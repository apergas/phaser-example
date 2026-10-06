# F0 · Generalizar recursos, herramientas y edificios — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

**Goal:** Que añadir un recurso, una herramienta o un edificio sea casi sólo añadir datos. Para ello se quitan las suposiciones "madera / hacha / casa" del dominio, del HUD y del dibujo, **sin cambiar la jugabilidad**.

**Architecture:**
- Nuevo enum `Resource` en `core`. `InventoryEntity` guarda un `Map<Resource, int>`.
- `BlueprintEntity` tiene un `cost: Map<Resource, int>`; `BuildOptionEntity` dice qué falta (`missing`).
- `PlayerStatusEntity` expone el `InventoryEntity` entero en lugar de `wood` / `hasAxe`.
- `HudData` expone listas genéricas de recursos y herramientas; `ResourceBar` pinta cualquiera de ellas con su icono de `CustomIcons`.
- `SpriteNames` elige el frame de cada edificio e ítem; `RenderConstants.buildingFrontOffset` su desplazamiento de dibujo.
- Nadie fuera de `SpriteNames`, `RenderConstants`, `CustomIcons` e `Internationalize` escribe a mano `'house'`, `'axe-pickup'`, `wood` ni `hasAxe`.
- Dos tareas secuenciales. Cada una deja `develop` en verde:
  - T0.1 cambia el dominio y adapta lo mínimo de `ForestBloc` para que todo compile;
  - T0.2 generaliza el HUD y el dibujo.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, Flame, `easy_localization`, `flutter_test` + `mockito` + `bloc_test` + `flame_test`.

**Cómo probar la fase entera:** en Chrome, en el emulador Android y en el simulador iOS el juego se comporta como hoy:
- el HUD muestra "Madera N" y el hacha (atenuada hasta recogerla);
- la casa cuesta 15;
- la previsualización y el edificio se dibujan igual que ahora; el polvo sale del muro frontal.

Sólo cambian tres textos:
- lo que falta en el menú *Construir*: "Faltan 5" pasa a "Faltan 5 de madera";
- el mensaje si faltan recursos: "No tienes madera suficiente." pasa a "No tienes recursos suficientes.";
- el mensaje al terminar un edificio: "¡Casa construida!" pasa a "Construcción terminada: Casa", para que no dé por hecho un nombre femenino.

## Reparto

| Tarea | Capa | Depende de | Paralelizable |
|---|---|---|---|
| T0.1 Dominio: recursos y costes | domain + data de tests + mínimo de `ForestBloc` | — | No |
| T0.2 Presentación: HUD de recursos y sprites por tipo | presentation | T0.1 | No |

---

### Task T0.1: Dominio: recursos, costes y estado del jugador

**Files:**
- Create:
  - `lib/core/config/constants/enum/resource.dart`
- Modify:
  - `lib/core/config/constants/enum/construction_rejection.dart`
  - `lib/layers/domain/entities/player/inventory_entity.dart`
  - `lib/layers/domain/entities/building/blueprint_entity.dart`
  - `lib/layers/domain/entities/game/build_option_entity.dart`
  - `lib/layers/domain/entities/game/player_status_entity.dart`
  - `lib/layers/domain/world/extensions/inventory_rules.dart`
  - `lib/layers/domain/world/construction.dart`
  - `lib/layers/domain/world/woodcutting.dart`
  - `lib/layers/domain/rules/blueprints.dart`
  - `lib/layers/domain/quests/quests.dart`
  - `lib/layers/domain/use-cases/game/get_player_status_use_case.dart`
  - `lib/layers/domain/use-cases/game/get_build_options_use_case.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - `lib/core/assets/i18n/internationalize.dart`
  - `lib/core/assets/i18n/translations/es.json`
- Delete:
  - `lib/layers/domain/world/extensions/blueprint_rules.dart` y `test/layers/domain/world/extensions/blueprint_rules_test.dart` (la asequibilidad pasa a `BuildOptionEntity.isAffordable`).
- Test (en `test/`):
  - `layers/domain/world/extensions/inventory_rules_test.dart`: se reescribe.
  - `layers/domain/entities/player/inventory_entity_test.dart`
  - `layers/domain/entities/building/blueprint_entity_test.dart`
  - `layers/domain/entities/game/build_option_entity_test.dart`
  - `layers/domain/entities/game/construction_result_entity_test.dart`
  - `layers/domain/entities/game/player_status_entity_test.dart`
  - `layers/domain/rules/blueprints_test.dart`
  - `layers/domain/quests/quest_log_test.dart`
  - `layers/domain/world/world_chopping_test.dart`
  - `layers/domain/world/world_construction_test.dart`
  - `layers/domain/use-cases/game/get_build_options_use_case_test.dart`
  - `layers/domain/use-cases/game/get_player_status_use_case_test.dart`
  - `layers/domain/use-cases/game/construct_building_use_case_test.dart`
  - `layers/domain/use-cases/game/game_flow_test.dart`
  - `layers/presentation/features/forest/bloc/forest_bloc_test.dart`
  - `core/assets/i18n/internationalize_test.dart`
  - Mocks: `mocks/domain/entities/player/inventory_entity_mock.dart`, `mocks/domain/entities/player/player_entity_mock.dart`, `mocks/domain/entities/building/blueprint_entity_mock.dart`, `mocks/domain/entities/game/build_option_entity_mock.dart`, `mocks/domain/entities/game/player_status_entity_mock.dart`, `mocks/domain/entities/game/construction_result_entity_mock.dart`, `mocks/domain/game/game_scenario_mock.dart`, `mocks/presentation/features/forest/forest_scenario_mock.dart`, `mocks/presentation/features/forest/build_item_data_mock.dart`.

**Interfaces:**
- Consumes: nada nuevo.
- Produces (lo que usan T0.2 y las fases siguientes):
  ```dart
  // lib/core/config/constants/enum/resource.dart
  enum Resource { wood }

  // lib/core/config/constants/enum/construction_rejection.dart
  enum ConstructionRejection { notEnoughResources, blocked }

  // lib/layers/domain/entities/player/inventory_entity.dart
  class InventoryEntity {
    final Map<Resource, int> resources;   // never holds zero amounts
    final Set<ToolKind> tools;
    const InventoryEntity({this.resources = const {}, this.tools = const {}});
  }

  // lib/layers/domain/world/extensions/inventory_rules.dart
  extension InventoryRules on InventoryEntity {
    int amount(Resource resource);
    InventoryEntity add(Resource resource, int quantity);
    Map<Resource, int> missing(Map<Resource, int> cost);   // only what is still short, > 0
    InventoryEntity? spend(Map<Resource, int> cost);       // null when something is missing
    InventoryEntity addTool(ToolKind tool);
    bool hasTool(ToolKind tool);
  }

  // lib/layers/domain/entities/building/blueprint_entity.dart
  BlueprintEntity({required BlueprintId id, required Map<Resource, int> cost, required int hitsToBuild, required double footprintRadius})

  // lib/layers/domain/entities/game/*
  BuildOptionEntity({required BlueprintId blueprint, required Map<Resource, int> cost, required Map<Resource, int> missing})
    bool get isAffordable;   // missing.isEmpty
  PlayerStatusEntity({position, activity, target, swingProgress, required InventoryEntity inventory})

  // lib/core/assets/i18n/internationalize.dart
  static String forestAmount({required Resource resource, required int amount});   // "15 de madera"
  static String forestMissing({required String amounts});                         // "Faltan 15 de madera"
  static String get forestMessageNotEnoughResources;                              // "No tienes recursos suficientes."
  ```

- [x] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f0-domain
```

- [x] **Step 2: Escribir el test de `InventoryRules`, que debe fallar**

Sustituir el contenido de `test/layers/domain/world/extensions/inventory_rules_test.dart` por:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

void main() {
  test('testWhenAddingResourcesThenAmountAccumulates', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final updated = inventory.add(Resource.wood, 4).add(Resource.wood, 2);

    // then
    expect(inventory.amount(Resource.wood), 0);
    expect(updated.amount(Resource.wood), 6);
  });

  test('testWhenSpendingAnAffordableCostThenReturnsInventoryWithTheRest', () {
    // given
    const inventory = InventoryEntityMock.withWood;

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.fourWood);

    // then
    expect(afterSpending?.amount(Resource.wood), 2);
  });

  test('testWhenSpendingMoreThanStoredThenReturnsNullAndReportsWhatIsMissing', () {
    // given
    final inventory = InventoryEntityMock.make(wood: 3);

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.fiveWood);
    final missing = inventory.missing(InventoryEntityMock.fiveWood);

    // then
    expect(afterSpending, isNull);
    expect(missing, InventoryEntityMock.twoWood);
    expect(inventory.amount(Resource.wood), 3);
  });

  test('testWhenNothingIsMissingThenMissingIsEmpty', () {
    // given
    final inventory = InventoryEntityMock.make(wood: 15);

    // when
    final missing = inventory.missing(InventoryEntityMock.fifteenWood);

    // then
    expect(missing, isEmpty);
  });

  test('testWhenSpendingEverythingThenTheResourceDisappearsFromTheMap', () {
    // given
    final inventory = InventoryEntityMock.make(wood: 15);

    // when
    final afterSpending = inventory.spend(InventoryEntityMock.fifteenWood);

    // then
    expect(afterSpending, InventoryEntityMock.mock);
  });

  test('testWhenAddingToolThenInventoryHasIt', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    final withAxe = inventory.addTool(ToolKind.axe);

    // then
    expect(inventory.hasTool(ToolKind.axe), isFalse);
    expect(withAxe.hasTool(ToolKind.axe), isTrue);
  });

  test('testWhenAddingANegativeAmountThenFails', () {
    // given
    const inventory = InventoryEntityMock.mock;

    // when
    Object act() => inventory.add(Resource.wood, -1);

    // then
    expect(act, throwsArgumentError);
  });
}
```

Y en `test/mocks/domain/entities/player/inventory_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';

abstract final class InventoryEntityMock {
  static const InventoryEntity mock = InventoryEntity();

  static const InventoryEntity withWood = InventoryEntity(resources: {Resource.wood: 6});

  static const InventoryEntity withAxe = InventoryEntity(tools: {ToolKind.axe});

  static const Map<Resource, int> twoWood = {Resource.wood: 2};

  static const Map<Resource, int> fourWood = {Resource.wood: 4};

  static const Map<Resource, int> fiveWood = {Resource.wood: 5};

  static const Map<Resource, int> fifteenWood = {Resource.wood: 15};

  static InventoryEntity make({int wood = 0, Set<ToolKind> tools = const {}}) =>
      InventoryEntity(resources: {if (wood > 0) Resource.wood: wood}, tools: tools);
}
```

- [x] **Step 3: Comprobar que falla**

Run: `flutter test test/layers/domain/world/extensions/inventory_rules_test.dart`
Expected: FAIL de compilación (`Resource` no existe; `add`, `amount`, `spend`, `missing` no están definidos).

- [x] **Step 4: Implementar `Resource`, `InventoryEntity` e `InventoryRules`**

`lib/core/config/constants/enum/resource.dart`:

```dart
enum Resource { wood }
```

`lib/layers/domain/entities/player/inventory_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final Map<Resource, int> resources;
  final Set<ToolKind> tools;

  const InventoryEntity({this.resources = const {}, this.tools = const {}});

  InventoryEntity copyWith({Map<Resource, int>? resources, Set<ToolKind>? tools}) {
    return InventoryEntity(resources: resources ?? this.resources, tools: tools ?? this.tools);
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity &&
      const MapEquality<Resource, int>().equals(other.resources, resources) &&
      const SetEquality<ToolKind>().equals(other.tools, tools);

  @override
  int get hashCode =>
      Object.hash(const MapEquality<Resource, int>().hash(resources), const SetEquality<ToolKind>().hash(tools));
}
```

`lib/layers/domain/world/extensions/inventory_rules.dart`. El mapa nunca guarda cantidades a cero, para que dos inventarios con lo mismo sean iguales:

```dart
import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/player/inventory_entity.dart';

extension InventoryRules on InventoryEntity {
  int amount(Resource resource) => resources[resource] ?? 0;

  InventoryEntity add(Resource resource, int quantity) {
    if (quantity < 0) throw ArgumentError.value(quantity, 'quantity', 'Cannot add a negative amount of ${resource.name}');
    if (quantity == 0) return this;
    return copyWith(resources: {...resources, resource: amount(resource) + quantity});
  }

  Map<Resource, int> missing(Map<Resource, int> cost) => {
    for (final MapEntry(key: resource, value: quantity) in cost.entries)
      if (quantity > amount(resource)) resource: quantity - amount(resource),
  };

  InventoryEntity? spend(Map<Resource, int> cost) {
    if (missing(cost).isNotEmpty) return null;
    final remaining = {
      ...resources,
      for (final MapEntry(key: resource, value: quantity) in cost.entries) resource: amount(resource) - quantity,
    }..removeWhere((_, quantity) => quantity == 0);
    return copyWith(resources: remaining);
  }

  InventoryEntity addTool(ToolKind tool) => copyWith(tools: {...tools, tool});

  bool hasTool(ToolKind tool) => tools.contains(tool);
}
```

Run: `flutter test test/layers/domain/world/extensions/inventory_rules_test.dart`
Expected: PASS.

- [x] **Step 5: `BlueprintEntity`, `Blueprints`, `ConstructionRejection`, `Construction`, `Woodcutting` y `Quests`**

`lib/layers/domain/entities/building/blueprint_entity.dart`: `woodCost` pasa a `cost`.

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/resource.dart';

class BlueprintEntity {
  final BlueprintId id;
  final Map<Resource, int> cost;
  final int hitsToBuild;
  final double footprintRadius;

  const BlueprintEntity({
    required this.id,
    required this.cost,
    required this.hitsToBuild,
    required this.footprintRadius,
  });

  @override
  bool operator ==(Object other) =>
      other is BlueprintEntity &&
      other.id == id &&
      const MapEquality<Resource, int>().equals(other.cost, cost) &&
      other.hitsToBuild == hitsToBuild &&
      other.footprintRadius == footprintRadius;

  @override
  int get hashCode => Object.hash(id, const MapEquality<Resource, int>().hash(cost), hitsToBuild, footprintRadius);
}
```

`lib/layers/domain/rules/blueprints.dart`:

```dart
static const BlueprintEntity house = BlueprintEntity(
  id: BlueprintId.house,
  cost: {Resource.wood: 15},
  hitsToBuild: 8,
  footprintRadius: 40,
);
```

`lib/core/config/constants/enum/construction_rejection.dart`:

```dart
enum ConstructionRejection { notEnoughResources, blocked }
```

`Construction.place` (`lib/layers/domain/world/construction.dart`):

```dart
final paid = state.player.inventory.spend(blueprint.cost);
if (paid == null) return const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources);
```

`Woodcutting.impact` (`lib/layers/domain/world/woodcutting.dart`):

```dart
state.player = state.player.withInventory(state.player.inventory.add(Resource.wood, tree.woodYield));
```

`Quests.all` (`lib/layers/domain/quests/quests.dart`):

```dart
_MeasuredQuest(id: QuestId.gatherWood, target: 15, measure: (world) => world.player.inventory.amount(Resource.wood)),
```

Se añaden los `import '…/core/config/constants/enum/resource.dart';` necesarios.

Se borran `lib/layers/domain/world/extensions/blueprint_rules.dart` y su test.

- [x] **Step 6: `BuildOptionEntity`, `PlayerStatusEntity` y sus casos de uso**

`lib/layers/domain/entities/game/build_option_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/resource.dart';

class BuildOptionEntity {
  final BlueprintId blueprint;
  final Map<Resource, int> cost;
  final Map<Resource, int> missing;

  const BuildOptionEntity({required this.blueprint, required this.cost, required this.missing});

  bool get isAffordable => missing.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is BuildOptionEntity &&
      other.blueprint == blueprint &&
      const MapEquality<Resource, int>().equals(other.cost, cost) &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(
    blueprint,
    const MapEquality<Resource, int>().hash(cost),
    const MapEquality<Resource, int>().hash(missing),
  );
}
```

`lib/layers/domain/entities/game/player_status_entity.dart`: `wood` y `hasAxe` se sustituyen por `final InventoryEntity inventory;` (constructor `required this.inventory`, en `==` y en `hashCode`).

`GetPlayerStatusUseCase.call()`:

```dart
return PlayerStatusEntity(
  position: player.position,
  activity: player.activity.playerActivity,
  target: world.playerTarget,
  swingProgress: world.workProgress,
  inventory: player.inventory,
);
```

Se quitan los imports de `tool_kind.dart` e `inventory_rules.dart` si quedan sin uso.

`GetBuildOptionsUseCase.call()`:

```dart
List<BuildOptionEntity> call() {
  final inventory = _sessionRepository.current().world.player.inventory;
  return Blueprints.all
      .map(
        (blueprint) => BuildOptionEntity(
          blueprint: blueprint.id,
          cost: blueprint.cost,
          missing: inventory.missing(blueprint.cost),
        ),
      )
      .toList();
}
```

- [x] **Step 7: Adaptar mocks y tests de dominio a la API nueva**

Patrón de sustitución en todos los ficheros de test y mocks de la lista *Files* (se añade `import 'package:rpg/core/config/constants/enum/resource.dart';` donde haga falta):

| Antes | Después |
|---|---|
| `inventory.addWood(n)` | `inventory.add(Resource.wood, n)` |
| `inventory.spendWood(n)!` | `inventory.spend({Resource.wood: n})!` |
| `inventory.wood` | `inventory.amount(Resource.wood)` |
| `InventoryEntity(wood: n)` | `InventoryEntity(resources: {Resource.wood: n})` |
| `InventoryEntity(wood: n, tools: {...})` | `InventoryEntity(resources: {Resource.wood: n}, tools: {...})` |
| `BlueprintEntity(..., woodCost: n, ...)` | `BlueprintEntity(..., cost: {Resource.wood: n}, ...)` |
| `BlueprintEntityMock.make(woodCost: n)` | `BlueprintEntityMock.make(cost: {Resource.wood: n})` |
| `ConstructionRejection.notEnoughWood` | `ConstructionRejection.notEnoughResources` |
| `ConstructionResultEntityMock.notEnoughWood` | `ConstructionResultEntityMock.notEnoughResources` |
| `status.wood` / `getPlayerStatus().wood` | `status.inventory.amount(Resource.wood)` |
| `status.hasAxe` | `status.inventory.hasTool(ToolKind.axe)` |
| `PlayerStatusEntity(..., wood: 0, hasAxe: false)` | `PlayerStatusEntity(..., inventory: InventoryEntityMock.mock)` |

`test/mocks/domain/entities/game/build_option_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/game/build_option_entity.dart';

abstract final class BuildOptionEntityMock {
  static const BuildOptionEntity mock = BuildOptionEntity(
    blueprint: BlueprintId.house,
    cost: {Resource.wood: 15},
    missing: {},
  );

  static const BuildOptionEntity unaffordable = BuildOptionEntity(
    blueprint: BlueprintId.house,
    cost: {Resource.wood: 15},
    missing: {Resource.wood: 5},
  );

  static BuildOptionEntity make({Map<Resource, int> missing = const {}}) =>
      BuildOptionEntity(blueprint: BlueprintId.house, cost: const {Resource.wood: 15}, missing: missing);
}
```

`unaffordable` vale para `GameScenarioMock.tenWood()` (faltan 5). Si `build_option_entity_test.dart` usaba `make(isAffordable: false)`, pasa a `make(missing: InventoryEntityMock.fiveWood)` y comprueba `isAffordable`:

```dart
test('testWhenSomethingIsMissingThenIsNotAffordable', () {
  // given
  final option = BuildOptionEntityMock.make(missing: InventoryEntityMock.fiveWood);

  // when
  final isAffordable = option.isAffordable;

  // then
  expect(isAffordable, isFalse);
  expect(BuildOptionEntityMock.mock.isAffordable, isTrue);
});
```

Renombrados:
- `testWhenWoodIsNotEnoughThenHouseIsNotAffordable` → `testWhenResourcesAreNotEnoughThenHouseIsNotAffordable` (`get_build_options_use_case_test.dart`).
- En `world_construction_test.dart` y `construct_building_use_case_test.dart`, los tests que esperan el rechazo por madera pasan a llamarse `…WithoutEnoughResources…`.

Run: `flutter test test/layers/domain test/layers/data test/core`
Expected: PASS. La presentación todavía no compila (`ForestBloc` usa `status.wood`); lo resuelven los pasos 8 y 9.

- [x] **Step 8: Textos de coste y de rechazo**

`es.json`, en `forest`:
- `hud.cost` se borra.
- `hud.missing` pasa a `"Faltan {amounts}"`.
- Nuevo bloque `"amount": { "wood": "{amount} de madera" }`.
- `message.notEnoughWood` se renombra a `"notEnoughResources": "No tienes recursos suficientes."`.
- `message.buildingCompleted` pasa a `"Construcción terminada: {name}"`.

`Internationalize`:

```dart
static String forestAmount({required Resource resource, required int amount}) => switch (resource) {
  Resource.wood => '$_forest.amount.wood'.tr(namedArgs: {'amount': '$amount'}),
};
static String forestMissing({required String amounts}) =>
    '$_forest.hud.missing'.tr(namedArgs: {'amounts': amounts});
static String get forestMessageNotEnoughResources => '$_forest.message.notEnoughResources'.tr();
```

Se borran `forestCost` y `forestMessageNotEnoughWood`.

`test/core/assets/i18n/internationalize_test.dart`:
- `testWhenFormattingCostsThenInsertsTheWood` pasa a `testWhenFormattingAmountsThenNamesTheResource`:

```dart
test('testWhenFormattingAmountsThenNamesTheResource', () {
  // given
  const amount = 15;

  // when
  final cost = Internationalize.forestAmount(resource: Resource.wood, amount: amount);
  final missing = Internationalize.forestMissing(amounts: Internationalize.forestAmount(resource: Resource.wood, amount: 5));
  final gained = Internationalize.forestMessageWoodGained(wood: 6);

  // then
  expect(cost, '15 de madera');
  expect(missing, 'Faltan 5 de madera');
  expect(gained, '+6 de madera');
});
```

- En `testWhenFormattingMessagesWithNamesThenInsertsThem`: `expect(completed, 'Construcción terminada: Casa');`.
- En la lista de `testWhenReadingEveryForestTextThenNoneFallsBackToItsKey`, `forestMessageNotEnoughWood` pasa a `forestMessageNotEnoughResources`.

- [x] **Step 9: Adaptar `ForestBloc` (sin cambiar todavía `HudData`)**

En `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`:
- `_openPlacement` y la rama de rechazo de `_place` usan `Internationalize.forestMessageNotEnoughResources`; el `case` pasa a `ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources)`.
- En `_playerRenderData`, `status.hasAxe` pasa a `status.inventory.hasTool(ToolKind.axe)` (import de `domain/world/extensions/inventory_rules.dart`).
- `_hudData` sigue rellenando `wood` y `hasAxe` de `HudData`, ahora desde el inventario; los textos del menú salen del coste genérico:

```dart
HudData _hudData(PlayerStatusEntity status, List<QuestProgressEntity> quests) {
  return HudData(
    wood: status.inventory.amount(Resource.wood),
    hasAxe: status.inventory.hasTool(ToolKind.axe),
    questBadge: '${quests.where((quest) => quest.isCompleted).length}/${quests.length}',
    quests: [for (final quest in quests) _questItem(quest)],
    buildItems: [for (final option in _getBuildOptionsUseCase()) _buildItem(option)],
    isBuildLocked: _placement != null,
  );
}

BuildItemData _buildItem(BuildOptionEntity option) {
  return BuildItemData(
    blueprint: option.blueprint,
    name: Internationalize.forestBlueprint(id: option.blueprint),
    costText: _amounts(option.cost),
    missingText: option.isAffordable ? null : Internationalize.forestMissing(amounts: _amounts(option.missing)),
    isEnabled: option.isAffordable,
  );
}

String _amounts(Map<Resource, int> amounts) {
  return amounts.entries
      .sortedBy<num>((entry) => entry.key.index)
      .map((entry) => Internationalize.forestAmount(resource: entry.key, amount: entry.value))
      .join(', ');
}
```

`test/mocks/presentation/features/forest/build_item_data_mock.dart`:

```dart
costText: Internationalize.forestAmount(resource: Resource.wood, amount: 15),
// makeUnaffordable:
missingText: Internationalize.forestMissing(
  amounts: Internationalize.forestAmount(resource: Resource.wood, amount: missingWood),
),
```

En `forest_bloc_test.dart`:
- `testWhenWoodIsNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace` pasa a `testWhenResourcesAreNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace` y espera `Internationalize.forestMessageNotEnoughResources`.

Run: `flutter test`
Expected: PASS (todos, incluido `architecture_test.dart`).

- [x] **Step 10: Verificación completa**

```bash
dart format --line-length 120 <ficheros escritos en esta tarea>
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: todo en verde; `build_runner` no cambia nada (no hay inyectables ni mocks nuevos).

- [x] **Step 11: Commit y PR**

```bash
git add lib test
git commit -m "[PROJECT-X]: Generalize inventory and building costs over resources"
```

Después, `/cerrar-tarea`: abre el PR con `Closes #<issue T0.1>`.

**Cómo probarlo a mano:** `flutter run -d chrome`. El juego funciona igual que antes, salvo los textos "Faltan 5 de madera", "No tienes recursos suficientes." y "Construcción terminada: Casa".

---

### Task T0.2: Presentación: HUD de recursos y sprites por tipo

**Files:**
- Create:
  - `lib/layers/presentation/features/forest/models/resource_item_data.dart`
  - `lib/layers/presentation/features/forest/models/tool_item_data.dart`
  - `test/mocks/presentation/features/forest/resource_item_data_mock.dart`
  - `test/mocks/presentation/features/forest/tool_item_data_mock.dart`
  - `test/layers/presentation/features/forest/models/resource_item_data_test.dart`
  - `test/layers/presentation/features/forest/models/tool_item_data_test.dart`
- Modify:
  - `lib/layers/presentation/features/forest/models/hud_data.dart`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - `lib/layers/presentation/features/forest/widgets/resource_bar.dart`
  - `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`
  - `lib/layers/presentation/theme/images/custom_icons.dart`
  - `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`
  - `lib/layers/presentation/features/forest/game/render/render_constants.dart`
  - `lib/layers/presentation/features/forest/game/components/building_component.dart`
  - `lib/layers/presentation/features/forest/game/components/ground_item_component.dart`
  - `lib/layers/presentation/features/forest/game/components/placement_ghost_component.dart`
  - `lib/layers/presentation/features/forest/game/forest_scene_component.dart`
  - `lib/layers/presentation/features/forest/game/particles/particle_bursts.dart`
  - `lib/core/assets/i18n/internationalize.dart` y `lib/core/assets/i18n/translations/es.json`
  - `CLAUDE.md` (constante del desplazamiento de los edificios)
- Test (en `test/`):
  - `layers/presentation/features/forest/widgets/resource_bar_test.dart`: se reescribe.
  - `layers/presentation/features/forest/widgets/hud_overlay_test.dart`
  - `layers/presentation/features/forest/models/hud_data_test.dart`
  - `layers/presentation/features/forest/bloc/forest_bloc_test.dart`
  - `layers/presentation/features/forest/game/atlas/sprite_names_test.dart`
  - `layers/presentation/features/forest/game/atlas/lpc_atlas_test.dart` y `lpc_assets_test.dart`
  - `layers/presentation/features/forest/game/components/building_component_test.dart`, `ground_item_component_test.dart`, `placement_ghost_component_test.dart`
  - `layers/presentation/features/forest/game/forest_scene_component_test.dart`
  - `layers/presentation/features/forest/game/particles/particle_bursts_test.dart`
  - `core/assets/i18n/internationalize_test.dart`
  - Mocks: `mocks/presentation/features/forest/hud_data_mock.dart`, `mocks/presentation/features/forest/game/lpc_assets_mock.dart`, `mocks/presentation/features/forest/game/particle_mock.dart`.

**Interfaces:**
- Consumes (de T0.1): `Resource`, `InventoryRules.amount` / `hasTool`, `PlayerStatusEntity.inventory`.
- Produces (lo que usan las fases siguientes):
  ```dart
  // models
  ResourceItemData({required Resource resource, required String name, required int amount})
  ToolItemData({required ToolKind tool, required String name, required bool isOwned})
  HudData({required List<ResourceItemData> resources, required List<ToolItemData> tools, questBadge, quests, buildItems, isBuildLocked})

  // Internationalize
  static String forestResource({required Resource resource});   // "Madera"
  static String forestTool({required ToolKind tool});            // "Hacha"

  // CustomIcons
  static String resource(Resource resource);   // wood.svg
  static String tool(ToolKind tool);           // axe.svg

  // ResourceBar
  ResourceBar({required List<ResourceItemData> resources, required List<ToolItemData> tools, bool showLabels = true})
  static Key toolKey(ToolKind tool);           // Key('resourceBarTool-axe')

  // game/atlas/sprite_names.dart
  static String building(BlueprintId id);      // house -> 'house'
  static String item(ToolKind kind);           // axe -> 'axe-pickup'

  // game/render/render_constants.dart
  static double buildingFrontOffset(BlueprintId id);   // house -> 24

  // BuildingComponent
  PositionEntity get front;                    // footprint centre + buildingFrontOffset

  // PlacementGhostComponent
  PlacementGhostComponent({required LpcAssets assets, required BlueprintId blueprint})

  // ParticleBursts
  static List<Particle> dust({required PositionEntity front, required math.Random random});
  static double dustSortY(PositionEntity front);
  ```

Una fase que añade un recurso o una herramienta sólo añade: el valor del enum, su caso en `Internationalize.forestResource`/`forestTool` (y `forestAmount`), su texto en `es.json`, su SVG y su caso en `CustomIcons`. Un edificio nuevo añade su caso en `SpriteNames.building` y `RenderConstants.buildingFrontOffset`.

- [x] **Step 1: Rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f0-presentation
```

- [x] **Step 2: Test de `SpriteNames` y del desplazamiento, que debe fallar**

En `test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart` se añade:

```dart
test('testWhenNamingBuildingsAndItemsThenFollowsTheAtlasFrameNames', () {
  // given
  const house = BlueprintId.house;
  const axe = ToolKind.axe;

  // when
  final buildingName = SpriteNames.building(house);
  final frontOffset = RenderConstants.buildingFrontOffset(house);
  final itemName = SpriteNames.item(axe);

  // then
  expect(buildingName, 'house');
  expect(frontOffset, 24);
  expect(itemName, 'axe-pickup');
});
```

Run: `flutter test test/layers/presentation/features/forest/game/atlas/sprite_names_test.dart`
Expected: FAIL de compilación (`building`, `item` y `buildingFrontOffset` no existen).

- [x] **Step 3: `SpriteNames` y `RenderConstants`**

`lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`:

```dart
import '../../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../../core/utils/kebab_case.dart';

abstract final class SpriteNames {
  static const String stump = 'stump';

  static String tree(TreeKind kind) => 'tree-${kind.name.toKebabCase()}';

  static String decoration(DecorationKind kind) => 'decor-${kind.name.toKebabCase()}';

  static String building(BlueprintId id) => switch (id) {
    BlueprintId.house => 'house',
  };

  static String item(ToolKind kind) => switch (kind) {
    ToolKind.axe => 'axe-pickup',
  };
}
```

`lib/layers/presentation/features/forest/game/render/render_constants.dart`: `static const double houseFrontOffset = 24;` se sustituye por

```dart
static double buildingFrontOffset(BlueprintId id) => switch (id) {
  BlueprintId.house => 24,
};
```

(con el import de `blueprint_id.dart`).

Run: el comando del paso 2. Expected: PASS del test nuevo; el resto del proyecto aún no compila (siguiente paso).

- [x] **Step 4: Componentes que dibujan edificios e ítems**

`BuildingComponent`:
- El frame sale de `SpriteNames.building(building.blueprint.id)`.
- Nuevo campo `final PositionEntity front;`, la base del muro frontal: `PositionEntity(x: building.position.x, y: building.position.y + RenderConstants.buildingFrontOffset(building.blueprint.id))`.
- `position` y `priority` se calculan desde `front`:

```dart
BuildingComponent({required LpcAssets assets, required BuildingEntity building})
  : this._(assets: assets, building: building, front: _frontOf(building));

BuildingComponent._({required LpcAssets assets, required BuildingEntity building, required this.front})
  : buildingId = building.id,
    footprint = building.position,
    super.fromFrame(
      frame: assets.frame(SpriteNames.building(building.blueprint.id)),
      sprite: assets.sprite(SpriteNames.building(building.blueprint.id)),
      position: front.toVector2(),
      priority: RenderDepth.bySortY(front.y),
    ) {
  progress = building.progress;
}

static PositionEntity _frontOf(BuildingEntity building) => PositionEntity(
  x: building.position.x,
  y: building.position.y + RenderConstants.buildingFrontOffset(building.blueprint.id),
);
```

`GroundItemComponent`: `SpriteNames.axePickup` pasa a `SpriteNames.item(item.kind)` en `frame` y `sprite`.

`PlacementGhostComponent`:
- El constructor recibe `required this.blueprint` (`final BlueprintId blueprint;`) y usa `SpriteNames.building(blueprint)`.
- `show` usa `RenderConstants.buildingFrontOffset(blueprint)`:

```dart
void show(PlacementData placement) {
  position.setValues(placement.position.x, placement.position.y + RenderConstants.buildingFrontOffset(blueprint));
  _isValid = placement.isValid;
  paint.colorFilter = ColorFilter.mode(placement.isValid ? validTint : invalidTint, BlendMode.modulate);
}
```

`ForestSceneComponent._showGhost`: si el fantasma existente es de otro *blueprint*, se sustituye.

```dart
void _showGhost(PlacementData? placement) {
  final existing = _ghost;
  if (placement == null || (existing != null && existing.blueprint != placement.blueprint)) {
    existing?.removeFromParent();
    _ghost = null;
  }
  if (placement == null) return;
  final ghost = _ghost;
  if (ghost != null) {
    ghost.show(placement);
    return;
  }
  final created = PlacementGhostComponent(assets: _assets, blueprint: placement.blueprint)..show(placement);
  _ghost = created;
  add(created);
}
```

- [x] **Step 5: Polvo desde el muro frontal**

`ParticleBursts` deja de conocer el desplazamiento de la casa:

```dart
static List<Particle> dust({required PositionEntity front, required math.Random random}) {
  return List.generate(dustPerHammer, (_) {
    final speed = _between(random, dustSpeedMin, dustSpeedMax);
    final angle = _between(random, dustAngleMin, dustAngleMax) * math.pi / 180;
    return Particle(
      kind: ParticleKind.dust,
      origin: PositionEntity(x: front.x, y: front.y - dustLift),
      velocityX: speed * math.cos(angle),
      velocityY: speed * math.sin(angle),
      gravity: 0,
      rotationDegrees: 0,
      lifespanSeconds: dustLifespanSeconds,
      alphaStart: dustAlphaStart,
      alphaEnd: dustAlphaEnd,
      scaleStart: dustScaleStart,
      scaleEnd: dustScaleEnd,
    );
  });
}

static double dustSortY(PositionEntity front) => front.y + sortYOffset;
```

Se quita el import de `render_constants.dart` si queda sin uso. En `ForestSceneComponent._onBuildingHammered`:

```dart
particles: ParticleBursts.dust(front: building.front, random: _random),
sortY: ParticleBursts.dustSortY(building.front),
```

Tests:
- `test/mocks/presentation/features/forest/game/particle_mock.dart`: `buildingCenter` (200, 180) se sustituye por `static const PositionEntity buildingFront = PositionEntity(x: 200, y: 204);`.
- En `particle_bursts_test.dart`, `testWhenHammeringThenSixDustPuffsRiseFromTheFrontWall` usa `ParticleMock.buildingFront`: el origen sigue siendo `ParticleMock.dustOrigin` (200, 200) y `dustSortY` sigue siendo 205.
- `lpc_assets_mock.dart` y `lpc_atlas_test.dart`: `SpriteNames.house` → `SpriteNames.building(BlueprintId.house)`, `SpriteNames.axePickup` → `SpriteNames.item(ToolKind.axe)`. `lpc_assets_test.dart`: igual.
- `placement_ghost_component_test.dart`: `PlacementGhostComponent(assets: LpcAssetsMock.create(), blueprint: BlueprintId.house)`; la posición esperada no cambia (300, 224).
- `building_component_test.dart`: se añade una aserción de `front` sobre el edificio que ya usa el test (`y` = `y` del edificio + 24).

Run: `flutter test test/layers/presentation/features/forest/game`
Expected: PASS.

- [x] **Step 6: Test del HUD genérico, que debe fallar**

`lib/layers/presentation/features/forest/models/resource_item_data.dart` y `tool_item_data.dart` se crean con el patrón de los demás modelos (campos `final`, constructor `const`, `==`/`hashCode` a mano). Sus tests de igualdad siguen el patrón de `hud_data_test.dart`.

`test/mocks/presentation/features/forest/resource_item_data_mock.dart`:

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/presentation/features/forest/models/resource_item_data.dart';

abstract final class ResourceItemDataMock {
  static ResourceItemData wood(int amount) =>
      ResourceItemData(resource: Resource.wood, name: Internationalize.forestResource(resource: Resource.wood), amount: amount);
}
```

`test/mocks/presentation/features/forest/tool_item_data_mock.dart`:

```dart
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/presentation/features/forest/models/tool_item_data.dart';

abstract final class ToolItemDataMock {
  static ToolItemData axe({required bool isOwned}) =>
      ToolItemData(tool: ToolKind.axe, name: Internationalize.forestTool(tool: ToolKind.axe), isOwned: isOwned);
}
```

`test/layers/presentation/features/forest/widgets/resource_bar_test.dart` se reescribe con las mismas comprobaciones que hoy, sobre listas:

```dart
double axeOpacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byKey(ResourceBar.toolKey(ToolKind.axe))).opacity;

testWidgets('testWhenRenderedThenItShowsEveryResourceAndTool', (tester) async {
  // given
  final bar = ResourceBar(resources: [ResourceItemDataMock.wood(23)], tools: [ToolItemDataMock.axe(isOwned: true)]);

  // when
  await tester.pumpHud(Center(child: bar));

  // then
  expect(find.text('23'), findsOneWidget);
  expect(find.text(Internationalize.forestResource(resource: Resource.wood)), findsOneWidget);
  expect(find.text(Internationalize.forestTool(tool: ToolKind.axe)), findsOneWidget);
});
```

Y del mismo modo `testWhenThePlayerHasNoAxeThenTheAxeIsDimmed` (0.35), `testWhenThePlayerHasTheAxeThenTheAxeIsOpaque` (1), `testWhenLabelsAreHiddenThenOnlyTheValueAndIconsAreShown` y `testWhenRenderedThenTheWoodAmountUsesTabularFigures`.

`hud_data_mock.dart`: cada `wood: n, hasAxe: b` pasa a `resources: [ResourceItemDataMock.wood(n)], tools: [ToolItemDataMock.axe(isOwned: b)]`.

`forest_bloc_test.dart`:

| Antes | Después |
|---|---|
| `expect(bloc.state.data.hud!.hasAxe, isTrue)` | `expect(bloc.state.data.hud!.tools, [ToolItemDataMock.axe(isOwned: true)])` |
| `expect(bloc.state.data.hud!.wood, 6)` | `expect(bloc.state.data.hud!.resources, [ResourceItemDataMock.wood(6)])` |

`hud_overlay_test.dart` y `internationalize_test.dart`: `Internationalize.forestWood` → `Internationalize.forestResource(resource: Resource.wood)`, `Internationalize.forestAxe` → `Internationalize.forestTool(tool: ToolKind.axe)`.

Run: `flutter test test/layers/presentation/features/forest/widgets test/layers/presentation/features/forest/bloc`
Expected: FAIL de compilación (`ResourceBar` no acepta `resources`, `HudData` no tiene `resources`).

- [x] **Step 7: `HudData`, `ForestBloc`, textos, iconos y `ResourceBar`**

`HudData`: `wood` y `hasAxe` se sustituyen por `final List<ResourceItemData> resources;` y `final List<ToolItemData> tools;`, comparadas con `ListEquality` y con `Object.hashAll` en `hashCode`, como `quests`.

`ForestBloc._hudData`:

```dart
resources: [
  for (final resource in Resource.values)
    ResourceItemData(
      resource: resource,
      name: Internationalize.forestResource(resource: resource),
      amount: status.inventory.amount(resource),
    ),
],
tools: [
  for (final tool in ToolKind.values)
    ToolItemData(
      tool: tool,
      name: Internationalize.forestTool(tool: tool),
      isOwned: status.inventory.hasTool(tool),
    ),
],
```

`es.json`: `forest.hud.wood` y `forest.hud.axe` se mueven a `"resource": { "wood": "Madera" }` y `"tool": { "axe": "Hacha" }`, dentro de `forest`.

`Internationalize`: `forestWood` y `forestAxe` se sustituyen por

```dart
static String forestResource({required Resource resource}) => switch (resource) {
  Resource.wood => '$_forest.resource.wood'.tr(),
};
static String forestTool({required ToolKind tool}) => switch (tool) {
  ToolKind.axe => '$_forest.tool.axe'.tr(),
};
```

`CustomIcons`:

```dart
static String resource(Resource resource) => switch (resource) {
  Resource.wood => wood,
};

static String tool(ToolKind tool) => switch (tool) {
  ToolKind.axe => axe,
};
```

`ResourceBar` (mismo aspecto que hoy; los iconos de recurso son de 22×14 y los de herramienta de 22×22, y las fases siguientes dibujan sus SVG a ese tamaño):

```dart
class ResourceBar extends StatelessWidget {
  final List<ResourceItemData> resources;
  final List<ToolItemData> tools;
  final bool showLabels;

  const ResourceBar({super.key, required this.resources, required this.tools, this.showLabels = true});

  static Key toolKey(ToolKind tool) => Key('resourceBarTool-${tool.name}');

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [for (final resource in resources) _resource(resource), for (final tool in tools) _tool(tool)],
      ),
    );
  }

  Widget _resource(ResourceItemData resource) {
    return Semantics(
      label: resource.name,
      value: '${resource.amount}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          SvgPicture.asset(CustomIcons.resource(resource.resource), width: 22, height: 14, excludeFromSemantics: true),
          if (showLabels)
            Text(resource.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              '${resource.amount}',
              style: CustomTextStyles.system18w600.copyWith(
                color: CustomColors.hudAccent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tool(ToolItemData tool) {
    return Opacity(
      key: toolKey(tool.tool),
      opacity: tool.isOwned ? 1 : 0.35,
      child: Semantics(
        label: tool.name,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset(CustomIcons.tool(tool.tool), width: 22, height: 22, excludeFromSemantics: true),
            if (showLabels) Text(tool.name, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
          ],
        ),
      ),
    );
  }
}
```

`HudOverlay`: `ResourceBar(resources: widget.hud.resources, tools: widget.hud.tools, showLabels: width >= HudOverlay.narrowWidth)`.

`CLAUDE.md`, en *Rendering constants*: "house drawn 24 px below its footprint centre" pasa a "buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px)". Se añade en un `git add CLAUDE.md` aparte.

Run: `flutter test`
Expected: PASS (todos, incluido `architecture_test.dart`).

- [x] **Step 8: Verificación completa**

```bash
dart format --line-length 120 <ficheros escritos en esta tarea>
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
grep -rn "houseFrontOffset\|axePickup\|SpriteNames.house\|forestWood\|forestAxe\|hasAxe" lib test
```

Expected: todo en verde y el `grep` sin resultados.

Prueba manual en Chrome (`flutter run -d chrome`), en el emulador (`flutter run -d emulator-5554`) y en el simulador (`flutter run -d "iPhone 17"`):
- el HUD muestra "Madera 0" y el hacha atenuada; en pantallas estrechas, sólo iconos y números;
- al recoger el hacha se ve nítida y al talar sube la madera;
- la previsualización de la casa sale verde o roja y la casa se ve igual que antes;
- el polvo sale del muro frontal.

- [x] **Step 9: Commit**

```bash
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-X]: Draw HUD resources and building sprites by kind"
```

Después, `/cerrar-tarea`. Con esto se cierra el milestone F0.
