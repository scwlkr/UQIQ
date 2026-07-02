# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Six-Level Tactile Prototype.

Release prep is paused. The active priority is implementing the Polished Six-Level Core from `docs/prd/0005-polished-six-level-core.md`.

## Active Next Step

- GitHub issue: [Implement Level 4 Gravity Has Handles physics-linked rearrange runner](https://github.com/scwlkr/UQIQ/issues/67)
- PRD: [`docs/prd/0005-polished-six-level-core.md`](prd/0005-polished-six-level-core.md)
- Branch: none assigned yet.

## Direction Captured

The stale phone-direction gate is closed: [Direction needed from phone playtest build](https://github.com/scwlkr/UQIQ/issues/49).

Current direction:

- UQIQ is a tactile mobile puzzle game first.
- Humor/judgment is secondary flavor.
- Freehand physics drawing is the strongest Level family.
- The next product proof is six polished Levels, not 60 Levels.
- The six-Level mix is two Draw/Shape, two Physics-Linked Rearrange, and two Memory/Reveal Levels.

## Six-Level Core

Design source: [Wayfinder map: UQIQ tactile six-level core](https://github.com/scwlkr/UQIQ/issues/56)

1. `First Ramp` - draw a ramp so the ball reaches the cup.
2. `Brake Check` - draw a stopper so the ball drops into the cup.
3. `Goalposts Are Portable` - drag the cup into the ball path.
4. `Gravity Has Handles` - drag `GRAVITY` to change the physics direction.
5. `Cup Blinks First` - reveal hidden cup, hide it, draw to memory.
6. `Remember the Pull` - reveal gravity direction, hide it, move `GRAVITY`.

## Current Gameplay Proof

- Debug phone playtest supports direct level jump and all-level Level List access.
- Existing Pack 1 direct-touch prototypes are playable on phone.
- Level 1 and Level 2 prove realish freehand physics drawing with collision-backed ramp/stopper solves.
- Level 3 proves physics-linked rearrange: touch drag moves the cup, `Release` moves the ball, and completion comes from ball/cup overlap.
- Current physical iPhone proof exists for Level 3: UQIQ `0.1.1 (20260702115314)` installed/launched on `17 Hoe Max`.

## Latest Verification

- Level 3 focused verifier passed: `godot --headless --path . --script res://scripts/verify_issue_66_goalposts_rearrange.gd`.
- README/local verification floor passed through `verify_issue_66_goalposts_rearrange.gd`.
- `git diff --check` passed for the Level 3 implementation.
- Level 3 iPhone smoke passed on `17 Hoe Max` with screenshot `/tmp/uqiq-ios-quick/uqiq-phone-20260702115314.png`.

## Known Blockers

- No current owner decision blocker for the prototype path.
- No current physical iPhone blocker; Level 4 will need a fresh phone proof after implementation.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until the six-Level core is stronger and scwlkr approves.

## Next Gate

Implement Level 4 `Gravity Has Handles`: dragging `GRAVITY` changes the physics direction, `Release` starts the ball, wrong slots fail visibly, and the right-wall slot completes by ball/cup overlap.
