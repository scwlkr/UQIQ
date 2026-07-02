# Level 2 Drawing Concept Twist

Parent ticket: https://github.com/scwlkr/UQIQ/issues/61

## Decision

Level 2 should be a freehand physics stopper level.

Level 1 teaches: draw a ramp and the ball moves.

Level 2 should teach: drawing is not always about making a path. Sometimes the clever move is drawing the missing obstacle.

## Player-Facing Level

Title:

```text
Brake Check
```

Prompt:

```text
Draw one line so the ball does not miss the cup.
```

Player experience:

1. The player sees a ball on a short left-side shelf or chute.
2. The cup sits below and slightly right of the ball's natural path.
3. A faint track or arrow implies the ball will roll right when released.
4. If the player draws another ramp or bridge, the ball speeds past the cup and fails.
5. The intended solve is a short vertical or slanted stopper just beyond the cup.
6. On `Release`, the ball rolls into the stopper, loses forward motion, and drops into the cup.
7. Completion feedback appears quickly and advances the six-level prototype flow.

The UQIQ Moment is the realization that the right drawing is not a path to the goal. It is the thing that prevents the ball from being too confident.

## Layout

Target portrait playfield: current phone-sized Godot viewport, `390x844`.

Suggested playfield coordinate model:

```text
playfield: 340w x 300h
ball_start: (74, 118)
ball_radius: 16
starter_chute: from (42, 134) to (170, 166)
cup_zone: (210, 224, 58, 52)
stopper_sweet_spot: x 268-304, y 166-238
gravity: downward
draw_area: whole playfield except top instruction/header padding
```

Visuals:

- Ball is a readable filled circle.
- Cup is a simple U-shaped goal or padded target zone below the ball path.
- Starter chute is a built-in static ramp so the ball already has motion.
- Drawn stroke is thick and high-contrast.
- Optional first-failure hint: briefly pulse the overshoot path after the ball misses.

## Level Spec Draft

This draft intentionally avoids `draw_options`; the solution is a physical outcome.

```json
{
  "id": "core_l02_brake_check",
  "pack_id": "six_level_core",
  "level_number": 2,
  "title": "Brake Check",
  "template": "Physics Draw",
  "challenge_type": "physics puzzle",
  "completion_mode": "auto_complete_on_goal_overlap",
  "prompt": "Draw one line so the ball does not miss the cup.",
  "rules": {
    "interaction_model": "freehand_physics_then_release",
    "moving_object": {
      "id": "ball",
      "shape": "circle",
      "start": [74, 118],
      "radius": 16,
      "initial_state": "resting_on_starter_chute"
    },
    "built_in_geometry": [
      {
        "id": "starter_chute",
        "type": "static_segment",
        "points": [[42, 134], [170, 166]],
        "collision_thickness_px": 12
      }
    ],
    "goal_zone": {
      "id": "cup",
      "rect": [210, 224, 58, 52],
      "forgiveness_px": 16
    },
    "draw_limit": {
      "strokes": 1,
      "min_length_px": 48,
      "max_sampled_points": 24,
      "collision_thickness_px": 12
    },
    "simulation_limit_seconds": 4,
    "reset_on_failure": true
  },
  "solution": {
    "success_condition": "ball overlaps cup goal zone after release",
    "intended_strategy": "draw a short stopper just beyond the cup so the rolling ball loses forward motion and drops into the goal",
    "common_wrong_strategy": "draw a ramp, bridge, or long guide under the ball, which sends it past the cup",
    "not_allowed": "answer-choice draw option"
  },
  "scoring": {
    "prototype": true
  },
  "roasts": {
    "failure": [
      "The ball had momentum. You gave it a highway."
    ],
    "delay": [
      "It does not need more path. It needs consequences."
    ],
    "scorecard": [
      "You solved physics by becoming a wall."
    ]
  },
  "assets": {
    "style": "flat_vector",
    "shapes": [
      "ball",
      "cup",
      "starter_chute",
      "freehand_stopper",
      "overshoot_path"
    ]
  },
  "uqiq_moment": "The obvious ramp/bridge answer is wrong; the correct draw is a stopper that makes the ball drop into the cup."
}
```

## Forgiveness

The acceptable solution should be broad:

- Vertical, slightly tilted, and short curved stoppers should work.
- The stopper should not require exact pixel placement; any stroke just past or partly over the cup should have a fair chance.
- The cup zone should be padded enough to catch slow drops and small rebounds.
- A line that looks like a ramp/bridge should fail by visible overshoot, not by silent rejection.
- Failed attempts should reset quickly without preserving old physics bodies.

Failure copy should describe what happened:

```text
Overshot. The ball did not need encouragement.
```

```text
Too short. Draw something the ball can actually hit.
```

## Implementation Notes

Level 2 should use the same future `freehand_physics_then_release` path as Level 1.

Minimum build shape:

- `RigidBody2D` ball starts on a built-in static chute.
- `StaticBody2D` starter chute creates the initial roll.
- `Line2D` plus `StaticBody2D` segment colliders represent the player's stroke.
- `Area2D` cup zone detects overlap.
- Runtime owner clears the drawn stopper, ball, and attempt state on reset.
- `InputEventScreenTouch` and `InputEventScreenDrag` are the primary input path.

Physics tuning should favor interpretation:

- Low-to-medium ball speed.
- Thick stopper collision.
- Modest ball bounciness so the stopper arrests motion more than launching it.
- Padded cup zone.
- Four-second simulation cap.

## Verification

A future implementation issue should prove:

- Level 2 renders as a freehand physics Level, not `draw_options` UI.
- Touch press/drag/release creates a thick visible stroke.
- The stroke creates collision geometry.
- `Release` starts the ball rolling from the built-in chute.
- A stopper beyond the cup completes by physical goal overlap.
- A ramp/bridge-like stroke overshoots and fails.
- A too-short stroke fails before simulation or with clear feedback.
- Reset removes old stroke/collision/ball state.
- Level 2 advances from Level 1 in the six-level prototype flow.
- Physical iPhone smoke shows the stopper is drawable in portrait with safe-area margins.

## Non-Goals

- No second stroke.
- No counterweight yet.
- No moving hazards.
- No score tuning.
- No Dur Token behavior.
- No Score Roastcard polish.
- No full 60-Level compatibility requirement for this proof.
