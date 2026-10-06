# F1 · Árboles con personalidad — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F0 |
| **Issue / milestone** | `phase:F1` · milestone `F1 Tree kinds` |

**Goal:** Que el tipo de árbol (`TreeKind`, que el generador ya decide) cambie cuánto cuesta talarlo y cuánta madera da. Aparece la primera decisión: ¿talo el roble grande o tres pinos rápidos? Además, la madera ganada se ve flotar sobre el árbol ("+8").

**Architecture:**
- Nueva entidad `TreeStatsEntity(woodYield, hitsToFell)` en `domain/entities/tree/`.
- `Rules.treeKindStats` es la tabla `TreeKind → TreeStatsEntity`. `Rules.hitsToFellTree` desaparece.
- `TreeEntity` **no cambia**: sigue teniendo `woodYield` y `hitsToFell`. Los rellena `TreeMapperDBO` a partir de `kind` con la tabla, e ignora `TreeDBO.wood`.
- El generador (`LevelLocalDatasourceImpl`) no cambia: sigue sacando `wood` de la semilla para no mover la secuencia aleatoria (posiciones y tipos idénticos).
- `World`, `Woodcutting` y `TreeFelledEventEntity` no cambian: ya usan los valores de cada árbol.
- Presentación:
  - `TreeFelledEffect` lleva `wood`;
  - `ForestSceneComponent._onTreeFelled` añade un `FloatingTextComponent` nuevo con el texto `Internationalize.forestFloatingWoodGained(wood:)`.
- Dos tareas secuenciales. Cada una deja `develop` en verde:
  - T1.1 dominio + datos;
  - T1.2 presentación.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame 1.38 (`TextComponent`), `easy_localization`, `flutter_test` + `mockito` + `bloc_test` + `flame_test`.

**Cómo probar la fase entera:** en Chrome, en el emulador Android y en el simulador iOS:
- un árbol grande (roble, viejo o gigante: `oak`, `old`, `big`) pide 7–8 golpes y da 8–9 de madera;
- un pino o un árbol delgado (`pine`, `slim`) cae en 3 golpes y da 4;
- el resto, como hoy: 5 golpes y 5–6 de madera;
- al caer cada árbol sube y se desvanece sobre el tocón un "+N" con la madera ganada (por ejemplo "+8" en un roble y "+4" en un pino). El *snackbar* "+N de madera" se mantiene;
- la misión "Consigue al menos 15 de madera" se sigue completando (por ejemplo, con dos robles o cuatro pinos);
- el bosque se ve igual que antes: mismas posiciones, tipos y decoración.

## Decisiones del plan

- **Tabla final** (`Rules.treeKindStats`; cubre los 14 valores de `TreeKind`):

  | `TreeKind` | Madera | Golpes | Árboles en el mapa |
  |---|---|---|---|
  | `oak` | 8 | 7 | 6 |
  | `old` | 9 | 8 | 6 |
  | `big` | 9 | 8 | 4 |
  | `pine` | 4 | 3 | 8 |
  | `slim` | 4 | 3 | 4 |
  | `wide`, `broad`, `dense`, `dome` (copa grande) | 6 | 5 | 6 + 3 + 4 + 2 |
  | `round`, `twisted`, `branches`, `leaning`, `lumpy` | 5 | 5 | 5 + 3 + 7 + 8 + 4 |

  Los grandes dan algo más de madera por golpe que el resto (≈ 1,1), pero obligan a quedarse quieto más tiempo; los pinos dan más por golpe (1,33), pero hay que ir de uno a otro.
- **Nuevo total de madera del mapa: 411** (antes 388) en `test/core/config/di/di_test.dart`. Se ha calculado ejecutando el generador real (`LevelLocalDatasourceImpl.fetch()`) y sumando la madera de la tabla por el `kind` de cada `TreeDBO`:
  - recuento de tipos (el mismo que fija el test dorado): broad 3, old 6, pine 8, slim 4, dense 4, branches 7, big 4, lumpy 4, leaning 8, oak 6, round 5, wide 6, twisted 3, dome 2;
  - 138 (grandes) + 48 (pinos y delgados) + 90 (copa grande) + 135 (resto) = **411**.
  - Si alguien cambia la tabla, recalcula el número con el test `testWhenStartingAGameThenTheProceduralForestIsLoaded`: el mensaje de fallo (`Expected: <411> Actual: <N>`) da el total nuevo, que se copia en el `expect`.
- **El total de `TreeDBO.wood` (388) no cambia:** `level_local_datasource_impl_test.dart` (también en Chrome) queda intacto.
- **`TreeEntity` conserva `woodYield` y `hitsToFell`:** F3 (rebrote) los vuelve a rellenar con la tabla. El dominio no consulta la tabla al talar; confía en la entidad.
- **El mapper lee la tabla con `Rules.treeKindStats[kind]!`.** Que no falte ningún tipo lo garantiza `rules_test.dart` (recorre `TreeKind.values`), igual que hace F0 con los recursos.
- **`TreeEntityMock.mock` (un `oak` con 6 de madera y 5 golpes) no se toca:** el dominio no mira la tabla y cambiarlo movería decenas de tests. Los tests que usaban `Rules.hitsToFellTree` pasan a `TreeEntityMock.mock.hitsToFell`. Para los casos por tipo hay un mock nuevo, `TreeEntityMock.ofKind(kind)`, que toma los valores de la tabla.
- **Tipos representativos en los tests:** `oak` (grande), `pine` (rápido) y `round` (como hoy). El mapper, además, se prueba con todos los `TreeKind`.
- **`FloatingTextComponent`:**
  - API genérica `FloatingTextComponent({required String text, required PositionEntity at, Color color = defaultColor})`, sin nada propio del bosque, para que C2 (arena, "−N") lo pueda reutilizar;
  - nace 20 px por encima de la base del tronco (`startLift`), anclado abajo al centro (`Anchor.bottomCenter`), y sube 18 px (`rise`) con `Easing.sineOut` en 900 ms (`lifetimeMs`);
  - opaco la primera mitad; en la segunda se desvanece linealmente hasta 0 y se quita solo;
  - texto de 9 px en negrita (18 px en pantalla con el zoom 2), color `CustomColors.hudAccent` con sombra `CustomColors.black` desplazada 0,5 px;
  - prioridad `RenderDepth.overlay`: siempre por encima de árboles y edificios;
  - la animación se lleva a mano en `update` (como `GroundItemComponent`), sin efectos de Flame. El `opacity` de `HasPaint` en `TextComponent` sustituye el color del texto por el de su `Paint`, así que el alfa se aplica rehaciendo el `TextPaint`.
- **El texto lo compone la escena, no el BLoC:** el efecto sólo lleva el número (`wood`), como pide la ficha.
- **Ramas:** `feature/PROJECT-X-f1-domain` y `feature/PROJECT-X-f1-presentation`, cada una desde `develop`. T1.2 empieza cuando T1.1 está fusionada.
- **Si la arena ya está (README, sección 6):** si C2 ya creó un componente de texto flotante, T1.2 lo reutiliza en lugar de crear `FloatingTextComponent` (ver la nota al principio de T1.2). Si no, C2 reutilizará este.

## Reparto

| Tarea | Capa | Depende de | Paralelizable |
|---|---|---|---|
| T1.1 Dominio y datos: madera y golpes por tipo | domain + data (+ tests que usaban `Rules.hitsToFellTree`) | — | No |
| T1.2 Presentación: "+N" flotante | presentation + i18n | T1.1 | No |

---

### Task T1.1: Dominio y datos: madera y golpes por tipo de árbol

**Files:**
- Create:
  - `lib/layers/domain/entities/tree/tree_stats_entity.dart`
  - `test/layers/domain/entities/tree/tree_stats_entity_test.dart`
  - `test/layers/domain/rules/rules_test.dart`
  - `test/mocks/domain/entities/tree/tree_stats_entity_mock.dart`
- Modify:
  - `lib/layers/domain/rules/rules.dart`
  - `lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart`
  - `CLAUDE.md` (*Architecture* y *Key cross-cutting conventions*)
- Test (en `test/`):
  - `layers/data/repositories/level/mappers/tree_mapper_dbo_test.dart`
  - `layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`
  - `layers/data/repositories/level/level_repository_impl_test.dart`
  - `layers/domain/world/world_chopping_test.dart`
  - `layers/domain/use-cases/game/game_flow_test.dart`
  - `layers/presentation/features/forest/bloc/forest_bloc_test.dart` (sólo deja de usar `Rules.hitsToFellTree`)
  - `core/config/di/di_test.dart` (388 → 411)
  - Mocks: `mocks/domain/entities/tree/tree_entity_mock.dart`, `mocks/domain/world/world_mock.dart`, `mocks/data/datasources/level/tree_dbo_mock.dart`, `mocks/data/datasources/level/level_dbo_mock.dart`.
- No cambian: `level_local_datasource_impl.dart`, `tree_dbo.dart`, `level_local_datasource_impl_test.dart`, `tree_entity.dart`, `woodcutting.dart`.

**Interfaces:**
- Consumes: `TreeKind` (`lib/core/config/constants/enum/tree_kind.dart`), `TreeEntity`, `TreeMapperDBO`.
- Produces (lo que usan T1.2 y F3):
  ```dart
  // lib/layers/domain/entities/tree/tree_stats_entity.dart
  class TreeStatsEntity {
    final int woodYield;    // >= 0
    final int hitsToFell;   // > 0
    const TreeStatsEntity({required this.woodYield, required this.hitsToFell});
    TreeStatsEntity copyWith({int? woodYield, int? hitsToFell});
  }

  // lib/layers/domain/rules/rules.dart
  static const Map<TreeKind, TreeStatsEntity> treeKindStats;   // one entry per TreeKind
  // removed: static const int hitsToFellTree

  // test mocks
  TreeStatsEntityMock.oak / .pine / .make({int woodYield, int hitsToFell})
  TreeEntityMock.ofKind(TreeKind kind)            // TreeEntityMock.mock with the table's wood and hits
  WorldMock.withAxeAndTreeOfKind(TreeKind kind)
  TreeDBOMock.ofKind(TreeKind kind)
  LevelDBOMock.mixedForest                         // oak, pine and round, with level wood that must be ignored
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f1-domain
```

- [ ] **Step 2: Test de `TreeStatsEntity`, que debe fallar**

`test/mocks/domain/entities/tree/tree_stats_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/tree/tree_stats_entity.dart';

abstract final class TreeStatsEntityMock {
  static const TreeStatsEntity oak = TreeStatsEntity(woodYield: 8, hitsToFell: 7);

  static const TreeStatsEntity pine = TreeStatsEntity(woodYield: 4, hitsToFell: 3);

  static TreeStatsEntity make({int woodYield = 5, int hitsToFell = 5}) =>
      TreeStatsEntity(woodYield: woodYield, hitsToFell: hitsToFell);
}
```

`test/layers/domain/entities/tree/tree_stats_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/tree/tree_stats_entity_mock.dart';

void main() {
  test('testWhenComparingStatsWithTheSameValuesThenTheyAreEqual', () {
    // given
    const stats = TreeStatsEntityMock.oak;

    // when
    final copy = TreeStatsEntityMock.make(woodYield: 8, hitsToFell: 7);

    // then
    expect(copy, stats);
    expect(copy.hashCode, stats.hashCode);
    expect(copy == TreeStatsEntityMock.pine, isFalse);
  });

  test('testWhenCopyingWithWoodAndHitsThenReplacesOnlyThose', () {
    // given
    const stats = TreeStatsEntityMock.oak;

    // when
    final copy = stats.copyWith(woodYield: 4, hitsToFell: 3);
    final unchanged = stats.copyWith();

    // then
    expect(copy, TreeStatsEntityMock.pine);
    expect(unchanged, stats);
  });

  test('testWhenWoodIsNegativeOrHitsAreNotPositiveThenCreationFails', () {
    // given
    const negativeWood = -1;
    const noHits = 0;

    // when
    Object withNegativeWood() => TreeStatsEntityMock.make(woodYield: negativeWood);
    Object withoutHits() => TreeStatsEntityMock.make(hitsToFell: noHits);

    // then
    expect(withNegativeWood, throwsA(isA<AssertionError>()));
    expect(withoutHits, throwsA(isA<AssertionError>()));
  });
}
```

Run: `flutter test test/layers/domain/entities/tree/tree_stats_entity_test.dart`
Expected: FAIL de compilación (`tree_stats_entity.dart` no existe).

- [ ] **Step 3: Implementar `TreeStatsEntity`**

`lib/layers/domain/entities/tree/tree_stats_entity.dart`:

```dart
class TreeStatsEntity {
  final int woodYield;
  final int hitsToFell;

  const TreeStatsEntity({required this.woodYield, required this.hitsToFell})
    : assert(woodYield >= 0),
      assert(hitsToFell > 0);

  TreeStatsEntity copyWith({int? woodYield, int? hitsToFell}) {
    return TreeStatsEntity(woodYield: woodYield ?? this.woodYield, hitsToFell: hitsToFell ?? this.hitsToFell);
  }

  @override
  bool operator ==(Object other) =>
      other is TreeStatsEntity && other.woodYield == woodYield && other.hitsToFell == hitsToFell;

  @override
  int get hashCode => Object.hash(woodYield, hitsToFell);
}
```

Run: `flutter test test/layers/domain/entities/tree/tree_stats_entity_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 4: Tests de la tabla y de talar cada tipo, que deben fallar**

`test/layers/domain/rules/rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/tree/tree_stats_entity_mock.dart';

void main() {
  test('testWhenListingTreeStatsThenEveryTreeKindHasAnEntry', () {
    // given
    final kinds = TreeKind.values.toSet();

    // when
    final covered = Rules.treeKindStats.keys.toSet();

    // then
    expect(covered, kinds);
  });

  test('testWhenComparingAnOakWithAPineThenTheOakNeedsMoreHitsAndGivesMoreWood', () {
    // given
    final oak = Rules.treeKindStats[TreeKind.oak]!;

    // when
    final pine = Rules.treeKindStats[TreeKind.pine]!;

    // then
    expect(oak, TreeStatsEntityMock.oak);
    expect(pine, TreeStatsEntityMock.pine);
    expect(oak.woodYield, greaterThan(pine.woodYield));
    expect(oak.hitsToFell, greaterThan(pine.hitsToFell));
  });
}
```

En `test/mocks/domain/entities/tree/tree_entity_mock.dart` se añade (con `import 'package:rpg/layers/domain/rules/rules.dart';`):

```dart
static TreeEntity ofKind(TreeKind kind) {
  final stats = Rules.treeKindStats[kind]!;
  return mock.copyWith(kind: kind, woodYield: stats.woodYield, hitsToFell: stats.hitsToFell);
}
```

En `test/mocks/domain/world/world_mock.dart` se añade (con `import 'package:rpg/core/config/constants/enum/tree_kind.dart';`):

```dart
static World withAxeAndTreeOfKind(TreeKind kind) =>
    make(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.ofKind(kind)]);
```

En `test/layers/domain/world/world_chopping_test.dart`, detrás de `testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded` (con `import 'package:rpg/core/config/constants/enum/tree_kind.dart';`):

```dart
for (final (name, kind, hits, wood) in const [
  ('testWhenChoppingAnOakThenTakesSevenHitsAndGivesEightWood', TreeKind.oak, 7, 8),
  ('testWhenChoppingAPineThenTakesThreeHitsAndGivesFourWood', TreeKind.pine, 3, 4),
  ('testWhenChoppingARoundTreeThenTakesFiveHitsAndGivesFiveWood', TreeKind.round, 5, 5),
]) {
  test(name, () {
    // given
    final world = WorldMock.withAxeAndTreeOfKind(kind);
    world.orderChop('tree-1');
    world.advanceFor(1500);

    // when
    final events = world.advanceFor(Rules.chopIntervalMs * hits + 100);

    // then
    expect(events.whereType<TreeHitEventEntity>().length, hits);
    expect(events, contains(GameEventEntityMock.makeTreeFelled(wood: wood)));
    expect(world.player.inventory.amount(Resource.wood), wood);
    expect(world.trees, isEmpty);
  });
}
```

Run: `flutter test test/layers/domain/rules test/layers/domain/world/world_chopping_test.dart`
Expected: FAIL de compilación (`Rules.treeKindStats` no existe).

- [ ] **Step 5: Añadir la tabla a `Rules`**

`lib/layers/domain/rules/rules.dart` (fichero caliente: `hitsToFellTree` se queda de momento, se borra en el paso 8; la tabla va al final):

```dart
import '../../../core/config/constants/enum/tree_kind.dart';
import '../entities/tree/tree_stats_entity.dart';

abstract final class Rules {
  static const int hitsToFellTree = 5;
  static const double chopIntervalMs = 750;
  static const double hammerIntervalMs = 650;
  static const double workGap = 2;
  static const double reachTolerance = 6;
  static const double pickUpRange = 14;
  static const double playerSpeed = 110;
  static const double playerRadius = 8;
  static const double treeTrunkRadius = 12;
  static const Map<TreeKind, TreeStatsEntity> treeKindStats = {
    TreeKind.slim: TreeStatsEntity(woodYield: 4, hitsToFell: 3),
    TreeKind.round: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.wide: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.broad: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.twisted: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.branches: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.leaning: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.lumpy: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.pine: TreeStatsEntity(woodYield: 4, hitsToFell: 3),
    TreeKind.dome: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.oak: TreeStatsEntity(woodYield: 8, hitsToFell: 7),
    TreeKind.dense: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.old: TreeStatsEntity(woodYield: 9, hitsToFell: 8),
    TreeKind.big: TreeStatsEntity(woodYield: 9, hitsToFell: 8),
  };
}
```

Las entradas siguen el orden de declaración de `TreeKind`.

Run: `flutter test test/layers/domain/rules test/layers/domain/world/world_chopping_test.dart test/layers/domain/entities/tree`
Expected: PASS.

- [ ] **Step 6: Tests del mapper, del repositorio y del total de madera, que deben fallar**

`test/mocks/data/datasources/level/tree_dbo_mock.dart` (con `import 'package:rpg/core/config/constants/enum/tree_kind.dart';` e `import 'package:rpg/core/utils/kebab_case.dart';`):

```dart
static TreeDBO ofKind(TreeKind kind) => TreeDBO(id: 'tree-1', kind: kind.name.toKebabCase(), x: 1, y: 2, wood: 6);
```

`test/mocks/data/datasources/level/level_dbo_mock.dart`, al final de la clase:

```dart
static const LevelDBO mixedForest = LevelDBO(
  width: 400,
  height: 300,
  playerStart: _playerStart,
  trees: [
    TreeDBO(id: 'tree-a', kind: 'oak', x: 50, y: 60, wood: 5),
    TreeDBO(id: 'tree-b', kind: 'pine', x: 150, y: 60, wood: 6),
    TreeDBO(id: 'tree-c', kind: 'round', x: 250, y: 60, wood: 6),
  ],
  items: _items,
  decorations: _decorations,
);
```

`test/layers/data/repositories/level/mappers/tree_mapper_dbo_test.dart` queda así:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:rpg/layers/domain/rules/rules.dart';

import '../../../../../mocks/data/datasources/level/tree_dbo_mock.dart';

void main() {
  late TreeMapperDBO sut;

  setUp(() {
    sut = TreeMapperDBO();
  });

  test('testWhenTreeHasNoIdThenUsesItsPositionInTheList', () {
    // given
    const dbo = TreeDBOMock.withoutId;

    // when
    final tree = sut.toEntity(dbo, index: 4);

    // then
    expect(tree.id, 'tree-5');
    expect(tree.woodYield, 4);
    expect(tree.kind, TreeKind.pine);
  });

  test('testWhenMappingEveryKindThenWoodAndHitsComeFromTheKindTable', () {
    // given
    final dbos = TreeKind.values.map(TreeDBOMock.ofKind).toList();

    // when
    final trees = [for (final dbo in dbos) sut.toEntity(dbo, index: 0)];

    // then
    expect(trees.map((tree) => tree.kind).toList(), TreeKind.values);
    for (final tree in trees) {
      expect(tree.woodYield, Rules.treeKindStats[tree.kind]!.woodYield);
      expect(tree.hitsToFell, Rules.treeKindStats[tree.kind]!.hitsToFell);
    }
  });

  test('testWhenMappingGeneratedTreesThenTheLevelWoodIsIgnored', () {
    // given
    const dbos = TreeDBOMock.firstGeneratedTrees;

    // when
    final trees = [for (var index = 0; index < dbos.length; index++) sut.toEntity(dbos[index], index: index)];

    // then
    expect(trees.map((tree) => tree.kind).toList(), [TreeKind.broad, TreeKind.old, TreeKind.pine]);
    expect(trees.map((tree) => tree.woodYield).toList(), [6, 9, 4]);
    expect(trees.map((tree) => tree.hitsToFell).toList(), [5, 8, 3]);
  });
}
```

`test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart`, en `testWhenMappingAValidLevelThenBuildsTheWorldWithDomainRules` (el árbol es un `oak` con `wood: 5` en el DBO):

```dart
expect(world.trees.single.woodYield, 8);
expect(world.trees.single.trunkRadius, 12.0);
expect(world.trees.single.hitsToFell, 7);
```

`test/layers/data/repositories/level/level_repository_impl_test.dart`, detrás de `testWhenLoadWithSuccessThenBuildsTheWorldFromTheDatasource`:

```dart
test('testWhenLoadingAMixedForestThenEachTreeTakesItsWoodAndHitsFromItsKind', () {
  // given
  when(localDatasource.fetch()).thenReturn(LevelDBOMock.mixedForest);

  // when
  final trees = sut.load().trees;

  // then
  expect(trees.map((tree) => tree.kind).toList(), [TreeKind.oak, TreeKind.pine, TreeKind.round]);
  expect(trees.map((tree) => tree.woodYield).toList(), [8, 4, 5]);
  expect(trees.map((tree) => tree.hitsToFell).toList(), [7, 3, 5]);
});
```

`test/core/config/di/di_test.dart`, en `testWhenStartingAGameThenTheProceduralForestIsLoaded`:

```dart
expect(snapshot.trees.fold<int>(0, (total, tree) => total + tree.woodYield), 411);
```

Run: `flutter test test/layers/data test/core/config/di/di_test.dart`
Expected: FAIL en los valores: el mapper aún copia `dbo.wood` y `Rules.hitsToFellTree` (por ejemplo `Expected: <411> Actual: <388>`, `Expected: [6, 9, 4] Actual: [6, 5, 6]`). `level_local_datasource_impl_test.dart` sigue en verde.

- [ ] **Step 7: `TreeMapperDBO` toma la madera y los golpes de la tabla**

`lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart`:

```dart
@Injectable()
class TreeMapperDBO {
  TreeEntity toEntity(TreeDBO dbo, {required int index}) {
    final treeId = dbo.id ?? 'tree-${index + 1}';
    final kind = _kind(treeId, dbo.kind);
    final stats = Rules.treeKindStats[kind]!;
    return TreeEntity(
      id: treeId,
      kind: kind,
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: stats.woodYield,
      hitsToFell: stats.hitsToFell,
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

Los imports no cambian.

Run: `flutter test test/layers/data test/core/config/di/di_test.dart`
Expected: PASS, incluido `level_local_datasource_impl_test.dart` con su total de `TreeDBO.wood` en 388.

- [ ] **Step 8: Borrar `Rules.hitsToFellTree`**

En `lib/layers/domain/rules/rules.dart` se borra la línea `static const int hitsToFellTree = 5;`.

Los tests que la usaban pasan al mock del árbol que talan (`TreeEntityMock.mock`, 5 golpes):
- `test/layers/domain/world/world_chopping_test.dart`:
  - en `testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded`: `world.advanceFor(Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell + 100)`;
  - en `testWhenTreeIsFelledThenPathIsFree`: `world.advanceFor(1500 + Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell + 100)`.
- `test/layers/domain/use-cases/game/game_flow_test.dart`:
  - `const chopTime = 2000 + Rules.chopIntervalMs * Rules.hitsToFellTree;` pasa a `final chopTime = 2000 + Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell;`;
  - nuevo import `'../../../../mocks/domain/entities/tree/tree_entity_mock.dart'`.
- `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`:
  - en `testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall`: `ForestBlocMock.tickFor(bloc, Rules.chopIntervalMs * TreeEntityMock.mock.hitsToFell);`;
  - nuevo import `'../../../../../mocks/domain/entities/tree/tree_entity_mock.dart'`.

Run: `grep -rn "hitsToFellTree" lib test`
Expected: sin resultados.

Run: `flutter test`
Expected: PASS (todos, incluido `architecture_test.dart`: `TreeStatsEntity` sólo tiene campos `final`).

- [ ] **Step 9: `CLAUDE.md`**

- En *Architecture*, la línea de `domain/`: "`rules/` (`Rules` tuning, `Blueprints` catalogue)" pasa a "`rules/` (`Rules` tuning, including `treeKindStats`: wood and hits per `TreeKind`; `Blueprints` catalogue)".
- En *Architecture*, la lista de entidades: "Geometry, tree, item, …" pasa a "Geometry, tree (`TreeEntity`, `TreeStatsEntity`), item, …".
- En *Key cross-cutting conventions*, "**The map is level data:** tree positions, wood, kinds and ground decoration come from the data layer; …" pasa a "**The map is level data:** tree positions, kinds and ground decoration come from the data layer; each tree's wood and hits come from `Rules.treeKindStats` through `TreeMapperDBO` (`TreeDBO.wood` is still generated so the seeded sequence, and every position, stays the same, but gameplay ignores it); …" (el resto de la frase no cambia).

Se añade con un `git add CLAUDE.md` aparte.

- [ ] **Step 10: Verificación completa**

```bash
dart format --line-length 120 lib/layers/domain/entities/tree/tree_stats_entity.dart lib/layers/domain/rules/rules.dart lib/layers/data/repositories/level/mappers/tree_mapper_dbo.dart test/layers/domain/entities/tree/tree_stats_entity_test.dart test/layers/domain/rules/rules_test.dart test/layers/domain/world/world_chopping_test.dart test/layers/domain/use-cases/game/game_flow_test.dart test/layers/data/repositories/level/mappers/tree_mapper_dbo_test.dart test/layers/data/repositories/level/mappers/level_mapper_dbo_test.dart test/layers/data/repositories/level/level_repository_impl_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/core/config/di/di_test.dart test/mocks/domain/entities/tree/tree_stats_entity_mock.dart test/mocks/domain/entities/tree/tree_entity_mock.dart test/mocks/domain/world/world_mock.dart test/mocks/data/datasources/level/tree_dbo_mock.dart test/mocks/data/datasources/level/level_dbo_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected:
- `build_runner` no cambia nada (no hay inyectables ni mocks nuevos);
- `flutter analyze` termina en `No issues found!`;
- los dos `flutter test` en verde. En Chrome, el total de entidades también es 411 y el de `TreeDBO.wood` sigue en 388.

- [ ] **Step 11: Commit y PR**

```bash
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-X]: Take tree wood and hits from the kind table"
```

Después, `/cerrar-tarea`: abre el PR con `Closes #<issue F1>` (o el número que le dé `/siguiente-tarea` a T1.1).

**Cómo probarlo a mano:** `flutter run -d chrome`. Recoge el hacha y tala un roble (7 golpes, +8 en el *snackbar*) y un pino (3 golpes, +4). Todavía no hay texto flotante.

---

### Task T1.2: Presentación: "+N" flotante sobre el árbol talado

> **Si la arena ya está:** antes de empezar, `grep -rn "class Floating" lib`. Si C2 ya creó un componente de texto flotante con texto, posición y color, se usa ese en los pasos 7 y 8 y se saltan los pasos 5 y 6 (su test ya existe). Se apunta en la sección 5 del README.

**Files:**
- Create:
  - `lib/layers/presentation/features/forest/game/components/floating_text_component.dart`
  - `test/layers/presentation/features/forest/game/components/floating_text_component_test.dart`
- Modify:
  - `lib/layers/presentation/features/forest/models/forest_effect.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - `lib/layers/presentation/features/forest/game/forest_scene_component.dart`
  - `lib/core/assets/i18n/internationalize.dart` y `lib/core/assets/i18n/translations/es.json`
  - `CLAUDE.md` (lista de componentes de `game/`)
- Test (en `test/`):
  - `core/assets/i18n/internationalize_test.dart`
  - `layers/presentation/features/forest/models/forest_effect_test.dart`
  - `layers/presentation/features/forest/bloc/forest_bloc_test.dart`
  - `layers/presentation/features/forest/game/forest_scene_component_test.dart`
  - Mocks: `mocks/presentation/features/forest/forest_effect_mock.dart`, `mocks/presentation/features/forest/game/forest_data_mock.dart`, `mocks/presentation/features/forest/forest_scenario_mock.dart`.

**Interfaces:**
- Consumes (de T1.1): `Rules.treeKindStats`, `TreeEntityMock.ofKind`. Ya existía: `TreeFelledEventEntity({required String treeId, required int wood})`.
- Produces (lo que puede reutilizar C2):
  ```dart
  // lib/layers/presentation/features/forest/models/forest_effect.dart
  TreeFelledEffect({required String treeId, required double fromX, required int wood})

  // lib/core/assets/i18n/internationalize.dart
  static String forestFloatingWoodGained({required int wood});   // "+8"

  // lib/layers/presentation/features/forest/game/components/floating_text_component.dart
  class FloatingTextComponent extends TextComponent<TextPaint> {
    static const Color defaultColor;      // CustomColors.hudAccent
    static const double startLift;        // 20: starts this far above `at`
    static const double rise;             // 18: climbs this much while it lives
    static const double lifetimeMs;       // 900, then removes itself
    FloatingTextComponent({required String text, required PositionEntity at, Color color = defaultColor});
    double get alpha;                     // 1 during the first half, then linear to 0
  }
  ```

- [ ] **Step 1: Rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f1-presentation
```

- [ ] **Step 2: Texto "+N", primero el test**

En `test/core/assets/i18n/internationalize_test.dart`, detrás de `testWhenFormattingAmountsThenNamesTheResource`:

```dart
test('testWhenFormattingTheFloatingWoodThenShowsOnlyThePlusAndTheAmount', () {
  // given
  const wood = 8;

  // when
  final floating = Internationalize.forestFloatingWoodGained(wood: wood);

  // then
  expect(floating, '+8');
});
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: FAIL de compilación (`forestFloatingWoodGained` no existe).

`es.json` (fichero caliente): al final del bloque `forest`, detrás de `"retry": "Reintentar"`:

```json
    "retry": "Reintentar",
    "floating": {
      "woodGained": "+{wood}"
    }
```

`Internationalize`, al final de la sección `forest` (detrás de `forestRetry`):

```dart
static String forestFloatingWoodGained({required int wood}) =>
    '$_forest.floating.woodGained'.tr(namedArgs: {'wood': '$wood'});
```

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: PASS.

- [ ] **Step 3: El efecto lleva la madera, primero los tests**

`test/mocks/presentation/features/forest/forest_effect_mock.dart`:

```dart
static TreeFelledEffect get treeFelled => TreeFelledEffect(treeId: 'tree-1', fromX: 180, wood: 6);

static TreeFelledEffect get treeFelledCopy => TreeFelledEffect(treeId: 'tree-1', fromX: 180, wood: 6);

static TreeFelledEffect get pineFelled => TreeFelledEffect(treeId: 'tree-1', fromX: 180, wood: 4);
```

`test/mocks/presentation/features/forest/game/forest_data_mock.dart`, en `treeFelled` (el árbol `tree` da 5):

```dart
effects: const [TreeFelledEffect(treeId: 'tree-1', fromX: 90, wood: 5)],
```

`test/mocks/presentation/features/forest/forest_scenario_mock.dart` (con `import 'package:rpg/core/config/constants/enum/tree_kind.dart';`), detrás de `axeInHandWithTree`:

```dart
static World axeInHandWithPine() => WorldMock.make(
  player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(tools: {ToolKind.axe})),
  trees: [TreeEntityMock.ofKind(TreeKind.pine)],
);
```

`test/layers/presentation/features/forest/models/forest_effect_test.dart`, al final:

```dart
test('testWhenFelledEffectsDifferOnlyInWoodThenTheyAreNotEqual', () {
  // given
  final oak = ForestEffectMock.treeFelled;

  // when
  final isEqual = oak == ForestEffectMock.pineFelled;

  // then
  expect(isEqual, isFalse);
});
```

`test/layers/presentation/features/forest/bloc/forest_bloc_test.dart` (con `import 'package:rpg/core/config/constants/enum/tree_kind.dart';`), detrás del grupo `testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall`, cuyo `contains(ForestEffectMock.treeFelled)` ya comprueba la madera (6):

```dart
blocTest<ForestBloc, ForestState>(
  'testWhenAPineIsFelledThenTheEffectCarriesItsWood',
  build: () {
    // given
    return ForestBlocMock.make(ForestScenarioMock.axeInHandWithPine(), navigationService: navigationService);
  },
  act: (bloc) {
    // when
    effects = ForestBlocMock.collectEffects(bloc);
    bloc
      ..add(const ForestStarted())
      ..add(const ForestMapClicked(position: ForestScenarioMock.treeCanopy, treeId: 'tree-1'));
    ForestBlocMock.tickFor(bloc, 1500 + Rules.chopIntervalMs * TreeEntityMock.ofKind(TreeKind.pine).hitsToFell);
  },
  wait: Duration.zero,
  verify: (bloc) {
    // then
    expect(effects, contains(ForestEffectMock.pineFelled));
    expect(
      ForestBlocMock.shownMessages(navigationService),
      contains(Internationalize.forestMessageWoodGained(wood: 4)),
    );
    expect(bloc.state.data.hud!.resources, [ResourceItemDataMock.wood(4)]);
  },
);
```

Run: `flutter test test/layers/presentation/features/forest/models test/layers/presentation/features/forest/bloc`
Expected: FAIL de compilación (`TreeFelledEffect` no tiene `wood`).

- [ ] **Step 4: `TreeFelledEffect.wood` y `ForestBloc._react`**

`lib/layers/presentation/features/forest/models/forest_effect.dart`:

```dart
final class TreeFelledEffect extends ForestEffect {
  final String treeId;
  final double fromX;
  final int wood;

  const TreeFelledEffect({required this.treeId, required this.fromX, required this.wood});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeFelledEffect && other.treeId == treeId && other.fromX == fromX && other.wood == wood;

  @override
  int get hashCode => Object.hash(TreeFelledEffect, treeId, fromX, wood);
}
```

`ForestBloc._react` (`lib/layers/presentation/features/forest/bloc/forest_bloc.dart`):

```dart
case TreeFelledEventEntity(:final treeId, :final wood):
  _showMessage(Internationalize.forestMessageWoodGained(wood: wood));
  effects.add(TreeFelledEffect(treeId: treeId, fromX: fromX, wood: wood));
```

`ForestSceneComponent._play` todavía no usa `wood`: el patrón `TreeFelledEffect(:final treeId, :final fromX)` sigue compilando.

Run: `flutter test test/layers/presentation/features/forest/models test/layers/presentation/features/forest/bloc`
Expected: PASS.

- [ ] **Step 5: `FloatingTextComponent`, primero el test**

`test/layers/presentation/features/forest/game/components/floating_text_component_test.dart`:

```dart
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/floating_text_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWithFlameGame('testWhenAddedThenShowsTheTextAboveTheTrunkBaseOverEverything', (game) async {
    // given
    final floating = FloatingTextComponent(
      text: Internationalize.forestFloatingWoodGained(wood: 8),
      at: const PositionEntity(x: 100, y: 120),
    );

    // when
    await game.ensureAdd(floating);

    // then
    expect(floating.text, Internationalize.forestFloatingWoodGained(wood: 8));
    expect(floating.position, Vector2(100, 100));
    expect(floating.anchor, Anchor.bottomCenter);
    expect(floating.priority, RenderDepth.overlay);
    expect(floating.alpha, 1);
  });

  testWithFlameGame('testWhenTimePassesThenRisesFadesAndRemovesItself', (game) async {
    // given
    final floating = FloatingTextComponent(
      text: Internationalize.forestFloatingWoodGained(wood: 4),
      at: const PositionEntity(x: 100, y: 120),
    );
    await game.ensureAdd(floating);

    // when
    game.update(0.45);
    final halfwayY = floating.position.y;
    final halfwayAlpha = floating.alpha;
    game.update(0.225);
    final fadingAlpha = floating.alpha;
    game.update(0.3);
    await game.ready();

    // then
    expect(halfwayY, closeTo(87.27, 0.01));
    expect(halfwayAlpha, closeTo(1, 0.001));
    expect(fadingAlpha, closeTo(0.5, 0.001));
    expect(floating.isMounted, isFalse);
  });
}
```

`87.27` = 120 − 20 − 18 · sin(π/4): a mitad de vida ha subido el `sineOut(0.5)` de los 18 px.

Run: `flutter test test/layers/presentation/features/forest/game/components/floating_text_component_test.dart`
Expected: FAIL de compilación (`floating_text_component.dart` no existe).

- [ ] **Step 6: Implementar `FloatingTextComponent`**

`lib/layers/presentation/features/forest/game/components/floating_text_component.dart`:

```dart
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../theme/colors/custom_colors.dart';
import '../render/easing.dart';
import '../render/render_depth.dart';

class FloatingTextComponent extends TextComponent<TextPaint> {
  static const Color defaultColor = CustomColors.hudAccent;
  static const Color outlineColor = CustomColors.black;
  static const double fontSize = 9;
  static const double startLift = 20;
  static const double rise = 18;
  static const double lifetimeMs = 900;
  static const double fadeStart = 0.5;

  final Color color;
  final double _startY;
  double _elapsedMs = 0;

  FloatingTextComponent({required String text, required PositionEntity at, this.color = defaultColor})
    : _startY = at.y - startLift,
      super(
        text: text,
        textRenderer: TextPaint(style: _style(color, 1)),
        position: Vector2(at.x, at.y - startLift),
        anchor: Anchor.bottomCenter,
        priority: RenderDepth.overlay,
      );

  double get alpha {
    final progress = _progress;
    if (progress <= fadeStart) return 1;
    return 1 - (progress - fadeStart) / (1 - fadeStart);
  }

  double get _progress => math.min(1.0, _elapsedMs / lifetimeMs);

  static TextStyle _style(Color color, double alpha) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color.withValues(alpha: alpha),
    shadows: [
      Shadow(
        color: outlineColor.withValues(alpha: alpha),
        offset: const Offset(0.5, 0.5),
      ),
    ],
  );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedMs += dt * 1000;
    position.y = _startY - rise * Easing.sineOut(_progress);
    textRenderer = TextPaint(style: _style(color, alpha));
    if (_progress >= 1) removeFromParent();
  }
}
```

Run: `flutter test test/layers/presentation/features/forest/game/components/floating_text_component_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: La escena muestra el "+N", primero el test**

`test/layers/presentation/features/forest/game/forest_scene_component_test.dart`:
- nuevos imports: `package:rpg/core/assets/i18n/internationalize.dart`, `package:rpg/layers/presentation/features/forest/game/components/floating_text_component.dart` y `'../../../../../helpers/spanish_translations.dart'`;
- al principio de `main()`: `setUpAll(loadSpanishTranslations);`;
- detrás de `testWhenATreeIsFelledThenFallsLeavesAStumpAndIsNoLongerTappable`:

```dart
testWithFlameGame('testWhenATreeIsFelledThenTheWoodGainedFloatsOverItsTrunk', (game) async {
  // given
  final scene = await _mountedScene(game);

  // when
  scene.show(ForestDataMock.treeFelled);
  await game.ready();

  // then
  final floating = scene.children.whereType<FloatingTextComponent>().single;
  expect(floating.text, Internationalize.forestFloatingWoodGained(wood: 5));
  expect(floating.position, Vector2(100, 100));
});
```

Run: `flutter test test/layers/presentation/features/forest/game/forest_scene_component_test.dart`
Expected: FAIL (`Bad state: No element`: la escena todavía no añade el texto).

- [ ] **Step 8: `ForestSceneComponent._onTreeFelled` añade el texto**

`lib/layers/presentation/features/forest/game/forest_scene_component.dart`:
- nuevos imports: `'../../../../../core/assets/i18n/internationalize.dart'` y `'components/floating_text_component.dart'`;
- en `_play`:

```dart
case TreeFelledEffect(:final treeId, :final fromX, :final wood):
  _onTreeFelled(treeId, fromX, wood);
```

- `_onTreeFelled`:

```dart
void _onTreeFelled(String treeId, double fromX, int wood) {
  final tree = _trees.remove(treeId);
  if (tree == null) return;
  tree.fell(fromX);
  _addClutter(SpriteNames.stump, tree.base, tree.base.y - 1);
  add(
    FloatingTextComponent(
      text: Internationalize.forestFloatingWoodGained(wood: wood),
      at: tree.base,
    ),
  );
}
```

Run: `flutter test test/layers/presentation/features/forest/game`
Expected: PASS.

- [ ] **Step 9: `CLAUDE.md`**

En *Architecture*, en `features/forest/game/`, la lista de `components/` "(ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player)" pasa a "(ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player, `FloatingTextComponent` for rising texts such as the "+N" of a felled tree)".

Se añade con un `git add CLAUDE.md` aparte.

- [ ] **Step 10: Verificación completa**

```bash
dart format --line-length 120 lib/layers/presentation/features/forest/game/components/floating_text_component.dart lib/layers/presentation/features/forest/models/forest_effect.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart lib/layers/presentation/features/forest/game/forest_scene_component.dart lib/core/assets/i18n/internationalize.dart test/layers/presentation/features/forest/game/components/floating_text_component_test.dart test/layers/presentation/features/forest/game/forest_scene_component_test.dart test/layers/presentation/features/forest/models/forest_effect_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/core/assets/i18n/internationalize_test.dart test/mocks/presentation/features/forest/forest_effect_mock.dart test/mocks/presentation/features/forest/game/forest_data_mock.dart test/mocks/presentation/features/forest/forest_scenario_mock.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: todo en verde; `build_runner` no cambia nada; `flutter analyze` termina en `No issues found!`.

Prueba manual en Chrome (`flutter run -d chrome`), en el emulador (`flutter run -d emulator-5554`) y en el simulador (`flutter run -d "iPhone 17"`):
- recoge el hacha y tala un roble: 7 golpes; al caer sube un "+8" dorado sobre el tocón, se desvanece en menos de un segundo y sale el *snackbar* "+8 de madera";
- tala un pino: 3 golpes y "+4";
- el texto se dibuja por encima de los árboles cercanos y no tapa el HUD;
- la misión de 15 de madera se completa.

- [ ] **Step 11: Commit**

```bash
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-X]: Float the wood gained over each felled tree"
```

Después, `/cerrar-tarea`. Con esto se cierra el milestone F1.
