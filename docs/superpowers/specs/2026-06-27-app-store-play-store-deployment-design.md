# App Store & Play Store Deployment — Design Spec

**Date:** 2026-06-27
**App:** Akeli v1.0.0+1 — African nutrition & recipes (Flutter)
**Author:** Curtis

---

## Context

Akeli is a Flutter app (iOS + Android) backed by Supabase and Firebase. This spec covers everything needed to publish the first release:

- **iOS:** Direct App Store submission (a prior FlutterFlow version was already Apple-approved)
- **Android:** Open Testing (public beta) track first, promote to production after user validation
- **CI/CD:** Codemagic (chosen because the dev machine is Windows — iOS builds require macOS)
- **Developer accounts:** Both Apple Developer Program and Google Play Console are active

---

## Workstream 1: App Configuration Hardening

### Android

- Add `minifyEnabled true` and `shrinkResources true` to the `release` build type in `android/app/build.gradle.kts`
- Add `proguard-rules.pro` with keep rules for Flutter engine, Firebase, Supabase, and Kotlin reflection
- Move `key.properties` contents (storePassword, keyPassword, keyAlias, storeFile) to Codemagic environment secrets; add `key.properties` to `.gitignore`; the Codemagic workflow generates the file at build time

### iOS

- Confirm and set the concrete Bundle Identifier to `io.akeli.com` in Xcode (`PRODUCT_BUNDLE_IDENTIFIER`) — must match the App ID registered in Apple Developer portal
- Enable the **Push Notifications** capability in the Xcode project (Signing & Capabilities tab)
- Upload the APNs Authentication Key from Firebase Console (Project Settings → Cloud Messaging) to App Store Connect (Users & Access → Keys → APNs)
- No manual certificate management — Codemagic handles signing via App Store Connect API

### Version Strategy

- First release ships as `1.0.0+1` (pubspec.yaml unchanged)
- Subsequent releases: bump `version:` in `pubspec.yaml` (e.g., `1.0.1+2`); Codemagic auto-increments the build number (`versionCode` / `CFBundleVersion`) on each CI build so the store never rejects a duplicate build number

### Environment / Secrets

- Supabase publishable key hardcoded in `lib/core/supabase_client.dart` — correct pattern for Flutter; no change needed
- All signing secrets and API keys live in Codemagic encrypted env vars, never in git

---

## Workstream 2: Android Play Store Setup

### Steps

1. **Create app record** in Google Play Console
   - Package name: `io.akeli.com`
   - Default language: French (`fr-FR`)
   - Category: Health & Fitness
   - App type: App (not game)

2. **Set up Open Testing track**
   - Enable the Open Testing track — public beta, no invite required
   - Users see a "Join Beta" banner on the Play Store listing

3. **First upload (manual)**
   - Build locally: `flutter build appbundle --release`
   - Upload the `.aab` to Open Testing track in Play Console
   - Required to activate the track before Codemagic can upload automatically

4. **Google Play API service account**
   - In Google Cloud Console (linked to the Play Console project): create a service account
   - Grant it the **Release Manager** role in Play Console (Setup → API access)
   - Export the service account JSON key → store in Codemagic env var `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`

5. **Promote to production**
   - After sufficient beta feedback, promote the open testing release to production in Play Console
   - No new build required — same AAB is promoted

### Already Done

- `applicationId = "io.akeli.com"` ✅
- Keystore (`android/app/akeli-release.keystore`) + `key.properties` configured ✅
- `google-services.json` present ✅
- Firebase push notification background handling ✅

---

## Workstream 3: iOS App Store Connect Setup

### Steps

1. **Register Bundle ID** in Apple Developer portal
   - Identifier: `io.akeli.com`
   - Capabilities: Push Notifications

2. **Create app record** in App Store Connect
   - Bundle ID: `io.akeli.com`
   - App name: Akeli
   - Primary language: French
   - Category: Health & Fitness

3. **Generate App Store Connect API key**
   - App Store Connect → Users & Access → Integrations → App Store Connect API
   - Create key with **App Manager** role
   - Download the `.p8` file (only downloadable once)
   - Note the **Key ID** and **Issuer ID**
   - Store all three in Codemagic env vars: `APP_STORE_CONNECT_PRIVATE_KEY`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`

4. **Codemagic automatic signing**
   - Codemagic creates and manages the iOS Distribution certificate and App Store provisioning profile automatically using the API key above
   - No manual export of `.p12` or `.mobileprovision` files needed

5. **First submission**
   - Codemagic builds and uploads the IPA to App Store Connect
   - Complete the store listing in App Store Connect UI (screenshots, description, review notes)
   - Submit for Apple review (~24–48h)

### Push Notifications

- `Info.plist` already has `UIBackgroundModes: remote-notification` ✅
- APNs key from Firebase must be uploaded to App Store Connect (separate from the App Store Connect API key)
- The Push Notifications capability must be enabled in the Xcode project before building

---

## Workstream 4: Store Listing Assets

All assets must be created from scratch.

### App Icon

| Platform | Size | Format |
|---|---|---|
| iOS (App Store) | 1024×1024 | PNG, no alpha channel, no rounded corners |
| Android (Play Store) | 512×512 | PNG or JPG |

The existing `assets/icons/app_icon.png` is used by `flutter_launcher_icons` for in-app icons. The store listing icons are uploaded separately in App Store Connect and Play Console.

### Screenshots

**iOS — required device sizes:**
- 6.7" (iPhone 16 Pro Max or iPhone 15 Pro Max): 1320×2868 px
- 6.5" (iPhone 14 Plus or iPhone 11 Pro Max): 1284×2778 px
- 5.5" (iPhone 8 Plus): 1242×2208 px
- 12.9" iPad Pro: 2048×2732 px

**Android — required:**
- Phone: min 2 screenshots, 320–3840 px on each side, aspect ratio 16:9 or 9:16
- 7" tablet: recommended
- 10" tablet: recommended

**Recommended workflow:** Use a screenshot framing tool (Previewed, DaVinci Apps, AppMockUp) — provide 1 real screenshot from the app, generate all required sizes with device frames.

**Minimum viable set (to unblock first submission):**
- 3 screenshots per platform × 2 required iOS sizes = 6 images
- 2 screenshots for Android phone

### Feature Graphic (Android only)

- Size: 1024×500 px
- Format: PNG or JPG
- Required for Play Store listing

### Text Content

**App name:** Akeli (both stores)

**iOS Subtitle (30 chars):** Recettes & nutrition africaines

**Short description — Android (80 chars):**
Découvrez des recettes africaines et suivez votre nutrition au quotidien.

**Full description (both stores, up to 4000 chars):**
To be written. Must cover: core features (recipe discovery, nutrition tracking, personalized feed), African cuisine focus, target audience. Available in French; English can be added as a secondary locale.

**Keywords — iOS (100 chars total):**
Suggested: `nutrition,recettes,africain,alimentation,santé,cuisine,régime,calories,repas,bien-être`

### Privacy Policy

- **Required by both stores before any submission**
- Must cover: data collected (account info, health/nutrition data), third-party services (Supabase, Firebase/FCM), user rights (deletion, access), contact email
- Hosting: a simple public page — Notion, GitHub Pages, or a `/privacy` route on a domain
- The URL must be stable and accessible (no login required)

### Language

- Primary: French (`fr-FR`)
- English locale: optional for launch, add post-launch

---

## Workstream 5: Codemagic CI/CD Pipeline

### `codemagic.yaml` — two workflows

**Triggers:**
- Tag `v*.*.*` → build + deploy both platforms
- Push to `main` → build only (no deploy), verify build health

### Android Workflow (`android-release`)

```
1. Set up Flutter (version from pubspec.yaml)
2. Generate key.properties from env vars
3. flutter pub get
4. flutter build appbundle --release
5. Sign AAB (keystore from env var, decoded from base64)
6. Publish to Play Store Open Testing track via Google Play API
```

**Env vars required:**
| Name | Content |
|---|---|
| `CM_KEYSTORE` | base64-encoded `akeli-release.keystore` |
| `CM_KEYSTORE_PASSWORD` | store password |
| `CM_KEY_PASSWORD` | key password |
| `CM_KEY_ALIAS` | `akeli-key` |
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | Google Play service account JSON |

### iOS Workflow (`ios-release`)

```
1. Set up Flutter (version from pubspec.yaml)
2. Set up code signing via App Store Connect API (automatic)
3. flutter pub get
4. flutter build ipa --release --export-options-plist=ExportOptions.plist
5. Publish IPA to App Store Connect (TestFlight / direct submission)
```

**Env vars required:**
| Name | Content |
|---|---|
| `APP_STORE_CONNECT_PRIVATE_KEY` | contents of the `.p8` API key file |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | Key ID from App Store Connect |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect |
| `APPLE_TEAM_ID` | Apple Developer Team ID |

### `ExportOptions.plist`

A file checked into the repo at `ios/ExportOptions.plist` telling Xcode how to export the archive:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <!-- Replace YOUR_TEAM_ID with the literal 10-char Apple Team ID from developer.apple.com -->
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
```

### Security

- `key.properties` added to `.gitignore`
- `android/app/akeli-release.keystore` added to `.gitignore` (stored as base64 env var in Codemagic)
- `.env` added to `.gitignore` (already should be)
- No secrets in source code or git history

---

## Execution Order

The workstreams have dependencies. Correct execution order:

```
1. App config hardening (all code changes first)
   └─ Move key.properties to gitignore + Codemagic vars
   └─ Add ProGuard to Android build
   └─ Confirm iOS Bundle ID in Xcode

2. Store infrastructure (accounts & records)
   └─ Register io.akeli.com Bundle ID in Apple Developer
   └─ Create App Store Connect app record
   └─ Create Google Play Console app record
   └─ Set up Open Testing track

3. First manual Android build & upload (activates Play Console)
   └─ flutter build appbundle --release (local)
   └─ Upload AAB to Open Testing in Play Console

4. Store listing assets (can run in parallel with steps 2-3)
   └─ Privacy policy → hosted URL
   └─ App icon (store-quality versions)
   └─ Screenshots (minimum viable set)
   └─ Descriptions & keywords

5. Codemagic setup
   └─ Connect GitHub repo to Codemagic
   └─ Add all env vars & secrets
   └─ Generate App Store Connect API key → add to Codemagic
   └─ Create Google Play service account → add to Codemagic
   └─ Create codemagic.yaml in repo

6. First CI build via tag
   └─ git tag v1.0.0 → push → Codemagic builds both platforms
   └─ iOS IPA lands in App Store Connect
   └─ Android AAB lands in Open Testing track

7. Complete store submissions
   └─ App Store Connect: add metadata + screenshots → submit for review
   └─ Play Console: complete listing → publish Open Testing
```

---

## Open Questions / Deferred

- **Privacy policy URL:** Needs a hosted location before any submission. Decide on hosting (Notion vs domain `/privacy` page).
- **Full description text:** 4000-char descriptions need to be written in French (and optionally English).
- **Screenshot content:** Need to decide which 3–5 screens to showcase (onboarding? feed? recipe detail? nutrition dashboard?).
- **App Store review notes:** Helpful to include a test account for Apple reviewers.
- **Android minSdkVersion:** Currently inherited from Flutter defaults (`flutter.minSdkVersion`). Verify this is acceptable (Flutter 3.x defaults to Android 5.0 / API 21).
- **Localization:** App initializes `fr_FR` locale. Both stores will be listed in French first; English locale is a post-launch task.
