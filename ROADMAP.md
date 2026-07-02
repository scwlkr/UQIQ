# UQIQ Roadmap

## Current Goal

Prove UQIQ as a tactile, phone-first puzzle game with a polished six-Level prototype before adding more content or resuming App Store release work.

The old 60-Level v1.0 path is parked until the six-Level core feels good on a physical iPhone and scwlkr approves the direction.

## Roadmap

1. **Planning Docs**
   - Maintain `CONTEXT.md` as the domain glossary.
   - Record hard-to-reverse decisions in `docs/adr/`.
   - Manage work through `docs/PROJECT_CYCLE.md`: Roadmap -> PRD -> GitHub Issue -> Next Step.
   - Keep the active PRD and active `next-step` issue named in `docs/RELEASE_STATUS.md`.

2. **Existing Godot Baseline**
   - Keep the current Godot 4.x project, portrait phone-only constraints, Flat Vector Style foundation, Judge Face, Level List, Play Screen, Local Profile, UQIQ Score placeholder, Dur Tokens, Roasts, Replay, and local verification floor.
   - Treat the existing 60-Level content and App Store draft assets as historical scaffolding, not the active product target.

3. **Polished Six-Level Core Prototype** _(active)_
   - Build six excellent tactile Levels:
     1. `First Ramp` - draw a ramp so the ball reaches the cup.
     2. `Brake Check` - draw a stopper so the ball drops into the cup.
     3. `Goalposts Are Portable` - drag the cup into the ball path.
     4. `Gravity Has Handles` - drag `GRAVITY` to change the physics direction.
     5. `Cup Blinks First` - remember a hidden cup, then draw toward it.
     6. `Remember the Pull` - remember a direction, then move `GRAVITY`.
   - Prefer realish, forgiving physics and direct touch interaction over answer-choice UI.
   - Done when all six Levels are playable on desktop and physical iPhone, have focused verifier coverage, reset cleanly, and scwlkr approves the phone feel.

4. **Core Feedback and Tuning**
   - Add only the feedback needed to make the six-Level prototype readable: success, failure, reset, lightweight Judge Face reactions, and minimal haptics/audio if cheap.
   - Keep UQIQ Score, Dur Token loops, Score Roastcards, 60-Level content expansion, and final Roast systems parked unless they directly help evaluate the six-Level core.

5. **Prototype TestFlight Gate**
   - Export the six-Level prototype through the Godot/Xcode path.
   - Test on physical iPhones.
   - Use internal TestFlight only if local phone proof is strong enough and scwlkr approves.
   - Ask testers only about crashes, stuck/confusing Levels, unfun Levels, unreadable/tiny UI, and whether the tactile core is promising.

6. **v1.0 Scope Decision**
   - After the six-Level core is proven or rejected, decide final v1.0 scope:
     - final Level count,
     - whether 60 curated Levels still makes sense,
     - role of UQIQ Score, Dur Tokens, Roastcards, and Judge Face,
     - asset/audio/haptic direction,
     - App Store/TestFlight release path.

7. **Parked v1.0 Production Path**
   - Content Factory, full polish pass, App Store metadata, external TestFlight, App Review, live hosting/DNS, and public release remain parked until the v1.0 scope decision reopens them.
