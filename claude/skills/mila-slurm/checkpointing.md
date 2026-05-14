# Checkpointing and preemption on the Mila cluster

Read this when writing or reviewing a job that runs on `main`, `long`,
`main-cpu`, or `long-cpu` — the **preemptible** partitions on Mila.

A job on a preemptible partition can be killed mid-run at any time when
a higher-priority job needs its resources. Slurm will then **requeue**
the job automatically, but it restarts the script from the top. Without
checkpointing, all in-memory progress is lost.

This file explains how to make jobs survive that cycle. The cheat sheet
explicitly calls out that "junior researchers don't write proper
checkpointing for their training experiments" — leading to wasted
compute and people retreating to `unkillable` (with its strict 1-GPU
limit) when they could be using the full cluster.

## What preemption looks like

When a job is preempted:

1. Slurm sends `SIGTERM` to the job's processes. (On Mila this is the
   default; no grace signal is configured.)
2. After a brief grace period, processes are killed with `SIGKILL`.
3. The job is **requeued** on the same partition with the same job ID.
4. The script runs again from the top.

The job's `State` in `sacct` will show `PREEMPTED` for the killed run,
then `RUNNING` again for the new attempt. The `Restarts` counter in
`scontrol show job <id>` increments each time.

## Three patterns, in order of effort

### Pattern 1: framework-native checkpointing (easiest)

If you're using a framework with built-in checkpointing, turn it on and
make sure the checkpoint path is on `$SCRATCH`, not `$SLURM_TMPDIR`
(which is wiped between attempts).

**HuggingFace `Trainer`**:
```python
training_args = TrainingArguments(
    output_dir=f"{scratch}/runs/{job_id}",
    save_strategy="steps",
    save_steps=500,
    save_total_limit=3,
)
trainer = Trainer(...)
trainer.train(resume_from_checkpoint=True)  # auto-finds latest
```

This detects a previous checkpoint on requeue and picks up from there.
Most training frameworks with first-class checkpoint callbacks behave
similarly — turn on periodic saving, point at a stable directory under
`$SCRATCH`, and pass the resume flag. Handles 90% of preemption cases
with a few extra lines.

### Pattern 2: manual checkpointing

For custom training loops, save state periodically and load it at start:

```python
import os
import torch
from pathlib import Path

job_id = os.environ.get("SLURM_JOB_ID", "local")
user = os.environ["USER"]
ckpt_dir = Path(f"/network/scratch/{user[0]}/{user}/runs/{job_id}")
ckpt_dir.mkdir(parents=True, exist_ok=True)
ckpt_path = ckpt_dir / "last.pt"

# --- Resume if checkpoint exists ---
start_step = 0
if ckpt_path.exists():
    state = torch.load(ckpt_path, map_location="cpu")
    model.load_state_dict(state["model"])
    optimizer.load_state_dict(state["optimizer"])
    start_step = state["step"]
    print(f"Resumed from step {start_step}")

# --- Training loop ---
for step in range(start_step, total_steps):
    train_one_step(...)

    if step % 500 == 0:
        # Atomic save: write to .tmp, then rename. Avoids a corrupt
        # checkpoint if the job is killed mid-write.
        tmp = ckpt_path.with_suffix(".pt.tmp")
        torch.save({
            "step": step + 1,
            "model": model.state_dict(),
            "optimizer": optimizer.state_dict(),
        }, tmp)
        tmp.replace(ckpt_path)
```

**Key details:**

- **Use `$SCRATCH`, not `$SLURM_TMPDIR`.** `$SLURM_TMPDIR` is per-job
  node-local storage that is wiped at job end (and the job may resume
  on a different node anyway).
- **Atomic write** (`.tmp` → `rename`). A non-atomic write leaves a
  corrupt file if preemption hits mid-`torch.save`, which then breaks
  the next attempt.
- **Cap checkpoint count.** Checkpoints are big; without cleanup
  `$SCRATCH` fills up. Keep the last N (e.g. 3) and delete older ones.
- **Save every N steps, not every epoch.** Epochs on large datasets can
  be hours. Aim for a checkpoint every 10–30 minutes of wall time.

### Pattern 3: SIGTERM handler (advanced, optional)

If you want to be extra safe and save *exactly* on preemption rather
than only at periodic checkpoints, install a signal handler:

```python
import signal

def on_preempt(signum, frame):
    print("Caught SIGTERM, saving checkpoint before exit...")
    save_checkpoint()  # your save function
    os._exit(0)

signal.signal(signal.SIGTERM, on_preempt)
```

This is only useful if the grace period (the gap between `SIGTERM` and
`SIGKILL`) is long enough to write a checkpoint. On Mila the default
grace is short, so don't rely on this alone — use it as a complement
to Pattern 1 or 2, not a replacement.

## Auto-requeue: is it on?

By default, Slurm requeues preempted jobs on Mila's preemptible
partitions. To be explicit (or to opt out):

```bash
#SBATCH --requeue        # default behavior, just makes it visible
#SBATCH --no-requeue     # opt out — job stays dead after preemption
```

Use `--no-requeue` only if the script truly cannot resume (e.g. a
hyperparameter search where each trial is independent and re-running
would corrupt the results database).

## Detecting "this is a resumed run"

Useful for logging and avoiding double-init of things like wandb runs:

```python
import os

restart_count = int(os.environ.get("SLURM_RESTART_COUNT", "0"))
is_resume = restart_count > 0

# For wandb: resume the same run instead of creating a new one
import wandb
wandb.init(
    project="my-project",
    id=os.environ["SLURM_JOB_ID"],   # stable ID across restarts
    resume="allow",
)
```

`SLURM_RESTART_COUNT` is `0` on the first attempt, `1` after the first
preemption, etc.

## Sanity checks before submitting a long job

Before you submit a multi-day job on `long`, verify:

- [ ] Checkpoint path is under `$SCRATCH`, not `$SLURM_TMPDIR` or
      `$HOME`.
- [ ] The job loads from the latest checkpoint at start if one exists.
- [ ] Checkpoints are written atomically.
- [ ] Checkpoint interval is ≤ ~30 minutes of wall time.
- [ ] Old checkpoints are pruned (keep last N).
- [ ] If using wandb / mlflow / similar, the run ID is stable across
      restarts (use `$SLURM_JOB_ID`).
- [ ] You've tested the resume path: run for a bit, kill the job
      (`scancel <id>`), resubmit, confirm it picks up.

The last item is the one people skip. Don't.

## Profiling and GPU utilization (related, often comes up together)

The cheat sheet also recommends profiling to make sure you're actually
using the GPU you reserved. Tools: `nvidia-smi` (live) or `wandb`
(logs GPU metrics automatically with `wandb.init`). If GPU utilization
is consistently under ~50%, the bottleneck is probably the data
pipeline — use more DataLoader workers
(`num_workers=$SLURM_CPUS_PER_TASK`), enable `pin_memory=True`, or
stage data to `$SLURM_TMPDIR`.

This is out of scope for "launching jobs" but worth flagging when
helping someone debug a long, expensive run.
