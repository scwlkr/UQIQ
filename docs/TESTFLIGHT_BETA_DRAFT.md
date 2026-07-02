# TestFlight Beta Draft

Status: External beta deferred by scwlkr. No external testers invited. No Beta App Review started.

## Apple Source Notes

- External testers are not App Store Connect users; App Store Connect supports inviting them by email or public link.
- An internal group must exist before external testing; UQIQ already has `Internal Smoke`.
- Builds uploaded as TestFlight Internal Only can only be added to internal tester groups.
- External testing requires an external group, a build added to that group, "What to Test" text, and TestFlight App Review when required.
- Test information for external testers includes a Beta App Description and Feedback Email.
- TestFlight feedback in App Store Connect can include screenshots, crash comments, and general comments.

References:

- https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/view-tester-feedback/
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-export-compliance-information-for-beta-builds/

## UQIQ Beta Recommendation

Keep testing internal-only for now. scwlkr is the only tester for the foreseeable future.

When the app is more advanced and scwlkr explicitly resumes external testing, use email invites only for the first beta. Do not create a public link yet.

Target:

- 0 external testers now.
- Future target after approval: 1-10 external testers.
- iPhone only.
- 15-30 minute test window per tester.
- Focus on release blockers, not feature requests.

External group name:

```text
External Smoke 01
```

Current build status:

- UQIQ `0.1.0 (1)` is internal-TestFlight-only.
- It is valid for internal smoke proof, but not eligible for external tester groups.
- Before external beta, upload a replacement build without `testFlightInternalTestingOnly=true`, likely build `2`, then submit that build for TestFlight App Review.

## Test Information Draft

Beta App Description:

```text
UQIQ is a short offline puzzle game with 60 tiny trick Levels, local progress, Dur Tokens, score roastcards, and joke roasts. This beta is only for finding launch crashes, stuck/confusing Levels, unreadable UI, save/progress issues, and roasts that go too far.
```

Feedback Email:

```text
dev@wlkrlabs.com
```

What to Test:

```text
Please play UQIQ for 15-30 minutes on iPhone.

Focus only on:
- crash on launch or during play
- stuck, impossible, or confusing Levels
- unreadable/tiny UI
- save/progress loss
- audio/haptics that feel broken or annoying
- roasts that feel too harsh or off-tone

UQIQ is not a real IQ test. Please do not send general feature requests unless something blocks release.
```

Export compliance draft:

```text
UQIQ does not intentionally use encryption beyond standard Apple platform behavior. Confirm in App Store Connect before Beta App Review submission.
```

## Tester List Fields

Collect this from scwlkr before any future external invite:

```text
name,email,device_model,ios_version,notes
```

Minimum accepted row:

```text
Jane Example,jane@example.com,iPhone 15 Pro,iOS 18.6,friend beta
```

## Invite Copy Draft

```text
Subject: UQIQ TestFlight beta

I am testing UQIQ, a tiny offline puzzle game for iPhone. If you have 15-30 minutes, please install it through TestFlight and send only release-blocking feedback:

- crashes
- stuck or impossible Levels
- confusing/unfun Levels
- unreadable UI
- save/progress loss
- roasts that go too far

It is not a real IQ test. It is supposed to be dumb in a specific way.

Thanks.
```

## Tester Response Format

Ask testers to send:

```text
Device:
iOS version:
UQIQ build:
Level/screen:
What happened:
Expected:
Can reproduce? yes/no:
Screenshot or TestFlight feedback attached? yes/no:
```

## Owner Gates

scwlkr must approve or provide:

- Public support/feedback email: `dev@wlkrlabs.com`.
- External tester list.
- Approval to upload a non-internal TestFlight build for external testing.
- Approval to submit that build to TestFlight App Review.
- Approval to notify testers after approval.

Current decision:

- No external testers for now.
- No non-internal TestFlight build for external beta yet.
- No TestFlight App Review yet.
- No public link unless scwlkr explicitly asks for it later.
