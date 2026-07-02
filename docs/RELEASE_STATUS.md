# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Release prep is paused. The current priority is making the gameplay core feel like interactive problem solving instead of answer-choice UI.

## Active Next Step

- GitHub issue: [#44 Add quick wireless iPhone deploy loop](https://github.com/scwlkr/UQIQ/issues/44)
- Branch: `codex/issue-44-quick-phone-deploy`

## Current Gameplay Proof

- Level 2 Drag Logic has direct drag/drop.
- Level 4 Pattern Grid has direct row marking.
- Level 6 and Pack 6 Physics Draw have direct line drawing.
- Level 1 Tap Logic now has a direct tap scene instead of `CORRECT` / `WRONG` answer-choice buttons.

## Latest Verification

- Issue #43 closed with proof in commit `ada873e` and merge `42dcafd`.
- `verify_issue_43_tactile_tap_logic.gd` passed.
- Affected checks passed: `verify_issue_40_interaction_core.gd`, `verify_issue_42_pattern_grid_interaction.gd`, `verify_issue_4.gd`, `verify_issue_5_desktop_smoke.gd`, `verify_issue_7_pack_1_smoke.gd`.
- Full README verification floor passed through `verify_issue_43_tactile_tap_logic.gd`.
- `scripts/deploy_phone.sh` passed on physical iPhone `17 Hoe Max`: installed/launched UQIQ `0.1.1 (20260701224540)` and saved `/tmp/uqiq-ios-quick/uqiq-phone-20260701224540.png`.

## Known Blockers

- No blocker for the current gameplay slice.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until gameplay core is stronger and scwlkr approves.

## Next Gate

Close #44 with proof, then route the next `next-step` back to gameplay-feel iteration.
