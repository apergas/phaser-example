# Fase 4 — Casos de uso y DI completa

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar `GameUseCase` / `GameUseCaseImpl` de Kotlin a diez casos de uso Dart (uno por acción) con sus tests, y cerrar el grafo de dependencias con injectable para que la pantalla (fase 5) pueda pedir cada caso de uso al `locator`.

**Architecture:** Cada caso de uso es una `final class` `@Injectable()` con un único `call()` **síncrono** (excepción E3 del README) que trabaja sobre la `GameSessionEntity` que devuelve `GameSessionRepository.current()`; `StartGameUseCase` es el único que usa `LevelRepository`. Los repositorios y datasources de la fase 3 ya están anotados; aquí se regenera `di.config.dart` y se comprueba con un test que todos los casos de uso comparten la misma partida (la sesión es `@LazySingleton`). El `ForestBloc` **no** se registra en DI: lo crea `ForestPage` en `BlocProvider.create` con `locator.get<T>()` (regla de `references/presentation/bloc.md`).

**Tech Stack:** Dart 3.13, injectable + get_it (build_runner), flutter_test, mockito (`@GenerateMocks`).

## Global Constraints

Todas las de [`README.md`](README.md) § Global Constraints, y además:

- Contrato de esta fase: README §3.6 (nombres de fichero, clases y firmas de `call`). Consume README §3.1–§3.5 tal cual los dejaron las fases 1–3.
- Casos de uso: `@Injectable()`, `final class`, constructor `const X({required this._repository})` (Dart ≥ 3.12, como el ejemplo del plugin), un solo método público `call()`, sin mapeos ni comentarios.
- Ningún caso de uso captura excepciones: los repositorios ya lanzan `AppException` (`NoGameInProgressException`, `InvalidLevelException`...), y el BLoC las captura en la fase 5.
- Tests en `test/layers/domain/use-cases/game/`, un fichero por caso de uso (más un fichero de flujo completo), nombres `testWhen<Action>Then<Result>`, `// given` / `// when` / `// then`.
- Datos de prueba solo en `test/mocks/**`: los cuerpos de los tests no construyen entidades ni mundos; si falta una variante, se añade al fichero de mocks.
- Mocks de repositorio generados con mockito en un único fichero `test/mocks/domain/repositories/repository_mocks.dart` (`@GenerateMocks([LevelRepository, GameSessionRepository])`).
- `flutter analyze` sin incidencias y `flutter test` verde al cerrar cada tarea.

## Lo que esta fase da por hecho (fases 1–3)

| Pieza | Ruta | Fase |
|---|---|---|
| `locator`, `configureDependencies({required String environment})`, `DiEnvironment` | `lib/core/config/di/{locator,di,di_environment}.dart` | 1 |
| `NavigationService` registrado con su anotación de DI | `lib/core/services/navigation/` | 1 |
| `AppException` y casos, `AppExceptionHandler` | `lib/core/error-handling/` | 1, 3 |
| Enums | `lib/core/config/constants/enum/` | 1–2 |
| Entidades, `World`, `QuestLog`, `Blueprints`, extensiones (`inventory_rules.dart` con `InventoryRules`, etc.) | `lib/layers/domain/` | 2 |
| `LevelRepository`, `GameSessionRepository` | `lib/layers/domain/repositories/` | 2 |
| Datasources, mappers y repositorios anotados (`@Injectable(as:)`, sesión `@LazySingleton(as:)`) | `lib/layers/data/` | 3 |
| Mocks de entidades y mundo: `PlayerEntityMock.mock`, `TreeEntityMock.mock`, `GroundItemEntityMock.mock`, `WorldMock.make(...)` | `test/mocks/domain/**` | 2 |

La tarea 1 empieza comprobando que los mocks de la fase 2 existen con esos nombres; si alguno falta, se crea con el código que se da ahí.

## Mapa de ficheros

```
lib/layers/domain/use-cases/game/
  start_game_use_case.dart            StartGameUseCase
  move_player_use_case.dart           MovePlayerUseCase
  chop_tree_use_case.dart             ChopTreeUseCase
  can_place_building_use_case.dart    CanPlaceBuildingUseCase
  construct_building_use_case.dart    ConstructBuildingUseCase
  advance_game_use_case.dart          AdvanceGameUseCase
  get_player_status_use_case.dart     GetPlayerStatusUseCase
  get_world_snapshot_use_case.dart    GetWorldSnapshotUseCase
  get_build_options_use_case.dart     GetBuildOptionsUseCase
  get_quests_use_case.dart            GetQuestsUseCase
lib/core/config/di/di.config.dart     (regenerado)

test/mocks/domain/repositories/repository_mocks.dart (+ .mocks.dart generado)
test/mocks/domain/entities/game/game_session_entity_mock.dart
test/mocks/domain/game/game_scenario_mock.dart
test/layers/domain/use-cases/game/<caso>_test.dart  (10)
test/layers/domain/use-cases/game/game_flow_test.dart
test/core/config/di/di_test.dart
```

Origen Kotlin: `shared/src/commonMain/kotlin/com/apergas/rpg/domain/usecases/game/GameUseCaseImpl.kt`, `shared/src/commonTest/kotlin/com/apergas/rpg/domain/usecases/game/GameUseCaseImplTests.kt`, `shared/src/commonTest/kotlin/com/apergas/rpg/di/GameContainerTests.kt`.

Correspondencia de tests Kotlin → Dart:

| `GameUseCaseImplTests` / `GameContainerTests` | Dart |
|---|---|
| `testWhenStartGameThenSavesLevelWorldWithFreshQuests` | `start_game_use_case_test.dart` |
| `testWhenStartGameWithLevelErrorThenErrorPropagates` | `start_game_use_case_test.dart` |
| `testWhenNoGameInProgressThenQueriesFailWithGeneralError` | `get_player_status_use_case_test.dart` (`...ThenFailsWithNoGameInProgress`) |
| `testWhenMovePlayerAndAdvanceThenPlayerReachesThePoint` | `move_player_use_case_test.dart` |
| `testWhenPlayingTheWholeLoopThenHouseIsBuiltAndQuestsAreCompleted` | `game_flow_test.dart` |
| `testWhenPickingUpTheAxeThenQuestIsCompletedAndNextOneIsCurrent` | `advance_game_use_case_test.dart` |
| `testWhenChoppingHalfASwingThenStatusReportsChoppingProgressAndTarget` | `get_player_status_use_case_test.dart` |
| `testWhenWoodIsNotEnoughThenHouseIsNotAffordable` | `get_build_options_use_case_test.dart` |
| `testWhenCheckingABlockedSiteThenCannotPlace` | `can_place_building_use_case_test.dart` |
| `GameContainerTests.testWhenStartingAGameThenTheProceduralForestIsLoaded` | `di_test.dart` |
| `GameContainerTests.testWhenTwoUseCasesAreMadeThenTheyShareTheSameGame` | `di_test.dart` |

---

### Task 1: Mocks de prueba y `StartGameUseCase`

**Files:**
- Create: `test/mocks/domain/repositories/repository_mocks.dart`
- Modify: `test/mocks/domain/entities/game/game_session_entity_mock.dart` (creado en la fase 3 con `make()`; se añade `playing(World)`)
- Create: `test/mocks/domain/game/game_scenario_mock.dart`
- Create: `lib/layers/domain/use-cases/game/start_game_use_case.dart`
- Test: `test/layers/domain/use-cases/game/start_game_use_case_test.dart`
- Generated: `test/mocks/domain/repositories/repository_mocks.mocks.dart`

**Interfaces:**
- Consumes: `LevelRepository.load() -> World`, `GameSessionRepository.save(GameSessionEntity)`, `GameSessionEntity({required World world, required QuestLog quests})`, `QuestLog({List<Quest>? quests})`, `InvalidLevelException({required String data})`, mocks de la fase 2.
- Produces: `StartGameUseCase({required LevelRepository levelRepository, required GameSessionRepository sessionRepository})` con `void call()`; `MockLevelRepository`, `MockGameSessionRepository`; `GameSessionEntityMock.playing(World world)`; `GameScenarioMock` (mundos de cada test, usados en las tareas 2 y 3).

- [ ] **Step 1: Comprobar los mocks de la fase 2**

Run: `ls test/mocks/domain/entities/player/player_entity_mock.dart test/mocks/domain/entities/tree/tree_entity_mock.dart test/mocks/domain/entities/item/ground_item_entity_mock.dart test/mocks/domain/world/world_mock.dart && grep -n "static" test/mocks/domain/entities/player/player_entity_mock.dart test/mocks/domain/entities/tree/tree_entity_mock.dart test/mocks/domain/entities/item/ground_item_entity_mock.dart test/mocks/domain/world/world_mock.dart`
Expected: los cuatro ficheros existen y declaran `PlayerEntityMock.mock`, `TreeEntityMock.mock`, `GroundItemEntityMock.mock`, `WorldMock.make` y la extensión `WorldAdvanceFor`; además existe `test/mocks/domain/entities/game/game_session_entity_mock.dart` con `GameSessionEntityMock.make()` (fase 3).

Si alguno falta o se llama distinto, crearlo (o añadir el miembro) con exactamente este contenido, que reproduce los mocks Kotlin (`PlayerMock.kt`, `TreeMock.kt`, `GroundItemMock.kt`, `WorldMock.kt`):

```dart
// test/mocks/domain/entities/player/player_entity_mock.dart
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';

abstract final class PlayerEntityMock {
  static const PlayerEntity mock = PlayerEntity(position: PositionEntity(x: 100, y: 100), speed: 100, radius: 8);
}
```

```dart
// test/mocks/domain/entities/tree/tree_entity_mock.dart
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';

abstract final class TreeEntityMock {
  static const TreeEntity mock = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 200, y: 100),
    trunkRadius: 10,
    woodYield: 6,
    hitsToFell: 5,
  );
}
```

```dart
// test/mocks/domain/entities/item/ground_item_entity_mock.dart
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/item/ground_item_entity.dart';

abstract final class GroundItemEntityMock {
  static const GroundItemEntity mock = GroundItemEntity(
    id: 'axe-1',
    kind: ToolKind.axe,
    position: PositionEntity(x: 150, y: 100),
  );
}
```

```dart
// test/mocks/domain/world/world_mock.dart
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/item/ground_item_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/player/player_entity_mock.dart';

abstract final class WorldMock {
  static World make({
    PlayerEntity player = PlayerEntityMock.mock,
    List<TreeEntity> trees = const [],
    List<GroundItemEntity> items = const [],
  }) {
    return World(width: 1000, height: 1000, player: player, trees: trees, items: items);
  }
}

extension WorldAdvanceFor on World {
  List<GameEventEntity> advanceFor(double totalMs) {
    final events = <GameEventEntity>[];
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      events.addAll(advance(16));
      elapsed += 16;
    }
    return events;
  }
}
```

(Los tests importan con `package:rpg/...` para `lib/` y rutas relativas para `test/`; si la fase 1 dejó otra regla en `analysis_options.yaml` para `test/`, se sigue esa.)

- [ ] **Step 2: Crear los mocks de repositorio**

```dart
// test/mocks/domain/repositories/repository_mocks.dart
import 'package:mockito/annotations.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/domain/repositories/session/game_session_repository.dart';

@GenerateMocks([LevelRepository, GameSessionRepository])
void main() {}
```

- [ ] **Step 3: Crear el mock de sesión y los escenarios**

```dart
// test/mocks/domain/entities/game/game_session_entity_mock.dart
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../world/world_mock.dart';

abstract final class GameSessionEntityMock {
  static GameSessionEntity make() => GameSessionEntity(world: WorldMock.make(), quests: QuestLog());

  static GameSessionEntity playing(World world) => GameSessionEntity(world: world, quests: QuestLog());
}
```

El fichero ya existe desde la fase 3 con `make()`: se **añade** solo el método `playing` y los imports que falten, sin tocar `make()`.

Los escenarios son los mundos que `GameUseCaseImplTests.kt` construía dentro de cada test; aquí se centralizan (regla global: nada de entidades inline en el cuerpo del test). Cada llamada devuelve un `World` nuevo, porque `World` es mutable.

```dart
// test/mocks/domain/game/game_scenario_mock.dart
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/item/ground_item_entity_mock.dart';
import '../entities/player/player_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';
import '../world/world_mock.dart';

abstract final class GameScenarioMock {
  static const PositionEntity axeSpot = PositionEntity(x: 110, y: 100);
  static const PositionEntity wholeLoopAxeSpot = PositionEntity(x: 125, y: 100);
  static const PositionEntity houseSite = PositionEntity(x: 400, y: 400);
  static const PositionEntity halfSwingTreeTarget = PositionEntity(x: 120, y: 100);
  static const PositionEntity playerDestination = PositionEntity(x: 50, y: 150);

  static World levelWithOneTree() => WorldMock.make(trees: [TreeEntityMock.mock]);

  static World playerAtFifty() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(position: const PositionEntity(x: 50, y: 50)));

  static World wholeLoop() => WorldMock.make(
    items: [GroundItemEntityMock.mock.copyWith(position: const PositionEntity(x: 120, y: 100))],
    trees: [
      TreeEntityMock.mock,
      TreeEntityMock.mock.copyWith(id: 'tree-2', position: const PositionEntity(x: 200, y: 200)),
      TreeEntityMock.mock.copyWith(id: 'tree-3', position: const PositionEntity(x: 100, y: 200)),
    ],
  );

  static World axeNextToPlayer() =>
      WorldMock.make(items: [GroundItemEntityMock.mock.copyWith(position: const PositionEntity(x: 110, y: 100))]);

  static World axeInHandNextToTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(tools: {ToolKind.axe})),
    trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 120, y: 100))],
  );

  static World tenWood() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(wood: 10)));

  static World treeOnBuildingSite() =>
      WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))]);
}
```

- [ ] **Step 4: Generar los mocks**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: termina con `Succeeded after ...` y crea `test/mocks/domain/repositories/repository_mocks.mocks.dart` con `class MockLevelRepository` y `class MockGameSessionRepository`.

- [ ] **Step 5: Escribir el test que falla**

```dart
// test/layers/domain/use-cases/game/start_game_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockLevelRepository levelRepository;
  late MockGameSessionRepository sessionRepository;
  late StartGameUseCase sut;

  setUp(() {
    levelRepository = MockLevelRepository();
    sessionRepository = MockGameSessionRepository();
    sut = StartGameUseCase(levelRepository: levelRepository, sessionRepository: sessionRepository);
  });

  test('testWhenStartGameThenSavesLevelWorldWithFreshQuests', () {
    // given
    when(levelRepository.load()).thenReturn(GameScenarioMock.levelWithOneTree());

    // when
    sut();

    // then
    verify(levelRepository.load()).called(1);
    final saved = verify(sessionRepository.save(captureAny)).captured.single as GameSessionEntity;
    expect(saved.world.trees.map((tree) => tree.id), ['tree-1']);
    expect(saved.quests.status(saved.world).any((quest) => quest.isCompleted), isFalse);
  });

  test('testWhenStartGameWithLevelErrorThenErrorPropagates', () {
    // given
    when(levelRepository.load()).thenThrow(const InvalidLevelException(data: 'missing width'));

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<InvalidLevelException>()));
    verifyNever(sessionRepository.save(any));
  });
}
```

- [ ] **Step 6: Ejecutar el test y verlo fallar**

Run: `flutter test test/layers/domain/use-cases/game/start_game_use_case_test.dart`
Expected: FAIL de compilación: `Error when reading 'lib/layers/domain/use-cases/game/start_game_use_case.dart': No such file or directory`.

- [ ] **Step 7: Implementar `StartGameUseCase`**

```dart
// lib/layers/domain/use-cases/game/start_game_use_case.dart
import 'package:injectable/injectable.dart';

import '../../entities/game/game_session_entity.dart';
import '../../quests/quest_log.dart';
import '../../repositories/level/level_repository.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class StartGameUseCase {
  final LevelRepository _levelRepository;
  final GameSessionRepository _sessionRepository;

  const StartGameUseCase({required this._levelRepository, required this._sessionRepository});

  void call() {
    _sessionRepository.save(GameSessionEntity(world: _levelRepository.load(), quests: QuestLog()));
  }
}
```

(`required this._levelRepository` expone el parámetro con nombre `levelRepository`, como en el ejemplo del plugin.)

- [ ] **Step 8: Ejecutar el test y verlo pasar**

Run: `flutter test test/layers/domain/use-cases/game/start_game_use_case_test.dart`
Expected: `All tests passed!` (2 tests).

- [ ] **Step 9: Analizar y formatear**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add lib/layers/domain/use-cases/game/start_game_use_case.dart test/mocks test/layers/domain/use-cases/game/start_game_use_case_test.dart
git commit -m "[PROJECT-X]: Add the start game use case"
```

---

### Task 2: Órdenes del jugador — mover, talar, comprobar sitio y construir

**Files:**
- Create: `lib/layers/domain/use-cases/game/move_player_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/chop_tree_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/can_place_building_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/construct_building_use_case.dart`
- Test: `test/layers/domain/use-cases/game/move_player_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/chop_tree_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/can_place_building_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/construct_building_use_case_test.dart`

**Interfaces:**
- Consumes: `GameSessionRepository.current() -> GameSessionEntity`; `World.movePlayerTo(PositionEntity)`, `World.orderChop(String) -> ChopResult`, `World.canPlace(BlueprintEntity, PositionEntity) -> bool`, `World.orderConstruction(BlueprintEntity, PositionEntity) -> ConstructionResultEntity`, `World.advance(double)`; `Blueprints.of(BlueprintId)`; `GameScenarioMock`, `GameSessionEntityMock` (tarea 1).
- Produces: `MovePlayerUseCase({required GameSessionRepository sessionRepository})` `void call({required double x, required double y})`; `ChopTreeUseCase(...)` `ChopResult call({required String treeId})`; `CanPlaceBuildingUseCase(...)` `bool call({required BlueprintId blueprint, required double x, required double y})`; `ConstructBuildingUseCase(...)` `ConstructionResultEntity call({required BlueprintId blueprint, required double x, required double y})`.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
// test/layers/domain/use-cases/game/move_player_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late MovePlayerUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = MovePlayerUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenMovePlayerAndAdvanceThenPlayerReachesThePoint', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.playerAtFifty());
    when(sessionRepository.current()).thenReturn(session);

    // when
    sut(x: GameScenarioMock.playerDestination.x, y: GameScenarioMock.playerDestination.y);
    session.world.advance(1000);

    // then
    expect(session.world.player.position, GameScenarioMock.playerDestination);
  });
}
```

```dart
// test/layers/domain/use-cases/game/chop_tree_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/chop_result.dart';
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ChopTreeUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ChopTreeUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenChoppingWithoutAxeThenReturnsNoAxe', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final result = sut(treeId: 'tree-1');

    // then
    expect(result, ChopResult.noAxe);
  });

  test('testWhenChoppingWithAxeThenReturnsOk', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.axeInHandNextToTree()));

    // when
    final result = sut(treeId: 'tree-1');

    // then
    expect(result, ChopResult.ok);
  });

  test('testWhenChoppingAnUnknownTreeThenReturnsUnknownTree', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.axeInHandNextToTree()));

    // when
    final result = sut(treeId: 'tree-99');

    // then
    expect(result, ChopResult.unknownTree);
  });
}
```

```dart
// test/layers/domain/use-cases/game/can_place_building_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/use-cases/game/can_place_building_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late CanPlaceBuildingUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = CanPlaceBuildingUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenCheckingABlockedSiteThenCannotPlace', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.treeOnBuildingSite()));

    // when
    final onTree = sut(blueprint: BlueprintId.house, x: 410, y: 400);
    final onGrass = sut(blueprint: BlueprintId.house, x: 600, y: 600);

    // then
    expect(onTree, isFalse);
    expect(onGrass, isTrue);
  });
}
```

```dart
// test/layers/domain/use-cases/game/construct_building_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/construction_rejection.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ConstructBuildingUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ConstructBuildingUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenWoodIsNotEnoughThenConstructionIsRejected', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final result = sut(blueprint: BlueprintId.house, x: 400, y: 400);

    // then
    expect(result, const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood));
  });
}
```

(El caso `Started` lo cubre `game_flow_test.dart` en la tarea 3, que es donde el jugador llega a tener 15 de madera.)

- [ ] **Step 2: Ejecutar los tests y verlos fallar**

Run: `flutter test test/layers/domain/use-cases/game/`
Expected: FAIL de compilación en los cuatro ficheros nuevos (`No such file or directory` para cada `*_use_case.dart`).

- [ ] **Step 3: Implementar los cuatro casos de uso**

```dart
// lib/layers/domain/use-cases/game/move_player_use_case.dart
import 'package:injectable/injectable.dart';

import '../../entities/geometry/position_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class MovePlayerUseCase {
  final GameSessionRepository _sessionRepository;

  const MovePlayerUseCase({required this._sessionRepository});

  void call({required double x, required double y}) {
    _sessionRepository.current().world.movePlayerTo(PositionEntity(x: x, y: y));
  }
}
```

```dart
// lib/layers/domain/use-cases/game/chop_tree_use_case.dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/chop_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class ChopTreeUseCase {
  final GameSessionRepository _sessionRepository;

  const ChopTreeUseCase({required this._sessionRepository});

  ChopResult call({required String treeId}) => _sessionRepository.current().world.orderChop(treeId);
}
```

```dart
// lib/layers/domain/use-cases/game/can_place_building_use_case.dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/geometry/position_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';

@Injectable()
final class CanPlaceBuildingUseCase {
  final GameSessionRepository _sessionRepository;

  const CanPlaceBuildingUseCase({required this._sessionRepository});

  bool call({required BlueprintId blueprint, required double x, required double y}) {
    return _sessionRepository.current().world.canPlace(Blueprints.of(blueprint), PositionEntity(x: x, y: y));
  }
}
```

```dart
// lib/layers/domain/use-cases/game/construct_building_use_case.dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../entities/game/construction_result_entity.dart';
import '../../entities/geometry/position_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';

@Injectable()
final class ConstructBuildingUseCase {
  final GameSessionRepository _sessionRepository;

  const ConstructBuildingUseCase({required this._sessionRepository});

  ConstructionResultEntity call({required BlueprintId blueprint, required double x, required double y}) {
    return _sessionRepository.current().world.orderConstruction(Blueprints.of(blueprint), PositionEntity(x: x, y: y));
  }
}
```

- [ ] **Step 4: Ejecutar los tests y verlos pasar**

Run: `flutter test test/layers/domain/use-cases/game/`
Expected: `All tests passed!` (8 tests: 2 + 1 + 3 + 1 + 1).

- [ ] **Step 5: Analizar y formatear**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/layers/domain/use-cases/game test/layers/domain/use-cases/game
git commit -m "[PROJECT-X]: Add the player order use cases"
```

---

### Task 3: Avance de la simulación y consultas de estado

**Files:**
- Create: `lib/layers/domain/use-cases/game/advance_game_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/get_player_status_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/get_world_snapshot_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/get_build_options_use_case.dart`
- Create: `lib/layers/domain/use-cases/game/get_quests_use_case.dart`
- Test: `test/layers/domain/use-cases/game/advance_game_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/get_player_status_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/get_world_snapshot_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/get_build_options_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/get_quests_use_case_test.dart`
- Test: `test/layers/domain/use-cases/game/game_flow_test.dart`

**Interfaces:**
- Consumes: `World.advance(double) -> List<GameEventEntity>`, `QuestLog.update(World) -> List<QuestCompletedEventEntity>`, `QuestLog.status(World) -> List<QuestProgressEntity>`, `World.player`, `World.playerTarget`, `World.workProgress`, `World.{width,height,trees,items,decorations,buildings}`, `InventoryRules.hasTool` (`lib/layers/domain/world/extensions/inventory_rules.dart`), `Blueprints.all`, sealed `ActivityEntity` / `IntentEntity`; casos de uso de las tareas 1–2.
- Produces: `AdvanceGameUseCase` `List<GameEventEntity> call({required double deltaMs})`; `GetPlayerStatusUseCase` `PlayerStatusEntity call()`; `GetWorldSnapshotUseCase` `WorldSnapshotEntity call()`; `GetBuildOptionsUseCase` `List<BuildOptionEntity> call()`; `GetQuestsUseCase` `List<QuestProgressEntity> call()`. Todos con constructor `({required GameSessionRepository sessionRepository})`.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
// test/layers/domain/use-cases/game/advance_game_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late AdvanceGameUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = AdvanceGameUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenPickingUpTheAxeThenQuestIsCompletedAndNextOneIsCurrent', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.axeNextToPlayer());
    when(sessionRepository.current()).thenReturn(session);
    session.world.movePlayerTo(GameScenarioMock.axeSpot);

    // when
    final events = sut(deltaMs: 200);

    // then
    expect(events, contains(const QuestCompletedEventEntity(questId: QuestId.pickUpAxe)));
    expect(
      session.quests.status(session.world)[1],
      const QuestProgressEntity(id: QuestId.gatherWood, progress: 0, target: 15, isCompleted: false, isCurrent: true),
    );
  });

  test('testWhenNothingHappensThenReturnsNoEvents', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final events = sut(deltaMs: 16);

    // then
    expect(events, isEmpty);
  });
}
```

```dart
// test/layers/domain/use-cases/game/get_player_status_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetPlayerStatusUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetPlayerStatusUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(const NoGameInProgressException());

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenChoppingHalfASwingThenStatusReportsChoppingProgressAndTarget', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.axeInHandNextToTree());
    when(sessionRepository.current()).thenReturn(session);
    session.world.orderChop('tree-1');
    session.world.advance(Rules.chopIntervalMs / 2);

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.chopping);
    expect(status.swingProgress, 0.5);
    expect(status.target, GameScenarioMock.halfSwingTreeTarget);
    expect(status.hasAxe, isTrue);
  });

  test('testWhenPlayerIsIdleThenStatusReportsIdleWithoutTarget', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.idle);
    expect(status.target, isNull);
    expect(status.swingProgress, 0);
    expect(status.wood, 10);
    expect(status.hasAxe, isFalse);
  });

  test('testWhenPlayerWalksThenStatusReportsWalkingAndDestination', () {
    // given
    final session = GameSessionEntityMock.playing(GameScenarioMock.playerAtFifty());
    when(sessionRepository.current()).thenReturn(session);
    session.world.movePlayerTo(GameScenarioMock.playerDestination);

    // when
    final status = sut();

    // then
    expect(status.activity, PlayerActivity.walking);
    expect(status.target, GameScenarioMock.playerDestination);
  });
}
```

```dart
// test/layers/domain/use-cases/game/get_world_snapshot_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/use-cases/game/get_world_snapshot_use_case.dart';

import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetWorldSnapshotUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetWorldSnapshotUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenTakingASnapshotThenReturnsEverythingPlacedInTheWorld', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final snapshot = sut();

    // then
    expect(snapshot.width, 1000);
    expect(snapshot.height, 1000);
    expect(snapshot.trees, [TreeEntityMock.mock]);
    expect(snapshot.items, isEmpty);
    expect(snapshot.decorations, isEmpty);
    expect(snapshot.buildings, isEmpty);
  });
}
```

```dart
// test/layers/domain/use-cases/game/get_build_options_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/game/build_option_entity.dart';
import 'package:rpg/layers/domain/use-cases/game/get_build_options_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetBuildOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetBuildOptionsUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenWoodIsNotEnoughThenHouseIsNotAffordable', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final options = sut();

    // then
    expect(options, [const BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: false)]);
  });
}
```

```dart
// test/layers/domain/use-cases/game/get_quests_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetQuestsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetQuestsUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenGameStartsThenFirstQuestIsCurrentAndNoneIsCompleted', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final quests = sut();

    // then
    expect(quests.map((quest) => quest.id), [QuestId.pickUpAxe, QuestId.gatherWood, QuestId.buildHouse]);
    expect(quests.any((quest) => quest.isCompleted), isFalse);
    expect(quests.first.isCurrent, isTrue);
  });
}
```

```dart
// test/layers/domain/use-cases/game/game_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/chop_result.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late MovePlayerUseCase movePlayer;
  late ChopTreeUseCase chopTree;
  late ConstructBuildingUseCase constructBuilding;
  late AdvanceGameUseCase advanceGame;
  late GetPlayerStatusUseCase getPlayerStatus;
  late GetQuestsUseCase getQuests;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    movePlayer = MovePlayerUseCase(sessionRepository: sessionRepository);
    chopTree = ChopTreeUseCase(sessionRepository: sessionRepository);
    constructBuilding = ConstructBuildingUseCase(sessionRepository: sessionRepository);
    advanceGame = AdvanceGameUseCase(sessionRepository: sessionRepository);
    getPlayerStatus = GetPlayerStatusUseCase(sessionRepository: sessionRepository);
    getQuests = GetQuestsUseCase(sessionRepository: sessionRepository);
  });

  List<GameEventEntity> advanceFor(double totalMs) {
    final events = <GameEventEntity>[];
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      events.addAll(advanceGame(deltaMs: 16));
      elapsed += 16;
    }
    return events;
  }

  test('testWhenPlayingTheWholeLoopThenHouseIsBuiltAndQuestsAreCompleted', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.wholeLoop()));
    const chopTime = 2000 + Rules.chopIntervalMs * Rules.hitsToFellTree;
    const axeSpot = GameScenarioMock.wholeLoopAxeSpot;
    const site = GameScenarioMock.houseSite;

    // when
    final withoutAxe = chopTree(treeId: 'tree-1');
    movePlayer(x: axeSpot.x, y: axeSpot.y);
    advanceFor(500);
    final chopResults = ['tree-1', 'tree-2', 'tree-3'].map((treeId) {
      final result = chopTree(treeId: treeId);
      advanceFor(chopTime);
      return result;
    }).toList();
    final woodAfterChopping = getPlayerStatus().wood;
    final construction = constructBuilding(blueprint: BlueprintId.house, x: site.x, y: site.y);
    final events = advanceFor(6000 + Rules.hammerIntervalMs * 8);

    // then
    expect(withoutAxe, ChopResult.noAxe);
    expect(chopResults, [ChopResult.ok, ChopResult.ok, ChopResult.ok]);
    expect(woodAfterChopping, 18);
    expect(construction, isA<ConstructionStartedEntity>());
    expect(events, contains(const BuildingCompletedEventEntity(buildingId: 'building-1', blueprint: BlueprintId.house)));
    expect(events, contains(const QuestCompletedEventEntity(questId: QuestId.buildHouse)));
    expect(getPlayerStatus().wood, 3);
    expect(getQuests().every((quest) => quest.isCompleted), isTrue);
  });
}
```

- [ ] **Step 2: Ejecutar los tests y verlos fallar**

Run: `flutter test test/layers/domain/use-cases/game/`
Expected: FAIL de compilación: faltan `advance_game_use_case.dart`, `get_player_status_use_case.dart`, `get_world_snapshot_use_case.dart`, `get_build_options_use_case.dart`, `get_quests_use_case.dart`.

- [ ] **Step 3: Implementar los cinco casos de uso**

```dart
// lib/layers/domain/use-cases/game/advance_game_use_case.dart
import 'package:injectable/injectable.dart';

import '../../entities/game/game_event_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class AdvanceGameUseCase {
  final GameSessionRepository _sessionRepository;

  const AdvanceGameUseCase({required this._sessionRepository});

  List<GameEventEntity> call({required double deltaMs}) {
    final session = _sessionRepository.current();
    final worldEvents = session.world.advance(deltaMs);
    return [...worldEvents, ...session.quests.update(session.world)];
  }
}
```

(Igual que en Kotlin: primero avanza el mundo y después se evalúan las misiones sobre el mundo ya avanzado.)

```dart
// lib/layers/domain/use-cases/game/get_player_status_use_case.dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/player_activity.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/game/player_status_entity.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../world/extensions/inventory_rules.dart';

@Injectable()
final class GetPlayerStatusUseCase {
  final GameSessionRepository _sessionRepository;

  const GetPlayerStatusUseCase({required this._sessionRepository});

  PlayerStatusEntity call() {
    final world = _sessionRepository.current().world;
    final player = world.player;
    return PlayerStatusEntity(
      position: player.position,
      activity: _activityOf(player.activity),
      target: world.playerTarget,
      swingProgress: world.workProgress,
      wood: player.inventory.wood,
      hasAxe: player.inventory.hasTool(ToolKind.axe),
    );
  }

  PlayerActivity _activityOf(ActivityEntity activity) => switch (activity) {
    IdleActivityEntity() => PlayerActivity.idle,
    WalkingActivityEntity() => PlayerActivity.walking,
    WorkingActivityEntity(:final intent) => switch (intent) {
      ChopIntentEntity() => PlayerActivity.chopping,
      ConstructIntentEntity() => PlayerActivity.constructing,
    },
  };
}
```

(Los dos `switch` son exhaustivos sobre jerarquías `sealed`: añadir un `IntentEntity` nuevo deja de compilar aquí, como el `when` de Kotlin.)

```dart
// lib/layers/domain/use-cases/game/get_world_snapshot_use_case.dart
import 'package:injectable/injectable.dart';

import '../../entities/game/world_snapshot_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class GetWorldSnapshotUseCase {
  final GameSessionRepository _sessionRepository;

  const GetWorldSnapshotUseCase({required this._sessionRepository});

  WorldSnapshotEntity call() {
    final world = _sessionRepository.current().world;
    return WorldSnapshotEntity(
      width: world.width,
      height: world.height,
      trees: world.trees,
      items: world.items,
      decorations: world.decorations,
      buildings: world.buildings,
    );
  }
}
```

```dart
// lib/layers/domain/use-cases/game/get_build_options_use_case.dart
import 'package:injectable/injectable.dart';

import '../../entities/game/build_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/blueprints.dart';

@Injectable()
final class GetBuildOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetBuildOptionsUseCase({required this._sessionRepository});

  List<BuildOptionEntity> call() {
    final wood = _sessionRepository.current().world.player.inventory.wood;
    return Blueprints.all
        .map(
          (blueprint) => BuildOptionEntity(
            blueprint: blueprint.id,
            woodCost: blueprint.woodCost,
            isAffordable: wood >= blueprint.woodCost,
          ),
        )
        .toList();
  }
}
```

```dart
// lib/layers/domain/use-cases/game/get_quests_use_case.dart
import 'package:injectable/injectable.dart';

import '../../entities/game/quest_progress_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class GetQuestsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetQuestsUseCase({required this._sessionRepository});

  List<QuestProgressEntity> call() {
    final session = _sessionRepository.current();
    return session.quests.status(session.world);
  }
}
```

- [ ] **Step 4: Ejecutar los tests y verlos pasar**

Run: `flutter test test/layers/domain/use-cases/game/`
Expected: `All tests passed!` (18 tests: 8 de las tareas 1–2 + 2 + 4 + 1 + 1 + 1 + 1).

- [ ] **Step 5: Comprobar que los diez casos de uso existen con el nombre del contrato**

Run: `grep -h "^final class" lib/layers/domain/use-cases/game/*.dart | sort`
Expected, exactamente:

```
final class AdvanceGameUseCase {
final class CanPlaceBuildingUseCase {
final class ChopTreeUseCase {
final class ConstructBuildingUseCase {
final class GetBuildOptionsUseCase {
final class GetPlayerStatusUseCase {
final class GetQuestsUseCase {
final class GetWorldSnapshotUseCase {
final class MovePlayerUseCase {
final class StartGameUseCase {
```

- [ ] **Step 6: Analizar, formatear y test de arquitectura**

Run: `dart format --line-length 120 lib test && flutter analyze && flutter test test/architecture_test.dart`
Expected: `No issues found!` y `All tests passed!` (los casos de uso solo importan `injectable`, dominio y `core/`).

- [ ] **Step 7: Commit**

```bash
git add lib/layers/domain/use-cases/game test/layers/domain/use-cases/game test/mocks/domain/game
git commit -m "[PROJECT-X]: Add the simulation and query use cases"
```

---

### Task 4: Grafo de dependencias completo y cómo se creará el `ForestBloc`

**Files:**
- Modify (generated): `lib/core/config/di/di.config.dart`
- Test: `test/core/config/di/di_test.dart`

**Interfaces:**
- Consumes: `configureDependencies({required String environment})`, `DiEnvironment.dev`, `locator` (fase 1); todas las clases anotadas de las fases 1–4.
- Produces: `locator.get<T>()` resuelve los 10 casos de uso, `LevelRepository`, `GameSessionRepository`, `LevelLocalDatasource`, `GameSessionLocalDatasource` (misma instancia siempre), los 5 mappers, `AppExceptionHandler` y `NavigationService`. Contrato para la fase 5/7: `ForestPage` crea el BLoC así (sin registro en DI):

```dart
BlocProvider(
  create: (context) => ForestBloc(
    startGameUseCase: locator.get<StartGameUseCase>(),
    movePlayerUseCase: locator.get<MovePlayerUseCase>(),
    chopTreeUseCase: locator.get<ChopTreeUseCase>(),
    canPlaceBuildingUseCase: locator.get<CanPlaceBuildingUseCase>(),
    constructBuildingUseCase: locator.get<ConstructBuildingUseCase>(),
    advanceGameUseCase: locator.get<AdvanceGameUseCase>(),
    getPlayerStatusUseCase: locator.get<GetPlayerStatusUseCase>(),
    getWorldSnapshotUseCase: locator.get<GetWorldSnapshotUseCase>(),
    getBuildOptionsUseCase: locator.get<GetBuildOptionsUseCase>(),
    getQuestsUseCase: locator.get<GetQuestsUseCase>(),
    navigationService: locator.get<NavigationService>(),
  )..add(ForestStarted()),
  child: const _ForestView(),
)
```

- [ ] **Step 1: Escribir el test de DI que falla**

Porta `GameContainerTests.kt`: el bosque procedural se carga entero y dos resoluciones distintas de los casos de uso trabajan sobre la misma partida.

```dart
// test/core/config/di/di_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/data/datasources/session/source/game_session_local_datasource.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/domain/repositories/session/game_session_repository.dart';
import 'package:rpg/layers/domain/use-cases/game/advance_game_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/can_place_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/chop_tree_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_build_options_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_player_status_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/get_world_snapshot_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/move_player_use_case.dart';
import 'package:rpg/layers/domain/use-cases/game/start_game_use_case.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await configureDependencies(environment: DiEnvironment.dev);
  });

  tearDown(() async {
    await locator.reset();
  });

  test('testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered', () {
    // given
    final registered = [
      locator.isRegistered<StartGameUseCase>(),
      locator.isRegistered<MovePlayerUseCase>(),
      locator.isRegistered<ChopTreeUseCase>(),
      locator.isRegistered<CanPlaceBuildingUseCase>(),
      locator.isRegistered<ConstructBuildingUseCase>(),
      locator.isRegistered<AdvanceGameUseCase>(),
      locator.isRegistered<GetPlayerStatusUseCase>(),
      locator.isRegistered<GetWorldSnapshotUseCase>(),
      locator.isRegistered<GetBuildOptionsUseCase>(),
      locator.isRegistered<GetQuestsUseCase>(),
      locator.isRegistered<LevelRepository>(),
      locator.isRegistered<GameSessionRepository>(),
      locator.isRegistered<GameSessionLocalDatasource>(),
      locator.isRegistered<AppExceptionHandler>(),
      locator.isRegistered<NavigationService>(),
    ];

    // when
    final allRegistered = registered.every((isRegistered) => isRegistered);

    // then
    expect(allRegistered, isTrue);
  });

  test('testWhenStartingAGameThenTheProceduralForestIsLoaded', () {
    // given
    final startGame = locator.get<StartGameUseCase>();

    // when
    startGame();
    final snapshot = locator.get<GetWorldSnapshotUseCase>()();

    // then
    expect(snapshot.trees.length, 70);
    expect(snapshot.trees.fold<int>(0, (total, tree) => total + tree.woodYield), 388);
    expect(snapshot.trees.first.kind, TreeKind.broad);
    expect(snapshot.decorations.length, greaterThanOrEqualTo(40));
  });

  test('testWhenUseCasesAreResolvedSeparatelyThenTheyShareTheSameGame', () {
    // given
    locator.get<StartGameUseCase>()();

    // when
    locator.get<MovePlayerUseCase>()(x: 800, y: 500);
    locator.get<AdvanceGameUseCase>()(deltaMs: 2000);

    // then
    expect(locator.get<GetPlayerStatusUseCase>()().position.y, 500);
  });

  test('testWhenResolvingTheSessionDatasourceTwiceThenItIsTheSameInstance', () {
    // given
    final first = locator.get<GameSessionLocalDatasource>();

    // when
    final second = locator.get<GameSessionLocalDatasource>();

    // then
    expect(identical(first, second), isTrue);
  });
}
```

(Los números 70 / 388 / `TreeKind.broad` / ≥40 son los mismos valores dorados que `GameContainerTests.kt`. El camino de importación de `NavigationService` es el que dejó la fase 1 según `references/core/navigation_service.md`; si el fichero se llama distinto, se ajusta solo ese import. Si la fase 1 registró `NavigationService` en otro entorno de DI, se usa ese entorno en `configureDependencies`.)

- [ ] **Step 2: Ejecutar el test y verlo fallar**

Run: `flutter test test/core/config/di/di_test.dart`
Expected: FAIL — `testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered` da `Expected: true Actual: <false>` (los casos de uso todavía no están en `di.config.dart`) y los demás fallan con `Bad state: GetIt: Object/factory with type StartGameUseCase is not registered inside GetIt`.

- [ ] **Step 3: Regenerar la configuración de DI**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `Succeeded after ...`.

- [ ] **Step 4: Revisar lo que se ha registrado**

Run: `grep -oE "(factory|lazySingleton|singleton)<[A-Za-z]+>" lib/core/config/di/di.config.dart | sort`
Expected: aparecen (entre otras de la fase 1) estas líneas:

```
factory<AdvanceGameUseCase>
factory<AppExceptionHandler>
factory<CanPlaceBuildingUseCase>
factory<ChopTreeUseCase>
factory<ConstructBuildingUseCase>
factory<DecorationMapperDBO>
factory<GameSessionRepository>
factory<GetBuildOptionsUseCase>
factory<GetPlayerStatusUseCase>
factory<GetQuestsUseCase>
factory<GetWorldSnapshotUseCase>
factory<GroundItemMapperDBO>
factory<LevelLocalDatasource>
factory<LevelMapperDBO>
factory<LevelRepository>
factory<MovePlayerUseCase>
factory<PositionMapperDBO>
factory<StartGameUseCase>
factory<TreeMapperDBO>
lazySingleton<GameSessionLocalDatasource>
```

y `NavigationService` con la anotación que fije `references/core/navigation_service.md`. No aparece ningún `ForestBloc` (los BLoC no se registran). Si falta algún tipo, la anotación de su clase (fases 1–3) está mal: se corrige en esa clase, no en `di.config.dart`, y se vuelve al Step 3.

- [ ] **Step 5: Ejecutar el test y verlo pasar**

Run: `flutter test test/core/config/di/di_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 6: Comprobar que el plan maestro ya recoge la creación del BLoC**

Run: `grep -n "no se registra en DI" docs/boost/plans/2026-10-05-flutter-migration/README.md`
Expected: una línea en D4 (`El ForestBloc no se registra en DI ... ForestPage lo crea en BlocProvider.create ...`). El README ya se corrigió al escribir el plan: no hay que editarlo. Si `di.dart` de la fase 1 todavía menciona un registro manual del `ForestBloc`, no se añade nada: los BLoC no se registran.

- [ ] **Step 7: Suite completa, análisis y formato**

Run: `dart format --line-length 120 lib test && flutter analyze && flutter test`
Expected: `No issues found!` y `All tests passed!` (todas las fases 1–4).

- [ ] **Step 8: Commit**

```bash
git add lib/core/config/di/di.config.dart test/core/config/di/di_test.dart
git commit -m "[PROJECT-X]: Register the game use cases in the dependency graph"
```

---

## Cierre de la fase

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → `All tests passed!` (incluye `test/architecture_test.dart`, `test/layers/domain/use-cases/game/**` y `test/core/config/di/di_test.dart`).
- [ ] `flutter test --platform chrome test/core/config/di/di_test.dart` → `All tests passed!` (el bosque procedural da 70 árboles / 388 de madera también compilado a JS).
- [ ] `git log --oneline -4` muestra los cuatro commits de la fase con formato `[PROJECT-X]: ...` y sin atribución a ninguna IA.
- [ ] Los once tests de Kotlin de la tabla de correspondencia tienen su equivalente Dart en verde.
