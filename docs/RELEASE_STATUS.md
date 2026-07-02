# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Release prep is paused. UQIQ has a tested app shell and internal TestFlight proof, but the gameplay core does not yet match the intended interactive problem-solving direction.

## Active Next Step

- GitHub issue: [#40 Build real interaction core prototype](https://github.com/scwlkr/UQIQ/issues/40)
- Branch: `codex/issue-40-interaction-core-prototype`

## Product Direction From scwlkr

- scwlkr is here to define game direction, not act as a QA tester.
- Current build feels too much like multiple-choice buttons.
- Real drag/drop and real physics drawing need to exist before more App Store release work.

## Latest Proof

- Internal TestFlight install/launch proof passed for UQIQ `0.1.0 (1)` on physical iPhone `17 Hoe Max`.
- Full local verification floor has passed through `verify_issue_38_long_screen_fit.gd`.
- Current content includes 60 JSON Level Specs, Local Profile, scoring, Dur Tokens, roasts, replay, and Score Roastcards.
- Current interaction implementation still uses button-choice approximations for Drag Logic and Physics Draw.
- Issue #39 was superseded by product-direction feedback and the new interaction-core issue.

## Known Blockers

- No external/human testing blocker for the current slice.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until gameplay core is stronger and scwlkr approves.

## Next Gate

Build and verify one real drag/drop interaction and one real drawing interaction in the existing Godot app.
