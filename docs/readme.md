# Emotion App Codebase Guide

## Overview
This Flutter app lets users pick an emotion, hold a button to "release" it, optionally leave a note, and review past moments. Data is stored locally on device.

## File-Level Structure and Responsibilities

### Root
- [lib/main.dart](../lib/main.dart)
  - App entry point. Boots Flutter and launches `LetGoApp`.

### App Shell
- [lib/ui/app.dart](../lib/ui/app.dart)
  - Configures `MaterialApp` (title, theme) and sets the initial route to `HomeScreen`.

### Theme
- [lib/ui/core/themes/app_theme.dart](../lib/ui/core/themes/app_theme.dart)
  - Centralized colors, text styles, spacing, and `ThemeData`.

### Domain Models
- [lib/domain/models/emotion.dart](../lib/domain/models/emotion.dart)
  - `Emotion` enum with display labels.
- [lib/domain/models/release_entry.dart](../lib/domain/models/release_entry.dart)
  - `ReleaseEntry` model with JSON serialization/deserialization.

### Local Storage
- [lib/data/local/release_storage.dart](../lib/data/local/release_storage.dart)
  - Reads/writes `ReleaseEntry` list using `SharedPreferences`.
  - New entries are prepended, and only the latest 100 are kept.
  - Provides lookup for the latest non-empty note by emotion.

### Home Feature
- [lib/ui/features/home/screens/home_screen.dart](../lib/ui/features/home/screens/home_screen.dart)
  - Main flow: emotion selection, optional "last note" display, and hold-to-release action.
  - Navigates to `DoneScreen` and resets selection after a save.
- [lib/ui/features/home/screens/done_screen.dart](../lib/ui/features/home/screens/done_screen.dart)
  - Post-release UI: summary, feedback buttons, optional note input, and save action.
  - Persists a `ReleaseEntry` via `ReleaseStorage`.
- [lib/ui/features/home/widgets/hold_release_button.dart](../lib/ui/features/home/widgets/hold_release_button.dart)
  - Interactive hold button, ring animation, timing, and haptics.
- [lib/ui/features/home/widgets/release_visualization.dart](../lib/ui/features/home/widgets/release_visualization.dart)
  - Animated bars based on hold duration.
- [lib/ui/features/home/widgets/emotion_selector.dart](../lib/ui/features/home/widgets/emotion_selector.dart)
  - Grid selection of emotions.
- [lib/ui/features/home/widgets/emotion_chip.dart](../lib/ui/features/home/widgets/emotion_chip.dart)
  - Single emotion chip UI.
- [lib/ui/features/home/widgets/feedback_button.dart](../lib/ui/features/home/widgets/feedback_button.dart)
  - Feedback selection pill.

### History Feature
- [lib/ui/features/history/screens/history_screen.dart](../lib/ui/features/history/screens/history_screen.dart)
  - Lists saved `ReleaseEntry` items in reverse chronological order.

## Current App Logic (Key Flows)

### Emotion Selection and Last Note
1. User selects an emotion on the home screen.
2. `HomeScreen` fetches the latest note for that emotion via `ReleaseStorage.findLatestMatchingNote`.
3. If found, it displays: “Last time you felt this way, you told yourself: …”.

### Hold-to-Release Interaction
- The hold button uses a `Ticker` and `Stopwatch` to update a ring animation.
- Rotation speed alternates every 2 seconds:
  - 0–2s: base speed (current behavior).
  - 2–4s: faster speed.
  - 4–6s: base speed.
  - 6–8s: faster speed, and so on until release.

### Release Completion and Saving
1. On pointer release, the hold duration is captured.
2. A short release animation plays; upon completion, the entry is reported to the parent.
3. `DoneScreen` constructs a `ReleaseEntry` and saves it through `ReleaseStorage`.

### Storage Logic (Local)
- Stored as a `SharedPreferences` string list under the key `release_entries`.
- Each item is a JSON-encoded `ReleaseEntry`.
- New entries are prepended, so the newest entry is first.
- Only the latest 100 are kept to bound storage size.
- `findLatestMatchingNote` returns the most recent entry with a non-empty note for the chosen emotion.

### Haptics (Vibration)
- In [lib/ui/features/home/widgets/hold_release_button.dart](../lib/ui/features/home/widgets/hold_release_button.dart):
  - A light haptic (`HapticFeedback.lightImpact()`) fires when the user releases the hold.
  - A medium haptic (`HapticFeedback.mediumImpact()`) fires after the release animation completes and just before the callback triggers.

## Notes
- UI copy and visual constants are centralized in `AppTheme`.
- The history list shows emotion, date, and duration for each entry.
