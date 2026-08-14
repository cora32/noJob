# noJob

A depressing dashboard for your job applications rejections.

## Build Instructions

### 1. Initialize the Project

Before building for any platform, ensure you have the dependencies and generated files ready:

```bash
# Install dependencies
flutter pub get

# Generate localization files (.arb)
flutter gen-l10n

# Run code generation (for Riverpod and other generators)
dart run build_runner build --delete-conflicting-outputs
```

### 2. Build for Specific Platforms

#### Windows (Desktop)

To build for Windows, you must have NuGet installed and configured in your system's PATH:

1. **Install NuGet:**
    * Download the `nuget.exe` CLI from [nuget.org/downloads](https://www.nuget.org/downloads).
    * Place the `nuget.exe` file in a dedicated folder (e.g., `C:\tools\nuget\`).

2. **Add to Path:**
    * Open the **Start Search**, type in "env", and choose "Edit the system environment variables".
    * Click the **Environment Variables...** button.
    * Under **System Variables**, find the **Path** variable and select it. Click **Edit...**.
   * Click **New** and add the full path to the folder where you placed `nuget.exe`.
    * Click **OK** on all windows to save the changes.
   * Restart your terminal or IDE.

**Build Command:**

```bash
flutter build windows
```

The executable will be located in `build/windows/x64/runner/Release/nojob.exe`.

#### Android

```bash
# To build an APK
flutter build apk

# To build an App Bundle (for Play Store)
flutter build appbundle
```

The outputs will be in `build/app/outputs/flutter-apk/` or `build/app/outputs/bundle/release/`.

#### Web

```bash
flutter build web
```

The production-ready web files will be in the `build/web/` directory.
