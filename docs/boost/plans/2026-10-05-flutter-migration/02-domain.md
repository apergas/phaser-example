# Fase 2 — Dominio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar a Dart todo el dominio del juego (enums, entidades, reglas de las entidades, `World` y sus sistemas, misiones, catálogo de planos, interfaces de repositorio) con los mismos tests que tenía Kotlin.

**Architecture:** Dart puro en `lib/layers/domain/` (sin Flutter, Flame, `dart:ui` ni `dart:io`). Las entidades solo tienen datos, getters calculados, `copyWith` y `==`/`hashCode`; las operaciones que en Kotlin eran métodos (`hit`, `spendWood`, `walkTo`, `distanceTo`...) pasan a extensiones en `domain/world/extensions/` (excepción E2 del README). `World` es el agregado mutable que delega en `Navigation`, `Woodcutting`, `Construction` y `pickUpItems` (excepción E1). Los enums viven en `lib/core/config/constants/enum/` (excepción E4).

**Tech Stack:** Dart 3.13, `package:collection` (`ListEquality`, `SetEquality`), `package:meta` (`@visibleForTesting`), `flutter_test`.

## Global Constraints

- Todas las de [`README.md`](README.md) → *Global Constraints*; en particular: nombres y firmas de §3.1–§3.3 sin cambios, sin comentarios en `lib/`, `dart format --line-length 120`, `flutter analyze` sin incidencias al final de cada tarea.
- Imports dentro de `lib/` siempre relativos (`prefer_relative_imports`); los tests importan `package:rpg/...`.
- Fuente de verdad del comportamiento: `shared/src/commonMain/kotlin/com/apergas/rpg/domain/` (no se borra hasta la fase 8). Los tests portados conservan **los mismos casos y los mismos literales** que `shared/src/commonTest/kotlin/com/apergas/rpg/domain/`.
- Los `require(...)` de Kotlin en constructores pasan a `assert(...)` en constructores `const` (los tests de Flutter se ejecutan con asserts activos); el de `Inventory.addWood` (que no es constructor) pasa a `ArgumentError`.
- `kotlin.math.hypot(dx, dy)` pasa a `sqrt(dx * dx + dy * dy)` (`dart:math` no tiene `hypot`). Para los valores de los tests el resultado es idéntico.
- Datos de test: las entidades de entrada salen de `test/mocks/**/<name>_mock.dart` (`abstract final class XMock { static const mock = ...; }`) o de una copia suya (`TreeEntityMock.mock.copyWith(...)`). Las coordenadas (`PositionEntity`) y los valores esperados en las aserciones pueden escribirse en línea.
- Para no disparar `prefer_const_constructors`, toda construcción con argumentos literales lleva `const`; los tests de asserts pasan los valores inválidos a través de variables `final`.
- Antes de cada commit: `dart format --line-length 120 lib test` y `flutter analyze` (esperado: `No issues found!`).

---

## Mapa de ficheros de la fase

```
lib/core/config/constants/enum/
  tree_kind.dart  decoration_kind.dart  tool_kind.dart  blueprint_id.dart  quest_id.dart
  chop_result.dart  construction_rejection.dart  player_activity.dart
lib/layers/domain/
  entities/geometry/position_entity.dart  obstacle_entity.dart
  entities/tree/tree_entity.dart
  entities/item/ground_item_entity.dart
  entities/decoration/decoration_entity.dart
  entities/building/blueprint_entity.dart  building_entity.dart
  entities/player/inventory_entity.dart  intent_entity.dart  activity_entity.dart  player_entity.dart
  entities/game/game_event_entity.dart  construction_result_entity.dart  build_option_entity.dart
                player_status_entity.dart  quest_progress_entity.dart  world_snapshot_entity.dart  game_session_entity.dart
  rules/rules.dart  blueprints.dart
  world/extensions/position_geometry.dart  obstacle_rules.dart  tree_rules.dart  building_rules.dart
                   inventory_rules.dart  player_rules.dart
  world/world_state.dart  work.dart  navigation.dart  woodcutting.dart  construction.dart  pick_up_items.dart  world.dart
  quests/quest.dart  quests.dart  quest_log.dart
  repositories/level/level_repository.dart
  repositories/session/game_session_repository.dart
test/mocks/domain/entities/tree/tree_entity_mock.dart
test/mocks/domain/entities/item/ground_item_entity_mock.dart
test/mocks/domain/entities/building/building_entity_mock.dart
test/mocks/domain/entities/player/player_entity_mock.dart
test/mocks/domain/entities/game/player_status_entity_mock.dart
test/mocks/domain/entities/game/world_snapshot_entity_mock.dart
test/mocks/domain/world/world_mock.dart
test/layers/domain/...   (espejo de lib/layers/domain)
```

| Kotlin (`shared/src/commonTest/.../domain/`) | Dart (`test/layers/domain/`) |
|---|---|
| `entities/geometry/PositionTests.kt` | `world/extensions/position_geometry_test.dart` (5) + `world/extensions/obstacle_rules_test.dart` (1) |
| `entities/tree/TreeTests.kt` | `world/extensions/tree_rules_test.dart` |
| `entities/building/BuildingTests.kt` | `world/extensions/building_rules_test.dart` |
| `entities/player/InventoryTests.kt` | `world/extensions/inventory_rules_test.dart` |
| `entities/player/PlayerTests.kt` | `world/extensions/player_rules_test.dart` (4) + `entities/player/player_entity_test.dart` (1) |
| `world/WorldMovementTests.kt` | `world/world_movement_test.dart` |
| `world/WorldItemsTests.kt` | `world/world_items_test.dart` |
| `world/WorldChoppingTests.kt` | `world/world_chopping_test.dart` |
| `world/WorldConstructionTests.kt` | `world/world_construction_test.dart` |
| `quests/QuestLogTests.kt` | `quests/quest_log_test.dart` |
| `TreeMock.kt`, `GroundItemMock.kt`, `PlayerMock.kt`, `WorldMock.kt` | `test/mocks/...` |

---

### Task 1: Enums, posición y obstáculo

**Files:**
- Create: `lib/core/config/constants/enum/tree_kind.dart`, `decoration_kind.dart`, `tool_kind.dart`, `blueprint_id.dart`, `quest_id.dart`, `chop_result.dart`, `construction_rejection.dart`, `player_activity.dart`
- Create: `lib/layers/domain/entities/geometry/position_entity.dart`, `obstacle_entity.dart`
- Create: `lib/layers/domain/world/extensions/position_geometry.dart`, `obstacle_rules.dart`
- Test: `test/layers/domain/entities/geometry/position_entity_test.dart`, `obstacle_entity_test.dart`
- Test: `test/layers/domain/world/extensions/position_geometry_test.dart`, `obstacle_rules_test.dart`
- Modify (solo si faltan): `pubspec.yaml` (`collection`, `meta`)

**Interfaces:**
- Consumes: proyecto de la fase 1 (`pubspec.yaml` con nombre `rpg`, `analysis_options.yaml`).
- Produces: los 8 enums de README §3.1 (salvo `forest/`); `PositionEntity({required double x, required double y})`; `ObstacleEntity({required PositionEntity position, required double radius})`; `extension PositionGeometry on PositionEntity { double distanceTo(PositionEntity other); PositionEntity moveTowards(PositionEntity target, double maxStep); PositionEntity pointAtDistance(double distance, PositionEntity towards); }`; `extension ObstacleRules on ObstacleEntity { bool blocks(PositionEntity position, double radius); }`.

- [ ] **Step 1: Comprobar dependencias puras de Dart**

Run: `grep -nE '^\s+(collection|meta):' pubspec.yaml`
Expected: dos líneas (`collection: ^…` y `meta: ^…`, ambas en `dependencies:`). Si falta alguna: `flutter pub add collection meta` y añadir `pubspec.yaml` y `pubspec.lock` al commit de esta tarea.

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/domain/entities/geometry/position_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

void main() {
  test('testWhenComparingPositionsWithSameCoordinatesThenTheyAreEqual', () {
    // given
    const position = PositionEntity(x: 3, y: 4);

    // when
    final isEqual = position == const PositionEntity(x: 3, y: 4);
    final isDifferent = position == const PositionEntity(x: 4, y: 3);

    // then
    expect(isEqual, isTrue);
    expect(isDifferent, isFalse);
    expect(position.hashCode, const PositionEntity(x: 3, y: 4).hashCode);
  });

  test('testWhenCopyingWithXThenOnlyXChanges', () {
    // given
    const position = PositionEntity(x: 3, y: 4);

    // when
    final copy = position.copyWith(x: 10);

    // then
    expect(copy, const PositionEntity(x: 10, y: 4));
  });
}
```

`test/layers/domain/entities/geometry/obstacle_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

void main() {
  test('testWhenRadiusIsNotPositiveThenCreationFails', () {
    // given
    final radius = 0.0;

    // when / then
    expect(() => ObstacleEntity(position: const PositionEntity(x: 0, y: 0), radius: radius), throwsA(isA<AssertionError>()));
  });

  test('testWhenComparingObstaclesWithSameValuesThenTheyAreEqual', () {
    // given
    const obstacle = ObstacleEntity(position: PositionEntity(x: 30, y: 0), radius: 10);

    // when
    final isEqual = obstacle == const ObstacleEntity(position: PositionEntity(x: 30, y: 0), radius: 10);

    // then
    expect(isEqual, isTrue);
  });
}
```

`test/layers/domain/world/extensions/position_geometry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/position_geometry.dart';

void main() {
  test('testWhenMeasuringDistanceThenReturnsEuclideanDistance', () {
    // given
    const origin = PositionEntity(x: 0, y: 0);

    // when
    final distance = origin.distanceTo(const PositionEntity(x: 3, y: 4));

    // then
    expect(distance, 5.0);
  });

  test('testWhenMovingTowardsTargetThenAdvancesByStep', () {
    // given
    const origin = PositionEntity(x: 0, y: 0);

    // when
    final moved = origin.moveTowards(const PositionEntity(x: 10, y: 0), 4);

    // then
    expect(moved, const PositionEntity(x: 4, y: 0));
  });

  test('testWhenStepWouldOvershootThenSnapsToTarget', () {
    // given
    const target = PositionEntity(x: 10, y: 0);

    // when
    final moved = const PositionEntity(x: 8, y: 0).moveTowards(target, 5);

    // then
    expect(moved, same(target));
  });

  test('testWhenAskingPointAtDistanceThenFollowsDirection', () {
    // given
    const origin = PositionEntity(x: 0, y: 0);

    // when
    final point = origin.pointAtDistance(5, const PositionEntity(x: 30, y: 40));

    // then
    expect(point, const PositionEntity(x: 3, y: 4));
  });

  test('testWhenBothPositionsCoincideThenPointIsBelow', () {
    // given
    const position = PositionEntity(x: 1, y: 1);

    // when
    final point = position.pointAtDistance(5, const PositionEntity(x: 1, y: 1));

    // then
    expect(point, const PositionEntity(x: 1, y: 6));
  });
}
```

`test/layers/domain/world/extensions/obstacle_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/obstacle_rules.dart';

void main() {
  test('testWhenFootprintsOverlapThenObstacleBlocks', () {
    // given
    const obstacle = ObstacleEntity(position: PositionEntity(x: 30, y: 0), radius: 10);

    // when
    final blocksNear = obstacle.blocks(const PositionEntity(x: 15, y: 0), 8);
    final blocksFar = obstacle.blocks(const PositionEntity(x: 0, y: 0), 8);

    // then
    expect(blocksNear, isTrue);
    expect(blocksFar, isFalse);
  });
}
```

- [ ] **Step 3: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/entities/geometry test/layers/domain/world/extensions`
Expected: FAIL por compilación (`Error when reading 'lib/layers/domain/entities/geometry/position_entity.dart': No such file or directory`).

- [ ] **Step 4: Crear los enums**

`lib/core/config/constants/enum/tree_kind.dart`:

```dart
enum TreeKind { slim, round, wide, broad, twisted, branches, leaning, lumpy, pine, dome, oak, dense, old, big }
```

`lib/core/config/constants/enum/decoration_kind.dart`:

```dart
enum DecorationKind { tallGrass, leaves, mushrooms, rock }
```

`lib/core/config/constants/enum/tool_kind.dart`:

```dart
enum ToolKind { axe }
```

`lib/core/config/constants/enum/blueprint_id.dart`:

```dart
enum BlueprintId { house }
```

`lib/core/config/constants/enum/quest_id.dart`:

```dart
enum QuestId { pickUpAxe, gatherWood, buildHouse }
```

`lib/core/config/constants/enum/chop_result.dart`:

```dart
enum ChopResult { ok, noAxe, unknownTree }
```

`lib/core/config/constants/enum/construction_rejection.dart`:

```dart
enum ConstructionRejection { notEnoughWood, blocked }
```

`lib/core/config/constants/enum/player_activity.dart`:

```dart
enum PlayerActivity { idle, walking, chopping, constructing }
```

- [ ] **Step 5: Crear las entidades de geometría**

`lib/layers/domain/entities/geometry/position_entity.dart`:

```dart
class PositionEntity {
  final double x;
  final double y;

  const PositionEntity({required this.x, required this.y});

  PositionEntity copyWith({double? x, double? y}) {
    return PositionEntity(x: x ?? this.x, y: y ?? this.y);
  }

  @override
  bool operator ==(Object other) => other is PositionEntity && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PositionEntity(x: $x, y: $y)';
}
```

`lib/layers/domain/entities/geometry/obstacle_entity.dart`:

```dart
import 'position_entity.dart';

class ObstacleEntity {
  final PositionEntity position;
  final double radius;

  const ObstacleEntity({required this.position, required this.radius}) : assert(radius > 0);

  @override
  bool operator ==(Object other) => other is ObstacleEntity && other.position == position && other.radius == radius;

  @override
  int get hashCode => Object.hash(position, radius);
}
```

- [ ] **Step 6: Crear las extensiones de geometría**

`lib/layers/domain/world/extensions/position_geometry.dart`:

```dart
import 'dart:math';

import '../../entities/geometry/position_entity.dart';

extension PositionGeometry on PositionEntity {
  double distanceTo(PositionEntity other) {
    final dx = other.x - x;
    final dy = other.y - y;
    return sqrt(dx * dx + dy * dy);
  }

  PositionEntity moveTowards(PositionEntity target, double maxStep) {
    final distance = distanceTo(target);
    if (distance <= maxStep) return target;
    final ratio = maxStep / distance;
    return PositionEntity(x: x + (target.x - x) * ratio, y: y + (target.y - y) * ratio);
  }

  PositionEntity pointAtDistance(double distance, PositionEntity towards) {
    final length = distanceTo(towards);
    if (length == 0) return PositionEntity(x: x, y: y + distance);
    final ratio = distance / length;
    return PositionEntity(x: x + (towards.x - x) * ratio, y: y + (towards.y - y) * ratio);
  }
}
```

`lib/layers/domain/world/extensions/obstacle_rules.dart`:

```dart
import '../../entities/geometry/obstacle_entity.dart';
import '../../entities/geometry/position_entity.dart';
import 'position_geometry.dart';

extension ObstacleRules on ObstacleEntity {
  bool blocks(PositionEntity position, double radius) => this.position.distanceTo(position) < this.radius + radius;
}
```

- [ ] **Step 7: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/entities/geometry test/layers/domain/world/extensions`
Expected: `All tests passed!` (10 tests).

- [ ] **Step 8: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/core/config/constants/enum lib/layers/domain test/layers/domain
git commit -m "[PROJECT-X]: Add domain enums and geometry entities"
```

Expected de `flutter analyze`: `No issues found!`. (Si en el Step 1 se añadieron dependencias, incluir también `pubspec.yaml pubspec.lock` en el `git add`.)

---

### Task 2: Árbol, objeto, decoración y reglas de juego

**Files:**
- Create: `lib/layers/domain/rules/rules.dart`
- Create: `lib/layers/domain/entities/tree/tree_entity.dart`, `lib/layers/domain/entities/item/ground_item_entity.dart`, `lib/layers/domain/entities/decoration/decoration_entity.dart`
- Create: `lib/layers/domain/world/extensions/tree_rules.dart`
- Create: `test/mocks/domain/entities/tree/tree_entity_mock.dart`, `test/mocks/domain/entities/item/ground_item_entity_mock.dart`
- Test: `test/layers/domain/entities/tree/tree_entity_test.dart`, `test/layers/domain/world/extensions/tree_rules_test.dart`, `test/layers/domain/entities/item/ground_item_entity_test.dart`

**Interfaces:**
- Consumes: `PositionEntity`, `ObstacleEntity`, `TreeKind`, `ToolKind`, `DecorationKind` (Task 1).
- Produces: `Rules` (README §3.3); `TreeEntity({required String id, required TreeKind kind, required PositionEntity position, required double trunkRadius, required int woodYield, required int hitsToFell, int hitsTaken = 0})` con getters `footprint`, `hitsRemaining`, `isFelled` y `copyWith`; `GroundItemEntity({required String id, required ToolKind kind, required PositionEntity position})`; `DecorationEntity({required String id, required DecorationKind kind, required PositionEntity position})`; `extension TreeRules on TreeEntity { TreeEntity hit(); }`; `TreeEntityMock.mock`, `GroundItemEntityMock.mock`.

- [ ] **Step 1: Crear los mocks de test**

`test/mocks/domain/entities/tree/tree_entity_mock.dart`:

```dart
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

`test/mocks/domain/entities/item/ground_item_entity_mock.dart`:

```dart
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

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/domain/entities/tree/tree_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';

import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenTreeIsNewThenFootprintIsItsTrunkAndAllHitsRemain', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final footprint = tree.footprint;

    // then
    expect(footprint, const ObstacleEntity(position: PositionEntity(x: 200, y: 100), radius: 10));
    expect(tree.hitsRemaining, 5);
    expect(tree.isFelled, isFalse);
  });

  test('testWhenWoodYieldIsNegativeOrHitsToFellIsNotPositiveThenCreationFails', () {
    // given
    final negativeWood = -1;
    final noHits = 0;

    // when / then
    expect(
      () => TreeEntity(
        id: 'tree-1',
        kind: TreeKind.oak,
        position: const PositionEntity(x: 0, y: 0),
        trunkRadius: 10,
        woodYield: negativeWood,
        hitsToFell: 5,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => TreeEntity(
        id: 'tree-1',
        kind: TreeKind.oak,
        position: const PositionEntity(x: 0, y: 0),
        trunkRadius: 10,
        woodYield: 6,
        hitsToFell: noHits,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('testWhenCopyingWithIdAndPositionThenTheRestIsKept', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final copy = tree.copyWith(id: 'neighbour', position: const PositionEntity(x: 165, y: 100));

    // then
    expect(copy.id, 'neighbour');
    expect(copy.position, const PositionEntity(x: 165, y: 100));
    expect(copy.copyWith(id: 'tree-1', position: tree.position), tree);
  });
}
```

`test/layers/domain/world/extensions/tree_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/world/extensions/tree_rules.dart';

import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenHitTheRequiredTimesThenTreeIsFelledAndIgnoresMoreHits', () {
    // given
    var tree = TreeEntityMock.mock;

    // when
    for (var i = 0; i < 5; i++) {
      tree = tree.hit();
    }
    final hitAgain = tree.hit();

    // then
    expect(tree.isFelled, isTrue);
    expect(hitAgain.hitsRemaining, 0);
  });

  test('testWhenHitOnceThenOriginalTreeIsUnchanged', () {
    // given
    const tree = TreeEntityMock.mock;

    // when
    final hitTree = tree.hit();

    // then
    expect(tree.hitsRemaining, 5);
    expect(hitTree.hitsRemaining, 4);
  });
}
```

`test/layers/domain/entities/item/ground_item_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/layers/domain/entities/decoration/decoration_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/domain/entities/item/ground_item_entity_mock.dart';

void main() {
  test('testWhenCopyingItemWithSameValuesThenItIsEqual', () {
    // given
    const item = GroundItemEntityMock.mock;

    // when
    final copy = item.copyWith(position: const PositionEntity(x: 150, y: 100));

    // then
    expect(copy, item);
    expect(copy.hashCode, item.hashCode);
  });

  test('testWhenComparingDecorationsThenKindAndPositionMatter', () {
    // given
    const decoration = DecorationEntity(id: 'decoration-1', kind: DecorationKind.rock, position: PositionEntity(x: 1, y: 2));

    // when
    final isEqual = decoration == decoration.copyWith(kind: DecorationKind.rock);
    final isDifferent = decoration == decoration.copyWith(kind: DecorationKind.leaves);

    // then
    expect(isEqual, isTrue);
    expect(isDifferent, isFalse);
  });
}
```

- [ ] **Step 3: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/entities/tree test/layers/domain/entities/item test/layers/domain/world/extensions/tree_rules_test.dart`
Expected: FAIL por compilación (`No such file or directory` para `tree_entity.dart`).

- [ ] **Step 4: Crear `Rules`**

`lib/layers/domain/rules/rules.dart`:

```dart
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
```

- [ ] **Step 5: Crear las entidades**

`lib/layers/domain/entities/tree/tree_entity.dart`:

```dart
import '../../../../core/config/constants/enum/tree_kind.dart';
import '../geometry/obstacle_entity.dart';
import '../geometry/position_entity.dart';

class TreeEntity {
  final String id;
  final TreeKind kind;
  final PositionEntity position;
  final double trunkRadius;
  final int woodYield;
  final int hitsToFell;
  final int hitsTaken;

  const TreeEntity({
    required this.id,
    required this.kind,
    required this.position,
    required this.trunkRadius,
    required this.woodYield,
    required this.hitsToFell,
    this.hitsTaken = 0,
  }) : assert(woodYield >= 0),
       assert(hitsToFell > 0);

  ObstacleEntity get footprint => ObstacleEntity(position: position, radius: trunkRadius);

  int get hitsRemaining => hitsToFell - hitsTaken;

  bool get isFelled => hitsRemaining == 0;

  TreeEntity copyWith({
    String? id,
    TreeKind? kind,
    PositionEntity? position,
    double? trunkRadius,
    int? woodYield,
    int? hitsToFell,
    int? hitsTaken,
  }) {
    return TreeEntity(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      position: position ?? this.position,
      trunkRadius: trunkRadius ?? this.trunkRadius,
      woodYield: woodYield ?? this.woodYield,
      hitsToFell: hitsToFell ?? this.hitsToFell,
      hitsTaken: hitsTaken ?? this.hitsTaken,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TreeEntity &&
      other.id == id &&
      other.kind == kind &&
      other.position == position &&
      other.trunkRadius == trunkRadius &&
      other.woodYield == woodYield &&
      other.hitsToFell == hitsToFell &&
      other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, kind, position, trunkRadius, woodYield, hitsToFell, hitsTaken);
}
```

`lib/layers/domain/entities/item/ground_item_entity.dart`:

```dart
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../geometry/position_entity.dart';

class GroundItemEntity {
  final String id;
  final ToolKind kind;
  final PositionEntity position;

  const GroundItemEntity({required this.id, required this.kind, required this.position});

  GroundItemEntity copyWith({String? id, ToolKind? kind, PositionEntity? position}) {
    return GroundItemEntity(id: id ?? this.id, kind: kind ?? this.kind, position: position ?? this.position);
  }

  @override
  bool operator ==(Object other) =>
      other is GroundItemEntity && other.id == id && other.kind == kind && other.position == position;

  @override
  int get hashCode => Object.hash(id, kind, position);
}
```

`lib/layers/domain/entities/decoration/decoration_entity.dart`:

```dart
import '../../../../core/config/constants/enum/decoration_kind.dart';
import '../geometry/position_entity.dart';

class DecorationEntity {
  final String id;
  final DecorationKind kind;
  final PositionEntity position;

  const DecorationEntity({required this.id, required this.kind, required this.position});

  DecorationEntity copyWith({String? id, DecorationKind? kind, PositionEntity? position}) {
    return DecorationEntity(id: id ?? this.id, kind: kind ?? this.kind, position: position ?? this.position);
  }

  @override
  bool operator ==(Object other) =>
      other is DecorationEntity && other.id == id && other.kind == kind && other.position == position;

  @override
  int get hashCode => Object.hash(id, kind, position);
}
```

- [ ] **Step 6: Crear la extensión `TreeRules`**

`lib/layers/domain/world/extensions/tree_rules.dart`:

```dart
import '../../entities/tree/tree_entity.dart';

extension TreeRules on TreeEntity {
  TreeEntity hit() => isFelled ? this : copyWith(hitsTaken: hitsTaken + 1);
}
```

- [ ] **Step 7: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/entities/tree test/layers/domain/entities/item test/layers/domain/world/extensions/tree_rules_test.dart`
Expected: `All tests passed!` (7 tests).

- [ ] **Step 8: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain test/layers/domain test/mocks
git commit -m "[PROJECT-X]: Add tree, ground item and decoration entities"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 3: Planos y edificios

**Files:**
- Create: `lib/layers/domain/entities/building/blueprint_entity.dart`, `building_entity.dart`
- Create: `lib/layers/domain/rules/blueprints.dart`
- Create: `lib/layers/domain/world/extensions/building_rules.dart`
- Create: `test/mocks/domain/entities/building/building_entity_mock.dart`
- Test: `test/layers/domain/rules/blueprints_test.dart`, `test/layers/domain/world/extensions/building_rules_test.dart`

**Interfaces:**
- Consumes: `PositionEntity`, `ObstacleEntity`, `BlueprintId` (Task 1).
- Produces: `BlueprintEntity({required BlueprintId id, required int woodCost, required int hitsToBuild, required double footprintRadius})`; `BuildingEntity({required String id, required BlueprintEntity blueprint, required PositionEntity position, int hitsDone = 0})` con `footprint`, `progress`, `isComplete`, `copyWith`; `Blueprints.house`, `Blueprints.all`, `Blueprints.of(BlueprintId)`; `extension BuildingRules on BuildingEntity { BuildingEntity hammer(); }`; `BuildingEntityMock.mock`.

- [ ] **Step 1: Escribir el mock y los tests que fallan**

`test/mocks/domain/entities/building/building_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/building/building_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

abstract final class BuildingEntityMock {
  static const BuildingEntity mock = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: PositionEntity(x: 0, y: 0),
  );
}
```

`test/layers/domain/world/extensions/building_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/obstacle_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/building_rules.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';

void main() {
  test('testWhenHammeredThenProgressGrowsUntilComplete', () {
    // given
    var building = BuildingEntityMock.mock;

    // when
    building = building.hammer();
    final afterOneHit = building.progress;
    for (var i = 0; i < 7; i++) {
      building = building.hammer();
    }

    // then
    expect(afterOneHit, 0.125);
    expect(building.isComplete, isTrue);
  });

  test('testWhenCompleteThenHammerDoesNothing', () {
    // given
    final complete = BuildingEntityMock.mock.copyWith(hitsDone: 8);

    // when
    final hammered = complete.hammer();

    // then
    expect(hammered, same(complete));
  });

  test('testWhenPlacedThenFootprintUsesTheBlueprintRadius', () {
    // given
    const building = BuildingEntityMock.mock;

    // when
    final footprint = building.footprint;

    // then
    expect(footprint, const ObstacleEntity(position: PositionEntity(x: 0, y: 0), radius: 40));
    expect(building.progress, 0.0);
    expect(building.isComplete, isFalse);
  });
}
```

`test/layers/domain/rules/blueprints_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/building/blueprint_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

void main() {
  test('testWhenAskingForTheHouseThenReturnsItsCostHitsAndFootprint', () {
    // given
    const id = BlueprintId.house;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(
      blueprint,
      const BlueprintEntity(id: BlueprintId.house, woodCost: 15, hitsToBuild: 8, footprintRadius: 40),
    );
    expect(Blueprints.all, [Blueprints.house]);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/rules test/layers/domain/world/extensions/building_rules_test.dart`
Expected: FAIL por compilación (`No such file or directory` para `building_entity.dart`).

- [ ] **Step 3: Crear las entidades**

`lib/layers/domain/entities/building/blueprint_entity.dart`:

```dart
import '../../../../core/config/constants/enum/blueprint_id.dart';

class BlueprintEntity {
  final BlueprintId id;
  final int woodCost;
  final int hitsToBuild;
  final double footprintRadius;

  const BlueprintEntity({
    required this.id,
    required this.woodCost,
    required this.hitsToBuild,
    required this.footprintRadius,
  });

  @override
  bool operator ==(Object other) =>
      other is BlueprintEntity &&
      other.id == id &&
      other.woodCost == woodCost &&
      other.hitsToBuild == hitsToBuild &&
      other.footprintRadius == footprintRadius;

  @override
  int get hashCode => Object.hash(id, woodCost, hitsToBuild, footprintRadius);
}
```

`lib/layers/domain/entities/building/building_entity.dart`:

```dart
import '../geometry/obstacle_entity.dart';
import '../geometry/position_entity.dart';
import 'blueprint_entity.dart';

class BuildingEntity {
  final String id;
  final BlueprintEntity blueprint;
  final PositionEntity position;
  final int hitsDone;

  const BuildingEntity({required this.id, required this.blueprint, required this.position, this.hitsDone = 0});

  ObstacleEntity get footprint => ObstacleEntity(position: position, radius: blueprint.footprintRadius);

  double get progress => hitsDone / blueprint.hitsToBuild;

  bool get isComplete => hitsDone >= blueprint.hitsToBuild;

  BuildingEntity copyWith({String? id, BlueprintEntity? blueprint, PositionEntity? position, int? hitsDone}) {
    return BuildingEntity(
      id: id ?? this.id,
      blueprint: blueprint ?? this.blueprint,
      position: position ?? this.position,
      hitsDone: hitsDone ?? this.hitsDone,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BuildingEntity &&
      other.id == id &&
      other.blueprint == blueprint &&
      other.position == position &&
      other.hitsDone == hitsDone;

  @override
  int get hashCode => Object.hash(id, blueprint, position, hitsDone);
}
```

- [ ] **Step 4: Crear el catálogo y la extensión**

`lib/layers/domain/rules/blueprints.dart`:

```dart
import '../../../core/config/constants/enum/blueprint_id.dart';
import '../entities/building/blueprint_entity.dart';

abstract final class Blueprints {
  static const BlueprintEntity house = BlueprintEntity(
    id: BlueprintId.house,
    woodCost: 15,
    hitsToBuild: 8,
    footprintRadius: 40,
  );

  static const List<BlueprintEntity> all = [house];

  static BlueprintEntity of(BlueprintId id) => all.firstWhere((blueprint) => blueprint.id == id);
}
```

`lib/layers/domain/world/extensions/building_rules.dart`:

```dart
import '../../entities/building/building_entity.dart';

extension BuildingRules on BuildingEntity {
  BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
}
```

- [ ] **Step 5: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/rules test/layers/domain/world/extensions/building_rules_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 6: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain test/layers/domain test/mocks
git commit -m "[PROJECT-X]: Add blueprint and building entities"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 4: Jugador, inventario, intención y actividad

**Files:**
- Create: `lib/layers/domain/entities/player/inventory_entity.dart`, `intent_entity.dart`, `activity_entity.dart`, `player_entity.dart`
- Create: `lib/layers/domain/world/extensions/inventory_rules.dart`, `player_rules.dart`
- Create: `test/mocks/domain/entities/player/player_entity_mock.dart`
- Test: `test/layers/domain/world/extensions/inventory_rules_test.dart`, `player_rules_test.dart`, `test/layers/domain/entities/player/player_entity_test.dart`

**Interfaces:**
- Consumes: `PositionEntity`, `PositionGeometry.moveTowards`, `ToolKind` (Task 1).
- Produces: `InventoryEntity({int wood = 0, Set<ToolKind> tools = const {}})`; `sealed class IntentEntity` → `ChopIntentEntity({required String treeId})`, `ConstructIntentEntity({required String buildingId})`; `sealed class ActivityEntity` → `IdleActivityEntity()`, `WalkingActivityEntity({required PositionEntity destination, IntentEntity? intent})`, `WorkingActivityEntity({required IntentEntity intent, required double elapsedMs})`; `PlayerEntity({required PositionEntity position, required double speed, required double radius, InventoryEntity inventory = const InventoryEntity(), ActivityEntity activity = const IdleActivityEntity()})` con `isMoving` y `copyWith`; extensiones `InventoryRules` y `PlayerRules` de README §3.3; `PlayerEntityMock.mock`.

- [ ] **Step 1: Escribir el mock y los tests que fallan**

`test/mocks/domain/entities/player/player_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';

abstract final class PlayerEntityMock {
  static const PlayerEntity mock = PlayerEntity(position: PositionEntity(x: 100, y: 100), speed: 100, radius: 8);
}
```

`test/layers/domain/world/extensions/inventory_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

void main() {
  test('testWhenSpendingAffordableWoodThenReturnsInventoryWithTheRest', () {
    // given
    final inventory = const InventoryEntity().addWood(6);

    // when
    final afterSpending = inventory.spendWood(4);

    // then
    expect(afterSpending?.wood, 2);
  });

  test('testWhenSpendingMoreWoodThanStoredThenReturnsNull', () {
    // given
    final inventory = const InventoryEntity().addWood(3);

    // when
    final afterSpending = inventory.spendWood(5);

    // then
    expect(afterSpending, isNull);
    expect(inventory.wood, 3);
  });

  test('testWhenAddingToolThenInventoryHasIt', () {
    // given
    const inventory = InventoryEntity();

    // when
    final withAxe = inventory.addTool(ToolKind.axe);

    // then
    expect(inventory.hasTool(ToolKind.axe), isFalse);
    expect(withAxe.hasTool(ToolKind.axe), isTrue);
  });

  test('testWhenAddingNegativeWoodThenFails', () {
    // given
    const inventory = InventoryEntity();

    // when / then
    expect(() => inventory.addWood(-1), throwsArgumentError);
  });
}
```

`test/layers/domain/world/extensions/player_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/entities/player/intent_entity.dart';
import 'package:rpg/layers/domain/world/extensions/player_rules.dart';

import '../../../../mocks/domain/entities/player/player_entity_mock.dart';

void main() {
  test('testWhenCreatedThenIsIdleWithoutNextPosition', () {
    // given
    const player = PlayerEntityMock.mock;

    // when
    final next = player.nextPosition(1000);

    // then
    expect(player.activity, const IdleActivityEntity());
    expect(next, isNull);
  });

  test('testWhenWalkingThenNextPositionAdvancesSpeedTimesSecondsWithoutMoving', () {
    // given
    final player = PlayerEntityMock.mock
        .copyWith(position: const PositionEntity(x: 0, y: 0))
        .walkTo(const PositionEntity(x: 1000, y: 0));

    // when
    final next = player.nextPosition(500);

    // then
    expect(next, const PositionEntity(x: 50, y: 0));
    expect(player.position, const PositionEntity(x: 0, y: 0));
  });

  test('testWhenStoppingThenReturnsToIdle', () {
    // given
    final walking = PlayerEntityMock.mock.walkTo(const PositionEntity(x: 10, y: 0));

    // when
    final stopped = walking.stop();

    // then
    expect(stopped.isMoving, isFalse);
    expect(stopped.activity, const IdleActivityEntity());
  });

  test('testWhenContinuingWorkThenTracksElapsedTime', () {
    // given
    final working = PlayerEntityMock.mock.startWork(const ChopIntentEntity(treeId: 'tree-1'));

    // when
    final later = working.continueWork(300);

    // then
    expect(later.activity, const WorkingActivityEntity(intent: ChopIntentEntity(treeId: 'tree-1'), elapsedMs: 300));
  });
}
```

`test/layers/domain/entities/player/player_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';

void main() {
  test('testWhenSpeedOrRadiusAreNotPositiveThenCreationFails', () {
    // given
    const position = PositionEntity(x: 0, y: 0);
    final zero = 0.0;

    // when / then
    expect(() => PlayerEntity(position: position, speed: zero, radius: 10), throwsA(isA<AssertionError>()));
    expect(() => PlayerEntity(position: position, speed: 100, radius: zero), throwsA(isA<AssertionError>()));
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/entities/player test/layers/domain/world/extensions/inventory_rules_test.dart test/layers/domain/world/extensions/player_rules_test.dart`
Expected: FAIL por compilación (`No such file or directory` para `player_entity.dart`).

- [ ] **Step 3: Crear inventario, intención y actividad**

`lib/layers/domain/entities/player/inventory_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final int wood;
  final Set<ToolKind> tools;

  const InventoryEntity({this.wood = 0, this.tools = const {}});

  InventoryEntity copyWith({int? wood, Set<ToolKind>? tools}) {
    return InventoryEntity(wood: wood ?? this.wood, tools: tools ?? this.tools);
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity && other.wood == wood && const SetEquality<ToolKind>().equals(other.tools, tools);

  @override
  int get hashCode => Object.hash(wood, const SetEquality<ToolKind>().hash(tools));
}
```

`lib/layers/domain/entities/player/intent_entity.dart`:

```dart
sealed class IntentEntity {
  const IntentEntity();
}

final class ChopIntentEntity extends IntentEntity {
  final String treeId;

  const ChopIntentEntity({required this.treeId});

  @override
  bool operator ==(Object other) => other is ChopIntentEntity && other.treeId == treeId;

  @override
  int get hashCode => Object.hash(ChopIntentEntity, treeId);
}

final class ConstructIntentEntity extends IntentEntity {
  final String buildingId;

  const ConstructIntentEntity({required this.buildingId});

  @override
  bool operator ==(Object other) => other is ConstructIntentEntity && other.buildingId == buildingId;

  @override
  int get hashCode => Object.hash(ConstructIntentEntity, buildingId);
}
```

`lib/layers/domain/entities/player/activity_entity.dart`:

```dart
import '../geometry/position_entity.dart';
import 'intent_entity.dart';

sealed class ActivityEntity {
  const ActivityEntity();
}

final class IdleActivityEntity extends ActivityEntity {
  const IdleActivityEntity();

  @override
  bool operator ==(Object other) => other is IdleActivityEntity;

  @override
  int get hashCode => (IdleActivityEntity).hashCode;
}

final class WalkingActivityEntity extends ActivityEntity {
  final PositionEntity destination;
  final IntentEntity? intent;

  const WalkingActivityEntity({required this.destination, this.intent});

  @override
  bool operator ==(Object other) =>
      other is WalkingActivityEntity && other.destination == destination && other.intent == intent;

  @override
  int get hashCode => Object.hash(WalkingActivityEntity, destination, intent);
}

final class WorkingActivityEntity extends ActivityEntity {
  final IntentEntity intent;
  final double elapsedMs;

  const WorkingActivityEntity({required this.intent, required this.elapsedMs});

  WorkingActivityEntity copyWith({IntentEntity? intent, double? elapsedMs}) {
    return WorkingActivityEntity(intent: intent ?? this.intent, elapsedMs: elapsedMs ?? this.elapsedMs);
  }

  @override
  bool operator ==(Object other) =>
      other is WorkingActivityEntity && other.intent == intent && other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(WorkingActivityEntity, intent, elapsedMs);
}
```

- [ ] **Step 4: Crear el jugador**

`lib/layers/domain/entities/player/player_entity.dart`:

```dart
import '../geometry/position_entity.dart';
import 'activity_entity.dart';
import 'inventory_entity.dart';

class PlayerEntity {
  final PositionEntity position;
  final double speed;
  final double radius;
  final InventoryEntity inventory;
  final ActivityEntity activity;

  const PlayerEntity({
    required this.position,
    required this.speed,
    required this.radius,
    this.inventory = const InventoryEntity(),
    this.activity = const IdleActivityEntity(),
  }) : assert(speed > 0),
       assert(radius > 0);

  bool get isMoving => activity is WalkingActivityEntity;

  PlayerEntity copyWith({
    PositionEntity? position,
    double? speed,
    double? radius,
    InventoryEntity? inventory,
    ActivityEntity? activity,
  }) {
    return PlayerEntity(
      position: position ?? this.position,
      speed: speed ?? this.speed,
      radius: radius ?? this.radius,
      inventory: inventory ?? this.inventory,
      activity: activity ?? this.activity,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerEntity &&
      other.position == position &&
      other.speed == speed &&
      other.radius == radius &&
      other.inventory == inventory &&
      other.activity == activity;

  @override
  int get hashCode => Object.hash(position, speed, radius, inventory, activity);
}
```

- [ ] **Step 5: Crear las extensiones**

`lib/layers/domain/world/extensions/inventory_rules.dart`:

```dart
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/player/inventory_entity.dart';

extension InventoryRules on InventoryEntity {
  InventoryEntity addWood(int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount', 'Cannot add a negative amount of wood');
    return copyWith(wood: wood + amount);
  }

  InventoryEntity? spendWood(int amount) => amount > wood ? null : copyWith(wood: wood - amount);

  InventoryEntity addTool(ToolKind tool) => copyWith(tools: {...tools, tool});

  bool hasTool(ToolKind tool) => tools.contains(tool);
}
```

`lib/layers/domain/world/extensions/player_rules.dart`:

```dart
import '../../entities/geometry/position_entity.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';
import '../../entities/player/inventory_entity.dart';
import '../../entities/player/player_entity.dart';
import 'position_geometry.dart';

extension PlayerRules on PlayerEntity {
  PlayerEntity walkTo(PositionEntity destination, {IntentEntity? intent}) {
    return copyWith(activity: WalkingActivityEntity(destination: destination, intent: intent));
  }

  PlayerEntity startWork(IntentEntity intent) {
    return copyWith(activity: WorkingActivityEntity(intent: intent, elapsedMs: 0));
  }

  PlayerEntity continueWork(double elapsedMs) {
    final working = activity;
    if (working is! WorkingActivityEntity) return this;
    return copyWith(activity: working.copyWith(elapsedMs: elapsedMs));
  }

  PlayerEntity stop() => copyWith(activity: const IdleActivityEntity());

  PositionEntity? nextPosition(double deltaMs) {
    final walking = activity;
    if (walking is! WalkingActivityEntity) return null;
    return position.moveTowards(walking.destination, speed * deltaMs / 1000);
  }

  PlayerEntity placeAt(PositionEntity position) => copyWith(position: position);

  PlayerEntity withInventory(InventoryEntity inventory) => copyWith(inventory: inventory);
}
```

- [ ] **Step 6: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/entities/player test/layers/domain/world/extensions/inventory_rules_test.dart test/layers/domain/world/extensions/player_rules_test.dart`
Expected: `All tests passed!` (9 tests).

- [ ] **Step 7: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain test/layers/domain test/mocks
git commit -m "[PROJECT-X]: Add player, inventory, intent and activity entities"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 5: Eventos, resultados y entidades de lectura

**Files:**
- Create: `lib/layers/domain/entities/game/game_event_entity.dart`, `construction_result_entity.dart`, `build_option_entity.dart`, `player_status_entity.dart`, `quest_progress_entity.dart`, `world_snapshot_entity.dart`
- Create: `test/mocks/domain/entities/game/player_status_entity_mock.dart`, `world_snapshot_entity_mock.dart`
- Test: `test/layers/domain/entities/game/game_event_entity_test.dart`, `construction_result_entity_test.dart`, `player_status_entity_test.dart`, `world_snapshot_entity_test.dart`, `quest_progress_entity_test.dart`

**Interfaces:**
- Consumes: entidades de las Tasks 1–4; `QuestId`, `BlueprintId`, `ToolKind`, `ConstructionRejection`, `PlayerActivity`.
- Produces (README §3.2): `sealed class GameEventEntity` → `ItemPickedUpEventEntity({required String itemId, required ToolKind kind})`, `PlayerBlockedEventEntity()`, `TreeHitEventEntity({required String treeId, required int hitsRemaining})`, `TreeFelledEventEntity({required String treeId, required int wood})`, `BuildingHammeredEventEntity({required String buildingId, required double progress})`, `BuildingCompletedEventEntity({required String buildingId, required BlueprintId blueprint})`, `QuestCompletedEventEntity({required QuestId questId})`; `sealed class ConstructionResultEntity` → `ConstructionStartedEntity({required BuildingEntity building})`, `ConstructionRejectedEntity({required ConstructionRejection reason})`; `BuildOptionEntity({required BlueprintId blueprint, required int woodCost, required bool isAffordable})`; `PlayerStatusEntity({required PositionEntity position, required PlayerActivity activity, PositionEntity? target, required double swingProgress, required int wood, required bool hasAxe})`; `QuestProgressEntity({required QuestId id, required int progress, required int target, required bool isCompleted, required bool isCurrent})`; `WorldSnapshotEntity({required double width, required double height, required List<TreeEntity> trees, required List<GroundItemEntity> items, required List<DecorationEntity> decorations, required List<BuildingEntity> buildings})`; mocks `PlayerStatusEntityMock.mock`, `WorldSnapshotEntityMock.mock`.

- [ ] **Step 1: Escribir los mocks**

`test/mocks/domain/entities/game/player_status_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/layers/domain/entities/game/player_status_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

abstract final class PlayerStatusEntityMock {
  static const PlayerStatusEntity mock = PlayerStatusEntity(
    position: PositionEntity(x: 100, y: 100),
    activity: PlayerActivity.idle,
    swingProgress: 0,
    wood: 0,
    hasAxe: false,
  );
}
```

`test/mocks/domain/entities/game/world_snapshot_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/game/world_snapshot_entity.dart';

import '../building/building_entity_mock.dart';
import '../item/ground_item_entity_mock.dart';
import '../tree/tree_entity_mock.dart';

abstract final class WorldSnapshotEntityMock {
  static const WorldSnapshotEntity mock = WorldSnapshotEntity(
    width: 1000,
    height: 1000,
    trees: [TreeEntityMock.mock],
    items: [GroundItemEntityMock.mock],
    decorations: [],
    buildings: [BuildingEntityMock.mock],
  );
}
```

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/domain/entities/game/game_event_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';

void main() {
  test('testWhenComparingEventsWithSameValuesThenTheyAreEqual', () {
    // given
    const List<GameEventEntity> events = [
      ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe),
      PlayerBlockedEventEntity(),
      TreeHitEventEntity(treeId: 'tree-1', hitsRemaining: 4),
      TreeFelledEventEntity(treeId: 'tree-1', wood: 6),
      BuildingHammeredEventEntity(buildingId: 'building-1', progress: 0.125),
      BuildingCompletedEventEntity(buildingId: 'building-1', blueprint: BlueprintId.house),
      QuestCompletedEventEntity(questId: QuestId.pickUpAxe),
    ];

    // when
    final copies = <GameEventEntity>[
      const ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe),
      const PlayerBlockedEventEntity(),
      const TreeHitEventEntity(treeId: 'tree-1', hitsRemaining: 4),
      const TreeFelledEventEntity(treeId: 'tree-1', wood: 6),
      const BuildingHammeredEventEntity(buildingId: 'building-1', progress: 0.125),
      const BuildingCompletedEventEntity(buildingId: 'building-1', blueprint: BlueprintId.house),
      const QuestCompletedEventEntity(questId: QuestId.pickUpAxe),
    ];

    // then
    expect(copies, events);
    expect(copies.map((event) => event.hashCode), events.map((event) => event.hashCode));
  });

  test('testWhenEventValuesDifferThenTheyAreNotEqual', () {
    // given
    const felled = TreeFelledEventEntity(treeId: 'tree-1', wood: 6);

    // when
    final isEqual = felled == const TreeFelledEventEntity(treeId: 'tree-1', wood: 5);

    // then
    expect(isEqual, isFalse);
  });
}
```

`test/layers/domain/entities/game/construction_result_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/construction_rejection.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';

void main() {
  test('testWhenComparingResultsThenBuildingAndReasonMatter', () {
    // given
    const started = ConstructionStartedEntity(building: BuildingEntityMock.mock);
    const rejected = ConstructionRejectedEntity(reason: ConstructionRejection.blocked);

    // when
    final sameStarted = started == const ConstructionStartedEntity(building: BuildingEntityMock.mock);
    final sameRejected = rejected == const ConstructionRejectedEntity(reason: ConstructionRejection.blocked);
    final otherReason = rejected == const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood);

    // then
    expect(sameStarted, isTrue);
    expect(sameRejected, isTrue);
    expect(otherReason, isFalse);
  });
}
```

`test/layers/domain/entities/game/player_status_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/layers/domain/entities/game/player_status_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/domain/entities/game/player_status_entity_mock.dart';

void main() {
  test('testWhenTargetsDifferThenStatusesAreNotEqual', () {
    // given
    const status = PlayerStatusEntityMock.mock;

    // when
    final sameStatus = status ==
        const PlayerStatusEntity(
          position: PositionEntity(x: 100, y: 100),
          activity: PlayerActivity.idle,
          swingProgress: 0,
          wood: 0,
          hasAxe: false,
        );
    final withTarget = status ==
        const PlayerStatusEntity(
          position: PositionEntity(x: 100, y: 100),
          activity: PlayerActivity.idle,
          target: PositionEntity(x: 1, y: 1),
          swingProgress: 0,
          wood: 0,
          hasAxe: false,
        );

    // then
    expect(sameStatus, isTrue);
    expect(withTarget, isFalse);
  });
}
```

`test/layers/domain/entities/game/world_snapshot_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/game/world_snapshot_entity.dart';

import '../../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../../mocks/domain/entities/game/world_snapshot_entity_mock.dart';
import '../../../../mocks/domain/entities/item/ground_item_entity_mock.dart';
import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';

void main() {
  test('testWhenListsHaveTheSameContentThenSnapshotsAreEqual', () {
    // given
    const snapshot = WorldSnapshotEntityMock.mock;

    // when
    final copy = WorldSnapshotEntity(
      width: 1000,
      height: 1000,
      trees: [TreeEntityMock.mock],
      items: [GroundItemEntityMock.mock],
      decorations: [],
      buildings: [BuildingEntityMock.mock],
    );

    // then
    expect(copy, snapshot);
    expect(copy.hashCode, snapshot.hashCode);
  });

  test('testWhenATreeIsMissingThenSnapshotsAreNotEqual', () {
    // given
    const snapshot = WorldSnapshotEntityMock.mock;

    // when
    final withoutTrees = WorldSnapshotEntity(
      width: 1000,
      height: 1000,
      trees: [],
      items: [GroundItemEntityMock.mock],
      decorations: [],
      buildings: [BuildingEntityMock.mock],
    );

    // then
    expect(withoutTrees == snapshot, isFalse);
  });
}
```

`test/layers/domain/entities/game/quest_progress_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/entities/game/build_option_entity.dart';
import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';

void main() {
  test('testWhenComparingQuestProgressThenEveryFieldMatters', () {
    // given
    const progress = QuestProgressEntity(id: QuestId.gatherWood, progress: 3, target: 15, isCompleted: false, isCurrent: true);

    // when
    final isEqual =
        progress == const QuestProgressEntity(id: QuestId.gatherWood, progress: 3, target: 15, isCompleted: false, isCurrent: true);
    final notCurrent =
        progress == const QuestProgressEntity(id: QuestId.gatherWood, progress: 3, target: 15, isCompleted: false, isCurrent: false);

    // then
    expect(isEqual, isTrue);
    expect(notCurrent, isFalse);
  });

  test('testWhenComparingBuildOptionsThenAffordabilityMatters', () {
    // given
    const option = BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: true);

    // when
    final isEqual = option == const BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: true);
    final notAffordable = option == const BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: false);

    // then
    expect(isEqual, isTrue);
    expect(notAffordable, isFalse);
  });
}
```

- [ ] **Step 3: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/entities/game`
Expected: FAIL por compilación (`No such file or directory` para `game_event_entity.dart`).

- [ ] **Step 4: Crear eventos y resultados**

`lib/layers/domain/entities/game/game_event_entity.dart`:

```dart
import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/quest_id.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

sealed class GameEventEntity {
  const GameEventEntity();
}

final class ItemPickedUpEventEntity extends GameEventEntity {
  final String itemId;
  final ToolKind kind;

  const ItemPickedUpEventEntity({required this.itemId, required this.kind});

  @override
  bool operator ==(Object other) => other is ItemPickedUpEventEntity && other.itemId == itemId && other.kind == kind;

  @override
  int get hashCode => Object.hash(ItemPickedUpEventEntity, itemId, kind);
}

final class PlayerBlockedEventEntity extends GameEventEntity {
  const PlayerBlockedEventEntity();

  @override
  bool operator ==(Object other) => other is PlayerBlockedEventEntity;

  @override
  int get hashCode => (PlayerBlockedEventEntity).hashCode;
}

final class TreeHitEventEntity extends GameEventEntity {
  final String treeId;
  final int hitsRemaining;

  const TreeHitEventEntity({required this.treeId, required this.hitsRemaining});

  @override
  bool operator ==(Object other) =>
      other is TreeHitEventEntity && other.treeId == treeId && other.hitsRemaining == hitsRemaining;

  @override
  int get hashCode => Object.hash(TreeHitEventEntity, treeId, hitsRemaining);
}

final class TreeFelledEventEntity extends GameEventEntity {
  final String treeId;
  final int wood;

  const TreeFelledEventEntity({required this.treeId, required this.wood});

  @override
  bool operator ==(Object other) => other is TreeFelledEventEntity && other.treeId == treeId && other.wood == wood;

  @override
  int get hashCode => Object.hash(TreeFelledEventEntity, treeId, wood);
}

final class BuildingHammeredEventEntity extends GameEventEntity {
  final String buildingId;
  final double progress;

  const BuildingHammeredEventEntity({required this.buildingId, required this.progress});

  @override
  bool operator ==(Object other) =>
      other is BuildingHammeredEventEntity && other.buildingId == buildingId && other.progress == progress;

  @override
  int get hashCode => Object.hash(BuildingHammeredEventEntity, buildingId, progress);
}

final class BuildingCompletedEventEntity extends GameEventEntity {
  final String buildingId;
  final BlueprintId blueprint;

  const BuildingCompletedEventEntity({required this.buildingId, required this.blueprint});

  @override
  bool operator ==(Object other) =>
      other is BuildingCompletedEventEntity && other.buildingId == buildingId && other.blueprint == blueprint;

  @override
  int get hashCode => Object.hash(BuildingCompletedEventEntity, buildingId, blueprint);
}

final class QuestCompletedEventEntity extends GameEventEntity {
  final QuestId questId;

  const QuestCompletedEventEntity({required this.questId});

  @override
  bool operator ==(Object other) => other is QuestCompletedEventEntity && other.questId == questId;

  @override
  int get hashCode => Object.hash(QuestCompletedEventEntity, questId);
}
```

`lib/layers/domain/entities/game/construction_result_entity.dart`:

```dart
import '../../../../core/config/constants/enum/construction_rejection.dart';
import '../building/building_entity.dart';

sealed class ConstructionResultEntity {
  const ConstructionResultEntity();
}

final class ConstructionStartedEntity extends ConstructionResultEntity {
  final BuildingEntity building;

  const ConstructionStartedEntity({required this.building});

  @override
  bool operator ==(Object other) => other is ConstructionStartedEntity && other.building == building;

  @override
  int get hashCode => Object.hash(ConstructionStartedEntity, building);
}

final class ConstructionRejectedEntity extends ConstructionResultEntity {
  final ConstructionRejection reason;

  const ConstructionRejectedEntity({required this.reason});

  @override
  bool operator ==(Object other) => other is ConstructionRejectedEntity && other.reason == reason;

  @override
  int get hashCode => Object.hash(ConstructionRejectedEntity, reason);
}
```

- [ ] **Step 5: Crear las entidades de lectura**

`lib/layers/domain/entities/game/build_option_entity.dart`:

```dart
import '../../../../core/config/constants/enum/blueprint_id.dart';

class BuildOptionEntity {
  final BlueprintId blueprint;
  final int woodCost;
  final bool isAffordable;

  const BuildOptionEntity({required this.blueprint, required this.woodCost, required this.isAffordable});

  @override
  bool operator ==(Object other) =>
      other is BuildOptionEntity &&
      other.blueprint == blueprint &&
      other.woodCost == woodCost &&
      other.isAffordable == isAffordable;

  @override
  int get hashCode => Object.hash(blueprint, woodCost, isAffordable);
}
```

`lib/layers/domain/entities/game/player_status_entity.dart`:

```dart
import '../../../../core/config/constants/enum/player_activity.dart';
import '../geometry/position_entity.dart';

class PlayerStatusEntity {
  final PositionEntity position;
  final PlayerActivity activity;
  final PositionEntity? target;
  final double swingProgress;
  final int wood;
  final bool hasAxe;

  const PlayerStatusEntity({
    required this.position,
    required this.activity,
    this.target,
    required this.swingProgress,
    required this.wood,
    required this.hasAxe,
  });

  @override
  bool operator ==(Object other) =>
      other is PlayerStatusEntity &&
      other.position == position &&
      other.activity == activity &&
      other.target == target &&
      other.swingProgress == swingProgress &&
      other.wood == wood &&
      other.hasAxe == hasAxe;

  @override
  int get hashCode => Object.hash(position, activity, target, swingProgress, wood, hasAxe);
}
```

`lib/layers/domain/entities/game/quest_progress_entity.dart`:

```dart
import '../../../../core/config/constants/enum/quest_id.dart';

class QuestProgressEntity {
  final QuestId id;
  final int progress;
  final int target;
  final bool isCompleted;
  final bool isCurrent;

  const QuestProgressEntity({
    required this.id,
    required this.progress,
    required this.target,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  bool operator ==(Object other) =>
      other is QuestProgressEntity &&
      other.id == id &&
      other.progress == progress &&
      other.target == target &&
      other.isCompleted == isCompleted &&
      other.isCurrent == isCurrent;

  @override
  int get hashCode => Object.hash(id, progress, target, isCompleted, isCurrent);

  @override
  String toString() =>
      'QuestProgressEntity(id: $id, progress: $progress, target: $target, isCompleted: $isCompleted, isCurrent: $isCurrent)';
}
```

`lib/layers/domain/entities/game/world_snapshot_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../building/building_entity.dart';
import '../decoration/decoration_entity.dart';
import '../item/ground_item_entity.dart';
import '../tree/tree_entity.dart';

class WorldSnapshotEntity {
  final double width;
  final double height;
  final List<TreeEntity> trees;
  final List<GroundItemEntity> items;
  final List<DecorationEntity> decorations;
  final List<BuildingEntity> buildings;

  const WorldSnapshotEntity({
    required this.width,
    required this.height,
    required this.trees,
    required this.items,
    required this.decorations,
    required this.buildings,
  });

  @override
  bool operator ==(Object other) =>
      other is WorldSnapshotEntity &&
      other.width == width &&
      other.height == height &&
      const ListEquality<TreeEntity>().equals(other.trees, trees) &&
      const ListEquality<GroundItemEntity>().equals(other.items, items) &&
      const ListEquality<DecorationEntity>().equals(other.decorations, decorations) &&
      const ListEquality<BuildingEntity>().equals(other.buildings, buildings);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    const ListEquality<TreeEntity>().hash(trees),
    const ListEquality<GroundItemEntity>().hash(items),
    const ListEquality<DecorationEntity>().hash(decorations),
    const ListEquality<BuildingEntity>().hash(buildings),
  );
}
```

- [ ] **Step 6: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/entities/game`
Expected: `All tests passed!` (7 tests).

- [ ] **Step 7: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain test/layers/domain test/mocks
git commit -m "[PROJECT-X]: Add game events, results and read entities"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 6: `WorldState`

**Files:**
- Create: `lib/layers/domain/world/world_state.dart`
- Test: `test/layers/domain/world/world_state_test.dart`

**Interfaces:**
- Consumes: `PlayerEntity`, `TreeEntity`, `GroundItemEntity`, `DecorationEntity`, `BuildingEntity`, `ObstacleEntity`, `ObstacleRules.blocks`, `PlayerEntityMock.mock`, `TreeEntityMock.mock`.
- Produces:

```dart
class WorldState {
  WorldState({required double width, required double height, required PlayerEntity player, required List<TreeEntity> trees, required List<GroundItemEntity> items, required List<DecorationEntity> decorations});
  final double width; final double height; PlayerEntity player;
  final List<DecorationEntity> decorations;
  final Map<String, TreeEntity> trees; final Map<String, GroundItemEntity> items; final Map<String, BuildingEntity> buildings;
  List<ObstacleEntity> obstacles();
  bool isBlocked(PositionEntity position, double radius);
  PositionEntity clamp(PositionEntity position, double margin);
  bool isInside(PositionEntity position, double margin);
  String nextId(String prefix);
}
```

Los mapas conservan el orden de inserción (los literales `{}` de Dart son `LinkedHashMap`), igual que el `LinkedHashMap` de Kotlin.

- [ ] **Step 1: Escribir el test que falla**

`test/layers/domain/world/world_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/world_state.dart';

import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';

WorldState _state({double width = 200, double height = 100}) => WorldState(
  width: width,
  height: height,
  player: PlayerEntityMock.mock,
  trees: [TreeEntityMock.mock],
  items: [],
  decorations: [],
);

void main() {
  test('testWhenClampingAPositionOutsideTheWorldThenKeepsTheMarginInside', () {
    // given
    final state = _state();

    // when
    final clamped = state.clamp(const PositionEntity(x: -50, y: 500), 8);

    // then
    expect(clamped, const PositionEntity(x: 8, y: 92));
  });

  test('testWhenAPositionIsTooCloseToTheEdgeThenItIsNotInside', () {
    // given
    final state = _state();

    // when
    final inside = state.isInside(const PositionEntity(x: 50, y: 50), 8);
    final nearEdge = state.isInside(const PositionEntity(x: 5, y: 50), 8);

    // then
    expect(inside, isTrue);
    expect(nearEdge, isFalse);
  });

  test('testWhenAskingForIdsThenTheyAreSequentialPerPrefix', () {
    // given
    final state = _state();

    // when
    final ids = [state.nextId('building'), state.nextId('building'), state.nextId('other')];

    // then
    expect(ids, ['building-1', 'building-2', 'other-1']);
  });

  test('testWhenTreesAndBuildingsStandThenTheyBlock', () {
    // given
    final state = _state(width: 1000, height: 1000);
    state.buildings[BuildingEntityMock.mock.id] = BuildingEntityMock.mock.copyWith(
      position: const PositionEntity(x: 500, y: 500),
    );

    // when
    final obstacles = state.obstacles();
    final blockedByTree = state.isBlocked(const PositionEntity(x: 200, y: 115), 8);
    final blockedByBuilding = state.isBlocked(const PositionEntity(x: 500, y: 545), 8);
    final free = state.isBlocked(const PositionEntity(x: 300, y: 300), 8);

    // then
    expect(obstacles.length, 2);
    expect(blockedByTree, isTrue);
    expect(blockedByBuilding, isTrue);
    expect(free, isFalse);
  });

  test('testWhenSizeIsNotPositiveThenCreationFails', () {
    // given
    final zero = 0.0;

    // when / then
    expect(() => _state(width: zero), throwsA(isA<AssertionError>()));
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/layers/domain/world/world_state_test.dart`
Expected: FAIL por compilación (`No such file or directory` para `world_state.dart`).

- [ ] **Step 3: Implementar `WorldState`**

`lib/layers/domain/world/world_state.dart`:

```dart
import 'dart:math';

import '../entities/building/building_entity.dart';
import '../entities/decoration/decoration_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/item/ground_item_entity.dart';
import '../entities/player/player_entity.dart';
import '../entities/tree/tree_entity.dart';
import 'extensions/obstacle_rules.dart';

class WorldState {
  WorldState({
    required this.width,
    required this.height,
    required this.player,
    required List<TreeEntity> trees,
    required List<GroundItemEntity> items,
    required List<DecorationEntity> decorations,
  }) : assert(width > 0 && height > 0),
       trees = {for (final tree in trees) tree.id: tree},
       items = {for (final item in items) item.id: item},
       decorations = List.unmodifiable(decorations);

  final double width;
  final double height;
  PlayerEntity player;
  final List<DecorationEntity> decorations;
  final Map<String, TreeEntity> trees;
  final Map<String, GroundItemEntity> items;
  final Map<String, BuildingEntity> buildings = {};
  final Map<String, int> _idCounters = {};

  List<ObstacleEntity> obstacles() => [
    for (final tree in trees.values) tree.footprint,
    for (final building in buildings.values) building.footprint,
  ];

  bool isBlocked(PositionEntity position, double radius) =>
      obstacles().any((obstacle) => obstacle.blocks(position, radius));

  PositionEntity clamp(PositionEntity position, double margin) {
    double clampValue(double value, double limit) => min(max(value, margin), limit - margin);
    return PositionEntity(x: clampValue(position.x, width), y: clampValue(position.y, height));
  }

  bool isInside(PositionEntity position, double margin) => clamp(position, margin) == position;

  String nextId(String prefix) {
    final next = (_idCounters[prefix] ?? 0) + 1;
    _idCounters[prefix] = next;
    return '$prefix-$next';
  }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/layers/domain/world/world_state_test.dart`
Expected: `All tests passed!` (5 tests).

- [ ] **Step 5: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain/world test/layers/domain/world
git commit -m "[PROJECT-X]: Add the world state shared by the systems"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 7: El agregado `World` y sus sistemas

**Files:**
- Create: `lib/layers/domain/world/work.dart`, `woodcutting.dart`, `construction.dart`, `navigation.dart`, `pick_up_items.dart`, `world.dart`
- Create: `test/mocks/domain/world/world_mock.dart`
- Test: `test/layers/domain/world/world_movement_test.dart`, `world_items_test.dart`, `world_chopping_test.dart`, `world_construction_test.dart`

**Interfaces:**
- Consumes: todo lo anterior (`WorldState`, extensiones, entidades, `Rules`, `Blueprints`, mocks).
- Produces: `World` exactamente con la API de README §3.3 (incluido `@visibleForTesting void updatePlayer(PlayerEntity Function(PlayerEntity player) transform)`); `abstract interface class Work<I extends IntentEntity>`; `final class BoundWork<I extends IntentEntity>`; `BoundWork<IntentEntity> workFor(IntentEntity intent)` (switch exhaustivo: añadir una mecánica = variante de `IntentEntity` + `Work` + una rama, y el compilador avisa); `Woodcutting` (con `static ChopResult check(WorldState, String)`), `Construction` (con `static bool canPlace(...)` y `static ConstructionResultEntity place(...)`), `Navigation`, `void pickUpItems(WorldState state, List<GameEventEntity> events)`; mocks `WorldMock.make({PlayerEntity player, List<TreeEntity> trees, List<GroundItemEntity> items})` y la extensión de test `WorldAdvanceFor.advanceFor(double totalMs)` (pasos de 16 ms).

- [ ] **Step 1: Escribir el mock del mundo**

`test/mocks/domain/world/world_mock.dart`:

```dart
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

- [ ] **Step 2: Escribir los tests de movimiento y objetos que fallan**

`test/layers/domain/world/world_movement_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenPathIsClearThenPlayerMoves', () {
    // given
    final world = WorldMock.make();
    world.movePlayerTo(const PositionEntity(x: 200, y: 100));

    // when
    world.advance(500);

    // then
    expect(world.player.position, const PositionEntity(x: 150, y: 100));
  });

  test('testWhenNextStepHitsATrunkThenPlayerStops', () {
    // given
    final world = WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 130, y: 100))]);
    world.movePlayerTo(const PositionEntity(x: 200, y: 100));

    // when
    world.advance(150);

    // then
    expect(world.player.position, const PositionEntity(x: 100, y: 100));
    expect(world.player.isMoving, isFalse);
  });

  test('testWhenDestinationIsOutsideTheWorldThenItIsClampedToTheEdge', () {
    // given
    final world = World(
      width: 200,
      height: 100,
      player: PlayerEntityMock.mock.copyWith(position: const PositionEntity(x: 50, y: 50)),
      trees: const [],
    );
    world.movePlayerTo(const PositionEntity(x: -50, y: 500));

    // when
    world.advanceFor(2000);

    // then
    expect(world.player.position, const PositionEntity(x: 8, y: 92));
  });
}
```

`test/layers/domain/world/world_items_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/entities/item/ground_item_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenPlayerWalksOverAToolThenPicksItUp', () {
    // given
    final world = WorldMock.make(items: [GroundItemEntityMock.mock]);
    world.movePlayerTo(const PositionEntity(x: 160, y: 100));

    // when
    final events = world.advanceFor(1000);

    // then
    expect(events, contains(const ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe)));
    expect(world.player.inventory.hasTool(ToolKind.axe), isTrue);
    expect(world.items, isEmpty);
  });
}
```

- [ ] **Step 3: Escribir los tests de talar que fallan**

`test/layers/domain/world/world_chopping_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/chop_result.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/entities/player/intent_entity.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

World _worldWithAxeAndTree() {
  final player = PlayerEntityMock.mock.copyWith(inventory: PlayerEntityMock.mock.inventory.addTool(ToolKind.axe));
  return WorldMock.make(player: player, trees: [TreeEntityMock.mock]);
}

void main() {
  test('testWhenChoppingWithoutAxeThenReturnsNoAxeAndStaysPut', () {
    // given
    final world = WorldMock.make(trees: [TreeEntityMock.mock]);

    // when
    final result = world.orderChop('tree-1');

    // then
    expect(result, ChopResult.noAxe);
    expect(world.player.isMoving, isFalse);
  });

  test('testWhenChoppingUnknownTreeThenReturnsUnknownTree', () {
    // given
    final world = _worldWithAxeAndTree();

    // when
    final result = world.orderChop('nope');

    // then
    expect(result, ChopResult.unknownTree);
  });

  test('testWhenChoppingThenWalksToTheNearSideAndStartsWorking', () {
    // given
    final world = _worldWithAxeAndTree();

    // when
    final result = world.orderChop('tree-1');
    world.advanceFor(1500);

    // then
    expect(result, ChopResult.ok);
    expect((world.player.activity as WorkingActivityEntity).intent, const ChopIntentEntity(treeId: 'tree-1'));
    expect(world.player.position, const PositionEntity(x: 180, y: 101));
  });

  test('testWhenNearSideIsBlockedThenChopsFromTheOtherSide', () {
    // given
    final player = PlayerEntityMock.mock.copyWith(
      position: const PositionEntity(x: 100, y: 300),
      inventory: PlayerEntityMock.mock.inventory.addTool(ToolKind.axe),
    );
    final world = WorldMock.make(
      player: player,
      trees: [
        TreeEntityMock.mock,
        TreeEntityMock.mock.copyWith(id: 'neighbour', position: const PositionEntity(x: 165, y: 100)),
      ],
    );
    world.orderChop('tree-1');

    // when
    world.advanceFor(4000);

    // then
    expect(world.player.activity, isA<WorkingActivityEntity>());
    expect(world.player.position.x, greaterThan(200));
  });

  test('testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded', () {
    // given
    final world = _worldWithAxeAndTree();
    world.orderChop('tree-1');
    world.advanceFor(1500);

    // when
    final events = world.advanceFor(Rules.chopIntervalMs * Rules.hitsToFellTree + 100);

    // then
    expect(events.whereType<TreeHitEventEntity>().length, 5);
    expect(events, contains(const TreeFelledEventEntity(treeId: 'tree-1', wood: 6)));
    expect(world.player.inventory.wood, 6);
    expect(world.trees, isEmpty);
    expect(world.player.activity, const IdleActivityEntity());
  });

  test('testWhenAnotherTreeStandsInTheWayThenReportsPlayerBlocked', () {
    // given
    final player = PlayerEntityMock.mock.copyWith(inventory: PlayerEntityMock.mock.inventory.addTool(ToolKind.axe));
    final world = WorldMock.make(
      player: player,
      trees: [
        TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 300, y: 100)),
        TreeEntityMock.mock.copyWith(id: 'in-the-way', position: const PositionEntity(x: 180, y: 100)),
      ],
    );
    world.orderChop('tree-1');

    // when
    final events = world.advanceFor(3000);

    // then
    expect(events, contains(const PlayerBlockedEventEntity()));
    expect(world.player.activity, const IdleActivityEntity());
  });

  test('testWhenTreeIsFelledThenPathIsFree', () {
    // given
    final world = _worldWithAxeAndTree();
    world.orderChop('tree-1');
    world.advanceFor(1500 + Rules.chopIntervalMs * Rules.hitsToFellTree + 100);

    // when
    world.movePlayerTo(const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000);

    // then
    expect(world.player.position, const PositionEntity(x: 300, y: 100));
  });
}
```

- [ ] **Step 4: Escribir los tests de construir que fallan**

`test/layers/domain/world/world_construction_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/construction_rejection.dart';
import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/entities/player/intent_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

const _house = Blueprints.house;

World _worldWithWood(int wood) =>
    WorldMock.make(player: PlayerEntityMock.mock.copyWith(inventory: PlayerEntityMock.mock.inventory.addWood(wood)));

void main() {
  test('testWhenConstructingWithoutEnoughWoodThenIsRejected', () {
    // given
    final world = WorldMock.make();

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 400, y: 400));

    // then
    expect(result, const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood));
    expect(world.buildings, isEmpty);
  });

  test('testWhenSiteOverlapsTreePlayerOrEdgeThenIsBlockedWithoutCharging', () {
    // given
    final world = WorldMock.make(
      player: PlayerEntityMock.mock.copyWith(inventory: PlayerEntityMock.mock.inventory.addWood(15)),
      trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))],
    );
    const blocked = ConstructionRejectedEntity(reason: ConstructionRejection.blocked);

    // when
    final overTree = world.orderConstruction(_house, const PositionEntity(x: 420, y: 400));
    final overPlayer = world.orderConstruction(_house, const PositionEntity(x: 110, y: 100));
    final overEdge = world.orderConstruction(_house, const PositionEntity(x: 10, y: 500));

    // then
    expect(overTree, blocked);
    expect(overPlayer, blocked);
    expect(overEdge, blocked);
    expect(world.player.inventory.wood, 15);
  });

  test('testWhenConstructingThenChargesWoodPlacesSiteAndWalksThere', () {
    // given
    final world = _worldWithWood(17);

    // when
    final result = world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // then
    expect(result, isA<ConstructionStartedEntity>());
    expect(world.player.inventory.wood, 2);
    expect(world.buildings.length, 1);
    expect(world.player.isMoving, isTrue);
  });

  test('testWhenReachingTheSiteThenBuildsFromTheFront', () {
    // given
    final world = _worldWithWood(17);
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // when
    world.advanceFor(3000);

    // then
    expect(
      (world.player.activity as WorkingActivityEntity).intent,
      const ConstructIntentEntity(buildingId: 'building-1'),
    );
    expect(world.player.position, const PositionEntity(x: 300, y: 150));
  });

  test('testWhenHammeringLongEnoughThenBuildingIsCompleted', () {
    // given
    final world = _worldWithWood(17);
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));

    // when
    final events = world.advanceFor(3000 + Rules.hammerIntervalMs * _house.hitsToBuild);

    // then
    expect(events.whereType<BuildingHammeredEventEntity>().length, 8);
    expect(events, contains(const BuildingCompletedEventEntity(buildingId: 'building-1', blueprint: BlueprintId.house)));
    expect(world.buildings.single.isComplete, isTrue);
    expect(world.player.activity, const IdleActivityEntity());
  });

  test('testWhenBuildingIsCompleteThenItBlocksMovement', () {
    // given
    final world = _worldWithWood(17);
    world.orderConstruction(_house, const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000 + Rules.hammerIntervalMs * _house.hitsToBuild);
    for (final waypoint in const [PositionEntity(x: 200, y: 200), PositionEntity(x: 200, y: 100)]) {
      world.movePlayerTo(waypoint);
      world.advanceFor(3000);
    }

    // when
    world.movePlayerTo(const PositionEntity(x: 500, y: 100));
    world.advanceFor(5000);

    // then
    expect(world.player.position.x, lessThan(260));
  });
}
```

- [ ] **Step 5: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/world`
Expected: FAIL por compilación (`No such file or directory` para `lib/layers/domain/world/world.dart`); `world_state_test.dart` no llega a ejecutarse en el mismo lote o pasa por separado.

- [ ] **Step 6: Crear el contrato `Work`**

`lib/layers/domain/world/work.dart`:

```dart
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import 'construction.dart';
import 'woodcutting.dart';
import 'world_state.dart';

abstract interface class Work<I extends IntentEntity> {
  double get intervalMs;

  ObstacleEntity? target(WorldState state, I intent);

  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side);

  bool impact(WorldState state, I intent, List<GameEventEntity> events);
}

final class BoundWork<I extends IntentEntity> {
  const BoundWork(this._work, this._intent);

  final Work<I> _work;
  final I _intent;

  double get intervalMs => _work.intervalMs;

  ObstacleEntity? target(WorldState state) => _work.target(state, _intent);

  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) =>
      _work.preferredSpots(target, distance, side);

  bool impact(WorldState state, List<GameEventEntity> events) => _work.impact(state, _intent, events);
}

BoundWork<IntentEntity> workFor(IntentEntity intent) => switch (intent) {
  ChopIntentEntity() => BoundWork<ChopIntentEntity>(const Woodcutting(), intent),
  ConstructIntentEntity() => BoundWork<ConstructIntentEntity>(const Construction(), intent),
};
```

- [ ] **Step 7: Crear `Woodcutting`**

`lib/layers/domain/world/woodcutting.dart`:

```dart
import '../../../core/config/constants/enum/chop_result.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/tree_rules.dart';
import 'work.dart';
import 'world_state.dart';

final class Woodcutting implements Work<ChopIntentEntity> {
  const Woodcutting();

  static ChopResult check(WorldState state, String treeId) {
    if (!state.trees.containsKey(treeId)) return ChopResult.unknownTree;
    if (!state.player.inventory.hasTool(ToolKind.axe)) return ChopResult.noAxe;
    return ChopResult.ok;
  }

  @override
  double get intervalMs => Rules.chopIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, ChopIntentEntity intent) => state.trees[intent.treeId]?.footprint;

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) {
    final position = target.position;
    return [
      PositionEntity(x: position.x + side * distance, y: position.y + 1),
      PositionEntity(x: position.x - side * distance, y: position.y + 1),
    ];
  }

  @override
  bool impact(WorldState state, ChopIntentEntity intent, List<GameEventEntity> events) {
    final tree = state.trees[intent.treeId]?.hit();
    if (tree == null) return true;
    events.add(TreeHitEventEntity(treeId: tree.id, hitsRemaining: tree.hitsRemaining));
    if (!tree.isFelled) {
      state.trees[tree.id] = tree;
      return false;
    }
    state.trees.remove(tree.id);
    state.player = state.player.withInventory(state.player.inventory.addWood(tree.woodYield));
    events.add(TreeFelledEventEntity(treeId: tree.id, wood: tree.woodYield));
    return true;
  }
}
```

- [ ] **Step 8: Crear `Construction`**

`lib/layers/domain/world/construction.dart`:

```dart
import '../../../core/config/constants/enum/construction_rejection.dart';
import '../entities/building/blueprint_entity.dart';
import '../entities/building/building_entity.dart';
import '../entities/game/construction_result_entity.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/building_rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/position_geometry.dart';
import 'work.dart';
import 'world_state.dart';

final class Construction implements Work<ConstructIntentEntity> {
  const Construction();

  static bool canPlace(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
    final radius = blueprint.footprintRadius;
    final player = state.player;
    final overlapsPlayer = position.distanceTo(player.position) < radius + player.radius;
    final overlapsItem = state.items.values.any((item) => position.distanceTo(item.position) < radius);
    return state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem;
  }

  static ConstructionResultEntity place(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
    final paid = state.player.inventory.spendWood(blueprint.woodCost);
    if (paid == null) return const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood);
    if (!canPlace(state, blueprint, position)) {
      return const ConstructionRejectedEntity(reason: ConstructionRejection.blocked);
    }
    state.player = state.player.withInventory(paid);
    final building = BuildingEntity(id: state.nextId('building'), blueprint: blueprint, position: position);
    state.buildings[building.id] = building;
    return ConstructionStartedEntity(building: building);
  }

  @override
  double get intervalMs => Rules.hammerIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, ConstructIntentEntity intent) {
    final building = state.buildings[intent.buildingId];
    if (building == null || building.isComplete) return null;
    return building.footprint;
  }

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) => [
    PositionEntity(x: target.position.x, y: target.position.y + distance),
  ];

  @override
  bool impact(WorldState state, ConstructIntentEntity intent, List<GameEventEntity> events) {
    final building = state.buildings[intent.buildingId]?.hammer();
    if (building == null) return true;
    state.buildings[building.id] = building;
    events.add(BuildingHammeredEventEntity(buildingId: building.id, progress: building.progress));
    if (!building.isComplete) return false;
    events.add(BuildingCompletedEventEntity(buildingId: building.id, blueprint: building.blueprint.id));
    return true;
  }
}
```

- [ ] **Step 9: Crear `Navigation` y `pickUpItems`**

`lib/layers/domain/world/navigation.dart`:

```dart
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/activity_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/position_geometry.dart';
import 'work.dart';
import 'world_state.dart';

const double _reachTolerance = 6;

class Navigation {
  Navigation(this._state);

  final WorldState _state;

  void walkTo(PositionEntity destination) {
    _state.player = _state.player.walkTo(_state.clamp(destination, _state.player.radius));
  }

  void goWorkOn(IntentEntity intent) {
    if (_isWithinReach(intent)) {
      _startWork(intent);
      return;
    }
    _state.player = _state.player.walkTo(_workSpot(intent), intent: intent);
  }

  void step(double deltaMs, WalkingActivityEntity activity, List<GameEventEntity> events) {
    final player = _state.player;
    final next = player.nextPosition(deltaMs);
    if (next == null) return;
    final intent = activity.intent;

    if (_state.isBlocked(next, player.radius)) {
      if (intent != null && _isWithinReach(intent)) {
        _startWork(intent);
        return;
      }
      if (intent != null) events.add(const PlayerBlockedEventEntity());
      _state.player = player.stop();
      return;
    }

    _state.player = player.placeAt(next);
    if (next != activity.destination) return;
    if (intent != null) {
      _startWork(intent);
    } else {
      _state.player = _state.player.stop();
    }
  }

  void _startWork(IntentEntity intent) {
    _state.player = workFor(intent).target(_state) != null
        ? _state.player.startWork(intent)
        : _state.player.stop();
  }

  bool _isWithinReach(IntentEntity intent) {
    final target = workFor(intent).target(_state);
    if (target == null) return false;
    final reach = target.radius + _state.player.radius + Rules.workGap + _reachTolerance;
    return _state.player.position.distanceTo(target.position) <= reach;
  }

  PositionEntity _workSpot(IntentEntity intent) {
    final player = _state.player;
    final work = workFor(intent);
    final target = work.target(_state);
    if (target == null) return player.position;
    final distance = target.radius + player.radius + Rules.workGap;
    final side = player.position.x < target.position.x ? -1 : 1;
    bool isFree(PositionEntity spot) => _state.isInside(spot, player.radius) && !_state.isBlocked(spot, player.radius);

    for (final spot in work.preferredSpots(target, distance, side)) {
      if (isFree(spot)) return spot;
    }
    return _state.clamp(target.position.pointAtDistance(distance, player.position), player.radius);
  }
}
```

`lib/layers/domain/world/pick_up_items.dart`:

```dart
import '../entities/game/game_event_entity.dart';
import '../rules/rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/position_geometry.dart';
import 'world_state.dart';

void pickUpItems(WorldState state, List<GameEventEntity> events) {
  for (final item in state.items.values.toList()) {
    if (item.position.distanceTo(state.player.position) > Rules.pickUpRange) continue;
    state.items.remove(item.id);
    state.player = state.player.withInventory(state.player.inventory.addTool(item.kind));
    events.add(ItemPickedUpEventEntity(itemId: item.id, kind: item.kind));
  }
}
```

- [ ] **Step 10: Crear el agregado `World`**

`lib/layers/domain/world/world.dart`:

```dart
import 'package:meta/meta.dart';

import '../../../core/config/constants/enum/chop_result.dart';
import '../entities/building/blueprint_entity.dart';
import '../entities/building/building_entity.dart';
import '../entities/decoration/decoration_entity.dart';
import '../entities/game/construction_result_entity.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/item/ground_item_entity.dart';
import '../entities/player/activity_entity.dart';
import '../entities/player/intent_entity.dart';
import '../entities/player/player_entity.dart';
import '../entities/tree/tree_entity.dart';
import 'construction.dart';
import 'extensions/player_rules.dart';
import 'navigation.dart';
import 'pick_up_items.dart';
import 'woodcutting.dart';
import 'work.dart';
import 'world_state.dart';

class World {
  World({
    required double width,
    required double height,
    required PlayerEntity player,
    required List<TreeEntity> trees,
    List<GroundItemEntity> items = const [],
    List<DecorationEntity> decorations = const [],
  }) : this._(
         WorldState(
           width: width,
           height: height,
           player: player,
           trees: trees,
           items: items,
           decorations: decorations,
         ),
       );

  World._(this._state) : _navigation = Navigation(_state);

  final WorldState _state;
  final Navigation _navigation;

  double get width => _state.width;

  double get height => _state.height;

  PlayerEntity get player => _state.player;

  List<TreeEntity> get trees => _state.trees.values.toList();

  List<GroundItemEntity> get items => _state.items.values.toList();

  List<DecorationEntity> get decorations => _state.decorations;

  List<BuildingEntity> get buildings => _state.buildings.values.toList();

  List<ObstacleEntity> get obstacles => _state.obstacles();

  double get workProgress {
    final activity = player.activity;
    if (activity is! WorkingActivityEntity) return 0;
    return activity.elapsedMs / workFor(activity.intent).intervalMs;
  }

  PositionEntity? get playerTarget => switch (player.activity) {
    WalkingActivityEntity(:final destination) => destination,
    WorkingActivityEntity(:final intent) => workFor(intent).target(_state)?.position,
    IdleActivityEntity() => null,
  };

  void movePlayerTo(PositionEntity destination) => _navigation.walkTo(destination);

  ChopResult orderChop(String treeId) {
    final result = Woodcutting.check(_state, treeId);
    if (result == ChopResult.ok) _navigation.goWorkOn(ChopIntentEntity(treeId: treeId));
    return result;
  }

  ConstructionResultEntity orderConstruction(BlueprintEntity blueprint, PositionEntity position) {
    final result = Construction.place(_state, blueprint, position);
    if (result is ConstructionStartedEntity) _navigation.goWorkOn(ConstructIntentEntity(buildingId: result.building.id));
    return result;
  }

  bool canPlace(BlueprintEntity blueprint, PositionEntity position) => Construction.canPlace(_state, blueprint, position);

  List<GameEventEntity> advance(double deltaMs) {
    final events = <GameEventEntity>[];
    switch (player.activity) {
      case final WalkingActivityEntity walking:
        _navigation.step(deltaMs, walking, events);
      case final WorkingActivityEntity working:
        _work(deltaMs, working, events);
      case IdleActivityEntity():
        break;
    }
    pickUpItems(_state, events);
    return events;
  }

  @visibleForTesting
  void updatePlayer(PlayerEntity Function(PlayerEntity player) transform) {
    _state.player = transform(_state.player);
  }

  void _work(double deltaMs, WorkingActivityEntity activity, List<GameEventEntity> events) {
    final work = workFor(activity.intent);
    if (work.target(_state) == null) {
      _state.player = _state.player.stop();
      return;
    }
    final elapsed = activity.elapsedMs + deltaMs;
    if (elapsed < work.intervalMs) {
      _state.player = _state.player.continueWork(elapsed);
      return;
    }
    _state.player = _state.player.continueWork(elapsed - work.intervalMs);
    if (work.impact(_state, events)) _state.player = _state.player.stop();
  }
}
```

- [ ] **Step 11: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/world`
Expected: `All tests passed!` (22 tests: 5 de `WorldState`, 3 de movimiento, 1 de objetos, 7 de talar, 6 de construir).

- [ ] **Step 12: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain/world test/layers/domain/world test/mocks/domain/world
git commit -m "[PROJECT-X]: Add the world aggregate with navigation, woodcutting and construction"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 8: Misiones

**Files:**
- Create: `lib/layers/domain/quests/quest.dart`, `quests.dart`, `quest_log.dart`
- Test: `test/layers/domain/quests/quest_log_test.dart`

**Interfaces:**
- Consumes: `World` (con `updatePlayer`, `orderConstruction`), `QuestId`, `ToolKind`, `BlueprintId`, `QuestProgressEntity`, `QuestCompletedEventEntity`, `WorldMock`, `WorldAdvanceFor`.
- Produces: `abstract interface class Quest { QuestId get id; int get target; int progress(World world); }`; `abstract final class Quests { static final List<Quest> all; }` (orden: `pickUpAxe` 1, `gatherWood` 15, `buildHouse` 1); `QuestLog({List<Quest>? quests})` con `List<QuestCompletedEventEntity> update(World world)` (completado permanente, cualquier orden) y `List<QuestProgressEntity> status(World world)` (progreso limitado al objetivo; `isCurrent` = primera no completada).

- [ ] **Step 1: Escribir el test que falla**

`test/layers/domain/quests/quest_log_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/extensions/player_rules.dart';

import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenGameStartsThenEveryQuestIsPendingAndTheFirstIsCurrent', () {
    // given
    final world = WorldMock.make();

    // when
    final status = QuestLog().status(world);

    // then
    expect(status, const [
      QuestProgressEntity(id: QuestId.pickUpAxe, progress: 0, target: 1, isCompleted: false, isCurrent: true),
      QuestProgressEntity(id: QuestId.gatherWood, progress: 0, target: 15, isCompleted: false, isCurrent: false),
      QuestProgressEntity(id: QuestId.buildHouse, progress: 0, target: 1, isCompleted: false, isCurrent: false),
    ]);
  });

  test('testWhenQuestIsFulfilledThenItIsReportedOnlyOnce', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog();
    world.updatePlayer((player) => player.withInventory(player.inventory.addTool(ToolKind.axe)));

    // when
    final first = questLog.update(world);
    final second = questLog.update(world);

    // then
    expect(first, const [QuestCompletedEventEntity(questId: QuestId.pickUpAxe)]);
    expect(second, isEmpty);
  });

  test('testWhenWoodIsSpentAfterCompletingThenWoodQuestStaysCompleted', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog();
    world.updatePlayer((player) => player.withInventory(player.inventory.addWood(16)));
    questLog.update(world);

    // when
    world.updatePlayer((player) => player.withInventory(player.inventory.spendWood(16)!));

    // then
    final woodQuest = questLog.status(world).firstWhere((quest) => quest.id == QuestId.gatherWood);
    expect(
      woodQuest,
      const QuestProgressEntity(id: QuestId.gatherWood, progress: 15, target: 15, isCompleted: true, isCurrent: false),
    );
  });

  test('testWhenProgressExceedsTargetThenItIsCapped', () {
    // given
    final world = WorldMock.make();
    world.updatePlayer((player) => player.withInventory(player.inventory.addWood(40)));

    // when
    final woodQuest = QuestLog().status(world).firstWhere((quest) => quest.id == QuestId.gatherWood);

    // then
    expect(woodQuest.progress, 15);
  });

  test('testWhenHouseIsOnlyPlacedThenBuildQuestIsNotCompleted', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog();
    world.updatePlayer((player) => player.withInventory(player.inventory.addWood(15)));
    questLog.update(world);
    world.orderConstruction(Blueprints.house, const PositionEntity(x: 300, y: 100));

    // when
    final whilePlaced = questLog.update(world);
    world.advanceFor(10000);
    final whenFinished = questLog.update(world);

    // then
    expect(whilePlaced, isEmpty);
    expect(whenFinished, const [QuestCompletedEventEntity(questId: QuestId.buildHouse)]);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/layers/domain/quests`
Expected: FAIL por compilación (`No such file or directory` para `quest_log.dart`).

- [ ] **Step 3: Implementar las misiones**

`lib/layers/domain/quests/quest.dart`:

```dart
import '../../../core/config/constants/enum/quest_id.dart';
import '../world/world.dart';

abstract interface class Quest {
  QuestId get id;

  int get target;

  int progress(World world);
}
```

`lib/layers/domain/quests/quests.dart`:

```dart
import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/quest_id.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../world/extensions/inventory_rules.dart';
import '../world/world.dart';
import 'quest.dart';

abstract final class Quests {
  static final List<Quest> all = [
    _MeasuredQuest(
      id: QuestId.pickUpAxe,
      target: 1,
      measure: (world) => world.player.inventory.hasTool(ToolKind.axe) ? 1 : 0,
    ),
    _MeasuredQuest(id: QuestId.gatherWood, target: 15, measure: (world) => world.player.inventory.wood),
    _MeasuredQuest(
      id: QuestId.buildHouse,
      target: 1,
      measure: (world) => world.buildings
          .where((building) => building.isComplete && building.blueprint.id == BlueprintId.house)
          .length,
    ),
  ];
}

final class _MeasuredQuest implements Quest {
  const _MeasuredQuest({required this.id, required this.target, required int Function(World world) measure})
    : _measure = measure;

  @override
  final QuestId id;

  @override
  final int target;

  final int Function(World world) _measure;

  @override
  int progress(World world) => _measure(world);
}
```

`lib/layers/domain/quests/quest_log.dart`:

```dart
import 'dart:math';

import '../../../core/config/constants/enum/quest_id.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/game/quest_progress_entity.dart';
import '../world/world.dart';
import 'quest.dart';
import 'quests.dart';

class QuestLog {
  QuestLog({List<Quest>? quests}) : _quests = quests ?? Quests.all;

  final List<Quest> _quests;
  final Set<QuestId> _completed = {};

  List<QuestCompletedEventEntity> update(World world) {
    final fulfilled = _quests
        .where((quest) => !_completed.contains(quest.id) && quest.progress(world) >= quest.target)
        .toList();
    _completed.addAll(fulfilled.map((quest) => quest.id));
    return [for (final quest in fulfilled) QuestCompletedEventEntity(questId: quest.id)];
  }

  List<QuestProgressEntity> status(World world) {
    QuestId? currentId;
    for (final quest in _quests) {
      if (!_completed.contains(quest.id)) {
        currentId = quest.id;
        break;
      }
    }
    return [
      for (final quest in _quests)
        QuestProgressEntity(
          id: quest.id,
          progress: _completed.contains(quest.id) ? quest.target : min(quest.progress(world), quest.target),
          target: quest.target,
          isCompleted: _completed.contains(quest.id),
          isCurrent: quest.id == currentId,
        ),
    ];
  }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/layers/domain/quests`
Expected: `All tests passed!` (5 tests).

- [ ] **Step 5: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain/quests test/layers/domain/quests
git commit -m "[PROJECT-X]: Add quests and the quest log"
```

Expected de `flutter analyze`: `No issues found!`.

---

### Task 9: Sesión, interfaces de repositorio y reglas de arquitectura del dominio

**Files:**
- Create: `lib/layers/domain/entities/game/game_session_entity.dart`
- Create: `lib/layers/domain/repositories/level/level_repository.dart`, `lib/layers/domain/repositories/session/game_session_repository.dart`
- Test: `test/layers/domain/entities/game/game_session_entity_test.dart`, `test/layers/domain/domain_architecture_test.dart`

**Interfaces:**
- Consumes: `World`, `QuestLog`, `WorldMock`.
- Produces: `GameSessionEntity({required World world, required QuestLog quests})`; `abstract interface class LevelRepository { World load(); }`; `abstract interface class GameSessionRepository { GameSessionEntity current(); void save(GameSessionEntity session); }` (consumidos por las fases 3 y 4). El test de arquitectura de dominio complementa `test/architecture_test.dart` de la fase 1 (no lo modifica).

- [ ] **Step 1: Escribir los tests**

`test/layers/domain/entities/game/game_session_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';

import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenSessionsShareWorldAndQuestLogThenTheyAreEqual', () {
    // given
    final world = WorldMock.make();
    final quests = QuestLog();
    final session = GameSessionEntity(world: world, quests: quests);

    // when
    final sameSession = session == GameSessionEntity(world: world, quests: quests);
    final otherQuests = session == GameSessionEntity(world: world, quests: QuestLog());

    // then
    expect(sameSession, isTrue);
    expect(otherQuests, isFalse);
  });
}
```

`test/layers/domain/domain_architecture_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dartFiles(String path) => Directory(
  path,
).listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart')).toList();

void main() {
  test('testWhenScanningTheDomainThenItImportsNoOuterLayerNorPlatformApi', () {
    // given
    final files = _dartFiles('lib/layers/domain');
    final forbidden = RegExp(
      r'''import\s+['"](package:flutter|package:flame|dart:ui|dart:io|[^'"]*/data/|[^'"]*/presentation/|[^'"]*config/di/)''',
    );

    // when
    final offenders = files.where((file) => forbidden.hasMatch(file.readAsStringSync())).map((file) => file.path);

    // then
    expect(offenders, isEmpty);
  });

  test('testWhenScanningEntitiesThenEveryFieldIsFinal', () {
    // given
    final files = _dartFiles('lib/layers/domain/entities');
    final mutableField = RegExp(r'^  (?![ })\]])(?!final |static |const )[^(=]*;$', multiLine: true);

    // when
    final offenders = files.where((file) => mutableField.hasMatch(file.readAsStringSync())).map((file) => file.path);

    // then
    expect(offenders, isEmpty);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/layers/domain/entities/game/game_session_entity_test.dart test/layers/domain/domain_architecture_test.dart`
Expected: FAIL por compilación en `game_session_entity_test.dart` (`No such file or directory` para `game_session_entity.dart`); los dos tests de arquitectura pasan (protegen las reglas de aquí en adelante).

- [ ] **Step 3: Crear la entidad de sesión y los contratos**

`lib/layers/domain/entities/game/game_session_entity.dart`:

```dart
import '../../quests/quest_log.dart';
import '../../world/world.dart';

class GameSessionEntity {
  final World world;
  final QuestLog quests;

  const GameSessionEntity({required this.world, required this.quests});

  @override
  bool operator ==(Object other) =>
      other is GameSessionEntity && identical(other.world, world) && identical(other.quests, quests);

  @override
  int get hashCode => Object.hash(identityHashCode(world), identityHashCode(quests));
}
```

`lib/layers/domain/repositories/level/level_repository.dart`:

```dart
import '../../world/world.dart';

abstract interface class LevelRepository {
  World load();
}
```

`lib/layers/domain/repositories/session/game_session_repository.dart`:

```dart
import '../../entities/game/game_session_entity.dart';

abstract interface class GameSessionRepository {
  GameSessionEntity current();

  void save(GameSessionEntity session);
}
```

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/layers/domain/entities/game/game_session_entity_test.dart test/layers/domain/domain_architecture_test.dart`
Expected: `All tests passed!` (3 tests).

- [ ] **Step 5: Comprobar que el test de campos detecta un `var`**

Añadir temporalmente la línea `  int counter = 0;` dentro de la clase `BuildOptionEntity` (justo después de `final bool isAffordable;`) en `lib/layers/domain/entities/game/build_option_entity.dart`.

Run: `flutter test test/layers/domain/domain_architecture_test.dart`
Expected: FAIL en `testWhenScanningEntitiesThenEveryFieldIsFinal` con `Expected: empty  Actual: (... 'lib/layers/domain/entities/game/build_option_entity.dart')`.

Quitar la línea y volver a ejecutar: `All tests passed!`.

- [ ] **Step 6: Ejecutar toda la fase**

Run: `flutter test test/layers/domain`
Expected: `All tests passed!` (80 tests aprox.: 10 + 7 + 4 + 9 + 7 + 22 + 5 + 3 + los de la fase 1 que estén bajo esa carpeta, si los hay).

Run: `flutter test`
Expected: `All tests passed!` (incluye `test/architecture_test.dart` de la fase 1).

- [ ] **Step 7: Formatear, analizar y hacer commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/domain test/layers/domain
git commit -m "[PROJECT-X]: Add the game session and the domain repository contracts"
```

Expected de `flutter analyze`: `No issues found!`.

---

## Cierre de la fase

- [ ] `flutter test test/layers/domain` → `All tests passed!`.
- [ ] `flutter analyze` → `No issues found!`.
- [ ] `git status` limpio; 9 commits `[PROJECT-X]: ...` en `feature/PROJECT-X-flutter-migration`.
- [ ] Si algo del plan no pudo seguirse al pie de la letra (p. ej. el analizador pide otro formato o un lint obliga a cambiar una firma), anotarlo en [`README.md`](README.md) §7 con el motivo y el commit, y avisar en el informe de la tarea para que las fases 3–5 lo tengan en cuenta.
