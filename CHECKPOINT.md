# NexChat checkpoint — 2026-11-04

Base commit: 9ef46906ac127575448745f3450f90f1254a222b.

Implemented: Supabase public client configuration; email/password signup/login; confirmation resend; reset email and Android callback/new-password UI; encrypted session persistence; sign out; account entry in Settings. Offline messages and application ID retained. No cloud chat database or online messages introduced. Full design overhaul is outside this change.

Backend observed: settings endpoint HTTP 200; email and signup enabled; confirmation required; Google disabled. No real user account or email was created during testing. No admin credentials available.

Validation: Python Android manifest generation passed. Local Flutter execution was blocked by automatic approval review due to its cloud metadata endpoint request. Use GitHub Actions for formatting, analysis, tests and APK compilation. Device visuals, real email delivery, token refresh after restart and cold/warm password-recovery deep links remain unverified.

Required owner setting: Supabase Authentication → URL Configuration → Redirect URLs: add com.nexchat.app://auth/callback. Publishable key cannot change admin settings. RLS, production email/abuse settings and MFA remain future work. Existing CI debug-signing fallback is unchanged; stable update signing remains an existing limitation.

Next: inspect CI result, fix any analysis/test/build failures, then verify email confirmation and reset on Android after redirect configuration. Continue the requested visual redesign as separate work with an agreed visual target.

## Completed build

Implementation commit: 7d88a0b06a8e97516783c3886ed2dc49d8ca1648.
GitHub Actions run 41720034021, build 5: SUCCESS. Dependency resolution, formatting, Flutter analysis, all 7 tests, universal and ABI release APK compilation and publication passed. Test coverage includes invalid email/password validation, auth rejection/retry and small-screen keyboard scrolling; these use a mock backend.
Release: https://github.com/techwithrakibofficial/NexChat/releases/tag/build-5
Universal APK: NexChat-v0.1.0-5.apk (51,041,067 bytes).
SHA-256: 5169f3e1283800877ef135cd71d469bcb691af28826608968f128f7e418636f4.
Device rendering, real email delivery and recovery callbacks remain unverified. Required Supabase redirect setting remains an owner action.
