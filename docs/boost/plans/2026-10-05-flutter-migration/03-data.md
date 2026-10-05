# Fase 3 — Capa de datos

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar a Dart la capa de datos del núcleo Kotlin: DBOs del nivel, el generador procedimental del bosque (idéntico al actual, comprobado con valores dorados), los mappers DBO → entidad, el datasource de sesión en memoria y los dos repositorios con `AppExceptionHandler`.

**Architecture:** `lib/layers/data/` según `references/data/*.md` del plugin: `datasources/<feature>/{source,local,local/dbo}/`, `repositories/<feature>/{mappers}/`. El datasource de nivel devuelve un `LevelDBO` (todos los campos nullable); los mappers `@Injectable()` lo convierten en el agregado `World` aplicando las reglas del dominio (`Rules`) y lanzando las `AppException` de nivel; los repositorios envuelven todo en `try/catch` y relanzan a través de `AppExceptionHandler`. La sesión vive en memoria en un datasource `@LazySingleton` (excepción E5 del README).

**Tech Stack:** Dart 3.13, injectable, collection (`ListEquality`), mockito + build_runner (tests), flutter_test.

## Global Constraints

- Todas las de [`README.md`](README.md) → *Global Constraints*; los nombres y firmas de §3 son contrato.
- Esta fase solo toca `lib/layers/data/`, `lib/core/utils/kebab_case.dart`, `test/layers/data/`, `test/core/utils/kebab_case_test.dart` y `test/mocks/`. No modifica dominio ni presentación.
- Prerrequisitos (fases 1 y 2, ya en el repo): `lib/core/utils/seeded_random.dart` (`SeededRandom(int seed)`, `double next()`), `lib/core/error-handling/exceptions/app_exceptions.dart` (`GenericException`, `InvalidLevelException`, `UnknownTreeKindException`, `UnknownDecorationKindException`, `UnknownItemKindException`, `NoGameInProgressException`, todas con `data` `String` donde README §3.4 lo indica), `lib/core/error-handling/handlers/app_exception_handler.dart`, `lib/core/config/di/*`, los enums de §3.1, las entidades de §3.2, `World`, `QuestLog`, `Rules` y las interfaces `LevelRepository` / `GameSessionRepository` de §3.3, y en tests `test/mocks/domain/world/world_mock.dart` con `abstract final class WorldMock { static World make({...}) }` (equivalente a `World.mock()` de Kotlin: mundo 1000×1000, `PlayerEntityMock.mock`, sin árboles ni objetos).
- Los DBOs **no** tienen `fromJson`/`toJson` (el nivel se genera en memoria, no se lee de JSON); sí `const` constructor, `==`, `hashCode` y `toString` escritos a mano (los tests dorados comparan DBOs).
- Valores dorados: los números de los tests se copian **literalmente** de `shared/src/commonTest/.../LevelLocalDataSourceImplTests.kt`. Si un test dorado falla, no se cambian los números: se busca la diferencia en el port (orden de llamadas a `next()`, `floor`, distancias).
- `dart:math` no tiene `hypot`: la distancia se calcula con `sqrt(dx * dx + dy * dy)`. Solo afecta a comparaciones con umbrales (≥120, ≥200, <32); el test dorado confirma que el bosque no cambia.
- Sin comentarios en `lib/`. Imports relativos en `lib/` (`prefer_relative_imports`); en `test/` se usa `package:rpg/...`.
- Después de cada tarea: `dart format --line-length 120 lib test` sin cambios pendientes y `flutter analyze` → `No issues found!`.

---

## Mapa de ficheros

| Fichero | Responsabilidad |
|---|---|
| `lib/core/utils/kebab_case.dart` | `extension KebabCase on String { String toKebabCase() }` (`tallGrass` → `tall-grass`). Lo reutiliza `SpriteNames` en la fase 6. |
| `lib/layers/data/datasources/level/local/dbo/point_dbo.dart` | `PointDBO` |
| `lib/layers/data/datasources/level/local/dbo/tree_dbo.dart` | `TreeDBO` |
| `lib/layers/data/datasources/level/local/dbo/item_dbo.dart` | `ItemDBO` |
| `lib/layers/data/datasources/level/local/dbo/decoration_dbo.dart` | `DecorationDBO` |
| `lib/layers/data/datasources/level/local/dbo/level_dbo.dart` | `LevelDBO` |
| `lib/layers/data/datasources/level/source/level_local_datasource.dart` | interfaz `LevelLocalDatasource` |
| `lib/layers/data/datasources/level/local/level_local_datasource_impl.dart` | generador con semillas fijas (port de `LevelLocalDataSourceImpl.kt`) |
| `lib/layers/data/datasources/session/source/game_session_local_datasource.dart` | interfaz `GameSessionLocalDatasource` |
| `lib/layers/data/datasources/session/local/game_session_local_datasource_impl.dart` | sesión en memoria (`@LazySingleton`) |
| `lib/layers/data/repositories/level/mappers/position_mapper_dbo.dart` | `PointDBO` → `PositionEntity` |
| `lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart` | `TreeDBO` → `TreeEntity` |
| `lib/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart` | `DecorationDBO` → `DecorationEntity` |
| `lib/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart` | `ItemDBO` → `GroundItemEntity` |
| `lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart` | `LevelDBO` → `World` |
| `lib/layers/data/repositories/level/level_repository_impl.dart` | `LevelRepositoryImpl` |
| `lib/layers/data/repositories/session/game_session_repository_impl.dart` | `GameSessionRepositoryImpl` |
| `test/mocks/data/datasources/level/level_dbo_mock.dart` | `LevelDBOMock` (port de `LevelDtoMock.kt`) |
| `test/mocks/domain/entities/game/game_session_entity_mock.dart` | `GameSessionEntityMock.make()` (la reutiliza la fase 4) |
| `test/core/utils/kebab_case_test.dart`, `test/layers/data/**_test.dart` | tests espejo de `lib/` |

Mapa de tests Kotlin → Dart:

| Kotlin (`shared/src/commonTest/.../data/`) | Dart |
|---|---|
| `datasources/local/level/LevelLocalDataSourceImplTests.kt` (4 tests) | `test/layers/data/datasources/level/local/level_local_datasource_impl_test.dart` |
| `datasources/local/level/LevelDtoMock.kt` | `test/mocks/data/datasources/level/level_dbo_mock.dart` |
| `datasources/local/level/LevelLocalDataSourceMock.kt`, `session/GameSessionLocalDataSourceMock.kt` | mocks generados por mockito (`*_test.mocks.dart`) |
| `repositories/level/LevelRepositoryImplTests.kt` (6 tests) | aserciones de mapeo/errores → `test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`; orquestación/errores → `test/layers/data/repositories/level/level_repository_impl_test.dart` (los 6 casos están cubiertos en el repositorio) |
| `repositories/session/GameSessionRepositoryImplTests.kt` (3 tests) | `test/layers/data/repositories/session/game_session_repository_impl_test.dart` |

---

### Task 1: Utilidad `toKebabCase`

**Files:**
- Create: `lib/core/utils/kebab_case.dart`
- Test: `test/core/utils/kebab_case_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: `extension KebabCase on String { String toKebabCase(); }` — usada por los mappers (tarea 3) y por `SpriteNames` (fase 6).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/utils/kebab_case.dart';

void main() {
  test('testWhenNameHasSeveralWordsThenJoinsThemWithHyphens', () {
    // given
    const name = 'tallGrass';

    // when
    final kebab = name.toKebabCase();

    // then
    expect(kebab, 'tall-grass');
  });

  test('testWhenNameHasOneWordThenKeepsItLowerCase', () {
    // given
    const name = 'oak';

    // when
    final kebab = name.toKebabCase();

    // then
    expect(kebab, 'oak');
  });

  test('testWhenNameStartsWithAnUpperCaseLetterThenDoesNotAddALeadingHyphen', () {
    // given
    const name = 'TallGrass';

    // when
    final kebab = name.toKebabCase();

    // then
    expect(kebab, 'tall-grass');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/kebab_case_test.dart`
Expected: FAIL — compilation error, `Error when reading 'lib/core/utils/kebab_case.dart': No such file or directory`.

- [ ] **Step 3: Write minimal implementation**

```dart
extension KebabCase on String {
  String toKebabCase() {
    return replaceAllMapped(RegExp(r'(?<!^)[A-Z]'), (match) => '-${match[0]}').toLowerCase();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/kebab_case_test.dart`
Expected: `All tests passed!` (3 tests).

- [ ] **Step 5: Format, analyze and commit**

```bash
dart format --line-length 120 lib/core/utils/kebab_case.dart test/core/utils/kebab_case_test.dart
flutter analyze
git add lib/core/utils/kebab_case.dart test/core/utils/kebab_case_test.dart
git commit -m "[PROJECT-X]: Add kebab-case helper for level and sprite names"
```

Expected: `flutter analyze` → `No issues found!`.

---

### Task 2: DBOs del nivel y generador del bosque

**Files:**
- Create: `lib/layers/data/datasources/level/local/dbo/point_dbo.dart`
- Create: `lib/layers/data/datasources/level/local/dbo/tree_dbo.dart`
- Create: `lib/layers/data/datasources/level/local/dbo/item_dbo.dart`
- Create: `lib/layers/data/datasources/level/local/dbo/decoration_dbo.dart`
- Create: `lib/layers/data/datasources/level/local/dbo/level_dbo.dart`
- Create: `lib/layers/data/datasources/level/source/level_local_datasource.dart`
- Create: `lib/layers/data/datasources/level/local/level_local_datasource_impl.dart`
- Test: `test/layers/data/datasources/level/local/level_local_datasource_impl_test.dart`

**Interfaces:**
- Consumes: `SeededRandom(int seed)` / `double next()` (`lib/core/utils/seeded_random.dart`, fase 1).
- Produces:
  - `class PointDBO { final double? x, y; const PointDBO({this.x, this.y}); }`
  - `class TreeDBO { final String? id, kind; final double? x, y; final int? wood; const TreeDBO({this.id, this.kind, this.x, this.y, this.wood}); }`
  - `class ItemDBO { final String? id, kind; final double? x, y; const ItemDBO({this.id, this.kind, this.x, this.y}); }`
  - `class DecorationDBO { final String? id, kind; final double? x, y; const DecorationDBO({this.id, this.kind, this.x, this.y}); }`
  - `class LevelDBO { final double? width, height; final PointDBO? playerStart; final List<TreeDBO>? trees; final List<ItemDBO>? items; final List<DecorationDBO>? decorations; const LevelDBO({...}); }`
  - `abstract interface class LevelLocalDatasource { LevelDBO fetch(); }`
  - `@Injectable(as: LevelLocalDatasource) class LevelLocalDatasourceImpl` con `const LevelLocalDatasourceImpl()`.

- [ ] **Step 1: Write the failing test**

`test/layers/data/datasources/level/local/level_local_datasource_impl_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/item_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/point_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/level_local_datasource_impl.dart';

void main() {
  late LevelLocalDatasourceImpl sut;

  setUp(() {
    sut = const LevelLocalDatasourceImpl();
  });

  test('testWhenFetchingTwiceThenReturnsTheSameForest', () {
    // given
    final first = sut.fetch();

    // when
    final second = sut.fetch();

    // then
    expect(second, first);
  });

  test('testWhenFetchingThenForestMatchesTheWebVersionExactly', () {
    // given
    const expectedFirstTrees = [
      TreeDBO(id: 'tree-1', kind: 'broad', x: 433.47085868008435, y: 155.17504904419184, wood: 6),
      TreeDBO(id: 'tree-2', kind: 'old', x: 389.38031366094947, y: 465.71301287971437, wood: 5),
      TreeDBO(id: 'tree-3', kind: 'pine', x: 721.9763031136245, y: 187.9368040524423, wood: 6),
    ];

    // when
    final level = sut.fetch();
    final trees = level.trees ?? const <TreeDBO>[];

    // then
    final kindCounts = <String?, int>{};
    for (final tree in trees) {
      kindCounts[tree.kind] = (kindCounts[tree.kind] ?? 0) + 1;
    }
    expect(level.width, 1600.0);
    expect(level.height, 1200.0);
    expect(level.playerStart, const PointDBO(x: 800.0, y: 600.0));
    expect(trees.length, 70);
    expect(trees.take(3).toList(), expectedFirstTrees);
    expect(
      trees.last,
      const TreeDBO(id: 'tree-70', kind: 'dense', x: 1487.0892029069364, y: 676.5116280969232, wood: 6),
    );
    expect(kindCounts, {
      'broad': 3,
      'old': 6,
      'pine': 8,
      'slim': 4,
      'dense': 4,
      'branches': 7,
      'big': 4,
      'lumpy': 4,
      'leaning': 8,
      'oak': 6,
      'round': 5,
      'wide': 6,
      'twisted': 3,
      'dome': 2,
    });
    expect(trees.fold<int>(0, (sum, tree) => sum + (tree.wood ?? 0)), 388);
    expect(level.items, const [ItemDBO(id: 'axe', kind: 'axe', x: 856.0, y: 608.0)]);
  });

  test('testWhenFetchingThenTreesKeepClearOfTheSpawnPoint', () {
    // given
    final level = sut.fetch();

    // when
    final closest = (level.trees ?? const <TreeDBO>[])
        .map((tree) => sqrt(pow((tree.x ?? 0) - 800.0, 2) + pow((tree.y ?? 0) - 600.0, 2)))
        .reduce(min);

    // then
    expect(closest, greaterThanOrEqualTo(200.0));
  });

  test('testWhenFetchingThenDecorationsAreVariedAndNeverUnderATreeOrOnTheSpawn', () {
    // given
    final level = sut.fetch();
    final trees = level.trees ?? const <TreeDBO>[];

    // when
    final decorations = level.decorations ?? const [];

    // then
    expect(decorations.length, greaterThanOrEqualTo(40));
    expect(decorations.map((decoration) => decoration.kind).toSet(), {'tall-grass', 'leaves', 'mushrooms', 'rock'});
    for (final decoration in decorations) {
      final x = decoration.x ?? 0;
      final y = decoration.y ?? 0;
      final underTree = trees.any(
        (tree) => (x - (tree.x ?? 0)).abs() < 64 && y > (tree.y ?? 0) - 170 && y < (tree.y ?? 0) + 20,
      );
      expect(underTree, isFalse);
      expect((x - 800.0).abs() >= 48 || y < 504.0 || y > 648.0, isTrue);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/layers/data/datasources/level/local/level_local_datasource_impl_test.dart`
Expected: FAIL — compilation error, `level_local_datasource_impl.dart`, `tree_dbo.dart`... not found.

- [ ] **Step 3: Write the DBOs**

`lib/layers/data/datasources/level/local/dbo/point_dbo.dart`:

```dart
class PointDBO {
  final double? x;
  final double? y;

  const PointDBO({this.x, this.y});

  @override
  bool operator ==(Object other) => other is PointDBO && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PointDBO(x: $x, y: $y)';
}
```

`lib/layers/data/datasources/level/local/dbo/tree_dbo.dart`:

```dart
class TreeDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;
  final int? wood;

  const TreeDBO({this.id, this.kind, this.x, this.y, this.wood});

  @override
  bool operator ==(Object other) =>
      other is TreeDBO && other.id == id && other.kind == kind && other.x == x && other.y == y && other.wood == wood;

  @override
  int get hashCode => Object.hash(id, kind, x, y, wood);

  @override
  String toString() => 'TreeDBO(id: $id, kind: $kind, x: $x, y: $y, wood: $wood)';
}
```

`lib/layers/data/datasources/level/local/dbo/item_dbo.dart`:

```dart
class ItemDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const ItemDBO({this.id, this.kind, this.x, this.y});

  @override
  bool operator ==(Object other) =>
      other is ItemDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'ItemDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
```

`lib/layers/data/datasources/level/local/dbo/decoration_dbo.dart`:

```dart
class DecorationDBO {
  final String? id;
  final String? kind;
  final double? x;
  final double? y;

  const DecorationDBO({this.id, this.kind, this.x, this.y});

  @override
  bool operator ==(Object other) =>
      other is DecorationDBO && other.id == id && other.kind == kind && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, kind, x, y);

  @override
  String toString() => 'DecorationDBO(id: $id, kind: $kind, x: $x, y: $y)';
}
```

`lib/layers/data/datasources/level/local/dbo/level_dbo.dart`:

```dart
import 'package:collection/collection.dart';

import 'decoration_dbo.dart';
import 'item_dbo.dart';
import 'point_dbo.dart';
import 'tree_dbo.dart';

class LevelDBO {
  final double? width;
  final double? height;
  final PointDBO? playerStart;
  final List<TreeDBO>? trees;
  final List<ItemDBO>? items;
  final List<DecorationDBO>? decorations;

  const LevelDBO({this.width, this.height, this.playerStart, this.trees, this.items, this.decorations});

  @override
  bool operator ==(Object other) =>
      other is LevelDBO &&
      other.width == width &&
      other.height == height &&
      other.playerStart == playerStart &&
      const ListEquality<TreeDBO>().equals(other.trees, trees) &&
      const ListEquality<ItemDBO>().equals(other.items, items) &&
      const ListEquality<DecorationDBO>().equals(other.decorations, decorations);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    playerStart,
    const ListEquality<TreeDBO>().hash(trees),
    const ListEquality<ItemDBO>().hash(items),
    const ListEquality<DecorationDBO>().hash(decorations),
  );

  @override
  String toString() =>
      'LevelDBO(width: $width, height: $height, playerStart: $playerStart, trees: $trees, items: $items, '
      'decorations: $decorations)';
}
```

- [ ] **Step 4: Write the datasource interface and implementation**

`lib/layers/data/datasources/level/source/level_local_datasource.dart`:

```dart
import '../local/dbo/level_dbo.dart';

abstract interface class LevelLocalDatasource {
  LevelDBO fetch();
}
```

`lib/layers/data/datasources/level/local/level_local_datasource_impl.dart` (port 1:1 de `LevelLocalDataSourceImpl.kt`: mismas constantes, mismas semillas, mismo orden de llamadas a `next()`):

```dart
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../../../core/utils/seeded_random.dart';
import '../source/level_local_datasource.dart';
import 'dbo/decoration_dbo.dart';
import 'dbo/item_dbo.dart';
import 'dbo/level_dbo.dart';
import 'dbo/point_dbo.dart';
import 'dbo/tree_dbo.dart';

@Injectable(as: LevelLocalDatasource)
class LevelLocalDatasourceImpl implements LevelLocalDatasource {
  static const double _width = 1600;
  static const double _height = 1200;
  static const int _treeCount = 70;
  static const double _minTreeSpacing = 120;
  static const double _spawnClearance = 200;
  static const double _borderMargin = 60;
  static const int _minWood = 5;
  static const int _maxWood = 6;
  static const int _treeSeed = 42;
  static const int _treeKindSeed = 7;
  static const List<String> _treeKinds = [
    'slim',
    'round',
    'wide',
    'broad',
    'twisted',
    'branches',
    'leaning',
    'lumpy',
    'pine',
    'dome',
    'oak',
    'dense',
    'old',
    'big',
  ];
  static const int _decorationSeed = 1337;
  static const int _decorationAttempts = 107;
  static const int _decorationPlacements = 20;
  static const double _decorationSpacing = 32;
  static const List<String> _decorationKinds = [
    'tall-grass',
    'tall-grass',
    'tall-grass',
    'leaves',
    'leaves',
    'mushrooms',
    'rock',
  ];
  static const double _treeHalfWidth = 64;
  static const double _treeHeight = 170;
  static const double _treeRoots = 20;
  static const double _spawnHalfWidth = 48;
  static const double _spawnAbove = 96;
  static const double _spawnBelow = 48;
  static const double _spawnX = _width / 2;
  static const double _spawnY = _height / 2;
  static const PointDBO _playerStart = PointDBO(x: _spawnX, y: _spawnY);
  static const ItemDBO _axe = ItemDBO(id: 'axe', kind: 'axe', x: _spawnX + 56, y: _spawnY + 8);

  const LevelLocalDatasourceImpl();

  @override
  LevelDBO fetch() {
    final trees = _scatterTrees();
    return LevelDBO(
      width: _width,
      height: _height,
      playerStart: _playerStart,
      trees: trees,
      items: const [_axe],
      decorations: _scatterDecorations(trees),
    );
  }

  List<TreeDBO> _scatterTrees() {
    final random = SeededRandom(_treeSeed);
    final kinds = SeededRandom(_treeKindSeed);
    final trees = <TreeDBO>[];

    var attempt = 0;
    while (attempt < _treeCount * 50 && trees.length < _treeCount) {
      attempt++;
      final x = _borderMargin + random.next() * (_width - _borderMargin * 2);
      final y = _borderMargin + random.next() * (_height - _borderMargin * 2);
      final clearOfSpawn = _distance(x, y, _spawnX, _spawnY) >= _spawnClearance;
      final apart = trees.every((tree) => _distance(x, y, tree.x!, tree.y!) >= _minTreeSpacing);
      if (clearOfSpawn && apart) {
        final wood = _minWood + (random.next() * (_maxWood - _minWood + 1)).floor();
        final kind = _treeKinds[(kinds.next() * _treeKinds.length).floor()];
        trees.add(TreeDBO(id: 'tree-${trees.length + 1}', kind: kind, x: x, y: y, wood: wood));
      }
    }
    return trees;
  }

  List<DecorationDBO> _scatterDecorations(List<TreeDBO> trees) {
    final random = SeededRandom(_decorationSeed);
    final decorations = <DecorationDBO>[];

    bool isFree(double x, double y) {
      final underTree = trees.any(
        (tree) => (x - tree.x!).abs() < _treeHalfWidth && y > tree.y! - _treeHeight && y < tree.y! + _treeRoots,
      );
      final onSpawn = (x - _spawnX).abs() < _spawnHalfWidth && y > _spawnY - _spawnAbove && y < _spawnY + _spawnBelow;
      final onAxe = _distance(x, y, _axe.x!, _axe.y!) < _decorationSpacing;
      final crowded = decorations.any((decoration) => _distance(x, y, decoration.x!, decoration.y!) < _decorationSpacing);
      return !underTree && !onSpawn && !onAxe && !crowded;
    }

    for (var attempt = 0; attempt < _decorationAttempts; attempt++) {
      final kind = _decorationKinds[(random.next() * _decorationKinds.length).floor()];
      for (var placement = 0; placement < _decorationPlacements; placement++) {
        final x = random.next() * _width;
        final y = random.next() * _height;
        if (isFree(x, y)) {
          decorations.add(DecorationDBO(id: 'decoration-${decorations.length + 1}', kind: kind, x: x, y: y));
          break;
        }
      }
    }
    return decorations;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/layers/data/datasources/level/local/level_local_datasource_impl_test.dart`
Expected: `All tests passed!` (4 tests). Si falla el test dorado, comparar paso a paso con `LevelLocalDataSourceImpl.kt` (orden de `random.next()`: x, y, y solo si el árbol se acepta, madera; el tipo usa su propio generador `kinds`). No tocar los números esperados.

- [ ] **Step 6: Run the golden tests on the web engine**

Run: `flutter test --platform chrome test/core/utils test/layers/data/datasources/level`
Expected: `All tests passed!` — mismo bosque compilado a JavaScript (README D8).

- [ ] **Step 7: Format, analyze and commit**

```bash
dart format --line-length 120 lib/layers/data test/layers/data
flutter analyze
git add lib/layers/data/datasources/level test/layers/data/datasources/level
git commit -m "[PROJECT-X]: Port the seeded forest generator and level DBOs"
```

Expected: `flutter analyze` → `No issues found!`.

---

### Task 3: Mappers DBO → entidad

**Files:**
- Create: `lib/layers/data/repositories/level/mappers/position_mapper_dbo.dart`
- Create: `lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart`
- Create: `lib/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart`
- Create: `lib/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart`
- Create: `lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart`
- Create: `test/mocks/data/datasources/level/level_dbo_mock.dart`
- Test: `test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`

**Interfaces:**
- Consumes: DBOs (tarea 2); `toKebabCase()` (tarea 1); `PositionEntity`, `TreeEntity`, `DecorationEntity`, `GroundItemEntity`, `PlayerEntity`, `World`, `Rules`, `TreeKind`, `DecorationKind`, `ToolKind` (fase 2 / README §3); `InvalidLevelException`, `UnknownTreeKindException`, `UnknownDecorationKindException`, `UnknownItemKindException` (fase 1).
- Produces (todos `@Injectable()`):
  - `PositionMapperDBO.toEntity(PointDBO dbo) → PositionEntity` (nulls → 0).
  - `TreeMapperDBO.toEntity(TreeDBO dbo, {required int index}) → TreeEntity` (id por defecto `tree-${index + 1}`, `trunkRadius: Rules.treeTrunkRadius`, `hitsToFell: Rules.hitsToFellTree`, `woodYield: wood ?? 0`; tipo desconocido → `UnknownTreeKindException(data: '<id>: "<kind>"')`).
  - `DecorationMapperDBO.toEntity(DecorationDBO dbo, {required int index}) → DecorationEntity` (id por defecto `decoration-${index + 1}`; tipo desconocido → `UnknownDecorationKindException(data: '<id>: "<kind>"')`).
  - `GroundItemMapperDBO.toEntity(ItemDBO dbo) → GroundItemEntity` (id `dbo.id ?? ''`, tipo sin distinguir mayúsculas; desconocido → `UnknownItemKindException(data: '<id>: "<kind>"')`).
  - `LevelMapperDBO({required PositionMapperDBO positionMapperDBO, required TreeMapperDBO treeMapperDBO, required DecorationMapperDBO decorationMapperDBO, required GroundItemMapperDBO groundItemMapperDBO})` con `World toEntity(LevelDBO dbo)` (sin ancho / alto / inicio → `InvalidLevelException(data: 'missing width' | 'missing height' | 'missing player start')`; jugador con `Rules.playerSpeed` y `Rules.playerRadius`).
  - `LevelDBOMock.mock`, `.mockWithUnknownItem`, `.mockWithoutSize`, `.mockWithUnknownTreeKind`, `.mockWithUnknownDecorationKind`.

- [ ] **Step 1: Write the mock data**

`test/mocks/data/datasources/level/level_dbo_mock.dart` (port de `LevelDtoMock.kt`, más una variante de decoración desconocida):

```dart
import 'package:rpg/layers/data/datasources/level/local/dbo/decoration_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/item_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/level_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/point_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';

abstract final class LevelDBOMock {
  static const PointDBO _playerStart = PointDBO(x: 200, y: 150);
  static const List<TreeDBO> _trees = [TreeDBO(id: 'tree-a', kind: 'oak', x: 50, y: 60, wood: 5)];
  static const List<ItemDBO> _items = [ItemDBO(id: 'axe', kind: 'axe', x: 220, y: 150)];
  static const List<DecorationDBO> _decorations = [
    DecorationDBO(id: 'decoration-a', kind: 'tall-grass', x: 300, y: 200),
  ];

  static const LevelDBO mock = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: _items,
    decorations: _decorations,
  );

  static const LevelDBO mockWithUnknownItem = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: [ItemDBO(id: 'mystery', kind: 'laser', x: 0, y: 0)],
    decorations: _decorations,
  );

  static const LevelDBO mockWithoutSize = LevelDBO(
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: _items,
    decorations: _decorations,
  );

  static const LevelDBO mockWithUnknownTreeKind = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: [TreeDBO(id: 'tree-x', kind: 'palm', x: 0, y: 0, wood: 5)],
    items: _items,
    decorations: _decorations,
  );

  static const LevelDBO mockWithUnknownDecorationKind = LevelDBO(
    width: 400,
    height: 300,
    playerStart: _playerStart,
    trees: _trees,
    items: _items,
    decorations: [DecorationDBO(id: 'decoration-x', kind: 'lava', x: 0, y: 0)],
  );
}
```

- [ ] **Step 2: Write the failing test**

`test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/decoration_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/level_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../../mocks/data/datasources/level/level_dbo_mock.dart';

void main() {
  late LevelMapperDBO sut;

  setUp(() {
    sut = LevelMapperDBO(
      positionMapperDBO: PositionMapperDBO(),
      treeMapperDBO: TreeMapperDBO(),
      decorationMapperDBO: DecorationMapperDBO(),
      groundItemMapperDBO: GroundItemMapperDBO(),
    );
  });

  test('testWhenMappingAValidLevelThenBuildsTheWorldWithDomainRules', () {
    // given
    const dbo = LevelDBOMock.mock;

    // when
    final world = sut.toEntity(dbo);

    // then
    expect(world.width, 400.0);
    expect(world.height, 300.0);
    expect(world.player.position, const PositionEntity(x: 200, y: 150));
    expect(world.player.speed, 110.0);
    expect(world.player.radius, 8.0);
    expect(world.trees.single.id, 'tree-a');
    expect(world.trees.single.woodYield, 5);
    expect(world.trees.single.trunkRadius, 12.0);
    expect(world.trees.single.hitsToFell, 5);
    expect(world.trees.single.kind, TreeKind.oak);
    expect(world.items.single.kind, ToolKind.axe);
    expect(world.items.single.position, const PositionEntity(x: 220, y: 150));
    expect(world.decorations.single.kind, DecorationKind.tallGrass);
    expect(world.decorations.single.position, const PositionEntity(x: 300, y: 200));
  });

  test('testWhenMappingTwiceThenEachWorldIsIndependent', () {
    // given
    final first = sut.toEntity(LevelDBOMock.mock);

    // when
    first.movePlayerTo(const PositionEntity(x: 10, y: 10));
    first.advance(1000);
    final second = sut.toEntity(LevelDBOMock.mock);

    // then
    expect(second.player.position, const PositionEntity(x: 200, y: 150));
  });

  test('testWhenLevelHasUnknownItemKindThenThrowsUnknownItemKindException', () {
    // given
    const dbo = LevelDBOMock.mockWithUnknownItem;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(isA<UnknownItemKindException>().having((exception) => exception.data, 'data', 'mystery: "laser"')),
    );
  });

  test('testWhenLevelHasUnknownTreeKindThenThrowsUnknownTreeKindException', () {
    // given
    const dbo = LevelDBOMock.mockWithUnknownTreeKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(isA<UnknownTreeKindException>().having((exception) => exception.data, 'data', 'tree-x: "palm"')),
    );
  });

  test('testWhenLevelHasUnknownDecorationKindThenThrowsUnknownDecorationKindException', () {
    // given
    const dbo = LevelDBOMock.mockWithUnknownDecorationKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(
        isA<UnknownDecorationKindException>().having((exception) => exception.data, 'data', 'decoration-x: "lava"'),
      ),
    );
  });

  test('testWhenLevelHasNoSizeThenThrowsInvalidLevelException', () {
    // given
    const dbo = LevelDBOMock.mockWithoutSize;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsA(isA<InvalidLevelException>().having((exception) => exception.data, 'data', 'missing width')));
  });

  test('testWhenTreeHasNoIdThenUsesItsPositionInTheList', () {
    // given
    const dbo = TreeDBO(kind: 'pine', x: 1, y: 2);

    // when
    final tree = TreeMapperDBO().toEntity(dbo, index: 4);

    // then
    expect(tree.id, 'tree-5');
    expect(tree.woodYield, 0);
    expect(tree.kind, TreeKind.pine);
  });

  test('testWhenDecorationHasNoIdThenUsesItsPositionInTheList', () {
    // given
    const dbo = DecorationDBO(kind: 'mushrooms', x: 1, y: 2);

    // when
    final decoration = DecorationMapperDBO().toEntity(dbo, index: 0);

    // then
    expect(decoration.id, 'decoration-1');
    expect(decoration.kind, DecorationKind.mushrooms);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`
Expected: FAIL — compilation error, `level_mapper_dbo.dart` (and the other mappers) not found.

- [ ] **Step 4: Write the mappers**

`lib/layers/data/repositories/level/mappers/position_mapper_dbo.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../datasources/level/local/dbo/point_dbo.dart';

@Injectable()
class PositionMapperDBO {
  PositionEntity toEntity(PointDBO dbo) {
    return PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0);
  }
}
```

`lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/utils/kebab_case.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/entities/tree/tree_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/level/local/dbo/tree_dbo.dart';

@Injectable()
class TreeMapperDBO {
  TreeEntity toEntity(TreeDBO dbo, {required int index}) {
    final treeId = dbo.id ?? 'tree-${index + 1}';
    return TreeEntity(
      id: treeId,
      kind: _kind(treeId, dbo.kind),
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: dbo.wood ?? 0,
      hitsToFell: Rules.hitsToFellTree,
    );
  }

  TreeKind _kind(String treeId, String? name) {
    for (final kind in TreeKind.values) {
      if (kind.name.toKebabCase() == name) return kind;
    }
    throw UnknownTreeKindException(data: '$treeId: "${name ?? ''}"');
  }
}
```

`lib/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/utils/kebab_case.dart';
import '../../../../domain/entities/decoration/decoration_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../datasources/level/local/dbo/decoration_dbo.dart';

@Injectable()
class DecorationMapperDBO {
  DecorationEntity toEntity(DecorationDBO dbo, {required int index}) {
    final decorationId = dbo.id ?? 'decoration-${index + 1}';
    return DecorationEntity(
      id: decorationId,
      kind: _kind(decorationId, dbo.kind),
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
    );
  }

  DecorationKind _kind(String decorationId, String? name) {
    for (final kind in DecorationKind.values) {
      if (kind.name.toKebabCase() == name) return kind;
    }
    throw UnknownDecorationKindException(data: '$decorationId: "${name ?? ''}"');
  }
}
```

`lib/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/entities/item/ground_item_entity.dart';
import '../../../datasources/level/local/dbo/item_dbo.dart';

@Injectable()
class GroundItemMapperDBO {
  GroundItemEntity toEntity(ItemDBO dbo) {
    final itemId = dbo.id ?? '';
    return GroundItemEntity(
      id: itemId,
      kind: _kind(itemId, dbo.kind),
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
    );
  }

  ToolKind _kind(String itemId, String? name) {
    for (final kind in ToolKind.values) {
      if (kind.name.toLowerCase() == name?.toLowerCase()) return kind;
    }
    throw UnknownItemKindException(data: '$itemId: "${name ?? ''}"');
  }
}
```

`lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/player/player_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../../domain/world/world.dart';
import '../../../datasources/level/local/dbo/level_dbo.dart';
import 'decoration_mapper_dbo.dart';
import 'ground_item_mapper_dbo.dart';
import 'position_mapper_dbo.dart';
import 'tree_mapper_dbo.dart';

@Injectable()
class LevelMapperDBO {
  final PositionMapperDBO _positionMapperDBO;
  final TreeMapperDBO _treeMapperDBO;
  final DecorationMapperDBO _decorationMapperDBO;
  final GroundItemMapperDBO _groundItemMapperDBO;

  const LevelMapperDBO({
    required this._positionMapperDBO,
    required this._treeMapperDBO,
    required this._decorationMapperDBO,
    required this._groundItemMapperDBO,
  });

  World toEntity(LevelDBO dbo) {
    final width = dbo.width ?? (throw const InvalidLevelException(data: 'missing width'));
    final height = dbo.height ?? (throw const InvalidLevelException(data: 'missing height'));
    final playerStart = dbo.playerStart ?? (throw const InvalidLevelException(data: 'missing player start'));
    final trees = dbo.trees ?? const [];
    final items = dbo.items ?? const [];
    final decorations = dbo.decorations ?? const [];
    return World(
      width: width,
      height: height,
      player: PlayerEntity(
        position: _positionMapperDBO.toEntity(playerStart),
        speed: Rules.playerSpeed,
        radius: Rules.playerRadius,
      ),
      trees: [for (var index = 0; index < trees.length; index++) _treeMapperDBO.toEntity(trees[index], index: index)],
      items: items.map(_groundItemMapperDBO.toEntity).toList(),
      decorations: [
        for (var index = 0; index < decorations.length; index++)
          _decorationMapperDBO.toEntity(decorations[index], index: index),
      ],
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`
Expected: `All tests passed!` (8 tests).

- [ ] **Step 6: Format, analyze and commit**

```bash
dart format --line-length 120 lib/layers/data test/layers/data test/mocks
flutter analyze
git add lib/layers/data/repositories/level/mappers test/layers/data/repositories/level/mappers test/mocks/data
git commit -m "[PROJECT-X]: Map level DBOs to the world aggregate"
```

Expected: `flutter analyze` → `No issues found!`.

---

### Task 4: `LevelRepositoryImpl`

**Files:**
- Create: `lib/layers/data/repositories/level/level_repository_impl.dart`
- Test: `test/layers/data/repositories/level/level_repository_impl_test.dart`
- Generated: `test/layers/data/repositories/level/level_repository_impl_test.mocks.dart`, `lib/core/config/di/di.config.dart`

**Interfaces:**
- Consumes: `LevelLocalDatasource` (tarea 2), `LevelMapperDBO` y sus mappers (tarea 3), `AppExceptionHandler.handle({required Object? exception, StackTrace? stackTrx})` (fase 1), `abstract interface class LevelRepository { World load(); }` (fase 2).
- Produces: `@Injectable(as: LevelRepository) final class LevelRepositoryImpl` con `const LevelRepositoryImpl({required LevelLocalDatasource localDatasource, required LevelMapperDBO levelMapperDBO, required AppExceptionHandler appExceptionHandler})` — lo consume `StartGameUseCase` (fase 4) a través de la interfaz.

- [ ] **Step 1: Write the failing test**

`test/layers/data/repositories/level/level_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/layers/data/datasources/level/source/level_local_datasource.dart';
import 'package:rpg/layers/data/repositories/level/level_repository_impl.dart';
import 'package:rpg/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/level_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/data/datasources/level/level_dbo_mock.dart';
import 'level_repository_impl_test.mocks.dart';

@GenerateMocks([LevelLocalDatasource])
void main() {
  late MockLevelLocalDatasource localDatasource;
  late LevelRepositoryImpl sut;

  setUp(() {
    localDatasource = MockLevelLocalDatasource();
    sut = LevelRepositoryImpl(
      localDatasource: localDatasource,
      levelMapperDBO: LevelMapperDBO(
        positionMapperDBO: PositionMapperDBO(),
        treeMapperDBO: TreeMapperDBO(),
        decorationMapperDBO: DecorationMapperDBO(),
        groundItemMapperDBO: GroundItemMapperDBO(),
      ),
      appExceptionHandler: AppExceptionHandler(),
    );
  });

  test('testWhenLoadWithSuccessThenBuildsTheWorldFromTheDatasource', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mock);

    // when
    final world = sut.load();

    // then
    verify(localDatasource.fetch()).called(1);
    expect(world.width, 400.0);
    expect(world.player.position, const PositionEntity(x: 200, y: 150));
    expect(world.trees.single.kind, TreeKind.oak);
  });

  test('testWhenLoadTwiceThenEachWorldIsIndependent', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mock);
    final first = sut.load();

    // when
    first.movePlayerTo(const PositionEntity(x: 10, y: 10));
    first.advance(1000);
    final second = sut.load();

    // then
    expect(second.player.position, const PositionEntity(x: 200, y: 150));
  });

  test('testWhenLevelHasUnknownItemKindThenThrowsUnknownItemKindException', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mockWithUnknownItem);

    // when
    void load() => sut.load();

    // then
    expect(
      load,
      throwsA(isA<UnknownItemKindException>().having((exception) => exception.data, 'data', 'mystery: "laser"')),
    );
  });

  test('testWhenLevelHasUnknownTreeKindThenThrowsUnknownTreeKindException', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mockWithUnknownTreeKind);

    // when
    void load() => sut.load();

    // then
    expect(
      load,
      throwsA(isA<UnknownTreeKindException>().having((exception) => exception.data, 'data', 'tree-x: "palm"')),
    );
  });

  test('testWhenLevelHasNoSizeThenThrowsInvalidLevelException', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mockWithoutSize);

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<InvalidLevelException>()));
  });

  test('testWhenDatasourceFailsThenErrorIsRoutedThroughTheHandler', () {
    // given
    when(localDatasource.fetch()).thenThrow(StateError('disk unavailable'));

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<GenericException>()));
    verify(localDatasource.fetch()).called(1);
  });
}
```

- [ ] **Step 2: Generate the mocks and run the test to verify it fails**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/layers/data/repositories/level/level_repository_impl_test.dart`
Expected: build_runner `Succeeded after ...` (genera `level_repository_impl_test.mocks.dart`); el test FAIL — compilation error, `level_repository_impl.dart` not found.

- [ ] **Step 3: Write minimal implementation**

`lib/layers/data/repositories/level/level_repository_impl.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/handlers/app_exception_handler.dart';
import '../../../domain/repositories/level/level_repository.dart';
import '../../../domain/world/world.dart';
import '../../datasources/level/source/level_local_datasource.dart';
import 'mappers/level_mapper_dbo.dart';

@Injectable(as: LevelRepository)
final class LevelRepositoryImpl implements LevelRepository {
  final LevelLocalDatasource _localDatasource;
  final LevelMapperDBO _levelMapperDBO;
  final AppExceptionHandler _appExceptionHandler;

  const LevelRepositoryImpl({
    required this._localDatasource,
    required this._levelMapperDBO,
    required this._appExceptionHandler,
  });

  @override
  World load() {
    try {
      return _levelMapperDBO.toEntity(_localDatasource.fetch());
    } catch (exception, stackTrace) {
      throw _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    }
  }
}
```

- [ ] **Step 4: Regenerate DI and run the tests**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/layers/data/repositories/level`
Expected: build_runner `Succeeded after ...`; `lib/core/config/di/di.config.dart` registra `LevelLocalDatasource`, los cinco mappers y `LevelRepository`; tests `All tests passed!` (6 + 8 tests).

- [ ] **Step 5: Format, analyze and commit**

```bash
dart format --line-length 120 lib/layers/data test/layers/data
flutter analyze
git add lib/layers/data/repositories/level/level_repository_impl.dart lib/core/config/di/di.config.dart test/layers/data/repositories/level
git commit -m "[PROJECT-X]: Add the level repository with centralised error handling"
```

Expected: `flutter analyze` → `No issues found!` (los `*.mocks.dart` y `di.config.dart` están excluidos del análisis según `analysis_options.yaml`).

---

### Task 5: Sesión en memoria y `GameSessionRepositoryImpl`

**Files:**
- Create: `lib/layers/data/datasources/session/source/game_session_local_datasource.dart`
- Create: `lib/layers/data/datasources/session/local/game_session_local_datasource_impl.dart`
- Create: `lib/layers/data/repositories/session/game_session_repository_impl.dart`
- Create: `test/mocks/domain/entities/game/game_session_entity_mock.dart`
- Test: `test/layers/data/datasources/session/local/game_session_local_datasource_impl_test.dart`
- Test: `test/layers/data/repositories/session/game_session_repository_impl_test.dart`
- Generated: `test/layers/data/repositories/session/game_session_repository_impl_test.mocks.dart`, `lib/core/config/di/di.config.dart`

**Interfaces:**
- Consumes: `GameSessionEntity({required World world, required QuestLog quests})`, `QuestLog({List<Quest>? quests})`, `abstract interface class GameSessionRepository { GameSessionEntity current(); void save(GameSessionEntity session); }` (fase 2); `NoGameInProgressException()`, `GenericException()`, `AppExceptionHandler` (fase 1); `WorldMock.make()` (fase 2, tests).
- Produces:
  - `abstract interface class GameSessionLocalDatasource { GameSessionEntity? get(); void set(GameSessionEntity session); }`
  - `@LazySingleton(as: GameSessionLocalDatasource) class GameSessionLocalDatasourceImpl` — una sola partida por app.
  - `@Injectable(as: GameSessionRepository) final class GameSessionRepositoryImpl` con `const GameSessionRepositoryImpl({required GameSessionLocalDatasource localDatasource, required AppExceptionHandler appExceptionHandler})`.
  - `GameSessionEntityMock.make() → GameSessionEntity` (mundo nuevo en cada llamada; lo reutiliza la fase 4).

- [ ] **Step 1: Write the mock data**

`test/mocks/domain/entities/game/game_session_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';

import '../../world/world_mock.dart';

abstract final class GameSessionEntityMock {
  static GameSessionEntity make() => GameSessionEntity(world: WorldMock.make(), quests: QuestLog());
}
```

- [ ] **Step 2: Write the failing tests**

`test/layers/data/datasources/session/local/game_session_local_datasource_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/data/datasources/session/local/game_session_local_datasource_impl.dart';

import '../../../../../mocks/domain/entities/game/game_session_entity_mock.dart';

void main() {
  late GameSessionLocalDatasourceImpl sut;

  setUp(() {
    sut = GameSessionLocalDatasourceImpl();
  });

  test('testWhenNothingWasSetThenGetReturnsNull', () {
    // given
    // a fresh datasource

    // when
    final session = sut.get();

    // then
    expect(session, isNull);
  });

  test('testWhenSettingASessionThenGetReturnsTheSameInstance', () {
    // given
    final session = GameSessionEntityMock.make();

    // when
    sut.set(session);

    // then
    expect(sut.get(), same(session));
  });
}
```

`test/layers/data/repositories/session/game_session_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/layers/data/datasources/session/source/game_session_local_datasource.dart';
import 'package:rpg/layers/data/repositories/session/game_session_repository_impl.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import 'game_session_repository_impl_test.mocks.dart';

@GenerateMocks([GameSessionLocalDatasource])
void main() {
  late MockGameSessionLocalDatasource localDatasource;
  late GameSessionRepositoryImpl sut;

  setUp(() {
    localDatasource = MockGameSessionLocalDatasource();
    sut = GameSessionRepositoryImpl(localDatasource: localDatasource, appExceptionHandler: AppExceptionHandler());
  });

  test('testWhenSavingThenCurrentReturnsTheSameSession', () {
    // given
    final session = GameSessionEntityMock.make();
    when(localDatasource.get()).thenReturn(session);

    // when
    sut.save(session);
    final current = sut.current();

    // then
    verify(localDatasource.set(session)).called(1);
    verify(localDatasource.get()).called(1);
    expect(current, same(session));
  });

  test('testWhenNoGameWasStartedThenCurrentThrowsNoGameInProgressException', () {
    // given
    when(localDatasource.get()).thenReturn(null);

    // when
    void current() => sut.current();

    // then
    expect(current, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenDatasourceFailsThenErrorIsRoutedThroughTheHandler', () {
    // given
    when(localDatasource.set(any)).thenThrow(StateError('storage unavailable'));

    // when
    void save() => sut.save(GameSessionEntityMock.make());

    // then
    expect(save, throwsA(isA<GenericException>()));
  });
}
```

- [ ] **Step 3: Generate the mocks and run the tests to verify they fail**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/layers/data/datasources/session test/layers/data/repositories/session`
Expected: build_runner falla o los tests FAIL — compilation error, `game_session_local_datasource.dart` / `game_session_local_datasource_impl.dart` / `game_session_repository_impl.dart` not found.

- [ ] **Step 4: Write the datasource and the repository**

`lib/layers/data/datasources/session/source/game_session_local_datasource.dart`:

```dart
import '../../../../domain/entities/game/game_session_entity.dart';

abstract interface class GameSessionLocalDatasource {
  GameSessionEntity? get();

  void set(GameSessionEntity session);
}
```

`lib/layers/data/datasources/session/local/game_session_local_datasource_impl.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../domain/entities/game/game_session_entity.dart';
import '../source/game_session_local_datasource.dart';

@LazySingleton(as: GameSessionLocalDatasource)
class GameSessionLocalDatasourceImpl implements GameSessionLocalDatasource {
  GameSessionEntity? _session;

  @override
  GameSessionEntity? get() => _session;

  @override
  void set(GameSessionEntity session) {
    _session = session;
  }
}
```

`lib/layers/data/repositories/session/game_session_repository_impl.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../core/error-handling/handlers/app_exception_handler.dart';
import '../../../domain/entities/game/game_session_entity.dart';
import '../../../domain/repositories/session/game_session_repository.dart';
import '../../datasources/session/source/game_session_local_datasource.dart';

@Injectable(as: GameSessionRepository)
final class GameSessionRepositoryImpl implements GameSessionRepository {
  final GameSessionLocalDatasource _localDatasource;
  final AppExceptionHandler _appExceptionHandler;

  const GameSessionRepositoryImpl({required this._localDatasource, required this._appExceptionHandler});

  @override
  GameSessionEntity current() {
    try {
      final session = _localDatasource.get();
      if (session == null) throw const NoGameInProgressException();
      return session;
    } catch (exception, stackTrace) {
      throw _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    }
  }

  @override
  void save(GameSessionEntity session) {
    try {
      _localDatasource.set(session);
    } catch (exception, stackTrace) {
      throw _appExceptionHandler.handle(exception: exception, stackTrx: stackTrace);
    }
  }
}
```

- [ ] **Step 5: Regenerate mocks and DI, run the tests**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/layers/data/datasources/session test/layers/data/repositories/session`
Expected: build_runner `Succeeded after ...`; `di.config.dart` registra `GameSessionLocalDatasource` como lazy singleton y `GameSessionRepository`; tests `All tests passed!` (2 + 3 tests).

- [ ] **Step 6: Run the whole phase**

Run: `flutter test test/core/utils test/layers/data && flutter test --platform chrome test/core/utils test/layers/data/datasources/level`
Expected: `All tests passed!` en ambas ejecuciones (VM: 3 + 4 + 8 + 6 + 2 + 3 tests de esta fase, más los de `SeededRandom` de la fase 1; Chrome: los dorados).

Run: `flutter test test/architecture_test.dart`
Expected: `All tests passed!` — `data/` solo importa `domain/` y `core/`.

- [ ] **Step 7: Format, analyze and commit**

```bash
dart format --line-length 120 lib test
flutter analyze
git add lib/layers/data/datasources/session lib/layers/data/repositories/session lib/core/config/di/di.config.dart test/layers/data/datasources/session test/layers/data/repositories/session test/mocks/domain/entities/game
git commit -m "[PROJECT-X]: Add the in-memory game session datasource and repository"
```

Expected: `flutter analyze` → `No issues found!`; `git status` limpio salvo ficheros generados ignorados.

---

## Cierre de la fase

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` (suite completa) → `All tests passed!`
- [ ] `flutter test --platform chrome test/core/utils test/layers/data/datasources/level` → `All tests passed!`
- [ ] Anotar en README §7 cualquier desviación (por ejemplo, si el test dorado obligó a ajustar el cálculo de distancias).
