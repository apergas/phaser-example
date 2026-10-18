# Empezar con el pico y sin el campamento — ficha

> Mejora sin fase propia: commits `[PROJECT-X]: …`. Antes de implementarla, `boost:writing-plans` sobre esta ficha. Issue #88.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-clean-start`, desde `develop` |
| **Estado** | Hecho (1156 tests, 257 en Chrome) |
| **Cuándo** | Después de [recursos directos al almacén](auto-stock.md): T1 ya está en `develop`, así que esta mejora escribe y arregla sus tests con TDD |

**Qué se quiere** (pedido por el usuario el 2026-10-18): "en el suelo siguen saliendo como unas maderas cuando apareces. quita eso" y "haz que al inicio ya dispongas del pico, que no haya que recogerlo".

**Por qué:**
- Las "maderas" son el campamento (`BlueprintId.camp`, un tocón delante de un montón de troncos que dibuja `build_camp` en `build_assets.py`), que el nivel pone terminado en (700, 592). Desde que [lo recogido va directo al almacén](auto-stock.md) ya no recibe nada: no tiene función.
- Ir a por el pico a (1012, 812) no aporta nada, igual que pasaba con el hacha ([empezar con el hacha](start-with-axe.md)).

**Qué desaparece:**
- **El campamento:** `Blueprints.camp`, `BlueprintId.camp`, su frame `camp` del atlas (`build_camp` y sus constantes `CAMP_*`), `SpriteNames`, `RenderConstants.buildingFrontOffset`, el texto `forest.blueprint.camp` y su línea en `CREDITS.md`. Sin él, `BlueprintEntity.isBuildable` siempre vale `true`, así que se quita con su comprobación en `Construction.rejection` y el filtro de `GetBuildOptionsUseCase`.
- **Los edificios del nivel:** el campamento era el único, así que se van `LevelDBO.buildings`, `BuildingDBO`, `BuildingMapperDBO` y los ids `level-building-<n>`.
- **Los objetos del suelo:** el pico era el único, así que se va todo el sistema: `GroundItemEntity`, `pickUpItems`, `Rules.pickUpRange`, `ItemPickedUpEventEntity`, `WorldState.items`, `World.items`, `WorldSnapshotEntity.items`, la comprobación de objetos al colocar un edificio, `ItemDBO`, `LevelDBO.items`, `GroundItemMapperDBO`, `UnknownItemKindException` y sus textos, `GroundItemComponent`, `ItemPickedUpEffect`, `SpriteNames.item`, los frames `axe-pickup` y `pickaxe-pickup` (con `AXE_PICKUP`, `AXE_COLOURS` y `PICKAXE_COLOURS`), los textos `pickedUpAxe`, `pickedUpAxeTouch`, `pickedUpPickaxe` y `pickedUpPickaxeTouch`, la reacción de `ForestBloc` y el autoguardado tras recoger un objeto. En el guardado, `SaveItemDBO`, `SaveGroundItemMapperDBO` y `SaveDBO.items`.

**Qué cambia:**
- **Inicio:** `LevelMapperDBO` da al jugador el hacha y el pico (`InventoryEntity(tools: {ToolKind.axe, ToolKind.pickaxe})`). `MineResult.noPickaxe` y su aviso se quedan, como `ChopResult.noAxe`.
- **Mapa:** la decoración que se quitaba por caer sobre el campamento o el pico se queda: de 93 piezas se pasa a 95 (vuelven `decoration-78`, que tapaba el campamento, y `decoration-105`, que tapaba el pico, sin cambiar de id; `-40` y `-85` siguen fuera porque también caen junto a una roca). Las rocas no se mueven: el sitio donde estaba el pico sigue libre de rocas (80 alrededor de (1012, 812)), porque sin esa comprobación entraría una roca nueva en (979, 771) y se correrían los ids de las demás.
- **Escena:** un edificio que nace terminado (opaco, sin barra ni rebote) y la limpieza de la decoración bajo los edificios al construir la escena se quedan, porque son los de una partida cargada.
- **Guardado:** `SaveDBO.currentVersion` pasa a 3. Al cargar una partida de la versión 1 o 2 se quitan los campamentos, se olvidan los objetos del suelo y se añade el pico a las herramientas del jugador (sus `toolLevels` se quedan). La versión 1 pasa antes por su migración al almacén. Cualquier otra versión empieza una partida nueva.
- **Documentación:** `CLAUDE.md` (el campamento, los edificios del nivel, el pico en el suelo, los objetos del suelo y el formato del guardado), `docs/GAME_DESIGN.md` si los menciona y una nota en la ficha de F5.
- **Tests:** los del campamento, los edificios del nivel y los objetos del suelo se quitan; se adaptan los valores fijos del nivel (decoración) y se añaden los del inicio con el pico y la migración a la versión 3. La arena y el test de equilibrado no cambian.
- **iOS** no se toca.

**Hecho:** en la escena, el campamento de los tests de un edificio cargado pasa a ser una casa terminada (`ForestDataMock.loadedHouse`), y el test de flujo completo empieza con el hacha en la mano. `BuildingEntityMock.dropOffSite` conserva su nombre.

## Prueba manual

En Chrome: al empezar una partida nueva ya no hay troncos junto al jugador ni pico en el suelo; la barra muestra el hacha y el pico y se puede picar una roca nada más empezar. *Construir* sigue ofreciendo los mismos edificios. Una partida guardada antes del cambio carga sin el campamento y con el pico.

---

# Empezar con el pico y sin el campamento — plan de implementación

> **Para agentes:** `boost:executing-plans` (en línea) o `boost:subagent-driven-development`. Con TDD (`boost:test-driven-development`): cada tarea escribe o adapta sus tests antes del código y borra los de lo que desaparece. Los pasos usan casillas (`- [ ]`).

**Objetivo:** la partida empieza con el hacha y el pico, sin campamento ni objetos en el suelo; las partidas de las versiones 1 y 2 se migran al cargar.

**Arquitectura:** se borra el plano del campamento y el soporte de edificios del nivel, y después todo el sistema de objetos del suelo (dominio, nivel, guardado y escena). El guardado sube a la versión 3 con un paso más en `SaveMigrationMapperDBO`.

**Tecnología:** Flutter / Dart, `injectable` + `build_runner`, mockito, `bloc_test`, Pillow para el atlas.

## Restricciones globales

- Commits `[PROJECT-X]: <Imperative description in English>`, sin atribución a IA; el fichero de instrucciones del proyecto se añade con su propio `git add`.
- `dart format --line-length 120` solo sobre lo escrito (nunca `di.config.dart` ni `*.mocks.dart`); `dart run build_runner build --delete-conflicting-outputs` tras cambiar DI o `@GenerateMocks`.
- Tests: `testWhen<Action>Then<Result>`, `// given` / `// when` / `// then`, datos en `test/mocks/**` (nada inline salvo `PositionEntity(x:, y:)`), textos por `Internationalize`.
- Cada tarea termina con `flutter analyze` sin avisos y `flutter test` en verde.
- La arena y `balance_test.dart` no cambian y siguen en verde.

## Decisiones

- **Rocas:** `LevelLocalDatasourceImpl` cambia `_pickaxe` por `static const PointDBO _rockFreeSpot = PointDBO(x: _spawnX + 212, y: _spawnY + 212)` y `_rockItemClearance` por `_rockFreeSpotClearance = 80`, así las 12 rocas salen iguales. *No está en la ficha del usuario*: se decide para no cambiar el mapa más de lo pedido.
- **Decoración:** `_isClear` solo mira las rocas (`_rockDecorationClearance` 48). Fuera `_campDecorationClearance`.
- **Construcción:** `Construction.rejection` queda: sitio fuera del mapa, sobre un obstáculo o sobre el jugador → `blocked`; ya no hay objetos ni planos no construibles.
- **Migración:** `toCurrent` pasa a `3 → dbo`, `2 → _fromVersionTwo(dbo)`, `1 → _fromVersionTwo(_fromVersionOne(dbo))`, otra → `InvalidSaveException`. `_fromVersionOne` deja la versión 2 como hasta ahora; `_fromVersionTwo` quita los edificios con `blueprint` `camp`, añade `'pickaxe'` a `player.inventory.tools` si no está (si no hay inventario, crea uno con el pico) y pone `version: 3`. Los objetos del suelo se olvidan solos: `SaveDBO.fromJson` ya no lee `items`.
- **Textos:** fuera `forest.blueprint.camp`, `forest.message.pickedUpAxe` / `pickedUpAxeTouch` / `pickedUpPickaxe` / `pickedUpPickaxeTouch`, `error.unknownItemKindTitle` / `unknownItemKindMessage`. La bienvenida no cambia ("Tala árboles para reunir madera y construir tu aldea.").
- **`BlueprintId`:** queda `{ house, forge, armory, mageTower, workshop }`. El guardado usa el nombre, así que quitar un valor de en medio no rompe nada.

## Tarea 1: fuera el campamento y los edificios del nivel

**Archivos:**
- Modificar: `blueprint_id.dart`, `blueprints.dart`, `blueprint_entity.dart` (fuera `isBuildable`), `construction.dart`, `get_build_options_use_case.dart`, `level_dbo.dart`, `level_local_datasource_impl.dart`, `level_mapper_dbo.dart`, `sprite_names.dart`, `render_constants.dart`, `internationalize.dart`, `es.json`, `build_assets.py`, `forest.png` / `forest.json` (regenerados), `CREDITS.md`.
- Borrar: `building_dbo.dart`, `building_mapper_dbo.dart`, sus tests y `building_dbo_mock.dart`.
- Tests: `blueprints_test.dart`, `blueprint_entity_test.dart`, `world_construction_test.dart`, `can_place_building_use_case_test.dart`, `get_build_options_use_case_test.dart`, `level_local_datasource_impl_test.dart`, `level_mapper_dbo_test.dart`, `level_repository_impl_test.dart`, `forest_scene_component_test.dart`, `building_component_test.dart`, `forest_bloc_village_test.dart`, los mocks que usan el campamento (`blueprint_entity_mock.dart`, `building_entity_mock.dart`, `level_dbo_mock.dart`, `level_scenario_mock.dart`…).

```dart
static const List<BlueprintEntity> all = [house, workshop, forge, armory, mageTower];
```

- [x] **Paso 1:** tests: `Blueprints.all` son los cinco planos construibles; el nivel ya no trae edificios (`World.buildings` vacío); la decoración del nivel tiene 94 piezas (vuelve `decoration-78`). Fallan.
- [x] **Paso 2:** quitar `camp` del catálogo y del enum, `isBuildable` y sus dos usos, `LevelDBO.buildings`, `BuildingDBO`, `BuildingMapperDBO`, `_camp` y `_campDecorationClearance`; los `switch` de `SpriteNames`, `RenderConstants` e `Internationalize` y `forest.blueprint.camp`.
- [x] **Paso 3:** `build_assets.py` sin `build_camp`, `CAMP_*` ni el frame; `cd asset-packs/lpc && python3 build_assets.py`; `CREDITS.md` sin la línea del campamento.
- [x] **Paso 4:** borrar y adaptar tests y mocks; `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`, formatear, commit `[PROJECT-X]: Remove the camp`.

## Tarea 2: empezar con el pico; fuera los objetos del suelo

**Archivos:**
- Modificar: `level_mapper_dbo.dart`, `level_dbo.dart`, `level_local_datasource_impl.dart`, `world.dart`, `world_state.dart`, `construction.dart`, `rules.dart` (fuera `pickUpRange`), `game_event_entity.dart`, `stats_recording.dart`, `world_snapshot_entity.dart`, `get_world_snapshot_use_case.dart`, `app_exceptions.dart`, `save_dbo.dart`, `save_mapper_dbo.dart`, `save_migration_mapper_dbo.dart`, `forest_bloc.dart`, `forest_effect.dart`, `forest_scene_component.dart`, `sprite_names.dart`, `internationalize.dart`, `es.json`, `build_assets.py`, `forest.png` / `forest.json`, `CREDITS.md`.
- Borrar: `ground_item_entity.dart`, `pick_up_items.dart`, `item_dbo.dart`, `ground_item_mapper_dbo.dart`, `save_item_dbo.dart`, `save_ground_item_mapper_dbo.dart`, `ground_item_component.dart`, sus tests (`world_items_test.dart`…) y mocks (`ground_item_entity_mock.dart`, `item_dbo_mock.dart`, `save_item_dbo_mock.dart`).

```dart
inventory: const InventoryEntity(tools: {ToolKind.axe, ToolKind.pickaxe}),
```

- [x] **Paso 1:** tests: `testWhenTheLevelIsMappedThenThePlayerHoldsTheAxeAndThePickaxe`, que se puede picar una roca nada más empezar y que la decoración (95 piezas, vuelve `decoration-105`) y las rocas del nivel salen como se decidió. Fallan.
- [x] **Paso 2:** el pico en el inventario inicial; fuera el sistema de objetos del suelo en dominio, nivel, guardado (`SaveDBO.items` y su mapper) y escena; `_rockFreeSpot`.
- [x] **Paso 3:** `ForestBloc` sin el caso `ItemPickedUpEventEntity` en `_isWorthSaving` ni en `_react`; textos fuera de `Internationalize` y `es.json`.
- [x] **Paso 4:** `build_assets.py` sin los frames `axe-pickup` y `pickaxe-pickup` ni sus constantes; regenerar el atlas; `CREDITS.md` sin el párrafo de los objetos.
- [x] **Paso 5:** borrar y adaptar tests y mocks; `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`, formatear, commit `[PROJECT-X]: Start with the pickaxe and remove ground items`.

## Tarea 3: guardado versión 3 con migración

**Archivos:** `save_dbo.dart` (`currentVersion = 3`), `save_migration_mapper_dbo.dart`, `save_dbo_mock.dart`, `save_json_mock.dart`, `save_migration_mapper_dbo_test.dart`, `game_save_repository_impl_test.dart`.

```dart
SaveDBO toCurrent(SaveDBO dbo) => switch (dbo.version) {
  SaveDBO.currentVersion => dbo,
  2 => _fromVersionTwo(dbo),
  1 => _fromVersionTwo(_fromVersionOne(dbo)),
  _ => throw InvalidSaveException(data: 'unknown version ${dbo.version}'),
};
```

- [x] **Paso 1:** tests: `testWhenAVersionTwoSaveIsMigratedThenTheCampIsRemoved`, `…ThenThePickaxeJoinsTheTools`, `…ThenToolLevelsAreKept`, `…ThenItBecomesVersionThree`, `testWhenAVersionTwoSaveHasNoInventoryThenItGetsThePickaxe`, `testWhenAVersionOneSaveIsMigratedThenItBecomesTheVersionThreeGame`, `testWhenAVersionThreeSaveIsMigratedThenItIsUnchanged`, la versión desconocida pasa a ser la 4; y `GameSaveRepositoryImpl.load` con un JSON de la versión 2 que tiene campamento y pico en el suelo. Fallan.
- [x] **Paso 2:** `_fromVersionTwo` y `currentVersion = 3`.
- [x] **Paso 3:** `flutter analyze`, `flutter test`, `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart`, formatear, commit `[PROJECT-X]: Migrate older saves to the clean start`.

## Tarea 4: documentación y cierre

- [x] Fichero de instrucciones del proyecto: el campamento, los edificios del nivel, el pico en el suelo, los objetos del suelo, `isBuildable`, el orden de `Construction.rejection` y el guardado v3 con su migración.
- [x] `docs/GAME_DESIGN.md`, si los menciona; nota en `F5-stone.md`.
- [x] Batería final: `build_runner` + `git diff --exit-code`, `flutter analyze`, `flutter test`, golden en Chrome.
- [x] `README.md` de los extras y `PROGRESS.md`: fila de la mejora ✅ en `develop` con los tests y *Siguiente paso*. Casillas de este plan marcadas. Commit `[PROJECT-X]: Close the clean start improvement`.
