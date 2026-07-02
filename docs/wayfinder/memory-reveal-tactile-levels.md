# Memory-Reveal Tactile Levels

Parent ticket: https://github.com/scwlkr/UQIQ/issues/60

## Decision

The two Memory/Reveal Levels should use brief reveal as a setup for tactile physics, not as a standalone sequence-recall task.

- Level 5: `Cup Blinks First` - briefly reveal the hidden cup, then draw a physical path to where it was.
- Level 6: `Remember the Pull` - briefly reveal the correct gravity wall, then move the `GRAVITY` tile there before release.

Together they teach two Memory/Reveal ideas:

- Memory can guide Freehand Physics Drawing.
- Memory can guide Physics-Linked Rearrange.

Both Levels should use new interaction models:

```text
reveal_then_freehand_physics
reveal_then_physics_linked_rearrange
```

The reveal must change the physical solve. It should not resolve as tile-order recall.

## Shared Rules

Both Memory/Reveal Levels should:

- Auto-reveal the key information briefly at Level start.
- Let the player tap `Reveal` once more if needed during prototype tuning.
- Hide the key information before the main tactile action.
- Use direct touch input on the playfield.
- Start physics only after the player taps `Release`.
- Complete by physical overlap between a moving object and a goal zone.
- Fail with visible physics feedback, then reset quickly.
- Avoid list-style answer buttons and pure sequence submit.

Recommended first-pass reveal timing:

```text
auto_reveal_seconds: 1.1
optional_reveal_count: 1
post_reveal_lockout: none
```

## Level 5: Cup Blinks First

### Player-Facing Level

Title:

```text
Cup Blinks First
```

Prompt:

```text
Remember the cup. Draw to where it was.
```

Player experience:

1. The player sees a ball at lower-left and a cup briefly glowing at upper-right.
2. The cup hides, leaving only a faint empty playfield and the ball.
3. The player draws one freehand ramp or guide toward the remembered cup location.
4. The player taps `Release`.
5. The ball rolls along the drawn stroke toward the hidden cup.
6. On success, the cup reappears as the ball overlaps it.
7. On failure, the cup briefly flashes again to explain the miss.

The UQIQ Moment is that the target is not visible while drawing, so the player must use memory to place a physical path.

### Layout

Target portrait playfield: current phone-sized Godot viewport, `390x844`.

Suggested playfield coordinate model:

```text
playfield: 340w x 300h
ball_start: (58, 224)
ball_radius: 16
hidden_cup_zone: (248, 130, 58, 56)
ghost_cup_flash_seconds: 1.1
draw_area: whole playfield except top instruction/header padding
gravity: downward
```

Visuals:

- Cup flashes as a bright outline, then hides.
- Hidden cup leaves no permanent outline in the first pass.
- Drawn stroke stays thick and high-contrast.
- Success makes the cup pop back in at the remembered location.
- Failure flashes the true cup location for quick learning.

### Level Spec Draft

```json
{
  "id": "core_l05_cup_blinks_first",
  "pack_id": "six_level_core",
  "level_number": 5,
  "title": "Cup Blinks First",
  "template": "Memory/Reveal Level",
  "challenge_type": "physics puzzle",
  "completion_mode": "auto_complete_on_goal_overlap",
  "prompt": "Remember the cup. Draw to where it was.",
  "rules": {
    "interaction_model": "reveal_then_freehand_physics",
    "reveal": {
      "auto_reveal_seconds": 1.1,
      "optional_reveal_count": 1,
      "revealed_items": [
        {
          "id": "hidden_cup",
          "type": "goal_zone",
          "rect": [248, 130, 58, 56]
        }
      ],
      "hide_before_action": true
    },
    "moving_object": {
      "id": "ball",
      "shape": "circle",
      "start": [58, 224],
      "radius": 16
    },
    "goal_zone": {
      "id": "hidden_cup",
      "rect": [248, 130, 58, 56],
      "forgiveness_px": 18,
      "visible_during_action": false
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
    "success_condition": "ball overlaps the hidden cup goal zone after release",
    "intended_strategy": "remember the flashed cup position and draw a rising ramp or guide toward it",
    "common_wrong_strategy": "draw toward the visible empty space or treat the reveal as a sequence recall",
    "not_allowed": "memory tile order submit"
  },
  "scoring": {
    "prototype": true
  },
  "roasts": {
    "failure": [
      "The cup blinked and your plan blinked harder."
    ],
    "delay": [
      "It showed you the cup. Briefly. Like mercy, but smaller."
    ],
    "scorecard": [
      "You drew at a memory and physics accepted the paperwork."
    ]
  },
  "assets": {
    "style": "flat_vector",
    "shapes": [
      "ball",
      "hidden_cup",
      "ghost_cup_flash",
      "freehand_stroke"
    ]
  },
  "uqiq_moment": "The player draws toward a goal that only existed on screen for a blink."
}
```

### Forgiveness

- The hidden cup should be physically padded.
- The valid ramp range should be broad.
- The one optional reveal should keep the Level from becoming a hard memory test.
- Failure should briefly show the hidden cup again.
- Reset should preserve the feeling that a better draw will work.

Failure copy:

```text
Missed the hidden cup. It was less there than your confidence.
```

```text
Too short. Memory is not a load-bearing structure.
```

## Level 6: Remember the Pull

### Player-Facing Level

Title:

```text
Remember the Pull
```

Prompt:

```text
Remember the arrow. Move GRAVITY there.
```

Player experience:

1. The player sees a ball near center and three wall/floor gravity slots.
2. A bright arrow briefly flashes toward the correct wall.
3. The arrow hides.
4. The player drags the `GRAVITY` tile to the remembered slot.
5. The player taps `Release`.
6. The ball falls in the remembered direction into the cup.
7. Wrong slots make the ball fall away, then the Level resets and re-flashes.

The UQIQ Moment is that the remembered reveal changes the rule the player applies, and the ball physically obeys that remembered rule.

### Layout

Target portrait playfield: current phone-sized Godot viewport, `390x844`.

Suggested playfield coordinate model:

```text
playfield: 340w x 300h
ball_start: (132, 156)
ball_radius: 16
cup_zone: (272, 128, 52, 64)
gravity_tile_start: (122, 236, 108, 46)
revealed_arrow: right
reveal_seconds: 1.1
gravity_slots:
  floor: (112, 238, 126, 46) -> vector [0, 720]
  left_wall: (18, 126, 72, 70) -> vector [-720, 0]
  right_wall: (250, 126, 72, 70) -> vector [720, 0]
```

Visuals:

- The reveal arrow should be large and directional.
- Slots should remain visible after the arrow hides.
- The cup can stay visible; the memory target is the correct pull direction.
- The `GRAVITY` tile should snap to the nearest slot.
- The selected slot should pulse before release.

### Level Spec Draft

```json
{
  "id": "core_l06_remember_the_pull",
  "pack_id": "six_level_core",
  "level_number": 6,
  "title": "Remember the Pull",
  "template": "Memory/Reveal Level",
  "challenge_type": "physics puzzle",
  "completion_mode": "auto_complete_on_goal_overlap",
  "prompt": "Remember the arrow. Move GRAVITY there.",
  "rules": {
    "interaction_model": "reveal_then_physics_linked_rearrange",
    "reveal": {
      "auto_reveal_seconds": 1.1,
      "optional_reveal_count": 1,
      "revealed_items": [
        {
          "id": "pull_arrow",
          "type": "direction",
          "direction": "right",
          "target_slot_id": "right_wall_slot"
        }
      ],
      "hide_before_action": true
    },
    "moving_object": {
      "id": "ball",
      "shape": "circle",
      "start": [132, 156],
      "radius": 16
    },
    "goal_zone": {
      "id": "right_wall_cup",
      "rect": [272, 128, 52, 64],
      "forgiveness_px": 16
    },
    "draggable_objects": [
      {
        "id": "gravity_tile",
        "label": "GRAVITY",
        "role": "rule_tile",
        "start_rect": [122, 236, 108, 46]
      }
    ],
    "drop_targets": [
      {
        "id": "floor_slot",
        "label": "down",
        "rect": [112, 238, 126, 46],
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
    "success_condition": "ball overlaps the right-wall cup after release under the remembered gravity slot",
    "intended_strategy": "remember the flashed arrow and drag GRAVITY to the matching slot before release",
    "common_wrong_strategy": "choose the obvious floor slot after the arrow hides",
    "not_allowed": "sequence recall or answer-choice direction buttons"
  },
  "scoring": {
    "prototype": true
  },
  "roasts": {
    "failure": [
      "The arrow told you. Then your memory unplugged the map."
    ],
    "delay": [
      "Move GRAVITY where the arrow pointed. The universe left a receipt."
    ],
    "scorecard": [
      "You remembered a direction and made falling file a change request."
    ]
  },
  "assets": {
    "style": "flat_vector",
    "shapes": [
      "ball",
      "right_wall_cup",
      "gravity_tile",
      "gravity_slots",
      "reveal_arrow"
    ]
  },
  "uqiq_moment": "The player remembers a flashed direction, moves GRAVITY there, and watches the ball fall sideways into the cup."
}
```

### Forgiveness

- Slot targets should be large.
- The `GRAVITY` tile should snap to the nearest slot.
- The optional reveal should be available once before release.
- Wrong gravity should visibly move the ball the wrong way.
- Reset should restore the tile and re-flash the arrow.

Failure copy:

```text
Wrong pull. Gravity followed your memory off a tiny cliff.
```

```text
The arrow was right. You were decorative.
```

## Implementation Notes

These Levels should build on the planned Draw/Shape and Physics-Linked Rearrange systems rather than the current `direct_memory_tiles` sequence UI.

Minimum build shape:

- A reveal layer that can show/hide target information on a timer.
- One optional `Reveal` action during prototype tuning.
- `Line2D` plus stroke colliders for Level 5.
- Draggable `GRAVITY` rule tile and slot snapping for Level 6.
- `RigidBody2D` or equivalent ball/token.
- `Area2D` goal zone.
- A `Release` action that starts simulation after reveal/draw/rearrange.
- Reset clears reveal state, drawing, moved rule tile, ball state, and transient feedback.

The loop should stay:

```text
brief reveal -> tactile action -> release -> watch physics -> retry or complete
```

## Verification

A future implementation issue should prove:

- Level 5 briefly reveals the hidden cup, hides it, then accepts a freehand draw.
- Level 5 completes only when the ball physically overlaps the hidden cup after release.
- Level 5 failure re-reveals the cup briefly.
- Level 6 briefly reveals a direction arrow, hides it, then accepts GRAVITY tile dragging.
- Level 6 changes ball motion based on the remembered selected slot.
- Level 6 completes only when the right-wall gravity choice moves the ball into the cup.
- Both Levels avoid pure sequence-recall UI and list-style answer buttons.
- Both Levels support `InputEventScreenTouch` and `InputEventScreenDrag`.
- Both Levels reset without stale reveal, physics, draw, or dragged-object state.
- Both Levels fit portrait phone safe-area margins.

## Non-Goals

- No long memory sequences.
- No hidden scoring complexity.
- No strict timer pressure after the reveal.
- No multi-object physics puzzles.
- No score tuning.
- No Dur Token behavior.
- No Score Roastcard polish.
- No full 60-Level compatibility requirement for this proof.
