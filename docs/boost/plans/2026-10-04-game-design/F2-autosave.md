# F2 · Guardado de la partida — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 3: va la última) |
| **Rama** | `feature/PROJECT-F2-autosave`, desde `feature/PROJECT-X-town` (arena C0–C13, "empezar con el hacha", F1, F3, F4, F5, F6, F7 y F8) |
| **Depende de** | F8 (taller, `InventoryEntity.toolLevels`, 19 misiones). Decidido el 2026-10-17, como en iOS. |
| **Issue / milestone** | `phase:F2` · milestone `F2 Autosave` |
| **Referencia iOS** | Ninguna implementación: en iOS solo hay ficha (`$IOS/docs/plans/2026-10-12-village/F2-autosave.md`) y las secciones *Para F2* de sus planes C12, F3–F8. Este plan sale de la ficha Flutter y del código tras F8. |

**Goal:** Que la partida sobreviva a cerrar la app o la pestaña: se guarda sola (tras los eventos importantes, cada 10 s de juego y al pasar a segundo plano), con un botón *Guardar*, y se puede empezar una *Nueva partida* desde el menú *Partida*.

**Architecture:** Dominio: `World.restore(...)` reconstruye el agregado con todo su estado (`WorldState` gana tocones, estadísticas, almacén y contadores de ids en su constructor y sigue dentro de `domain/world/`), `QuestLog(completed:)` + `completed`, `Upgrades.maxLevel`, `Rules.autosaveIntervalMs`, el repositorio `GameSaveRepository` (`load` / `save` / `clear`, síncrono) y los casos de uso `SaveGameUseCase` y `NewGameUseCase`; `StartGameUseCase` carga primero el guardado. Datos: `shared_preferences` con `SharedPreferencesWithCache` creada una vez en un módulo de DI con `@preResolve`; `data/datasources/save/` guarda un `SaveDBO` (versión 1) con un DBO por pieza y JSON escrito a mano; `data/repositories/save/` con `GameSaveRepositoryImpl` y un `Save*MapperDBO` por pieza, que validan y convierten. **La sesión viva pasa al repositorio:** `GameSessionRepositoryImpl` es el `@LazySingleton` que guarda el `GameSessionEntity` y desaparece el datasource en memoria `data/datasources/session/` (los datasources solo ven DBOs). Presentación: `ForestBloc` guarda (eventos importantes, 10 s, `ForestPaused`, al volver de la arena, *Guardar*) y empieza de nuevo (`ForestNewGameRequested`); `ForestPage` escucha el ciclo de vida con `AppLifecycleListener` y crea un `ForestGame` nuevo al empezar de nuevo; el sexto botón *Partida* abre `GamePanel` con *Guardar* y *Nueva partida* (confirmación en el panel).

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`, `easy_localization`, `injectable`. **Dependencia nueva:** `shared_preferences` (Android, iOS y web), en su propio commit.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*. La única excepción es medir los umbrales del HUD con un test de widget de usar y tirar en el *scratchpad* (no se guarda; ya hecho al escribir este plan, decisión 14).
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Si la tarea cambia DI (TF2.3, TF2.4): `dart run build_runner build --delete-conflicting-outputs` y se commitea `di.config.dart` tal cual (nunca se formatea); si `build_runner` reescribe algún `test/**/*.mocks.dart`, se deshace con `git checkout -- test` (no se toca `test/`). TF2.1 y la última tarea: `flutter build web` y `flutter build apk --debug` terminan bien (plugin nuevo).
- **Determinismo:** F2 no añade ni reordena ninguna tirada de `SeededRandom`, no toca el nivel ni el combate. Una partida cargada sigue igual que la guardada: mismos ids, mismo orden de árboles (los rebrotados al final) y mismos contadores.
- `World`, `WorldState`, `Work` y los sistemas solo se tocan dentro de `domain/world/`. El guardado lee la API pública de `World` (getters) y restaura con `World.restore`.
- Los datasources solo ven DBOs (decisión del usuario): nada de entidades en `data/datasources/**`.
- Casos nuevos de enum **al final**: `HudMenu.game`; `ForestPaused`, `ForestSaveRequested` y `ForestNewGameRequested`, al final de `ForestEvent`. `switch` exhaustivos en el orden de declaración.
- Textos solo en `es.json`, leídos por `Internationalize`; ninguno de los textos nuevos dice cómo interactuar, así que no llevan variante `…Touch`.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-F2]: <frase en inglés en imperativo>`; el commit, en un comando aparte del `git add`.

## Decisiones

Las de la ficha (que se conservan abajo, en *Ficha original*) más las que salen del código tras F8 y de la decisión del usuario del 2026-10-17 sobre la sesión:

1. **Sesión en el repositorio:** `GameSessionRepositoryImpl` pasa a `@LazySingleton(as: GameSessionRepository)` y guarda el `GameSessionEntity?` vivo en un campo; `current()` lanza `NoGameInProgressException` si no hay. Se borran `data/datasources/session/` (fuente e implementación). La interfaz `GameSessionRepository` no cambia (`current()`, `save(session)`), así que ningún caso de uso cambia por esto. Ya no inyecta `AppExceptionHandler`: el único error posible ya es una `AppException`.
2. **`GameSaveRepository`** (`domain/repositories/save/game_save_repository.dart`): `GameSessionEntity? load()`, `void save(GameSessionEntity session)`, `void clear()`. `load` **nunca lanza**: un guardado ausente, roto, de otra versión o fuera de rango devuelve `null` y se registra con `Logger.error` (el mensaje sale de `AppExceptionHandler`). `save` y `clear` registran y relanzan la excepción convertida por `AppExceptionHandler` (fallos síncronos, p. ej. al serializar).
3. **Restaurar el mundo:** `World.restore({width, height, player, trees, stumps, rocks, items, decorations, buildings, hero, stats, stock, idCounters})`. `WorldState` recibe en su constructor `stumps`, `stats`, `stock` e `idCounters` (opcionales, con los valores de antes por defecto) y expone `idCounters` (sin modificar); `World.idCounters` lo publica. La actividad del jugador **no** se guarda: al cargar está quieto (`IdleActivityEntity`), y el trabajo a medias se retoma tocando otra vez (una obra conserva su progreso).
4. **Qué se guarda** (versión 1, todo de una vez): tamaño del mundo; árboles (`id`, `kind`, `x`, `y`, `hitsTaken`; madera, golpes y radio vuelven de `Rules.treeKindStats` / `Rules.treeTrunkRadius`, como hace el nivel) en el orden de `World.trees`; tocones (`id`, `kind`, `x`, `y`, `elapsedMs`); rocas (`id`, `x`, `y`, `hitsTaken`; radio, piedra y golpes de `Rules`); objetos del suelo (`id`, `kind`, `x`, `y`); **decoraciones** (`id`, `kind`, `x`, `y`: la ficha no las nombra, pero `World` las necesita y así el guardado no depende de volver a generar el nivel); edificios (`id`, `blueprint`, `x`, `y`, `hitsDone`; el campamento, la cantera y el taller como cualquiera); contadores de ids; estadísticas; almacén (`resources`, `tools`, `toolLevels` del `InventoryEntity`); jugador (`x`, `y` y su inventario: carga, herramientas y `toolLevels`; velocidad y radio de `Rules`); héroe (`weaponTier`, `armorTier`, `skillLevels`, `clearedLevels`, `fightsFought`); misiones completadas (nombres de `QuestId`, en el orden del enum). Los enums se guardan por su `name` de Dart (`asNameMap()` al leer).
5. **Validar al cargar** (en los `Save*MapperDBO`; cualquier fallo lanza `InvalidSaveException` y el repositorio devuelve `null`):
   - versión distinta de `SaveDBO.currentVersion` (1), JSON roto o de otro tipo (lo lanza `jsonDecode` / el `as` del DBO);
   - falta el tamaño (o ≤ 0), el jugador, un id o una coordenada;
   - un nombre de enum desconocido (árbol, decoración, objeto, plano, recurso, herramienta, habilidad, nivel de arena, misión);
   - cantidades < 0 (recursos, contadores, estadísticas, `fightsFought`, `elapsedMs`);
   - la carga del jugador por encima de `Rules.carryCapacity`;
   - tiers del equipo fuera de `0..Gear.maxTier(slot)`;
   - niveles de habilidad fuera de `1..SkillEntity.maxLevel` (el `assert` de `HeroEntity` no tiene tope);
   - `hitsTaken` de un árbol o una roca fuera de `0 ≤ golpes < hitsToFell / hitsToBreak` (con `==` ya estaría talado o roto y no seguiría en el mundo; con el hacha o el pico de hierro cae antes, así que nunca se guarda con más);
   - `hitsDone` de un edificio fuera de `0..hitsToBuild`;
   - un nivel de herramienta por debajo de 1 es inválido (`withToolLevel` lanza) y uno sin mejora en el catálogo se recorta a `Upgrades.maxLevel(tool)` (nuevo: el nivel más alto de `Upgrades.all` para esa herramienta, 1 si no hay);
   - una cantera guardada se queda aunque su roca ya esté rota (la regla de colocación no se vuelve a comprobar).
   Los recursos se cargan con `InventoryRules.add`, que no guarda ceros. Un campo ausente que tiene valor por defecto en la entidad (golpes, progreso, héroe, estadísticas, inventario) toma ese valor.
6. **`InvalidSaveException`** (`core/error-handling/exceptions/app_exceptions.dart`, `data` = el motivo en inglés), con textos `error.invalidSaveTitle` "Partida guardada no válida" y `error.invalidSaveMessage` "La partida guardada no es válida: {reason}". No se enseña al jugador (se registra); los textos existen porque toda `AppException` los tiene.
7. **Almacenamiento:** `StorageModule` (`core/config/di/storage_module.dart`, `@module`) con `@singleton @preResolve Future<SharedPreferencesWithCache> get preferences` (`SharedPreferencesWithCacheOptions()` sin lista de claves); `configureDependencies` pasa a `await locator.init(environment: environment)`. `GameSaveLocalDatasourceImpl` (`@LazySingleton`) lee la clave `farming.save` síncronamente de la caché y escribe *fire-and-forget* (`unawaited`, con `catchError` que registra con `Logger`).
8. **DBOs** en `data/datasources/save/local/dbo/`: `SaveDBO` (`currentVersion = 1`) y `SaveTreeDBO`, `SaveStumpDBO`, `SaveRockDBO`, `SaveItemDBO`, `SaveDecorationDBO`, `SaveBuildingDBO`, `SavePlayerDBO`, `SaveInventoryDBO`, `SaveHeroDBO`, `SaveStatsDBO`; todos los campos anulables, `fromJson` / `toJson` a mano, `==` / `hashCode` / `toString` como los DBOs del nivel. Las lecturas comunes (`double` desde `num`, mapas de enteros, listas) van en funciones de `save_json.dart`. Prefijo `Save` para no chocar con los DBOs y *mappers* del nivel.
9. **Mappers** en `data/repositories/save/mappers/`, uno por pieza, `@Injectable()`, con `toDBO(entidad)` y `toEntity(dbo)`: `SavePositionMapperDBO` (coordenadas obligatorias), `SaveTreeMapperDBO`, `SaveStumpMapperDBO`, `SaveRockMapperDBO`, `SaveGroundItemMapperDBO`, `SaveDecorationMapperDBO`, `SaveBuildingMapperDBO`, `SaveInventoryMapperDBO`, `SavePlayerMapperDBO`, `SaveHeroMapperDBO`, `SaveStatsMapperDBO` y `SaveMapperDBO` (la partida entera: versión, tamaño, contadores, misiones).
10. **Casos de uso:** `SaveGameUseCase.call()` guarda `GameSessionRepository.current()`; `NewGameUseCase.call()` borra el guardado y deja en la sesión un mundo nuevo del nivel con un `QuestLog()` vacío (no guarda: lo hará el siguiente autoguardado); `StartGameUseCase.call()` usa el guardado si `load()` devuelve uno y, si no, el nivel.
11. **Cuándo guarda `ForestBloc`** (`SaveGameUseCase`):
    - en el tick, si llega alguno de estos eventos: `TreeFelledEventEntity`, `BuildingCompletedEventEntity`, `ItemPickedUpEventEntity`, `QuestCompletedEventEntity`, `RockBrokenEventEntity`, `DepositedEventEntity` (un solo guardado por tick, tras procesarlos);
    - cada `Rules.autosaveIntervalMs = 10000` ms de juego, sumando los `deltaMs` de `ForestTicked` (el contador vuelve a 0 con cualquier guardado);
    - al comprar equipo (`ok`), aprender o subir una habilidad (`ok` / `upgraded`) y comprar una mejora (`ok`);
    - al volver de la arena: `_onArenaRequested` espera el `Future` de `NavigationService.push(const ArenaPage())` y guarda (la pelea ya está cobrada); el manejador queda pendiente sin bloquear los ticks porque `on<ForestEvent>` usa el transformador concurrente por defecto;
    - con `ForestPaused`.
    Un autoguardado que falla no avisa (ya lo registra el repositorio). Solo se guarda en `ForestSuccess`.
12. ***Guardar*** (`ForestSaveRequested`): guarda, pone el contador a 0 y avisa `forest.game.saved` "Partida guardada"; si `SaveGameUseCase` lanza, pop-up de error con `NavigationService.showErrorPopUp` (título y mensaje de la excepción, botón `common.accept`). ***Nueva partida*** (`ForestNewGameRequested`): `ForestInProgress` → `NewGameUseCase` → reinicia el estado del bloc (saludo, colocación, orientación, última posición, contador) → `ForestSuccess`; si falla, pop-up y `ForestFailure` como al arrancar (*Reintentar* lanza `ForestStarted`, que ya no encuentra guardado y carga el nivel).
13. **Segundo plano:** `_ForestViewState` crea un `AppLifecycleListener(onPause:, onHide:)` en `initState` (lo libera en `dispose`) que añade `ForestPaused`. En la web, Flutter pasa a `hidden` con el `visibilitychange` de la pestaña, así que el mismo `onHide` cubre recargar o cerrar la pestaña (no hace falta `package:web`).
14. **Menú *Partida*:** `HudMenu.game` (al final); **sexto** botón *Partida*, **el último** (tras *Arena*), con el icono nuevo `save.svg` (`CustomIcons.save`, un disquete 22 × 22). Abre `GamePanel` (`widgets/game_panel.dart`, `StatefulWidget`, 260–340 px como el de mejoras) con el título "PARTIDA" (mayúsculas y estilo del título de *Mejoras*), *Guardar* (`GamePanel.saveKey`) y *Nueva partida* (`GamePanel.newGameKey`); *Nueva partida* cambia el panel a la confirmación "Se perderá la partida actual. ¿Empezar de nuevo?" con *Empezar* (`GamePanel.confirmKey`) y *Cancelar* (`GamePanel.cancelKey`, vuelve a las dos acciones). *Guardar* y *Empezar* cierran el panel; `HudOverlay` gana `onSaveRequested` y `onNewGameRequested`.
15. **Umbrales del HUD**, medidos con Roboto (test de usar y tirar en el *scratchpad* con `test/helpers/roboto_font.dart`, el de F8 con un sexto `HudButton` "Partida" con icono): la barra con nombres sigue en **1042,1** px (sin nombres 548,5), los seis botones miden **714,7** (593,9 con cinco). En una línea: 12 + 1042,1 + 8 + 714,7 + 12 = 1788,8, más la holgura de 24 = 1812,8 → **`buttonsBelowWidth = 1820`** (antes 1700). `narrowWidth` sigue en **1100** (la barra no cambia). A 640 px (móvil apaisado) la fila de seis botones (738,7 con márgenes) ya no cabe entera y el `FittedBox` que ya la envuelve la encoge al ~83 %; la barra sin nombres sí cabe.
16. **Escena al cargar:** los edificios terminados ya nacen sin barra (F6), y tocones y brotes sin animación de crecer (solo crecen con su efecto); el estado inicial no lleva efectos. Lo único nuevo: `ForestSceneComponent._build` quita la decoración de debajo de los edificios que ya existen (antes solo lo hacía `BuildingPlacedEffect`). **Nueva partida:** `_ForestView` escucha con un `BlocListener` el paso de `ForestSuccess` a `ForestInProgress` y crea un `ForestGame` nuevo (como *Reintentar* tras un fallo del arte), así la escena no arrastra edificios ni decoraciones de la partida anterior.
17. **Textos:** `forest.hud.game` "Partida", `forest.game.save` "Guardar", `forest.game.saved` "Partida guardada", `forest.game.newGame` "Nueva partida", `forest.game.newGameConfirm` "Se perderá la partida actual. ¿Empezar de nuevo?", `forest.game.confirm` "Empezar", `forest.game.cancel` "Cancelar"; `error.invalidSaveTitle` / `error.invalidSaveMessage` (decisión 6).
18. **`CLAUDE.md`:** se borra E5; E6 pasa a "los repositorios leen solo datasources locales (el nivel y el guardado; sin remoto ni cache-first)"; E7 añade el almacenamiento (`config/di/storage_module.dart` con `shared_preferences`); el *Layout* de `data` y `core` y la descripción del repositorio de sesión y del flujo de guardado y carga.

### Desvíos respecto a la ficha

- Se guardan también las decoraciones y el tamaño del mundo (decisión 4).
- La sesión viva vive en `GameSessionRepositoryImpl` y desaparece `data/datasources/session/` (decisión del usuario, decisión 1); por eso E5 se borra en vez de reescribirse.
- La comprobación de versión la hace `SaveMapperDBO` (el datasource solo lee y escribe JSON).
- `hitsTaken` de árboles y rocas: `0 ≤ golpes < total` (decisión 5); la ficha decía "entre 0 y sus golpes".
- No hay excepción propia para un fallo al guardar: el pop-up usa la que devuelve `AppExceptionHandler` (`GenericException` si no es una `AppException`), porque la ficha no trae textos para eso.
- *Partida* es el sexto botón y el último; a 640 px la fila se encoge (decisión 15).

## Reparto

| Tarea | Qué |
|---|---|
| TF2.1 | Dependencia `shared_preferences` (commit propio) |
| TF2.2 | Dominio: restaurar el mundo y las misiones, `Upgrades.maxLevel`, `Rules.autosaveIntervalMs`, `GameSaveRepository` |
| TF2.3 | Datos del guardado: módulo de almacenamiento, excepción, DBOs, datasource, *mappers* y repositorio (DI) |
| TF2.4 | La sesión en el repositorio y los casos de uso de guardar, empezar de nuevo y cargar (DI) |
| TF2.5 | Autoguardado en `ForestBloc`, ciclo de vida en `ForestPage` y la escena al cargar |
| TF2.6 | El menú *Partida*: icono, textos, `GamePanel`, sexto botón y umbrales |
| TF2.7 | Cierre: T1, `PROGRESS.md`, README, `CLAUDE.md` |

---

### Task TF2.1: Dependencia `shared_preferences`

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock` (y lo que `flutter pub add` regenere y esté versionado).

- [ ] **Step 1:** `flutter pub add shared_preferences` (restricción con `^`, la última estable). Comprobar que `pubspec.yaml` la lista en `dependencies` con `^`.
- [ ] **Step 2: Verificar:** `flutter analyze lib` → `No issues found!`; `flutter build web --release --base-href /phaser-example/ --dart-define-from-file=lib/core/config/env/production_environment.json` y `flutter build apk --debug` terminan bien.
- [ ] **Step 3: Commit** — `git add pubspec.yaml pubspec.lock` (y los ficheros generados versionados que cambien); en otro comando `git commit -m "[PROJECT-F2]: Add the shared_preferences dependency"`.

---

### Task TF2.2: Dominio — restaurar el mundo y las misiones

**Files:**
- Modify: `lib/layers/domain/world/world_state.dart`, `lib/layers/domain/world/world.dart`, `lib/layers/domain/quests/quest_log.dart`, `lib/layers/domain/rules/upgrades.dart`, `lib/layers/domain/rules/rules.dart`
- Create: `lib/layers/domain/repositories/save/game_save_repository.dart`

**Interfaces:**
- Consumes: `WorldState`, `StumpEntity`, `StatsEntity`, `InventoryEntity`, `UpgradeEntity`.
- Produces: `World.restore({required double width, required double height, required PlayerEntity player, required List<TreeEntity> trees, required List<StumpEntity> stumps, required List<RockEntity> rocks, required List<GroundItemEntity> items, required List<DecorationEntity> decorations, required List<BuildingEntity> buildings, required HeroEntity hero, required StatsEntity stats, required InventoryEntity stock, required Map<String, int> idCounters})`; `Map<String, int> World.idCounters`; `QuestLog({List<Quest>? quests, Set<QuestId> completed = const {}})` y `Set<QuestId> QuestLog.completed`; `int Upgrades.maxLevel(ToolKind tool)`; `Rules.autosaveIntervalMs == 10000`; `GameSaveRepository { GameSessionEntity? load(); void save(GameSessionEntity session); void clear(); }`.

- [ ] **Step 1: `WorldState`** — constructor con el estado restaurable y los contadores públicos (solo lectura):

```diff
     required List<BuildingEntity> buildings,
     this.hero = const HeroEntity(),
+    List<StumpEntity> stumps = const [],
+    this.stats = const StatsEntity(),
+    this.stock = const InventoryEntity(),
+    Map<String, int> idCounters = const {},
   }) : assert(width > 0 && height > 0),
        trees = {for (final tree in trees) tree.id: tree},
        items = {for (final item in items) item.id: item},
        rocks = {for (final rock in rocks) rock.id: rock},
        buildings = {for (final building in buildings) building.id: building},
+       stumps = {for (final stump in stumps) stump.id: stump},
+       _idCounters = {...idCounters},
        decorations = List.unmodifiable(decorations);
```

```diff
-  final Map<String, StumpEntity> stumps = {};
-  StatsEntity stats = const StatsEntity();
-  InventoryEntity stock = const InventoryEntity();
-  final Map<String, int> _idCounters = {};
+  final Map<String, StumpEntity> stumps;
+  StatsEntity stats;
+  InventoryEntity stock;
+  final Map<String, int> _idCounters;
+
+  Map<String, int> get idCounters => Map.unmodifiable(_idCounters);
```

- [ ] **Step 2: `World.restore`** — detrás del constructor normal (imports nuevos: `stats_entity.dart` ya está; añadir ninguno más, todos los tipos ya se importan):

```dart
  World.restore({
    required double width,
    required double height,
    required PlayerEntity player,
    required List<TreeEntity> trees,
    required List<StumpEntity> stumps,
    required List<RockEntity> rocks,
    required List<GroundItemEntity> items,
    required List<DecorationEntity> decorations,
    required List<BuildingEntity> buildings,
    required HeroEntity hero,
    required StatsEntity stats,
    required InventoryEntity stock,
    required Map<String, int> idCounters,
  }) : this._(
         WorldState(
           width: width,
           height: height,
           player: player,
           trees: trees,
           items: items,
           decorations: decorations,
           rocks: rocks,
           buildings: buildings,
           hero: hero,
           stumps: stumps,
           stats: stats,
           stock: stock,
           idCounters: idCounters,
         ),
       );
```

Y el getter, junto a `stock`:

```dart
  Map<String, int> get idCounters => _state.idCounters;
```

- [ ] **Step 3: `QuestLog`** — misiones completadas restaurables y expuestas:

```diff
 class QuestLog {
-  QuestLog({List<Quest>? quests}) : _quests = quests ?? Quests.all;
+  QuestLog({List<Quest>? quests, Set<QuestId> completed = const {}})
+    : _quests = quests ?? Quests.all,
+      _completed = {...completed};
 
   final List<Quest> _quests;
-  final Set<QuestId> _completed = {};
+  final Set<QuestId> _completed;
+
+  Set<QuestId> get completed => Set.unmodifiable(_completed);
```

- [ ] **Step 4: `Upgrades.maxLevel` y `Rules.autosaveIntervalMs`** — `upgrades.dart` (añadir `import 'dart:math';`), tras `reached`:

```dart
  static int maxLevel(ToolKind tool) =>
      all.where((upgrade) => upgrade.tool == tool).fold(1, (level, upgrade) => max(level, upgrade.level));
```

`rules.dart`, tras `upgradedHitsPercent`:

```dart
  static const double autosaveIntervalMs = 10000;
```

- [ ] **Step 5: el repositorio** — `lib/layers/domain/repositories/save/game_save_repository.dart` (fichero nuevo):

```dart
import '../../entities/game/game_session_entity.dart';

abstract interface class GameSaveRepository {
  GameSessionEntity? load();

  void save(GameSessionEntity session);

  void clear();
}
```

- [ ] **Step 6: Verificar:** `flutter analyze lib` → `No issues found!`; `dart format --line-length 120` sobre los seis ficheros.
- [ ] **Step 7: Commit** — `git add lib/layers/domain`; en otro comando `git commit -m "[PROJECT-F2]: Restore the world and the quest log"`.

---

### Task TF2.3: Datos del guardado

**Files:**
- Create: `lib/core/config/di/storage_module.dart`; `lib/layers/data/datasources/save/local/dbo/{save_json,save_dbo,save_tree_dbo,save_stump_dbo,save_rock_dbo,save_item_dbo,save_decoration_dbo,save_building_dbo,save_inventory_dbo,save_player_dbo,save_hero_dbo,save_stats_dbo}.dart`; `lib/layers/data/datasources/save/source/game_save_local_datasource.dart`; `lib/layers/data/datasources/save/local/game_save_local_datasource_impl.dart`; `lib/layers/data/repositories/save/mappers/{save_position,save_tree,save_stump,save_rock,save_ground_item,save_decoration,save_building,save_inventory,save_player,save_hero,save_stats,save}_mapper_dbo.dart`; `lib/layers/data/repositories/save/game_save_repository_impl.dart`
- Modify: `lib/core/config/di/di.dart`, `lib/core/config/di/di.config.dart` (generado), `lib/core/error-handling/exceptions/app_exceptions.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`

**Interfaces:**
- Consumes: `World.restore`, `World.idCounters`, `QuestLog(completed:)`, `QuestLog.completed`, `Upgrades.maxLevel`, `GameSaveRepository` (TF2.2); `Gear.maxTier`, `Skills.byId`, `Blueprints.of`, `Rules`, `InventoryRules.add` / `addTool` / `withToolLevel` / `load`, `Logger`, `AppExceptionHandler`.
- Produces: `SharedPreferencesWithCache` en el *locator*; `InvalidSaveException({required String data})`; `Internationalize.errorInvalidSaveTitle`, `errorInvalidSaveMessage({required String reason})`; `GameSaveLocalDatasource { SaveDBO? load(); void save(SaveDBO save); void clear(); }`; `SaveDBO.currentVersion == 1`; `SaveMapperDBO.toDBO(GameSessionEntity) → SaveDBO` y `toEntity(SaveDBO) → GameSessionEntity`; `GameSaveRepositoryImpl` registrado como `GameSaveRepository`.

- [ ] **Step 1: módulo de almacenamiento** — `lib/core/config/di/storage_module.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class StorageModule {
  @singleton
  @preResolve
  Future<SharedPreferencesWithCache> get preferences =>
      SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
}
```

`di.dart`:

```diff
 Future<void> configureDependencies({required String environment}) async {
-  locator.init(environment: environment);
+  await locator.init(environment: environment);
 }
```

- [ ] **Step 2: excepción y textos** — `app_exceptions.dart`, al final:

```dart
final class InvalidSaveException extends AppException<String> {
  @override
  String get title => Internationalize.errorInvalidSaveTitle;

  @override
  String get message => Internationalize.errorInvalidSaveMessage(reason: data!);

  const InvalidSaveException({required String super.data});
}
```

`es.json`, en `error`, tras `noGameInProgressMessage`:

```json
    "invalidSaveTitle": "Partida guardada no válida",
    "invalidSaveMessage": "La partida guardada no es válida: {reason}"
```

`internationalize.dart`, tras `errorNoGameInProgressMessage`:

```dart
  static String get errorInvalidSaveTitle => '$_error.invalidSaveTitle'.tr();
  static String errorInvalidSaveMessage({required String reason}) =>
      '$_error.invalidSaveMessage'.tr(namedArgs: {'reason': reason});
```

- [ ] **Step 3: lecturas de JSON** — `lib/layers/data/datasources/save/local/dbo/save_json.dart` (fichero nuevo):

```dart
double? readDouble(Object? value) => (value as num?)?.toDouble();

Map<String, int>? readIntMap(Object? value) =>
    (value as Map<String, dynamic>?)?.map((key, amount) => MapEntry(key, amount as int));

List<String>? readStringList(Object? value) => (value as List<dynamic>?)?.map((item) => item as String).toList();

List<T>? readObjectList<T>(Object? value, T Function(Map<String, dynamic> json) fromJson) =>
    (value as List<dynamic>?)?.map((item) => fromJson(item as Map<String, dynamic>)).toList();
```

- [ ] **Step 4: DBOs de las piezas con posición** — `lib/layers/data/datasources/save/local/dbo/save_tree_dbo.dart` (fichero nuevo):

```dart
import 'save_json.dart';

class SaveTreeDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;
  final int? hitsTaken;

  const SaveTreeDBO({this.id, this.kind, this.x, this.y, this.hitsTaken});

  factory SaveTreeDBO.fromJson(Map<String, dynamic> json) => SaveTreeDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    hitsTaken: json['hitsTaken'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y, 'hitsTaken': hitsTaken};

  @override
  bool operator ==(Object other) =>
      other is SaveTreeDBO &&
      other.id == id &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, kind, x, y, hitsTaken);

  @override
  String toString() => 'SaveTreeDBO(id: $id, kind: $kind, x: $x, y: $y, hitsTaken: $hitsTaken)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_stump_dbo.dart` (fichero nuevo):

```dart
import 'save_json.dart';

class SaveStumpDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;
  final double? elapsedMs;

  const SaveStumpDBO({this.id, this.kind, this.x, this.y, this.elapsedMs});

  factory SaveStumpDBO.fromJson(Map<String, dynamic> json) => SaveStumpDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    elapsedMs: readDouble(json['elapsedMs']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y, 'elapsedMs': elapsedMs};

  @override
  bool operator ==(Object other) =>
      other is SaveStumpDBO &&
      other.id == id &&
      other.kind == kind &&
      other.x == x &&
      other.y == y &&
      other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(id, kind, x, y, elapsedMs);

  @override
  String toString() => 'SaveStumpDBO(id: $id, kind: $kind, x: $x, y: $y, elapsedMs: $elapsedMs)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_rock_dbo.dart` (fichero nuevo):

```dart
import 'save_json.dart';

class SaveRockDBO {
  final String? id;
  final double? x;
  final double? y;
  final int? hitsTaken;

  const SaveRockDBO({this.id, this.x, this.y, this.hitsTaken});

  factory SaveRockDBO.fromJson(Map<String, dynamic> json) => SaveRockDBO(
    id: json['id'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    hitsTaken: json['hitsTaken'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y, 'hitsTaken': hitsTaken};

  @override
  bool operator ==(Object other) =>
      other is SaveRockDBO && other.id == id && other.x == x && other.y == y && other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, x, y, hitsTaken);

  @override
  String toString() => 'SaveRockDBO(id: $id, x: $x, y: $y, hitsTaken: $hitsTaken)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_item_dbo.dart` (fichero nuevo):

```dart
import 'save_json.dart';

class SaveItemDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const SaveItemDBO({this.id, this.kind, this.x, this.y});

  factory SaveItemDBO.fromJson(Map<String, dynamic> json) => SaveItemDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      other is SaveItemDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'SaveItemDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_decoration_dbo.dart` (fichero nuevo):

```dart
import 'save_json.dart';

class SaveDecorationDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const SaveDecorationDBO({this.id, this.kind, this.x, this.y});

  factory SaveDecorationDBO.fromJson(Map<String, dynamic> json) => SaveDecorationDBO(
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
  );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      other is SaveDecorationDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'SaveDecorationDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_building_dbo.dart` (fichero nuevo):

```dart
import 'save_json.dart';

class SaveBuildingDBO {
  final String? id;
  final String? blueprint;
  final double? x;
  final double? y;
  final int? hitsDone;

  const SaveBuildingDBO({this.id, this.blueprint, this.x, this.y, this.hitsDone});

  factory SaveBuildingDBO.fromJson(Map<String, dynamic> json) => SaveBuildingDBO(
    id: json['id'] as String?,
    blueprint: json['blueprint'] as String?,
    x: readDouble(json['x']),
    y: readDouble(json['y']),
    hitsDone: json['hitsDone'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'blueprint': blueprint, 'x': x, 'y': y, 'hitsDone': hitsDone};

  @override
  bool operator ==(Object other) =>
      other is SaveBuildingDBO &&
      other.id == id &&
      other.blueprint == blueprint &&
      other.x == x &&
      other.y == y &&
      other.hitsDone == hitsDone;

  @override
  int get hashCode => Object.hash(id, blueprint, x, y, hitsDone);

  @override
  String toString() => 'SaveBuildingDBO(id: $id, blueprint: $blueprint, x: $x, y: $y, hitsDone: $hitsDone)';
}
```

- [ ] **Step 5: DBOs del inventario, el jugador, el héroe y las estadísticas** — `lib/layers/data/datasources/save/local/dbo/save_inventory_dbo.dart` (fichero nuevo):

```dart
import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveInventoryDBO {
  final Map<String, int>? resources;
  final List<String>? tools;
  final Map<String, int>? toolLevels;

  const SaveInventoryDBO({this.resources, this.tools, this.toolLevels});

  factory SaveInventoryDBO.fromJson(Map<String, dynamic> json) => SaveInventoryDBO(
    resources: readIntMap(json['resources']),
    tools: readStringList(json['tools']),
    toolLevels: readIntMap(json['toolLevels']),
  );

  Map<String, dynamic> toJson() => {'resources': resources, 'tools': tools, 'toolLevels': toolLevels};

  @override
  bool operator ==(Object other) =>
      other is SaveInventoryDBO &&
      const MapEquality<String, int>().equals(other.resources, resources) &&
      const ListEquality<String>().equals(other.tools, tools) &&
      const MapEquality<String, int>().equals(other.toolLevels, toolLevels);

  @override
  int get hashCode => Object.hash(
    const MapEquality<String, int>().hash(resources),
    const ListEquality<String>().hash(tools),
    const MapEquality<String, int>().hash(toolLevels),
  );

  @override
  String toString() => 'SaveInventoryDBO(resources: $resources, tools: $tools, toolLevels: $toolLevels)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_player_dbo.dart` (fichero nuevo):

```dart
import 'save_inventory_dbo.dart';
import 'save_json.dart';

class SavePlayerDBO {
  final double? x;
  final double? y;
  final SaveInventoryDBO? inventory;

  const SavePlayerDBO({this.x, this.y, this.inventory});

  factory SavePlayerDBO.fromJson(Map<String, dynamic> json) {
    final inventory = json['inventory'] as Map<String, dynamic>?;
    return SavePlayerDBO(
      x: readDouble(json['x']),
      y: readDouble(json['y']),
      inventory: inventory == null ? null : SaveInventoryDBO.fromJson(inventory),
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'inventory': inventory?.toJson()};

  @override
  bool operator ==(Object other) =>
      other is SavePlayerDBO && other.x == x && other.y == y && other.inventory == inventory;

  @override
  int get hashCode => Object.hash(x, y, inventory);

  @override
  String toString() => 'SavePlayerDBO(x: $x, y: $y, inventory: $inventory)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_hero_dbo.dart` (fichero nuevo):

```dart
import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveHeroDBO {
  final int? weaponTier;
  final int? armorTier;
  final Map<String, int>? skillLevels;
  final List<String>? clearedLevels;
  final int? fightsFought;

  const SaveHeroDBO({this.weaponTier, this.armorTier, this.skillLevels, this.clearedLevels, this.fightsFought});

  factory SaveHeroDBO.fromJson(Map<String, dynamic> json) => SaveHeroDBO(
    weaponTier: json['weaponTier'] as int?,
    armorTier: json['armorTier'] as int?,
    skillLevels: readIntMap(json['skillLevels']),
    clearedLevels: readStringList(json['clearedLevels']),
    fightsFought: json['fightsFought'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'weaponTier': weaponTier,
    'armorTier': armorTier,
    'skillLevels': skillLevels,
    'clearedLevels': clearedLevels,
    'fightsFought': fightsFought,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveHeroDBO &&
      other.weaponTier == weaponTier &&
      other.armorTier == armorTier &&
      const MapEquality<String, int>().equals(other.skillLevels, skillLevels) &&
      const ListEquality<String>().equals(other.clearedLevels, clearedLevels) &&
      other.fightsFought == fightsFought;

  @override
  int get hashCode => Object.hash(
    weaponTier,
    armorTier,
    const MapEquality<String, int>().hash(skillLevels),
    const ListEquality<String>().hash(clearedLevels),
    fightsFought,
  );

  @override
  String toString() =>
      'SaveHeroDBO(weaponTier: $weaponTier, armorTier: $armorTier, skillLevels: $skillLevels, '
      'clearedLevels: $clearedLevels, fightsFought: $fightsFought)';
}
```

`lib/layers/data/datasources/save/local/dbo/save_stats_dbo.dart` (fichero nuevo):

```dart
import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveStatsDBO {
  final int? treesFelled;
  final Map<String, int>? treesFelledByKind;
  final int? buildingsCompleted;
  final int? treesRegrown;

  const SaveStatsDBO({this.treesFelled, this.treesFelledByKind, this.buildingsCompleted, this.treesRegrown});

  factory SaveStatsDBO.fromJson(Map<String, dynamic> json) => SaveStatsDBO(
    treesFelled: json['treesFelled'] as int?,
    treesFelledByKind: readIntMap(json['treesFelledByKind']),
    buildingsCompleted: json['buildingsCompleted'] as int?,
    treesRegrown: json['treesRegrown'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'treesFelled': treesFelled,
    'treesFelledByKind': treesFelledByKind,
    'buildingsCompleted': buildingsCompleted,
    'treesRegrown': treesRegrown,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveStatsDBO &&
      other.treesFelled == treesFelled &&
      const MapEquality<String, int>().equals(other.treesFelledByKind, treesFelledByKind) &&
      other.buildingsCompleted == buildingsCompleted &&
      other.treesRegrown == treesRegrown;

  @override
  int get hashCode => Object.hash(
    treesFelled,
    const MapEquality<String, int>().hash(treesFelledByKind),
    buildingsCompleted,
    treesRegrown,
  );

  @override
  String toString() =>
      'SaveStatsDBO(treesFelled: $treesFelled, treesFelledByKind: $treesFelledByKind, '
      'buildingsCompleted: $buildingsCompleted, treesRegrown: $treesRegrown)';
}
```

- [ ] **Step 6: `SaveDBO`** — `lib/layers/data/datasources/save/local/dbo/save_dbo.dart` (fichero nuevo):

```dart
import 'package:collection/collection.dart';

import 'save_building_dbo.dart';
import 'save_decoration_dbo.dart';
import 'save_hero_dbo.dart';
import 'save_inventory_dbo.dart';
import 'save_item_dbo.dart';
import 'save_json.dart';
import 'save_player_dbo.dart';
import 'save_rock_dbo.dart';
import 'save_stats_dbo.dart';
import 'save_stump_dbo.dart';
import 'save_tree_dbo.dart';

class SaveDBO {
  static const int currentVersion = 1;

  final int? version;
  final double? width;
  final double? height;
  final SavePlayerDBO? player;
  final SaveHeroDBO? hero;
  final SaveStatsDBO? stats;
  final SaveInventoryDBO? stock;
  final List<SaveTreeDBO>? trees;
  final List<SaveStumpDBO>? stumps;
  final List<SaveRockDBO>? rocks;
  final List<SaveItemDBO>? items;
  final List<SaveDecorationDBO>? decorations;
  final List<SaveBuildingDBO>? buildings;
  final Map<String, int>? idCounters;
  final List<String>? completedQuests;

  const SaveDBO({
    this.version,
    this.width,
    this.height,
    this.player,
    this.hero,
    this.stats,
    this.stock,
    this.trees,
    this.stumps,
    this.rocks,
    this.items,
    this.decorations,
    this.buildings,
    this.idCounters,
    this.completedQuests,
  });

  factory SaveDBO.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>?;
    final hero = json['hero'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final stock = json['stock'] as Map<String, dynamic>?;
    return SaveDBO(
      version: json['version'] as int?,
      width: readDouble(json['width']),
      height: readDouble(json['height']),
      player: player == null ? null : SavePlayerDBO.fromJson(player),
      hero: hero == null ? null : SaveHeroDBO.fromJson(hero),
      stats: stats == null ? null : SaveStatsDBO.fromJson(stats),
      stock: stock == null ? null : SaveInventoryDBO.fromJson(stock),
      trees: readObjectList(json['trees'], SaveTreeDBO.fromJson),
      stumps: readObjectList(json['stumps'], SaveStumpDBO.fromJson),
      rocks: readObjectList(json['rocks'], SaveRockDBO.fromJson),
      items: readObjectList(json['items'], SaveItemDBO.fromJson),
      decorations: readObjectList(json['decorations'], SaveDecorationDBO.fromJson),
      buildings: readObjectList(json['buildings'], SaveBuildingDBO.fromJson),
      idCounters: readIntMap(json['idCounters']),
      completedQuests: readStringList(json['completedQuests']),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'width': width,
    'height': height,
    'player': player?.toJson(),
    'hero': hero?.toJson(),
    'stats': stats?.toJson(),
    'stock': stock?.toJson(),
    'trees': trees?.map((tree) => tree.toJson()).toList(),
    'stumps': stumps?.map((stump) => stump.toJson()).toList(),
    'rocks': rocks?.map((rock) => rock.toJson()).toList(),
    'items': items?.map((item) => item.toJson()).toList(),
    'decorations': decorations?.map((decoration) => decoration.toJson()).toList(),
    'buildings': buildings?.map((building) => building.toJson()).toList(),
    'idCounters': idCounters,
    'completedQuests': completedQuests,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveDBO &&
      other.version == version &&
      other.width == width &&
      other.height == height &&
      other.player == player &&
      other.hero == hero &&
      other.stats == stats &&
      other.stock == stock &&
      const ListEquality<SaveTreeDBO>().equals(other.trees, trees) &&
      const ListEquality<SaveStumpDBO>().equals(other.stumps, stumps) &&
      const ListEquality<SaveRockDBO>().equals(other.rocks, rocks) &&
      const ListEquality<SaveItemDBO>().equals(other.items, items) &&
      const ListEquality<SaveDecorationDBO>().equals(other.decorations, decorations) &&
      const ListEquality<SaveBuildingDBO>().equals(other.buildings, buildings) &&
      const MapEquality<String, int>().equals(other.idCounters, idCounters) &&
      const ListEquality<String>().equals(other.completedQuests, completedQuests);

  @override
  int get hashCode => Object.hash(
    version,
    width,
    height,
    player,
    hero,
    stats,
    stock,
    const ListEquality<SaveTreeDBO>().hash(trees),
    const ListEquality<SaveStumpDBO>().hash(stumps),
    const ListEquality<SaveRockDBO>().hash(rocks),
    const ListEquality<SaveItemDBO>().hash(items),
    const ListEquality<SaveDecorationDBO>().hash(decorations),
    const ListEquality<SaveBuildingDBO>().hash(buildings),
    const MapEquality<String, int>().hash(idCounters),
    const ListEquality<String>().hash(completedQuests),
  );

  @override
  String toString() =>
      'SaveDBO(version: $version, width: $width, height: $height, player: $player, hero: $hero, stats: $stats, '
      'stock: $stock, trees: $trees, stumps: $stumps, rocks: $rocks, items: $items, decorations: $decorations, '
      'buildings: $buildings, idCounters: $idCounters, completedQuests: $completedQuests)';
}
```

- [ ] **Step 7: datasource** — `lib/layers/data/datasources/save/source/game_save_local_datasource.dart` (fichero nuevo):

```dart
import '../local/dbo/save_dbo.dart';

abstract interface class GameSaveLocalDatasource {
  SaveDBO? load();

  void save(SaveDBO save);

  void clear();
}
```

`lib/layers/data/datasources/save/local/game_save_local_datasource_impl.dart` (fichero nuevo):

```dart
import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/services/logging/source/logger.dart';
import '../source/game_save_local_datasource.dart';
import 'dbo/save_dbo.dart';

@LazySingleton(as: GameSaveLocalDatasource)
class GameSaveLocalDatasourceImpl implements GameSaveLocalDatasource {
  static const String _key = 'farming.save';
  static const String _logHeader = 'GameSaveLocalDatasource';

  final SharedPreferencesWithCache _preferences;
  final Logger _logger;

  const GameSaveLocalDatasourceImpl({required this._preferences, required this._logger});

  @override
  SaveDBO? load() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    return SaveDBO.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void save(SaveDBO save) {
    unawaited(_preferences.setString(_key, jsonEncode(save.toJson())).catchError(_logFailure));
  }

  @override
  void clear() {
    unawaited(_preferences.remove(_key).catchError(_logFailure));
  }

  void _logFailure(Object error, StackTrace stackTrace) {
    _logger.error(message: '$error', header: _logHeader, stackTrace: stackTrace);
  }
}
```

- [ ] **Step 8: mappers de las piezas** — `lib/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/geometry/position_entity.dart';

@Injectable()
class SavePositionMapperDBO {
  PositionEntity toEntity({required double? x, required double? y, required String owner}) {
    return PositionEntity(
      x: x ?? (throw InvalidSaveException(data: '$owner without x')),
      y: y ?? (throw InvalidSaveException(data: '$owner without y')),
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_tree_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/tree/tree_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/save/local/dbo/save_tree_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveTreeMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveTreeMapperDBO({required this._positionMapperDBO});

  SaveTreeDBO toDBO(TreeEntity tree) {
    return SaveTreeDBO(
      id: tree.id,
      kind: tree.kind.name,
      x: tree.position.x,
      y: tree.position.y,
      hitsTaken: tree.hitsTaken,
    );
  }

  TreeEntity toEntity(SaveTreeDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'tree without id'));
    final kind =
        TreeKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'tree $id: unknown kind "${dbo.kind}"'));
    final stats = Rules.treeKindStats[kind] ?? (throw InvalidSaveException(data: 'tree $id: no stats for ${kind.name}'));
    final hitsTaken = dbo.hitsTaken ?? 0;
    if (hitsTaken < 0 || hitsTaken >= stats.hitsToFell) {
      throw InvalidSaveException(data: 'tree $id: $hitsTaken hits taken of ${stats.hitsToFell}');
    }
    return TreeEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'tree $id'),
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: stats.woodYield,
      hitsToFell: stats.hitsToFell,
      hitsTaken: hitsTaken,
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_stump_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/tree/stump_entity.dart';
import '../../../datasources/save/local/dbo/save_stump_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveStumpMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveStumpMapperDBO({required this._positionMapperDBO});

  SaveStumpDBO toDBO(StumpEntity stump) {
    return SaveStumpDBO(
      id: stump.id,
      kind: stump.kind.name,
      x: stump.position.x,
      y: stump.position.y,
      elapsedMs: stump.elapsedMs,
    );
  }

  StumpEntity toEntity(SaveStumpDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'stump without id'));
    final kind =
        TreeKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'stump $id: unknown kind "${dbo.kind}"'));
    final elapsedMs = dbo.elapsedMs ?? 0;
    if (elapsedMs < 0) throw InvalidSaveException(data: 'stump $id: elapsed $elapsedMs ms');
    return StumpEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'stump $id'),
      elapsedMs: elapsedMs,
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_rock_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/rock/rock_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/save/local/dbo/save_rock_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveRockMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveRockMapperDBO({required this._positionMapperDBO});

  SaveRockDBO toDBO(RockEntity rock) {
    return SaveRockDBO(id: rock.id, x: rock.position.x, y: rock.position.y, hitsTaken: rock.hitsTaken);
  }

  RockEntity toEntity(SaveRockDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'rock without id'));
    final hitsTaken = dbo.hitsTaken ?? 0;
    if (hitsTaken < 0 || hitsTaken >= Rules.rockHitsToBreak) {
      throw InvalidSaveException(data: 'rock $id: $hitsTaken hits taken of ${Rules.rockHitsToBreak}');
    }
    return RockEntity(
      id: id,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'rock $id'),
      radius: Rules.rockRadius,
      stoneYield: Rules.rockStoneYield,
      hitsToBreak: Rules.rockHitsToBreak,
      hitsTaken: hitsTaken,
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_ground_item_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/item/ground_item_entity.dart';
import '../../../datasources/save/local/dbo/save_item_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveGroundItemMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveGroundItemMapperDBO({required this._positionMapperDBO});

  SaveItemDBO toDBO(GroundItemEntity item) {
    return SaveItemDBO(id: item.id, kind: item.kind.name, x: item.position.x, y: item.position.y);
  }

  GroundItemEntity toEntity(SaveItemDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'item without id'));
    final kind =
        ToolKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'item $id: unknown kind "${dbo.kind}"'));
    return GroundItemEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'item $id'),
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_decoration_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/decoration/decoration_entity.dart';
import '../../../datasources/save/local/dbo/save_decoration_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveDecorationMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveDecorationMapperDBO({required this._positionMapperDBO});

  SaveDecorationDBO toDBO(DecorationEntity decoration) {
    return SaveDecorationDBO(
      id: decoration.id,
      kind: decoration.kind.name,
      x: decoration.position.x,
      y: decoration.position.y,
    );
  }

  DecorationEntity toEntity(SaveDecorationDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'decoration without id'));
    final kind =
        DecorationKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'decoration $id: unknown kind "${dbo.kind}"'));
    return DecorationEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'decoration $id'),
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_building_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/building/building_entity.dart';
import '../../../../domain/rules/blueprints.dart';
import '../../../datasources/save/local/dbo/save_building_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveBuildingMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveBuildingMapperDBO({required this._positionMapperDBO});

  SaveBuildingDBO toDBO(BuildingEntity building) {
    return SaveBuildingDBO(
      id: building.id,
      blueprint: building.blueprint.id.name,
      x: building.position.x,
      y: building.position.y,
      hitsDone: building.hitsDone,
    );
  }

  BuildingEntity toEntity(SaveBuildingDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'building without id'));
    final blueprintId =
        BlueprintId.values.asNameMap()[dbo.blueprint] ??
        (throw InvalidSaveException(data: 'building $id: unknown blueprint "${dbo.blueprint}"'));
    final blueprint = Blueprints.of(blueprintId);
    final hitsDone = dbo.hitsDone ?? 0;
    if (hitsDone < 0 || hitsDone > blueprint.hitsToBuild) {
      throw InvalidSaveException(data: 'building $id: $hitsDone hits of ${blueprint.hitsToBuild}');
    }
    return BuildingEntity(
      id: id,
      blueprint: blueprint,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'building $id'),
      hitsDone: hitsDone,
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_inventory_mapper_dbo.dart` (fichero nuevo):

```dart
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/resource.dart';
import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/player/inventory_entity.dart';
import '../../../../domain/rules/upgrades.dart';
import '../../../../domain/world/extensions/inventory_rules.dart';
import '../../../datasources/save/local/dbo/save_inventory_dbo.dart';

@Injectable()
class SaveInventoryMapperDBO {
  SaveInventoryDBO toDBO(InventoryEntity inventory) {
    return SaveInventoryDBO(
      resources: {
        for (final MapEntry(key: resource, value: amount) in inventory.resources.entries) resource.name: amount,
      },
      tools: [for (final tool in inventory.tools) tool.name],
      toolLevels: {for (final MapEntry(key: tool, value: level) in inventory.toolLevels.entries) tool.name: level},
    );
  }

  InventoryEntity toEntity(SaveInventoryDBO? dbo, {required String owner}) {
    if (dbo == null) return const InventoryEntity();
    var inventory = const InventoryEntity();
    for (final MapEntry(key: name, value: amount) in (dbo.resources ?? const <String, int>{}).entries) {
      final resource =
          Resource.values.asNameMap()[name] ?? (throw InvalidSaveException(data: '$owner: unknown resource "$name"'));
      if (amount < 0) throw InvalidSaveException(data: '$owner: $amount ${resource.name}');
      inventory = inventory.add(resource, amount);
    }
    for (final name in dbo.tools ?? const <String>[]) {
      inventory = inventory.addTool(_tool(name, owner: owner));
    }
    for (final MapEntry(key: name, value: level) in (dbo.toolLevels ?? const <String, int>{}).entries) {
      final tool = _tool(name, owner: owner);
      if (level < 1) throw InvalidSaveException(data: '$owner: ${tool.name} level $level');
      inventory = inventory.withToolLevel(tool, min(level, Upgrades.maxLevel(tool)));
    }
    return inventory;
  }

  ToolKind _tool(String name, {required String owner}) {
    return ToolKind.values.asNameMap()[name] ?? (throw InvalidSaveException(data: '$owner: unknown tool "$name"'));
  }
}
```

`lib/layers/data/repositories/save/mappers/save_player_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/player/player_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../../domain/world/extensions/inventory_rules.dart';
import '../../../datasources/save/local/dbo/save_player_dbo.dart';
import 'save_inventory_mapper_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SavePlayerMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;
  final SaveInventoryMapperDBO _inventoryMapperDBO;

  const SavePlayerMapperDBO({required this._positionMapperDBO, required this._inventoryMapperDBO});

  SavePlayerDBO toDBO(PlayerEntity player) {
    return SavePlayerDBO(
      x: player.position.x,
      y: player.position.y,
      inventory: _inventoryMapperDBO.toDBO(player.inventory),
    );
  }

  PlayerEntity toEntity(SavePlayerDBO? dbo) {
    final player = dbo ?? (throw const InvalidSaveException(data: 'missing player'));
    final inventory = _inventoryMapperDBO.toEntity(player.inventory, owner: 'player');
    if (inventory.load > Rules.carryCapacity) {
      throw InvalidSaveException(data: 'player carries ${inventory.load} of ${Rules.carryCapacity}');
    }
    return PlayerEntity(
      position: _positionMapperDBO.toEntity(x: player.x, y: player.y, owner: 'player'),
      speed: Rules.playerSpeed,
      radius: Rules.playerRadius,
      inventory: inventory,
    );
  }
}
```

`lib/layers/data/repositories/save/mappers/save_hero_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/hero/hero_entity.dart';
import '../../../../domain/rules/gear.dart';
import '../../../../domain/rules/skills.dart';
import '../../../datasources/save/local/dbo/save_hero_dbo.dart';

@Injectable()
class SaveHeroMapperDBO {
  SaveHeroDBO toDBO(HeroEntity hero) {
    return SaveHeroDBO(
      weaponTier: hero.weaponTier,
      armorTier: hero.armorTier,
      skillLevels: {for (final MapEntry(key: id, value: level) in hero.skillLevels.entries) id.name: level},
      clearedLevels: [for (final level in hero.clearedLevels) level.name],
      fightsFought: hero.fightsFought,
    );
  }

  HeroEntity toEntity(SaveHeroDBO? dbo) {
    if (dbo == null) return const HeroEntity();
    final skillLevels = <SkillId, int>{};
    for (final MapEntry(key: name, value: level) in (dbo.skillLevels ?? const <String, int>{}).entries) {
      final id =
          SkillId.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'hero: unknown skill "$name"'));
      final maxLevel = Skills.byId(id).maxLevel;
      if (level < 1 || level > maxLevel) throw InvalidSaveException(data: 'hero: ${id.name} level $level of $maxLevel');
      skillLevels[id] = level;
    }
    final fightsFought = dbo.fightsFought ?? 0;
    if (fightsFought < 0) throw InvalidSaveException(data: 'hero: $fightsFought fights');
    return HeroEntity(
      weaponTier: _tier(dbo.weaponTier, GearSlot.weapon),
      armorTier: _tier(dbo.armorTier, GearSlot.armor),
      skillLevels: skillLevels,
      clearedLevels: {
        for (final name in dbo.clearedLevels ?? const <String>[])
          ArenaLevelId.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'hero: unknown level "$name"')),
      },
      fightsFought: fightsFought,
    );
  }

  int _tier(int? tier, GearSlot slot) {
    final value = tier ?? 0;
    if (value < 0 || value > Gear.maxTier(slot)) throw InvalidSaveException(data: 'hero: ${slot.name} tier $value');
    return value;
  }
}
```

`lib/layers/data/repositories/save/mappers/save_stats_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/game/stats_entity.dart';
import '../../../datasources/save/local/dbo/save_stats_dbo.dart';

@Injectable()
class SaveStatsMapperDBO {
  SaveStatsDBO toDBO(StatsEntity stats) {
    return SaveStatsDBO(
      treesFelled: stats.treesFelled,
      treesFelledByKind: {
        for (final MapEntry(key: kind, value: count) in stats.treesFelledByKind.entries) kind.name: count,
      },
      buildingsCompleted: stats.buildingsCompleted,
      treesRegrown: stats.treesRegrown,
    );
  }

  StatsEntity toEntity(SaveStatsDBO? dbo) {
    if (dbo == null) return const StatsEntity();
    return StatsEntity(
      treesFelled: _count(dbo.treesFelled, 'treesFelled'),
      treesFelledByKind: {
        for (final MapEntry(key: name, value: count) in (dbo.treesFelledByKind ?? const <String, int>{}).entries)
          TreeKind.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'stats: unknown tree kind "$name"')):
              _count(count, 'treesFelledByKind.$name'),
      },
      buildingsCompleted: _count(dbo.buildingsCompleted, 'buildingsCompleted'),
      treesRegrown: _count(dbo.treesRegrown, 'treesRegrown'),
    );
  }

  int _count(int? count, String field) {
    final value = count ?? 0;
    if (value < 0) throw InvalidSaveException(data: 'stats: $field $value');
    return value;
  }
}
```

- [ ] **Step 9: la partida entera** — `lib/layers/data/repositories/save/mappers/save_mapper_dbo.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/quest_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/game/game_session_entity.dart';
import '../../../../domain/quests/quest_log.dart';
import '../../../../domain/world/world.dart';
import '../../../datasources/save/local/dbo/save_dbo.dart';
import 'save_building_mapper_dbo.dart';
import 'save_decoration_mapper_dbo.dart';
import 'save_ground_item_mapper_dbo.dart';
import 'save_hero_mapper_dbo.dart';
import 'save_inventory_mapper_dbo.dart';
import 'save_player_mapper_dbo.dart';
import 'save_rock_mapper_dbo.dart';
import 'save_stats_mapper_dbo.dart';
import 'save_stump_mapper_dbo.dart';
import 'save_tree_mapper_dbo.dart';

@Injectable()
class SaveMapperDBO {
  final SaveTreeMapperDBO _treeMapperDBO;
  final SaveStumpMapperDBO _stumpMapperDBO;
  final SaveRockMapperDBO _rockMapperDBO;
  final SaveGroundItemMapperDBO _groundItemMapperDBO;
  final SaveDecorationMapperDBO _decorationMapperDBO;
  final SaveBuildingMapperDBO _buildingMapperDBO;
  final SaveInventoryMapperDBO _inventoryMapperDBO;
  final SavePlayerMapperDBO _playerMapperDBO;
  final SaveHeroMapperDBO _heroMapperDBO;
  final SaveStatsMapperDBO _statsMapperDBO;

  const SaveMapperDBO({
    required this._treeMapperDBO,
    required this._stumpMapperDBO,
    required this._rockMapperDBO,
    required this._groundItemMapperDBO,
    required this._decorationMapperDBO,
    required this._buildingMapperDBO,
    required this._inventoryMapperDBO,
    required this._playerMapperDBO,
    required this._heroMapperDBO,
    required this._statsMapperDBO,
  });

  SaveDBO toDBO(GameSessionEntity session) {
    final world = session.world;
    final completed = session.quests.completed;
    return SaveDBO(
      version: SaveDBO.currentVersion,
      width: world.width,
      height: world.height,
      player: _playerMapperDBO.toDBO(world.player),
      hero: _heroMapperDBO.toDBO(world.hero),
      stats: _statsMapperDBO.toDBO(world.stats),
      stock: _inventoryMapperDBO.toDBO(world.stock),
      trees: world.trees.map(_treeMapperDBO.toDBO).toList(),
      stumps: world.stumps.map(_stumpMapperDBO.toDBO).toList(),
      rocks: world.rocks.map(_rockMapperDBO.toDBO).toList(),
      items: world.items.map(_groundItemMapperDBO.toDBO).toList(),
      decorations: world.decorations.map(_decorationMapperDBO.toDBO).toList(),
      buildings: world.buildings.map(_buildingMapperDBO.toDBO).toList(),
      idCounters: {...world.idCounters},
      completedQuests: [
        for (final id in QuestId.values)
          if (completed.contains(id)) id.name,
      ],
    );
  }

  GameSessionEntity toEntity(SaveDBO dbo) {
    if (dbo.version != SaveDBO.currentVersion) {
      throw InvalidSaveException(data: 'unknown version ${dbo.version}');
    }
    return GameSessionEntity(
      world: World.restore(
        width: _size(dbo.width, 'width'),
        height: _size(dbo.height, 'height'),
        player: _playerMapperDBO.toEntity(dbo.player),
        trees: (dbo.trees ?? const []).map(_treeMapperDBO.toEntity).toList(),
        stumps: (dbo.stumps ?? const []).map(_stumpMapperDBO.toEntity).toList(),
        rocks: (dbo.rocks ?? const []).map(_rockMapperDBO.toEntity).toList(),
        items: (dbo.items ?? const []).map(_groundItemMapperDBO.toEntity).toList(),
        decorations: (dbo.decorations ?? const []).map(_decorationMapperDBO.toEntity).toList(),
        buildings: (dbo.buildings ?? const []).map(_buildingMapperDBO.toEntity).toList(),
        hero: _heroMapperDBO.toEntity(dbo.hero),
        stats: _statsMapperDBO.toEntity(dbo.stats),
        stock: _inventoryMapperDBO.toEntity(dbo.stock, owner: 'stock'),
        idCounters: _idCounters(dbo.idCounters ?? const {}),
      ),
      quests: QuestLog(
        completed: {
          for (final name in dbo.completedQuests ?? const <String>[])
            QuestId.values.asNameMap()[name] ?? (throw InvalidSaveException(data: 'unknown quest "$name"')),
        },
      ),
    );
  }

  double _size(double? size, String field) {
    if (size == null || size <= 0) throw InvalidSaveException(data: 'world $field $size');
    return size;
  }

  Map<String, int> _idCounters(Map<String, int> counters) {
    for (final MapEntry(key: prefix, value: count) in counters.entries) {
      if (count < 0) throw InvalidSaveException(data: 'id counter $prefix $count');
    }
    return counters;
  }
}
```

- [ ] **Step 10: el repositorio** — `lib/layers/data/repositories/save/game_save_repository_impl.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../core/error-handling/handlers/app_exception_handler.dart';
import '../../../../core/services/logging/source/logger.dart';
import '../../../domain/entities/game/game_session_entity.dart';
import '../../../domain/repositories/save/game_save_repository.dart';
import '../../datasources/save/source/game_save_local_datasource.dart';
import 'mappers/save_mapper_dbo.dart';

@Injectable(as: GameSaveRepository)
final class GameSaveRepositoryImpl implements GameSaveRepository {
  static const String _logHeader = 'GameSaveRepository';

  final GameSaveLocalDatasource _localDatasource;
  final SaveMapperDBO _saveMapperDBO;
  final AppExceptionHandler _appExceptionHandler;
  final Logger _logger;

  const GameSaveRepositoryImpl({
    required this._localDatasource,
    required this._saveMapperDBO,
    required this._appExceptionHandler,
    required this._logger,
  });

  @override
  GameSessionEntity? load() {
    try {
      final dbo = _localDatasource.load();
      return dbo == null ? null : _saveMapperDBO.toEntity(dbo);
    } catch (exception, stackTrace) {
      _handled(exception, stackTrace);
      return null;
    }
  }

  @override
  void save(GameSessionEntity session) {
    try {
      _localDatasource.save(_saveMapperDBO.toDBO(session));
    } catch (exception, stackTrace) {
      throw _handled(exception, stackTrace);
    }
  }

  @override
  void clear() {
    try {
      _localDatasource.clear();
    } catch (exception, stackTrace) {
      throw _handled(exception, stackTrace);
    }
  }

  AppException<Object?> _handled(Object exception, StackTrace stackTrace) {
    final error = _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    _logger.error(message: '${error.message} ($exception)', header: _logHeader, stackTrace: stackTrace);
    return error;
  }
}
```

- [ ] **Step 11: Verificar:** `dart run build_runner build --delete-conflicting-outputs` (registra `StorageModule.preferences` con `preResolve`, el datasource, los doce *mappers* y el repositorio; `init` pasa a devolver `Future`); si toca `test/**/*.mocks.dart`, `git checkout -- test`. `flutter analyze lib` → `No issues found!`; `dart format --line-length 120` sobre los ficheros escritos (no sobre `di.config.dart`).
- [ ] **Step 12: Commit** — `git add lib/core lib/layers/data/datasources/save lib/layers/data/repositories/save`; en otro comando `git commit -m "[PROJECT-F2]: Add the save game storage"`.

---

### Task TF2.4: La sesión en el repositorio y los casos de uso

**Files:**
- Delete: `lib/layers/data/datasources/session/` (las dos clases)
- Modify: `lib/layers/data/repositories/session/game_session_repository_impl.dart`, `lib/layers/domain/use-cases/game/start_game_use_case.dart`, `lib/core/config/di/di.config.dart` (generado)
- Create: `lib/layers/domain/use-cases/game/save_game_use_case.dart`, `lib/layers/domain/use-cases/game/new_game_use_case.dart`

**Interfaces:**
- Consumes: `GameSaveRepository` (TF2.2, implementado en TF2.3), `GameSessionRepository`, `LevelRepository`, `QuestLog()`.
- Produces: `GameSessionRepositoryImpl()` `@LazySingleton`; `SaveGameUseCase.call()` (lanza `AppException` si falla); `NewGameUseCase.call()`; `StartGameUseCase({levelRepository, sessionRepository, saveRepository})`.

- [ ] **Step 1: borrar el datasource en memoria** — `git rm -r lib/layers/data/datasources/session`.
- [ ] **Step 2: la sesión viva** — fichero completo `lib/layers/data/repositories/session/game_session_repository_impl.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../domain/entities/game/game_session_entity.dart';
import '../../../domain/repositories/session/game_session_repository.dart';

@LazySingleton(as: GameSessionRepository)
final class GameSessionRepositoryImpl implements GameSessionRepository {
  GameSessionEntity? _session;

  @override
  GameSessionEntity current() => _session ?? (throw const NoGameInProgressException());

  @override
  void save(GameSessionEntity session) {
    _session = session;
  }
}
```

- [ ] **Step 3: casos de uso** — `lib/layers/domain/use-cases/game/save_game_use_case.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../repositories/save/game_save_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class SaveGameUseCase {
  final GameSessionRepository _sessionRepository;
  final GameSaveRepository _saveRepository;

  const SaveGameUseCase({required this._sessionRepository, required this._saveRepository});

  void call() {
    _saveRepository.save(_sessionRepository.current());
  }
}
```

`lib/layers/domain/use-cases/game/new_game_use_case.dart` (fichero nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../entities/game/game_session_entity.dart';
import '../../quests/quest_log.dart';
import '../../repositories/level/level_repository.dart';
import '../../repositories/save/game_save_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class NewGameUseCase {
  final LevelRepository _levelRepository;
  final GameSessionRepository _sessionRepository;
  final GameSaveRepository _saveRepository;

  const NewGameUseCase({
    required this._levelRepository,
    required this._sessionRepository,
    required this._saveRepository,
  });

  void call() {
    _saveRepository.clear();
    _sessionRepository.save(GameSessionEntity(world: _levelRepository.load(), quests: QuestLog()));
  }
}
```

Fichero completo `lib/layers/domain/use-cases/game/start_game_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../entities/game/game_session_entity.dart';
import '../../quests/quest_log.dart';
import '../../repositories/level/level_repository.dart';
import '../../repositories/save/game_save_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class StartGameUseCase {
  final LevelRepository _levelRepository;
  final GameSessionRepository _sessionRepository;
  final GameSaveRepository _saveRepository;

  const StartGameUseCase({
    required this._levelRepository,
    required this._sessionRepository,
    required this._saveRepository,
  });

  void call() {
    _sessionRepository.save(
      _saveRepository.load() ?? GameSessionEntity(world: _levelRepository.load(), quests: QuestLog()),
    );
  }
}
```

- [ ] **Step 4: Verificar:** `dart run build_runner build --delete-conflicting-outputs` (desaparece `GameSessionLocalDatasource`, `GameSessionRepository` pasa a `lazySingleton`, aparecen los dos casos de uso); si toca `test/**/*.mocks.dart`, `git checkout -- test`. `flutter analyze lib` → `No issues found!`; `dart format --line-length 120` sobre los cuatro ficheros.
- [ ] **Step 5: Commit** — `git add -A lib/layers/data lib/layers/domain lib/core/config/di`; en otro comando `git commit -m "[PROJECT-F2]: Keep the session in its repository and load the save"`.

---

### Task TF2.5: Autoguardado en el bosque

**Files:**
- Modify: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `bloc/forest_event.dart`, `forest_page.dart`, `game/forest_scene_component.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`

**Interfaces:**
- Consumes: `SaveGameUseCase`, `NewGameUseCase` (TF2.4), `Rules.autosaveIntervalMs` (TF2.2), `NavigationService.push` / `showErrorPopUp` / `showSnackbar`.
- Produces: `ForestBloc({…, required SaveGameUseCase saveGameUseCase, required NewGameUseCase newGameUseCase, …})`; eventos `ForestPaused()`, `ForestSaveRequested()`, `ForestNewGameRequested()`; `Internationalize.forestGameSaved`.

- [ ] **Step 1: texto** — `es.json`, en `forest`, un grupo nuevo `game` (tras `floating`):

```json
    "game": {
      "saved": "Partida guardada"
    }
```

`internationalize.dart`, tras `forestWorkshop`:

```dart
  static String get forestGameSaved => '$_forest.game.saved'.tr();
```

- [ ] **Step 2: eventos** — al final de `forest_event.dart`:

```dart
final class ForestPaused extends ForestEvent {
  const ForestPaused();
}

final class ForestSaveRequested extends ForestEvent {
  const ForestSaveRequested();
}

final class ForestNewGameRequested extends ForestEvent {
  const ForestNewGameRequested();
}
```

- [ ] **Step 3: el bloc** — imports `../../../../domain/use-cases/game/new_game_use_case.dart` y `../../../../domain/use-cases/game/save_game_use_case.dart`; campos `final SaveGameUseCase _saveGameUseCase;` y `final NewGameUseCase _newGameUseCase;` (tras `_buyUpgradeUseCase`), `double _msSinceSave = 0;` (tras `_hasGreeted`); en el constructor `required this._saveGameUseCase, required this._newGameUseCase,` tras `required this._buyUpgradeUseCase,`; y tres casos al final del `switch`:

```dart
        ForestPaused() => _onPaused(event, emit),
        ForestSaveRequested() => _onSaveRequested(event, emit),
        ForestNewGameRequested() => _onNewGameRequested(event, emit),
```

`_onStarted` reutiliza el reinicio y el pop-up:

```dart
  Future<void> _onStarted(ForestStarted event, Emitter<ForestState> emit) async {
    emit(ForestInProgress(data: state.data));

    try {
      _startGameUseCase();
      _resetSession();
      emit(ForestSuccess(data: _buildData(effects: const [])));
    } on AppException catch (exception) {
      _showError(exception);
      emit(ForestFailure(data: state.data, exception: exception));
    }
  }
```

En `_onTicked`, tras `_announceQuests(...)` y antes del `emit`:

```dart
    _msSinceSave += event.deltaMs;
    if (_msSinceSave >= Rules.autosaveIntervalMs || gameEvents.any(_isWorthSaving)) _autosave();
```

`_onArenaRequested` guarda al volver:

```dart
  Future<void> _onArenaRequested(ForestArenaRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _placement = null;
    final arenaClosed = _navigationService.push(const ArenaPage());
    emit(ForestSuccess(data: _buildData(effects: const [])));
    await arenaClosed;
    _autosave();
  }
```

`_autosave();` tras `effects.add(GearPurchasedEffect(gear: id));`, tras cada `effects.add(SkillLearnedEffect(skill: id));` (casos `ok` y `upgraded`) y tras `effects.add(UpgradePurchasedEffect(upgrade: id));`.

Manejadores y ayudas nuevas (tras `_onUpgradeRequested` / `_buyUpgrade`):

```dart
  Future<void> _onPaused(ForestPaused event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _autosave();
  }

  Future<void> _onSaveRequested(ForestSaveRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _msSinceSave = 0;
    try {
      _saveGameUseCase();
      _showMessage(Internationalize.forestGameSaved);
    } on AppException catch (exception) {
      _showError(exception);
    }
  }

  Future<void> _onNewGameRequested(ForestNewGameRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    emit(ForestInProgress(data: state.data));

    try {
      _newGameUseCase();
      _resetSession();
      emit(ForestSuccess(data: _buildData(effects: const [])));
    } on AppException catch (exception) {
      _showError(exception);
      emit(ForestFailure(data: state.data, exception: exception));
    }
  }

  void _resetSession() {
    _hasGreeted = false;
    _placement = null;
    _facing = Facing.down;
    _msSinceSave = 0;
    _lastPosition = _getPlayerStatusUseCase().position;
  }

  bool _autosave() {
    _msSinceSave = 0;
    try {
      _saveGameUseCase();
      return true;
    } on AppException {
      return false;
    }
  }

  bool _isWorthSaving(GameEventEntity gameEvent) => switch (gameEvent) {
    ItemPickedUpEventEntity() ||
    TreeFelledEventEntity() ||
    BuildingCompletedEventEntity() ||
    QuestCompletedEventEntity() ||
    RockBrokenEventEntity() ||
    DepositedEventEntity() => true,
    PlayerBlockedEventEntity() ||
    TreeHitEventEntity() ||
    BuildingHammeredEventEntity() ||
    TreeSproutedEventEntity() ||
    TreeRegrownEventEntity() ||
    RockHitEventEntity() => false,
  };
```

Junto a `_showMessage`:

```dart
  void _showError(AppException exception) {
    _navigationService.showErrorPopUp(
      title: exception.title,
      message: exception.message,
      buttonTitle: Internationalize.commonAccept,
    );
  }
```

- [ ] **Step 4: la página** — `ForestPage` inyecta los dos casos de uso (imports `../../../domain/use-cases/game/new_game_use_case.dart` y `save_game_use_case.dart`):

```dart
        saveGameUseCase: locator.get<SaveGameUseCase>(),
        newGameUseCase: locator.get<NewGameUseCase>(),
```

`_ForestViewState` escucha el ciclo de vida y crea un juego nuevo al empezar de nuevo:

```dart
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onPause: _onBackground, onHide: _onBackground);
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  void _onBackground() => bloc.add(const ForestPaused());
```

```diff
   void dispose() {
+    _lifecycleListener.dispose();
     widget.routeObserver.unsubscribe(this);
```

```dart
      body: BlocListener<ForestBloc, ForestState>(
        listenWhen: (previous, current) => previous is ForestSuccess && current is ForestInProgress,
        listener: (context, state) => setState(() => _game = _createGame()),
        child: BlocBuilder<ForestBloc, ForestState>(
          buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
          builder: (context, state) => _bodyByState(state),
        ),
      ),
```

- [ ] **Step 5: la escena al cargar** — `ForestSceneComponent._build`, tras la decoración:

```dart
    for (final building in world.buildings) {
      _clearClutterUnder(_building(building));
    }
```

- [ ] **Step 6: Verificar:** `flutter analyze lib` → `No issues found!`; `dart format --line-length 120` sobre los seis ficheros.
- [ ] **Step 7: Commit** — `git add lib`; en otro comando `git commit -m "[PROJECT-F2]: Autosave the forest"`.

---

### Task TF2.6: El menú *Partida*

**Files:**
- Create: `lib/core/assets/images/icons/save.svg`, `lib/layers/presentation/features/forest/widgets/game_panel.dart`
- Modify: `lib/core/config/constants/enum/forest/hud_menu.dart`, `lib/layers/presentation/theme/images/custom_icons.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`, `lib/layers/presentation/features/forest/forest_page.dart`

**Interfaces:**
- Consumes: `ForestSaveRequested`, `ForestNewGameRequested` (TF2.5), `HudButton`, `HudPanel`.
- Produces: `HudMenu.game`; `CustomIcons.save`; `GamePanel({required VoidCallback onSave, required VoidCallback onNewGame})` con `saveKey`, `newGameKey`, `confirmKey`, `cancelKey`; `HudOverlay({…, required VoidCallback onSaveRequested, required VoidCallback onNewGameRequested})`, `HudOverlay.buttonsBelowWidth == 1820`, `narrowWidth == 1100`; `Internationalize.forestGame`, `forestGameSave`, `forestGameNewGame`, `forestGameNewGameConfirm`, `forestGameConfirm`, `forestGameCancel`.

- [ ] **Step 1: icono** — `lib/core/assets/images/icons/save.svg` (fichero nuevo; un disquete 22 × 22 con los colores del HUD):

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
  <path d="M3 4.5A1.5 1.5 0 0 1 4.5 3H15.5L19 6.5V17.5A1.5 1.5 0 0 1 17.5 19H4.5A1.5 1.5 0 0 1 3 17.5Z" fill="#4F7FB8"/>
  <rect x="6.5" y="3" width="8" height="5.5" rx="0.6" fill="#C9CED6"/>
  <rect x="11.5" y="4" width="2" height="3.5" fill="#4F7FB8"/>
  <rect x="6" y="11.5" width="10" height="7.5" rx="0.8" fill="#F2E8D5"/>
  <path d="M8 14H14M8 16.5H14" stroke="#B9A98A" stroke-width="1.2" stroke-linecap="round"/>
</svg>
```

`custom_icons.dart`, tras `workshop`:

```dart
  static const String save = '$_path/save.svg';
```

`hud_menu.dart`:

```diff
-enum HudMenu { quests, build, hero, upgrades }
+enum HudMenu { quests, build, hero, upgrades, game }
```

- [ ] **Step 2: textos** — `es.json`: en `forest.hud`, tras `workshop`, `"game": "Partida"`; el grupo `forest.game` queda:

```json
    "game": {
      "save": "Guardar",
      "saved": "Partida guardada",
      "newGame": "Nueva partida",
      "newGameConfirm": "Se perderá la partida actual. ¿Empezar de nuevo?",
      "confirm": "Empezar",
      "cancel": "Cancelar"
    }
```

`internationalize.dart`, tras `forestWorkshop` (junto a `forestGameSaved`):

```dart
  static String get forestGame => '$_forest.hud.game'.tr();
  static String get forestGameSave => '$_forest.game.save'.tr();
  static String get forestGameNewGame => '$_forest.game.newGame'.tr();
  static String get forestGameNewGameConfirm => '$_forest.game.newGameConfirm'.tr();
  static String get forestGameConfirm => '$_forest.game.confirm'.tr();
  static String get forestGameCancel => '$_forest.game.cancel'.tr();
```

- [ ] **Step 3: el panel** — `lib/layers/presentation/features/forest/widgets/game_panel.dart` (fichero nuevo):

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_button.dart';
import 'hud_panel.dart';

class GamePanel extends StatefulWidget {
  static const Key saveKey = Key('gamePanelSave');
  static const Key newGameKey = Key('gamePanelNewGame');
  static const Key confirmKey = Key('gamePanelConfirm');
  static const Key cancelKey = Key('gamePanelCancel');

  final VoidCallback onSave;
  final VoidCallback onNewGame;

  const GamePanel({super.key, required this.onSave, required this.onNewGame});

  @override
  State<GamePanel> createState() => _GamePanelState();
}

class _GamePanelState extends State<GamePanel> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 340),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Semantics(
                  header: true,
                  child: Text(
                    Internationalize.forestGame.toUpperCase(),
                    style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
                  ),
                ),
              ),
              if (_isConfirming) ..._confirmation() else _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        HudButton(key: GamePanel.saveKey, label: Internationalize.forestGameSave, onPressed: widget.onSave),
        HudButton(
          key: GamePanel.newGameKey,
          label: Internationalize.forestGameNewGame,
          onPressed: () => setState(() => _isConfirming = true),
        ),
      ],
    );
  }

  List<Widget> _confirmation() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          Internationalize.forestGameNewGameConfirm,
          style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          HudButton(key: GamePanel.confirmKey, label: Internationalize.forestGameConfirm, onPressed: widget.onNewGame),
          HudButton(
            key: GamePanel.cancelKey,
            label: Internationalize.forestGameCancel,
            onPressed: () => setState(() => _isConfirming = false),
          ),
        ],
      ),
    ];
  }
}
```

- [ ] **Step 4: el sexto botón** — `hud_overlay.dart` (import `game_panel.dart`):

```diff
-  static const double buttonsBelowWidth = 1700;
+  static const double buttonsBelowWidth = 1820;
```

Parámetros nuevos, tras `onUpgradeSelected`: `final VoidCallback onSaveRequested;` y `final VoidCallback onNewGameRequested;` (y `required this.onSaveRequested, required this.onNewGameRequested,` en el constructor). Botón, tras *Arena*:

```dart
        HudButton(
          label: Internationalize.forestGame,
          icon: CustomIcons.save,
          isActive: _openMenu == HudMenu.game,
          onPressed: () => _toggle(HudMenu.game),
        ),
```

Caso del menú, tras `HudMenu.upgrades`:

```dart
      HudMenu.game => GamePanel(onSave: _onSaveRequested, onNewGame: _onNewGameRequested),
```

Y al final de la clase de estado:

```dart
  void _onSaveRequested() {
    setState(() => _openMenu = null);
    widget.onSaveRequested();
  }

  void _onNewGameRequested() {
    setState(() => _openMenu = null);
    widget.onNewGameRequested();
  }
```

`forest_page.dart`, en `_hudOverlay`:

```dart
      onSaveRequested: () => bloc.add(const ForestSaveRequested()),
      onNewGameRequested: () => bloc.add(const ForestNewGameRequested()),
```

- [ ] **Step 5: Verificar:** `flutter analyze lib` → `No issues found!`; `dart format --line-length 120` sobre los ficheros Dart escritos; `flutter build web --release --base-href /phaser-example/ --dart-define-from-file=lib/core/config/env/production_environment.json` y `flutter build apk --debug` terminan bien.
- [ ] **Step 6: Commit** — `git add lib`; en otro comando `git commit -m "[PROJECT-F2]: Add the game menu"`.

---

### Task TF2.7: Cierre de la fase

- [ ] **Step 1:** añadir a *Para T1* de `docs/boost/plans/2026-10-17-extras/T1-tests.md` el bullet `- **F2** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F2 → `✅`, `feature/PROJECT-F2-autosave`, nota "Bloque 3. Sin tests (T1)."; `README.md`: icono de F2 → ✅; cabecera de este plan con lo implementado y los desvíos.
- [ ] **Step 3:** `CLAUDE.md`: *Layout* de `core` (`config/di/storage_module.dart`) y `data` (`datasources/save`, `repositories/save`, sin `datasources/session`); E5 borrada, E6 y E7 actualizadas (decisión 18); `GameSessionRepositoryImpl` `@LazySingleton` con la sesión viva; `GameSaveRepository`, `SaveGameUseCase`, `NewGameUseCase`, `StartGameUseCase` con el guardado; `World.restore`, `QuestLog.completed`, `Upgrades.maxLevel`, `Rules.autosaveIntervalMs`; `ForestBloc` (cuándo guarda, `ForestPaused` / `ForestSaveRequested` / `ForestNewGameRequested`), `AppLifecycleListener` y el `ForestGame` nuevo en `ForestPage`, `GamePanel`, el sexto botón *Partida* y los umbrales 1820 / 1100; una nota *Save format* (versión 1, qué se guarda, validaciones, subir `SaveDBO.currentVersion` al añadir estado). Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); el commit `[PROJECT-F2]: Close the save game phase` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque de la aldea, en Chrome y Android:

1. Jugar un rato con de todo: talar (tocones y brotes), una roca a medias, el almacén con oro y maná, la carga a medias, una obra a medias y el taller terminado, el hacha de hierro, el héroe con equipo y habilidades mejoradas, niveles de arena ganados y misiones completadas. Cerrar la app (en la web, recargar la pestaña): todo sigue igual (posición del jugador, ids, misiones, insignia `x/19`), el jugador está quieto, la obra a medias conserva su barra y tocándola se retoma; los edificios terminados no tienen barra y no hay decoración debajo de ellos; ningún efecto se reproduce al cargar.
2. Ganar una pelea y cerrar la app justo al volver de la arena: el oro y el nivel superado se conservan.
3. Pasar la app a segundo plano (Android) o cambiar de pestaña (web) y matarla: se conserva lo hecho hasta ese momento.
4. *Partida* (sexto botón, con el disquete) ▸ *Guardar* avisa "Partida guardada" y cierra el panel. *Nueva partida* pide "Se perderá la partida actual. ¿Empezar de nuevo?"; *Cancelar* vuelve a las dos acciones; *Empezar* cierra el panel, vuelve al nivel inicial (solo el campamento, el hacha, el pico en el suelo, 0/19) con el saludo de bienvenida y sin restos de la partida anterior en la escena. Recargar: sigue la partida nueva.
5. Un guardado corrupto (en la web, cambiar a mano `flutter.farming.save` en el *localStorage* por `{`) no rompe la app: empieza de cero y el log dice por qué.
6. HUD: los seis botones caben en la línea de la barra a partir de 1820 px y bajan debajo por debajo; los nombres de la barra se ocultan por debajo de 1100; a 640 px la fila de botones se encoge un poco y la barra cabe.

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F2 (no se ha tocado `test/`). Datos en `test/mocks/**` (p. ej. `SaveDBOMock` y un mock por DBO de pieza, `GameSessionEntityMock` con un mundo que tenga de todo, `SaveJsonMock` con JSON roto, de otra versión y fuera de rango), nunca en línea:

- **Compilación:** `ForestBloc(saveGameUseCase:, newGameUseCase:)` (`forest_bloc_test.dart`, `forest_bloc_mock.dart`, `forest_page_test.dart`); `StartGameUseCase(saveRepository:)` (`start_game_use_case_test.dart`, `forest_bloc_mock.dart`); `HudOverlay(onSaveRequested:, onNewGameRequested:)` (`hud_overlay_test.dart`); `GameSessionRepositoryImpl()` sin datasource ni `AppExceptionHandler` (`game_session_repository_impl_test.dart` y su `.mocks.dart`); `game_session_local_datasource_impl_test.dart` se borra (ya no existe la clase); `di_test.dart`: `await locator.init(...)`, `SharedPreferences.setMockInitialValues({})` antes, sin `GameSessionLocalDatasource`, con `SharedPreferencesWithCache`, `GameSaveLocalDatasource`, `GameSaveRepository`, los doce `Save*MapperDBO`, `SaveGameUseCase` y `NewGameUseCase`, y `GameSessionRepository` como *singleton* (mismo objeto dos veces); `container_app_test.dart`, `forest_page_test.dart` y `arena_page_test.dart` si llaman a `configureDependencies` (necesitan `SharedPreferences.setMockInitialValues`).
- **Dominio:** `world_restore_test.dart` (`World.restore` conserva árboles con golpes y su orden, tocones, rocas, objetos, decoraciones, edificios, héroe, estadísticas, almacén, carga, `toolLevels` y contadores: el siguiente id de un tocón o un edificio sigue la numeración); `quest_log_test.dart` (`completed` y `QuestLog(completed:)`: siguen completadas aunque el mundo ya no las cumpla, no se vuelven a anunciar); `upgrades_test.dart` (`maxLevel` 2 para el hacha y el pico); `save_game_use_case_test.dart`, `new_game_use_case_test.dart` (borra y deja un mundo nuevo con misiones vacías), `start_game_use_case_test.dart` (con guardado usa el guardado, sin él el nivel); `MockGameSaveRepository` con `@GenerateMocks`.
- **Datos:**
  - ida y vuelta `GameSessionEntity` → `SaveDBO` → JSON → `SaveDBO` → `GameSessionEntity` con un mundo que tenga de todo (`SaveMapperDBO`, comparando cada getter de `World` y `QuestLog.completed`);
  - cada `Save*MapperDBO`: `toDBO` / `toEntity` y cada validación de la decisión 5 → `InvalidSaveException` (incluido el recorte de `toolLevels` a `Upgrades.maxLevel` y que no aparecen ceros en `resources`);
  - cada DBO: `fromJson(toJson())` igual, `==` / `hashCode`, `fromJson` con tipos equivocados lanza;
  - `game_save_local_datasource_impl_test.dart` con `SharedPreferences.setMockInitialValues` y `SharedPreferencesWithCache.create`: sin clave `null`, guarda y lee, `clear` borra, JSON roto lanza;
  - `game_save_repository_impl_test.dart`: versión desconocida, JSON roto y datos fuera de rango → `null` sin lanzar y con `Logger.error`; `save` / `clear` que fallan lanzan la `AppException` del `AppExceptionHandler`;
  - `game_session_repository_impl_test.dart`: sin partida `NoGameInProgressException`, `save` y `current` devuelven el mismo objeto.
- **Presentación:** `forest_bloc_test.dart`: guarda tras cada evento importante y no tras los demás, a los 10 000 ms acumulados (no a los 9999) y vuelve a contar, con `ForestPaused`, al comprar equipo / mejora / habilidad con éxito (no al fallar), al volver de la arena (el `push` completa), *Guardar* avisa "Partida guardada" o enseña el pop-up si falla, un autoguardado que falla no avisa; *Nueva partida* emite `ForestInProgress` → `ForestSuccess` con el mundo del nivel, borra el guardado y vuelve a saludar. `game_panel_test.dart` (título, *Guardar* llama a `onSave`, *Nueva partida* enseña la confirmación, *Cancelar* vuelve, *Empezar* llama a `onNewGame`). `hud_overlay_test.dart`: el botón *Partida* sexto abre y cierra el panel, *Guardar* y *Empezar* lo cierran, *Arena* lo cierra; `buttonsBelowWidth` 1820 (tests de 1819 / 1820) y `narrowWidth` 1100. `forest_page_test.dart`: `ForestPaused` con `AppLifecycleState.hidden` / `paused` y un `ForestGame` nuevo tras *Nueva partida*. `forest_scene_component_test.dart`: sin decoración debajo de un edificio que ya está en el primer estado. `custom_icons_test.dart` (`save`), `internationalize_test.dart` (`forest.hud.game`, el grupo `forest.game`, `error.invalidSave*`).

---

## Ficha original

Se conserva tal cual para el historial (las decisiones de arriba mandan).

**Objetivo:** que la partida sobreviva a cerrar la app o la pestaña: se guarda sola y también con un botón *Guardar*, y hay un botón *Nueva partida*. Al ir la última, el formato nace completo en la **versión 1** y ninguna fase anterior lo toca.

**Dominio:** `GameSaveRepository` (`domain/repositories/save/`): `GameSessionEntity? load()`, `void save(GameSessionEntity session)` y `void clear()`, síncrono (E3). `World` gana una *factory* de restauración con todo su estado (árboles con golpes y en orden, tocones, rocas, objetos, edificios con progreso, contadores, estadísticas, almacén y carga ≤ `Rules.carryCapacity`, jugador con herramientas y `toolLevels`, héroe con arma, armadura, `skillLevels`, niveles superados y `fightsFought`); `WorldState` no sale de `domain/world/`. `QuestLog` expone y restaura sus misiones completadas. Casos de uso `SaveGameUseCase`, `NewGameUseCase`; `StartGameUseCase` carga primero el guardado.

**Validar al cargar:** cantidades ≥ 0; tiers dentro del catálogo; niveles de habilidad entre 1 y `maxLevel`; `hitsTaken` de cada roca entre 0 y sus golpes; estadísticas ≥ 0; nivel de herramienta < 1 inválido y sin mejora recortado al máximo de `Upgrades`; una cantera se queda aunque su roca esté rota.

**Datos:** `shared_preferences` en su propio commit; `SharedPreferencesWithCache` en un módulo de DI con `@preResolve`; `data/datasources/save/` con `SaveDBO` (con `version`) y un DBO por pieza, campos anulables, JSON a mano; `GameSaveLocalDatasourceImpl` `@LazySingleton`; enums por `name`; `data/repositories/save/` con `GameSaveRepositoryImpl` y un `*MapperDBO` por pieza, sin cantidades 0; `SaveDBO.currentVersion = 1`, versión desconocida o JSON roto = "no hay partida".

**Cuándo se guarda:** tras talar, terminar un edificio, recoger un objeto, completar una misión, romper una roca, entregar, comprar equipo, mejora o habilidad, y al volver de la arena; cada `Rules.autosaveIntervalMs = 10000`; al pasar a segundo plano (`AppLifecycleListener`, `ForestPaused`).

**Menú *Partida*:** `HudMenu.game` con `save.svg`; *Guardar* (`ForestSaveRequested`, "Partida guardada", pop-up si falla) y *Nueva partida* (`ForestNewGameRequested`, confirmación en el panel). Umbrales del HUD medidos de nuevo. **Escena al cargar:** sin barras en lo terminado, tocones sin crecer, sin efectos. **Textos:** los de la decisión 17.
