# Privacy And Support Page Draft

Status: Draft for scwlkr/legal review. Not live.

## Hosting Plan

Target URLs:

- Privacy Policy URL: `https://uqiq.wlkrlabs.com/privacy`
- Support URL: `https://uqiq.wlkrlabs.com/support`

Plan:

- Publish a minimal static page before App Store submission.
- The `/privacy` page should contain the full privacy policy and a support/contact section.
- The `/support` page may be a short support page or a redirect to `/privacy#support`, as long as it leads to real contact information.
- Live hosting/DNS changes require explicit scwlkr approval/action.

Blocked before submission:

- Confirmed public support email: `dev@wlkrlabs.com`.
- Publish the URLs.
- Verify both URLs load over HTTPS from a non-logged-in browser.

## Page Copy

```text
UQIQ Privacy Policy and Support

Last updated: [publish date]

UQIQ is a mobile puzzle game from WLKRLABS. This page explains the privacy practices and support contact for UQIQ v1.0.

Privacy Summary

UQIQ does not collect personal data from the app.

UQIQ v1.0 is designed to run offline. It has no accounts, no backend login, no ads, no in-app purchases, no Game Center, no in-app AI, no analytics SDK, no crash reporting SDK, and no tracking SDK.

Local Game Data

UQIQ stores game progress locally on your device so the game can remember unlocked Levels, completed Levels, best attempts, Dur Tokens, DUR'D state, and your UQIQ score.

This local game data stays on your device. WLKRLABS does not receive it from the app.

Device Permissions

UQIQ v1.0 does not use the camera, microphone, photo library, contacts, location, Bluetooth, Health, or other sensitive device data.

Children

UQIQ is not submitted as a Kids Category app and is not directed to children under 13.

Third Parties

UQIQ v1.0 does not include advertising networks, analytics providers, social SDKs, payment SDKs, or account providers.

Support

For support, bugs, privacy questions, or App Store review contact, email:

dev@wlkrlabs.com

Please include your device model, iOS version, UQIQ app version, and a short description of the issue. Do not send passwords, payment details, or sensitive personal information.

Changes

If UQIQ changes its data practices, WLKRLABS will update this page and the App Store privacy answers before submitting an app update.
```

## App Store Connect Inputs

Privacy Policy URL:

```text
https://uqiq.wlkrlabs.com/privacy
```

Support URL:

```text
https://uqiq.wlkrlabs.com/support
```

Support/contact placeholder:

```text
dev@wlkrlabs.com
```

Owner decision needed:

- Confirm whether `/support` is a separate page or redirects to `/privacy#support`.
