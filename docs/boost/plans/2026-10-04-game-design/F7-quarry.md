# F7 · Cantera — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F5 (piedra) y F6 (entregas) |
| **Issue / milestone** | `phase:F7` · milestone `F7 Quarry` |

## Objetivo

Añadir la primera **regla de colocación** propia de un edificio, y un edificio cuya función depende del terreno.

## Decisiones ya tomadas

**Cantera** (`BlueprintId.quarry`):
- Cuesta 25 de madera.
- **Sólo se puede colocar** a menos de `Rules.quarryRockRange` (≈ 120 u) de una roca que no esté rota.

**Reglas de colocación:**
- `BlueprintEntity` gana `placementRule: PlacementRuleEntity`, una jerarquía `sealed` en un solo fichero (E8) con dos casos: `AnywherePlacementRuleEntity` y `NearRockPlacementRuleEntity(range)`.
- `Construction.canPlace` evalúa la regla.
- El motivo del rechazo se expone como `ConstructionRejection.needsNearbyRock` (enum de core).
- `CanPlaceBuildingUseCase` pasa a devolver el motivo (o `null` si se puede), y `PlacementData` gana `invalidReason`, para explicar el porqué mientras se coloca (`Internationalize.forestPlacementNeedsRock`).

**Funciones:**
- Es punto de entrega de **piedra**. Los almacenes de F6 aceptan todo; la cantera, sólo piedra.
- Picar a menos de `Rules.quarryBoostRange` de una cantera terminada es un 30 % más rápido. Para ello, `Work.intervalMs` pasa a depender del estado (`intervalMs(WorldState state, I intent)`), lo que toca también a `Woodcutting` y `Construction`.

**Arte:** frame `quarry`, montado en `build_assets.py` con rocas de `terrain_atlas` y un tejadillo o una valla, todo con piezas existentes.

## Ficheros previstos

- **Dominio:** `entities/building/blueprint_entity.dart`, `entities/building/placement_rule_entity.dart` (nuevo), `rules/blueprints.dart`, `rules/rules.dart`, `world/construction.dart`, `world/mining.dart`, `world/depositing.dart`, `world/work.dart`, `use-cases/game/can_place_building_use_case.dart`, enums de core (`blueprint_id.dart`, `construction_rejection.dart`).
- **Presentación:** `models/placement_data.dart` (`invalidReason`), `bloc/forest_bloc.dart`, `widgets/placement_bar.dart`, `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`, `Internationalize`, `es.json`.
- **Arte:** `build_assets.py`.
- **UI:** el motivo se muestra como texto en la barra de colocación (táctil) y en un *snackbar* al intentar colocar (web y táctil).

## Cómo probarlo

- Elegir "Cantera": la previsualización sale roja lejos de una roca, con el motivo, y verde cerca de una.
- Una vez construida, se puede entregar piedra en ella.
- Picar cerca de la cantera es visiblemente más rápido. Se puede medir el tiempo entre golpes.
