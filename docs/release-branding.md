# Release Branding Checklist (US Launch)

This guide defines icon asset requirements and text metadata standards for a production release.

## 1) Source Icon Requirement

Prepare one master icon file:

- File path: `assets/branding/app_icon_1024.png`
- Size: `1024x1024 px`
- Format: PNG
- Color profile: sRGB
- Background: fully opaque (no transparency for iOS final output)
- Design: no thin outlines, no tiny text, strong contrast for small sizes

## 2) Recommended Icon Sizes

Use a 1024 master and generate all platform sizes automatically. These are the critical sizes to validate manually:

### iOS

- 1024x1024 (App Store marketing icon, required)
- 180x180 (iPhone home screen)
- 167x167 (iPad Pro home screen)
- 152x152 (iPad home screen)
- 120x120 (legacy iPhone home screen)

### Android

- 512x512 (Google Play listing icon, required in store console)
- 192x192 (xxxhdpi launcher)
- 144x144 (xxhdpi launcher)
- 96x96 (xhdpi launcher)
- 72x72 (hdpi launcher)
- 48x48 (mdpi launcher)

## 3) Generate Launcher Icons

After placing `assets/branding/app_icon_1024.png`, run:

```bash
flutter pub get
dart run flutter_launcher_icons
```

The command generates iOS `AppIcon.appiconset` images and Android launcher assets.

## 4) Verify Before Store Submission

- iOS icon has no alpha channel and no rounded corners baked in.
- Android icon is visually centered and readable on dark/light wallpapers.
- App name shown under icon is `Emotion Release`.
- Store listing title, short description, and full description use final US copy.
