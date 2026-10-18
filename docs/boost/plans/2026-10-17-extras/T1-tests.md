# T1 · Tests — ficha

> **Plan detallado: abajo** (*Plan de implementación*). Commits `[PROJECT-T1]: …`.

| | |
|---|---|
| **Rama** | `feature/PROJECT-T1-tests`, desde `develop` con todo lo anterior unido |
| **Depende de** | Todo lo demás: C9–C12, los arreglos y mejoras, F1, F3–F8 y F2. Va **la última**. |

> **Hecho (2026-10-18):** el periodo sin tests ha terminado. Las fases vuelven a escribir sus tests (TDD) y a pasar la batería completa (`flutter test` y Chrome) antes de cerrarse. Final de T1: 1206 tests en la VM, 260 en Chrome.

## Objetivo

Desde el 2026-10-17 (a mitad de C9, tras TC9.3) el desarrollo sigue **sin tests**: ni se escriben tests nuevos ni se arreglan los que se rompan por un cambio. Lo decidió el usuario, igual que se hizo en la versión iOS. T1 deja la batería entera en verde al final.

## Qué hace

- **Arreglar** los tests existentes que hayan dejado de compilar o de pasar (firmas nuevas, catálogos con maná, misiones, recursos, etc.).
- **Escribir** los tests de lo que se hizo sin ellos. Cada plan o ficha implementado sin tests lleva su sección *Para T1* con lo que hay que cubrir; esta fase los recoge todos.
- Volver a medir los umbrales del HUD con el test de `hud_overlay_test.dart` (fuente Roboto) si han cambiado los recursos o los botones.
- Comprobar las cifras exactas que ya están en los planes: goldens de combate y tablas de equilibrado (`balance_test.dart`).
- Mantener las convenciones de `CLAUDE.md` (nombres `testWhen…Then…`, *given/when/then*, mocks centralizados).

## Hecho cuando

`build_runner` sin cambios, `flutter analyze` sin avisos (incluido `test/`), `flutter test` y los tests en Chrome en verde.

## Para T1 (se va rellenando)

- **C9** (TC9.1–TC9.3 sí tienen tests; TC9.4 no, y rompe la compilación de estos tests porque `arenaReward(amount:)` pasa a `arenaReward(amounts:)`). El código exacto está en la tarea TC9.4 de [C9-mana.md](../2026-10-06-hero-arena/C9-mana.md):
  - `test/mocks/domain/world/funds_mock.dart`: `barbarianChiefReward`, `barbarianChiefRepeatReward`, `thirtyGold`, `tenGoldAndZeroMana`, `sixManaBeforeTwentyFiveGold`;
  - `test/mocks/presentation/features/arena/arena_result_data_mock.dart`: `amounts:` con `FundsMock`, y renombrar a `championWithTheChiefReward` / `victoryWithTheChiefRepeatReward`;
  - `test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`: `amounts:` con `FundsMock`;
  - `test/core/assets/i18n/internationalize_test.dart`: `arenaReward` con `+75 de oro, 20 de maná`, `+10 de oro`, `+25 de oro, 6 de maná` y sin cantidades 0;
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`, `arena_page_test.dart` y `widgets/result_panel_test.dart`: los nombres nuevos y los textos con maná.
- **C10** (sin tests; rompe la compilación de estos). Detalle en la sección *Para T1* de [C10-no-skip.md](../2026-10-06-hero-arena/C10-no-skip.md):
  - `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`: quitar `ArenaReplaySkipped` (varios tests), rehacerlos con `ArenaReplayTicked` hasta el final; test nuevo de que se emiten los efectos de todos los turnos, `FightEndedEffect` y `ChampionEffect`;
  - `test/layers/presentation/features/arena/models/fight_replay_data_test.dart`: borrar el test de `skipped()`;
  - `test/mocks/presentation/features/arena/arena_data_mock.dart`: `.skipped()` por `.advanced(durationMs)`;
  - `widgets/fight_button_test.dart` y `widgets/arena_hud_test.dart`: sin `onSkip` ni `Internationalize.arenaSkip`; sin botón durante la repetición y *Empezar pelea* al acabar;
  - `arena_page_test.dart`: quitar lo que use el salto; `internationalize_test.dart`: sin `arena.skip`.
- **C11** (sin tests; rompe la compilación de estos y puede cambiar resultados). Detalle, semillas y cifras en la sección *Para T1* de [C11-enemy-skills.md](../2026-10-06-hero-arena/C11-enemy-skills.md):
  - `test/mocks/presentation/features/arena/arena_effect_mock.dart`: `SkillUsedEffect` con `side` e `index` (héroe: `FightSide.hero, 0`) y variantes de enemigo; arregla la compilación de `arena_bloc_test.dart`;
  - revisar resultados de los tests que pelean con los niveles reales 6–10: `arena_flow_test.dart`, `start_fight_use_case_test.dart` (jefe), `arena_bloc_test.dart` (`banditTrio`, `wolfPack`, `barbarianChief`);
  - `arena_levels_test.dart`: `enemySkillChance` 0 en 1–5 y 0,015 / 0,02 / 0,025 / 0,03 / 0,035 en 6–10; `arena_level_entity_test.dart`: valor por defecto, `copyWith`, `==`, `hashCode`; mocks de nivel con probabilidad;
  - `enemy_kind_rules_test.dart` (nuevo): habilidades de cada `EnemyKind`;
  - `combat_test.dart`: goldens de los niveles 6–10 (semillas 0, 25, 1, 8 y 1), probabilidad 0 da el registro de antes, *Segundo aliento* del jefe una sola vez, `adviceFor` sin los `dodge` del héroe;
  - `balance_test.dart`: sigue en verde con las probabilidades; añadir ≥ 60 % con las semillas 0–999 (89,0/86,6, 73,0/75,1, 78,0/71,9, 79,0/74,0, 64,0/60,8 %);
  - `arena_bloc_test.dart`: `SkillUsedEffect` de enemigo (bando e índice); `arena_scene_component_test.dart`: el nombre flota sobre el enemigo.
- **C12** (sin tests; rompe la compilación de muchos tests del héroe y de las habilidades). Detalle, goldens y cifras en la sección *Para T1* de [C12-skill-levels.md](../2026-10-06-hero-arena/C12-skill-levels.md):
  - `HeroEntity(skills:)` → `skillLevels:` en `hero_entity_mock.dart`, `balance_scenario_mock.dart` y `hero_entity_test.dart`; `Combat.resolve(skills:)` → `skillLevels:` en `combat_test.dart` y `balance_test.dart` (su `_spentOn` suma `costOf` de cada nivel);
  - `SkillEntity(cost:)` → `costs:` (`skill_entity_mock.dart`, `skill_entity_test.dart`, `skills_test.dart`: costes por nivel); `SkillOptionEntity` con `level` y sin `SkillOptionState.known` (`skill_option_entity_mock.dart`, `skill_option_entity_test.dart`: `nextLevel`/`nextCost`, `get_skill_options_use_case_test.dart`: `maxed`);
  - `LearnSkillResult` sin `alreadyKnown`, con `upgraded`/`maxed`: `learn_skill_use_case_test.dart` (aprender, mejorar, máximo, sin recursos, sin torre, en ese orden), `skill_flow_test.dart`, `forest_bloc_skill_test.dart` (*snackbar* "Has mejorado" y `SkillLearnedEffect`);
  - `hero_rules_test.dart`: `levelOf`, `skills`, `withSkill` (asserts 0 y 4) y `power` con niveles (99 / 178 / 118 / 211; jefe 133 / 155 / 178);
  - `combat_test.dart`: goldens de nivel 2 y 3 (*Bárbaro* semilla 0: 6 / 7 / 8 de daño en el turno 5; *Manada* semilla 0: 3 / 5 / 5 esquivas; *Jefe* semilla 0, héroe 3/3: cura de 21 a 51 / 59 / 66 en el turno 16) y el nivel 1 igual al registro de antes;
  - `balance_test.dart`: techo ≤ 95 % con las habilidades en nivel 3 (semillas 0–99 y 0–999);
  - `Internationalize.forestSkillDescription(id:, level:)`, claves nuevas y sin `skillAlreadyKnown`: `internationalize_test.dart`, `skill_item_data_mock.dart`, `hero_panel_data_mock.dart`, `skill_tile_test.dart` (Nv 2/3, *Aprender*/*Mejorar*/*Máximo*), `hero_panel_test.dart`, `hud_overlay_test.dart`, `forest_page_test.dart`.
- **C13** (sin tests; rompe la compilación de un test y cambia el resultado de los del bloc de la arena). Detalle en la sección *Para T1* de [C13-hero-armour.md](../2026-10-06-hero-arena/C13-hero-armour.md):
  - `arena_sprite_names_test.dart`: `heroWith(weapon)` → `heroWith(weapon, armor)`; los 16 juegos (4 armas × `workClothes`/`leatherArmor`/`chainMail`/`plateArmor`, y `null`) existen en `arena.json` con sus 17 frames y tienen nombres distintos; `hero-steel-sword-plate`, `hero-leather`; con `workClothes` o `null`, los nombres de antes;
  - `fighter_render_data_mock.dart`: `armor: GearId.workClothes` en los mocks del héroe (`heroIdle`, `heroWithSteelSwordIdle`, `heroAfterBeatingTheRookie`, `heroSwinging`), que arregla `arena_bloc_test.dart` y `ArenaDataMock`; mock nuevo `heroInPlateIdle`;
  - `armor` en `==`/`hashCode` de `FighterRenderData`; `arena_frames_test.dart`: `hero-steel-sword-plate-idle-0`; `arena_bloc_test.dart`: con `armorTier: 2` el héroe lleva `GearId.chainMail` en la vista previa y la repetición y los enemigos `null`;
  - `ArenaAssetsMock`: frames de los juegos con armadura si algún test pinta un héroe con ella.
- **Empezar con el hacha** (sin tests; rompe y cambia varios). Detalle en la sección *Para T1* de [start-with-axe.md](start-with-axe.md): los escenarios y mocks que empezaban sin hacha (`ForestScenarioMock.axeNextToPlayer`, `GameScenarioMock`, mocks de nivel/DBO con el objeto del hacha), `quests_test` / `quest_log_test` (`QuestId.pickUpAxe` ya no existe; 11 → 10 misiones, la aldea pasa a 2), `forest_bloc_test` (bienvenida nueva, aviso de recogida) e `internationalize_test` (clave `pickUpAxe`).
- **F1** (sin tests; rompe la compilación de varios y cambia el total de madera). Detalle en la sección *Para T1* y los pasos de test de [F1-tree-kinds.md](../2026-10-04-game-design/F1-tree-kinds.md): `Rules.treeKindStats` y `TreeStatsEntity`, el *mapper* con madera y golpes por tipo (`di_test.dart` 388 → 411), `Rules.hitsToFellTree` eliminado, `TreeFelledEffect.wood` y el "+N" flotante de la escena.
- **F3** (sin tests; rompe la compilación de dos mocks). Detalle y goldens en la sección *Para T1* de [F3-regrowth.md](../2026-10-04-game-design/F3-regrowth.md):
  - `WorldSnapshotEntity` con `stumps` obligatorio: `world_snapshot_entity_mock.dart` y `forest_data_mock.dart`; `architecture_test.dart`: `world/regrowth.dart` en `_worldInternals`;
  - `StumpEntityMock` (`fresh`, `almostSapling`, `sapling`, `ready`); `stump_entity_test.dart` y `stump_rules_test.dart` (`isSapling` en 60 000, `grown` limitado a 180 000);
  - `world_regrowth_test.dart` (ticks de 50 ms): pino `tree-37` talado en 5500 brota en 65 500 y vuelve en 185 500; `elapsedMs` 0 en el tick de la tala; espera con el jugador a < 20 (a 22 no); una casa a < 52 borra el tocón; los tocones no bloquean ni el paso ni `canPlace`; el árbol que vuelve sale el último;
  - `forest_bloc_test.dart`: `TreeSproutedEffect` / `TreeRegrownEffect` sin *snackbar*; `growth_motion_test.dart`; `stump_component_test.dart` (50 × 41, 18 × 30, crecimiento 0,35 → 1 en 600 ms); `forest_scene_component_test.dart` (reconcilia tocones y brotes por id, la tala ya no añade decoración); `lpc_atlas_test.dart`: frame `sapling`.
- **F4** (sin tests; cambia el resultado de los de misiones y del panel). Detalle en la sección *Para T1* de [F4-quests-chapter-1.md](../2026-10-04-game-design/F4-quests-chapter-1.md):
  - `architecture_test.dart`: `world/stats_recording.dart` en `_worldInternals`;
  - `StatsEntityMock`; `stats_entity_test.dart`, `stats_rules_test.dart` y `stats_recording_test.dart` (talados, por tipo desde el tocón, edificios terminados, rebrotados; en el mismo tick que el evento); `building_rules_test.dart`: `completeCount`;
  - `quests_test.dart` / `quest_log_test.dart`: 10 → 15 misiones, aldea 2 → 7, las cinco nuevas en su orden y fuera de orden, `gatherFortyWood` pegajosa;
  - `forest_bloc_test.dart`: insignia `x/15`, recorte por línea (plegada "N hechas", la actual, dos pendientes), aviso de línea completa con la séptima de la aldea; `hud_data_mock.dart` / `quest_item_data_mock.dart` con menos filas;
  - `quest_row_test.dart`: fila plegada; `internationalize_test.dart`: los cinco títulos y el plural "1 hecha" / "3 hechas".
- **F5** (sin tests; rompe la compilación de los tests del bosque y cambia los del nivel, los costes y el HUD). Detalle en la sección *Para T1* de [F5-stone.md](../2026-10-04-game-design/F5-stone.md):
  - compilación: `ForestBloc(mineRockUseCase:)`, `WorldSnapshotEntity(rocks:)` (`world_snapshot_entity_mock.dart`, `forest_data_mock.dart`), `LevelMapperDBO(rockMapperDBO:)`; `di_test.dart` con `MineRockUseCase` y `RockMapperDBO`; `architecture_test.dart`: `world/mining.dart` en `_worldInternals`;
  - dominio: `RockEntityMock`; `rock_entity_test.dart`, `rock_rules_test.dart`, `world_mining_test.dart` (`unknownRock` antes que `noPickaxe`, un golpe cada 750 ms, `RockBroken` con 8 en el octavo, la roca deja de ser obstáculo, volver a tocarla reinicia), `world_regrowth_test.dart` (tocón a 33 de una roca no rebrota, a 35 sí), `mine_rock_use_case_test.dart`; costes con 10 de piedra en Herrería, Armería y Torre (`blueprints_test.dart`, opciones de construcción y los flujos del héroe que las construyen); `balance_test.dart` sin cambios;
  - datos: `level_local_datasource_impl_test.dart` (12 rocas, golden `rock-1` (303.66, 1110.24), `rock-2` (1333.10, 464.67), `rock-3` (385.68, 823.07); 94 decoraciones sin los ids 6, 12, 17, 30, 34, 37, 40, 42, 49, 68, 81, 85 y 105; `items` = el pico en (1012, 812); invariantes), goldens de decoración VM y Chrome, `rock_mapper_dbo_test.dart`;
  - presentación: `forest_bloc_test.dart` (avisos de pico y piedra con ratón y táctil, `RockHitEffect` / `RockBrokenEffect`, pose `pickaxe`, edificio → roca → árbol, `HudData` con cuatro recursos y dos herramientas), `rockAt` y reconciliación de rocas en la escena, `rock_component_test.dart`, `rock_motion_test.dart`, `particle_bursts_test.dart` (`stoneChips`), `player_frames_test.dart`, `LpcAssetsMock`, `lpc_atlas_test.dart`, `custom_icons_test.dart`, `internationalize_test.dart`, `hud_overlay_test.dart` (`buttonsBelowWidth` 1260 y `narrowWidth` 770).
- **F6** (sin tests; rompe la compilación de los tests del bosque y del nivel y cambia los de pagos, misiones y HUD). Detalle en la sección *Para T1* de [F6-storehouse.md](../2026-10-04-game-design/F6-storehouse.md):
  - compilación: `ForestBloc(depositUseCase:, getStockUseCase:)`, `HudData(stock:, carry:)` sin `resources` (`hud_data_mock.dart`, `forest_data_mock.dart`), `ResourceBar(stock:, carry:)`, `WorldState(buildings:)`, `LevelMapperDBO(buildingMapperDBO:)`; `di_test.dart` con `DepositUseCase`, `GetStockUseCase` y `BuildingMapperDBO`; `architecture_test.dart`: `world/depositing.dart` en `_worldInternals`;
  - dominio: `resource_rules_test.dart`, carga en `inventory_rules_test.dart` (`load`, `freeLoad`, `isLoadFull`, `cargo`, `adding`, `unloading`); `world_deposit_test.dart` (capacidad, lo que no cabe se pierde, `carryFull`, `unknownBuilding` / `notADropOff` / `emptyLoad` / `ok`, entregar en el campamento y en un almacén, 400 ms, oro y maná fuera de la carga); `world_funds_test.dart` contra `world.stock` (`earn`, `spend`, `funds`); `Construction` paga del almacén y no coloca el campamento; `blueprints_test.dart` (almacén segundo, campamento último), `building_rules_test.dart` (`acceptsDeposits`), `stats_recording_test.dart`; `quests_test.dart` (`gatherWood` y `gatherFortyWood` miden el almacén); `get_build_options_use_case_test.dart` (sin el campamento, lo que falta contra el almacén), `deposit_use_case_test.dart`, `get_stock_use_case_test.dart`; los flujos y escenarios que construyen o compran ponen los recursos en el almacén; `balance_test.dart` sin cambios;
  - datos: `level_local_datasource_impl_test.dart` (el campamento en (700, 592); 93 decoraciones, falta además la 78; goldens de decoración VM y Chrome), `building_mapper_dbo_test.dart` (sin id, sin posición, blueprint desconocido → `InvalidLevelException`, terminado), `==` de `LevelDBO` con `buildings`;
  - presentación: `forest_bloc_test.dart` (avisos de carga llena al tocar y al llenarse, entregar / carga vacía / reanudar / andar al tocar un edificio, "Guardado en el almacén: …", `HudData.stock` y `carry`, pose quieta al entregar), `building_component_test.dart` (nace terminado sin barra), `resource_bar_test.dart` (rótulo "Almacén", carga en color de aviso), `hud_overlay_test.dart` (`buttonsBelowWidth` 1460 y `narrowWidth` 960), `lpc_atlas_test.dart` (`camp`, `storehouse`), `internationalize_test.dart` (siete claves nuevas y dos textos de misión).
- **F7** (sin tests; rompe la compilación de los tests de colocación y cambia los de entregas y picado). Detalle en la sección *Para T1* de [F7-quarry.md](../2026-10-04-game-design/F7-quarry.md):
  - compilación: `PlacementData(invalidReason:)` sin `isValid` ni `copyWith` (`placement_data_mock.dart`, `placement_data_test.dart`, `forest_data_mock.dart`, `forest_bloc_mock.dart`), `PlacementBar(reason:)`, `CanPlaceBuildingUseCase` → `ConstructionRejection?`, `World.placementRejection` en lugar de `canPlace`, `BlueprintEntity(accepts:)` sin `isDropOff`, `InventoryRules.unloading(accepted)`, `Work.intervalMs(state, intent)`;
  - dominio: `placement_rule_rules_test.dart` (a 61, 62, 119,9 y 120 de la roca, sin rocas, roca rota) y `==` de `PlacementRuleEntity`; `construction_test.dart` / `world_construction_test.dart` (orden de los rechazos, `notEnoughResources` antes que la regla, `needsNearbyRock` sin cobrar); `blueprints_test.dart` (cantera tercera, 25 de madera, `accepts` de cada plano), `blueprint_entity_test.dart` (`==` con `accepts` y `placementRule`), `building_rules_test.dart` (`acceptsDeposits` con `accepts` vacío, `boostsMining`); `inventory_rules_test.dart` (`cargoFor`, `unloading(accepted)`); `world_deposit_test.dart` (la cantera solo recibe piedra, con solo madera `emptyLoad`, a medio hacer `notADropOff`); `world_mining_test.dart` (525 ms con una cantera terminada a < 160 de la roca, 750 lejos o a medio hacer, `workProgress`; talar, construir y entregar sin cambios); `can_place_building_use_case_test.dart` (`null` / el motivo), `get_build_options_use_case_test.dart` (cantera tercera);
  - presentación: `forest_bloc_test.dart` (`invalidReason` al mover, `blocked` al abrir, tocar con `needsNearbyRock` avisa y sigue colocando), `placement_bar_test.dart` (rótulo del motivo, oculto y fuera de la semántica sin motivo, misma altura), `lpc_atlas_test.dart` (`quarry`), `internationalize_test.dart` (`forest.blueprint.quarry`, `forest.placement.needsRock`, `forestPlacementRejection` de cada motivo).
- **F8** (sin tests; rompe la compilación de los tests del bosque y cambia los de misiones, golpes y HUD). Detalle en la sección *Para T1* de [F8-workshop.md](../2026-10-04-game-design/F8-workshop.md):
  - compilación: `ForestBloc(getUpgradeOptionsUseCase:, buyUpgradeUseCase:)`, `HudData(upgradeItems:)` (`hud_data_mock.dart`, `forest_data_mock.dart`), `HudOverlay(onUpgradeSelected:)`; `di_test.dart` con `BuyUpgradeUseCase` y `GetUpgradeOptionsUseCase`;
  - dominio: `inventory_rules_test.dart` (`toolLevel`, `withToolLevel`, `hitsNeeded` 1→1 … 9→6, todas las operaciones conservan `toolLevels`), `==` de `InventoryEntity` con `toolLevels`; `world_woodcutting_test.dart` / `world_mining_test.dart` (nivel 1 sin cambios; pino 3 → 2, roble 7 → 5, roca 8 → 5; árbol a medias cae con los golpes nuevos; intervalos iguales); `upgrades_test.dart`, `upgrade_entity_test.dart`, `upgrade_option_entity_test.dart`; `blueprints_test.dart` y `get_build_options_use_case_test.dart` (taller cuarto, 20 de madera y 10 de piedra); `buy_upgrade_use_case_test.dart` (`alreadyOwned` → `noWorkshop` → `notEnoughResources` sin cobrar → `ok` del almacén); `get_upgrade_options_use_case_test.dart`; `quests_test.dart` / `quest_log_test.dart` (15 → 19, aldea 7 → 11, las cuatro nuevas al final); `balance_test.dart` sin cambios;
  - presentación: `forest_bloc_test.dart` (avisos de cada `UpgradeResult`, `UpgradePurchasedEffect` solo con `ok`, `upgradeItems` por estado, "Hacha de hierro" en la barra, insignia `x/19`); `upgrade_menu_test.dart` / `upgrade_option_tile_test.dart`; `hud_overlay_test.dart` (botón *Taller* tercero, comprar no cierra el panel, `buttonsBelowWidth` 1700 y `narrowWidth` 1100); `lpc_atlas_test.dart` (`workshop`), `custom_icons_test.dart` (`workshop`), `internationalize_test.dart` (taller, grupo `forest.upgrade`, dos avisos y cuatro misiones).
- **F2** (sin tests; rompe la compilación de los tests del bosque, de la sesión y de DI, y borra un `.mocks.dart` al regenerar). Detalle en la sección *Para T1* de [F2-autosave.md](../2026-10-04-game-design/F2-autosave.md):
  - compilación: `ForestBloc(saveGameUseCase:, newGameUseCase:)` (`forest_bloc_test.dart`, `forest_bloc_mock.dart`, `forest_page_test.dart`), `StartGameUseCase(saveRepository:)`, `HudOverlay(onSaveRequested:, onNewGameRequested:)`, `GameSessionRepositoryImpl()` sin datasource (`game_session_repository_impl_test.dart` + `.mocks.dart` regenerado), borrar `game_session_local_datasource_impl_test.dart`; `di_test.dart` con `await locator.init`, `SharedPreferences.setMockInitialValues`, el datasource, el repositorio, los doce `Save*MapperDBO` y los dos casos de uso nuevos, `GameSessionRepository` *singleton*; `container_app_test.dart` / `forest_page_test.dart` / `arena_page_test.dart` si llaman a `configureDependencies`;
  - dominio: `World.restore` (todo el estado y la numeración de ids), `QuestLog(completed:)` / `completed`, `Upgrades.maxLevel`, `save_game_use_case_test.dart`, `new_game_use_case_test.dart`, `start_game_use_case_test.dart` (guardado primero), `MockGameSaveRepository`;
  - datos: ida y vuelta `GameSessionEntity` → `SaveDBO` → JSON → `GameSessionEntity` con un mundo que tenga de todo; cada `Save*MapperDBO` y cada validación (versión, JSON roto, enums, negativos, carga, tiers, niveles de habilidad, `hitsTaken`, `hitsDone`, recorte de `toolLevels`, sin ceros); cada DBO (`fromJson(toJson())`, `==`); el datasource con `SharedPreferences.setMockInitialValues`; `GameSaveRepositoryImpl` (`load` → `null` y registra, `save` / `clear` lanzan); `GameSessionRepositoryImpl`;
  - presentación: `forest_bloc_test.dart` (guarda tras los eventos importantes, a los 10 000 ms, con `ForestPaused`, tras compras con éxito y al volver de la arena; *Guardar* avisa o enseña el pop-up; *Nueva partida* `InProgress` → `Success` con el nivel), `game_panel_test.dart`, `hud_overlay_test.dart` (sexto botón *Partida*, `buttonsBelowWidth` 1820, `narrowWidth` 1100), `forest_page_test.dart` (ciclo de vida, juego nuevo), `forest_scene_component_test.dart` (sin decoración bajo edificios cargados), `custom_icons_test.dart` (`save`), `internationalize_test.dart` (`forest.hud.game`, `forest.game`, `error.invalidSave*`).

---

# T1 · Tests — plan de implementación

> **Para agentes:** `boost:executing-plans` (tarea a tarea, un commit por tarea). Los pasos usan casillas (`- [ ]`).

**Objetivo:** la batería entera en verde y sin avisos, con los tests que pide cada *Para T1* de C9–C13, F1–F8, F2 y *Empezar con el hacha*.

**Arquitectura:** primero que todo compile (mocks centralizados, firmas nuevas, `.mocks.dart` regenerados); después cada área en orden de dependencia (dominio → datos → casos de uso → presentación → Flame → textos/iconos/atlas → Chrome). Cada test se ajusta al comportamiento ACTUAL de `lib/`, y las cifras de los *Para T1* son la especificación: si el código no las da, se investiga (iOS en `/Users/axelperezgaspar/farming-ios`, solo lectura) y se anota en *Discrepancias* antes de tocar nada.

**Stack:** `flutter_test`, `mockito` (`@GenerateMocks`), `bloc_test`, `flame_test` (`testWithFlameGame`), `shared_preferences` (`setMockInitialValues`).

## Restricciones globales

- Nombres `testWhen<Acción>Then<Resultado>`; `// given`, `// when`, `// then`; `test/` refleja `lib/`.
- Datos de prueba como `static` en `test/mocks/**/<nombre>_mock.dart`; nunca entidades, modelos de vista, efectos, poses, excepciones ni DBO en línea (solo `PositionEntity(x:, y:)` como argumento o valor esperado).
- Textos de la app desde `Internationalize`; solo `internationalize_test.dart` escribe las cadenas en español. Etiquetas arbitrarias en `test/mocks/presentation/widgets/widget_text_mock.dart`.
- Tests de widget y página: `loadSpanishTranslations` y `pumpUntil`; las páginas, `rootBundle.clear()` en `setUp`; las medidas del HUD, `loadRobotoFont`.
- `*.mocks.dart` y `di.config.dart` solo con `dart run build_runner build --delete-conflicting-outputs`; nunca a mano ni con `dart format`. El resto, `dart format --line-length 120`.
- `lib/` no se toca salvo fallo real, en su propio commit `[PROJECT-T1]: Fix <fallo>`.
- Commits `[PROJECT-T1]: <inglés imperativo>`, sin atribución de IA.

## Tareas

| Tarea | Qué | Depende de |
|---|---|---|
| TT1.1 | Compilación: mocks, firmas, `.mocks.dart`, `architecture_test` | — |
| TT1.2 | Combate y equilibrado (C11, C12) | TT1.1 |
| TT1.3 | Héroe, habilidades y arena en el dominio (C9, C11, C12) | TT1.1 |
| TT1.4 | Árboles, tocones, estadísticas y misiones (F1, F3, F4, hacha) | TT1.1 |
| TT1.5 | Piedra, almacén, cantera y taller en el dominio (F5–F8) | TT1.4 |
| TT1.6 | Datos del nivel y goldens (F1, F5, F6) | TT1.1 |
| TT1.7 | Guardado (F2): dominio, casos de uso y datos | TT1.5, TT1.6 |
| TT1.8 | Casos de uso del bosque y flujos | TT1.5 |
| TT1.9 | Arena en la presentación (C9–C13) | TT1.3 |
| TT1.10 | `ForestBloc` (F1–F8, F2, C12, hacha) | TT1.8 |
| TT1.11 | Widgets del HUD y umbrales | TT1.10 |
| TT1.12 | Componentes Flame del bosque | TT1.1 |
| TT1.13 | Textos, iconos, atlas y DI | TT1.1 |
| TT1.14 | Páginas, contenedor y Chrome | todas |

### TT1.1: que la batería compile ✅

**Archivos:** los 51 de `flutter analyze` (mocks en `test/mocks/**`, tests que construyen `ForestBloc`, `HudData`, `PlacementData`, `WorldSnapshotEntity`, `SkillEntity`, `HeroEntity`…), `test/architecture_test.dart`; borrar `test/layers/data/datasources/session/local/game_session_local_datasource_impl_test.dart`.

- [x] `FundsMock` (C9): `barbarianChiefReward` (50 oro + 16 maná), `barbarianChiefRepeatReward`, `thirtyGold`, `tenGoldAndZeroMana`, `sixManaBeforeTwentyFiveGold`; `ArenaResultDataMock` y `ArenaLevelItemDataMock` con `amounts:`; renombrar a `championWithTheChiefReward` / `victoryWithTheChiefRepeatReward`.
- [x] C10: `ArenaDataMock` con `.advanced(durationMs)`; quitar `ArenaReplaySkipped`, `onSkip` y `arenaSkip` de los tests.
- [x] C11: `ArenaEffectMock` con `side: FightSide.hero, index: 0` y una variante de enemigo.
- [x] C12: `skillLevels:` en `HeroEntityMock`, `BalanceScenarioMock`, `hero_entity_test`, `combat_test`, `balance_test`; `SkillEntity(costs:)`; `SkillOptionEntity(level:)` sin `known`; `LearnSkillResult` sin `alreadyKnown`; `forestSkillDescription(id:, level:)`; `SkillItemData(level:)`.
- [x] C13: `heroWith(weapon, armor)`; `armor: GearId.workClothes` en los mocks del héroe de `FighterRenderDataMock`.
- [x] Hacha: sin `QuestId.pickUpAxe` en los mocks.
- [x] F1: `TreeEntityMock.mock.hitsToFell` por `Rules.hitsToFellTree`; `TreeFelledEffect(wood:)`.
- [x] F3/F5: `WorldSnapshotEntity(stumps:, rocks:)`; `LevelMapperDBO(rockMapperDBO:, buildingMapperDBO:)`.
- [x] F6: `HudData(stock:, carry:)`, `ResourceBar(stock:, carry:)`, `ForestBloc(depositUseCase:, getStockUseCase:)`.
- [x] F7: `PlacementData(invalidReason:)`, `PlacementBar(reason:)`, `CanPlaceBuildingUseCase` → `ConstructionRejection?`.
- [x] F8/F2: `ForestBloc(getUpgradeOptionsUseCase:, buyUpgradeUseCase:, saveGameUseCase:, newGameUseCase:)`, `HudData(upgradeItems:)`, `HudOverlay(onUpgradeSelected:, onSaveRequested:, onNewGameRequested:)`, `StartGameUseCase(saveRepository:)`, `GameSessionRepositoryImpl()`, `MockGameSaveRepository`.
- [x] `architecture_test.dart`: `regrowth.dart`, `stats_recording.dart`, `mining.dart`, `depositing.dart` en `_worldInternals`.
- [x] `dart run build_runner build --delete-conflicting-outputs`; `flutter analyze` → "No issues found!"; commit.

### TT1.2: combate y equilibrado ✅

**Archivos:** `test/layers/domain/combat/combat_test.dart`, `balance_test.dart`, `test/mocks/domain/game/balance_scenario_mock.dart`, `test/mocks/domain/entities/combat/arena_level_entity_mock.dart`.

- [x] Los goldens anteriores pasan con `skillLevels` en nivel 1 y los niveles de mock sin probabilidad.
- [x] C11 (héroe esperado de `BalanceScenarioMock`, niveles reales): *Tres bandidos* s0 turno 11 héroe → enemigo 1 `dodge`, 0, vida 26, 27 turnos, victoria; *Bárbaro* s25 turno 7 enemigo 0 → héroe `doubleStrike` 5, vida 32, 18 turnos, victoria; *Manada* s1 turno 4 enemigo 2 `doubleStrike` 4, vida 41, 22 turnos, victoria; *Dos bárbaros* s8 turno 18 enemigo 1 `doubleStrike` 6, vida 5, 23 turnos, derrota `almostThere`; *Jefe* s1 turno 4 enemigo 2 `doubleStrike` 1, vida 63, turno 24 enemigo 0 `secondWind` vida 44, 31 turnos, derrota `needDefense`. Con `enemySkillChance: 0`, el registro de antes. El jefe cura una sola vez. `adviceFor` sin los `dodge` del héroe.
- [x] C12: *Bárbaro* s0 solo *Golpe doble* turno 5 daño 6/7/8, vida 34/33/32, 17/15/15 turnos; *Manada* s0 solo *Esquiva* 3/5/5 esquivas (nivel 1 y 2 derrota `almostThere` en 23 y 24 turnos, primera en el turno 6 contra el enemigo 1; nivel 3 victoria en 25, primera en el turno 1, enemigo 0, vida 55); *Jefe* s0 héroe (3, 3) solo *Segundo aliento* turno 16 de 21 a 51/59/66, nivel 1 derrota `almostThere` en 46, 2 y 3 victoria en 49.
- [x] `balance_test`: `_spentOn` suma `costOf` de cada nivel; ≥ 60 % con semillas 0–999 (89,0/86,6, 73,0/75,1, 78,0/71,9, 79,0/74,0, 64,0/60,8 % en 6–10); con las habilidades en nivel 3 ≤ 95 % (0–99 y 0–999) y un paso por detrás < 50 %.
- [x] `flutter test test/layers/domain/combat`; commit.

### TT1.3: héroe, habilidades y arena en el dominio ✅

**Archivos:** `hero_entity_test`, `hero_rules_test`, `skills_test`, `skill_entity_test`, `skill_option_entity_test`, `arena_levels_test`, `arena_level_entity_test`, nuevo `test/layers/domain/world/extensions/enemy_kind_rules_test.dart`, `learn_skill_use_case_test`, `get_skill_options_use_case_test`, `start_fight_use_case_test`, `arena_flow_test`, `skill_flow_test`, `world_funds_test`.

- [x] `hero_rules_test`: `levelOf`, `skills`, `withSkill` (asserts 0 y 4), `power` 99 / 178 / 118 / 211 y jefe 133 / 155 / 178.
- [x] `skills_test`: `maxLevel` 3, costes por nivel, `costOf(1)` = coste de antes; `skill_option_entity_test`: `nextLevel` / `nextCost`, `canLearn`, `assert`.
- [x] `learn_skill_use_case_test`: `ok` (nivel 1), `upgraded` (90 / 30 y 135 / 45 del *Golpe doble*), `maxed` sin cobrar, `notEnoughResources`, sin torre `missingBuilding` aunque esté al máximo, al máximo `maxed` sin recursos; `get_skill_options_use_case_test`: `level`, `maxed`, `missing`.
- [x] `arena_levels_test`: `enemySkillChance` 0 en 1–5, 0,015 / 0,02 / 0,025 / 0,03 / 0,035 en 6–10; `arena_level_entity_test`; `enemy_kind_rules_test`.
- [x] `world_funds_test` contra `world.stock`; resultados de `start_fight_use_case_test` y `arena_flow_test` con los niveles reales.
- [x] `flutter test test/layers/domain`; commit.

### TT1.4: árboles, tocones, estadísticas y misiones ✅

**Archivos:** `tree_stats_entity_test`, `rules_test`, `stump_entity_test`, `stump_rules_test`, `world_regrowth_test`, `stats_entity_test`, `stats_rules_test`, `stats_recording_test`, `building_rules_test`, `quests_test`, `quest_log_test`, `world_chopping_test`, `game_flow_test`, mocks `StumpEntityMock`, `StatsEntityMock`.

- [x] F1: `Rules.treeKindStats`, `TreeStatsEntity`.
- [x] F3: `isSapling` en 60 000, `grown` hasta 180 000; `tree-37` talado en 5500 brota en 65 500 y vuelve en 185 500 (ticks de 50 ms); `elapsedMs` 0 en el tick de la tala; jugador a < 20 espera, a 22 no; casa a < 52 borra el tocón; los tocones no bloquean; el árbol vuelve el último.
- [x] F4: estadísticas en el mismo tick; `completeCount`.
- [x] Misiones (hacha, F4, F8): 19 misiones, aldea 11, las nuevas en su orden y fuera de orden, `gatherFortyWood` y `gatherTwentyStone` pegajosas, `gatherWood` / `gatherFortyWood` miden el almacén.
- [x] `flutter test test/layers/domain`; commit.

### TT1.5: piedra, almacén, cantera y taller en el dominio ✅

**Archivos:** `rock_entity_test`, `rock_rules_test`, `world_mining_test`, `resource_rules_test`, `inventory_rules_test`, `inventory_entity_test`, `world_deposit_test`, `construction_test` / `world_construction_test`, `blueprints_test`, `blueprint_entity_test`, `placement_rule_rules_test`, `placement_rule_entity_test`, `upgrades_test`, `upgrade_entity_test`, `upgrade_option_entity_test`, `world_woodcutting_test`; mocks `RockEntityMock`, `InventoryEntityMock`, `BuildingEntityMock`, `UpgradeEntityMock`.

- [x] F5: `unknownRock` antes que `noPickaxe`, un golpe cada 750 ms, `RockBroken(stone: 8)` en el octavo, la roca deja de ser obstáculo, volver a tocarla reinicia; tocón a 33 de una roca no rebrota, a 35 sí; costes con 10 de piedra.
- [x] F6: carga (`load`, `freeLoad`, `isLoadFull`, `cargo`, `adding`, `unloading`), capacidad 10, lo que no cabe se pierde, `carryFull`, `orderDeposit` (`unknownBuilding` / `notADropOff` / `emptyLoad` / `ok`), 400 ms, campamento y almacén, oro y maná fuera; `Construction` paga del almacén; blueprints (almacén segundo, campamento último).
- [x] F7: regla a 61, 62, 119,9 y 120; orden de rechazos; cantera tercera con 25 de madera; solo piedra; 525 ms a < 160.
- [x] F8: `toolLevel`, `withToolLevel`, `hitsNeeded` 1→1 … 9→6; pino 3 → 2, roble 7 → 5, roca 8 → 5; taller cuarto (20 madera, 10 piedra); `Upgrades.maxLevel` 2.
- [x] `flutter test test/layers/domain`; commit.

### TT1.6: datos del nivel y goldens ✅

**Archivos:** `level_local_datasource_impl_test`, `tree_mapper_dbo_test`, `rock_mapper_dbo_test`, `building_mapper_dbo_test`, `level_mapper_dbo_test`, `level_repository_impl_test`, `test/core/utils`, `di_test` (madera 411), mocks de DBO.

- [x] 70 árboles, madera por tipo (411 en el mundo); 12 rocas (`rock-1` (303.66, 1110.24), `rock-2` (1333.10, 464.67), `rock-3` (385.68, 823.07)); 93 decoraciones sin los ids 6, 12, 17, 30, 34, 37, 40, 42, 49, 68, 78, 81, 85 y 105; `items` = el pico en (1012, 812); campamento en (700, 592); invariantes.
- [x] Mappers: sin id, sin posición, blueprint desconocido → `InvalidLevelException`, terminado; `==` de `LevelDBO`.
- [x] VM y `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart`; commit.

### TT1.7: guardado (F2) ✅

**Archivos:** `world_restore_test`, `quest_log_test`, `save_game_use_case_test`, `new_game_use_case_test`, `start_game_use_case_test`, `test/layers/data/datasources/save/**`, `test/layers/data/repositories/save/**`, `game_session_repository_impl_test`; mocks `SaveDBOMock`, `GameSessionEntityMock`, `SaveJsonMock`.

- [x] `World.restore` (todo el estado y la numeración de ids); `QuestLog(completed:)`.
- [x] Ida y vuelta entidad → DBO → JSON → entidad; cada `Save*MapperDBO` y cada validación; cada DBO (`fromJson(toJson())`, `==`); datasource; `GameSaveRepositoryImpl` (`load` → `null` y registra; `save` / `clear` lanzan); `GameSessionRepositoryImpl`.
- [x] `flutter test test/layers`; commit.

### TT1.8: casos de uso del bosque y flujos ✅

**Archivos:** `mine_rock_use_case_test`, `deposit_use_case_test`, `get_stock_use_case_test`, `can_place_building_use_case_test`, `get_build_options_use_case_test`, `buy_upgrade_use_case_test`, `get_upgrade_options_use_case_test`, `get_world_snapshot_use_case_test`, `buy_gear_use_case_test`, flujos; `ForestScenarioMock`, `GameScenarioMock`.

- [x] `buy_upgrade`: `alreadyOwned` → `noWorkshop` → `notEnoughResources` sin cobrar → `ok` del almacén.
- [x] Opciones: sin el campamento; almacén, cantera, taller; lo que falta contra el almacén.
- [x] Los escenarios ponen los recursos en el almacén.
- [x] `flutter test test/layers/domain`; commit.

### TT1.9: arena en la presentación ✅

**Archivos:** `arena_bloc_test`, `fight_replay_data_test`, `fight_button_test`, `arena_hud_test`, `result_panel_test`, `arena_sprite_names_test`, `arena_frames_test`, `fighter_render_data_test`, `arena_scene_component_test`, mocks de la arena.

- [x] C10: la repetición con `ArenaReplayTicked` hasta el final emite todos los efectos, `FightEndedEffect` y `ChampionEffect`; sin botón durante la repetición.
- [x] C11: `SkillUsedEffect` de enemigo con bando e índice; el nombre flota sobre el enemigo.
- [x] C13: 16 juegos con 17 frames, nombres distintos, `hero-steel-sword-plate`, `hero-leather`; `armorTier: 2` → `GearId.chainMail`, enemigos `null`; `heroInPlateIdle` → `hero-steel-sword-plate-idle-0`.
- [x] `flutter test test/layers/presentation/features/arena`; commit.

### TT1.10: `ForestBloc` ✅

**Archivos:** `forest_bloc_test`, `forest_bloc_skill_test`, `forest_bloc_mock`, mocks de `HudData`, `QuestItemData`, `ForestEffect`.

- [x] Hacha: bienvenida nueva. F1: "+N". F3: `TreeSproutedEffect` / `TreeRegrownEffect` sin aviso. F4: insignia, recorte por línea, aviso de línea completa. F5: avisos de pico y piedra, `RockHit` / `RockBroken`, pose `pickaxe`, edificio → roca → árbol. F6: carga llena, entregar, "Guardado en el almacén: …". F7: `invalidReason`. F8: `UpgradeResult`, `upgradeItems`, "Hacha de hierro", `x/19`. C12: "Has mejorado", `maxed`. F2: autoguardado (eventos, 10 000 ms, `ForestPaused`, compras, arena), *Guardar*, *Nueva partida*.
- [x] `flutter test test/layers/presentation/features/forest/bloc`; commit.

### TT1.11: widgets del HUD y umbrales ✅

**Archivos:** `hud_overlay_test`, `resource_bar_test`, `placement_bar_test`, `placement_data_test`, `quest_row_test`, `skill_tile_test`, `hero_panel_test`, `upgrade_menu_test`, `upgrade_option_tile_test`, `game_panel_test`.

- [x] `buttonsBelowWidth` 1820 (1819 / 1820) y `narrowWidth` 1100 con `loadRobotoFont`; seis botones; *Taller* y *Partida*.
- [x] Carga en color de aviso; rótulo "Almacén"; barra con motivo y misma altura; fila plegada; Nv 2/3 y *Aprender* / *Mejorar* / *Máximo*.
- [x] `flutter test test/layers/presentation/features/forest/widgets`; commit.

### TT1.12: componentes Flame del bosque ✅

**Archivos:** `growth_motion_test`, `stump_component_test`, `rock_component_test`, `rock_motion_test`, `particle_bursts_test`, `player_frames_test`, `building_component_test`, `floating_text_component_test`, `forest_scene_component_test`, `forest_world_test`, `LpcAssetsMock`.

- [x] Crecimiento 0,35 → 1 en 600 ms; tocón 50 × 41, brote 18 × 30; roca 61 × 45 y 350 ms; `stoneChips` 8; campamento terminado sin barra; reconciliación de tocones, brotes y rocas; `rockAt`; "+N"; sin decoración bajo edificios cargados.
- [x] `flutter test test/layers/presentation/features/forest/game`; commit.

### TT1.13: textos, iconos, atlas y DI ✅

**Archivos:** `internationalize_test`, `custom_icons_test`, `lpc_atlas_test`, `di_test`.

- [x] Todas las claves nuevas de C9–F2 y sin `arena.skip`, `skillAlreadyKnown`, `pickUpAxe`; iconos `workshop`, `save`; frames `sapling`, `camp`, `storehouse`, `quarry`, `workshop`; DI con `await locator.init`, `SharedPreferences.setMockInitialValues` y `GameSessionRepository` *singleton*.
- [x] `flutter test test/core`; commit.

### TT1.14: páginas, contenedor y Chrome ✅

**Archivos:** `forest_page_test`, `arena_page_test`, `container_app_test`.

- [x] Ciclo de vida (`ForestPaused` con `hidden` / `paused`), `ForestGame` nuevo tras *Nueva partida*.
- [x] `build_runner` + `git diff --exit-code`, `flutter analyze`, `flutter test`, Chrome; commit.

## Discrepancias

Ninguna cifra de los *Para T1* contradice al código: goldens de combate (C11, C12), tablas de equilibrado, poderes, rebrote de `tree-37` (5500 / 65 500 / 185 500), rocas, 93 decoraciones, 411 de madera, umbrales del HUD (1820 / 1100) y número de misiones (19, aldea 11) salen exactos. Notas:

- El golden de `tree-37` exige ir antes a donde estaba el hacha (856, 608), como el programa de iOS; con el hacha en la mano el jugador sale de (800, 600) (`LevelScenarioMock.oldAxeSpot`).
- `HeroEntityMock.champion` pasa de 12 a 13 peleas: con las habilidades de los enemigos (C11) la semilla 12 pierde contra el jefe.
- `SaveScenarioMock` usa árboles de mock con cifras que no son las de `Rules`; el guardado los reconstruye con `Rules.treeKindStats`, así que la ida y vuelta exacta usa `SaveRoundTripMock`.
- `game_save_repository_impl_test.dart` va con `@TestOn('vm')`: lee `es.json` con `dart:io` y no hay goldens en él.
- Se añade `shared_preferences_platform_interface` a `dev_dependencies` para `InMemorySharedPreferencesAsync` (`test/helpers/in_memory_preferences.dart`).
- Sin fallos en `lib/`.
