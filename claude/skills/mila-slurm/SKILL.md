---
name: mila-slurm
description: "Launch Slurm jobs on the Mila cluster. Use whenever the user wants to submit, queue, monitor, or cancel jobs on Mila — anything involving sbatch, srun, salloc, squeue, scancel, sacct, --partition=unkillable/main/long, --gres=gpu:..., $SLURM_TMPDIR, or login-X.login.server.mila.quebec. Covers writing sbatch scripts, picking the right partition + GPU + time limit for Mila's specific limits, common environment setup (modules, conda, dataset staging), and inspecting job status. For long jobs on preemptible partitions, also read checkpointing.md in this skill."
---

# Launching Slurm jobs on the Mila cluster

This skill is for submitting and managing jobs on the Mila cluster.
It's condensed from the official Mila compute cheat sheet (2025-06-27,
v3) plus the parts of stock Slurm that an agent actually needs to
write a working `sbatch` script on the first try.

## When to use this skill

Trigger on any of:

- The user asks to submit / queue / run / launch / "sbatch" something
  on the cluster.
- The user mentions Mila partitions (`unkillable`, `unkillable-cpu`,
  `short-unkillable`, `main`, `main-cpu`, `long`, `long-cpu`), Mila
  GPU models (RTX8000, V100, A100, A100L, A6000, L40S, H100), or
  filesystem paths (`/network/scratch`, `/network/datasets`,
  `/network/weights`, `/network/projects`).
- The user is editing a script with `#SBATCH` directives.

## How to use this skill

This file is a quick reference. For long-running jobs on preemptible
partitions (`main`, `long`, `main-cpu`, `long-cpu`), also read
`checkpointing.md` in this skill folder — it covers requeue, signal
handling, and resumable training so jobs survive preemption.

The general workflow:

1. **Confirm what the user actually wants** — partition, time, GPU model
   and count, memory, CPUs. Don't guess. If they said "run my training
   job" with no resource hints, ask.
2. **Pick the right partition** (see "Partitions" below). Wrong partition
   = job sits in queue forever or gets preempted in an hour.
3. **Write an `sbatch` script as a file**, don't try to cram everything
   into a one-line `sbatch` command. The cheat sheet's house style is a
   script with `#SBATCH` directives. This skill follows that.
4. **Submit with `sbatch script.sh`** and capture the returned job ID.
5. **Monitor with `squeue -u $USER`** or `sacct` — do not poll harder
   than every ~10 seconds.

## Partitions

Use `--partition=<name>` (or `-p <name>`) to select priority class.
Jobs in higher-priority partitions can preempt lower-priority ones.
Preemption order: `unkillable > main > long`.

| Partition          | Max resources per job          | Max time | Notes                                    |
| ------------------ | ------------------------------ | -------- | ---------------------------------------- |
| `unkillable`       | 6 CPUs, 32 GB RAM, 1 GPU       | 2 days   | Not preempted. Strict limits.            |
| `unkillable-cpu`   | 2 CPUs, 16 GB RAM, 0 GPU       | 2 days   | CPU-only equivalent.                     |
| `short-unkillable` | exactly 4 GPUs (A100L/L40S/H100) | 3 hours  | Multi-GPU only. Only path to H100s.    |
| `main`             | 8 CPUs, 48 GB RAM, 2 GPUs      | 5 days   | Default for most jobs. Preemptible.      |
| `main-cpu`         | 8 CPUs, 64 GB RAM, 0 GPU       | 5 days   | CPU-only. Preemptible.                   |
| `long`             | no resource limit              | 7 days   | Preempted by `main` and `unkillable`.    |
| `long-cpu`         | no resource limit              | 7 days   | CPU-only. Preemptible.                   |

**Rules of thumb:**

- Debugging or interactive-feeling work, ≤ 2 days, 1 GPU → `unkillable`.
- Normal training run, ≤ 5 days, ≤ 2 GPUs → `main`.
- Long sweep or run that needs > 5 days or > 2 GPUs (and isn't a 4-GPU
  H100 burst) → `long`, **and** read `checkpointing.md` first.
- 4-GPU short burst on H100s → `short-unkillable`. This is the only way
  to get H100s on the Mila cluster. Must request exactly 4 GPUs.
- CPU-only job → use a `-cpu` partition. If you ask for `unkillable` /
  `main` / `long` without `--gres=gpu:...`, Slurm translates it to the
  `-cpu` equivalent automatically, but being explicit is clearer.

**Preemption** (brief): jobs on `main`, `long`, and the `-cpu` variants
can be killed mid-run and **automatically requeued** by Slurm when a
higher-priority job needs the resources. For jobs longer than a couple
of hours, the training script should be able to resume from a
checkpoint. See `checkpointing.md`.

## GPU types

Request a specific GPU model with `--gres=gpu:<model>:<count>`. Valid
models:

- `rtx8000` — 48 GB
- `v100` — 32 GB
- `a100` — 40 GB
- `a100l` — 80 GB (the "large" A100)
- `a6000` — 48 GB
- `l40s` — 48 GB
- `h100` — 80 GB (only via `short-unkillable`)

You can also use `--gres=gpu:<count>` without a model name to let Slurm
pick. Prefer naming the model when the workload cares about memory or
arch (e.g. anything needing >48 GB VRAM should ask for `a100l` or `h100`).

To see current node specs, counts, and per-node CPU/RAM, run on the
cluster: `sinfo -N -l` or `scontrol show node <nodename>`. The cheat
sheet also publishes "optimal" CPU:RAM ratios per node type
(e.g. 1 GPU : 12 CPUs : 256 GB on A100L nodes); asking close to those
ratios helps the scheduler pack jobs and reduces queue time.

## The sbatch script template

This is the canonical shape. Adjust the resource block; the rest is
mostly invariant.

```bash
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --partition=main                       # see partition table
#SBATCH --gres=gpu:rtx8000:1                   # 1 RTX8000; drop for CPU-only
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=12:00:00                        # HH:MM:SS or D-HH:MM:SS
#SBATCH --output=/network/scratch/${USER:0:1}/$USER/slurm-%j.out
#SBATCH --error=/network/scratch/${USER:0:1}/$USER/slurm-%j.err

set -euo pipefail

# 1. Environment
module --quiet load anaconda/3
conda activate my_env                          # or: source venv/bin/activate

# 2. Stage data to fast local scratch (optional but recommended for big data)
mkdir -p "$SLURM_TMPDIR/data"
cp -r /network/datasets/<dataset_name> "$SLURM_TMPDIR/data/"

# 3. Run
cd /home/mila/${USER:0:1}/$USER/my_project
python train.py \
    --data-path "$SLURM_TMPDIR/data/<dataset_name>" \
    --output-dir "$SLURM_TMPDIR/output"

# 4. Save anything you want to keep off the node before the job ends
cp -r "$SLURM_TMPDIR/output" "/network/scratch/${USER:0:1}/$USER/runs/$SLURM_JOB_ID/"
```

Notes on the template:

- **`#SBATCH` lines must come before any executable line.** Slurm stops
  parsing them at the first non-comment, non-blank line.
- **Time format**: `HH:MM:SS` (e.g. `12:00:00`) or `D-HH:MM:SS`
  (e.g. `2-00:00:00` for 2 days). Always under the partition's max.
- **Memory**: `--mem=16G` is total RAM for the job. You can also use
  `--mem-per-gpu=16G` when scaling with GPU count.
- **`set -euo pipefail`**: makes the script fail loudly instead of
  silently continuing past an error.
- **The output path** uses `${USER:0:1}` because Mila's home/scratch
  trees are sharded by first letter of the username
  (`/network/scratch/j/jdoe/`). Pre-create the directory.

## Multi-GPU / multi-node patterns

**1 node, multiple GPUs** (most common for distributed training):

```bash
#SBATCH --gpus-per-task=rtx8000:1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-node=4    # 4 tasks → 4 GPUs on this node
#SBATCH --mem=64G
#SBATCH --time=00:15:00
```

**Multiple nodes** (only when you actually need >1 node — most jobs do
not):

```bash
#SBATCH --gpus-per-task=rtx8000:1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-node=4
#SBATCH --nodes=2
#SBATCH --mem=64G
#SBATCH --time=00:15:00
```

Then launch the workload with `srun` inside the script so each task runs
on its allocated GPU:

```bash
srun python train.py
```

**Heuristic**: if each parallel job needs only 1 GPU, **do not** run
them as one multi-GPU job. Submit independent jobs or use an array
(below) — they'll schedule sooner and survive preemption independently.

## Job arrays (hyperparameter sweeps, multiple seeds)

For N independent runs of the same script with different parameters:

```bash
#SBATCH --array=0-9                # 10 jobs, $SLURM_ARRAY_TASK_ID = 0..9
#SBATCH --gres=gpu:rtx8000:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=logs/sweep-%A_%a.out  # %A=array job id, %a=task id

seeds=(0 1 2 3 4 5 6 7 8 9)
python train.py --seed "${seeds[$SLURM_ARRAY_TASK_ID]}"
```

Or submit at the command line: `sbatch --array=0-9 script.sh`. To limit
concurrency (e.g. only 4 running at a time): `--array=0-9%4`.

## Key Slurm environment variables (available inside the job)

| Variable                | What it is                                                  |
| ----------------------- | ----------------------------------------------------------- |
| `$SLURM_JOB_ID`         | The job's ID. Use in output paths.                          |
| `$SLURM_TMPDIR`         | Fast node-local scratch. Wiped at job end. Stage data here. |
| `$SLURM_CPUS_PER_TASK`  | What you asked for in `--cpus-per-task`. Use for DataLoader `num_workers`. |
| `$SLURM_ARRAY_TASK_ID`  | Index within an array job.                                  |
| `$SLURM_ARRAY_JOB_ID`   | The array's parent job ID.                                  |
| `$SLURM_PROCID`         | Rank of this task within `srun` (for distributed training). |
| `$SLURM_NTASKS`         | Total tasks in the job.                                     |
| `$SLURM_JOB_NODELIST`   | Nodes assigned. Useful for torchrun rendezvous.             |

## Filesystem at a glance

The cheat sheet calls out that **where you read and write matters**.
Don't push the user hard on this, but if they're staging GBs of data:

| Path                        | What it's for                              | Speed   | Backed up |
| --------------------------- | ------------------------------------------ | ------- | --------- |
| `$HOME`                     | Code, configs, dotfiles. 100 GB quota.     | Low     | Yes       |
| `$SCRATCH` (= `/network/scratch/...`) | Run outputs, checkpoints. 5 TB.  | High    | No        |
| `$SLURM_TMPDIR`             | Per-job node-local scratch.                | Highest | No (wiped) |
| `/network/datasets`         | Shared, read-only datasets.                | Medium  | No        |
| `/network/weights`          | Shared, read-only model weights.           | High    | No        |
| `/network/projects`         | Lab/project shared space.                  | Varies  | No        |

For a big dataset accessed many times in a job, `cp` it from
`/network/datasets` to `$SLURM_TMPDIR` once at the start of the script,
then read from `$SLURM_TMPDIR`. For a small or rarely-read dataset,
don't bother.

## Submitting and monitoring

```bash
# Submit
sbatch my_script.sh
# → Submitted batch job 12345678

# Watch your queue
squeue -u $USER

# Detail on one job
scontrol show job 12345678

# Cancel
scancel 12345678
scancel -u $USER                    # cancel ALL your jobs
scancel --state=PENDING -u $USER    # only the queued ones

# After it finishes — exit code, runtime, memory used
sacct -j 12345678 --format=JobID,JobName,State,ExitCode,Elapsed,MaxRSS,AllocTRES%40

# Listing jobs over a time range
sacct -u $USER -S 2025-05-01 -E now \
    --format=JobID,JobName,Partition,State,Elapsed
```

When `squeue` shows a job stuck in `PENDING`, the `REASON` column tells
you why: `Priority` (waiting in queue), `Resources` (waiting for the
hardware you asked for), `QOSMaxJobsPerUserLimit` (too many of your jobs
running), etc. `Resources` on an exotic ask (e.g. `--gres=gpu:h100:8`)
often means "you can't have that on this cluster" — re-check the
partition and GPU model.

## Common failure modes

These are mistakes an agent will reliably make if not warned:

- **Asking for resources that exceed the partition's per-job cap.** The
  job is rejected at submit or sits in `PENDING` with reason
  `QOSMaxCpuPerJobLimit` / similar. Check the partition table above.
- **`#SBATCH` lines after the first non-comment line.** They're silently
  ignored. Put all `#SBATCH` directives at the top.
- **No `--time`**. The default time limit is short and partition-specific.
  Always set `--time` explicitly.
- **Output path in a directory that doesn't exist.** Slurm will fail the
  job at start. `mkdir -p` the log directory before `sbatch`, or use a
  directory you know exists.
- **Activating conda before `module load anaconda/3`.** `conda` isn't on
  `PATH` until the module is loaded. Load first, activate second.
- **Running heavy work on login nodes.** Login nodes are for editing,
  submitting, and tiny tests. Anything >~30 seconds of CPU or any GPU
  use belongs in a job.
- **`--gres=gpu:h100:1` on `main`.** H100s are only available via
  `short-unkillable`, which also requires exactly 4 GPUs.
- **One big multi-GPU job for embarrassingly parallel work.** Use an
  array of single-GPU jobs instead — schedules faster, isolates failures.

## Getting current cluster state

When in doubt about what's available right now:

- `sinfo` — partitions and node states.
- `sinfo -N -l` — per-node detail (GPUs, RAM, state).
- `scontrol show node <name>` — full spec for one node.
- `scontrol show partition <name>` — limits for one partition.
- `savail` — lists available GPUs.
- `partition-stats -v` — similar to `savail`.

Prefer these over hard-coded assumptions. The cheat sheet itself warns
"every map is a simplification of reality" — node counts, partition
limits, and module versions drift.
