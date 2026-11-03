# NexChat • Liquid Glass Android

Auth preview, version 0.1.0. Supabase accounts with offline demo chats; not a production messenger.

## Download the APK

Open **Actions → Build NexChat APK** to see the build. When green, open **Releases** and download `NexChat-v0.1.0-<run>.apk`. Android may ask to allow installs from your download app. No PC, backend account or API keys required.

## What works

- Three-page welcome with English/Bangla choice; Supabase email/password signup and login, confirmation resend, reset link handling, sign out and encrypted auth session storage.
- Dark/light glass styling, violet/cyan accents, animated onboarding indicator, responsive centered layout.
- Offline sample contacts and chat search.
- SQLite persistent text messages, replies, long-press copy/reactions, edit own messages within 15 minutes, local delete and confirmed clear history.
- Saved Messages, sample friends, profile, persistent appearance/language settings.
- CI analysis, widget tests, release APKs, ABI APKs and SHA-256 checksums.

Single check means **saved locally**, not delivered. Presence dots are sample decorations. Messages are never sent to other people. No fake automated replies are generated.

## Not implemented yet

Supabase chat sync/RLS, full Bangla translation, bundled Bangla fonts, automatic hardware performance detection, profile editing, media, stories, reels, WebRTC, push, app lock, 2FA, E2EE, tablet three-panel mode and advanced motion. Disabled tabs explain their status. Reduce effects currently disables conversation-card blur only. No security or production readiness claim is made. SQLite is not encrypted.

## Build architecture

Flutter **3.32.8**, Java 17, `flutter_riverpod` 2.6.1 for app preferences, `sqflite` 2.4.2. LocalStore is the only chat data source. Design primitives and motion tokens live under `lib/core/`. Features are expanded incrementally.

The workflow generates Android's standard runner from the exact pinned Flutter SDK. `tool/configure_android.py` explicitly sets **com.nexchat.app**. minSdk 23. This avoids an incomplete or mismatched Gradle wrapper. No native SDK or executable binary is hand-written. To build locally: generate the Android runner as in the workflow, run the configuration script, `flutter pub get`, `flutter test`, then `flutter build apk --release`.

## Signing and updating

No secrets: builds install using the runner's debug signing configuration. This is for testing. A new CI machine can generate a different certificate, requiring uninstall before installing the next APK; uninstall deletes local data. For stable updates, set repository Actions secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` with your own persistent signing key. Never commit signing keys. A secure key generation helper is deferred; no private key is exposed as a public artifact.

Supabase client configuration is in `lib/core/auth/supabase_config.dart`, with optional `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_PUBLISHABLE_KEY=...` overrides. The publishable key is a public client key, not a privileged server secret. Email/password authentication is connected; chat database tables, RLS and TURN are not implemented. FCM is absent, so google-services.json is not needed. No schema is provided pretending to secure an unimplemented backend.

## Next phase

Device verification of auth callbacks, strict membership-based RLS, real direct chats, offline outbox and friend requests. Backend service quotas and NAT/TURN limitations must be checked when those features are connected. Free services cannot promise unlimited storage or guaranteed call connectivity.

## Troubleshooting

- Red Actions run: open its failed step; analysis/tests intentionally block broken releases.
- No release: wait for APK builds and check workflow write permissions.
- App not installed: remove an older build with a different signing certificate (this deletes its local data), or configure persistent signing.
- Demo data only: account authentication uses Supabase, but conversations remain local demo data.

Developer: Rakib Chowdhury.

## Supabase Auth setup (2026-11-04)

Connected project: `erzskhvcktygussqblbu`. Public settings endpoint confirmed HTTP 200, email provider enabled, signup enabled, email autoconfirm disabled, Google disabled.

**Required dashboard action:** Authentication → URL Configuration → Redirect URLs → add `com.nexchat.app://auth/callback` and save. This cannot be set with the client publishable key. Keep email confirmation enabled. Enable production SMTP, server-side password policy and abuse controls before opening public registration. No privileged key is required in the app.

Signup sends a real confirmation email. Sign in after confirmation. Password reset sends an email that returns to the Android app and opens the new-password screen. Open links on the same phone and installation that initiated the request (PKCE). Never copy passwords into logs. The client checks new passwords for 12 characters; Supabase's server policy remains authoritative.

Account operations are separate from the offline demo. Demo profile and conversations are sample data shared by people using this device, not synced user-owned messages. Signing out does not delete demo messages. Account metadata is never used to grant authorization.

Android sessions use `flutter_secure_storage`, with Android backups disabled. No password persistence, service-role key or application-ID change is introduced. Google OAuth and MFA are not configured by this change.
