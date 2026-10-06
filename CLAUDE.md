# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

- Single **Flutter** app at the repo root (Android, iOS, web), Dart package `rpg`. All game logic and all views live in `lib/`.
- `lib/core/` — `assets/` (`images/lpc/`: the only copy of the art, with `CREDITS.md`; `images/icons/`: HUD SVG icons; `i18n/translations/es.json` + `i18n/internationalize.dart`), `config/` (`constants/enum/` with every enum, screen-only ones in `enum/forest/`; `di/` with `locator.dart`, `di.dart`, generated `di.config.dart`, `di_environment.dart`; `env/` with `EnvironmentConstants` and the dev/prod `--dart-define-from-file` JSON files), `error-handling/` (`CustomException`, `AppException` cases, `AppExceptionHandler`), `services/logging/` (`Logger`, `CustomLoggerImpl`, `BlocLogger`), `services/navigation/` (`NavigationService` + `NavifyImpl`: navigation, snackbars, error pop-ups), `utils/` (`seeded_random.dart`, `kebab_case.dart`).
- `lib/layers/domain/`, `lib/layers/data/`, `lib/layers/presentation/` — see Architecture.
- `test/` mirrors `lib/`; `test/mocks/` holds centralised mock data; `test/helpers/` has `loadSpanishTranslations` (`spanish_translations.dart`), `pumpUntil` (`pump_until.dart`) and `hud_test_app.dart`; `test/architecture_test.dart` enforces the layer rules.
- `android/`, `ios/`, `web/` — Flutter runners (app name `RPG`, ids `com.apergas.rpg`, landscape only on mobile: Android `userLandscape`, iOS landscape left/right + full screen).
- `asset-packs/lpc/` — raw LPC art and `build_assets.py`, which generates `lib/core/assets/images/lpc/`.
- `.github/workflows/deploy.yml` — Flutter pinned to 3.47.6 (`flutter-version` in `subosito/flutter-action`, bump it in its own commit); on pushes to `main` that touch the app: `build_runner` + `git diff --exit-code`, `flutter analyze`, `flutter test`, golden tests in Chrome, `flutter build web --base-href /phaser-example/` (production env file) and publish `build/web` to GitHub Pages (https://apergas.github.io/phaser-example/). Android and iOS are tested locally only.
- `docs/GAME_DESIGN.md` — game analysis and ideas for new mechanics (not implemented).

## Commands

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs          # regenerate di.config.dart and *.mocks.dart (both committed) after DI/mock changes
flutter analyze                                                   # lints (flutter_lints + prefer_relative_imports); must end with "No issues found!"
flutter test                                                      # all tests on the Dart VM
flutter test test/layers/domain/world                             # filtered
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart   # forest golden values on the web
dart format --line-length 120 <the files you wrote>             # never on di.config.dart or *.mocks.dart
flutter run -d chrome | flutter run -d emulator-5554 | flutter run -d "iPhone 17"
flutter build web --release --base-href /phaser-example/ --dart-define-from-file=lib/core/config/env/production_environment.json
```

Regenerate art after editing the asset script: `cd asset-packs/lpc && python3 build_assets.py` (needs Pillow).

## Architecture

Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DOMAIN <- DATA`, `CORE` used by all. `test/architecture_test.dart` checks that domain imports nothing from data/presentation nor Flutter/Flame/`dart:ui`/`dart:io`, data never imports presentation, presentation never imports data, core imports nothing from `layers/` (except the NavigationService widgets), nothing outside `domain/world/` imports its internals (`WorldState`, `Work`, the systems), Flame stays in `game/` and the page, and entities have only `final` fields.

- `lib/layers/domain/`
  - `entities/<feature>/` — immutable `*Entity` classes: `final` fields, `const` constructor, `copyWith`, computed getters, hand-written `==`/`hashCode`. Geometry, tree, item, decoration, building (`BlueprintEntity`, `BuildingEntity`), player (`InventoryEntity`, `PlayerEntity`, sealed `ActivityEntity`, sealed `IntentEntity`), game (sealed `GameEventEntity`, sealed `ConstructionResultEntity`, `PlayerStatusEntity`, `WorldSnapshotEntity`, `QuestProgressEntity`, `BuildOptionEntity`, `GameSessionEntity`), hero (`CombatStatsEntity`, `HeroEntity`, `HeroStatusEntity`), gear (`GearEntity`), combat (`EnemyEntity`, `ArenaLevelEntity`, `FightTurnEntity`, `FightLogEntity`).
  - `world/` — `World`, the mutable aggregate and only entry point that changes the game. It owns a `WorldState` and delegates to systems: `Navigation`, `Woodcutting`, `Construction`, `pickUpItems`. `World` also owns the hero (`hero`, `updateHero`) and the funds (`funds`, `earn`, `spend`: the only way to pay or get paid). Work mechanics are an `IntentEntity` subtype + a `Work` + one case in `workFor()` (exhaustive `switch`). `advance(deltaMs)` returns `GameEventEntity`s. `world/extensions/` holds the entity operations (`hit`, `hammer`, `add`, `spend`, `missing`, `addTool`, `hasTool`, `walkTo`, `distanceTo`...; `HeroRules`: `stats`, `power`, `equipped`, `nextGear`, `withGear`).
  - `quests/` (`Quest`, `Quests`, `QuestLog` with sticky completion), `rules/` (`Rules` tuning, `Blueprints` catalogue, `Gear` catalogue), `repositories/{level,session}` (interfaces).
  - `use-cases/game/` — one `@Injectable()` class per action with a synchronous `call()`: start game, move player, chop tree, can place / construct building, advance, player status, world snapshot, build options, quests; `hero/`: `GetHeroStatusUseCase`. Each reads the session from `GameSessionRepository`.
- `lib/layers/data/` — `datasources/level` (`LevelLocalDatasourceImpl`: seeded procedural forest that also decides each tree's kind and the ground decoration; all-nullable DBOs in `local/dbo/`), `datasources/session` (in-memory, `@LazySingleton`: one game per app), `repositories/level` (`LevelRepositoryImpl` + injected `*MapperDBO`s), `repositories/session`. Errors go through `AppExceptionHandler`.
- `lib/layers/presentation/`
  - `app/` — `ContainerApp` (`MaterialApp` with easy_localization and the navigator key of `NavigationService`) and `ContainerAppBloc`, which replaces the start screen with `ForestPage` through `NavigationService`.
  - `features/forest/bloc/` — `ForestBloc` (single `on<ForestEvent>` with `await switch`; events `ForestStarted`, `ForestTicked`, `ForestMapClicked`, `ForestPointerMoved`, `ForestBuildRequested`, `ForestPlacementCancelled`; states `ForestInitial` / `ForestInProgress` / `ForestSuccess` / `ForestFailure` carrying `ForestData`). Handlers are synchronous so ticks keep frame order. Messages are snackbars through `NavigationService`.
  - `features/forest/models/` — view models (`PlayerRenderData`, sealed `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `ResourceItemData`, `ToolItemData`, `PlacementData`) and sealed `ForestEffect` (played once per emitted state).
  - `features/forest/game/` — Flame, the only place besides `forest_page.dart` that may import `package:flame` / `flame_bloc` (rule in `architecture_test.dart`): `ForestGame` (`update` caps `dt` at 100 ms once and uses that value for `ForestTicked` and for every component, so animations never run ahead of the simulation) + `ForestWorld` + `ForestSceneComponent` + `ForestStateListener` (reconciles components with `ForestData.world` by id; plays effects), `components/` (ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player), `atlas/` (`LpcAtlas` for `forest.json`, `AlphaMask`, `LpcAssets` + loader, `SpriteNames`), `render/` (`RenderConstants`, depth, position conversion, easing, tree motion, player frames, `CameraFraming` working with `Offset`/`Size`, not Flame vectors), `particles/`.
  - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` + `QuestRow`, `PlacementBar` (touch), `HudPanel`, `HudButton`; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
  - `widgets/` — `CustomButton`, `CustomPopUp` (used by `NavifyImpl`). `theme/` — `colors/custom_colors.dart`, `styles/custom_text_styles.dart`, `images/custom_icons.dart`, `custom_theme.dart`.

Documented exceptions to the plugin (keep them; do not "fix" them):

- E1 — `domain/world/`, `domain/quests/`, `domain/rules/` (and `domain/combat/` from the arena plan) exist besides entities/repositories/use-cases: the simulation is a mutable aggregate.
- E2 — entity operations live in `domain/world/extensions/`; entities keep only computed getters.
- E3 — use cases have a synchronous `call()`: the game advances per frame with no I/O.
- E4 — entities use the enums in `core/config/constants/enum/` (`TreeKind`, `ToolKind`, ...).
- E5 — `GameSessionLocalDatasource` stores the `GameSessionEntity` in memory (no DBO).
- E6 — repositories read only the local datasource (no remote, no cache-first).
- E7 — core has only `assets`, `config` (`constants`, `di`, `env`), `error-handling`, `services/{logging,navigation}`, `utils` (no network/storage/connection yet).
- E8 — sealed hierarchies are declared in a single file.
- E9 — `features/forest/` adds `models/` and `game/` (Flame) next to `bloc/`, `widgets/` and the page; Flame stays confined to `game/` and the page.
- E10 — `BlocLogger` logs only `onError` (`ForestTicked` arrives 60 times per second).
- E11 — BLoC and page tests use the real use cases over `MockLevelRepository` / `MockGameSessionRepository` and mock only `NavigationService`: use cases are `final class` and mockito cannot mock them.

Key cross-cutting conventions:

- **Positions are feet / trunk bases**, in world units = native art pixels; the domain and Flame are both Y-down (no conversion). The same point drives collision, sprite anchoring and draw order (component `priority` = base `y`).
- **New resource, tool or building:** a `Resource`/`ToolKind`/`BlueprintId` is the enum value (appended at the end) + its cases in `Internationalize` and `es.json`, `CustomIcons` (+ SVG in `lib/core/assets/images/icons/`), `SpriteNames` (+ atlas frame via `build_assets.py`) and, for buildings, `RenderConstants.buildingFrontOffset`; `lpc_atlas_test.dart`, `internationalize_test.dart` and `custom_icons_test.dart` fail if any piece is missing.
- **The map is level data:** tree positions, wood, kinds and ground decoration come from the data layer; the view never picks art or places decor itself (`SpriteNames` maps kind → atlas frame).
- **Rendering constants** (`features/forest/game/render/render_constants.dart`, art-specific so not in `core`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px); sprites drawn with `FilterQuality.none`.
- `GameWidget(autofocus: false)` is deliberate: with autofocus Flame swallows every key and Esc never reaches the page's `CallbackShortcuts`.
- Tree taps/clicks are pixel-accurate (texture alpha), so shadows and gaps between leaves fall through to movement. On the web, right click or Esc cancels placement; touch screens get the placement bar.

## Constraints

- `analysis_options.yaml` is the plugin's plus four excludes Flutter re-adds on every `pub get`/`analyze` (`build/**`, `android/**`, `ios/**`, `web/**`); keep them.
- Generated files (`di.config.dart`, `*.mocks.dart`) are committed exactly as `build_runner` writes them, never run through `dart format`; CI fails if they are stale.
- Versions only in `pubspec.yaml` (caret constraints, `sdk: ^3.13.0`); bump a dependency in its own commit. Android `compileSdk`/`targetSdk` 36 is a team rule.
- Plugin rules: folders kebab-case, files snake_case with type suffix, classes with type suffix (`TreeEntity`, `ChopTreeUseCase`, `LevelLocalDatasourceImpl`, `LevelDBO`, `LevelMapperDBO`, `ForestBloc`, `ForestPage`); `locator`, never `GetIt.instance`; no `@Injectable()` on BLoCs; no `Equatable`; nullable `copyWith` fields with `ValueGetter`; no comments in `lib/`; `dart format --line-length 120`; regenerate DI after any change outside `presentation/`.
- Tests: mirror `lib/`; names `testWhen<Action>Then<Result>`; `// given`, `// when`, `// then`; mocks with mockito `@GenerateMocks`, BLoCs with `blocTest`; mock data as `static` fields in `test/mocks/**/<name>_mock.dart` (e.g. `TreeEntityMock.mock`), never declared inline in a test (no inline entities, view models, effects, poses, exceptions/errors or DBOs: add the variant to the mock file). Exception: `PositionEntity(x:, y:)` coordinate literals may stay inline as call arguments or expected values. App texts in tests come from `Internationalize` (only `internationalize_test.dart` spells out the Spanish strings it checks); arbitrary widget labels go in `test/mocks/presentation/widgets/widget_text_mock.dart`. Widget and page tests call `loadSpanishTranslations` and wait with `pumpUntil` from `test/helpers/`; page tests call `rootBundle.clear()` in `setUp`.
- Code, identifiers and comments in English; player-facing text in Spanish only in `es.json`, read through `Internationalize` (the app name `RPG` is the only per-platform text: `AndroidManifest.xml`, `Info.plist`, `web/index.html`, `web/manifest.json`).
- LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0: any new LPC asset must be credited in `lib/core/assets/images/lpc/CREDITS.md`.
- Git flow: `main` (published) / `develop` (default) / `feature/PROJECT-X-<description>` branches. A git hook enforces commit messages as `[PROJECT-123]: Imperative description` (or `[PROJECT-X]: ...` without a ticket), branches as `(feature|bugfix|hotfix)/PROJECT-123-description`, and rejects any AI attribution (no `Co-Authored-By` for an AI, no Claude/Anthropic mentions).
