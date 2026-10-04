# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

- `shared/` — Kotlin Multiplatform module (targets: Android, iOS arm64/simulator, JS) with **all** game logic: domain, data, the shared view model and the dependency container. Package root `com.apergas.rpg`.
- `androidApp/` — Jetpack Compose + Hilt app. Only views.
- `iosApp/` — SwiftUI + SpriteKit app (`iosApp.xcodeproj`, hand-written, Xcode file-system synchronized folders: new `.swift` files under `iosApp/iosApp` or `iosApp/iosAppTests` join their target automatically). Only views.
- `webApp/` — Vite + Phaser 4 + TypeScript. Only views; consumes `shared` as the npm package `rpg-shared` (`file:../shared/build/dist/js/productionLibrary`).
- `asset-packs/lpc/` — raw LPC art and `build_assets.py`, which generates `webApp/public/assets/lpc/` and copies it to `androidApp/src/main/assets/lpc/` and `iosApp/iosApp/Resources/lpc/`.
- `.github/workflows/deploy.yml` — on pushes to `main` that touch the web or `shared`: shared JVM + JS tests, the `rpg-shared` package, then `npm ci`, typecheck, test, build in `webApp/` and publish `webApp/dist` to GitHub Pages (https://apergas.github.io/phaser-example/). Android and iOS are tested locally only.
- `docs/boost/plans/2026-10-04-kmp-migration/` — the migration plan; its README section 8 records every deviation found while executing it.

## Commands

```sh
./gradlew :shared:allTests                                   # shared tests on JVM, JS (Chrome headless) and iOS simulator
./gradlew :shared:testAndroidHostTest --tests "com.apergas.rpg.domain.world.*"   # JVM only, filtered
./gradlew :shared:jsBrowserProductionLibraryDistribution     # npm package the web app depends on (run before npm install/ci)
./gradlew :androidApp:testDebugUnitTest                      # Android unit tests
./gradlew :androidApp:connectedDebugAndroidTest              # Android instrumented tests (running emulator)
./gradlew :androidApp:installDebug                           # install on the emulator (AVD Medium_Phone_API_36.0)
xcodebuild test -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 17'
cd webApp && npm run dev | npm test | npm run typecheck | npm run build
```

`local.properties` (gitignored) must point `sdk.dir` at the Android SDK. The iOS build runs `./gradlew :shared:embedAndSignAppleFrameworkForXcode` from an Xcode run-script phase. Regenerate art after editing the asset script: `cd asset-packs/lpc && python3 build_assets.py` (needs Pillow). There is no linter.

## Architecture

Rules live once in `shared`, written with the team's Android conventions; the apps only draw. `Presentation ──▶ Domain ◀── Data`, enforced by `shared/src/androidHostTest/kotlin/com/apergas/rpg/ArchitectureTests.kt` (domain imports nothing from data/presentation/di or platform APIs, data never imports presentation, presentation never imports data, entities have no `var`) and, for the web, by `webApp/tests/architecture.test.ts` (no `domain/`, `data/` or `*ViewModel.ts`; presentation imports only `phaser`, `rpg-shared` and itself).

- `shared/src/commonMain/kotlin/com/apergas/rpg/`
  - `domain/entities/` — immutable `data class`es (operations return copies): geometry, player (`Inventory`, `Intent`, `Activity`), tree (`TreeKind`), decoration, item, building (`Blueprints`), game (`GameEvent`, results, read entities such as `PlayerStatus`, `WorldSnapshot`, `QuestProgress`, `BuildOption`, `GameSession`).
  - `domain/world/` — `World`, the mutable aggregate and only entry point that changes the game. It owns a `WorldState` and delegates to `internal` systems: `Navigation`, `Woodcutting`, `Construction`, `pickUpItems`. Work mechanics are an `Intent` variant + a `Work` + one branch in `workFor()` (exhaustive `when`). `advance(deltaMs)` returns `GameEvent`s.
  - `domain/quests/` (`QuestLog`, sticky completion), `domain/rules/Rules.kt` (tuning), `domain/errors/` (`AppError`, `ErrorHandler`), `domain/repositories/` (interfaces).
  - `domain/usecases/game/` — a single `GameUseCase` / `GameUseCaseImpl` with every operation, synchronous (the simulation advances per frame, no I/O). It fetches the session from `GameSessionRepository` on each call.
  - `data/` — `datasources/local/level` (`LevelLocalDataSourceImpl`: seeded procedural forest that also decides each tree's kind and the ground decoration; all-nullable `@Serializable` DTOs), `repositories/level` (`LevelRepositoryImpl` + `internal` `LevelMappers.kt`, errors through `ErrorHandler`), `repositories/session` (in-memory session).
  - `presentation/forest/` — `ForestContract.kt` (`ForestState` / `ForestIntent` / `ForestEffect`), `ForestViewModel` (JetBrains multiplatform `ViewModel`; intents handled **synchronously** so `Tick` runs in frame order; effects via `tryEmit` on a buffered `SharedFlow`), `ForestLabels` (every player-facing Spanish text, including touch-bar and accessibility strings), `SpriteNames` (level kind → atlas frame name, used by all three apps).
  - `di/GameContainer.kt` — iOS-style container: builds DataSource → Repository → UseCase; one session for the whole app; `makeForestViewModel()`.
  - `util/SeededRandom.kt` — LCG identical to the old TypeScript one (golden-value tests keep the forest identical).
- `shared/src/jsMain/.../web/` — `ForestWebController` (`@JsExport`), the only API the web sees, with plain exported `Web*` types; effects are pulled per frame with `takeEffects()`. Kotlin/JS types nullables as `T | null | undefined`.
- `androidApp/` — `app/` (`@HiltAndroidApp`, `MainActivity`, `di/GameModule` providing `GameUseCase` from `GameContainer`), `presentation/navigation` (typed routes), `presentation/forest/ForestScreen.kt` (game loop with `withFrameNanos`, `ForestScaffold` with the snackbar and the placement bar as `bottomBar`), `components/HudOverlay.kt` (HUD and `PlacementBar`), `world/` (`WorldCanvas` Y-sorted drawing, `WorldSceneState` fed by effects, `AtlasParser` for `forest.json`, `LpcAssets`, `Particles` with closed-form trajectories). `ForestViewModel` is created with `viewModel(factory = ...)` (no `@HiltViewModel`: it lives in `commonMain`).
- `iosApp/iosApp/Presentation/` — `ForestView` (SwiftUI, hosts the SpriteKit scene) + Swift `ForestViewModel` (`@Observable`, wraps the shared one) + `ForestBuilder`; `World/ForestScene.swift` (SKScene: nodes, camera, game loop, effects, touches), `ScenePoint` (the only Y-up conversion), `LpcAtlas`, `ParticleEmitters` (`SKEmitterNode`). SKIE exposes Flows as `AsyncSequence` and `onEnum(of:)`; sealed-interface members appear flattened in Swift (`ForestIntentTick(deltaMs:)`).
- `webApp/src/` — `main.ts` (creates the controller, `Hud`, scenes; dev builds expose `window.__rpg = { game, controller }` for browser automation), `presentation/screens/forest/ForestScene.ts` (each frame: `tick`, play `takeEffects()`, render `state()`), `hud/Hud.ts`, `player/PlayerView.ts`, `world/*View.ts` (`GroundView` draws the level's decoration), `screens/preload/PreloadScene.ts`, `common/assets.ts` (texture registry), `common/depth.ts`.

Key cross-cutting conventions:

- **Positions are feet / trunk bases**, in world units = native art pixels; the domain is Y-down. The same point drives collision, sprite anchoring and draw order (sort by base `y`) on every platform; only `iosApp`'s `ScenePoint` flips Y.
- **The map is level data:** tree positions, wood, kinds and ground decoration come from `shared`; apps never pick art or place decor themselves.
- **Rendering constants are the same in the three apps:** camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; house drawn 24 px below its footprint centre.
- Tree taps/clicks are pixel-accurate (texture alpha), so shadows and gaps between leaves fall through to movement.

## Constraints

- Versions only in `gradle/libs.versions.toml`. `compileSdk`/`targetSdk` 36 is a team rule; AndroidX libraries that need `minCompileSdk` 37 cannot be used (that is why lifecycle is 2.10.0). AGP 9: `shared` uses `com.android.kotlin.multiplatform.library`, the app has built-in Kotlin (no `org.jetbrains.kotlin.android`).
- Tests (Kotlin and Swift): `// given`, `// when`, `// then`; names `testWhen<Action>Then<Result>`; mock data as `val <Entity>.Companion.mock` / `static let mock`; hand-written mocks with an `error` property and `<method>Called` flags.
- Code, identifiers and comments in English; player-facing text in Spanish only in `ForestLabels` (the app name is the only per-platform text: `app_name`, `Info.plist`, `<title>`).
- `webApp` tsconfig has `erasableSyntaxOnly`: no constructor parameter properties or enums. Vite `base: './'` keeps asset URLs relative for the Pages sub-path.
- LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0: any new LPC asset must be credited in `webApp/public/assets/lpc/CREDITS.md`.
- Git flow: `main` (published) / `develop` (default) / `feature/PROJECT-X-<description>` branches. A git hook enforces commit messages as `[PROJECT-123]: Imperative description` (or `[PROJECT-X]: ...` without a ticket), branches as `(feature|bugfix|hotfix)/PROJECT-123-description`, and rejects any AI attribution (no `Co-Authored-By` for an AI, no Claude/Anthropic mentions).
