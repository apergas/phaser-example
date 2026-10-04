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

Clean Architecture with ports & adapters; the dependency rule is enforced by `tests/architecture.test.ts` (domain imports nothing outside itself, application only the domain, presentation only the application layer, never the domain).

- `src/domain/` — pure TypeScript, no Phaser.
  - `world/World.ts` is the aggregate root and the only entry point that changes the world. It holds a `WorldState` and delegates each rule to a system: `Navigation` (walking, collisions, reach, where to stand), `Woodcutting`, `Construction`, `pickUpItems`. Commands return results instead of throwing; `advance(deltaMs)` returns `WorldEvent[]`.
  - Work mechanics are pluggable: the player's activity is generic (`idle` / `walking` with optional `Intent` / `working` on an `Intent`). A mechanic is an `Intent` variant plus a `Work` (target, preferred spots, interval, impact) registered in `World`'s `WorkRegistry` — movement, reach and timing are shared. `GetGameStateUseCase.WORK_ACTIVITY` maps it to the activity name adapters see.
  - `quests/QuestLog.ts` — quests are checks against the `World` (`progress >= target`), completion is sticky. Tuning values live in `rules.ts` and `Blueprints`.
- `src/application/` — use cases plus ports.
  - `ports/GameSessionRepository` (current `{ world, quests }`) and `ports/LevelSource` (`LevelDefinition` as plain data). `StartGameUseCase` builds a session from a level; every other use case fetches the session from the repository on each call.
  - `dto.ts` + `mappers.ts`: everything crossing to adapters is a DTO, including events (`GameEventDto`) and ids (`BlueprintKey`, `QuestKey`, `ToolKey`). The identity mappers only compile while domain and DTO unions match.
- `src/infrastructure/` — port implementations: `levels/ProceduralForestLevel` (seeded generator; a Tiled loader would be another `LevelSource`), `persistence/InMemoryGameSessionRepository`.
- `src/presentation/` — `phaser/` scenes translate input into use cases and turn `GameEventDto`s into effects; views only draw (one per tree/item/building, keyed by id). `dom/Hud.ts` is the HTML overlay behind `HudPort`. Player-facing text lives in `labels.ts`.
- `src/main.ts` — composition root. In dev builds it exposes `window.__rpg = { game, gameState }` for browser automation (stripped from production).

Key cross-cutting conventions:

- **Positions are feet / trunk bases**, in world units = native art pixels. The same point drives collision, sprite anchoring and draw order.
- **Depth (3/4 view):** `views/depth.ts` — ground, then shadows, then everything sorted by base `y`.
- **Scaling:** art is drawn at native size and the camera zooms by `CAMERA_ZOOM` (2). `ForestScene.fitCameraBounds` divides the viewport by the zoom and grows bounds symmetrically so a world smaller than the window stays centred. The canvas uses `Scale.RESIZE` to fill the browser.
- **Facing/animation state is derived in `PlayerView`** from the position delta (or the work target), not stored in the domain. Work animations (`hero-chop`, `hero-hammer`, 128px frames) are not timed by Phaser: the frame is picked from the domain's `swingProgress`, so the impact frame coincides with the hit event.
- **Assets:** `presentation/phaser/assets.ts` is the single registry of texture keys, frame names and sheet layouts. `PreloadScene` loads them and registers animations before starting `ForestScene`. Tree frames in `forest.json` carry a `pivot` at the trunk base (computed by `build_assets.py`), so tree images need no `setOrigin`.
- **LPC character sheets:** 64×64 frames, rows ordered `up, left, down, right`; walk has 9 columns (0 = standing, 1–8 = cycle), idle has 2. Variants with the axe in hand are pre-composed (`hero-*-axe`). Clothes and hair are recoloured in `build_assets.py` (`RECOLOURS`).
- **Tree clicks are pixel-accurate** (`TreeView.containsPoint` checks texture alpha), so shadows and gaps between leaves fall through to movement.
- Randomness (tree variants, decor) goes through `shared/seededRandom.ts` so layouts are reproducible.

## Constraints

- `tsconfig` has `erasableSyntaxOnly`: no constructor parameter properties (`constructor(private x)`) or enums; declare fields explicitly.
- Domain and use-case code is covered by Vitest in `rpg/tests/` (mirrors `src/`); presentation is verified by running the game.
- Vite `base: './'` keeps asset URLs relative so the build works under the Pages sub-path; asset URLs in code are relative (`assets/lpc/...`).
- LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0: any new LPC asset must be credited in `rpg/public/assets/lpc/CREDITS.md`.
- A git hook enforces commit messages as `[PROJECT-123]: Imperative description` (or `[PROJECT-X]: ...` without a ticket), branches as `(feature|bugfix|hotfix)/PROJECT-123-description`, and rejects any AI attribution (no `Co-Authored-By` for an AI, no Claude/Anthropic mentions).
