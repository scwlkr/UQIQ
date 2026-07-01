# Project Cycle

UQIQ is managed through a Roadmap -> PRD -> GitHub Issue -> Next Step loop.

GitHub repo: `https://github.com/scwlkr/UQIQ`

## Rule

There is always exactly one open GitHub issue labeled `next-step`.

## Flow

1. **Roadmap**
   - `ROADMAP.md` owns the phase order and launch path.
   - Update it only when project direction changes.

2. **PRD**
   - `docs/prd/` owns scoped product requirements for one roadmap phase or milestone.
   - A PRD must state goal, non-goals, decisions, acceptance criteria, and suggested issue slices.

3. **GitHub Issue**
   - GitHub issues own executable work.
   - Each issue links to a PRD, has a small scope, and includes a Done Bar.

4. **Next Step**
   - The active issue gets the `next-step` label.
   - When it closes, the next issue is created or selected and receives `next-step`.

## Work Loop

Before work:

- Read `ROADMAP.md`.
- Read the active PRD.
- Read the issue labeled `next-step`.

During work:

- Keep changes scoped to the issue.
- Comment on the issue when a decision changes scope.

After work:

- Post proof: commit, tests/checks, screenshots, device result, or explanation.
- Close the issue if the Done Bar is met.
- Make sure a new open issue has `next-step`.

## Labels

- `next-step`: the one active task.
- `prd`: a PRD/planning issue.
- `task`: implementation or content work.
- `bug`: defect.
- `decision-needed`: blocked on a product/technical choice.
- `blocked`: blocked by external access/tooling/review.
- `phase:planning`: planning/docs.
- `phase:build`: Godot/client build.
- `phase:content`: Level Specs and tuning.
- `phase:release`: TestFlight/App Store.
