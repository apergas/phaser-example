# F3 · Rebrote de árboles — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS**: esta ficha recoge lo que se decidió y comprobó allí (`$IOS/docs/plans/2026-10-12-village/F3-regrowth.md`); manda sobre la versión anterior de esta ficha.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F3-regrowth`, desde `feature/PROJECT-X-town` |
| **Depende de** | F1 |
| **Issue / milestone** | `phase:F3` · milestone `F3 Regrowth` |
| **Referencia iOS** | merge `80de0c2` (`[PROJECT-F3]: Merge the regrowth`), commits `bcee57f` (dominio), `42c594a` (frame), `1e0ced3` (escena) |

## Objetivo

Que el bosque deje de agotarse: un tocón brota y, con el tiempo, vuelve a ser el mismo árbol.

## Decisiones ya tomadas

**Dominio:**
- El tocón pasa a ser estado del dominio: `StumpEntity(id, kind: TreeKind, position, elapsedMs)` en `domain/entities/tree/`, guardado en `WorldState.stumps` (orden de inserción) y expuesto en `WorldSnapshotEntity.stumps`.
- **Tiempos** (`Rules`, `double`, contados desde la tala): `sproutAfterMs = 60000` (tocón → brote) y `regrowAfterMs = 180000` (brote → árbol). Para probar a mano se acortan ahí, nunca con lógica de depuración.
- **Ids:** el tocón lleva el id del árbol talado y el árbol que vuelve, el del tocón (`tree-37` → tocón `tree-37` → árbol `tree-37`). No se usa `WorldState.nextId("tree")`: los ids del nivel los pone el repositorio por índice. El árbol que vuelve va **al final** de `WorldState.trees`.
- El árbol que vuelve conserva tipo y sitio, con la madera y los golpes de `Rules.treeKindStats` (F1). Si un tipo faltara en la tabla, el brote se queda esperando (sin `!`).
- **Sistema `Regrowth`** (`domain/world/regrowth.dart`, pieza interna: se añade a `test/architecture_test.dart`). Es **lo primero** de `World.advance`, antes del trabajo y del paso del jugador. Un tocón creado en el tick *t* termina ese tick con `elapsedMs = 0`.
- **Sitio ocupado:** el árbol no aparece si su tronco (`Rules.treeTrunkRadius`) bloquea al jugador con la regla de `Navigation` (distancia < 12 + 8) o si el sitio está bloqueado por edificios o árboles. Mientras espera, `elapsedMs` se queda en `regrowAfterMs` y se reintenta cada tick, sin límite. El jugador que tala se queda a 22 (`Rules.workGap`) y no bloquea.
- **Construir borra el tocón:** `Construction.place` quita, tras dar de alta el edificio, cada tocón cuyo árbol futuro chocaría con él (distancia < 40 + 12 con los edificios de hoy).
- Tocones y brotes **no bloquean** ni el paso (`obstacles()` no cambia) ni la colocación.

**Eventos:** `TreeSproutedEventEntity(stumpId)` y `TreeRegrownEventEntity(tree)`, al final de `game_event_entity.dart`. `ForestBloc` los traduce a `TreeSproutedEffect` / `TreeRegrownEffect` **sin snackbar** (se repetirían a cada rato; lo importante se ve en el mapa).

**Escena:**
- `_onTreeFelled` deja de añadir el tocón decorativo: los tocones salen de la instantánea y se reconcilian por id, como los árboles.
- `StumpComponent` (tocón o brote) en `game/components/`, con prioridad `y - 1`, para que el árbol que cae se dibuje encima de su tocón. Si un tocón pasa a brote, se quita su componente y se crea otro con el frame nuevo.
- **Crecimiento** con la curva de `render/easing.dart` dentro de `update(dt)`, como `TreeMotion` (avanza con el `dt` limitado de `ForestGame`): escala de 0,35 a 1 en 600 ms con `backOut` (se pasa un 6 % y vuelve), anclada en la base del tronco. Lo usan el brote al aparecer y el árbol al volver.
- Los efectos solo apuntan el id; la reconciliación hace crecer el componente que crea con ese id. Si cae y crece a la vez, gana caer.

**Arte:** `sapling` = la celda (13, 25) de `terrain_atlas.png` (caja `(416, 800, 448, 832)`, el arbolito de tallo marrón del *LPC Tile Atlas* de Daniel Eddeland, ya acreditado). Recortado queda en 18 × 30, con pivote en la base del tallo (`x 0.3889, y 0.9`). `SpriteNames.sapling`; una línea en `CREDITS.md`. Al regenerar, cinco frames pequeños cambian de sitio dentro de `forest.png` (mismo tamaño y pivote).

**Guardado:** en F2 (tocones en orden con `id`, `kind`, `position` y `elapsedMs`).

## Ficheros previstos

- **Dominio:** `entities/tree/stump_entity.dart` (nuevo), `entities/game/world_snapshot_entity.dart`, `game_event_entity.dart`, `world/world.dart`, `world_state.dart`, `regrowth.dart` (nuevo), `construction.dart`, `woodcutting.dart`, `rules/rules.dart`, `use-cases/game/get_world_snapshot_use_case.dart`.
- **Presentación:** `models/forest_effect.dart`, `bloc/forest_bloc.dart`, `game/atlas/sprite_names.dart`, `game/forest_scene_component.dart`, `game/forest_state_listener.dart`, `game/components/stump_component.dart` (nuevo), `game/render/growth_motion.dart` (nuevo, junto a `tree_motion.dart`).
- **Arte:** `build_assets.py`, `forest.{png,json}`, `CREDITS.md`.
- **Tests:** `test/architecture_test.dart` (pieza interna nueva) y mocks de `StumpEntity`.

## Cómo probarlo

Con las duraciones acortadas en local (sin commitearlas):
- talar deja un tocón, que brota y luego vuelve a ser el mismo árbol, en su sitio, que se puede volver a talar;
- de pie sobre el tocón, el árbol espera, y aparece en cuanto el jugador se aparta;
- construir encima borra el tocón;
- abrir la arena pausa el rebrote.

Tests (los goldens de iOS valen tal cual: mismo dominio):
- `world_regrowth_test.dart`, con ticks de 50 ms:
  - el pino `tree-37` talado en t = 5500 brota en 65500 y vuelve en 185500;
  - el tocón del tick de la tala acaba ese tick con `elapsedMs` 0;
  - con el jugador a menos de 20 del centro no rebrota y `elapsedMs` se queda en 180000; a 22, sí;
  - una casa a menos de 52 borra el tocón;
  - los tocones nunca bloquean ni el camino ni `canPlace`;
  - el árbol que vuelve sale el último en la instantánea.
- `stump_component_test.dart` (`testWithFlameGame`): tamaño 50 × 41 del tocón y 18 × 30 del brote, y el crecimiento de 0,35 a 1 en 600 ms.
- `growth_motion_test.dart`.
- `forest_scene_component_test.dart`: reconcilia tocones y brotes por id, y la tala ya no añade decoración.
- `lpc_atlas_test.dart`: el frame `sapling` existe.
