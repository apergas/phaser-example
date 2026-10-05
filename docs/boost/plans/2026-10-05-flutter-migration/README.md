# Migración a Flutter — Plan maestro

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement each phase plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Execute the phase documents **in order**; each one leaves the project compiling and its tests green.

**Goal:** Reescribir el proyecto completo (núcleo Kotlin Multiplatform + apps Compose, SwiftUI/SpriteKit y Phaser) como **una sola app Flutter** para Android, iOS y web, con el mismo juego, la misma arquitectura por capas y el mismo arte LPC, y borrar todo el código anterior.

**Architecture:** Proyecto Flutter en la raíz del repo con las convenciones del plugin `flutter-arch-conventions` (v0.0.8): `lib/core/` + `lib/layers/{domain,data,presentation}`, get_it + injectable, BLoC, easy_localization, Page/View. El mundo se dibuja con **Flame** dentro de un `GameWidget`; el HUD son widgets Flutter. El `ForestBloc` es la única fuente de estado de la pantalla (también los ticks del bucle de juego); los casos de uso son **síncronos** porque la simulación avanza por fotograma sin E/S.

**Tech Stack:** Flutter 3.47.x / Dart 3.13.x (stable), flame, flame_bloc, flutter_bloc, bloc, get_it, injectable, easy_localization, flutter_svg (widgets `CustomButton`/`CustomPopUp` de Navify, iconos del HUD), hybrid_logger (`BlocLogger`), collection, meta; dev: build_runner, injectable_generator, mockito, bloc_test, flutter_lints, flame_test.

## Global Constraints

- Dependency rule (plugin `flutter-clean-arch-conventions.md`): `PRESENTATION -> DOMAIN <- DATA`, `CORE` usable by all. Domain imports nothing from `data/` or `presentation/`, nor `package:flutter`, `package:flame`, `dart:ui`, `dart:io`. Data imports only domain and core. Presentation never imports data. Core imports nothing from `layers/` except the documented exceptions (NavigationService/Navify widgets). Checked by `test/architecture_test.dart`.
- Folders kebab-case (`use-cases`, `error-handling`), files snake_case with type suffix (`tree_entity.dart`, `chop_tree_use_case.dart`, `level_local_datasource_impl.dart`, `level_dbo.dart`, `level_mapper_dbo.dart`, `forest_bloc.dart`, `forest_page.dart`).
- Classes PascalCase with suffix: `TreeEntity`, `LevelRepository` / `LevelRepositoryImpl`, `ChopTreeUseCase`, `LevelLocalDatasource` / `LevelLocalDatasourceImpl`, `LevelDBO`, `LevelMapperDBO`, `ForestBloc` / `ForestEvent` / `ForestState`, `ForestPage` / `_ForestView`.
- Entities: only `final` fields, `const` constructor, `copyWith` (nullable fields via `ValueGetter`), computed getters allowed, hand-written `operator ==` / `hashCode` (no `Equatable`, no `freezed`). One entity per file, except sealed hierarchies (Dart requires them in one library).
- Every `enum` lives in `lib/core/config/constants/enum/` (one per file; screen-only enums under `enum/forest/`).
- Use cases: one class per action, `@Injectable()`, single `call()` method, `final class`, constructor `const X({required this._repository})`.
- Repositories catch everything and rethrow `_appExceptionHandler.handle(exception: e, stackTrx: s)`. BLoC catches `AppException`.
- BLoC: events past tense, states nouns, one `on<ForestEvent>` with `await switch (event)`; no `@Injectable()` on the BLoC (registered by hand in DI, see phase 4); Page/View with `_bodyByState` switch expression; snackbars only through `NavigationService` called from the BLoC.
- No comments in `lib/` code (plugin rule 11). Tests may use `// given`, `// when`, `// then`.
- Tests: mirror `lib/` under `test/`; names `testWhen<Action>Then<Result>`; `// given` / `// when` / `// then`; mocks with `mockito` `@GenerateMocks` (generated `*.mocks.dart`); BLoC with `blocTest`; mock data centralised as `static` fields in `test/mocks/**/<name>_mock.dart` (e.g. `TreeEntityMock.mock`), never declared inline in a test body.
- `dart format --line-length 120`; `analysis_options.yaml` exactly as in the plugin (with `prefer_relative_imports`); `flutter analyze` with zero issues at the end of every task.
- Player-facing text only in Spanish and only in `lib/core/assets/i18n/translations/es.json`, read through `Internationalize`. The app name `RPG` is the only per-platform text (`AndroidManifest.xml` label, `Info.plist` `CFBundleDisplayName`, `web/index.html` `<title>` and `web/manifest.json`).
- Ids: Android `applicationId` and iOS bundle id `com.apergas.rpg`; Dart package name `rpg`.
- Versions: newest stable of every package on the day phase 1 runs, written once in `pubspec.yaml` with a caret and never changed afterwards without its own commit. Flutter SDK constraint `sdk: ^3.13.0`.
- LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0: `CREDITS.md` travels with the art and any new asset is credited there.
- Git: branch `feature/PROJECT-X-flutter-migration` (from `develop`). Commits `[PROJECT-X]: Imperative description`. The repo hook rejects any AI attribution: no `Co-Authored-By` for an AI, no Claude/Anthropic mentions. Stage `CLAUDE.md` in its own `git add` command.
- The game must behave exactly as today (same forest, same rules, same texts, same animations and timings) — this is a port, not a redesign. No new mechanics from `docs/GAME_DESIGN.md`.
- Until phase 8 the old projects (`shared/`, `androidApp/`, `iosApp/`, `webApp/`, Gradle files) stay untouched and the existing Pages deploy keeps working; phase 8 replaces and deletes them.

---

## 1. Dónde estamos y dónde queremos llegar

### Hoy

```
phaser-example/
  shared/        Kotlin Multiplatform: domain, data, presentation (ForestViewModel), di (GameContainer), jsMain (web facade)
  androidApp/    Compose + Hilt (solo vistas)
  iosApp/        SwiftUI + SpriteKit (solo vistas)
  webApp/        Vite + Phaser 4 + TypeScript (solo vistas), consume shared como paquete npm
  asset-packs/lpc/build_assets.py  ->  shared/assets/lpc/ (única copia del arte)
  settings.gradle.kts, build.gradle.kts, gradle/, gradlew*, kotlin-js-store/
```

~3.500 líneas de Kotlin (con tests) y ~2.200 entre Compose, Swift y TypeScript. Tests: `shared` (JVM/JS/iOS), Android unit/instrumented, XCTest, Vitest.

### Destino

```
phaser-example/
  pubspec.yaml  analysis_options.yaml  build.yaml
  lib/
    main.dart
    core/
      assets/
        i18n/translations/es.json
        i18n/internationalize.dart
        images/lpc/                     <- arte generado (antes shared/assets/lpc/), CREDITS.md incluido
      config/
        constants/enum/                 TreeKind, DecorationKind, ToolKind, BlueprintId, QuestId, ChopResult,
                                        ConstructionRejection, PlayerActivity, forest/{Facing, WorkTool, QuestItemStatus}
        constants/                      render_constants.dart (zoom, frames, secuencias...)
        di/                             locator.dart, di.dart, di.config.dart (generado), di_environment.dart
      error-handling/exceptions/        custom_exception.dart, app_exceptions.dart
      error-handling/handlers/          app_exception_handler.dart
      services/navigation/              source/navigation_service.dart + implementación (según references/core/navigation_service.md)
      utils/                            seeded_random.dart
    layers/
      domain/
        entities/<feature>/             *_entity.dart
        world/                          World (agregado), WorldState, Work, Navigation, Woodcutting, Construction, pick_up_items
        world/extensions/               operaciones de las entidades (hit, hammer, addWood, walkTo, distanceTo...)
        quests/                         Quest, Quests, QuestLog
        rules/                          Rules, Blueprints
        repositories/{level,session}/   interfaces
        use-cases/game/                 10 casos de uso
      data/
        datasources/level/{source,local,local/dbo}/
        datasources/session/{source,local}/
        repositories/level/{mappers}/, repositories/session/
      presentation/
        app/container_app.dart
        features/forest/
          bloc/                         forest_bloc.dart, forest_event.dart, forest_state.dart
          models/                       modelos de vista (PlayerRenderData, PlayerPose, HudData, ...), ForestEffect
          game/                         Flame: forest_game.dart, components/, atlas/, sprite_names.dart
          widgets/                      HUD
          forest_page.dart
        widgets/                        reutilizables
        theme/                          custom_colors.dart, custom_text_styles.dart
  test/                                 espejo de lib/ + mocks/ + architecture_test.dart
  android/  ios/  web/                  runners generados por flutter create
  asset-packs/lpc/                      build_assets.py (ahora escribe en lib/core/assets/images/lpc/)
  docs/
```

---

## 2. Decisiones de arquitectura

### D1. Convenciones del plugin, con excepciones documentadas (modo pragmático)

Se siguen estructura, nombres, DI, errores, BLoC, Page/View, i18n y tests del plugin `flutter-arch-conventions`. Estas son las **únicas** desviaciones, y cada una se anota también en el `CLAUDE.md` nuevo (fase 8):

| # | Regla del plugin | Excepción | Motivo |
|---|---|---|---|
| E1 | Dominio = entidades + repositorios + casos de uso | Se añaden `domain/world/`, `domain/quests/` y `domain/rules/` | La simulación es un **agregado mutable** (`World`) con sistemas; no es una entidad ni un caso de uso. Ya era así en Kotlin. |
| E2 | Entidades sin lógica | La lógica que hoy tienen (`Tree.hit()`, `Inventory.spendWood()`, `Player.walkTo()`, `Position.distanceTo()`...) pasa a **extensiones** en `domain/world/extensions/`. Las entidades conservan solo getters calculados (`isFelled`, `progress`, `footprint`), que el plugin permite. | Entidades = datos; reglas en dominio. |
| E3 | Casos de uso `Future<T> call()` | `call()` **síncrono** | El bucle de juego avanza por fotograma, sin E/S. Un `Future` por tick desordenaría la simulación. |
| E4 | Enums globales no llegan a las entidades | Las entidades usan los enums de `core/config/constants/enum/` (`TreeKind`, `ToolKind`...) | Sin ellos el dominio tendría que modelar los tipos como `String`. Los enums siguen siendo valores planos. |
| E5 | Datasource local devuelve DBO | `GameSessionLocalDatasource` guarda la `GameSessionEntity` en memoria | La sesión contiene el agregado vivo `World`; serializarlo a DBO por fotograma no tiene sentido. Cuando haya guardado en disco se añadirá un DBO. |
| E6 | Repositorio cache-first local → remoto | No hay remoto: el repositorio lee del datasource local y mapea | No hay backend. |
| E7 | Core completo (network, storage, connection, logging...) | Solo `assets`, `config` (`constants`, `di`, `env`), `error-handling`, `services/{logging,navigation}`, `utils` | Sin red ni persistencia todavía; el plugin dice "no scaffold empty ones speculatively". |
| E8 | Un fichero por clase | Jerarquías `sealed` en un único fichero (`activity_entity.dart`, `intent_entity.dart`, `game_event_entity.dart`, `construction_result_entity.dart`, `player_pose.dart`, `forest_effect.dart`) | Dart obliga a declarar los subtipos de una `sealed class` en la misma librería. |
| E10 | `BlocLogger` registra cada evento y transición | Solo registra `onError` | `ForestTicked` llega 60 veces por segundo y llenaría el log. |
| E11 | Mocks con mockito de las dependencias del BLoC | Los tests del BLoC y de la página usan los casos de uso **reales** sobre `MockLevelRepository` / `MockGameSessionRepository`, y solo mockean `NavigationService` | Los casos de uso son `final class` (plugin) y mockito no puede generar mocks de clases `final` fuera de su librería. Es lo que hacía `ForestViewModelFixture.kt`. |
| E9 | Presentación = bloc + page + widgets | Se añaden `features/forest/models/` (modelos de vista) y `features/forest/game/` (Flame) | El estado de la pantalla tiene tipos propios (pose, HUD, colocación, efectos) y el mundo es un juego Flame, no un árbol de widgets. |

### D2. Flame para el mundo, widgets Flutter para el HUD

- `ForestGame extends FlameGame` (con `flame_bloc`: `FlameBlocProvider<ForestBloc, ForestState>`) dibuja suelo, decoración, árboles, objetos, edificios, jugador, fantasma de colocación y partículas. Cámara con zoom 2 que sigue al jugador y se limita a los bordes del mundo.
- Orden de pintado = `priority` = `y` de la base (pies / tronco), igual que hoy.
- El HUD (madera, hacha, *Construir*, *Misiones*, barra de colocación táctil) son widgets en un `Stack` sobre el `GameWidget`, leídos con `BlocSelector`/`BlocBuilder(buildWhen:)` para no reconstruirse en cada fotograma.
- Los mensajes (bienvenida, "+6 de madera", errores...) son **snackbars** lanzados por el BLoC a través de `NavigationService` (regla del plugin; Android ya usaba snackbar).

### D3. `ForestBloc`: toda la pantalla, también el bucle

- `ForestGame.update(dt)` hace `bloc.add(ForestTicked(deltaMs: dt * 1000))`. Los clics/toques, el puntero, *Construir* y *Cancelar* son también eventos. Un único `on<ForestEvent>` con `await switch (event)`; los handlers son síncronos, así que los eventos se procesan en el orden en que llegan (la vista pinta el estado del tick anterior: ≤1 fotograma de retardo, igual en todas las plataformas).
- El estado (`ForestSuccess`) lleva `ForestData`: `world` (instantánea), `player` (pose, orientación, posición), `hud`, `placement` y `effects` (efectos producidos por **ese** evento; el juego los reproduce al recibir cada estado y no se repiten porque cada emisión trae su propia lista).
- Lo que hacía `ForestViewModel` (qué significa un clic, modo colocación, orientación del personaje, qué mensaje y qué efecto produce cada `GameEvent`) se porta tal cual al BLoC, con los mismos tests.

### D4. DI con get_it + injectable

`@Injectable(as: Interface)` para datasources y repositorios, `@LazySingleton(as: ...)` para la sesión en memoria (una sola partida por app, como el `GameContainer`), `@Injectable()` para casos de uso, mappers y `AppExceptionHandler`. El `ForestBloc` **no se registra en DI** (`references/presentation/bloc.md`): `ForestPage` lo crea en `BlocProvider.create` con `locator.get<T>()` de los 10 casos de uso y de `NavigationService`, y le añade `ForestStarted()`. `configureDependencies({required String environment})` es asíncrona y `main.dart` la espera.

### D5. Arte: el mismo pipeline, otra carpeta

`asset-packs/lpc/build_assets.py` cambia solo su `OUT` a `lib/core/assets/images/lpc/`. El contenido (`forest.png` + `forest.json` en formato JSON-hash con `pivot`, `ground.png`, `hero-*.png`) no cambia. Flame se configura con `images.prefix = 'lib/core/assets/images/'`. `forest.json` se lee con un parser propio pequeño (`LpcAtlas`) que respeta `pivot`, como hacían Android e iOS.

### D6. Mismas constantes de render en todas partes

Zoom 2; frames de personaje LPC de 64 px, filas `up, left, down, right`; andar columnas 1–8 a 10 fps; reposo 2 columnas a 2 fps; hojas de trabajo de 128 px con secuencias talar `[0,0,5,5,4,4,3,1]` y martillar `[0,0,5,5,4,4,1]`, fotograma elegido por `swingProgress` para que el impacto coincida con el golpe; casa dibujada 24 px por debajo del centro de su huella; toque de árbol con precisión de píxel (alfa de la textura). Todo en `lib/layers/presentation/features/forest/game/render/render_constants.dart`.

### D7. Coordenadas

El dominio es Y-abajo en unidades de mundo = píxeles nativos LPC. Flame también es Y-abajo: **no hay conversión** (desaparece `ScenePoint`).

### D8. El bosque es idéntico

`SeededRandom` (LCG `state = (state * 1664525 + 1013904223) & 0xFFFFFFFF`) se porta a Dart. El producto máximo (~7,1e15) cabe en 2^53, así que da los mismos valores en Dart nativo y en Dart web (JS). Los tests de valores dorados de Kotlin (`SeededRandomTests`, `LevelLocalDataSourceImplTests`) se portan con los mismos números.

### D9. Despliegue web

GitHub Pages sigue publicando en https://apergas.github.io/phaser-example/: `flutter build web --release --base-href /phaser-example/`. El workflow nuevo (fase 8) ejecuta `flutter analyze`, `flutter test` y el build. Android e iOS se prueban en local.

---

## 3. Contratos entre fases

Cada fase solo ve su documento: estos nombres y firmas son **el contrato** y no se cambian sin actualizar todas las fases.

### 3.1 Enums (`lib/core/config/constants/enum/`)

```dart
enum TreeKind { slim, round, wide, broad, twisted, branches, leaning, lumpy, pine, dome, oak, dense, old, big }   // tree_kind.dart (order matters: the level generator indexes it)
enum DecorationKind { tallGrass, leaves, mushrooms, rock }                                                       // decoration_kind.dart
enum ToolKind { axe }                                                                                            // tool_kind.dart
enum BlueprintId { house }                                                                                       // blueprint_id.dart
enum QuestId { pickUpAxe, gatherWood, buildHouse }                                                               // quest_id.dart
enum ChopResult { ok, noAxe, unknownTree }                                                                       // chop_result.dart
enum ConstructionRejection { notEnoughWood, blocked }                                                            // construction_rejection.dart
enum PlayerActivity { idle, walking, chopping, constructing }                                                    // player_activity.dart
enum Facing { up, left, down, right }                                                                            // forest/facing.dart
enum WorkTool { axe, hammer }                                                                                    // forest/work_tool.dart
enum QuestItemStatus { done, current, pending }                                                                  // forest/quest_item_status.dart
enum PlayerSheet { walk, idle, walkAxe, idleAxe, chop, hammer }                                                                                    // forest/player_sheet.dart (fase 6: hojas LPC del jugador)
enum ParticleKind { woodChip, dust }                                                                                    // forest/particle_kind.dart (fase 6)
enum HudMenu { quests, build }                                                                                    // forest/hud_menu.dart (fase 7: menú abierto del HUD)
```

### 3.2 Entidades (`lib/layers/domain/entities/`)

| Fichero | Clase | Campos (todos `final`) | Getters |
|---|---|---|---|
| `geometry/position_entity.dart` | `PositionEntity` | `double x, y` | — |
| `geometry/obstacle_entity.dart` | `ObstacleEntity` | `PositionEntity position, double radius` (assert `radius > 0`) | — |
| `tree/tree_entity.dart` | `TreeEntity` | `String id, TreeKind kind, PositionEntity position, double trunkRadius, int woodYield, int hitsToFell, int hitsTaken = 0` (asserts `woodYield >= 0`, `hitsToFell > 0`) | `footprint`, `hitsRemaining`, `isFelled` |
| `item/ground_item_entity.dart` | `GroundItemEntity` | `String id, ToolKind kind, PositionEntity position` | — |
| `decoration/decoration_entity.dart` | `DecorationEntity` | `String id, DecorationKind kind, PositionEntity position` | — |
| `building/blueprint_entity.dart` | `BlueprintEntity` | `BlueprintId id, int woodCost, int hitsToBuild, double footprintRadius` | — |
| `building/building_entity.dart` | `BuildingEntity` | `String id, BlueprintEntity blueprint, PositionEntity position, int hitsDone = 0` | `footprint`, `progress`, `isComplete` |
| `player/inventory_entity.dart` | `InventoryEntity` | `int wood = 0, Set<ToolKind> tools = const {}` | — |
| `player/player_entity.dart` | `PlayerEntity` | `PositionEntity position, double speed, double radius, InventoryEntity inventory = const InventoryEntity(), ActivityEntity activity = const IdleActivityEntity()` (asserts `speed > 0`, `radius > 0`) | `isMoving` |
| `player/activity_entity.dart` | `sealed class ActivityEntity` → `IdleActivityEntity()`, `WalkingActivityEntity(destination, IntentEntity? intent)`, `WorkingActivityEntity(IntentEntity intent, double elapsedMs)` | | |
| `player/intent_entity.dart` | `sealed class IntentEntity` → `ChopIntentEntity(String treeId)`, `ConstructIntentEntity(String buildingId)` | | |
| `game/game_event_entity.dart` | `sealed class GameEventEntity` → `ItemPickedUpEventEntity(itemId, ToolKind kind)`, `PlayerBlockedEventEntity()`, `TreeHitEventEntity(treeId, int hitsRemaining)`, `TreeFelledEventEntity(treeId, int wood)`, `BuildingHammeredEventEntity(buildingId, double progress)`, `BuildingCompletedEventEntity(buildingId, BlueprintId blueprint)`, `QuestCompletedEventEntity(QuestId questId)` | | |
| `game/construction_result_entity.dart` | `sealed class ConstructionResultEntity` → `ConstructionStartedEntity(BuildingEntity building)`, `ConstructionRejectedEntity(ConstructionRejection reason)` | | |
| `game/build_option_entity.dart` | `BuildOptionEntity` | `BlueprintId blueprint, int woodCost, bool isAffordable` | — |
| `game/player_status_entity.dart` | `PlayerStatusEntity` | `PositionEntity position, PlayerActivity activity, PositionEntity? target, double swingProgress, int wood, bool hasAxe` | — |
| `game/quest_progress_entity.dart` | `QuestProgressEntity` | `QuestId id, int progress, int target, bool isCompleted, bool isCurrent` | — |
| `game/world_snapshot_entity.dart` | `WorldSnapshotEntity` | `double width, height, List<TreeEntity> trees, List<GroundItemEntity> items, List<DecorationEntity> decorations, List<BuildingEntity> buildings` | — |
| `game/game_session_entity.dart` | `GameSessionEntity` | `World world, QuestLog quests` | — |

Constructores con parámetros con nombre (`required`), `const` donde Dart lo permita, `==`/`hashCode` escritos a mano (listas y conjuntos con `ListEquality`/`SetEquality` de `package:collection`).

### 3.3 Reglas del dominio (`lib/layers/domain/`)

```dart
// rules/rules.dart
abstract final class Rules {
  static const int hitsToFellTree = 5;
  static const double chopIntervalMs = 750;
  static const double hammerIntervalMs = 650;
  static const double workGap = 2;
  static const double pickUpRange = 14;
  static const double playerSpeed = 110;
  static const double playerRadius = 8;
  static const double treeTrunkRadius = 12;
}

// rules/blueprints.dart
abstract final class Blueprints {
  static const BlueprintEntity house = BlueprintEntity(id: BlueprintId.house, woodCost: 15, hitsToBuild: 8, footprintRadius: 40);
  static const List<BlueprintEntity> all = [house];
  static BlueprintEntity of(BlueprintId id);
}

// world/extensions/*.dart
extension PositionGeometry on PositionEntity { double distanceTo(PositionEntity other); PositionEntity moveTowards(PositionEntity target, double maxStep); PositionEntity pointAtDistance(double distance, PositionEntity towards); }
extension ObstacleRules on ObstacleEntity { bool blocks(PositionEntity position, double radius); }
extension TreeRules on TreeEntity { TreeEntity hit(); }
extension BuildingRules on BuildingEntity { BuildingEntity hammer(); }
extension InventoryRules on InventoryEntity { InventoryEntity addWood(int amount); InventoryEntity? spendWood(int amount); InventoryEntity addTool(ToolKind tool); bool hasTool(ToolKind tool); }
extension PlayerRules on PlayerEntity { PlayerEntity walkTo(PositionEntity destination, {IntentEntity? intent}); PlayerEntity startWork(IntentEntity intent); PlayerEntity continueWork(double elapsedMs); PlayerEntity stop(); PositionEntity? nextPosition(double deltaMs); PlayerEntity placeAt(PositionEntity position); PlayerEntity withInventory(InventoryEntity inventory); }

// world/world.dart
class World {
  World({required double width, required double height, required PlayerEntity player, required List<TreeEntity> trees, List<GroundItemEntity> items = const [], List<DecorationEntity> decorations = const []});
  double get width; double get height; PlayerEntity get player;
  List<TreeEntity> get trees; List<GroundItemEntity> get items; List<DecorationEntity> get decorations; List<BuildingEntity> get buildings; List<ObstacleEntity> get obstacles;
  double get workProgress; PositionEntity? get playerTarget;
  void movePlayerTo(PositionEntity destination);
  ChopResult orderChop(String treeId);
  ConstructionResultEntity orderConstruction(BlueprintEntity blueprint, PositionEntity position);
  bool canPlace(BlueprintEntity blueprint, PositionEntity position);
  List<GameEventEntity> advance(double deltaMs);
  @visibleForTesting void updatePlayer(PlayerEntity Function(PlayerEntity player) transform);
}

// quests/quest.dart, quests.dart, quest_log.dart
abstract interface class Quest { QuestId get id; int get target; int progress(World world); }
abstract final class Quests { static final List<Quest> all; }
class QuestLog { QuestLog({List<Quest>? quests}); List<QuestCompletedEventEntity> update(World world); List<QuestProgressEntity> status(World world); }

// repositories/level/level_repository.dart
abstract interface class LevelRepository { World load(); }
// repositories/session/game_session_repository.dart
abstract interface class GameSessionRepository { GameSessionEntity current(); void save(GameSessionEntity session); }
```

### 3.4 Errores (`lib/core/error-handling/`)

`CustomException<T>` y `sealed class AppException<T> extends CustomException<T>` como en `references/core/core.md`, con estos casos (todos `final class`, `title`/`message` desde `Internationalize`):

```dart
GenericException()                                   // anything unexpected
InvalidLevelException({required String data})        // data = reason, e.g. "missing width"
UnknownTreeKindException({required String data})     // data = 'tree-3: "palm"'
UnknownDecorationKindException({required String data})
UnknownItemKindException({required String data})
NoGameInProgressException()                          // session read before StartGameUseCase
```

`AppExceptionHandler.handle({required Object? exception, StackTrace? stackTrx})`: si ya es `AppException` la devuelve; si no, `GenericException()`.

### 3.5 Datos (`lib/layers/data/`) y utilidades

```dart
// core/utils/seeded_random.dart
class SeededRandom { SeededRandom(int seed); double next(); }

// core/utils/kebab_case.dart  (fase 3; la reutiliza SpriteNames en la fase 6)
extension KebabCase on String { String toKebabCase(); }

// datasources/level/source/level_local_datasource.dart
abstract interface class LevelLocalDatasource { LevelDBO fetch(); }
// datasources/level/local/level_local_datasource_impl.dart   @Injectable(as: LevelLocalDatasource)
// datasources/level/local/dbo/{level_dbo, point_dbo, tree_dbo, item_dbo, decoration_dbo}.dart   all fields nullable
class LevelDBO { final double? width, height; final PointDBO? playerStart; final List<TreeDBO>? trees; final List<ItemDBO>? items; final List<DecorationDBO>? decorations; }
class PointDBO { final double? x, y; }
class TreeDBO { final String? id, kind; final double? x, y; final int? wood; }
class ItemDBO { final String? id, kind; final double? x, y; }
class DecorationDBO { final String? id, kind; final double? x, y; }

// datasources/session/source/game_session_local_datasource.dart
abstract interface class GameSessionLocalDatasource { GameSessionEntity? get(); void set(GameSessionEntity session); }
// datasources/session/local/game_session_local_datasource_impl.dart   @LazySingleton(as: GameSessionLocalDatasource)

// repositories/level/mappers/*.dart   @Injectable(), injected into the repository
class LevelMapperDBO { World toEntity(LevelDBO dbo); }   // uses the mappers below
class PositionMapperDBO { PositionEntity toEntity(PointDBO dbo); }
class TreeMapperDBO { TreeEntity toEntity(TreeDBO dbo, {required int index}); }
class DecorationMapperDBO { DecorationEntity toEntity(DecorationDBO dbo, {required int index}); }
class GroundItemMapperDBO { GroundItemEntity toEntity(ItemDBO dbo); }
// repositories/level/level_repository_impl.dart       @Injectable(as: LevelRepository)
// repositories/session/game_session_repository_impl.dart  @Injectable(as: GameSessionRepository)
```

### 3.6 Casos de uso (`lib/layers/domain/use-cases/game/`)

| Fichero | Clase | `call` |
|---|---|---|
| `start_game_use_case.dart` | `StartGameUseCase` | `void call()` |
| `move_player_use_case.dart` | `MovePlayerUseCase` | `void call({required double x, required double y})` |
| `chop_tree_use_case.dart` | `ChopTreeUseCase` | `ChopResult call({required String treeId})` |
| `can_place_building_use_case.dart` | `CanPlaceBuildingUseCase` | `bool call({required BlueprintId blueprint, required double x, required double y})` |
| `construct_building_use_case.dart` | `ConstructBuildingUseCase` | `ConstructionResultEntity call({required BlueprintId blueprint, required double x, required double y})` |
| `advance_game_use_case.dart` | `AdvanceGameUseCase` | `List<GameEventEntity> call({required double deltaMs})` (eventos del mundo + misiones completadas) |
| `get_player_status_use_case.dart` | `GetPlayerStatusUseCase` | `PlayerStatusEntity call()` |
| `get_world_snapshot_use_case.dart` | `GetWorldSnapshotUseCase` | `WorldSnapshotEntity call()` |
| `get_build_options_use_case.dart` | `GetBuildOptionsUseCase` | `List<BuildOptionEntity> call()` |
| `get_quests_use_case.dart` | `GetQuestsUseCase` | `List<QuestProgressEntity> call()` |

### 3.7 Presentación (`lib/layers/presentation/features/forest/`)

```dart
// bloc/forest_event.dart  (part of forest_bloc.dart)
sealed class ForestEvent {}
final class ForestStarted extends ForestEvent {}
final class ForestTicked extends ForestEvent { final double deltaMs; }
final class ForestMapClicked extends ForestEvent { final PositionEntity position; final String? treeId; final bool isSecondary; }   // isSecondary defaults to false
final class ForestPointerMoved extends ForestEvent { final PositionEntity position; }
final class ForestBuildRequested extends ForestEvent { final BlueprintId blueprint; }
final class ForestPlacementCancelled extends ForestEvent {}

// bloc/forest_state.dart  (part of forest_bloc.dart)
class ForestData { final WorldSnapshotEntity? world; final PlayerRenderData? player; final HudData? hud; final PlacementData? placement; final List<ForestEffect> effects; ForestData copyWith(...); }
sealed class ForestState { final ForestData data; const ForestState({required this.data}); }   // ForestData: todos los campos opcionales, effects = const []
final class ForestInitial extends ForestState { const ForestInitial() : super(data: const ForestData()); }
final class ForestInProgress extends ForestState { const ForestInProgress({required super.data}); }
final class ForestSuccess extends ForestState { const ForestSuccess({required super.data}); }
final class ForestFailure extends ForestState { final CustomException exception; const ForestFailure({required super.data, required this.exception}); }

// models/
class PlayerRenderData { final PositionEntity position; final Facing facing; final PlayerPose pose; }          // player_render_data.dart
sealed class PlayerPose {} -> IdlePose(bool withAxe), WalkPose(bool withAxe), WorkPose(WorkTool tool, double swingProgress)   // player_pose.dart
class HudData { final int wood; final bool hasAxe; final String questBadge; final List<QuestItemData> quests; final List<BuildItemData> buildItems; final bool isBuildLocked; }   // hud_data.dart
class QuestItemData { final String title; final String progressText; final QuestItemStatus status; }         // quest_item_data.dart
class BuildItemData { final BlueprintId blueprint; final String name; final String costText; final String? missingText; final bool isEnabled; }   // build_item_data.dart
class PlacementData { final BlueprintId blueprint; final PositionEntity position; final bool isValid; }       // placement_data.dart
sealed class ForestEffect {} -> ItemPickedUpEffect(itemId), TreeHitEffect(treeId, double fromX), TreeFelledEffect(treeId, double fromX), BuildingPlacedEffect(BuildingEntity building), BuildingHammeredEffect(buildingId, double progress), BuildingCompletedEffect(buildingId)   // forest_effect.dart
```

Todos los modelos con `==`/`hashCode` escritos a mano (los `buildWhen` del HUD y los tests los necesitan).

`ForestBloc({required StartGameUseCase, MovePlayerUseCase, ChopTreeUseCase, CanPlaceBuildingUseCase, ConstructBuildingUseCase, AdvanceGameUseCase, GetPlayerStatusUseCase, GetWorldSnapshotUseCase, GetBuildOptionsUseCase, GetQuestsUseCase, NavigationService})`.

`SpriteNames` (`game/atlas/sprite_names.dart`): `static String tree(TreeKind kind)` → `tree-<kebab>`; `static String decoration(DecorationKind kind)` → `decor-<kebab>`.

---

## 4. Fases

Orden obligatorio: cada una consume lo que produjo la anterior.

| # | Documento | Entrega | Comprobación de cierre |
|---|---|---|---|
| 1 | [`01-project-and-core.md`](01-project-and-core.md) | Proyecto Flutter en la raíz junto al código viejo; `pubspec.yaml`, `analysis_options.yaml`, core (DI, errores, navegación, i18n, `SeededRandom`), arte copiado a `lib/core/assets/images/lpc/` (la copia vieja sigue hasta la fase 8) y `build_assets.py` escribiendo en ambas, `ContainerApp` + `main.dart` con pantalla vacía, test de arquitectura | `flutter analyze` limpio, `flutter test` verde, app vacía arranca en web |
| 2 | [`02-domain.md`](02-domain.md) | Enums, entidades, extensiones, `World` y sistemas, misiones, reglas, interfaces de repositorio | tests de dominio portados verdes |
| 3 | [`03-data.md`](03-data.md) | DBOs, generador de nivel, mappers, repositorios de nivel y sesión; bosque idéntico (valores dorados) | `flutter test test/layers/data` verde |
| 4 | [`04-use-cases-and-di.md`](04-use-cases-and-di.md) | 10 casos de uso, registro DI completo (`di.config.dart` generado) | tests de casos de uso + test de DI verdes |
| 5 | [`05-forest-bloc.md`](05-forest-bloc.md) | `ForestBloc`, eventos, estado, modelos, efectos, `es.json` + `Internationalize` del juego | `blocTest` portados de `ForestViewModelTests` verdes |
| 6 | [`06-flame-world.md`](06-flame-world.md) | `ForestGame` y componentes Flame (atlas, suelo, decoración, árboles con toque por píxel, objetos, edificios por fases, jugador animado, fantasma, partículas, cámara) | tests de componentes/atlas verdes; mundo visible y jugable con ratón en web |
| 7 | [`07-hud-and-page.md`](07-hud-and-page.md) | `ForestPage`/`_ForestView`, HUD, barra de colocación, snackbars, entrada táctil y de ratón (clic derecho / Esc) | widget tests verdes; las 3 misiones completadas en web, Android (emulador) e iOS (simulador) |
| 8 | [`08-platforms-ci-cleanup.md`](08-platforms-ci-cleanup.md) | Runners (nombre, ids, iconos, orientación), workflow de Pages con Flutter, borrado de `shared/`, `androidApp/`, `iosApp/`, `webApp/`, Gradle, `kotlin-js-store/`; README, `CLAUDE.md`, `.gitignore`, memoria del plan | CI verde y Pages desplegado tras merge a `main`; repo sin restos de KMP |

---

## 5. Mapa de ficheros Kotlin / apps → Flutter

| Hoy | Flutter | Fase |
|---|---|---|
| `shared/.../domain/entities/**` | `lib/layers/domain/entities/**` (`*_entity.dart`) + enums en `lib/core/config/constants/enum/` | 2 |
| métodos de entidades (`hit`, `spendWood`, `walkTo`, `distanceTo`...) | `lib/layers/domain/world/extensions/*.dart` | 2 |
| `shared/.../domain/world/*.kt` | `lib/layers/domain/world/*.dart` | 2 |
| `shared/.../domain/quests/*.kt` | `lib/layers/domain/quests/*.dart` | 2 |
| `shared/.../domain/rules/Rules.kt`, `Blueprints` | `lib/layers/domain/rules/rules.dart`, `blueprints.dart` | 2 |
| `shared/.../domain/errors/AppError.kt`, `ErrorHandler.kt`, `data/errors/DataErrorHandlerImpl.kt` | `lib/core/error-handling/exceptions/app_exceptions.dart`, `handlers/app_exception_handler.dart` | 1 (base), 3 (casos de nivel) |
| `shared/.../domain/repositories/**` | `lib/layers/domain/repositories/**` | 2 |
| `shared/.../util/SeededRandom.kt` | `lib/core/utils/seeded_random.dart` | 1 |
| `shared/.../data/datasources/local/level/**` (+ `dto/`) | `lib/layers/data/datasources/level/{source,local,local/dbo}/` | 3 |
| `shared/.../data/datasources/local/session/**` | `lib/layers/data/datasources/session/{source,local}/` | 3 |
| `shared/.../data/repositories/level/LevelMappers.kt` | `lib/layers/data/repositories/level/mappers/*_mapper_dbo.dart` | 3 |
| `shared/.../data/repositories/**Impl.kt` | `lib/layers/data/repositories/**_repository_impl.dart` | 3 |
| `shared/.../domain/usecases/game/GameUseCase(Impl).kt` | 10 ficheros en `lib/layers/domain/use-cases/game/` | 4 |
| `shared/.../di/GameContainer.kt`, `androidApp/.../di/GameModule.kt` | `lib/core/config/di/*` (injectable) | 1, 4 |
| `shared/.../presentation/forest/ForestContract.kt`, `ForestViewModel.kt` | `lib/layers/presentation/features/forest/bloc/*`, `models/*` | 5 |
| `shared/.../presentation/forest/ForestLabels.kt` | `lib/core/assets/i18n/translations/es.json` + `lib/core/assets/i18n/internationalize.dart` | 5 |
| `shared/.../presentation/forest/SpriteNames.kt` | `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart` | 6 |
| `androidApp/.../world/*`, `iosApp/.../World/*`, `webApp/src/presentation/**/world/*View.ts`, `player/PlayerView.ts` | `lib/layers/presentation/features/forest/game/**` (Flame) | 6 |
| `androidApp/.../components/HudOverlay.kt`, `webApp/src/presentation/**/hud/*`, `iosApp/.../ForestView.swift` | `lib/layers/presentation/features/forest/widgets/*`, `forest_page.dart` | 7 |
| `androidApp/.../MainActivity.kt`, navegación, `iosApp/iosApp/*App.swift`, `webApp/src/main.ts` | `lib/main.dart`, `lib/layers/presentation/app/container_app.dart` | 1, 7 |
| `shared/src/jsMain/**` (fachada web) | — (desaparece) | 8 |
| `shared/src/androidHostTest/.../ArchitectureTests.kt`, `webApp/tests/architecture.test.ts` | `test/architecture_test.dart` | 1 (y se amplía en 2–7) |
| `shared/src/commonTest/**` | `test/layers/**` + `test/mocks/**` | 2–5 |
| `.github/workflows/deploy.yml` | mismo fichero, pasos de Flutter | 8 |

---

## 6. Riesgos y cómo se mitigan

| Riesgo | Mitigación |
|---|---|
| El BLoC procesa eventos de forma asíncrona y el tick se desordena | Handlers síncronos dentro de un único `on<ForestEvent>`: el orden de `add` se conserva. Test `blocTest` que encadena `ForestMapClicked` + varios `ForestTicked` y comprueba la posición final. |
| Reconstruir el HUD 60 veces por segundo | `BlocSelector` / `buildWhen` comparando `HudData` (con `==` a mano). El mundo Flame no reconstruye widgets. |
| Arte borroso al escalar | `Paint()..filterQuality = FilterQuality.none` en todos los sprites; zoom entero (2). |
| El bosque cambia por diferencias numéricas | Tests dorados de `SeededRandom` y del generador ejecutados también en Chrome: `flutter test --platform chrome test/core/utils test/layers/data`. |
| Toque por píxel lento | Se lee el alfa de `forest.png` una vez (`Image.toByteData`) y se consulta por coordenada; solo para árboles bajo el punto. |
| Flutter web pesa más que Phaser | Aceptado (decisión del equipo). `--release` + `--wasm` si el renderer lo permite sin romper el toque por píxel; si no, CanvasKit. |
| Se pierde paridad visual | La fase 6 compara capturas de la web Phaser actual (antes de borrarla, en local) con la versión Flame: mismas posiciones, mismos sprites, mismo orden. |

---

## 7. Desviaciones encontradas al ejecutar

Conocidas al escribir el plan (se confirman o corrigen al ejecutar):

- Textos: los getters de `Internationalize` con parámetros usan argumentos con nombre (`forestCost(wood:)`, `forestBlueprint(id:)`, `forestQuestTitle(id:)`...). Nuevo texto `forest.retry` = "Reintentar" para la pantalla de error al cargar el nivel (antes no existía esa pantalla).
- Solo `es` (el plugin propone `es` + `en`). Orientación: no se fuerza vertical como en `gen-main`; se mantiene la de las apps actuales, apaisado en móvil (Android `userLandscape`, iOS landscape left/right), configurada en los runners en la fase 8.
- `ContainerAppBloc` recibe `NavigationService` en la fase 7 y navega con `pushReplacement(const ForestPage())`.
- Fase 6 (sigue a la web publicada cuando las apps difieren): barra de progreso y rebote de la casa, hacha flotando con sombra, curvas de árbol y cámara con lerp 0,1 de la web; la decoración bajo la casa se limpia con el rectángulo del sprite (como la web). Nuevo: `dt` limitado a 100 ms por fotograma y arrastre táctil del fantasma durante la colocación.
- `RenderConstants` gana `cameraLerp`, `maxFrameSeconds`, `backgroundColor` y `solidAlpha` en la fase 6.
- Dart no tiene `hypot`: `sqrt(dx*dx + dy*dy)`; los tests dorados confirman que el bosque no cambia.
- `di.config.dart` y `*.mocks.dart` se versionan; la CI ejecuta `build_runner` igualmente. No hay `build.yaml`.

Durante la ejecución: cada desviación nueva del plan, con su motivo y el commit.

- Fase 1, tarea 1: `analysis_options.yaml` = el del plugin + `build/**`, `android/**`, `ios/**`, `web/**` en `analyzer.exclude`. Flutter 3.47 las vuelve a añadir en cada `flutter pub get` / `flutter analyze`; decidido aceptarlas (esas carpetas no tienen Dart).
- Fase 1, tarea 5: contraste de `CustomButtonColor` corregido respecto al plugin (deshabilitado = `foreground` al 50 %, `warning` con texto negro) — decisión del usuario, commit `8eead64`. `CustomButtonColor`, `CustomButtonSize` y `ActionsDirection` siguen junto a sus widgets, como en el ejemplo del plugin (son enums con colores/tamaños, no valores planos).
- Fase 1, tarea 7: `NavifyImpl.showSnackbar` añade `behavior: SnackBarBehavior.floating`; la referencia del plugin pone `margin` sin él y Flutter lanza la aserción "Margin can only be used with floating behavior" (commit `46aa16b`).
- Fase 2, tarea 9: la regex de campos no `final` de `domain_architecture_test.dart` no detectaba campos con inicializador (`int counter = 0;`); se cambió por `^  (?![ })\]])(?!final |static |const )(?!.*(\(|=>)).*;$` (commit `37a6379`).
- Fase 2 (revisión de arquitectura): `LevelRepository.load()` devuelve el agregado `World` y `GameSessionEntity` contiene `World` y `QuestLog` (agregados mutables, no entidades planas): forma parte de E1/E5. Las validaciones de constructor de las entidades son `assert` (invariantes en debug; los datos vienen del generador propio).
- Fase 5: los modelos de vista se prueban con datos de `test/mocks/presentation/features/forest/` (sin carpeta `models/`; regla del usuario de no declarar datos en los tests); `HudDataMock` vive ahí. Los mocks generados (`*.mocks.dart`) se commitean tal como los escribe `build_runner`, sin `dart format` (commit `a23295a`).
- Fase 6 (aislamiento del motor, decisión del usuario): `package:flame`/`flame_bloc` solo se permiten en `features/forest/game/` y `forest_page.dart` (regla en `architecture_test.dart`); `RenderConstants` pasa de `core/config/constants/` a `features/forest/game/render/` (es del arte LPC); `CameraFraming` deja de usar `Vector2`. Los enums `PlayerSheet`/`ParticleKind` siguen en `core/config/constants/enum/forest/` (regla del plugin).
