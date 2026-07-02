# App Store Metadata Draft

Status: Draft for scwlkr review. Not submitted to App Store Connect.

## Source Notes

- Apple App Information: name max 30 characters, subtitle max 30 characters, Privacy Policy URL required for iOS.
- Apple Platform Version Information: keywords are limited to 100 bytes; Support URL must lead to real contact information.
- Apple Screenshot Specifications: upload 1-10 screenshots in `.jpeg`, `.jpg`, or `.png`; current 6.9-inch iPhone sizes include `1320 x 2868` portrait and `2868 x 1320` landscape.
- Apple App Privacy Details: disclose data collected by the app and third-party partners, including whether data is linked or used for tracking.
- Apple Age Ratings: App Store Connect generates the rating from questionnaire answers.

References:

- https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/

## Listing Draft

App name: `UQIQ`

Subtitle: `Puzzle Game for Giga Brains`

Promotional text:

```text
Sixty tiny puzzle traps. One fake brain score. Zero mercy from the Judge Face.
```

Description:

```text
UQIQ is a fast offline puzzle game about confidently being wrong.

Play 60 bite-size Levels across logic traps, word tricks, pattern grids, memory flashes, and fake physics. Every solve updates your UQIQ score, records your best attempt, and lets the Judge Face roast your choices.

UQIQ is not a real IQ test. It is a pocket-sized argument with your own attention span.

Features:
- 60 offline Levels across 6 themed packs
- Local progress, replay, best attempts, and unlocks
- UQIQ score range from -20 to 420
- Roasts, Dur Tokens, and score roastcards
- No accounts, ads, in-app purchases, Game Center, or in-app AI
```

Keywords draft, under 100 bytes:

```text
puzzle,logic,brain,offline,levels,tricks,riddles,patterns,memory,physics,roast
```

Category notes:

- Primary category: Games.
- Game subcategory candidate: Puzzle.
- Secondary candidate for scwlkr review: Trivia or Word.

Version notes:

```text
Initial release.
```

Copyright:

```text
2026 WLKRLABS
```

Support URL:

```text
https://uqiq.wlkrlabs.com/support
```

Privacy Policy URL:

```text
https://uqiq.wlkrlabs.com/privacy
```

Owner-review notes:

- See `docs/PRIVACY_SUPPORT_PAGE_DRAFT.md` for the page copy and hosting plan.
- The support URL must be live and include actual contact information before submission.
- The privacy URL must be live before submission.
- If scwlkr wants one combined page, `https://uqiq.wlkrlabs.com/support` can redirect to `https://uqiq.wlkrlabs.com/privacy#support` after that path is verified.

## Privacy Draft

Data collection answer:

```text
No, we do not collect data from this app.
```

Basis:

- UQIQ has no accounts, backend, ads, IAP, Game Center, in-app AI, analytics SDK, crash SDK, or tracking SDK.
- UQIQ stores Local Profile data only on device: unlocked Level, completed Levels, best attempts, Dur Tokens, DUR'D state, and UQIQ score.
- Current iOS export privacy strings state that camera, microphone, and photo library are not used in v1.0.
- Repo scan found no intentional app-side network, account, advertising, purchase, analytics, camera, microphone, or photo-library feature.

Do not submit this privacy answer if any SDK, analytics, crash reporting, web view, account feature, sharing feature, or support/contact form is added before review.

## Age-Rating Draft Inputs

Likely inputs for current app behavior:

- Kids Category: No.
- Made for ages 17 and under: No.
- Cartoon or fantasy violence: None.
- Realistic violence: None.
- Prolonged graphic or sadistic realistic violence: None.
- Profanity or crude humor: Infrequent/Mild, owner review needed because the game uses insult-style roasts.
- Mature or suggestive themes: None.
- Horror or fear themes: None.
- Medical or treatment information: None.
- Alcohol, tobacco, or drug references: None.
- Sexual content or nudity: None.
- Simulated gambling: None.
- Contests, gambling, or real-money purchases: None.
- User-generated content: No.
- Unrestricted web access: No.
- Messaging or chat: No.
- Location sharing: No.
- In-app purchases: No.

Content note:

- Current content has joke insults such as "smooth brain" and "one braincell"; no obvious profanity, gambling, sexual content, drug content, or graphic violence was found in the repo scan.

## Screenshot And Icon Checklist

Existing icon assets:

- `assets/icons/ios/app_store_1024x1024.png`
- iPhone/iPad icon slots are configured in `export_presets.cfg`.
- Icon proof: `sips` reports `1024 x 1024`.

Current proof screenshot:

- `/tmp/uqiq-testflight-installed-launch-proof.png`
- Size: `2868 x 1320`, which matches a 6.9-inch iPhone landscape screenshot size.

Draft App Store screenshot set:

- Generated by `godot --path . --script res://scripts/capture_app_store_screenshots.gd`.
- Output size: `1320 x 2868` each.
- The script captured a smaller Mac backing texture and resized to the 6.9-inch portrait draft size; use as draft assets, not final App Store upload without review.
- `docs/app-store/screenshots/01_level_list.png`
- `docs/app-store/screenshots/02_level_01_play.png`
- `docs/app-store/screenshots/03_pattern_grid.png`
- `docs/app-store/screenshots/04_memory_flash.png`
- `docs/app-store/screenshots/05_physics_draw.png`
- `docs/app-store/screenshots/06_score_roastcard.png`

Still needed before submission:

- Review or replace draft screenshots before upload; Scorecard and Physics Draw drafts show useful content but clip lower page content.
- Capture final App Store screenshots from the release/TestFlight build in the intended portrait presentation if scwlkr wants device-native assets instead of local draft captures.
- Recommended set: Level List, Level 01 play, a Pattern Grid level, a Memory Flash level, a Physics Draw level, and Score Roastcard.
- Verify whether App Store Connect accepts only the 6.9-inch iPhone set for this phone-only app, or whether it asks for additional sizes in the current app record.
- Confirm app icon readability at App Store size and small Home Screen size.

## Missing Actions

- Live support URL.
- Live privacy policy URL.
- scwlkr-approved public support contact.
- Final App Store screenshot set.
- scwlkr approval of subtitle, description, keywords, category, privacy answer, age-rating answer, and support contact.
- App Store Connect entry/submission after approval.
