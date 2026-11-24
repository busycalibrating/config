# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
<!-- A detailed project overview of the codebase can be found in the [project overview](./assets/CLAUDE_OVERVIEW.md) file. -->

## Behavioural Guidelines

This is a machine learning research codebase. 
Write simple, readable, reproducible research code. 
Ensure you use the standard 
Do not maintain any silent fallbacks as we change the code. Fail loudly.
Prefer code that is easy to inspect, modify, debug, and trust over clever abstractions.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals. For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### 5. ML performance

Use the GPU you're allocated, but don't reach for complexity until
profiling shows it's needed. Premature optimization masks bugs and
obscures intent.

**Sensible defaults:**

- **Training**: `bf16` mixed precision, `DataLoader` with
  `num_workers=$SLURM_CPUS_PER_TASK` and `pin_memory=True`, attention
  via `F.scaled_dot_product_attention` (gets FlashAttention for free
  on A100/H100).
- **Inference**: KV cache on, batched generation, `torch.inference_mode()`.
  For anything past a few prompts; potentially use vLLM/SGLang/TGI rather than a
  hand-rolled loop (ask)

**Don't reach for these without a measured reason:** FSDP / DeepSpeed,
custom CUDA or Triton kernels, int4/int8 quantization mid-development.
A single A100L or H100 fits more than you'd think with `bf16` +
gradient checkpointing.

**Rule of thumb**: if `nvidia-smi` shows GPU utilization under ~50%,
the bottleneck is the data pipeline, not the model. Fix that first.

### 6. Research Logging

When running experiments, keep a log that you track high level findings and results in. 
For each batch of experiments you run, produce an output markdown log that contains the 
hypothesis tested, key results/findings, relevant information to reproduce it, and potential
outcomes/next steps if relevant. 

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.