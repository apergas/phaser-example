# C13 · Armadura visible del héroe — ficha

> **Plan detallado: pendiente.** Al empezar, `boost:writing-plans` sobre esta ficha. Antes era una mejora sin fase; el 2026-10-17 el usuario la convirtió en la fase C13. No está en iOS.

| | |
|---|---|
| **Rama** | `feature/PROJECT-C13-hero-armour`, desde `feature/PROJECT-X-arena` |
| **Depende de** | C12 |
| **Issue / milestone** | `phase:C13` · milestone `C13 Hero armour` · #67 |

**Decidido por el usuario (2026-10-17): juegos precompuestos por combinación** (`hero-<arma>-<armadura>`, 4 × 4 = 16 juegos), el mismo camino que las armas, sin tocar Flame.

**Qué se quiere:** igual que el héroe cambia de arma en la arena (hacha → espada corta → de hierro → de acero), que cambie de aspecto al comprar armadura.

**Cómo están hoy las armas:**
- `build_assets.py` compone cada juego del héroe con sus capas LPC y su arma (`ARENA_FIGHTERS`: `hero`, `hero-short-sword`, `hero-iron-sword`, `hero-steel-sword`). Cada juego tiene 17 frames: 2 de reposo, 9 de andar y 6 de golpe.
- `ArenaBloc` lee el arma equipada (`Gear.of(GearSlot.weapon, hero.weaponTier).id`) y la pasa en `FighterRenderData.weapon`.
- `ArenaSpriteNames.heroWith(GearId?)` elige el juego.
- **La armadura no llega a la vista:** `FighterRenderData` no tiene campo para ella y el héroe lleva siempre la ropa de trabajo.
- En el bosque el jugador no muestra equipo, ni arma ni armadura. Esto no cambia.

**Armaduras del catálogo** (`Gear`, `GearSlot.armor`) **y capas LPC posibles:**

| Tier | Armadura | Capas | ¿Están en el repo? |
|---|---|---|---|
| 0 | Ropa de trabajo | La camisa de manga larga de hoy (`torso_clothes_longsleeve`) | Sí |
| 1 | Armadura de cuero | `torso_armour_leather_male` (la de los bárbaros), quizá con brazales | Sí (`sources/barbarians/`) |
| 2 | Cota de malla | Torso de malla, y hombreras si las hay | No |
| 3 | Armadura de placas | Torso, hombreras y piernas de placas, y quizá yelmo | No |

- Las capas que faltan se bajan del Universal LPC Spritesheet Character Generator, en el mismo commit que ya usan los bárbaros (`58ce1aa`), carpeta `spritesheets/`. Las rutas hay que confirmarlas en el repositorio, y cada capa trae sus animaciones `idle`, `walk` y `slash`.
- Licencias esperadas: OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0. Cada capa nueva se acredita en `CREDITS.md`.

**Opciones que se valoraron** (se eligió la primera):
- **Juegos precompuestos por combinación** (`hero-<arma>-<armadura>`):
  - es el camino de hoy y no hay que tocar Flame;
  - pero son 4 × 4 = 16 juegos, 272 frames del héroe en vez de 68, y `arena.png` crece bastante.
- **Armadura como capa aparte**, dibujada encima del héroe con su arma:
  - un juego de frames por armadura, con `FighterComponent` pintando dos sprites alineados;
  - el atlas crece poco, pero el orden de capas (el arma delante o detrás del torso según el frame) lo complica.

**Piezas, en cualquiera de los dos casos:**
- `FighterRenderData.armor` (`GearId?`), que `ArenaBloc` rellena con `Gear.of(GearSlot.armor, hero.armorTier).id` en los mismos dos sitios que el arma.
- Los nombres en `ArenaSpriteNames`, el atlas regenerado y sus tests (`arena_sprite_names_test.dart`, `ArenaAssetsMock`).

**Prueba manual:** comprar cada armadura en la Armería y ver al héroe con ella en la arena, con cada arma.
