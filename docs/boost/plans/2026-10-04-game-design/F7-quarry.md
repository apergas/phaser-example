# F7 · Cantera — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-village/F7-quarry.md`); esta ficha manda sobre la versión anterior.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F7-quarry`, desde `feature/PROJECT-X-town` |
| **Depende de** | F5 (piedra) y F6 (entregas) |
| **Issue / milestone** | `phase:F7` · milestone `F7 Quarry` |
| **Referencia iOS** | merge `ad3be22` (`[PROJECT-F7]: Merge the quarry`), commits `a8cc24a` (reglas y cantera), `c2bbf58` (solo piedra), `6d0289a` (picar más rápido), `8bf7ac4` (arte), `4afbf4f` (motivo en la barra) |

## Objetivo

Una cantera que solo se puede colocar junto a una roca, que solo recibe piedra y que hace más rápido picar las rocas que tiene cerca. Mientras se coloca, la barra explica por qué un sitio no vale.

## Decisiones ya tomadas

**Reglas de colocación:**
- `BlueprintEntity.placementRule: PlacementRuleEntity`, una jerarquía `sealed` en un solo fichero (E8) con `AnywherePlacementRuleEntity` (por defecto) y `NearRockPlacementRuleEntity(range)`. Se evalúa en `domain/world/extensions/placement_rule_rules.dart`.
- "Junto a una roca": distancia de centro a centro **estrictamente** menor que `Rules.quarryRockRange = 120`, contra las rocas que quedan (una rota ya no está). Con radios 40 y 22, el centro de la cantera vale entre 62 (más cerca choca con la roca) y 120.
- `ConstructionRejection.needsNearbyRock`, al final del enum.
- **Orden de los rechazos** (`Construction.rejection`, que sustituye a `canPlace`):
  1. no construible → `blocked` (el campamento);
  2. la regla del plano → su motivo (`needsNearbyRock`);
  3. fuera del mapa, encima de un obstáculo, del jugador o de un objeto → `blocked`.

  La regla va antes que el sitio, para que lejos de las rocas el motivo sea siempre "junto a una roca". `place` comprueba antes el almacén (`notEnoughResources`).
- `CanPlaceBuildingUseCase` conserva el nombre y devuelve `ConstructionRejection?` (`null` = se puede).

**Cantera** (`BlueprintId.quarry`, al final del enum): 25 de madera, 8 golpes, radio 40, **tercera** en el menú (tras el almacén).

**Qué recibe cada edificio:**
- El booleano de punto de entrega de F6 pasa a `accepts: Set<Resource>`: campamento y almacén `{wood, stone}`, cantera `{stone}`, los demás vacío.
- `BuildingRules.acceptsDeposits` = terminado y `accepts` no vacío.
- `Depositing` deja en la carga lo que el edificio no acepta. Con solo madera en la cantera → `emptyLoad` y el aviso de siempre; con madera y piedra, entrega la piedra y la madera se queda.

**Picar más rápido:**
- `Rules.quarryMineIntervalMs = 525` (750 − 30 %) cuando hay una cantera **terminada** a menos de `Rules.quarryBoostRange = 160` de la **roca** (no del jugador). 160 > 120, así que la roca junto a la que se colocó siempre queda dentro.
- `Work.intervalMs` pasa a depender del estado (`intervalMs(WorldState state)` en cada `Work`). Talar (750), construir (650) y entregar (400) no cambian. `World` lee el intervalo una vez por tick.

**Arte** (sin autores nuevos): `quarry` = la roca grande entre dos bloques de piedra agrietada, tras dos tramos de la valla de la arena (128 × 63, pivote `(0.5, 1)`). `buildingFrontOffset` 16, porque es bajita.

**El motivo mientras se coloca:**
- `PlacementData.invalidReason: ConstructionRejection?` (con `isValid` calculado) y un texto por motivo (`Internationalize.forestPlacementRejection`).
- La `PlacementBar` (táctil) enseña el rótulo para **cualquier** motivo, también "Ahí no cabe." sobre el jugador, en color de aviso. Ocupa siempre su hueco (transparente si el sitio vale), para que la barra no cambie de altura y el *snackbar* no salte.
- En la web, sin barra, el motivo sale en el *snackbar* al intentar colocar.
- Tocar el mapa o *Construir aquí* con `needsNearbyRock` avisa y la colocación sigue abierta, como con `blocked`.

**Textos:** `forest.blueprint.quarry` "Cantera", `forest.placement.needsRock` "La cantera tiene que ir junto a una roca.".

**Guardado:** la cantera es un edificio más (F2). Al cargar no se vuelve a comprobar la regla: una cantera guardada se queda aunque su roca ya esté rota.

## Ficheros previstos

- **Dominio:** `entities/building/blueprint_entity.dart`, `entities/building/placement_rule_entity.dart` (nuevo), `rules/blueprints.dart`, `rules/rules.dart`, `world/construction.dart`, `mining.dart`, `depositing.dart`, `work.dart`, `woodcutting.dart`, `world.dart`, `extensions/placement_rule_rules.dart` (nuevo), `extensions/building_rules.dart`, `extensions/inventory_rules.dart`, `use-cases/game/can_place_building_use_case.dart`.
- **Core:** `blueprint_id.dart`, `construction_rejection.dart`, `es.json`, `internationalize.dart`.
- **Presentación:** `models/placement_data.dart`, `bloc/forest_bloc.dart`, `widgets/placement_bar.dart`, `game/atlas/sprite_names.dart`, `game/render/render_constants.dart`.
- **Arte:** `build_assets.py`, `forest.{png,json}`, `CREDITS.md`.

## Cómo probarlo

- "Cantera" es la tercera del menú. Lejos de las rocas la silueta sale roja y la barra dice "La cantera tiene que ir junto a una roca."; tocar avisa y no coloca. Junto a una roca sale verde y sin texto.
- La cantera terminada recibe la piedra y deja la madera en la carga.
- Picar las rocas cercanas va visiblemente más rápido (525 ms frente a 750).
- Tests:
  - `placement_rule_rules_test.dart`: a 61, 62, 119,9 y 120 de la roca; una roca rota no cuenta;
  - `construction_test.dart`: el orden de los rechazos;
  - `world_deposit_test.dart`: la cantera solo recibe piedra y con solo madera da `emptyLoad`;
  - `world_mining_test.dart`: 525 ms con la cantera terminada a < 160 de la roca y 750 a medio hacer o lejos;
  - `can_place_building_use_case_test.dart` devuelve el motivo;
  - `forest_bloc_test.dart` y `placement_bar_test.dart`: el motivo en la barra y en el aviso, y la barra con la misma altura;
  - `lpc_atlas_test.dart` e `internationalize_test.dart`.
