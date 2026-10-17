# F5 · Piedra y pico — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-village/F5-stone.md`, con la tabla de rocas y el código de `build_assets.py`); esta ficha manda sobre la versión anterior.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F5-stone`, desde `feature/PROJECT-X-town` |
| **Depende de** | F4 (orden de iOS; técnicamente solo F0) |
| **Issue / milestone** | `phase:F5` · milestone `F5 Stone` |
| **Referencia iOS** | merge `b26be1c` (`[PROJECT-F5]: Merge stone and the pickaxe`), commits `1a69419` (dominio), `073dd32` (frames), `06f881c` (nivel), `1b7dcde` (escena) |

## Objetivo

Un segundo recurso que se recoge en el mapa: rocas que se pican con un pico encontrado lejos del inicio. La piedra paga los edificios del héroe y, después, la cantera y el taller.

## Decisiones ya tomadas

**Dominio:**
- `Resource.stone`, al final del enum (detrás de `mana`); `ToolKind.pickaxe`.
- `RockEntity(id, position, radius, stoneYield, hitsToBreak, hitsTaken)` en `domain/entities/rock/`, con `footprint`, `hitsRemaining` e `isBroken` calculados. `hit()` en `domain/world/extensions/rock_rules.dart`.
- Es un obstáculo (`WorldState.obstacles()` = troncos, rocas y edificios) y la colocación no puede ir encima.
- **Cifras** (`Rules`): `rockRadius = 22`, `rockStoneYield = 8`, `rockHitsToBreak = 8`, `mineIntervalMs = 750` (como talar). Unos 6 s por roca.
- Las 12 rocas dan 96 de piedra, más que los 75 que piden F5 y F8 juntas. Las rocas **no vuelven**.
- **`Mining`**, calcado de `Woodcutting` (`domain/world/mining.dart`, pieza interna):
  - `MineIntentEntity(rockId)` y su caso en `workFor()`;
  - `PlayerActivity.mining`;
  - `MineResult { ok, noPickaxe, unknownRock }` (`unknownRock` se comprueba antes que `noPickaxe`);
  - `MineRockUseCase` y `World.orderMine`.
- Golpe a golpe:
  - el jugador se pone a izquierda o derecha y da un golpe cada 750 ms;
  - el último golpe quita la roca de `WorldState.rocks` (deja de bloquear), suma la piedra al inventario del jugador (F6 la pasa a la carga) y emite `RockHitEventEntity(rockId)` y `RockBrokenEventEntity(rockId, stone)`, en ese orden y al final de los eventos;
  - no queda resto en el suelo;
  - volver a tocar la roca que se pica reinicia el golpe, como talar.
- `StatsRecording` (F4) da a los eventos de roca una rama que no cambia nada; las misiones de piedra son de F8.

**Costes:** la Herrería y la Armería pasan a 25 de madera + 10 de piedra, y la Torre de magia a 30 de madera + 40 de oro + 10 de piedra. `Gear` y `Skills` no cambian, así que `balance_test.dart` sigue en verde sin tocarlo.

**Nivel** (`LevelLocalDatasourceImpl`):
- **Rocas:** con su propia semilla, `rockSeed = 2026`, después de los árboles. Hasta 600 intentos de dos tiradas (`x`, `y` dentro del margen de 60). Una roca vale si está:
  - a ≥ 200 del inicio, ≥ 80 del pico y ≥ 200 de otra roca;
  - a ≥ 60 de **todo** tronco (así ningún tocón de F3 queda bloqueado para siempre);
  - fuera de la caja de copa de cualquier árbol.

  Salen 12. `RockDBO(id, position)` sin cifras (las pone el mapeo con `Rules`); `LevelDBO.rocks`; `RockMapperDBO`.
- **Golden** (mismo `SeededRandom` que iOS, así que sale igual): `rock-1` (303.66, 1110.24), `rock-2` (1333.10, 464.67), `rock-3` (385.68, 823.07).
- **Decoración:** se genera igual que antes y después se quitan las que caen a menos de 48 de una roca o de 32 del pico: 13 de 107 (ids 6, 12, 17, 30, 34, 37, 40, 42, 49, 68, 81, 85 y 105). Quedan huecos, pero ninguna se mueve ni cambia de id. Los goldens de decoración (VM y Chrome) se actualizan.
- **Pico:** el segundo `ItemDBO` (`id`/`kind` `pickaxe`) en `(spawnX + 212, spawnY + 212)` = (1012, 812), a 299,8 del inicio. El hacha sigue siendo `items[0]`.
- Árboles, tipos, posiciones y madera (411 / 388) **no cambian**.

**Toque:** `ForestMapClicked` pasa a llevar el objetivo tocado. El plan elige entre un `rockId` más (junto a `treeId` y `buildingId`) o un enum `MapTarget { tree, rock, building }` + id en `core/config/constants/enum/forest/`; iOS usó el enum. La roca se toca al píxel con `AlphaMask`, como árboles y edificios, y gana el componente de mayor prioridad.

**Escena:**
- `RockComponent`, con prioridad `y`.
- Al golpear tiembla 1,5 px durante 120 ms (`RockMotion`). Al romperse encoge al 60 % y se desvanece en 350 ms, y deja de poder tocarse.
- Esquirlas grises: `ParticleKind.stoneChip` (al final) y `ParticleBursts.stoneChips`, la variante de `woodChips` con origen 14 por encima de la base.
- "+8" flotante (`forest.floating.stoneGained`, dorado por defecto) y *snackbar* "+8 de piedra".
- Pose de picar con la hoja del martillo: `WorkTool.pickaxe`. `PlayerRenderData` saca la herramienta con un `switch` exhaustivo sobre `PlayerActivity` (si no, picar pintaría al jugador quieto).

**Arte** (sin autores nuevos; dos líneas en `CREDITS.md`):
- `rock-large`: la roca gris con dos guijarros de `terrain_atlas.png`, caja `(864, 736, 928, 800)`, 61 × 45, pivote `(0.5, 0.8)`.
- `pickaxe-pickup`: `axe-pickup` con el mango y la hoja en gris, **reflejado** para no confundirlo con el hacha. El código de iOS está en su plan, tarea 2.
- Iconos `stone.svg` (22 × 14) y `pickaxe.svg` (22 × 22), los de iOS (`$IOS/Farming/Assets.xcassets/Icons/{stone,pickaxe}.imageset/`).

**Textos:**
- `forest.resource.stone` "Piedra", `forest.amount.stone` "{amount} de piedra", `forest.tool.pickaxe` "Pico".
- `forest.message.needPickaxe` "Necesitas un pico para picar.".
- `forest.message.pickedUpPickaxe`: "¡Pico recogido! Haz clic en una roca para picarla." con ratón y "¡Pico recogido! Toca una roca para picarla." en táctil (regla de textos táctiles de la [alineación](../2026-10-06-hero-arena/X-ios-alignment.md)).
- `forest.message.stoneGained` "+{amount} de piedra", `forest.floating.stoneGained` "+{amount}".

**HUD:** la barra gana Piedra y Pico. Se vuelven a medir `HudOverlay.buttonsBelowWidth` y `narrowWidth`, con 9999 de todo, la insignia `16/16` y la misma holgura de 24 px. En iOS, 1300 y 800 pt; en Flutter se miden con un test de widget.

**Guardado:** en F2 (rocas con `id`, `position` y `hitsTaken`; el pico va con los objetos del suelo).

## Ficheros previstos

- **Dominio:** `entities/rock/rock_entity.dart` (nuevo), `intent_entity.dart`, `game_event_entity.dart`, `world_snapshot_entity.dart`, `world/mining.dart` (nuevo), `work.dart`, `world.dart`, `world_state.dart`, `navigation.dart`, `stats_recording.dart`, `extensions/rock_rules.dart` (nuevo), `extensions/activity_rules.dart`, `rules/rules.dart`, `rules/blueprints.dart`, `use-cases/game/mine_rock_use_case.dart` (nuevo), `get_world_snapshot_use_case.dart`.
- **Core:** `resource.dart`, `tool_kind.dart`, `player_activity.dart`, `mine_result.dart` (nuevo), `forest/work_tool.dart`, `forest/particle_kind.dart`, `es.json`, `internationalize.dart`, `images/icons/{stone,pickaxe}.svg`.
- **Datos:** `level_local_datasource_impl.dart`, `dbo/rock_dbo.dart` (nuevo), `dbo/level_dbo.dart`, `mappers/rock_mapper_dbo.dart` (nuevo), `mappers/level_mapper_dbo.dart`.
- **Presentación:** `bloc/forest_bloc.dart`, `bloc/forest_event.dart`, `models/forest_effect.dart`, `models/player_render_data.dart`, `game/components/rock_component.dart` (nuevo), `game/forest_scene_component.dart`, `game/forest_state_listener.dart`, `game/forest_world.dart`, `game/atlas/sprite_names.dart`, `game/render/rock_motion.dart` (nuevo), `game/particles/*`, `widgets/hud_overlay.dart`, `theme/images/custom_icons.dart`.
- **Arte:** `build_assets.py`, `forest.{png,json}`, `CREDITS.md`.
- **Tests:** `architecture_test.dart` (pieza nueva) y `di.config.dart` regenerado.

## Cómo probarlo

- El bosque se ve igual, con 12 rocas grises y un pico a unos 300 abajo a la derecha del inicio.
- Tocar una roca sin pico avisa. Con el pico, el jugador pica con el gesto del martillo, la roca tiembla y suelta esquirlas, y al octavo golpe se encoge y sube "+8"; después ya se puede pasar por su sitio.
- La Herrería, la Armería y la Torre de magia piden 10 de piedra.
- Tests (mocks en `test/mocks/**`, nunca en línea):
  - **`level_local_datasource_impl_test.dart`:**
    - 12 rocas, con el golden de las tres primeras;
    - 70 árboles idénticos, con 388 de madera en los DBO;
    - 94 decoraciones, sin los 13 ids quitados y las demás en su sitio;
    - el pico en `items[1]` (1012, 812);
    - invariantes de las rocas: a ≥ 34 de todo tronco (el generador garantiza 60), ≥ 200 del inicio y entre ellas, ≥ 80 del pico, fuera de las copas.
  - **`level_repository_impl_test.dart`:** `RockDBO` sin id da `rock-<n>` y sin posición da (0, 0); cifras de `Rules`.
  - **`world_mining_test.dart`:**
    - `unknownRock` y `noPickaxe` no mueven al jugador;
    - un `RockHit` cada 750 ms y en el octavo `RockBroken` con 8;
    - la roca sale de `obstacles`;
    - volver a tocarla reinicia el golpe.
  - **`world_regrowth_test.dart`:** un tocón a 33 de una roca no rebrota y a 35 sí.
  - **Resto de dominio:** `blueprints_test.dart` con los costes nuevos; `balance_test.dart` sin cambios.
  - **`forest_bloc_test.dart`:**
    - avisos de pico y de piedra;
    - `RockHitEffect` / `RockBrokenEffect`;
    - la pose `pickaxe`;
    - `HudData` con cuatro recursos y dos herramientas.
  - **Escena y atlas:**
    - `rock_component_test.dart` (61 × 45, toque al píxel, encoger y quitar a los 350 ms);
    - `rock_motion_test.dart`;
    - `particle_bursts_test.dart` (`stoneChips`);
    - `lpc_atlas_test.dart`, `custom_icons_test.dart`, `internationalize_test.dart`;
    - el umbral del HUD.
