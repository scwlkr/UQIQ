# Level 1 Draw-First Opener

Parent ticket: https://github.com/scwlkr/UQIQ/issues/59

## Decision

Level 1 should be a straightforward freehand physics ramp level.

It should not be a trick question. Its job is to prove the new promise in the first minute: draw on the phone, your line becomes physical, the ball moves, the cup catches it.

## Player-Facing Level

Title:

```text
First Ramp
```

Prompt:

```text
Draw a ramp so the ball rolls into the cup.
```

Player experience:

1. The player sees a ball near the lower-left of a portrait playfield.
2. The player sees a cup/goal zone on the lower-right, slightly higher than the ball.
3. The player draws one rising stroke from near the ball toward the cup.
4. The stroke becomes a solid ramp.
5. The player taps `Release`.
6. The ball rolls down/right along the drawn ramp into the cup.
7. Completion feedback appears quickly and the next Level unlocks.

The UQIQ Moment is not a joke twist. It is the tactile moment when the player's drawn mark becomes real enough to affect motion.

## Layout

Target portrait playfield: current phone-sized Godot viewport, `390x844`.

Suggested playfield coordinate model:

```text
playfield: 340w x 300h
ball_start: (58, 218)
ball_radius: 16
cup_zone: (258, 146, 54, 58)
gravity: downward
draw_area: whole playfield except top instruction/header padding
```

Visuals:

- Ball is a readable filled circle, not a text label.
- Cup is a simple U-shaped goal or padded target zone.
- Drawn line is thick and high-contrast.
- Optional ghost hint: a very faint dashed ramp suggestion for the first launch only.

## Level Spec Draft

This draft intentionally moves away from `draw_options`.

```json
{
  "id": "core_l01_first_ramp",
  "pack_id": "six_level_core",
  "level_number": 1,
  "title": "First Ramp",
  "template": "Physics Draw",
  "challenge_type": "physics puzzle",
  "completion_mode": "auto_complete_on_goal_overlap",
  "prompt": "Draw a ramp so the ball rolls into the cup.",
  "rules": {
    "interaction_model": "freehand_physics_then_release",
    "moving_object": {
      "id": "ball",
      "shape": "circle",
      "start": [58, 218],
      "radius": 16
    },
    "goal_zone": {
      "id": "cup",
      "rect": [258, 146, 54, 58],
      "forgiveness_px": 14
    },
    "draw_limit": {
      "strokes": 1,
      "min_length_px": 70,
      "max_sampled_points": 30,
      "collision_thickness_px": 12
    },
    "simulation_limit_seconds": 4,
    "reset_on_failure": true
  },
  "solution": {
    "success_condition": "ball overlaps cup goal zone after release",
    "intended_strategy": "draw a rising ramp from below the ball toward the cup",
    "not_allowed": "answer-choice draw option"
  },
  "scoring": {
    "prototype": true
  },
  "roasts": {
    "failure": [
      "The ball respected your line. That was the problem."
    ],
    "delay": [
      "Draw under the ball. Gravity can handle the paperwork."
    ],
    "scorecard": [
      "You made a line become a ramp. That is the whole trick."
    ]
  },
  "assets": {
    "style": "flat_vector",
    "shapes": [
      "ball",
      "cup",
      "freehand_stroke",
      "goal_zone"
    ]
  },
  "uqiq_moment": "The player learns that a drawn line becomes physical enough to move the ball."
}
```

## Forgiveness

The acceptable solution should be broad:

- Rising ramps from left-to-right should work across a wide angle range.
- The ramp should not need to start at an exact pixel.
- The cup zone should be padded enough that near-misses still feel fair.
- Short strokes should fail before release with a clear message.
- A valid-looking failed ramp should reset quickly and invite another draw.

Failure copy should explain physics state, not insult execution:

```text
Too short. Give the ball something real to roll on.
```

```text
Missed the cup. Try lifting the end closer to the goal.
```

## Implementation Notes

Level 1 should use the future `freehand_physics_then_release` path from the realish physics prototype contract.

Minimum build shape:

- `Line2D` for the stroke.
- `StaticBody2D` segment colliders for the stroke.
- `RigidBody2D` ball or equivalent simple physics body.
- `Area2D` cup zone.
- Runtime owner node that clears old stroke/body state on reset.
- `InputEventScreenTouch` and `InputEventScreenDrag` as the primary path.

Keep this separate from the old `direct_draw_line_then_release` classifier path until the new path is stable.

## Verification

A future implementation issue should prove:

- Level 1 no longer uses Tap Logic or answer-choice UI.
- Level 1 renders a freehand physics playfield.
- Touch press/drag/release creates a thick visible stroke.
- The stroke creates collision geometry.
- `Release` starts ball motion.
- A broad rising ramp reaches the cup.
- A too-short line fails.
- A bad flat line fails.
- Reset clears old stroke/collision/ball state.
- Completion advances the six-level prototype flow.
- Physical iPhone smoke shows the level is playable in portrait with safe-area margins.

## Non-Goals

- No trick wording in Level 1.
- No score tuning.
- No Dur Token behavior.
- No Score Roastcard polish.
- No multi-object physics.
- No multi-stroke drawing.
- No full 60-Level compatibility requirement for this proof.
