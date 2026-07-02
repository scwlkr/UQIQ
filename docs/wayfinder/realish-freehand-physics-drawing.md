# Realish Freehand Physics Drawing Prototype

Parent ticket: https://github.com/scwlkr/UQIQ/issues/58

## Current Baseline

The current Godot build already proves direct touch drawing, but it does not yet prove realish physics.

What exists:

- `physics_draw_surface` receives direct mouse and screen-touch input.
- `player_drawn_line` renders the player's stroke.
- `InputEventScreenTouch` and `InputEventScreenDrag` paths are covered.
- Drawn lines are classified into deterministic gesture ids such as `ramp_to_cup`.
- Release succeeds when the classified id matches the Level Spec solution.

What is missing:

- No `RigidBody2D` ball is simulated.
- No drawn stroke becomes collision geometry.
- No target is reached by physical motion.
- Release is currently an answer check, not a physics outcome.

## Minimum Prototype

Build one Q Remastered-like proof path before expanding Draw/Shape content.

The minimum implementation is a single portrait phone playfield where:

- The player draws one freehand stroke directly on the playfield.
- The stroke becomes visible geometry and physical collision.
- A ball or token moves under Godot 2D physics after `Release`.
- A cup, flag, or goal zone detects success by overlap.
- Failure resets quickly without leaving stale physics bodies.
- The same level can be verified headlessly with simulated touch input.

This should live behind a new interaction model, for example:

```text
freehand_physics_then_release
```

Do not replace every Physics Draw level at once. Keep the old deterministic classifier path available until the new proof is stable.

## Technical Shape

Use Godot 2D physics for the prototype:

- `RigidBody2D` or equivalent physics body for the moving ball/token.
- `Area2D` for the goal zone.
- `StaticBody2D` segment colliders created from the drawn stroke.
- `Line2D` for the visible stroke.
- One parent node that owns and clears all runtime physics bodies.

Input pipeline:

- Accept `InputEventScreenTouch` and `InputEventScreenDrag` as the primary path.
- Keep mouse input only for desktop/dev verification.
- Clamp all points to the drawing surface.
- Resample points by distance so one shaky finger does not create excessive colliders.
- Reject very short strokes before creating physics bodies.

Recommended first-pass limits:

- 1 stroke.
- 1 moving object.
- 1 goal.
- 1 active drawn body at a time.
- 20-30 max sampled points.
- 8-14 px visual/collision thickness.
- 3-5 seconds max simulation per attempt.

## Forgiveness Rules

This is not a precision sandbox. The prototype should make the idea matter more than finger accuracy.

- Goal zone should be visually obvious and physically padded.
- Ball/token should be large enough to read on phone.
- Stroke collision should be thick enough to tolerate imperfect lines.
- Valid solutions should accept a range of ramps/bridges, not one exact angle.
- A failed attempt should explain the physical reason: too short, missed goal, blocked path, or object fell away.
- Reset should be one tap and preserve the player's sense that another idea will work.

## Level Spec Direction

Future Draw/Shape specs should move away from `draw_options` as answer choices.

Prefer fields that describe a physical setup:

```text
interaction_model
ball_start
goal_zone
draw_limit
simulation_limit_seconds
success_condition
failure_conditions
forgiveness
```

Keep `direct_draw_gesture` only as a verifier helper or temporary migration field, not as the player-facing model.

## Verification Contract

A future implementation ticket should add focused verifier coverage for:

- Touch press/drag/release creates a visible stroke.
- Stroke creates collision geometry.
- Ball/token moves after release.
- Valid ramp/bridge reaches the goal.
- Too-short stroke fails.
- Bad flat or blocking stroke fails.
- Reset removes old physics bodies.
- No `Draw:` option buttons appear on the new prototype path.
- The same path works in desktop headless verification and physical iPhone smoke.

## Decision

The minimum proof of realish UQIQ drawing is not more gesture classification. It is one contained, phone-safe, touch-first physics runner where a drawn stroke changes object motion and the goal is reached by physical overlap.
