# Recursos directos al almacén — ficha

> Mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-auto-stock`, desde `develop` |
| **Estado** | Plan detallado |
| **Cuándo** | T1 ya está en `develop` (#84): esta mejora escribe y arregla sus tests con TDD |

**Qué se quiere** (pedido por el usuario el 2026-10-18): quitar la mecánica de llevar lo recogido al almacén. Al talar un árbol o romper una roca, la madera o la piedra se suman directamente al almacén de la aldea.

**Qué desaparece** (lo que añadió F6 y toda F7):
- **La carga:** `Rules.carryCapacity`, `InventoryRules.load` / `freeLoad` / `isLoadFull` / `cargo` / `cargoFor` / `unloading`, `ResourceRules.takesCargo`, los resultados `ChopResult.carryFull` y `MineResult.carryFull` y sus avisos.
- **La entrega:** `Depositing`, `DepositIntentEntity`, `PlayerActivity.depositing`, `World.orderDeposit`, `DepositUseCase`, `DepositResult`, `DepositedEventEntity`, `Rules.depositIntervalMs`, `BuildingRules.acceptsDeposits` y `BlueprintEntity.accepts`.
- **En el HUD:** `CarryItemData`, "Carga 7/10" y su separador en `ResourceBar`, los textos `forest.carry`, `carryFull`, `deposited` y `nothingToDeposit` (con sus variantes táctiles).
- **En `ForestBloc`:** tocar un edificio ya no intenta entregar; uno sin terminar reanuda la obra y uno terminado deja pasar el toque al movimiento, como antes de F6. El autoguardado tras una entrega desaparece (sigue el de árbol talado y roca rota).

**Qué cambia:**
- **`Woodcutting` y `Mining`:** el último golpe suma toda la madera del árbol (`treeKindStats`) o toda la piedra de la roca (`Rules.rockStoneYield`) a `WorldState.stock`, sin límite. El evento lleva esa cantidad entera y el "+N" flotante no cambia.
- **Inventario:** `InventoryEntity.resources` deja de usarse; se quita y el inventario guarda solo `tools` y `toolLevels`. `GetPlayerStatusUseCase` deja de dar la carga.
- **Almacén (`BlueprintId.storehouse`):** sin entrega ya no sirve para nada. Se quita del catálogo y del enum, con su frame del atlas, su icono SVG, sus textos y su `buildingFrontOffset` (decidido con el usuario el 2026-10-18).
- **Cantera (`BlueprintId.quarry`):** se quita del todo, como el almacén (decidido con el usuario el 2026-10-18): catálogo, enum, frame del atlas (`build_assets.py` y `forest.json`, y `CREDITS.md` si deja de usarse algo), icono SVG, textos, `buildingFrontOffset` y `SpriteNames`. Con ella se van la aceleración de la minería (`Rules.quarryMineIntervalMs`, `quarryBoostRange`, `BuildingRules.boostsMining`; `Mining` vuelve a un ritmo fijo de `Rules.mineIntervalMs`) y la regla de colocación junto a una roca (`Rules.quarryRockRange`, `NearRockPlacementRuleEntity`, `PlacementRuleRules`, `ConstructionRejection.needsNearbyRock` y su texto). Si `PlacementRuleEntity` se queda solo con `AnywherePlacementRuleEntity`, se quita la jerarquía entera y `BlueprintEntity.placementRule`.
- **Picar piedra:** una roca pasa de 8 a 7 golpes (`Rules.rockHitsToBreak` 7). Con el pico de hierro bajan a ⌈7 × 60 %⌉ = 5, igual que ahora; cada golpe tarda lo mismo que un hachazo (decidido con el usuario el 2026-10-18): `Rules.mineIntervalMs` se quita y `Mining` usa `Rules.chopIntervalMs` (750 ms), así que si cambia el ritmo de la tala cambia también el de la minería.
- **Campamento:** se queda como edificio inicial del mapa, ya sin función de entrega.
- **Misiones:** "Lleva 15 de madera al almacén" pasa a "Reúne 15 de madera"; las de 40 de madera y 20 de piedra se quedan, porque ya leen el almacén. *Construye una cantera* (`QuestId.buildQuarry`) sale de `Quests.all` y del enum: el capítulo 2 queda en reunir piedra, taller y hacha de hierro, y la línea de la aldea pasa de 11 a 10 misiones (19 → 18 en total).
- **HUD:** `ResourceBar` se estrecha, así que hay que volver a medir `HudOverlay.buttonsBelowWidth` y `narrowWidth` con Roboto. La etiqueta "Almacén" del principio de la barra se queda.
- **Guardado:** `SaveDBO.currentVersion` pasa a 2, porque el inventario ya no lleva recursos y, si sale, el almacén ya no es un `BlueprintId`. Una partida de la versión 1 se migra al cargar: lo que llevaba el jugador se suma al almacén los almacenes y canteras construidos se quitan del mapa y la misión `buildQuarry` completada se descarta (decidido con el usuario el 2026-10-18).
- **Documentación:** `CLAUDE.md` (la carga, `Depositing`, el almacén, el formato del guardado), `docs/GAME_DESIGN.md` y las fichas de F6 y F7, donde se anota que la carga, el almacén y la cantera se quitaron aquí.
- **Tests:** los de la carga, la entrega, el almacén y el HUD de T1 se quitan o se adaptan, y se añaden los de la suma directa y la migración del guardado. El test de equilibrado no cambia, porque la arena no usa la carga.
- **iOS** no se toca: es un cambio nuevo, no de paridad.

## Prueba manual

En Chrome: talar un pino suma 4 de madera al almacén al instante y una roca se rompe en 7 golpes (5 con el pico de hierro) y suma su piedra, sin límite de carga. El menú *Construir* ya no ofrece almacén ni cantera. Tocar el campamento no hace nada especial. La barra ya no muestra "Carga" y los botones caben en la misma línea en pantallas más estrechas que antes. Una partida guardada antes del cambio carga con lo que llevaba el jugador ya sumado al almacén.

---

# Recursos directos al almacén — plan de implementación

> **Para agentes:** `boost:executing-plans` (en línea) o `boost:subagent-driven-development`. Con TDD (`boost:test-driven-development`): T1 ya está en `develop`, así que cada tarea escribe o adapta sus tests antes del código y borra los de lo que desaparece. Los pasos usan casillas (`- [ ]`).

**Objetivo:** talar un árbol o romper una roca suma toda su madera o piedra a `WorldState.stock`, sin carga, sin entrega, sin almacén ni cantera; las partidas de la versión 1 se migran al cargar.

**Arquitectura:** el almacén deja de ser un `InventoryEntity` (que pierde `resources`) y pasa a ser un `StockEntity` propio con sus operaciones en `StockRules`; `Woodcutting` y `Mining` escriben en él. Se borra lo que añadió F6 (carga y `Depositing`) y F7 (cantera, regla de colocación, aceleración). El guardado sube a la versión 2 con un `SaveMigrationMapperDBO` que convierte una `SaveDBO` de la versión 1 antes de mapearla.

**Tecnología:** Flutter / Dart, `injectable` + `build_runner`, mockito, `bloc_test`, Pillow para el atlas.

## Restricciones globales

- Commits `[PROJECT-X]: <Imperative description in English>`, sin atribución a IA; el fichero de instrucciones del proyecto se añade con su propio `git add`.
- `dart format --line-length 120` solo sobre lo escrito (nunca `di.config.dart` ni `*.mocks.dart`); `dart run build_runner build --delete-conflicting-outputs` tras cambiar DI o `@GenerateMocks`.
- Tests: `testWhen<Action>Then<Result>`, `// given` / `// when` / `// then`, datos en `test/mocks/**` (nada inline salvo `PositionEntity(x:, y:)`), textos por `Internationalize`.
- Cada tarea termina con `flutter analyze` sin avisos y `flutter test` en verde.
- El test de equilibrado (`balance_test.dart`) no cambia y sigue en verde.

## Decisiones

- **`StockEntity`** (`lib/layers/domain/entities/stock/stock_entity.dart`): `final Map<Resource, int> resources`, `const` con `{}` por defecto, `copyWith`, `==`/`hashCode` a mano. Sus operaciones, que hoy están en `InventoryRules` (`amount`, `add`, `adding`, `missing`, `spend`), pasan a `StockRules` en `world/extensions/stock_rules.dart`. `WorldState.stock`, `World.stock`, `World.funds`, `World.restore(stock:)` y `GetStockUseCase` usan `StockEntity`. *No está en la ficha*: hace falta porque el almacén era un `InventoryEntity` y la ficha quita `InventoryEntity.resources`.
- **`InventoryRules`** se queda con `addTool`, `hasTool`, `toolLevel`, `withToolLevel` y `hitsNeeded`. `ResourceRules` se borra entera (solo tenía `takesCargo`).
- **`Work.intervalMs(state, intent)`** se queda como está: `Construction` y `Woodcutting` ya tienen ritmo fijo, y `Mining` devuelve `Rules.chopIntervalMs`.
- **Tocar un edificio:** `_orderAtBuilding` queda en `_resumeConstructionUseCase(buildingId: id) == ResumeConstructionResult.ok`; terminado o desconocido, el toque sigue hacia roca, árbol o movimiento.
- **Guardado v2:** el inventario se guarda con `tools` y `toolLevels` (sin `resources`); el almacén pasa a un `SaveStockDBO { resources }` con su `SaveStockMapperDBO` (misma forma JSON que el `stock` de la versión 1, que llevaba además `tools` y `toolLevels` vacíos, ignorados). `SaveInventoryDBO.resources` se queda, nullable, solo para leer la versión 1; el mapper del inventario no lo lee. `SaveMigrationMapperDBO.toCurrent(SaveDBO)`: versión 2 → igual; versión 1 → suma `player.inventory.resources` a `stock.resources` (un importe negativo es `InvalidSaveException`), quita los `buildings` con `blueprint` `storehouse` o `quarry`, quita `buildQuarry` de `completedQuests`, quita los recursos del inventario y pone `version: 2`; otra versión → `InvalidSaveException`. `SaveMapperDBO.toEntity` la llama primero.
- **Textos:** `forest.quest.gatherWood` "Reúne 15 de madera"; fuera `forest.hud.carry`, `forest.message.carryFull`, `deposited`, `nothingToDeposit`, `forest.placement.needsRock`, `forest.blueprint.storehouse` / `quarry` y `forest.quest.buildQuarry`. Estos textos no tienen variante `…Touch`.
- **Arte:** fuera `build_storehouse`, `build_quarry`, sus constantes (`STOREHOUSE_WALL_BOX`, `CRATE_*`, `QUARRY_*`) y sus frames; se regenera `forest.png` / `forest.json`. En `CREDITS.md` se quitan los párrafos del almacén y la cantera y sus nombres del título (las fuentes siguen usándose para otros frames).
- **Prueba manual:** el pino da 4 de madera (`Rules.treeKindStats`), no 3 como decía la ficha (3 son sus golpes).

## Tarea 1: el almacén como `StockEntity`

Refactor sin cambio de comportamiento.

**Archivos:**
- Crear: `lib/layers/domain/entities/stock/stock_entity.dart`, `lib/layers/domain/world/extensions/stock_rules.dart`, `test/layers/domain/entities/stock/stock_entity_test.dart`, `test/layers/domain/world/extensions/stock_rules_test.dart`, `test/mocks/domain/entities/stock/stock_entity_mock.dart`
- Modificar: `world_state.dart`, `world.dart`, `construction.dart`, `depositing.dart`, `quests.dart`, `get_stock_use_case.dart`, `get_build_options_use_case.dart`, `get_upgrade_options_use_case.dart`, `get_gear_options_use_case.dart`, `get_skill_options_use_case.dart`, `save_mapper_dbo.dart` (aquí solo convierte `StockEntity` ↔ `SaveInventoryDBO.resources`; el DBO propio llega en la Tarea 4), `forest_bloc.dart`, y los mocks y tests que construyen el almacén (`forest_scenario_mock.dart`, `save_scenario_mock.dart`, `game_scenario_mock.dart`, `world_funds_test.dart`, `world_restore_test.dart`, `get_stock_use_case_test.dart`…).

```dart
class StockEntity {
  final Map<Resource, int> resources;

  const StockEntity({this.resources = const {}});

  StockEntity copyWith({Map<Resource, int>? resources}) => StockEntity(resources: resources ?? this.resources);

  @override
  bool operator ==(Object other) =>
      other is StockEntity && const MapEquality<Resource, int>().equals(other.resources, resources);

  @override
  int get hashCode => const MapEquality<Resource, int>().hash(resources);
}
```

- [ ] **Paso 1:** tests de `StockEntity` (igualdad, `copyWith`) y de `StockRules` (los de recursos de `inventory_rules_test.dart`: `amount`, `add` negativo/cero, `adding`, `missing`, `spend`), con `StockEntityMock`. Fallan: no existe.
- [ ] **Paso 2:** crear la entidad y `StockRules` (las operaciones de recursos de `InventoryRules` sobre `StockEntity`).
- [ ] **Paso 3:** cambiar `WorldState.stock`, `World` (`stock`, `funds`, `earn`, `restore`), `Construction.place`, `Depositing.impact`, `Quests`, los casos de uso y `ForestBloc` a `StockEntity` / `StockRules`; el mapper del guardado convierte el almacén con `SaveInventoryDBO(resources:)`. Adaptar mocks y tests del almacén a `StockEntityMock`.
- [ ] **Paso 4:** `flutter analyze`, `flutter test`, formatear, commit `[PROJECT-X]: Keep the village stock in its own entity`.

## Tarea 2: lo recogido va directo al almacén; fuera la carga y la entrega

**Archivos:**
- Modificar: `rules.dart` (fuera `carryCapacity`, `depositIntervalMs`), `inventory_entity.dart` (fuera `resources`), `inventory_rules.dart`, `woodcutting.dart`, `mining.dart`, `world.dart`, `work.dart`, `intent_entity.dart`, `activity_rules.dart`, `game_event_entity.dart`, `stats_recording.dart`, `building_rules.dart` (fuera `acceptsDeposits`), `blueprint_entity.dart` y `blueprints.dart` (fuera `accepts`), `chop_result.dart` y `mine_result.dart` (fuera `carryFull`), `player_activity.dart` (fuera `depositing`), `save_inventory_mapper_dbo.dart` (no escribe ni lee recursos), `save_player_mapper_dbo.dart` (fuera la comprobación de la carga), `forest_bloc.dart`, `forest_page.dart`, `hud_data.dart`, `resource_bar.dart`, `hud_overlay.dart`, `internationalize.dart`, `es.json`.
- Borrar: `depositing.dart`, `deposit_use_case.dart`, `deposit_result.dart`, `resource_rules.dart`, `carry_item_data.dart` y sus tests y mocks (`world_deposit_test.dart`, `deposit_use_case_test.dart`, `resource_rules_test.dart`, `carry_item_data_mock.dart`…).
- Tests: `world_chopping_test.dart`, `world_mining_test.dart`, `inventory_rules_test.dart`, `forest_bloc_test.dart`, `forest_bloc_village_test.dart`, `forest_bloc_save_test.dart`, `resource_bar_test.dart`, `hud_overlay_test.dart`, `internationalize_test.dart`, `save_*_mapper_dbo_test.dart`, `game_flow_test.dart`.

```dart
state.trees.remove(tree.id);
state.stumps[tree.id] = StumpEntity(id: tree.id, kind: tree.kind, position: tree.position);
state.stock = state.stock.add(Resource.wood, tree.woodYield);
events.add(TreeFelledEventEntity(treeId: tree.id, wood: tree.woodYield));
```

```dart
state.rocks.remove(rock.id);
state.stock = state.stock.add(Resource.stone, rock.stoneYield);
events.add(RockBrokenEventEntity(rockId: rock.id, stone: rock.stoneYield));
```

- [ ] **Paso 1:** tests nuevos: `testWhenATreeIsFelledThenItsWholeWoodGoesToTheStock` (con el almacén ya por encima de 10), `testWhenARockBreaksThenItsWholeStoneGoesToTheStock`; en el bloc, `testWhenAFinishedBuildingIsTappedThenThePlayerWalksThere` y `testWhenAnUnfinishedBuildingIsTappedThenConstructionResumes` (sin entrega), y que la barra ya no muestra la carga. Fallan.
- [ ] **Paso 2:** el código de arriba en `Woodcutting` y `Mining`, sin `carryFull` en `check`; fuera `Depositing`, la intención, la actividad, el evento, el caso de uso, `DepositResult`, `acceptsDeposits`, `accepts`, la carga de `InventoryRules`, `ResourceRules`, `InventoryEntity.resources` y las reglas.
- [ ] **Paso 3:** `ForestBloc`: fuera `_depositUseCase`, `_isGathering` y los avisos de carga llena; `_orderAtBuilding` solo reanuda obras; fuera `DepositedEventEntity` de `_isWorthSaving` y `_react`; `HudData` sin `carry`; `ResourceBar` sin `_carry()` ni `carryKey`; `ForestPage` sin `DepositUseCase`. Textos fuera de `Internationalize` y `es.json`.
- [ ] **Paso 4:** borrar los tests de lo quitado y adaptar los demás (lo que empezaba con recursos en el inventario pasa a tenerlos en el almacén).
- [ ] **Paso 5:** `dart run build_runner build --delete-conflicting-outputs` (DI sin `DepositUseCase`), `flutter analyze`, `flutter test`, formatear, commit `[PROJECT-X]: Send gathered resources straight to the stock`.

## Tarea 3: fuera el almacén, la cantera y su regla; roca de 7 golpes

**Archivos:**
- Modificar: `blueprint_id.dart` (fuera `storehouse`, `quarry`), `blueprints.dart`, `blueprint_entity.dart` (fuera `placementRule`), `construction.dart`, `building_rules.dart` (fuera `boostsMining`), `mining.dart`, `rules.dart` (fuera `mineIntervalMs`, `quarryMineIntervalMs`, `quarryRockRange`, `quarryBoostRange`; `rockHitsToBreak` 7), `construction_rejection.dart` (fuera `needsNearbyRock`), `quest_id.dart` y `quests.dart` (fuera `buildQuarry`), `sprite_names.dart`, `render_constants.dart`, `internationalize.dart`, `es.json`, `build_assets.py`, `forest.png` / `forest.json` (regenerados), `CREDITS.md`.
- Borrar: `placement_rule_entity.dart`, `placement_rule_rules.dart` y sus tests y mocks.
- Tests: `blueprints_test.dart`, `world_construction_test.dart`, `world_mining_test.dart`, `can_place_building_use_case_test.dart`, `quests_test.dart`, `get_quests_use_case_test.dart`, `building_rules_test.dart`, `lpc_atlas_test.dart`, `sprite_names_test.dart`, `internationalize_test.dart`, `placement_bar_test.dart`, `placement_data_test.dart`, `rock_entity_mock.dart`…

```dart
@override
double intervalMs(WorldState state, MineIntentEntity intent) => Rules.chopIntervalMs;
```

```dart
static ConstructionRejection? rejection(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
  if (!blueprint.isBuildable) return ConstructionRejection.blocked;
  final radius = blueprint.footprintRadius;
  // ... sin la regla de colocación, igual que hoy desde aquí
}
```

- [ ] **Paso 1:** tests: `testWhenARockIsMinedSevenTimesThenItBreaks`, `testWhenTheIronPickaxeHitsFiveTimesThenTheRockBreaks`, `testWhenMiningThenEachBlowTakesTheChoppingInterval`, `Blueprints.all` sin almacén ni cantera, `Quests.all` con 10 misiones en la aldea y 18 en total. Fallan.
- [ ] **Paso 2:** quitar los dos planos del catálogo y del enum, la jerarquía `PlacementRuleEntity`, `PlacementRuleRules`, `needsNearbyRock`, `boostsMining`, las constantes y `buildQuarry`; `Rules.rockHitsToBreak = 7`; `Mining.intervalMs` con `Rules.chopIntervalMs`.
- [ ] **Paso 3:** `SpriteNames`, `RenderConstants.buildingFrontOffset`, `Internationalize` (`forestBlueprint`, `forestQuestTitle`, `forestPlacementRejection`) y `es.json` sin esos casos.
- [ ] **Paso 4:** en `build_assets.py`, quitar `build_storehouse`, `build_quarry`, sus constantes y frames y su mención en el docstring; `cd asset-packs/lpc && python3 build_assets.py`; `CREDITS.md` sin el almacén ni la cantera.
- [ ] **Paso 5:** borrar y adaptar tests y mocks; `flutter analyze`, `flutter test`, formatear, commit `[PROJECT-X]: Remove the storehouse and the quarry`.

## Tarea 4: guardado versión 2 con migración

**Archivos:**
- Crear: `lib/layers/data/datasources/save/local/dbo/save_stock_dbo.dart`, `lib/layers/data/repositories/save/mappers/save_stock_mapper_dbo.dart`, `lib/layers/data/repositories/save/mappers/save_migration_mapper_dbo.dart`, sus tests y mocks (`save_stock_dbo_mock.dart`, variantes de la versión 1 en `save_dbo_mock.dart` / `save_json_mock.dart`).
- Modificar: `save_dbo.dart` (`currentVersion = 2`, `stock` como `SaveStockDBO`), `save_mapper_dbo.dart`, `save_inventory_dbo.dart`, DI regenerada.

```dart
SaveDBO toCurrent(SaveDBO dbo) => switch (dbo.version) {
  SaveDBO.currentVersion => dbo,
  1 => _fromVersionOne(dbo),
  _ => throw InvalidSaveException(data: 'unknown version ${dbo.version}'),
};
```

- [ ] **Paso 1:** tests de `SaveMigrationMapperDBO`: `testWhenAVersionOneSaveIsMigratedThenTheCarriedResourcesJoinTheStock`, `…ThenStorehousesAndQuarriesAreRemoved`, `…ThenTheQuarryQuestIsDropped`, `…ThenItBecomesVersionTwo`, `testWhenAVersionTwoSaveIsMigratedThenItIsUnchanged`, `testWhenAnUnknownVersionIsMigratedThenItThrowsInvalidSave`, `testWhenACarriedAmountIsNegativeThenItThrowsInvalidSave`; de `SaveStockMapperDBO` (ida y vuelta, recurso desconocido, importe negativo); de `GameSaveRepositoryImpl.load` con un JSON de la versión 1. Fallan.
- [ ] **Paso 2:** crear `SaveStockDBO`, `SaveStockMapperDBO` y `SaveMigrationMapperDBO`; `SaveMapperDBO` los usa; `currentVersion = 2`.
- [ ] **Paso 3:** `dart run build_runner build --delete-conflicting-outputs`, adaptar los tests del guardado (la versión de los mocks pasa a 2), `flutter analyze`, `flutter test`, `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart`, formatear, commit `[PROJECT-X]: Migrate version 1 saves to the direct stock`.

## Tarea 5: umbrales del HUD

**Archivos:** `lib/layers/presentation/features/forest/widgets/hud_overlay.dart` y, si hace falta, `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`.

- [ ] **Paso 1:** medir con un test de usar y tirar en el *scratchpad* (Roboto con `loadRobotoFont`, `HudDataMock.withEveryResourceAndTool`: 9999 de cada recurso y las dos herramientas mejoradas) el ancho de la barra con y sin nombres y de la fila de seis botones.
- [ ] **Paso 2:** `buttonsBelowWidth` = 12 + barra con nombres + 8 + botones + 12 + 24, redondeado hacia arriba a la decena; `narrowWidth` = barra con nombres + 24 de márgenes + 24, redondeado igual. Los tests de los umbrales en verde.
- [ ] **Paso 3:** `flutter test test/layers/presentation/features/forest/widgets`, formatear, commit `[PROJECT-X]: Measure the HUD breakpoints without the load`.

## Tarea 6: documentación y cierre

- [ ] Fichero de instrucciones del proyecto: la carga, `Depositing`, el almacén y la cantera, la regla de colocación, el ritmo y los golpes de la minería, `StockEntity`, el guardado v2 y la migración, los conteos de misiones (10 en la aldea, 18 en total), los umbrales del HUD.
- [ ] `docs/GAME_DESIGN.md`: lo que hablaba de carga, almacén y cantera.
- [ ] Nota en `F6-storehouse.md` y `F7-quarry.md`: la carga, la entrega, el almacén y la cantera se quitaron en esta mejora.
- [ ] Batería final: `build_runner` + `git diff --exit-code`, `flutter analyze`, `flutter test`, golden en Chrome.
- [ ] `PROGRESS.md`: fila de la mejora ✅ en `develop` con los tests; *Siguiente paso* 1 → ✅. Casillas de este plan marcadas. Commit `[PROJECT-X]: Close the direct stock improvement`.
