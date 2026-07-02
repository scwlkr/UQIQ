# PRD 0005: Polished Six-Level Core

## Goal

Build a tactile six-Level prototype that proves UQIQ is fun as a phone-first puzzle game before scaling content or resuming App Store release work.

## Source Decisions

- [Wayfinder map: UQIQ tactile six-level core](https://github.com/scwlkr/UQIQ/issues/56)
- [Prototype realish freehand physics drawing feel](https://github.com/scwlkr/UQIQ/issues/58)
- [Design Level 1 draw-first opener](https://github.com/scwlkr/UQIQ/issues/59)
- [Design Level 2 drawing concept twist](https://github.com/scwlkr/UQIQ/issues/61)
- [Design the two Physics-Linked Rearrange levels](https://github.com/scwlkr/UQIQ/issues/62)
- [Design the two Memory-Reveal tactile levels](https://github.com/scwlkr/UQIQ/issues/60)

## Scope

- Keep UQIQ phone-only and portrait-first.
- Build a six-Level prototype:
  1. `First Ramp` - Freehand Physics Drawing, direct ramp.
  2. `Brake Check` - Freehand Physics Drawing, stopper twist.
  3. `Goalposts Are Portable` - Physics-Linked Rearrange, moved cup.
  4. `Gravity Has Handles` - Physics-Linked Rearrange, moved gravity rule.
  5. `Cup Blinks First` - Memory/Reveal plus Freehand Physics Drawing.
  6. `Remember the Pull` - Memory/Reveal plus Physics-Linked Rearrange.
- Add the interaction models needed for those Levels:
  - `freehand_physics_then_release`
  - `physics_linked_rearrange_then_release`
  - `reveal_then_freehand_physics`
  - `reveal_then_physics_linked_rearrange`
- Use realish, forgiving physics: readable motion, broad success windows, thick collision, padded goals, fast reset.
- Preserve the existing deterministic Physics Draw and direct interaction paths until the new prototype path is stable.
- Add focused scripted verification for each new interaction path.
- Prove the six-Level prototype on desktop Godot and one physical iPhone when the device is available.

## Non-Goals

- No 60-Level content expansion.
- No final v1.0 level-count decision.
- No App Store submission, external TestFlight, live DNS/hosting, or public release.
- No UQIQ Score tuning.
- No Dur Token loop changes.
- No Score Roastcard polish.
- No large audio, haptic, art, or asset pass.
- No in-app AI, backend, accounts, ads, IAP, Game Center, or user-created Levels.
- No iPad-specific layout.

## Decisions

- The active product proof is the Polished Six-Level Core, not the old 60-Level/App Store path.
- Draw/Shape is the strongest Level family and owns the first two Levels.
- Rearrange and Memory/Reveal must affect physics or interpretation of physics; they must not become static sorting or pure recall.
- Completion should come from physical outcomes where possible, especially moving-object overlap with a goal zone.
- Humor and judgment remain secondary flavor while the tactile core is being proven.
- Feedback is core-first: success, failure, reset, and basic readability before scoring or Roastcard systems.

## Acceptance Criteria

- All six Levels are playable in order from a clean local state.
- Level 1 and Level 2 use freehand drawing that becomes collision geometry and affects ball motion.
- Level 3 and Level 4 use drag/rearrange actions that change the physics outcome before release.
- Level 5 and Level 6 use brief reveal/hide behavior that changes the later drawing or rearrange solve.
- No Level depends on answer-choice UI as the primary solve.
- Each Level has clear failure, quick reset, and forgiving touch/physics thresholds.
- Focused verifier coverage proves the intended success and at least one meaningful failure path for each interaction family.
- The local README verification floor still passes, or unrelated failures are documented.
- One physical iPhone proof is captured when the device is available.
- scwlkr playtests the six-Level prototype and explicitly approves, redirects, or rejects the direction.

## Suggested Issues

1. Implement Level 1 `First Ramp` freehand physics runner.
2. Implement Level 2 `Brake Check` on the same freehand physics path.
3. Implement `physics_linked_rearrange_then_release` and Level 3 `Goalposts Are Portable`.
4. Implement Level 4 `Gravity Has Handles`.
5. Implement the reveal layer and Level 5 `Cup Blinks First`.
6. Implement Level 6 `Remember the Pull`.
7. Wire six-Level prototype flow, focused feedback, reset consistency, and phone proof.

## First Next Step

[Implement Level 1 First Ramp freehand physics runner](https://github.com/scwlkr/UQIQ/issues/64)
