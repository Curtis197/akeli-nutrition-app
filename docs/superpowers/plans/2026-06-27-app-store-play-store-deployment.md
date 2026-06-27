# App Store & Play Store Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Akeli v1.0.0+1 to the App Store (direct submission) and Google Play Open Testing track, with Codemagic CI/CD automating all future releases via `v*` git tags.

**Architecture:** 13 tasks executed in dependency order — code hardening first, then store account setup and first manual Android upload (to unlock the Play Console track), Apple portal setup in parallel, store listing assets in parallel, then Codemagic pipeline wiring everything together. Tagging `v1.0.0` triggers both platform builds automatically once all secrets are configured.

**Tech Stack:** Flutter 3.x, Codemagic CI/CD (mac_mini_m2 runners), Google Play API v3, App Store Connect API, Android release keystore (already exists at `android/app/akeli-release.keystore`).

## Global Constraints

- Bundle Identifier / Application ID: `io.akeli.com` (both platforms — iOS currently has `io.akeli.akeli`, must change)
- App version: `1.0.0+1` — do not change `pubspec.yaml` for the first submission
- Android keystore: `android/app/akeli-release.keystore`, alias `akeli-key` — already exists and gitignored
- `android/.gitignore` already excludes `key.properties` and `*.keystore` — no changes needed there
- Primary store language: French (`fr-FR`)
- App category: Health & Fitness (both stores)
- CI/CD: Codemagic only — dev machine is Windows, iOS builds require macOS
- All signing secrets live in Codemagic encrypted env vars, never in git

## Execution Dependency Order

```
Task 1 (ProGuard)   ─┐
Task 2 (Bundle ID)  ─┼──► Task 4 (First manual AAB) ──► Task 5 (Service account)
                      │                                          │
Task 3 (Play Console)─┘                                         │
Task 6 (Apple setup) — can run in parallel with 1-5 ────────────┤
Task 7 (APNs setup)  — depends on Task 6 ───────────────────────┤
Task 8 (Privacy policy) — independent ──────────────────────────┤
Task 9 (Descriptions)   — independent ──────────────────────────┤
Task 10 (Screenshots)   — independent ──────────────────────────┤
                                                                 │
                              Task 11 (Codemagic UI) ◄──────────┤
                              Task 12 (codemagic.yaml) ◄── depends on 11
                              Task 13 (First CI tag) ◄───────── all above
```

---

### Task 1: Android build hardening — ProGuard + R8

**Files:**
- Modify: `android/app/build.gradle.kts`
- Create: `android/app/proguard-rules.pro`

**Interfaces:**
- Produces: release build with R8 code shrinking enabled; ProGuard keep rules for Flutter engine, Firebase, and OkHttp

---

- [ ] **Step 1: Add minifyEnabled, shrinkResources, and ProGuard config to the release build type**

Open `android/app/build.gradle.kts`. Replace the existing `release` block inside `buildTypes`:

```kotlin
// BEFORE
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}

// AFTER
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

- [ ] **Step 2: Create `android/app/proguard-rules.pro`**

```proguard
# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# OkHttp (used by networking plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep annotation metadata for serialization
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Preserve source file names for crash stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

- [ ] **Step 3: Verify the debug build still compiles**

```bash
flutter build apk --debug
```

Expected last line: `✓ Built build\app\outputs\apk\debug\app-debug.apk`

Debug builds don't use ProGuard so this just confirms the Gradle DSL change parsed correctly.

- [ ] **Step 4: Commit**

```bash
git add android/app/build.gradle.kts android/app/proguard-rules.pro
git commit -m "feat(android): enable R8 shrinking and add ProGuard rules for release build"
```

---

### Task 2: iOS Bundle Identifier — change io.akeli.akeli → io.akeli.com

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: Bundle ID `io.akeli.com` set consistently across all 3 build configurations (Debug, Release, Profile)

---

- [ ] **Step 1: Confirm the current values**

```bash
grep -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

Expected output (3 Runner entries + 3 RunnerTests entries):
```
375:    PRODUCT_BUNDLE_IDENTIFIER = io.akeli.akeli;
391:    PRODUCT_BUNDLE_IDENTIFIER = io.akeli.akeli.RunnerTests;
408:    PRODUCT_BUNDLE_IDENTIFIER = io.akeli.akeli.RunnerTests;
423:    PRODUCT_BUNDLE_IDENTIFIER = io.akeli.akeli.RunnerTests;
554:    PRODUCT_BUNDLE_IDENTIFIER = io.akeli.akeli;
576:    PRODUCT_BUNDLE_IDENTIFIER = io.akeli.akeli;
```

- [ ] **Step 2: Replace the Runner Bundle ID (leave RunnerTests unchanged)**

On Windows PowerShell:
```powershell
$content = Get-Content "ios\Runner.xcodeproj\project.pbxproj" -Raw
$content = $content -replace 'PRODUCT_BUNDLE_IDENTIFIER = io\.akeli\.akeli;', 'PRODUCT_BUNDLE_IDENTIFIER = io.akeli.com;'
Set-Content "ios\Runner.xcodeproj\project.pbxproj" $content
```

On Mac/Linux:
```bash
sed -i '' 's/PRODUCT_BUNDLE_IDENTIFIER = io\.akeli\.akeli;/PRODUCT_BUNDLE_IDENTIFIER = io.akeli.com;/g' \
  ios/Runner.xcodeproj/project.pbxproj
```

- [ ] **Step 3: Verify only Runner entries changed (RunnerTests should remain io.akeli.akeli.RunnerTests)**

```bash
grep -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

Expected: 3 lines showing `io.akeli.com`, 3 lines showing `io.akeli.akeli.RunnerTests`.

- [ ] **Step 4: Mac-only — Enable Push Notifications capability in Xcode**

This step requires macOS + Xcode. If you don't have a Mac available now, note it as a blocker before App Store submission (Apple will reject without it).

On Mac:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Click **Runner** target → **Signing & Capabilities** tab
3. Click **+ Capability** → search for "Push Notifications" → double-click to add
4. Xcode creates `ios/Runner/Runner.entitlements` with `aps-environment = production`
5. Commit the new entitlements file:
```bash
git add ios/Runner/Runner.entitlements
git commit -m "feat(ios): add Push Notifications entitlement for App Store release"
```

- [ ] **Step 5: Commit the Bundle ID change**

```bash
git add ios/Runner.xcodeproj/project.pbxproj
git commit -m "chore(ios): update Bundle Identifier from io.akeli.akeli to io.akeli.com"
```

---

### Task 3: Google Play Console — app record + Open Testing track (external)

**No code files changed.** All steps performed at [play.google.com/console](https://play.google.com/console).

---

- [ ] **Step 1: Create the app record**

Go to Play Console → **All apps** → **Create app**:
- App name: `Akeli`
- Default language: `French (fr-FR)`
- App type: `App`
- Free or paid: `Free`
- Check both declaration boxes (Developer Program Policies + US export laws)
- Click **Create app**

- [ ] **Step 2: Set up app content declarations**

Navigate to **Policy** → **App content** and complete all required sections:

| Section | Value |
|---|---|
| Privacy policy | URL from Task 8 (do Task 8 first if possible, or come back) |
| Ads | No ads |
| Content rating | Run the questionnaire — select Health category, general audience |
| Target audience | Age 16+ (nutrition app collecting health data) |
| Data safety | Declare: email (collected), nutrition/food diary data (collected), Firebase analytics (collected), no data sold to third parties |

- [ ] **Step 3: Set up the Open Testing track**

Navigate to **Release** → **Testing** → **Open testing** → **Create new release**

Do NOT upload an AAB yet (done in Task 4). Just click through to confirm the track is accessible and active.

- [ ] **Step 4: Set app category**

Navigate to **Store presence** → **Store settings**:
- App category: Health & Fitness
- Contact email: `curtiscapre@gmail.com`

- [ ] **Verification:** Play Console shows the Akeli app in your app list. The Open testing track page is accessible under Testing.

---

### Task 4: First manual Android AAB build + upload

**Prerequisite:** Tasks 1, 2, and 3 complete. `android/key.properties` must exist on your local disk (it is gitignored but should still be present from original setup).

---

- [ ] **Step 1: Verify key.properties is present locally**

```bash
cat android/key.properties
```

Expected output (values from the original file):
```
storePassword=<your store password>
keyPassword=<your key password>
keyAlias=akeli-key
storeFile=akeli-release.keystore
```

If this file is missing (e.g., on a fresh clone), recreate it using the credentials stored in your password manager from the original setup.

- [ ] **Step 2: Build the release Android App Bundle**

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Expected last line:
```
✓ Built build\app\outputs\bundle\release\app-release.aab (XX.X MB)
```

Build time: 3–8 minutes. If you see ProGuard errors, check `android/app/proguard-rules.pro` from Task 1.

- [ ] **Step 3: Upload the AAB to Play Console Open Testing**

Play Console → **Release** → **Testing** → **Open testing** → **Create new release**:
1. Upload `build\app\outputs\bundle\release\app-release.aab`
2. Release name: auto-filled as `1.0.0 (1)` — leave as-is
3. Release notes (What's new in French):
   ```
   fr-FR: Première version bêta d'Akeli — recettes africaines et suivi nutritionnel personnalisé.
   ```
4. Click **Review release** → **Start rollout to Open testing**

- [ ] **Verification:** Play Console → Open testing shows the release as "In review" or "Published". This is required before Codemagic can upload to this track automatically.

---

### Task 5: Google Play API service account

**No code files changed.** Steps performed in Google Cloud Console + Play Console.

---

- [ ] **Step 1: Open Google Cloud Console for your Play project**

Go to [console.cloud.google.com](https://console.cloud.google.com) → select the project linked to your Google Play account.

- [ ] **Step 2: Create a service account**

Navigate to **IAM & Admin** → **Service Accounts** → **+ Create Service Account**:
- Name: `codemagic-deployer`
- Description: `Codemagic automated Play Store deployments`
- Click **Create and continue** → skip role assignment → **Done**

- [ ] **Step 3: Download the JSON key**

Click `codemagic-deployer` → **Keys** tab → **Add Key** → **Create new key** → **JSON** → **Create**

A `.json` file downloads automatically. Save it securely — the entire contents of this file is the `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` value you'll paste into Codemagic in Task 11. It cannot be re-downloaded.

- [ ] **Step 4: Grant the service account access in Play Console**

Play Console → **Setup** → **API access**:
1. Click **Link to an existing Google Cloud project** if not already linked — select your project
2. Under Service accounts, find `codemagic-deployer@<project>.iam.gserviceaccount.com` → **Grant access**
3. Role: **Release manager**
4. Click **Apply** → **Invite user**

- [ ] **Verification:** Play Console → Setup → API access shows `codemagic-deployer` with "Release manager" role.

---

### Task 6: Apple Developer Portal + App Store Connect setup (external)

**No code files changed.** Steps at [developer.apple.com](https://developer.apple.com) and [appstoreconnect.apple.com](https://appstoreconnect.apple.com).

---

- [ ] **Step 1: Register the Bundle ID**

Go to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers** → **+**:
- Type: **App IDs** → Continue
- Select: **App** → Continue
- Description: `Akeli`
- Bundle ID: **Explicit** → `io.akeli.com`
- Capabilities: enable **Push Notifications**
- Click **Register**

- [ ] **Step 2: Record your Apple Team ID**

On [developer.apple.com/account](https://developer.apple.com/account), your Team ID appears in the top-right membership card. It is a 10-character alphanumeric string (e.g., `AB12CD34EF`).

Save it now — you will use it in Task 12 (ExportOptions.plist).

- [ ] **Step 3: Create the App Store Connect app record**

Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App**:
- Platforms: iOS
- Name: `Akeli`
- Primary language: French
- Bundle ID: select `io.akeli.com` (appears after Step 1)
- SKU: `akeli-ios-v1`
- User Access: Full Access
- Click **Create**

- [ ] **Step 4: Generate the App Store Connect API key for Codemagic**

App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **+**:
- Name: `Codemagic Akeli`
- Role: **App Manager**
- Click **Generate**

Download the `.p8` file immediately — **it is only available once**. Also note:
- **Key ID** (shown in the key list, e.g., `ABCD1234EF`)
- **Issuer ID** (shown at the top of the API Keys page)

Save all three (`.p8` file, Key ID, Issuer ID) securely. You will upload them to Codemagic in Task 11 Step 2.

- [ ] **Verification:** App Store Connect shows Akeli in My Apps. The API key appears in Users and Access → Integrations with status Active.

---

### Task 7: APNs key — Firebase → App Store Connect

**No code files changed.**

**Prerequisite:** Task 6 complete (you need the Apple Team ID and Apple Developer account access).

---

- [ ] **Step 1: Check if an APNs key is already configured in Firebase**

Go to [console.firebase.google.com](https://console.firebase.google.com) → Akeli project → **Project Settings** (gear icon) → **Cloud Messaging** tab → **Apple app configuration** section.

If an APNs Auth Key is already shown as configured, this task is done — skip to Verification.

- [ ] **Step 2: Create an APNs Auth Key (if not already done)**

Go to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Keys** → **+**:
- Key Name: `Akeli APNs Key`
- Enable: **Apple Push Notifications service (APNs)**
- Click **Continue** → **Register** → **Download**

Note the **Key ID** shown on the download page. Save the `.p8` file.

- [ ] **Step 3: Upload the APNs key to Firebase**

Firebase Console → Project Settings → Cloud Messaging → Apple app configuration → **Upload** (APNs Auth Key):
- File: the `.p8` APNs key from Step 2
- Key ID: the APNs Key ID from Step 2
- Team ID: your 10-char Apple Team ID from Task 6 Step 2

Click **Upload**.

- [ ] **Verification:** Firebase Console → Cloud Messaging → Apple app configuration shows: `APNs Auth Key: Configured ✓`

---

### Task 8: Privacy policy — create and host

**No code files changed.** A publicly accessible URL is required by both stores before any submission can go live.

---

- [ ] **Step 1: Create the privacy policy page**

Create a public Notion page (or equivalent hosted page) with this minimum French content. Replace `[DATE]` with today's date (`27 juin 2026`):

```
Politique de confidentialité — Akeli
Dernière mise à jour : 27 juin 2026

Akeli collecte et utilise les données suivantes pour fonctionner :

1. DONNÉES COLLECTÉES
- Adresse e-mail et nom d'affichage (création de compte)
- Préférences nutritionnelles et données de repas enregistrées
- Jeton de notification push (pour les alertes personnalisées)
- Données d'utilisation anonymisées (Firebase Analytics)

2. STOCKAGE ET SÉCURITÉ
Ces données sont hébergées via Supabase (infrastructure en Union Européenne)
et Google Firebase. Elles sont protégées par chiffrement en transit et au repos.
Elles ne sont jamais vendues à des tiers.

3. VOS DROITS
Pour demander la suppression de votre compte et de vos données,
contactez-nous à : curtiscapre@gmail.com
Nous traiterons votre demande sous 30 jours.

4. CONTACT
Curtis — curtiscapre@gmail.com
```

**Hosting via Notion:**
1. Create a new Notion page → paste the content above
2. Click **Share** in the top-right → toggle **Publish to web** → copy the public URL

The URL looks like: `https://www.notion.so/Politique-de-confidentialite-Akeli-xxxxxxxx`

- [ ] **Step 2: Verify the URL is publicly accessible**

Open the URL in an incognito browser window. It must load without requiring login. If Notion shows a login prompt, re-check the "Publish to web" setting.

- [ ] **Step 3: Add the URL to both store listings**

- Play Console → **Policy** → **App content** → Privacy policy → paste URL → **Save**
- App Store Connect → Akeli → **App Information** (under General section) → **Privacy Policy URL** → paste URL → **Save**

---

### Task 9: Store listing content — descriptions + keywords

**No code files changed.** Enter text metadata into both store portals.

---

- [ ] **Step 1: Enter French metadata in App Store Connect**

App Store Connect → Akeli → click the **French (France)** version under the App Store tab:

**Name:** `Akeli`

**Subtitle (30 chars max):**
```
Recettes & nutrition africaines
```

**Description (up to 4000 chars):**
```
Akeli est votre compagnon de nutrition inspiré des saveurs africaines.

🍲 RECETTES AFRICAINES AUTHENTIQUES
Explorez des centaines de recettes de cuisine africaine : plats traditionnels, accompagnements, desserts et boissons. Chaque recette est accompagnée de sa valeur nutritionnelle complète.

📊 SUIVI NUTRITIONNEL PERSONNALISÉ
Suivez vos apports en calories, protéines, glucides et lipides au quotidien. Akeli adapte ses recommandations à votre profil et vos objectifs de santé.

✨ FEED PERSONNALISÉ
Découvrez chaque jour de nouvelles recettes adaptées à vos préférences alimentaires et à votre historique de consommation.

🔔 RAPPELS & NOTIFICATIONS
Recevez des rappels de repas et des suggestions personnalisées pour maintenir une alimentation équilibrée.

Akeli — Mangez africain, vivez sainement.
```

**Keywords (100 chars max, comma-separated — no spaces after commas):**
```
nutrition,recettes,africain,alimentation,santé,cuisine,régime,calories,repas,bien-être
```

**Support URL:** `mailto:curtiscapre@gmail.com`
**Privacy Policy URL:** URL from Task 8

- [ ] **Step 2: Enter French metadata in Play Console**

Play Console → Akeli → **Grow** → **Store presence** → **Main store listing** → select **French (fr-FR)**:

**Short description (80 chars max):**
```
Recettes africaines authentiques et suivi nutritionnel personnalisé.
```

**Full description:** paste the same 4000-char text from Step 1.

- [ ] **Verification:** Both store listings show the French text without validation errors.

---

### Task 10: Store listing assets — icon, screenshots, feature graphic

**No code files changed.** Create and upload all visual assets.

---

- [ ] **Step 1: Prepare the store app icon**

The `assets/icons/app_icon.png` is used by `flutter_launcher_icons` for in-app icons. The store listing icons are separate and uploaded in the portals.

Create two exports at store-required sizes. If you have the source file (Figma, etc.), export from there. Otherwise use ImageMagick (install from [imagemagick.org](https://imagemagick.org) if needed):

```bash
# iOS App Store: 1024×1024, no alpha
magick assets/icons/app_icon.png -resize 1024x1024 -alpha remove store_icon_ios_1024.png

# Android Play Store: 512×512
magick assets/icons/app_icon.png -resize 512x512 store_icon_android_512.png
```

Do not commit these files — they are uploaded directly to the store portals.

- [ ] **Step 2: Take raw screenshots of the app**

Run the app and take screenshots of these 4 key screens:
1. Home / recipe feed (shows personalized content)
2. Recipe detail page (shows recipe + nutrition info)
3. Nutrition dashboard (shows daily tracking)
4. Profile / onboarding screen

**iOS screenshots — required device sizes:**
- 6.7" (iPhone 15 Pro Max): screenshots at 1290×2796 px — use the iPhone 15 Pro Max simulator in Xcode or a real device
- 6.5" (iPhone 14 Plus): 1242×2688 or 1284×2778 px
- 12.9" iPad Pro (3rd gen+): 2048×2732 px

**Android screenshots:**
- Phone (any modern device): minimum 2 screenshots, at least 320 px on shortest side

On iOS simulator (on Mac): Device → take screenshot saves to Desktop.
On Android emulator: use the camera icon in the emulator controls sidebar.

- [ ] **Step 3: Frame screenshots with device mockups (strongly recommended)**

Go to [DaVinci Apps](https://davinciapps.com) or [AppMockUp](https://app-mockup.com):
1. Upload your raw screenshots
2. Select a device frame (iPhone 15 Pro Max for 6.7", Pixel 7 for Android)
3. Add a short caption per screenshot (e.g., "Vos recettes africaines, chaque jour")
4. Export all required sizes

This takes ~30 minutes and significantly improves conversion on the store listing.

- [ ] **Step 4: Create the Android feature graphic**

Size: 1024×500 px, PNG or JPG. Required for Play Store — without it the listing cannot go live.

Use [Canva](https://canva.com) → create a custom size 1024×500:
- Place the Akeli icon centered or left-aligned
- Add tagline: `Recettes africaines • Nutrition personnalisée`
- Use the app's primary color from `lib/core/theme.dart` as background
- Export as PNG

- [ ] **Step 5: Upload to App Store Connect**

App Store Connect → Akeli → French (France) → scroll to **Screenshots**:
- Upload under **6.7" Display** (required)
- Upload under **6.5" Display** (required)
- Upload under **12.9" iPad Pro** (required)

- [ ] **Step 6: Upload to Play Console**

Play Console → **Grow** → **Store presence** → **Main store listing** → Graphics:
- **App icon**: upload `store_icon_android_512.png`
- **Feature graphic**: upload the 1024×500 graphic from Step 4
- **Phone screenshots**: upload minimum 2 phone screenshots

- [ ] **Verification:** Both store listings show no missing asset warnings. App Store Connect listing preview renders correctly. Play Console store listing shows all graphics.

---

### Task 11: Codemagic — connect repo + configure secrets

**No code files changed.** All steps in Codemagic web UI at [codemagic.io](https://codemagic.io).

**Prerequisite:** Tasks 2 (keystore base64), 5 (service account JSON), and 6 (App Store Connect API key .p8) must be complete.

---

- [ ] **Step 1: Connect your GitHub repository**

Go to [codemagic.io](https://codemagic.io) → sign in with GitHub → **Add application** → select `akeli-nutrition-app` → choose **codemagic.yaml** workflow (not the Flutter workflow wizard) → **Finish**.

- [ ] **Step 2: Add App Store Connect API key integration**

Codemagic → **Teams** → your team → **Integrations** → **Developer Portal** → **Add**:
- Name: `Akeli ASC Key` (must match exactly what you put in `codemagic.yaml` in Task 12)
- Issuer ID: [from Task 6 Step 4]
- Key ID: [from Task 6 Step 4]
- Private key: upload the `.p8` file from Task 6 Step 4

- [ ] **Step 3: Encode the Android keystore to base64**

Run this on your Windows machine to get the base64 string:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("$PWD\android\app\akeli-release.keystore")
) | Out-File -FilePath "$env:TEMP\keystore.b64" -Encoding ascii -NoNewline
```

Open `$env:TEMP\keystore.b64` in a text editor. Copy the entire string (it will be a long single line). Delete the file after copying.

- [ ] **Step 4: Create environment variable group `android_signing`**

Codemagic → your Akeli app → **Environment variables** → **+ Add group** → name: `android_signing`

Add these 4 variables, all marked as **Secure**:

| Variable name | Value |
|---|---|
| `CM_KEYSTORE` | the base64 string from Step 3 |
| `CM_KEYSTORE_PASSWORD` | the storePassword from your `android/key.properties` |
| `CM_KEY_PASSWORD` | the keyPassword from your `android/key.properties` |
| `CM_KEY_ALIAS` | `akeli-key` |

- [ ] **Step 5: Create environment variable group `google_play`**

Codemagic → Environment variables → **+ Add group** → name: `google_play`

Add 1 variable, marked as **Secure**:

| Variable name | Value |
|---|---|
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | paste the entire JSON file content from Task 5 Step 3 |

- [ ] **Verification:** Codemagic shows:
  - Akeli app connected to the GitHub repo
  - Integration `Akeli ASC Key` listed under Teams → Integrations
  - Groups `android_signing` (4 vars) and `google_play` (1 var) under Environment variables

---

### Task 12: Create codemagic.yaml + ios/ExportOptions.plist

**Files:**
- Create: `codemagic.yaml` (project root)
- Create: `ios/ExportOptions.plist`

**Prerequisite:** Task 11 complete (you need the Apple Team ID recorded from Task 6 Step 2, and the Codemagic integration name `Akeli ASC Key` confirmed from Task 11 Step 2).

**Interfaces:**
- Consumes: Codemagic env var groups `android_signing`, `google_play`; Codemagic integration `Akeli ASC Key`
- Produces: automated build + deploy on every `v*` tag; build health check on every `main` push

---

- [ ] **Step 1: Create `ios/ExportOptions.plist`**

Replace `YOUR_10_CHAR_TEAM_ID` with your actual Apple Team ID from Task 6 Step 2:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_10_CHAR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 2: Create `codemagic.yaml` at the project root**

```yaml
workflows:

  # ── Android: build AAB → upload to Play Store Open Testing (beta) ─────────
  android-release:
    name: Android Release → Open Testing
    max_build_duration: 60
    instance_type: mac_mini_m2
    triggering:
      events:
        - tag
      tag_patterns:
        - pattern: 'v*'
          include: true
      cancel_previous_builds: true
    environment:
      flutter: stable
      groups:
        - android_signing
        - google_play
    scripts:
      - name: Decode keystore from base64
        script: |
          echo $CM_KEYSTORE | base64 --decode > $CM_BUILD_DIR/android/app/akeli-release.keystore
      - name: Generate key.properties
        script: |
          cat > $CM_BUILD_DIR/android/key.properties <<EOF
          storePassword=$CM_KEYSTORE_PASSWORD
          keyPassword=$CM_KEY_PASSWORD
          keyAlias=$CM_KEY_ALIAS
          storeFile=$CM_BUILD_DIR/android/app/akeli-release.keystore
          EOF
      - name: Get Flutter packages
        script: flutter pub get
      - name: Build release Android App Bundle
        script: flutter build appbundle --release --build-number=$CM_BUILD_NUMBER
    artifacts:
      - build/**/outputs/**/*.aab
    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: beta      # "beta" = Open Testing track in Play Console

  # ── iOS: build IPA → upload to App Store Connect (direct submission) ──────
  ios-release:
    name: iOS Release → App Store
    max_build_duration: 120
    instance_type: mac_mini_m2
    triggering:
      events:
        - tag
      tag_patterns:
        - pattern: 'v*'
          include: true
      cancel_previous_builds: true
    environment:
      flutter: stable
      ios_signing:
        distribution_type: app_store
        bundle_identifier: io.akeli.com
    integrations:
      app_store_connect: Akeli ASC Key
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Build release IPA
        script: |
          flutter build ipa --release \
            --build-number=$CM_BUILD_NUMBER \
            --export-options-plist=ios/ExportOptions.plist
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: false
        submit_to_app_store: true

  # ── Build health check on every push to main (no deployment) ─────────────
  build-check:
    name: Build Check (main branch)
    max_build_duration: 30
    instance_type: mac_mini_m2
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: main
          include: true
      cancel_previous_builds: true
    environment:
      flutter: stable
    scripts:
      - name: Get Flutter packages
        script: flutter pub get
      - name: Analyze
        script: flutter analyze
      - name: Run tests
        script: flutter test
      - name: Verify Android debug build
        script: flutter build apk --debug
```

- [ ] **Step 3: Commit both files**

```bash
git add codemagic.yaml ios/ExportOptions.plist
git commit -m "feat(ci): add Codemagic pipeline — Android Open Testing + iOS App Store direct"
```

---

### Task 13: First CI build via tag + complete store submissions

**Prerequisite:** All previous tasks complete. Both store listings must have privacy policy URL, descriptions, and all required screenshots entered.

---

- [ ] **Step 1: Push all commits to main and verify build-check passes**

```bash
git push origin main
```

Go to Codemagic → your app → **Builds**. Wait for the `build-check` workflow to complete with a green checkmark (~15 min). If it fails, fix the issue before proceeding to the tag.

- [ ] **Step 2: Tag v1.0.0 and push**

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers both `android-release` and `ios-release` workflows simultaneously.

- [ ] **Step 3: Monitor both Codemagic builds**

In Codemagic → Builds, you'll see two builds starting in parallel:
- **Android Release → Open Testing** (~15–20 min)
- **iOS Release → App Store** (~30–45 min)

Click each build to stream the logs. Common errors and fixes:

| Error | Location | Fix |
|---|---|---|
| `Keystore file 'akeli-release.keystore' not found` | Android build Step 1 | Re-encode the keystore — update `CM_KEYSTORE` in Codemagic env vars |
| `Bundle identifier does not match` | iOS signing | Verify `io.akeli.com` in both `project.pbxproj` and `codemagic.yaml ios_signing` |
| `Missing Push Notifications entitlement` | iOS build | Complete Task 2 Step 4 on a Mac (add Push Notifications capability in Xcode) |
| `google_play: track 'beta' not found` | Android publish | Verify Task 4 (first manual upload) was completed — the track must exist before automation can use it |
| `Integration 'Akeli ASC Key' not found` | iOS signing | Verify the integration name in Codemagic matches exactly: `Akeli ASC Key` |

- [ ] **Step 4: Complete the iOS App Store submission**

After the iOS build succeeds, the IPA is automatically uploaded to App Store Connect. Go to App Store Connect → Akeli → **iOS App** section:

1. Select the uploaded build (it appears under the **TestFlight** tab initially, then in **App Store** → Prepare for Submission)
2. Fill in **App Review Information**:
   - Sign-in required: Yes
   - Demo account username: a test Supabase account you created
   - Demo account password: that account's password
   - Notes to reviewer: `This is an African cuisine nutrition app. The reviewer can create an account or use the provided test credentials. Push notifications require device testing.`
3. Verify the French store listing shows no warnings
4. Click **Submit for Review**

Apple review time: typically 24–48 hours for first submissions.

- [ ] **Step 5: Verify Android Open Testing**

Play Console → **Release** → **Testing** → **Open testing**: the Codemagic-uploaded AAB should appear as a new release (build 2, since build 1 was the manual upload in Task 4).

If it shows "Pending publication", click **Review release** → **Start rollout to Open testing**.

- [ ] **Final verification:**
  - Codemagic → Builds: both `android-release` and `ios-release` show green ✓
  - App Store Connect: Akeli status = **"Waiting for Review"**
  - Play Console → Open testing: release published and rollout active
  - Future releases: push a `v1.0.1` tag → Codemagic automatically builds and deploys to both stores

---

## Post-Launch: Promoting Android to Production

After the open beta period, promote the tested release to production in Play Console:

1. Play Console → Release → Production → **Create new release**
2. Click **Add from library** → select the AAB from the Open testing track
3. Set rollout percentage (start at 20% for staged rollout, increase to 100% over a few days)
4. Click **Review release** → **Start rollout to Production**

No new build required — the same signed AAB is promoted.
