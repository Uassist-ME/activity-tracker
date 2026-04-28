# activity_tracker

A Flutter desktop application targeting macOS and Windows.

## Environment Configuration

This project uses `--dart-define-from-file` to inject environment-specific values (API URL, keys, etc.) at compile time. Env files live in [env/](env/) and are read by [lib/core/config/env.dart](lib/core/config/env.dart).

Real env files (`env/dev.json`, `env/staging.json`, `env/prod.json`) are git-ignored. Copy [env/dev.example.json](env/dev.example.json) to `env/dev.json` and fill in your local values before running the app for the first time.

## Running the App

Pick the env file that matches the environment you want to run against.

```bash
# Development
flutter run --dart-define-from-file=env/dev.json

# Staging
flutter run --dart-define-from-file=env/staging.json

# Production (local verification only — not for distribution)
flutter run --dart-define-from-file=env/prod.json
```

Values are accessed in Dart via the `Env` class:

```dart
import 'package:activity_tracker/core/config/env.dart';

final url = Env.apiUrl;
if (Env.isProd) { /* ... */ }
```

## Release Builds

### macOS

```bash
flutter build macos --release --dart-define-from-file=env/prod.json
```

Output: `build/macos/Build/Products/Release/activity_tracker.app`

#### Packaging as a `.dmg`

Requires [`create-dmg`](https://github.com/create-dmg/create-dmg) (install via Homebrew: `brew install create-dmg`).

```bash
create-dmg \
  --volname "ActivityTracker" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "activity_tracker.app" 150 200 \
  --app-drop-link 450 200 \
  "ActivityTrackerApp.dmg" \
  "build/macos/Build/Products/Release/activity_tracker.app"
```

Flag reference:
- `--volname` — name shown in Finder when the DMG is mounted
- `--window-size 600 400` — DMG window dimensions (width × height)
- `--icon-size 100` — icon size inside the window
- `--icon "activity_tracker.app" 150 200` — positions the app icon on the **left** at `(150, 200)`
- `--app-drop-link 450 200` — adds the Applications shortcut on the **right** at `(450, 200)`, so the user drags the app onto it to install

Output: `ActivityTrackerApp.dmg` in the current directory.

> Note: the app inside the DMG is named `activity_tracker.app` (Flutter's default). To rename it to `ActivityTracker.app`, update `CFBundleName` in `macos/Runner/Info.plist`.

#### Installing a new version

The app is ad-hoc signed, so macOS treats every rebuild as a new app and ignores the previously granted Accessibility / Automation permissions. Before installing a new DMG, fully quit the running app and reset its TCC entries:

```bash
tccutil reset Accessibility com.example.activityTracker
tccutil reset AppleEvents   com.example.activityTracker
```

Then replace `/Applications/activity_tracker.app` with the new build and launch it — macOS will prompt for permissions fresh.

### Windows

```bash
flutter build windows --release --dart-define-from-file=env/prod.json
```

Output: `build/windows/x64/runner/Release/` — contains `activity_tracker.exe`, required `.dll`s, and a `data/` folder. **All files in this folder must be distributed together** — the app will not run if you ship only the `.exe`.

For distribution, choose one:

- **Zip the folder** — simplest, no installer, user extracts and runs the `.exe`.
- **MSIX package** — add the [`msix`](https://pub.dev/packages/msix) pub dev dependency, then `dart run msix:create`. Produces a single `.msix` installer.
- **Inno Setup / WiX** — traditional `.exe` installer, more configurable.

## Project Structure

```
lib/
  core/
    config/
      env.dart          # Typed env accessor (Env.apiUrl, etc.)
  main.dart
env/
  dev.json              # Git-ignored, local only
  staging.json          # Git-ignored
  prod.json             # Git-ignored
  dev.example.json      # Committed template
```

## Resources

- [Flutter docs](https://docs.flutter.dev/)
- [Dart-define reference](https://dart.dev/tools/dart-define)
