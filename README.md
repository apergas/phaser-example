# phaser-example

Top-down (3/4 view) RPG prototype built with **TypeScript + Phaser 4 + Vite**, following Clean Architecture:

```
rpg/src/
  domain/          pure game rules: World aggregate split into systems (navigation,
                   woodcutting, construction, pick-up), quests, repository protocols,
                   use cases and the read-only models they return. No Phaser.
  data/            datasources, DTOs, mappers and repository implementations
                   (procedural level, in-memory session)
  presentation/    MVVM by screen: screens/<name>/ holds the Scene + ViewModel pair and its
                   child components (hud/, player/, world/); view models are plain TS and tested
  main.ts          composition root
```

The dependency rule is checked by `rpg/tests/architecture.test.ts`.

Gather-and-build loop: pick up the axe next to the spawn point, click a tree to chop it (5 hits,
5–6 wood each), then use **Construir** to place a house (15 wood) and watch it being built. **Misiones** lists the
current goals and their progress.

## Run locally

```sh
cd rpg
npm install
npm run dev    # dev server
npm test       # domain, use-case, view-model and architecture tests (Vitest)
npm run typecheck
npm run build  # static build in rpg/dist
```

Every push to `main` is built and published to GitHub Pages by `.github/workflows/deploy.yml`.

## Art

- `asset-packs/lpc/` — Liberated Pixel Cup sources and `build_assets.py`, which generates the textures in
  `rpg/public/assets/lpc/` (requires Pillow).

LPC art is licensed CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0 and requires attribution:
see [`rpg/public/assets/lpc/CREDITS.md`](rpg/public/assets/lpc/CREDITS.md).
