# Changelog

## 1.0.0 — 2026-10-30

First release. Android APK on
[GitHub Releases](https://github.com/kaysman/healthy_hour/releases/tag/v1.0.0).

### Added

- **Reminders that fire while the app is closed.** Water and walking
  notifications inside the working window, planned from the same
  timestamps as the on-screen countdowns and rescheduled whenever a
  session, drink or setting changes. Restored after a reboot.
- **A new Home.** One ring for whichever habit is due next, one-tap
  `Start walk` / `Back to work` and `Drank water` with a five-second Undo,
  and an hour grid that scores each working hour as healthy when it has
  both a walk and a drink. Tapping an hour lists what was logged in it, to
  edit a walk's start or delete a walk or drink.
- **A drink log**, kept for two days, instead of only the last drink.
- **The Working / Walking tint on every screen**, not just Home.
- App icon, launch screen, and a monochrome notification icon.
- 109 app tests and 7 design-system tests, run in CI with format and
  analyze checks.

### Fixed

- Settings had no back button, and Android's back gesture closed the app.
- Status-bar icons were white on light screens.
- Android 12+ launch theme referenced a nonexistent attribute and broke
  the build.
- `HiveSessionRepository.close()` always threw.

### Removed

- The pan/zoom timeline, replaced by the hour grid.
