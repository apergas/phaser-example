# F5 · Piedra y pico — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F0 |
| **Issue / milestone** | `phase:F5` · milestone `F5 Stone` |

## Objetivo

Añadir un segundo recurso. Así aparece la decisión de qué recoger primero, y se prepara la piedra para los edificios de F7 y F8.

## Decisiones ya tomadas

**Dominio:**
- `Resource.stone` y `ToolKind.pickaxe` (enums de core).
- El pico está en el suelo, como el hacha, a unos 300 u del spawn para obligar a explorar.
- Entidad `RockEntity(id, position, radius, stoneYield, hitsToBreak, hitsTaken)` en `domain/entities/rock/`, con `footprint` como `TreeEntity`. Es un obstáculo: entra en `WorldState.obstacles()`. Su operación `hit()` va en `domain/world/extensions/rock_rules.dart`.

**Mecánica:**
- `MineIntentEntity(rockId)` en `intent_entity.dart` y un sistema `Mining implements Work<MineIntentEntity>` en `domain/world/mining.dart` (pieza interna: se añade a la lista de `test/architecture_test.dart`).
- Un caso en `workFor()` (`work.dart`) y otro en `activity_rules.dart`, con `PlayerActivity.mining` (core).
- Eventos `RockHitEventEntity` y `RockBrokenEventEntity` en `game_event_entity.dart`.
- Enum `MineResult { ok, noPickaxe, unknownRock }` en core (como `ChopResult`) y caso de uso `MineRockUseCase` con `call({required String rockId})`. `World.orderMine(rockId)`.

**Nivel:**
- 10–15 rocas grandes, generadas en `LevelLocalDatasourceImpl` con su **propia semilla** después de los árboles. `RockDBO` en `local/dbo/`, `LevelDBO.rocks`, `RockMapperDBO` en `repositories/level/mappers/`.
- No pueden cambiar las posiciones de árboles ni de la decoración: los tests dorados no se tocan.
- La decoración, que se genera después, también se separa de las rocas. Si eso la cambia, se acepta: se actualizan sus valores dorados (en VM y en Chrome) y se apunta en las desviaciones.

**Clic:**
- `ForestMapClicked` lleva hoy `treeId`. Pasa a llevar el objetivo tocado: o bien `targetId` + un enum `MapTarget { tree, rock }` en `core/config/constants/enum/forest/`, o bien un `rockId` aparte. Se decide en el plan.
- Detección por píxel con `AlphaMask`, igual que en los árboles (`TreeComponent`).

**Arte** (sólo LPC ya disponible):
- Roca grande: un bloque de rocas de `terrain_atlas.png`, frame `rock-large` (`SpriteNames.rock`).
- **En `asset-packs/lpc/sources/tools/` no hay pico.** Solución provisional:
  - El ítem del suelo es el sprite del hacha recoloreado en gris con `recolour()` en `build_assets.py`: frame `pickaxe-pickup`, en `SpriteNames.item(ToolKind.pickaxe)`.
  - La animación de picar reutiliza la **hoja del martillo** (`hero-hammer.png`) con `RenderConstants.hammerSequence`: `WorkTool` (core/enum/forest) gana `pickaxe`, que `PlayerFrames` dibuja con la hoja del martillo.
  - Se apunta como desviación. Queda abierta la opción de traer el pico LPC, que necesitaría créditos.
- Partículas: esquirlas grises. `ParticleKind.stoneChip` y `ParticleBursts.stoneChips(...)`, variante de `woodChips`, con su color en `ParticleBurstComponent`.
- HUD: SVG nuevos `stone.svg` (22×14) y `pickaxe.svg` (22×22) en `lib/core/assets/images/icons/`, con sus casos en `CustomIcons.resource` / `CustomIcons.tool`. `ResourceBar` no cambia (F0).

**Textos** (`es.json` + `Internationalize`):
- `forest.resource.stone: "Piedra"`, `forest.tool.pickaxe: "Pico"`, `forest.amount.stone: "{amount} de piedra"`.
- Mensajes `needPickaxe` y `pickedUpPickaxe`. El mensaje de `ItemPickedUpEventEntity` pasa a depender de su `kind` (el evento ya lo lleva).

**Persistencia:** se guardan las rocas y el pico.

**Si la arena ya está** (plan *Héroe y arena*):
- Si C3 está: 15 de piedra en el coste de `steelSword` y `plateArmor` (`Gear.all`), y 10 de piedra en la Herrería y la Armería (`Blueprints.all`). Si C5 está, también 10 en la Torre de magia.
- Se actualizan sus tests (`gear_test.dart`, `blueprints_test.dart`).
- `Resource.stone` va al final del enum, después de `gold`.

## Ficheros previstos

**Dominio:**
- Entidades: `lib/layers/domain/entities/rock/rock_entity.dart` (nuevo), `intent_entity.dart`, `game_event_entity.dart`, `world_snapshot_entity.dart`.
- Enums de core: `resource.dart`, `tool_kind.dart`, `player_activity.dart`, `mine_result.dart` (nuevo).
- Mundo: `world/mining.dart` (nuevo), `work.dart`, `world.dart`, `world_state.dart`, `navigation.dart`, `extensions/rock_rules.dart` (nuevo), `extensions/activity_rules.dart`.
- Casos de uso: `mine_rock_use_case.dart` (nuevo), `get_world_snapshot_use_case.dart`.

**Datos:** `level_local_datasource_impl.dart`, `dbo/rock_dbo.dart` (nuevo), `dbo/level_dbo.dart`, `mappers/rock_mapper_dbo.dart` (nuevo), `mappers/level_mapper_dbo.dart`.

**Presentación:**
- `bloc/forest_bloc.dart`, `bloc/forest_event.dart`, `models/forest_effect.dart`, `models/player_pose.dart` si cambia la pose.
- `game/components/rock_component.dart` (nuevo), `game/forest_scene_component.dart`, `game/forest_state_listener.dart`, `game/atlas/sprite_names.dart`, `game/render/player_frames.dart`, `game/particles/*`.
- `theme/images/custom_icons.dart`, `Internationalize`, `es.json`.

**Arte:** `asset-packs/lpc/build_assets.py` y `lib/core/assets/images/lpc/CREDITS.md`.

**Tests:** `test/architecture_test.dart` (nueva pieza interna) y `di.config.dart` regenerado (caso de uso y *mapper* nuevos).

## Cómo probarlo

- Clic en una roca sin pico: aparece un mensaje que pide el pico.
- Recoger el pico y picar una roca: la roca se rompe y la piedra sube en el HUD.
- La roca bloquea el paso hasta que se rompe.
- La madera y el hacha siguen funcionando igual que antes.
