# Physics-Linked Rearrange Levels

Parent ticket: https://github.com/scwlkr/UQIQ/issues/62

## Decision

The two Rearrange Levels should transfer the Draw/Shape spine into direct manipulation without becoming static drag/drop sorting.

- Level 3: `Goalposts Are Portable` - drag the cup/goal zone into the ball's real path before release.
- Level 4: `Gravity Has Handles` - drag the `GRAVITY` rule tile to the side that should pull the ball into the cup.

Together they teach two different Rearrange ideas:

- Physical setup can be moved.
- A label/rule tile can change what the physics means.

Both Levels should use a new interaction model:

```text
physics_linked_rearrange_then_release
```

The rearrange action must change the physics outcome. It should not resolve as ordinary drag/drop answer validation.

## Shared Rules

Both Rearrange Levels should:

- Use direct touch drag on the playfield.
- Treat `InputEventScreenTouch` and `InputEventScreenDrag` as the primary input path.
- Keep mouse input only for desktop/dev verification.
- Give large draggable objects and large drop/catch zones.
- Start physics only after the player taps `Release`.
- Complete by physical overlap between a moving object and a goal zone.
- Fail with visible physics feedback, then reset quickly.
- Avoid `draw_options` and avoid list-style answer buttons.

## Level 3: Goalposts Are Portable

### Player-Facing Level

Title:

```text
Goalposts Are Portable
```

Prompt:

```text
Move the cup where the ball is actually going.
```

Player experience:

1. The player sees a ball on a fixed left-side chute.
2. The cup starts in an obvious but wrong lower-right position.
3. A faint dotted landing marker sits under the ball's natural path.
4. The player drags the cup to that landing area.
5. The player taps `Release`.
6. The ball rolls/falls along the fixed setup into the moved cup.
7. Completion feedback appears quickly and advances the six-level prototype flow.

The UQIQ Moment is that the player solves the physics by moving the finish line, not by moving the ball or drawing another path.

### Layout

Target portrait playfield: current phone-sized Godot viewport, `390x844`.

Suggested playfield coordinate model:

```text
playfield: 340w x 300h
ball_start: (72, 88)
ball_radius: 16
starter_chute: from (44, 108) to (166, 144)
wrong_cup_start: (260, 214, 58, 52)
catch_zone_hint: (188, 214, 74, 58)
cup_allowed_drag_rect: (36, 156, 268, 112)
gravity: downward
```

Visuals:

- Ball is a readable filled circle.
- Starter chute is fixed and visibly not draggable.
- Cup has a clear handle or outline while dragging.
- Catch-zone hint is subtle, not a full solution arrow.
- Release button stays disabled or visually muted until the cup has been moved at least once.

### Level Spec Draft

```json
{
  "id": "core_l03_goalposts_are_portable",
  "pack_id": "six_level_core",
  "level_number": 3,
  "title": "Goalposts Are Portable",
  "template": "Rearrange Level",
  "challenge_type": "physics puzzle",
  "completion_mode": "auto_complete_on_goal_overlap",
  "prompt": "Move the cup where the ball is actually going.",
  "rules": {
    "interaction_model": "physics_linked_rearrange_then_release",
    "rearrange_mode": "move_goal_marker",
    "moving_object": {
      "id": "ball",
      "shape": "circle",
      "start": [72, 88],
      "radius": 16,
      "initial_state": "resting_on_starter_chute"
    },
    "built_in_geometry": [
      {
        "id": "starter_chute",
        "type": "static_segment",
        "points": [[44, 108], [166, 144]],
        "collision_thickness_px": 12
      }
    ],
    "draggable_objects": [
      {
        "id": "cup",
        "label": "CUP",
        "role": "goal_zone",
        "start_rect": [260, 214, 58, 52],
        "allowed_drag_rect": [36, 156, 268, 112]
      }
    ],
    "target_placement": {
      "id": "catch_zone_hint",
      "rect": [188, 214, 74, 58],
      "forgiveness_px": 18
    },
    "simulation_limit_seconds": 4,
    "reset_on_failure": true
  },
  "solution": {
    "success_condition": "ball overlaps the moved cup goal zone after release",
    "intended_strategy": "drag the cup into the ball's natural landing path before release",
    "common_wrong_strategy": "try to drag the ball, draw a path, or leave the cup in its starting position",
    "not_allowed": "static drag/drop answer validation"
  },
  "scoring": {
    "prototype": true
  },
  "roasts": {
    "failure": [
      "The ball went exactly where physics said. Your cup filed a complaint elsewhere."
    ],
    "delay": [
      "The cup is the movable part. Shocking governance failure."
    ],
    "scorecard": [
      "You moved the finish line and called it intelligence."
    ]
  },
  "assets": {
    "style": "flat_vector",
    "shapes": [
      "ball",
      "starter_chute",
      "draggable_cup",
      "catch_zone_hint"
    ]
  },
  "uqiq_moment": "The player realizes the target is movable and solves by relocating the cup into the physical path."
}
```

### Forgiveness

- The cup should snap or softly settle into the catch area when close.
- The catch area should be bigger than the visible cup.
- The ball path should be slow and readable.
- Dropping the cup slightly off-center should still catch.
- Failure should show the ball missing the cup, not silently reject the placement.

Failure copy:

```text
Missed. The cup was decorative over there.
```

```text
Move the cup under the fall, not near your hopes.
```

## Level 4: Gravity Has Handles

### Player-Facing Level

Title:

```text
Gravity Has Handles
```

Prompt:

```text
Move GRAVITY to the wall with the cup.
```

Player experience:

1. The player sees a ball near the center-left of the playfield.
2. The cup sits on the right wall.
3. A `GRAVITY` tile starts in the bottom/floor slot.
4. The player drags `GRAVITY` to the right-wall slot.
5. The player taps `Release`.
6. The ball falls sideways into the cup.
7. Wrong slots make the ball fall away from the cup, then reset.

The UQIQ Moment is that moving a label changes the physics rule, not just the UI wording.

### Layout

Target portrait playfield: current phone-sized Godot viewport, `390x844`.

Suggested playfield coordinate model:

```text
playfield: 340w x 300h
ball_start: (112, 150)
ball_radius: 16
cup_zone: (274, 128, 52, 64)
gravity_tile_start: (132, 236, 96, 46)
gravity_slots:
  floor: (122, 238, 116, 46) -> vector [0, 720]
  left_wall: (18, 126, 72, 70) -> vector [-720, 0]
  right_wall: (250, 126, 72, 70) -> vector [720, 0]
```

Visuals:

- Cup is attached to the right wall.
- `GRAVITY` tile is large enough to drag with a thumb.
- Slots use arrows or wall outlines, not dense text.
- The selected gravity vector should pulse briefly before release.

### Level Spec Draft

```json
{
  "id": "core_l04_gravity_has_handles",
  "pack_id": "six_level_core",
  "level_number": 4,
  "title": "Gravity Has Handles",
  "template": "Rearrange Level",
  "challenge_type": "physics puzzle",
  "completion_mode": "auto_complete_on_goal_overlap",
  "prompt": "Move GRAVITY to the wall with the cup.",
  "rules": {
    "interaction_model": "physics_linked_rearrange_then_release",
    "rearrange_mode": "move_rule_tile",
    "moving_object": {
      "id": "ball",
      "shape": "circle",
      "start": [112, 150],
      "radius": 16
    },
    "goal_zone": {
      "id": "right_wall_cup",
      "rect": [274, 128, 52, 64],
      "forgiveness_px": 16
    },
    "draggable_objects": [
      {
        "id": "gravity_tile",
        "label": "GRAVITY",
        "role": "rule_tile",
        "start_rect": [132, 236, 96, 46]
      }
    ],
    "drop_targets": [
      {
        "id": "floor_slot",
        "label": "down",
        "rect": [122, 238, 116, 46],
        "gravity_vector": [0, 720],
        "role": "decoy"
      },
      {
        "id": "left_wall_slot",
        "label": "left",
        "rect": [18, 126, 72, 70],
        "gravity_vector": [-720, 0],
        "role": "decoy"
      },
      {
        "id": "right_wall_slot",
        "label": "right",
        "rect": [250, 126, 72, 70],
        "gravity_vector": [720, 0],
        "role": "correct"
      }
    ],
    "simulation_limit_seconds": 4,
    "reset_on_failure": true
  },
  "solution": {
    "success_condition": "ball overlaps the right-wall cup after release under the selected gravity vector",
    "intended_strategy": "drag GRAVITY into the right-wall slot before release",
    "common_wrong_strategy": "leave gravity on the floor or move it to the opposite wall",
    "not_allowed": "text-only rule choice without physics motion"
  },
  "scoring": {
    "prototype": true
  },
  "roasts": {
    "failure": [
      "Gravity obeyed you. That is the concerning part."
    ],
    "delay": [
      "The cup is on the wall. Try making falling stupider."
    ],
    "scorecard": [
      "You moved a word and bullied physics into compliance."
    ]
  },
  "assets": {
    "style": "flat_vector",
    "shapes": [
      "ball",
      "right_wall_cup",
      "gravity_tile",
      "gravity_slots",
      "direction_pulse"
    ]
  },
  "uqiq_moment": "The player drags the GRAVITY label to the right wall and the ball falls sideways into the cup."
}
```

### Forgiveness

- Drop slots should be large thumb zones.
- The `GRAVITY` tile should snap into a slot when close.
- If released outside a slot, the tile returns to its last valid slot.
- The right-wall cup should be padded enough to catch sideways motion.
- Wrong slots should produce visible physical failure.

Failure copy:

```text
Gravity went that way. The cup did not.
```

```text
Wrong wall. Excellent confidence, poor universe.
```

## Implementation Notes

These Levels should build on the current direct drag work but should not use the old pure object-target answer check as the final win condition.

Minimum build shape:

- `Control` or `Area2D` draggable objects during the rearrange phase.
- `InputEventScreenTouch` and `InputEventScreenDrag` for touch-first dragging.
- A `Release` action that locks rearrangement and starts the physics simulation.
- `RigidBody2D` or equivalent ball/token.
- `Area2D` goal zone, including moved goal state for Level 3.
- Mutable gravity vector or per-level force direction for Level 4.
- Reset clears moved objects, selected rule state, moving body state, and transient feedback.

Do not add multi-step editing, inventories, or separate confirmation dialogs. The loop should stay:

```text
drag one thing -> release -> watch physics -> retry or complete
```

## Verification

A future implementation issue should prove:

- Level 3 renders a draggable cup/goal marker in the playfield.
- Level 3 completes only when the moved cup catches the ball by physical overlap.
- Level 3 visibly fails when the cup stays in the wrong place.
- Level 4 renders a draggable `GRAVITY` rule tile and large wall/floor slots.
- Level 4 changes the ball's motion based on the selected gravity slot.
- Level 4 completes only when the right-wall gravity choice moves the ball into the right-wall cup.
- Both Levels use touch drag on iPhone, not list-style answer buttons.
- Both Levels reset without stale physics bodies or stale dragged-object state.
- Both Levels fit portrait phone safe-area margins.

## Non-Goals

- No freehand drawing in these two Levels.
- No multi-object physics puzzles.
- No precision slotting.
- No score tuning.
- No Dur Token behavior.
- No Score Roastcard polish.
- No full 60-Level compatibility requirement for this proof.
