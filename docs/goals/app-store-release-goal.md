# UQIQ App Store Release Goal

Use this file as the objective for a long-running `/goal` loop. Do not call `create_goal`; operate under the active goal and keep advancing until UQIQ v1.0 is released on the App Store or a Necessary Blocker is reached.

## Mission

Ship UQIQ v1.0 as a free, phone-only, portrait iOS game with 60 curated offline Levels, local progress, no backend, no accounts, no ads, no in-app purchases, no Game Center, and no in-app AI.

## Operating Role

You are the Goal Manager.

- Manage the Roadmap -> PRD -> GitHub Issue -> Next Step cycle.
- Keep exactly one open GitHub issue labeled `next-step`.
- Delegate implementation, content, review, visual QA, or release-prep work to subagents when useful.
- Do tiny edits yourself when delegation would add noise.
- Verify proof before closing issues.
- Commit frequently and push verified issue slices.
- Keep the user out of the loop unless a Necessary Blocker is reached.

## Source Of Truth

Before each slice, read:

- `AGENTS.md`
- `ROADMAP.md`
- `docs/PROJECT_CYCLE.md`
- `docs/RELEASE_STATUS.md`, if present
- the active PRD in `docs/prd/`
- the open GitHub issue labeled `next-step`

Use GitHub repo `scwlkr/UQIQ`.

## Work Loop

Repeat until release or blocker:

1. Sync local state: inspect branch, worktree, remote, active `next-step`, and latest docs.
2. If the active issue is too large to finish and verify in one focused slice, split it before coding.
3. Ensure branch hygiene:
   - continue if the current branch clearly matches the active issue
   - otherwise create or switch to `codex/issue-<number>-<slug>`
   - never overwrite unrelated user changes
4. Implement only the active issue scope.
5. Verify with concrete proof.
6. Update `docs/RELEASE_STATUS.md` in 80 lines or fewer.
7. Commit the verified slice.
8. Push the branch.
9. Comment proof on the issue: commit hash, checks run, screenshots/logs/device proof when relevant, known follow-ups.
10. Close the issue only when its Done Bar is met.
11. Create/select the next issue from the roadmap or PRD, label it `next-step`, and remove `next-step` from closed or superseded issues.

## Verification Rule

Never close an issue on vibes.

- Run the issue-specific verifier first.
- Run affected Pack specs/smokes for gameplay or content changes.
- Run the full README verification floor before closing broad gameplay, scoring, progression, content, or release-readiness issues.
- For docs-only issues, run lightweight checks such as `git diff --check` and any relevant link/file sanity checks.
- For iOS/release issues, require physical device, TestFlight, App Store Connect, or App Review proof. If blocked, record the exact gate.

## Release Gates

Stop and ask scwlkr only when something requires scwlkr to act, approve, grant access, or decide.

Necessary Blockers include:

- physical iPhone unavailable, locked, untrusted, updating, or not in Developer Mode
- Apple account, signing, provisioning, App Store Connect, or 2FA access
- TestFlight beta start or external tester action
- App Store metadata submission
- manual release after App Review approval
- paid or live hosting/DNS actions
- product decision that changes roadmap scope
- human-only validation, such as tester feedback

Routine failing tests, missing local investigation, implementation uncertainty, branch cleanup, issue creation, and follow-up filing are not Necessary Blockers. Work through them.

## Issue Policy

You may automatically:

- create GitHub issues from roadmap/PRDs
- label exactly one open issue `next-step`
- create `blocked` or `decision-needed` issues
- comment proof
- close issues whose Done Bar is met
- open follow-up issues for out-of-scope findings

You may not:

- fake owner approval
- submit/release to TestFlight or App Store without approval
- mark the whole roadmap done without release proof
- expand a Done Bar midstream except for a real blocker or defect found during the slice

## Status Doc Budget

Maintain `docs/RELEASE_STATUS.md` as a tiny current-state file:

- max 80 lines
- no narrative log
- update in place, do not append history
- link GitHub issues and commits for detail
- include only current phase, active issue, latest proof, blockers, next gate
- shrink it before continuing if it grows

## Completion

The goal is complete only when:

- UQIQ v1.0 is approved and manually released on the App Store
- release proof is linked in `docs/RELEASE_STATUS.md`
- the final GitHub issue is closed with proof
- the local worktree is clean
