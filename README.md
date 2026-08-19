# Healthy Hour

[![CI](https://github.com/kaysman/healthy_hour/actions/workflows/ci.yml/badge.svg)](https://github.com/kaysman/healthy_hour/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flutter app for **Healthy Hour** — alternates between Working and Walking
sessions and reminds you to drink water.

Bloc + Hive, feature-first folders inside `lib/`, with a single shared
package for the design system.

> **Status:** work in progress, built in the open. The app runs and the
> screens below are real, but it has never been released and it does not
> notify you yet. [What's done and what isn't](#status).

## Screens

All six screens below are the Home surface in different states / themes.
Settings is reached via the `Working Time` / `Adjust` pill
in the top-right.

### Light theme

| Working                                                                                                                                                                                   | Walking                                                                                                                                                                    | Session selected                                                                                                                                                                                                          |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Home – working, light](docs/screens/Home.png)                                                                                                                                           | ![Home – walking, light](docs/screens/Home-1.png)                                                                                                                          | ![Home – session selected, light](docs/screens/Home-2.png)                                                                                                                                                                |
| Working session running. Soft green tint at the top, `🧑‍💻` hero with live `06:34:12` duration, `Have a walk` CTA, ruler timeline anchored to **Now**, Water 💧 + Walking 👟 cards beneath. | Walking session running. Tint shifts to warm yellow, hero swaps to `👟`, CTA flips to `Continue working`. The `Working Time` pill turns into the brand-green active state. | A past `Walking` segment is tapped on the timeline. The selected bar is ringed in green; an actions card (edit ✏️ / delete 🗑️) animates in above the strip. Tapping edit opens a time picker; delete removes the session. |

### Dark theme

| Working                                                                                       | Walking                                                                              | Session selected                                                                                            |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| ![Home – working, dark](docs/screens/Home-3.png)                                              | ![Home – walking, dark](docs/screens/Home-4.png)                                     | ![Home – session selected, dark](docs/screens/Home-5.png)                                                   |
| Same layout, dark surface. Working tint is a deep green wash at the top fading to near-black. | Walking tint is a warm amber wash, brand-green CTA pops against the dark background. | Selection + actions card on dark surface, with the same green selection ring and edit / delete affordances. |

### Settings — `/settings`

- **Working window** — start / end time chips; tap to open a `TimePicker`.
- **Water reminder** — interval slider, 5–90 minutes, drives the Water
  ring on Home.
- **Walking reminder** — interval slider, same range, drives the
  Walking ring on Home.

## How the timer works

There is no countdown, and nothing accumulates elapsed time.

A `Session` stores two fields that matter: `startedAt`, and a nullable
`endedAt`. The session whose `endedAt` is still null is the one you're in.
`HomeBloc` ticks once a second, and the only thing that tick does is push
the current wall-clock `now` into state:

```dart
Duration durationAt(DateTime moment) => (endedAt ?? moment).difference(startedAt);
```

Every number on screen — the hero duration, the timeline segments, the
water and walking rings — is derived from that. The state object holds no
counter:

```dart
Duration get currentDuration => current?.durationAt(now) ?? Duration.zero;
```

The useful consequence is that there is nothing to drift. Backgrounding the
app, being killed by the OS, or coming back hours later all yield the right
duration, because the duration was never stored — it is recomputed from two
timestamps and the current clock. Editing a past session is just moving a
timestamp, and every derived value follows for free.

The same choice is what makes the timeline editable at all. Sessions are an
append-only log of what actually happened, not a machine with a running
total, so "delete this walk" or "that walk started 10 minutes earlier" are
ordinary edits rather than surgery on accumulated state.

`HomeBloc` also takes an injectable `Clock`, which is what makes any of this
testable without waiting in real time.

## Layout

```
healthy_hour/
├─ android/                       # generated by `flutter create`
├─ ios/                           # generated by `flutter create`
├─ lib/
│  ├─ main.dart                   # entrypoint
│  └─ src/
│     ├─ app.dart, app_observer.dart, router.dart
│     ├─ core/                    # DateTime/Duration extensions, typedefs
│     ├─ domain/                  # pure-Dart entities, repos, use-cases
│     ├─ data/                    # Hive-backed repository implementations
│     └─ features/
│        ├─ home/                 # HomeBloc + HomePage + widgets (incl. embedded timeline)
│        └─ settings/             # SettingsBloc + SettingsPage
├─ test/
├─ packages/
│  └─ healthy_hour_ui_kit/        # design system: theme, icons, widgets, DurationFormatter
├─ pubspec.yaml
└─ analysis_options.yaml
```

`healthy_hour_ui_kit` is the only local package — kept separate so the
design system has no app coupling and can be reused (companion apps,
storybooks, marketing site). It's wired in via a `path:` dependency in
`pubspec.yaml`.

## First-time setup

The `android/` and `ios/` projects are committed, so there is no
`flutter create` step. Bundle id is `com.ikayapps.healthy_hour`.

```bash
flutter pub get
```

## Running

```bash
flutter run
```

## Quality gates

All three run on every push and pull request — see
[`.github/workflows/ci.yml`](.github/workflows/ci.yml).

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

`flutter analyze` and `dart format` cover `packages/` from the root, but
`flutter test` does not — the design system has its own suite:

```bash
cd packages/healthy_hour_ui_kit && flutter test
```

## Status

Working:

- Home — working/walking switching, live duration, water and walking rings,
  and an interactive timeline you can pan, pinch-zoom, select, edit, delete.
- Settings — working window, water interval, walking interval.
- Local persistence through Hive, with the domain layer kept pure Dart.
- Design system extracted to `packages/healthy_hour_ui_kit`.
- Light and dark themes.
- `flutter analyze` clean under `very_good_analysis`.

Not there yet:

- **No notifications.** The intervals drive the on-screen rings only;
  nothing fires while the app is closed. This is the biggest gap between the
  app and its own premise, and it's next.
- **No sync, no accounts.** Everything is on-device. An Express + Prisma +
  Postgres service — JWT auth, session CRUD, settings — is written but is
  not wired to the app or published yet.
- **Thin tests.** One widget smoke test and three formatter unit tests. The
  Blocs and use-cases are untested, which is a shame given `HomeBloc` takes
  an injectable clock specifically so they'd be easy to test.
- Not on any store.

## Code generation

`hive_ce_generator` produces `*.g.dart` files for Hive type adapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## License

[MIT](LICENSE) © Atabek Kadir
