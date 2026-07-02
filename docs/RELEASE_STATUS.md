# UQIQ Release Status

Last updated: 2026-07-02

## Current Phase

Six-Level Tactile Prototype.

Release prep is paused. The active priority is implementing the Polished Six-Level Core from `docs/prd/0005-polished-six-level-core.md`.

## Active Next Step

- GitHub issue: [Implement Level 1 First Ramp freehand physics runner](https://github.com/scwlkr/UQIQ/issues/64)
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
- Existing Physics Draw proves touch drawing and gesture classification, but not yet realish physical collision.
- Physical iPhone proof exists for the old direct-touch build: UQIQ `0.1.1 (20260702073553)` installed/launched on `17 Hoe Max`.

## Latest Verification

- Wayfinder planning artifacts are committed and pushed through `6eaa100`.
- `git diff --check` passed for the six-Level planning artifacts.
- Previous phone proof for the old direct-touch build passed with screenshot `/tmp/uqiq-ios-quick/uqiq-phone-20260702073553.png`.

## Known Blockers

- No current owner decision blocker for the prototype path.
- Physical iPhone proof is required again after the new realish physics implementation exists.
- App Store submission, external TestFlight, live privacy/support hosting, and public release remain paused until the six-Level core is stronger and scwlkr approves.

## Next Gate

Implement Level 1 `First Ramp` with realish freehand physics: drawn stroke becomes collision geometry, `Release` starts ball motion, and the ball reaches the cup by physical overlap.
