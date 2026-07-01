# UQIQ Context

UQIQ is a fake-IQ mobile puzzle game where each playable puzzle should make the player feel clever, judged, confused, and determined without presenting itself as a real IQ test.

## Language

**Level**:
One playable puzzle instance the player can complete, fail, retry, skip, or share.
_Avoid_: Problem, puzzle, stage

**Level Spec**:
The design record for a Level: identity, Level Pack, Challenge Type, title, content, rules, target solution, scoring thresholds, Roast text, and asset/style references.
_Avoid_: Level script, puzzle doc, content row

**Versioned Level Content**:
Level Specs and supporting content stored in the app repo and shipped inside the app binary for v1.0.
_Avoid_: CMS content, remote levels, spreadsheet source of truth

**Level Template**:
A reusable playable structure that multiple Levels can share, such as a tap-order puzzle, drag-object puzzle, memory reveal puzzle, or timing puzzle. v1.0 should use about six Level Templates rather than treating every Level as a one-off.
_Avoid_: Level engine, mechanic engine, custom level script

**Tap Logic**:
A Level Template where the solution depends on tapping the correct, wrong, hidden, or counterintuitive target.
_Avoid_: Tap level, button puzzle

**Drag Logic**:
A Level Template where the solution depends on dragging an object, text, or UI element into a meaningful position.
_Avoid_: Drag level, move puzzle

**Text Trap**:
A Level Template where the solution depends on interpreting, disobeying, or reframing a written prompt.
_Avoid_: Word problem, trick question

**Pattern Grid**:
A Level Template where the solution depends on visual sequence, odd-one-out, grouping, or pattern recognition.
_Avoid_: Pattern puzzle, grid puzzle

**Memory Flash**:
A Level Template where the player briefly sees information, then must recall order, position, identity, or count.
_Avoid_: Memory puzzle, recall level

**Physics Draw**:
A Level Template where the player draws or places simple geometry so a physics object reaches a target.
_Avoid_: Physics level, ball puzzle, draw puzzle

**Chaos Modifier**:
A modifier that adds timing, movement, fake pressure, or disruptive behavior to another Level Template. It is not a v1.0 Level Template by itself.
_Avoid_: Timing/Chaos template, chaos level

**No Global Timer**:
The pacing rule that UQIQ does not place every Level under visible time pressure. Speed can affect UQIQ Score, and specific Levels can use a Chaos Modifier, but the game is not globally timed.
_Avoid_: Timed game, countdown mode, speedrun mode

**Level Pack**:
A grouped set of 10 Levels with a loose theme and internal difficulty curve.
_Avoid_: World, chapter, batch

**Pack Title Card**:
A short savage intro shown when a Level Pack begins. It adds tone without creating a story mode or cutscene system.
_Avoid_: Cutscene, story intro, chapter narrative

**Primary Template**:
The main Level Template for a Level Pack. Each v1.0 Level Pack has one Primary Template and mixes in a small number of Levels from other Templates to avoid repetition.
_Avoid_: Pack engine, pack mechanic

**Linear Unlock**:
The v1.0 progression rule: completing or DUR'ing a Level unlocks the next Level. Level Packs are visible milestones every 10 Levels rather than separate gates.
_Avoid_: Pack unlock, world gate, branching map

**Level List**:
The v1.0 navigation surface: a single vertical list grouped by Level Pack, showing locked, completed, and DUR'D states plus UQIQ Score and Dur Tokens.
_Avoid_: World map, overworld, chapter select

**Play Screen**:
The main Level surface: a top bar for UQIQ Score, Level number, and Dur Tokens; a center stage for Level content; and bottom actions such as submit, reset, or Roast when relevant. The Judge Face appears as feedback rather than occupying permanent space.
_Avoid_: Game screen, puzzle screen, question screen

**Portrait Only**:
The v1.0 orientation constraint: UQIQ runs in portrait orientation only, including Physics Draw Levels.
_Avoid_: Landscape support, responsive orientation, rotation support

**Phone-Only Launch**:
The v1.0 device scope: optimize and release for phones first. iPad-specific layout and experience work is out of scope until after launch.
_Avoid_: Universal launch, iPad launch, tablet mode

**Review-Minimum Usability**:
The v1.0 accessibility scope: do only what is needed to keep the app complete, stable, readable, tappable, and reviewable for App Store approval. UQIQ does not take on extra accessibility work beyond that in v1.0.
_Avoid_: Accessibility roadmap, full VoiceOver support, extra accessibility pass

**Completion Mode**:
How a Level ends after the player reaches or chooses a solution. Tap Logic, Drag Logic, and Physics Draw may auto-complete; Text Trap, Pattern Grid, and Memory Flash usually use submit.
_Avoid_: Submit behavior, auto-submit rule

**Orientation Is a Trap**:
The first Level Pack. It teaches that UQIQ is not a normal quiz app through easy wins and trick interactions, without physics-heavy Levels.
_Avoid_: Tutorial, intro pack, onboarding

**Words Are Lying**:
The Text Trap Primary Template Level Pack.
_Avoid_: Word pack, text pack

**Move the Wrong Thing**:
The Drag Logic Primary Template Level Pack.
_Avoid_: Drag pack, movement pack

**Pattern Crimes**:
The Pattern Grid Primary Template Level Pack.
_Avoid_: Pattern pack, sequence pack

**Brain Buffer Full**:
The Memory Flash Primary Template Level Pack.
_Avoid_: Memory pack, recall pack

**Gravity Is Fake**:
The Physics Draw Primary Template Level Pack.
_Avoid_: Physics pack, gravity pack

**Into the Fire**:
The onboarding stance for UQIQ: throw the player directly into playable Levels with no tutorial text.
_Avoid_: Tutorial, walkthrough, explanation

**Challenge Type**:
The mechanic family a Level belongs to, such as logic trap, word puzzle, pattern puzzle, memory challenge, physics puzzle, timed challenge, or chaos round.
_Avoid_: Level type, mode

**Dur Token**:
A limited skip token. v1.0 gives the player 3 total Dur Tokens across the full curated offline level pack.
_Avoid_: Skip, skip token, pass

**DUR'D**:
The state of a Level that was bypassed with a Dur Token and still needs to be completed. Completing a DUR'D Level returns the spent Dur Token.
_Avoid_: Skipped, passed, incomplete

**UQIQ Score**:
The visible player score, formatted exactly like `UQIQ 100`. It is loosely based on real performance signals such as Levels completed, completion speed, and action efficiency, clamped to the absurd visible range `UQIQ -20` through `UQIQ 420`, but it is a game score rather than a real intelligence measurement.
_Avoid_: IQ score, rating, rank

**Local UQIQ Score**:
The v1.0 score scope: UQIQ Score is stored and shown locally only, with no Game Center leaderboards or achievements.
_Avoid_: Global leaderboard, Game Center score, online ranking

**Score Roastcard**:
The compact post-Level score breakdown showing funny scoring deltas such as speed, action count, Roast penalty, and absurd flavor labels without exposing the full formula.
_Avoid_: Score report, detailed formula, result screen

**Final Roastcard**:
The post-Level-60 ending screen showing final UQIQ Score, a savage certificate-style result, and a replay prompt.
_Avoid_: Ending cutscene, story finale, credits sequence

**Best Attempt**:
The strongest completed performance for a Level. UQIQ Score uses Best Attempts so replays can improve the score and bad early attempts do not permanently punish the player.
_Avoid_: First attempt, latest attempt

**Replay**:
A repeat attempt on an unlocked Level. Replays can improve Best Attempt and UQIQ Score but do not change Linear Unlock order.
_Avoid_: Retry, rematch, practice

**Attempt Metrics**:
The shared performance signals every Level reports for scoring: completion state, duration, action count, hint usage, and Dur Token usage.
_Avoid_: Telemetry, analytics, stats

**Roast**:
A mocking hint offered after repeated failure or delay. A Roast helps the player solve the Level but lowers that Level's Best Attempt contribution.
_Avoid_: Hint, clue, help

**Savage Roast Boundary**:
The tone rule for UQIQ's harsh comedy: ridicule the player's in-game performance and fictional UQIQ persona as hard as possible while avoiding protected traits, real-world identity, disability, body, age, race, gender, sexuality, religion, self-harm, sexual content, realistic violence, and real clinical intelligence claims.
_Avoid_: Friendly hint, targeted insult, hate content

**Clean Savage Roast**:
A harsh but non-profane UQIQ insult built from absurd phrases such as dingleberry, hot breath, or smooth brain. v1.0 avoids direct profanity and protected-class slurs.
_Avoid_: Profanity, real slur, hate speech

**UQIQ Moment**:
The memorable twist each Level must include, such as trick wording, unexpected interaction, funny failure, visual gag, or scoring surprise.
_Avoid_: Generic puzzle, straightforward skill check

**Mostly Finishable, Occasionally Humiliating**:
The v1.0 difficulty posture: average players should be able to finish all 60 Levels with 3 Dur Tokens and some Roasts, while still feeling tricked, mocked, and challenged.
_Avoid_: Stuck forever, trivial, hardcore puzzle difficulty

**12+ Rating Target**:
The intended App Store age-rating posture for v1.0. The final rating comes from Apple's questionnaire, but UQIQ should avoid content that would push the game toward 17+.
_Avoid_: 4+ target, 17+ target

**Privacy Page**:
The basic static policy/support page for App Store submission, hosted at `https://uqiq.wlkrlabs.com/privacy`.
_Avoid_: Privacy portal, support site, legal site

**Context-Aware Roast**:
A Clean Savage Roast selected from the player's in-game behavior, such as answering too fast, taking too long, failing repeatedly, using a Roast, or spending a Dur Token.
_Avoid_: Random insult, generic flavor text

**Fail Loop**:
The repeated experience after an unsuccessful Level attempt: immediate feedback, funny judgment, and instant retry. v1.0 has no lives, cooldowns, or forced ads.
_Avoid_: Death loop, loss state, fail state

**Flat Vector Style**:
The visual style for UQIQ: bold shapes, minimalist geometry, vibrant color palettes, and 2D vector art. It avoids gradients, textures, and complex shadows so the game stays scalable, clean, and mobile-friendly.
_Avoid_: Fake test-room theme, realistic art, textured art, complex shadows

**Self-Generated Art Pipeline**:
The v1.0 art production approach: the assistant creates and maintains the art through Godot-authored flat primitives, reusable scenes, and small generated SVG/icon assets when needed. The user should not need to manually create art.
_Avoid_: Manual art pass, outsourced art, hand-drawn asset dependency

**Development-Only AI**:
AI used during production for references, drafts, art prompts, insult banks, or Level ideas. v1.0 ships deterministic offline content and does not include AI runtime behavior.
_Avoid_: In-app AI, generated live content, AI level generation

**Godot Client**:
The v1.0 app implementation target: Godot 4.x game/client, versioned Level Specs, and local save data for the Local Profile.
_Avoid_: Native Swift app, backend-first app, web app

**Judge Face**:
A simple flat geometric mascot that reacts to wins, failures, and Roasts. It gives UQIQ personality without requiring a large illustrated character-art pipeline.
_Avoid_: Mascot, character, avatar

**Problem**:
The prompt or question-like content inside a Level when that Level uses question-like material. Not every Level has a Problem.
_Avoid_: Level, challenge

**v1.0 App Store Promise**:
The first public iOS release commitment: a curated offline level pack with local progress and no accounts, backend, user-created levels, or daily challenge.
_Avoid_: MVP, beta scope, launch scope

**Vertical Slice**:
The first playable proof of the whole UQIQ loop: one Level per Level Template, Level List, Play Screen, Local Profile, UQIQ Score placeholder, Dur Tokens, Roasts, Judge Face, and Flat Vector Style.
_Avoid_: Prototype, demo, first build

**Offline Play**:
The v1.0 availability rule: the full curated level pack is playable without internet. Network access, if present, is only for crash reporting and Anonymous Level Events.
_Avoid_: Online requirement, connected play, server-gated play

**Local Profile**:
The single on-device save record for v1.0. It owns unlocked Level, completed Levels, DUR'D Levels, Dur Tokens remaining, Best Attempts, UQIQ Score inputs, and settings.
_Avoid_: Account, user profile, cloud save

**v1.0 Monetization**:
The first public iOS release is free with no ads and no in-app purchases.
_Avoid_: Ad-supported launch, paid launch, launch IAP

**Anonymous Level Event**:
A privacy-light gameplay event that records Level activity without player identity, such as started, completed, failed, DUR'D, or Roast used.
_Avoid_: User analytics, tracking, profile event
