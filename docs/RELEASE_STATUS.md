# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Release prep is paused. UQIQ has a tested app shell and internal TestFlight proof, but the gameplay core does not yet match the intended interactive problem-solving direction.

## Active Next Step

- GitHub issue: [#42 Build interactive Pattern Grid prototype](https://github.com/scwlkr/UQIQ/issues/42)
- Branch: `codex/issue-42-interactive-pattern-grid`

## Product Direction From scwlkr

- scwlkr is here to define game direction, not act as a QA tester.
- Current build feels too much like multiple-choice buttons.
- Real drag/drop and real physics drawing need to exist before more App Store release work.

## Latest Proof

- Internal TestFlight install/launch proof passed for UQIQ `0.1.0 (1)` on physical iPhone `17 Hoe Max`.
- Full local verification floor has passed through `verify_issue_38_long_screen_fit.gd`.
- Current content includes 60 JSON Level Specs, Local Profile, scoring, Dur Tokens, roasts, replay, and Score Roastcards.
- Issue #40 adds a direct drag/drop playfield for Level 2 and a direct drawing surface for Level 6.
- `verify_issue_40_interaction_core.gd` proves the rendered UI no longer exposes `Move:` / `Drop on:` / `Draw:` choice buttons for those prototypes.
- Full documented verification floor passed after the interaction-core slice.
- Issue #40 closed with proof in commit `9047e91`.
- Issue #41 adds direct drawing gestures for all eight Pack 6 Physics Draw levels.
- `verify_issue_41_pack_6_direct_drawing.gd` proves Pack 6 Physics Draw levels reject a bad line and complete through direct drawing.
- Full documented verification floor passed after the Pack 6 drawing slice.
- Issue #41 closed with proof in commit `c41c67f`.
- Issue #42 adds direct row-marking interaction for Level 4 Pattern Grid.
- `verify_issue_42_pattern_grid_interaction.gd` proves Level 4 rejects a wrong row and completes from marked grid state without `Submit Pattern`.
- Full documented verification floor passed after the Pattern Grid slice.
- Issue #39 was superseded by product-direction feedback and the new interaction-core issue.

## Known Blockers

- No external/human testing blocker for the current slice.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until gameplay core is stronger and scwlkr approves.

## Next Gate

Close issue #42 with proof, then choose the next gameplay-depth issue before release work resumes.
