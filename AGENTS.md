# Agent Instructions

## Confirm Before Implementing

Before implementing anything non-trivial — architectural decisions, multi-file changes, new abstractions, refactors, or anything with meaningful trade-offs — **pause and propose first**:

- Explain what you plan to do and why.
- Call out assumptions, design choices, risks, and anything that could break — especially in shared or critical code paths.
- Wait for explicit confirmation before writing or editing code.

Simple, obviously correct, single-line fixes may proceed directly.

## Task Tracking

### States

Track every open item as one of:

- **⏳ awaiting confirmation** — proposed, not yet approved
- **🔧 in progress** — actively being worked on
- **⏸ blocked** — waiting on user input or external dependency
- **✅ done** — completed

### Status block

Show a compact status block (one line per item, most urgent first) when:

- Multiple items are open simultaneously
- A task changes state or a milestone completes
- The user asks (`status`, `where are we`, etc.)

```
⏳ Refactor auth middleware — awaiting your OK
🔧 Fix CSV export bug — in progress
⏸ Deploy script — needs AWS creds
```

**Skip the block** when only one task is active and progressing normally — just do the work.

### Pruning

- ✅ items appear **once** on completion, then drop from subsequent status blocks.
- In long conversations where all prior tasks are done, start fresh — no historical recap unless asked.

### Interleaving and conflicts

- A ⏳ item stays open until confirmed, rejected, or explicitly dropped.
- If a new request arrives while something is ⏳: briefly note what's pending (one sentence), then **respond** to the new request — don't ignore it. That does **not** mean implementing it without approval.
- **New** work is still subject to **Confirm Before Implementing** when it is non-trivial: propose and wait for confirmation; don't jump straight to code just because something else was ⏳ or the message was a “quick” follow-up.
- If a new request **conflicts** with a ⏳ proposal, say so and ask which to pursue before writing code.

### Sequencing

- **Respect explicit order** when the user is strict about it (e.g. “do in this order,” “don’t skip steps,” numbered list **and** they treat it as a sequence). Do **not** skip ahead unless they allow parallel work, reordering, or skipping. If a step is blocked, say what's needed; default to **not** advancing until it’s unblocked or they tell you to skip/reorder.
- **Reorder or unify when it helps**: Lists are often a brain dump. If items overlap, duplicate effort, or a different order is safer (dependencies, less rework), you may **propose a merged or reordered plan** and wait for confirmation before treating that as the new sequence — same bar as **Confirm Before Implementing** when the change is non-trivial.
- Non-trivial work: give a **short step outline** first. **Checkpoint before risky steps** — dependency installs, migrations, schema/API changes, destructive commands — unless told to run through without stopping.

### Definition of done

Use the user's acceptance criteria if stated. Otherwise: changes match the ask, tests pass, docs stay in sync (see **After Making Changes**).

## Before Making Changes

- Read and understand the relevant existing code before proposing anything.
- Prefer minimal, targeted edits — change only what is necessary.
- If anything is unclear, ask rather than assume.

## Comments for scanability

When adding or editing code, put a short comment **immediately before** non-trivial, long, or dense sections—multi-step logic, heavy pipelines, nested branching, concurrency, I/O orchestration, or anything that is not obvious from names alone. The comment should say **what the following block is about to do** (intent or outcome), not narrate every line.

- Skip comments for obvious one-liners or code whose names already carry the full meaning.
- Prefer one clear sentence over scattering noise inside the block.
- A solid module or function docstring counts toward this when it states responsibility and the main flow.

## Available Tools

- The AWS CLI is available for AWS operations (S3, EC2, SSM, CloudWatch, etc.).
- AWS CLI commands must be run outside the sandbox, as the sandbox blocks the network access required for AWS API calls.

## Running Code

- Use a project-specific virtual environment when one exists.
- Run commands from the repo root unless a subdirectory is explicitly required.
- Include the exact interpreter path when it matters for dependencies.
- Call out environment or path assumptions that affect whether a command will work.

## After Making Changes

- Run `git diff` to review all modifications.
- Verify changes are correct, consistent, and clean — no redundant edits, no unintended side-effects, no leftover debug code. Revert anything unexpected or unrelated.
- Keep code and docs (`.md` files) in sync — if behavior changes, update corresponding documentation.
- Run existing tests. If new behavior was added, add or update tests to cover it.
