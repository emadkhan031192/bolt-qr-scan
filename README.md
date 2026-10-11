# Bolt QR Scan and Generator

A fully offline QR & barcode scanner + generator. No ads, no login, no analytics — everything stays on the phone.

## What it does

- **Scan** QR codes and barcodes with the camera (bundled ML Kit, works offline on first run) or **pick an image from the gallery**.
- **Generate** QR codes from text, URLs, Wi-Fi credentials, contacts (vCard), phone numbers, SMS, email, and location — and share or save them as PNG images.
- Scan history kept on-device (view, copy, re-open, delete).
- Flash toggle, beep on successful scan, and quick action buttons (open URL, call, SMS, email, add Wi-Fi, open map) based on what the code contains.

## Privacy

- Fully offline: no ads, no accounts, no analytics, no tracking.
- Only permission: **CAMERA** (plus legacy storage on Android 9 and below so saving to the gallery works there).
- `android:allowBackup="false"` — nothing leaves the device.

## How the GitHub build works

`.github/workflows/build.yml` runs on every push, manually (`workflow_dispatch`), and on tags `v*`:

1. Check out the repo
2. Set up Java 17 (Temurin) and Flutter **3.47.7**
3. `flutter pub get` → `flutter analyze` → `flutter test`
4. `flutter build apk --release --split-per-abi` (one APK per CPU architecture, signed if release secrets are present)
5. Upload the APKs as the `apk-per-abi` artifact
6. On a `v*` tag, the `release` job downloads the artifacts and attaches them to a GitHub release

## Download & install

1. Open the latest workflow run (or tagged release) on GitHub → **Artifacts** → `apk-per-abi`.
2. Pick the APK for your device (most phones are `arm64-v8a`).
3. Copy it to your phone and open it; allow "Install unknown apps" when asked, then tap **Install**.
4. On first launch, grant the **Camera** permission when prompted.

## Release signing setup

Create a keystore once (on your own machine):

```bash
keytool -genkey -v -keystore keystore.jks -alias boltscan -keyalg RSA -keysize 2048 -validity 10000
```

Then add these four repository secrets (GitHub → Settings → Secrets and variables → Actions):

| Secret              | Value                                                          |
|---------------------|----------------------------------------------------------------|
| `KEYSTORE_BASE64`   | `base64 -w0 keystore.jks` output                               |
| `KEYSTORE_PASSWORD` | the keystore password                                          |
| `KEY_ALIAS`         | the alias (e.g. `boltscan`)                                    |
| `KEY_PASSWORD`      | the key password                                               |

If no secrets are set, the build still succeeds and signs with the debug key (fine for testing, not for distribution).

## Known deviations from the original build spec

- **Low-light auto flash suggestion skipped** — `mobile_scanner` exposes no brightness API, so there is nothing to trigger it on; the flash toggle is one tap away on the scan screen.
- **Wi-Fi Connect opens Wi-Fi settings + copies the password** — a true one-tap add needs a `WifiNetworkSuggestion` platform channel and behaves inconsistently across OEMs, so the app hands you off to system settings with the password on the clipboard.
- **"Detected in X.XX s" is measured from scan-session start** (controller start/resume/mode change/sheet dismiss) to the first `onDetect` callback — the plugin exposes no per-frame timestamps.
- `WRITE_EXTERNAL_STORAGE` is declared with `android:maxSdkVersion="29"` (needed only on API ≤ 29 for the `gal` save plugin).
- The result sheet's rise animation uses the platform bottom-sheet default (spec target was ~160 ms).
