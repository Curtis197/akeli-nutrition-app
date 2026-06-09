# Android Play Store Deployment Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Akeli Flutter app to Google Play Store via a GitHub Actions CI/CD pipeline with no manual build steps after first setup.

**Architecture:** Local signing keys are generated once and stored as GitHub Secrets. On every push to `main`, GitHub Actions builds the release AAB, signs it, and uploads it to the Play Store internal track. The first AAB upload to Play Console must be done manually (Google requirement); after that, all updates are automated.

**Tech Stack:** Flutter (Android AAB), keytool (JDK 21, already installed), GitHub Actions, `r0adkll/upload-google-play` action, Google Play Developer API (service account).

---

## Prerequisites

- JDK 21 with `keytool` — already installed at `C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\bin\keytool.exe`
- Flutter SDK — already installed
- GitHub repo — `Curtis197/akeli-nutrition-app`
- A Google Play Developer account ($25 one-time fee if not already registered)

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `android/app/akeli-release.keystore` | Create (gitignored) | Release signing key |
| `android/key.properties` | Create (gitignored) | Keystore credentials for Gradle |
| `android/app/build.gradle.kts` | Modify | Load signing config from key.properties |
| `.gitignore` | Modify | Exclude keystore + key.properties |
| `.github/workflows/deploy-android.yml` | Create | CI/CD: build AAB + upload to Play Store |

---

## Task 1: Generate the Release Keystore

**Files:**
- Create: `android/app/akeli-release.keystore`

> **IMPORTANT:** Store the passwords you choose in a password manager. If you lose the keystore or its passwords, you cannot update the app on Play Store — ever. There is no recovery.

- [ ] **Step 1: Run keytool to generate the keystore**

Open PowerShell in the project root and run:

```powershell
& "C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\bin\keytool.exe" `
  -genkey -v `
  -keystore android\app\akeli-release.keystore `
  -alias akeli-key `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

You will be prompted for:
- **Keystore password** — choose a strong password, save it as `KEYSTORE_STORE_PASSWORD`
- **Key password** — can be the same or different, save it as `KEYSTORE_KEY_PASSWORD`
- **First and last name** — your name or "Akeli"
- **Organization unit** — "Engineering" or press Enter
- **Organization** — "Akeli" or press Enter
- **City, State, Country code** — fill in your details

Expected output ends with:
```
[Storing android\app\akeli-release.keystore]
```

- [ ] **Step 2: Verify the keystore was created**

```powershell
& "C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\bin\keytool.exe" `
  -list -v `
  -keystore android\app\akeli-release.keystore `
  -alias akeli-key
```

Expected: Entry type `PrivateKeyEntry`, algorithm `RSA`, validity `10000` days.

---

## Task 2: Protect Secrets in .gitignore

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add keystore and key.properties to .gitignore**

Open `.gitignore` and add these lines (or verify they're already present):

```gitignore
# Android signing — never commit these
android/key.properties
android/app/*.keystore
android/app/*.jks
```

- [ ] **Step 2: Verify neither file is tracked**

```powershell
git status android/key.properties android/app/akeli-release.keystore
```

Expected: both files listed under "Untracked files" (not staged). If they show as tracked, run:
```powershell
git rm --cached android/key.properties android/app/akeli-release.keystore
```

- [ ] **Step 3: Commit the .gitignore update**

```powershell
git add .gitignore
git commit -m "chore(android): gitignore release keystore and key.properties"
```

---

## Task 3: Create key.properties

**Files:**
- Create: `android/key.properties`

- [ ] **Step 1: Create android/key.properties with your credentials**

Replace `YOUR_STORE_PASSWORD` and `YOUR_KEY_PASSWORD` with the passwords you chose in Task 1:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=akeli-key
storeFile=akeli-release.keystore
```

> `storeFile` is a path relative to the `android/app/` directory where the keystore lives.

---

## Task 4: Configure Gradle Release Signing

**Files:**
- Modify: `android/app/build.gradle.kts`

- [ ] **Step 1: Replace the current build.gradle.kts**

Open [android/app/build.gradle.kts](android/app/build.gradle.kts). Replace the full file content with:

```kotlin
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.akeli.nutrition"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "akeli-key"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.akeli.nutrition"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
```

- [ ] **Step 2: Commit the Gradle change**

```powershell
git add android/app/build.gradle.kts
git commit -m "feat(android): configure release signing from key.properties"
```

---

## Task 5: Build and Verify the Release AAB Locally

**Files:** none — output goes to `build/app/outputs/bundle/release/app-release.aab`

- [ ] **Step 1: Build the release AAB**

```powershell
flutter build appbundle --release
```

Expected output ends with:
```
Built build/app/outputs/bundle/release/app-release.aab (xx.x MB).
```

- [ ] **Step 2: Verify it is signed with the release key (not debug)**

```powershell
& "C:\Program Files\Microsoft\jdk-21.0.10.7-hotspot\bin\keytool.exe" `
  -printcert `
  -jarfile build\app\outputs\bundle\release\app-release.aab
```

Expected: the certificate owner matches what you entered in Task 1 (your name / "Akeli"). If you see "Android Debug" as the owner, the signing config was not picked up — re-check `key.properties`.

---

## Task 6: Google Play Console Manual Setup

> **This task cannot be automated.** Google requires the first AAB upload to be done via the web UI. After this, all subsequent uploads are automated via CI.

- [ ] **Step 1: Create or log in to your Play Developer account**

Go to [play.google.com/console](https://play.google.com/console). Pay the $25 one-time registration fee if not already registered.

- [ ] **Step 2: Create a new app**

- Click **"Create app"**
- App name: `Akeli`
- Default language: English (or French if primary audience is Francophone Africa)
- App or game: `App`
- Free or paid: your choice
- Accept policies → **Create app**

- [ ] **Step 3: Complete the required store listing fields**

Under **Grow > Store presence > Main store listing**, fill in at minimum:
- Short description (80 chars)
- Full description (4000 chars)
- 2 screenshots (min)
- Feature graphic (1024×500 px)
- App icon (512×512 px, already in Flutter assets)

- [ ] **Step 4: Upload the first AAB manually to Internal Testing**

- Go to **Testing > Internal testing > Create new release**
- Upload `build/app/outputs/bundle/release/app-release.aab`
- Add release notes → **Save** → **Review release** → **Start rollout**

> **This is required once.** After this, the CI workflow handles all future uploads.

- [ ] **Step 5: Set up Play Console API access**

- Go to **Setup > API access**
- Click **"Link to an existing Google Cloud project"** (or create a new one)
- Note the Google Cloud project ID

- [ ] **Step 6: Create a service account**

- Click **"Create new service account"** — this opens Google Cloud Console
- In Google Cloud Console: **IAM & Admin > Service Accounts > Create service account**
  - Name: `akeli-play-deploy`
  - Role: `Service Account > Service Account User`
  - Click **Done**
- Click the service account → **Keys > Add key > Create new key > JSON**
- Download the JSON file — this is `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

- [ ] **Step 7: Grant the service account Play Console access**

- Back in Play Console → **Setup > API access**
- Find `akeli-play-deploy` in the service accounts list → **Grant access**
- Role: **Release manager**
- Click **Invite user** → **Apply**

---

## Task 7: Create GitHub Actions Deployment Workflow

**Files:**
- Create: `.github/workflows/deploy-android.yml`

- [ ] **Step 1: Create the workflow file**

Create `.github/workflows/deploy-android.yml` with this content:

```yaml
name: Deploy to Google Play

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/akeli-release.keystore

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_STORE_PASSWORD }}
          keyPassword=${{ secrets.KEYSTORE_KEY_PASSWORD }}
          keyAlias=${{ secrets.KEYSTORE_KEY_ALIAS }}
          storeFile=akeli-release.keystore
          EOF

      - name: Build release AAB
        run: flutter build appbundle --release --build-number=${{ github.run_number }}

      - name: Upload to Google Play (internal track)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.akeli.nutrition
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
          status: completed
          releaseName: ${{ github.run_number }}
```

- [ ] **Step 2: Commit the workflow**

```powershell
git add .github/workflows/deploy-android.yml
git commit -m "feat(ci): add GitHub Actions deploy-to-Play-Store workflow"
```

---

## Task 8: Configure GitHub Secrets

> Done via the GitHub web UI at **github.com/Curtis197/akeli-nutrition-app/settings/secrets/actions**.

- [ ] **Step 1: Base64-encode the keystore**

In PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\akeli-release.keystore")) | Set-Clipboard
```

Go to GitHub Secrets → **New repository secret**:
- Name: `KEYSTORE_BASE64`
- Value: paste from clipboard

- [ ] **Step 2: Add remaining secrets**

Add these four secrets (one by one):

| Secret name | Value |
|-------------|-------|
| `KEYSTORE_STORE_PASSWORD` | Your store password from Task 1 |
| `KEYSTORE_KEY_PASSWORD` | Your key password from Task 1 |
| `KEYSTORE_KEY_ALIAS` | `akeli-key` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Full contents of the JSON key file from Task 6 Step 6 |

---

## Task 9: Trigger and Verify the Pipeline

- [ ] **Step 1: Push to main to trigger the workflow**

```powershell
git push origin main
```

- [ ] **Step 2: Watch the workflow run**

Go to [github.com/Curtis197/akeli-nutrition-app/actions](https://github.com/Curtis197/akeli-nutrition-app/actions).

Click the **"Deploy to Google Play"** run. All steps should be green.

If the `Upload to Google Play` step fails with `"No existing APKs or AABs"` — this means the first manual upload in Task 6 Step 4 wasn't completed. Do that first, then re-run the workflow.

- [ ] **Step 3: Confirm in Play Console**

Go to **Testing > Internal testing** in Play Console. The new release (build number = GitHub run number) should appear within a few minutes.

---

## Summary

After completing all tasks:
- Every `git push origin main` automatically builds a signed AAB and uploads it to the Play Store internal track
- To promote to production: in Play Console → **Production > Create new release** → promote from internal track
- To bump the public version: update `version` in `pubspec.yaml` (e.g. `1.0.1+2`); the `+N` suffix is overridden by `--build-number=${{ github.run_number }}` in CI
