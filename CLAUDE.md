# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

- `rpg/` — the game (TypeScript + Phaser 4 + Vite + Vitest). All npm commands run from here.
- `asset-packs/lpc/` — raw LPC art sources and `build_assets.py`, which generates everything in `rpg/public/assets/lpc/`.
- `.github/workflows/deploy.yml` — every push to `main` runs `npm ci`, `npm test`, `npm run build` in `rpg/` and publishes `rpg/dist` to GitHub Pages (https://apergas.github.io/phaser-example/).

## Commands (from `rpg/`)

```sh
npm run dev                               # dev server
npm test                                  # vitest run (all tests)
npx vitest run tests/domain/World.test.ts # single file
npx vitest run -t "clamps the destination" # single test by name
npm run typecheck                         # type-check src and tests (tsconfig.test.json)
npm run build                             # tsc + vite build into dist/
```

There is no linter. Regenerate art after editing the asset script: `cd asset-packs/lpc && python3 build_assets.py` (needs Pillow).

## Architecture

Clean Architecture laid out like the team's iOS/Android apps (`domain` / `data` / `presentation`). The dependency rule is enforced by `tests/architecture.test.ts`: the domain imports nothing outside itself, its core (entities, world, quests) does not know use cases or repositories, `data` never touches presentation, presentation reaches the domain only through `domain/usecases/` (and its models) and never imports `data`, and view models never import Phaser, views or CSS.

- `src/domain/` — pure TypeScript, no Phaser.
  - `world/World.ts` is the aggregate root and the only entry point that changes the world. It holds a `WorldState` and delegates each rule to a system: `Navigation` (walking, collisions, reach, where to stand), `Woodcutting`, `Construction`, `pickUpItems`. Commands return results instead of throwing; `advance(deltaMs)` returns `WorldEvent[]`.
  - Work mechanics are pluggable: the player's activity is generic (`idle` / `walking` with optional `Intent` / `working` on an `Intent`). A mechanic is an `Intent` variant plus a `Work` (target, preferred spots, interval, impact) registered in `World`'s `WorkRegistry` — movement, reach and timing are shared. `GetGameStateUseCase.WORK_ACTIVITY` maps it to the activity name adapters see.
  - `quests/QuestLog.ts` — quests are checks against the `World` (`progress >= target`), completion is sticky. Tuning values live in `rules.ts` and `Blueprints`.
  - `repositories/` — protocols: `GameSessionRepository` (current `{ world, quests }`) and `LevelRepository` (returns a ready `World`).
  - `usecases/` — one class per use case. `StartGameUseCase` builds a session from the level; every other use case fetches the session from the repository on each call.
  - `usecases/models/` + `models/mappers.ts`: what use cases return to adapters are read-only models (`PlayerState`, `WorldSnapshot`, `QuestProgress`, `BuildOption`, `GameNotice` for events, `*Key` ids) — never domain entities, which are mutable and would let adapters bypass the use cases. They are deliberately not called DTOs. The identity mappers for keys only compile while domain and model unions match.
- `src/data/` — same shape as the mobile apps: `datasources/` (`LevelDataSource` port + `ProceduralForestLevelDataSource`; a Tiled loader or a save-game store would be other data sources) return `dtos/` (`LevelDto`: raw, untrusted external shape — "DTO" is reserved for these), `mappers/` (`LevelMapper.toWorld` validates and builds entities), `repositories/` (`LevelRepositoryImpl`, `InMemoryGameSessionRepository`) implement the domain protocols.
- `src/presentation/` — MVVM, organised by screen like an iOS `Features/` folder: each screen folder holds its view + view model pair at the root and its child components (each with its own pair when they have presentation logic) in subfolders.
  - `screens/forest/` — `ForestScene` + `ForestViewModel`, the gameplay screen. `ForestViewModel` owns presentation logic: what a map click means (chop / walk / place), placement mode and its validity, which message each event shows, and turning `GameNotice`s into one-shot `Effect`s (tree-hit, building-placed...). It composes the child view models:
    - `hud/` — `Hud` (HTML overlay) + `HudViewModel` (display-ready `HudState`: formatted texts, quest status, build items, message with a `serial`).
    - `player/` — `PlayerView` + `PlayerViewModel` (`PlayerRenderState`: facing + pose — idle/walk with or without axe, or work with tool and swing progress).
    - `world/` — `TreeView`, `ItemView`, `BuildingView`, `GroundView`: drawn straight from use-case models (`TreeInfo`, `BuildingInfo`...), no view model per object (like rows of a list).
  - `screens/preload/` — `PreloadScene`: loads textures and registers animations; no view model.
  - `common/` — `assets.ts` (texture registry), `depth.ts` (draw order), `labels.ts` (all player-facing text).
  - Views are passive: no binding framework — the game loop is the binding. Each frame the scene calls `vm.tick(delta)`, plays the returned effects and renders `vm.*.state`. Views only decide engine/art matters (pixel hit-testing, sprite keys, LPC frame sequences, tweens, camera). View models are plain TypeScript tested in `tests/presentation/` (mirrors `src/`); any `*ViewModel.ts` importing Phaser, a view or CSS fails the architecture test.
- `src/main.ts` — composition root. In dev builds it exposes `window.__rpg = { game, gameState, viewModel }` for browser automation (stripped from production).

Key cross-cutting conventions:

- **Positions are feet / trunk bases**, in world units = native art pixels. The same point drives collision, sprite anchoring and draw order.
- **Depth (3/4 view):** `views/depth.ts` — ground, then shadows, then everything sorted by base `y`.
- **Scaling:** art is drawn at native size and the camera zooms by `CAMERA_ZOOM` (2). `ForestScene.fitCameraBounds` divides the viewport by the zoom and grows bounds symmetrically so a world smaller than the window stays centred. The canvas uses `Scale.RESIZE` to fill the browser.
- **Facing/animation state is derived in `PlayerView`** from the position delta (or the work target), not stored in the domain. Work animations (`hero-chop`, `hero-hammer`, 128px frames) are not timed by Phaser: the frame is picked from the domain's `swingProgress`, so the impact frame coincides with the hit event.
- **Assets:** `presentation/common/assets.ts` is the single registry of texture keys, frame names and sheet layouts. `PreloadScene` loads them and registers animations before starting `ForestScene`. Tree frames in `forest.json` carry a `pivot` at the trunk base (computed by `build_assets.py`), so tree images need no `setOrigin`.
- **LPC character sheets:** 64×64 frames, rows ordered `up, left, down, right`; walk has 9 columns (0 = standing, 1–8 = cycle), idle has 2. Variants with the axe in hand are pre-composed (`hero-*-axe`). Clothes and hair are recoloured in `build_assets.py` (`RECOLOURS`).
- **Tree clicks are pixel-accurate** (`TreeView.containsPoint` checks texture alpha), so shadows and gaps between leaves fall through to movement.
- Randomness (tree variants, decor) goes through `shared/seededRandom.ts` so layouts are reproducible.

## Constraints

- `tsconfig` has `erasableSyntaxOnly`: no constructor parameter properties (`constructor(private x)`) or enums; declare fields explicitly.
- Domain and use-case code is covered by Vitest in `rpg/tests/` (mirrors `src/`); presentation is verified by running the game.
- Vite `base: './'` keeps asset URLs relative so the build works under the Pages sub-path; asset URLs in code are relative (`assets/lpc/...`).
- LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0: any new LPC asset must be credited in `rpg/public/assets/lpc/CREDITS.md`.
- A git hook enforces commit messages as `[PROJECT-123]: Imperative description` (or `[PROJECT-X]: ...` without a ticket), branches as `(feature|bugfix|hotfix)/PROJECT-123-description`, and rejects any AI attribution (no `Co-Authored-By` for an AI, no Claude/Anthropic mentions).
