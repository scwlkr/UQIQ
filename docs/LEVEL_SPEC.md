# Level Spec

UQIQ v1.0 stores Level Specs as JSON, one Pack Level File per Level Pack.

## Required Fields

Each Level Spec includes:

- `id`: Stable unique id.
- `pack_id`: Stable Level Pack id.
- `level_number`: Global 1-60 Level number.
- `title`: Player-facing Level title.
- `template`: Level Template name.
- `challenge_type`: Challenge Type label.
- `completion_mode`: How the Level completes.
- `prompt`: Player-facing prompt or setup text.
- `rules`: The mechanic rules needed to run the Level.
- `solution`: The target solution or win condition.
- `scoring`: Speed/action/Roast thresholds for UQIQ Score.
- `roasts`: Failure, delay/help, and Score Roastcard lines.
- `assets`: Flat Vector Style asset references or inline shape needs.
- `uqiq_moment`: The Level's memorable twist.

## Pack Level File

Each Pack Level File contains exactly 10 Level Specs.

Example path:

```text
content/levels/pack_01_orientation_is_a_trap.json
```
