# phaser-example

Top-down (3/4 view) gather-and-build game prototype written in **Flutter** for Android, iOS and the web. The
world is drawn with **Flame**; the HUD is plain Flutter widgets. The code follows the team's Flutter Clean
Architecture conventions (`flutter-arch-conventions`): `core/` plus `domain` / `data` / `presentation` layers,
get_it + injectable, BLoC and easy_localization.

```
lib/
  main.dart
  core/          assets (LPC art, i18n), config (enums, env, DI), error-handling, services, utils
  layers/
    domain/      entities, world (simulation aggregate), quests, rules, repositories, use-cases
    data/        datasources (procedural level, in-memory session), repositories (with mappers)
    presentation/ app (ContainerApp), features/forest (BLoC, Flame game + render constants, HUD widgets), theme, widgets
test/            mirrors lib/, plus mocks/ and architecture_test.dart
android/ ios/ web/  Flutter runners
asset-packs/lpc/ LPC art sources and build_assets.py
```

Layer rules are checked by `test/architecture_test.dart`.

Gather-and-build loop: pick up the axe next to the spawn point, tap or click a tree to chop it (5 hits,
5–6 wood each), then use **Construir** to place a house (15 wood) and watch it being built. **Misiones** lists the
current goals and their progress.

## Run locally

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # DI config and mockito mocks (committed)
flutter analyze
flutter test                                                # all tests on the VM
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart   # forest golden values on the web
flutter run -d chrome                                       # web
flutter run -d emulator-5554                                # Android emulator
flutter run -d "iPhone 17"                                  # iOS simulator
```

Needs the Flutter SDK (stable, 3.47.6), Chrome for the web, the Android SDK and Xcode for the mobile targets.

Every push to `main` that touches the app runs analysis and tests, builds the web app with
`--base-href /phaser-example/` and `--dart-define-from-file=lib/core/config/env/production_environment.json`, and
publishes `build/web` to GitHub Pages: https://apergas.github.io/phaser-example/ (`.github/workflows/deploy.yml`).
CI pins Flutter 3.47.6 (`flutter-version` in `subosito/flutter-action`); to bump it, change that value in its own
commit together with any `pubspec.yaml`/`pubspec.lock` update it needs.

## Art

- `asset-packs/lpc/` — Liberated Pixel Cup sources and `build_assets.py`, which generates the textures in
  `lib/core/assets/images/lpc/`, the single copy the app reads on every platform (requires Pillow):
  `cd asset-packs/lpc && python3 build_assets.py`.

LPC art is licensed CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0 and requires attribution:
see [`lib/core/assets/images/lpc/CREDITS.md`](lib/core/assets/images/lpc/CREDITS.md).
