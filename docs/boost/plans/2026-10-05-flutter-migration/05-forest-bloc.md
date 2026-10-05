# Fase 5 — `ForestBloc`, modelos de vista y textos del juego

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar toda la lógica de presentación de `ForestViewModel.kt` / `ForestContract.kt` / `ForestLabels.kt` a un `ForestBloc` de Flutter con sus eventos, su estado, sus modelos de vista, sus efectos y los textos en `es.json`, con los tests de `ForestViewModelTests.kt` portados a `blocTest`.

**Architecture:** Un único `ForestBloc` (pantalla completa, varios eventos con carga útil → BLoC, no Cubit) recibe todo: arranque, ticks del bucle de juego, clics, puntero, *Construir* y *Cancelar*. Un solo `on<ForestEvent>` con `await switch (event)`; los handlers no hacen ningún `await` real, así que los eventos se procesan en el orden de llegada (README D3). Cada emisión `ForestSuccess` lleva un `ForestData` con la instantánea del mundo, el render del jugador, el HUD ya formateado, la colocación y los efectos producidos por ese evento. Los mensajes al jugador son snackbars lanzados desde el BLoC con `NavigationService.showSnackbar` (regla del plugin). El BLoC **no** se registra en DI: `ForestPage` (fase 7) lo crea en `BlocProvider.create` con `locator.get<T>()`, como fija la fase 4.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_bloc, bloc, easy_localization, collection; tests con flutter_test, bloc_test y mockito (`@GenerateMocks` + build_runner).

## Global Constraints

Todas las de `README.md` (sección *Global Constraints*) aplican. Además, en esta fase:

- Solo se tocan: `lib/core/config/constants/enum/forest/`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/bloc/`, `lib/layers/presentation/features/forest/models/`, `test/helpers/`, `test/mocks/` (ficheros nuevos de presentación y servicios) y `test/core/assets/`, `test/layers/presentation/`. Nada de dominio, datos, DI ni Flame.
- Forma del estado exactamente como `references/presentation/bloc.md`: `ForestData` con `copyWith` (`ValueGetter` solo para campos anulables, nunca para listas), `sealed class ForestState { final ForestData data; }` con `ForestInitial`, `ForestInProgress`, `ForestSuccess`, `ForestFailure(exception)`; eventos `sealed` en pasado con constructores `const`; handlers `_on` + nombre del evento sin el prefijo `Forest`.
- `ForestStarted`: `emit(ForestInProgress)` → arrancar partida → `emit(ForestSuccess)`; `on AppException catch` → `showErrorPopUp(title, message, buttonTitle: Internationalize.commonError)` + `emit(ForestFailure)`. El resto de eventos se ignoran mientras el estado no sea `ForestSuccess` (no hay partida).
- Línea en blanco entre un `emit(...)` y la siguiente sentencia que no lo describa (regla 18 del plugin).
- Sin comentarios en `lib/`. En tests, `// given`, `// when`, `// then`.
- Los textos visibles se comprueban en los tests **con el literal en español** (igual que los tests Kotlin): los tests cargan `es.json` con `test/helpers/spanish_translations.dart`.
- Los casos de uso son `final class` (no se pueden mockear con mockito). Los tests del BLoC usan los **casos de uso reales** sobre `MockLevelRepository` y `MockGameSessionRepository` de la fase 4, exactamente como hacía `ForestViewModelFixture.kt` (caso de uso real sobre repositorios mock). `NavigationService` sí se mockea.
- Datos de prueba solo en `test/mocks/**` (mundos y posiciones de cada escenario en `ForestScenarioMock`); los cuerpos de los tests no construyen entidades. Los modelos de vista esperados (`QuestItemData`, `BuildItemData`, `PlacementData`, efectos) sí se escriben en el test: son el resultado esperado, no datos de entrada.

---

## Prerrequisitos (fases 1–4, ya en el repo)

| Qué | Dónde | Fase |
|---|---|---|
| `NavigationService` con `void showSnackbar({required String message, double? bottomMargin})` y `void showErrorPopUp({required String title, String? message, Widget? content, required String buttonTitle, bool willPop = false})` | `lib/core/services/navigation/source/navigation_service.dart` | 1 |
| `Internationalize` (con `static const String _common = 'common'` y `commonError`) + `es.json` | `lib/core/assets/i18n/internationalize.dart`, `lib/core/assets/i18n/translations/es.json` | 1 |
| `CustomException`, `AppException` y sus casos (`InvalidLevelException({required String data})`...) | `lib/core/error-handling/exceptions/custom_exception.dart`, `app_exceptions.dart` | 1 |
| Enums `BlueprintId`, `QuestId`, `ChopResult`, `ConstructionRejection`, `PlayerActivity`, `ToolKind` | `lib/core/config/constants/enum/*.dart` | 2 |
| Entidades de README §3.2, `World`, extensiones `PlayerRules` / `InventoryRules` | `lib/layers/domain/entities/**`, `lib/layers/domain/world/world.dart`, `lib/layers/domain/world/extensions/player_rules.dart`, `inventory_rules.dart` | 2 |
| `Rules` | `lib/layers/domain/rules/rules.dart` | 2 |
| Los 10 casos de uso, todos con `sessionRepository:`; `StartGameUseCase` además con `levelRepository:` | `lib/layers/domain/use-cases/game/*.dart` | 4 |
| `MockLevelRepository`, `MockGameSessionRepository` | `test/mocks/domain/repositories/repository_mocks.dart` (+ `.mocks.dart`) | 4 |
| `PlayerEntityMock.mock`, `TreeEntityMock.mock` (`tree-1`, roble, (200,100), radio 10, 6 de madera, 5 golpes), `GroundItemEntityMock.mock` (`axe-1`, hacha, (150,100)), `WorldMock.make({player, trees, items})` (1000×1000) | `test/mocks/domain/entities/**`, `test/mocks/domain/world/world_mock.dart` | 2/4 |

## Ficheros de esta fase

```
lib/core/config/constants/enum/forest/facing.dart
lib/core/config/constants/enum/forest/work_tool.dart
lib/core/config/constants/enum/forest/quest_item_status.dart
lib/core/assets/i18n/translations/es.json                       (modificar: bloque "forest")
lib/core/assets/i18n/internationalize.dart                      (modificar: getters forest*)
lib/layers/presentation/features/forest/models/player_pose.dart
lib/layers/presentation/features/forest/models/player_render_data.dart
lib/layers/presentation/features/forest/models/quest_item_data.dart
lib/layers/presentation/features/forest/models/build_item_data.dart
lib/layers/presentation/features/forest/models/hud_data.dart
lib/layers/presentation/features/forest/models/placement_data.dart
lib/layers/presentation/features/forest/models/forest_effect.dart
lib/layers/presentation/features/forest/bloc/forest_event.dart
lib/layers/presentation/features/forest/bloc/forest_state.dart
lib/layers/presentation/features/forest/bloc/forest_bloc.dart
test/helpers/spanish_translations.dart
test/mocks/core/services/navigation_service_mocks.dart          (+ .mocks.dart generado)
test/mocks/presentation/features/forest/forest_scenario_mock.dart
test/mocks/presentation/features/forest/forest_bloc_mock.dart
test/core/assets/i18n/internationalize_test.dart
test/layers/presentation/features/forest/models/player_pose_test.dart
test/layers/presentation/features/forest/models/hud_data_test.dart
test/layers/presentation/features/forest/models/placement_data_test.dart
test/layers/presentation/features/forest/models/forest_effect_test.dart
test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart
test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
```

## Mapa Kotlin → Flutter de esta fase

| Kotlin (`shared/.../presentation/forest/`) | Flutter |
|---|---|
| `ForestContract.kt` → `ForestState`, `PlayerRenderState`, `PlayerPose`, `HudState`, `QuestItem`, `BuildItem`, `Placement` | `bloc/forest_state.dart` (`ForestData` + estados), `models/*.dart` (`PlayerRenderData`, `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `PlacementData`) |
| `ForestContract.kt` → `Facing`, `WorkTool`, `QuestItemStatus` | `lib/core/config/constants/enum/forest/*.dart` |
| `ForestContract.kt` → `ForestIntent` | `bloc/forest_event.dart` (`ForestStarted` sustituye al `init {}` del ViewModel) |
| `ForestContract.kt` → `ForestEffect` (sin `ShowMessage`) | `models/forest_effect.dart` |
| `ForestEffect.ShowMessage(text)` | `NavigationService.showSnackbar(message: text)` |
| `ForestViewModel.kt` | `bloc/forest_bloc.dart` |
| `ForestLabels.kt` | bloque `forest` de `es.json` + getters `forest*` de `Internationalize` |
| `ForestViewModelFixture.kt` | `test/mocks/presentation/features/forest/forest_bloc_mock.dart` |
| `ForestViewModelTests.kt` | `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart` |

---

### Task 1: Enums de pantalla y modelos de vista

**Files:**
- Create: `lib/core/config/constants/enum/forest/facing.dart`
- Create: `lib/core/config/constants/enum/forest/work_tool.dart`
- Create: `lib/core/config/constants/enum/forest/quest_item_status.dart`
- Create: `lib/layers/presentation/features/forest/models/player_pose.dart`
- Create: `lib/layers/presentation/features/forest/models/player_render_data.dart`
- Create: `lib/layers/presentation/features/forest/models/quest_item_data.dart`
- Create: `lib/layers/presentation/features/forest/models/build_item_data.dart`
- Create: `lib/layers/presentation/features/forest/models/hud_data.dart`
- Create: `lib/layers/presentation/features/forest/models/placement_data.dart`
- Create: `lib/layers/presentation/features/forest/models/forest_effect.dart`
- Test: `test/layers/presentation/features/forest/models/player_pose_test.dart`
- Test: `test/layers/presentation/features/forest/models/hud_data_test.dart`
- Test: `test/layers/presentation/features/forest/models/placement_data_test.dart`
- Test: `test/layers/presentation/features/forest/models/forest_effect_test.dart`

**Interfaces:**
- Consumes: `PositionEntity` (`==` por `x`/`y`), `BuildingEntity` (`==` por valor), `BlueprintId` (fase 2).
- Produces (usados por la tarea 3, la fase 6 y la fase 7):
  - `enum Facing { up, left, down, right }`, `enum WorkTool { axe, hammer }`, `enum QuestItemStatus { done, current, pending }`
  - `sealed class PlayerPose` → `IdlePose({required bool withAxe})`, `WalkPose({required bool withAxe})`, `WorkPose({required WorkTool tool, required double swingProgress})`
  - `PlayerRenderData({required PositionEntity position, required Facing facing, required PlayerPose pose})`
  - `QuestItemData({required String title, required String progressText, required QuestItemStatus status})`
  - `BuildItemData({required BlueprintId blueprint, required String name, required String costText, String? missingText, required bool isEnabled})`
  - `HudData({required int wood, required bool hasAxe, required String questBadge, required List<QuestItemData> quests, required List<BuildItemData> buildItems, required bool isBuildLocked})`
  - `PlacementData({required BlueprintId blueprint, required PositionEntity position, required bool isValid})` con `copyWith({BlueprintId? blueprint, PositionEntity? position, bool? isValid})`
  - `sealed class ForestEffect` → `ItemPickedUpEffect({required String itemId})`, `TreeHitEffect({required String treeId, required double fromX})`, `TreeFelledEffect({required String treeId, required double fromX})`, `BuildingPlacedEffect({required BuildingEntity building})`, `BuildingHammeredEffect({required String buildingId, required double progress})`, `BuildingCompletedEffect({required String buildingId})`
  - Todos con `operator ==` y `hashCode` por valor.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
// test/layers/presentation/features/forest/models/player_pose_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';

void main() {
  test('testWhenComparingPosesWithTheSameValuesThenTheyAreEqual', () {
    // given
    const first = WorkPose(tool: WorkTool.axe, swingProgress: 0.5);
    const second = WorkPose(tool: WorkTool.axe, swingProgress: 0.5);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenComparingPosesOfDifferentKindsThenTheyAreNotEqual', () {
    // given
    const idle = IdlePose(withAxe: true);
    const walk = WalkPose(withAxe: true);

    // when
    final isEqual = idle == walk;

    // then
    expect(isEqual, isFalse);
  });
}
```

```dart
// test/layers/presentation/features/forest/models/hud_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

void main() {
  HudData hud({required int wood}) {
    return HudData(
      wood: wood,
      hasAxe: false,
      questBadge: '0/3',
      quests: const [QuestItemData(title: 'Recoge el hacha', progressText: '', status: QuestItemStatus.current)],
      buildItems: const [
        BuildItemData(
          blueprint: BlueprintId.house,
          name: 'Casa',
          costText: '15 de madera',
          missingText: 'Faltan 15',
          isEnabled: false,
        ),
      ],
      isBuildLocked: false,
    );
  }

  test('testWhenComparingHudsWithEqualListsThenTheyAreEqual', () {
    // given
    final first = hud(wood: 0);
    final second = hud(wood: 0);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenTheWoodChangesThenTheHudsAreNotEqual', () {
    // given
    final first = hud(wood: 0);
    final second = hud(wood: 6);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isFalse);
  });
}
```

```dart
// test/layers/presentation/features/forest/models/placement_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';

void main() {
  test('testWhenCopyingWithANewPositionThenKeepsTheRest', () {
    // given
    const placement = PlacementData(blueprint: BlueprintId.house, position: PositionEntity(x: 1, y: 2), isValid: true);

    // when
    final moved = placement.copyWith(position: const PositionEntity(x: 3, y: 4));

    // then
    expect(moved, const PlacementData(blueprint: BlueprintId.house, position: PositionEntity(x: 3, y: 4), isValid: true));
  });
}
```

```dart
// test/layers/presentation/features/forest/models/forest_effect_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

void main() {
  test('testWhenComparingEffectsWithTheSameValuesThenTheyAreEqual', () {
    // given
    const first = TreeFelledEffect(treeId: 'tree-1', fromX: 180);
    const second = TreeFelledEffect(treeId: 'tree-1', fromX: 180);

    // when
    final isEqual = first == second;

    // then
    expect(isEqual, isTrue);
    expect(first.hashCode, second.hashCode);
  });

  test('testWhenEffectsOfDifferentKindsShareTheTreeThenTheyAreNotEqual', () {
    // given
    const hit = TreeHitEffect(treeId: 'tree-1', fromX: 180);
    const felled = TreeFelledEffect(treeId: 'tree-1', fromX: 180);

    // when
    final isEqual = hit == felled;

    // then
    expect(isEqual, isFalse);
  });
}
```

- [ ] **Step 2: Ejecutar los tests y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/models`
Expected: FAIL en compilación con `Error when reading 'lib/layers/presentation/features/forest/models/player_pose.dart': No such file or directory` (y equivalentes para el resto de modelos).

- [ ] **Step 3: Crear los enums**

```dart
// lib/core/config/constants/enum/forest/facing.dart
enum Facing { up, left, down, right }
```

```dart
// lib/core/config/constants/enum/forest/work_tool.dart
enum WorkTool { axe, hammer }
```

```dart
// lib/core/config/constants/enum/forest/quest_item_status.dart
enum QuestItemStatus { done, current, pending }
```

- [ ] **Step 4: Crear los modelos**

```dart
// lib/layers/presentation/features/forest/models/player_pose.dart
import '../../../../../core/config/constants/enum/forest/work_tool.dart';

sealed class PlayerPose {
  const PlayerPose();
}

final class IdlePose extends PlayerPose {
  final bool withAxe;

  const IdlePose({required this.withAxe});

  @override
  bool operator ==(Object other) => identical(this, other) || other is IdlePose && other.withAxe == withAxe;

  @override
  int get hashCode => Object.hash(IdlePose, withAxe);
}

final class WalkPose extends PlayerPose {
  final bool withAxe;

  const WalkPose({required this.withAxe});

  @override
  bool operator ==(Object other) => identical(this, other) || other is WalkPose && other.withAxe == withAxe;

  @override
  int get hashCode => Object.hash(WalkPose, withAxe);
}

final class WorkPose extends PlayerPose {
  final WorkTool tool;
  final double swingProgress;

  const WorkPose({required this.tool, required this.swingProgress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkPose && other.tool == tool && other.swingProgress == swingProgress;

  @override
  int get hashCode => Object.hash(WorkPose, tool, swingProgress);
}
```

```dart
// lib/layers/presentation/features/forest/models/player_render_data.dart
import '../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import 'player_pose.dart';

class PlayerRenderData {
  final PositionEntity position;
  final Facing facing;
  final PlayerPose pose;

  const PlayerRenderData({required this.position, required this.facing, required this.pose});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerRenderData && other.position == position && other.facing == facing && other.pose == pose;

  @override
  int get hashCode => Object.hash(position, facing, pose);
}
```

```dart
// lib/layers/presentation/features/forest/models/quest_item_data.dart
import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';

class QuestItemData {
  final String title;
  final String progressText;
  final QuestItemStatus status;

  const QuestItemData({required this.title, required this.progressText, required this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestItemData && other.title == title && other.progressText == progressText && other.status == status;

  @override
  int get hashCode => Object.hash(title, progressText, status);
}
```

```dart
// lib/layers/presentation/features/forest/models/build_item_data.dart
import '../../../../../core/config/constants/enum/blueprint_id.dart';

class BuildItemData {
  final BlueprintId blueprint;
  final String name;
  final String costText;
  final String? missingText;
  final bool isEnabled;

  const BuildItemData({
    required this.blueprint,
    required this.name,
    required this.costText,
    this.missingText,
    required this.isEnabled,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildItemData &&
          other.blueprint == blueprint &&
          other.name == name &&
          other.costText == costText &&
          other.missingText == missingText &&
          other.isEnabled == isEnabled;

  @override
  int get hashCode => Object.hash(blueprint, name, costText, missingText, isEnabled);
}
```

```dart
// lib/layers/presentation/features/forest/models/hud_data.dart
import 'package:collection/collection.dart';

import 'build_item_data.dart';
import 'quest_item_data.dart';

class HudData {
  final int wood;
  final bool hasAxe;
  final String questBadge;
  final List<QuestItemData> quests;
  final List<BuildItemData> buildItems;
  final bool isBuildLocked;

  const HudData({
    required this.wood,
    required this.hasAxe,
    required this.questBadge,
    required this.quests,
    required this.buildItems,
    required this.isBuildLocked,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudData &&
          other.wood == wood &&
          other.hasAxe == hasAxe &&
          other.questBadge == questBadge &&
          const ListEquality<QuestItemData>().equals(other.quests, quests) &&
          const ListEquality<BuildItemData>().equals(other.buildItems, buildItems) &&
          other.isBuildLocked == isBuildLocked;

  @override
  int get hashCode =>
      Object.hash(wood, hasAxe, questBadge, Object.hashAll(quests), Object.hashAll(buildItems), isBuildLocked);
}
```

```dart
// lib/layers/presentation/features/forest/models/placement_data.dart
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../domain/entities/geometry/position_entity.dart';

class PlacementData {
  final BlueprintId blueprint;
  final PositionEntity position;
  final bool isValid;

  const PlacementData({required this.blueprint, required this.position, required this.isValid});

  PlacementData copyWith({BlueprintId? blueprint, PositionEntity? position, bool? isValid}) {
    return PlacementData(
      blueprint: blueprint ?? this.blueprint,
      position: position ?? this.position,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementData && other.blueprint == blueprint && other.position == position && other.isValid == isValid;

  @override
  int get hashCode => Object.hash(blueprint, position, isValid);
}
```

```dart
// lib/layers/presentation/features/forest/models/forest_effect.dart
import '../../../../domain/entities/building/building_entity.dart';

sealed class ForestEffect {
  const ForestEffect();
}

final class ItemPickedUpEffect extends ForestEffect {
  final String itemId;

  const ItemPickedUpEffect({required this.itemId});

  @override
  bool operator ==(Object other) => identical(this, other) || other is ItemPickedUpEffect && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(ItemPickedUpEffect, itemId);
}

final class TreeHitEffect extends ForestEffect {
  final String treeId;
  final double fromX;

  const TreeHitEffect({required this.treeId, required this.fromX});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreeHitEffect && other.treeId == treeId && other.fromX == fromX;

  @override
  int get hashCode => Object.hash(TreeHitEffect, treeId, fromX);
}

final class TreeFelledEffect extends ForestEffect {
  final String treeId;
  final double fromX;

  const TreeFelledEffect({required this.treeId, required this.fromX});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreeFelledEffect && other.treeId == treeId && other.fromX == fromX;

  @override
  int get hashCode => Object.hash(TreeFelledEffect, treeId, fromX);
}

final class BuildingPlacedEffect extends ForestEffect {
  final BuildingEntity building;

  const BuildingPlacedEffect({required this.building});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BuildingPlacedEffect && other.building == building;

  @override
  int get hashCode => Object.hash(BuildingPlacedEffect, building);
}

final class BuildingHammeredEffect extends ForestEffect {
  final String buildingId;
  final double progress;

  const BuildingHammeredEffect({required this.buildingId, required this.progress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildingHammeredEffect && other.buildingId == buildingId && other.progress == progress;

  @override
  int get hashCode => Object.hash(BuildingHammeredEffect, buildingId, progress);
}

final class BuildingCompletedEffect extends ForestEffect {
  final String buildingId;

  const BuildingCompletedEffect({required this.buildingId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BuildingCompletedEffect && other.buildingId == buildingId;

  @override
  int get hashCode => Object.hash(BuildingCompletedEffect, buildingId);
}
```

- [ ] **Step 5: Ejecutar los tests y ver que pasan**

Run: `flutter test test/layers/presentation/features/forest/models`
Expected: `All tests passed!` (8 tests).

- [ ] **Step 6: Formatear y analizar**

Run: `dart format --line-length 120 lib/core/config/constants/enum/forest lib/layers/presentation/features/forest/models test/layers/presentation/features/forest/models && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/core/config/constants/enum/forest lib/layers/presentation/features/forest/models test/layers/presentation/features/forest/models
git commit -m "[PROJECT-X]: Add the forest screen view models and effects"
```

---

### Task 2: Textos del juego en `es.json` + `Internationalize`

**Files:**
- Modify: `lib/core/assets/i18n/translations/es.json` (añadir el bloque `"forest"` en la raíz)
- Modify: `lib/core/assets/i18n/internationalize.dart` (añadir los getters `forest*` al final de la clase, sin comentario de sección)
- Create: `test/helpers/spanish_translations.dart`
- Test: `test/core/assets/i18n/internationalize_test.dart`

**Interfaces:**
- Consumes: `BlueprintId`, `QuestId` (fase 2); `Internationalize` y `es.json` de la fase 1.
- Produces (usados por la tarea 3 y la fase 7):
  - `Internationalize.forestWood`, `forestAxe`, `forestBuild`, `forestQuests`, `forestQuestDone`
  - `Internationalize.forestCost({required int wood})`, `forestMissing({required int wood})`
  - `Internationalize.forestBlueprint({required BlueprintId id})`, `forestQuestTitle({required QuestId id})`
  - `Internationalize.forestMessageWelcome`, `forestMessageNeedAxe`, `forestMessageBlockedPath`, `forestMessagePickedUpAxe`, `forestMessageBlockedSite`, `forestMessageNotEnoughWood`, `forestMessageBuildingStarted`, `forestMessageAllQuestsCompleted`
  - `Internationalize.forestMessageWoodGained({required int wood})`, `forestMessagePlacing({required String name})`, `forestMessageBuildingCompleted({required String name})`, `forestMessageQuestCompleted({required String title})`
  - `Internationalize.forestPlacementConfirm`, `forestPlacementCancel`, `forestAccessibilityGameWorld`
  - `loadSpanishTranslations()` (helper de test): carga `es.json` en `easy_localization` sin widgets.

- [ ] **Step 1: Comprobar lo que dejó la fase 1**

Run: `grep -n "commonError\|class Internationalize" lib/core/assets/i18n/internationalize.dart && grep -n '"common"' lib/core/assets/i18n/translations/es.json && ls test/helpers 2>/dev/null`
Expected: aparecen `class Internationalize`, `commonError` y el bloque `"common"`. Si falta `commonError`, añadir a `es.json` `"common": { "error": "Aceptar" }` y a la clase `static const String _common = 'common';` + `static String get commonError => '$_common.error'.tr();`. Si `test/helpers/` ya tiene un helper que carga `es.json`, usarlo en lugar de crear `spanish_translations.dart` y cambiar el import en los tests de esta fase.

- [ ] **Step 2: Crear el helper de traducciones para tests**

`easy_localization` no expone una API pública para cargar traducciones sin `EasyLocalization` (widget); `Localization.load` es la que usa el propio paquete en sus tests (`test/easy_localization_test.dart` del paquete).

Si en la versión instalada `Localization.load` o `Translations` tienen otra firma (el analizador marca el import de `src/`), abrir `~/.pub-cache/hosted/pub.dev/easy_localization-<versión>/lib/src/localization.dart` y adaptar **solo este helper** a la firma real (el resto de la fase no depende de cómo se cargue). Alternativa sin API interna, si `src/` ya no expone nada usable: convertir los tests que comprueban textos en `testWidgets` que montan `EasyLocalization(supportedLocales: const [Locale('es')], path: 'lib/core/assets/i18n/translations', startLocale: const Locale('es'), child: const SizedBox())` tras `await EasyLocalization.ensureInitialized()`, con `SharedPreferences.setMockInitialValues({})`, y anotar la desviación en README §7.

```dart
// test/helpers/spanish_translations.dart
// ignore_for_file: implementation_imports
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';

void loadSpanishTranslations() {
  final file = File('lib/core/assets/i18n/translations/es.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  Localization.load(const Locale('es'), translations: Translations(json));
}
```

- [ ] **Step 3: Escribir el test que falla**

```dart
// test/core/assets/i18n/internationalize_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';

import '../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenFormattingCostsThenInsertsTheWood', () {
    // given
    const wood = 15;

    // when
    final cost = Internationalize.forestCost(wood: wood);
    final missing = Internationalize.forestMissing(wood: 5);
    final gained = Internationalize.forestMessageWoodGained(wood: 6);

    // then
    expect(cost, '15 de madera');
    expect(missing, 'Faltan 5');
    expect(gained, '+6 de madera');
  });

  test('testWhenNamingBlueprintsAndQuestsThenUsesTheSpanishTitles', () {
    // given
    const blueprint = BlueprintId.house;

    // when
    final name = Internationalize.forestBlueprint(id: blueprint);
    final quests = QuestId.values.map((id) => Internationalize.forestQuestTitle(id: id)).toList();

    // then
    expect(name, 'Casa');
    expect(quests, ['Recoge el hacha', 'Consigue al menos 15 de madera', 'Construye una casa']);
  });

  test('testWhenFormattingMessagesWithNamesThenInsertsThem', () {
    // given
    const name = 'Casa';

    // when
    final placing = Internationalize.forestMessagePlacing(name: name);
    final completed = Internationalize.forestMessageBuildingCompleted(name: name);
    final quest = Internationalize.forestMessageQuestCompleted(title: 'Recoge el hacha');

    // then
    expect(placing, 'Elige dónde construir: Casa. Clic derecho o Esc para cancelar.');
    expect(completed, '¡Casa construida!');
    expect(quest, 'Misión completada: Recoge el hacha');
  });

  test('testWhenReadingEveryForestTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestWood,
      Internationalize.forestAxe,
      Internationalize.forestBuild,
      Internationalize.forestQuests,
      Internationalize.forestQuestDone,
      Internationalize.forestMessageWelcome,
      Internationalize.forestMessageNeedAxe,
      Internationalize.forestMessageBlockedPath,
      Internationalize.forestMessagePickedUpAxe,
      Internationalize.forestMessageBlockedSite,
      Internationalize.forestMessageNotEnoughWood,
      Internationalize.forestMessageBuildingStarted,
      Internationalize.forestMessageAllQuestsCompleted,
      Internationalize.forestPlacementConfirm,
      Internationalize.forestPlacementCancel,
      Internationalize.forestAccessibilityGameWorld,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Madera',
      'Hacha',
      'Construir',
      'Misiones',
      'Hecha',
      'Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.',
      'Necesitas un hacha para talar.',
      'Hay algo en medio. Acércate por otro lado.',
      '¡Hacha recogida! Haz clic en un árbol para talarlo.',
      'Ahí no cabe. Busca un sitio despejado.',
      'No tienes madera suficiente.',
      'Manos a la obra…',
      '¡Has completado todas las misiones!',
      'Construir aquí',
      'Cancelar',
      'Mundo de juego: bosque con árboles, el personaje y los edificios',
    ]);
  });
}
```

- [ ] **Step 4: Ejecutar el test y ver que falla**

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: FAIL en compilación con `Member not found: 'forestCost'` (y el resto de getters `forest*`).

- [ ] **Step 5: Añadir el bloque `forest` a `es.json`**

Añadir esta clave en la raíz del objeto JSON (junto a `common`, `error`...), respetando las comas. El texto es literal de `ForestLabels.kt`; los parámetros pasan a `{nombre}` de `easy_localization`:

```json
  "forest": {
    "hud": {
      "wood": "Madera",
      "axe": "Hacha",
      "build": "Construir",
      "quests": "Misiones",
      "questDone": "Hecha",
      "cost": "{wood} de madera",
      "missing": "Faltan {wood}"
    },
    "blueprint": {
      "house": "Casa"
    },
    "quest": {
      "pickUpAxe": "Recoge el hacha",
      "gatherWood": "Consigue al menos 15 de madera",
      "buildHouse": "Construye una casa"
    },
    "message": {
      "welcome": "Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.",
      "needAxe": "Necesitas un hacha para talar.",
      "blockedPath": "Hay algo en medio. Acércate por otro lado.",
      "pickedUpAxe": "¡Hacha recogida! Haz clic en un árbol para talarlo.",
      "blockedSite": "Ahí no cabe. Busca un sitio despejado.",
      "notEnoughWood": "No tienes madera suficiente.",
      "buildingStarted": "Manos a la obra…",
      "allQuestsCompleted": "¡Has completado todas las misiones!",
      "woodGained": "+{wood} de madera",
      "placing": "Elige dónde construir: {name}. Clic derecho o Esc para cancelar.",
      "buildingCompleted": "¡{name} construida!",
      "questCompleted": "Misión completada: {title}"
    },
    "placement": {
      "confirm": "Construir aquí",
      "cancel": "Cancelar"
    },
    "accessibility": {
      "gameWorld": "Mundo de juego: bosque con árboles, el personaje y los edificios"
    }
  }
```

Run: `python3 -c "import json; json.load(open('lib/core/assets/i18n/translations/es.json'))" && echo ok`
Expected: `ok`

- [ ] **Step 6: Añadir los getters a `Internationalize`**

Añadir los imports (rutas relativas desde `lib/core/assets/i18n/`) al principio del fichero, junto al de `easy_localization`:

```dart
import '../../config/constants/enum/blueprint_id.dart';
import '../../config/constants/enum/quest_id.dart';
```

Y al final del cuerpo de la clase `Internationalize`, antes de la última `}`:

```dart
  static const String _forest = 'forest';
  static String get forestWood => '$_forest.hud.wood'.tr();
  static String get forestAxe => '$_forest.hud.axe'.tr();
  static String get forestBuild => '$_forest.hud.build'.tr();
  static String get forestQuests => '$_forest.hud.quests'.tr();
  static String get forestQuestDone => '$_forest.hud.questDone'.tr();
  static String forestCost({required int wood}) => '$_forest.hud.cost'.tr(namedArgs: {'wood': '$wood'});
  static String forestMissing({required int wood}) => '$_forest.hud.missing'.tr(namedArgs: {'wood': '$wood'});
  static String forestBlueprint({required BlueprintId id}) => switch (id) {
    BlueprintId.house => '$_forest.blueprint.house'.tr(),
  };
  static String forestQuestTitle({required QuestId id}) => switch (id) {
    QuestId.pickUpAxe => '$_forest.quest.pickUpAxe'.tr(),
    QuestId.gatherWood => '$_forest.quest.gatherWood'.tr(),
    QuestId.buildHouse => '$_forest.quest.buildHouse'.tr(),
  };
  static String get forestMessageWelcome => '$_forest.message.welcome'.tr();
  static String get forestMessageNeedAxe => '$_forest.message.needAxe'.tr();
  static String get forestMessageBlockedPath => '$_forest.message.blockedPath'.tr();
  static String get forestMessagePickedUpAxe => '$_forest.message.pickedUpAxe'.tr();
  static String get forestMessageBlockedSite => '$_forest.message.blockedSite'.tr();
  static String get forestMessageNotEnoughWood => '$_forest.message.notEnoughWood'.tr();
  static String get forestMessageBuildingStarted => '$_forest.message.buildingStarted'.tr();
  static String get forestMessageAllQuestsCompleted => '$_forest.message.allQuestsCompleted'.tr();
  static String forestMessageWoodGained({required int wood}) =>
      '$_forest.message.woodGained'.tr(namedArgs: {'wood': '$wood'});
  static String forestMessagePlacing({required String name}) =>
      '$_forest.message.placing'.tr(namedArgs: {'name': name});
  static String forestMessageBuildingCompleted({required String name}) =>
      '$_forest.message.buildingCompleted'.tr(namedArgs: {'name': name});
  static String forestMessageQuestCompleted({required String title}) =>
      '$_forest.message.questCompleted'.tr(namedArgs: {'title': title});
  static String get forestPlacementConfirm => '$_forest.placement.confirm'.tr();
  static String get forestPlacementCancel => '$_forest.placement.cancel'.tr();
  static String get forestAccessibilityGameWorld => '$_forest.accessibility.gameWorld'.tr();
```

- [ ] **Step 7: Ejecutar el test y ver que pasa**

Run: `flutter test test/core/assets/i18n/internationalize_test.dart`
Expected: `All tests passed!` (4 tests).

- [ ] **Step 8: Formatear, analizar y suite completa**

Run: `dart format --line-length 120 lib/core/assets/i18n test/helpers test/core/assets && flutter analyze && flutter test`
Expected: `No issues found!` y `All tests passed!`

- [ ] **Step 9: Commit**

```bash
git add lib/core/assets/i18n test/helpers/spanish_translations.dart test/core/assets/i18n/internationalize_test.dart
git commit -m "[PROJECT-X]: Move the forest texts to the Spanish translations"
```

---

### Task 3: `ForestBloc` — eventos, estado y arranque de la partida

**Files:**
- Create: `lib/layers/presentation/features/forest/bloc/forest_event.dart`
- Create: `lib/layers/presentation/features/forest/bloc/forest_state.dart`
- Create: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
- Create: `test/mocks/core/services/navigation_service_mocks.dart` (+ `navigation_service_mocks.mocks.dart` generado)
- Create: `test/mocks/presentation/features/forest/forest_scenario_mock.dart`
- Create: `test/mocks/presentation/features/forest/forest_bloc_mock.dart`
- Test: `test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart`

**Interfaces:**
- Consumes: modelos y enums de la tarea 1; `Internationalize.commonError` (fase 1); los 10 casos de uso (fase 4); `NavigationService` (fase 1); `AppException`, `CustomException`, `InvalidLevelException` (fase 1); `MockLevelRepository`, `MockGameSessionRepository`, `WorldMock.make`, `PlayerEntityMock.mock`, `TreeEntityMock.mock`, `GroundItemEntityMock.mock` (fases 2/4); `PlayerRules.withInventory`, `InventoryRules.addTool` / `addWood` (fase 2).
- Produces (usados por la tarea 4, la fase 6 y la fase 7):
  - Eventos: `ForestStarted()`, `ForestTicked({required double deltaMs})`, `ForestMapClicked({required PositionEntity position, String? treeId, bool isSecondary = false})`, `ForestPointerMoved({required PositionEntity position})`, `ForestBuildRequested({required BlueprintId blueprint})`, `ForestPlacementCancelled()` — todos `const`.
  - `ForestData({WorldSnapshotEntity? world, PlayerRenderData? player, HudData? hud, PlacementData? placement, List<ForestEffect> effects = const []})` + `copyWith`.
  - `sealed class ForestState { final ForestData data; }` → `ForestInitial()`, `ForestInProgress({required data})`, `ForestSuccess({required data})`, `ForestFailure({required data, required CustomException exception})`.
  - `ForestBloc({required StartGameUseCase startGameUseCase, required MovePlayerUseCase movePlayerUseCase, required ChopTreeUseCase chopTreeUseCase, required CanPlaceBuildingUseCase canPlaceBuildingUseCase, required ConstructBuildingUseCase constructBuildingUseCase, required AdvanceGameUseCase advanceGameUseCase, required GetPlayerStatusUseCase getPlayerStatusUseCase, required GetWorldSnapshotUseCase getWorldSnapshotUseCase, required GetBuildOptionsUseCase getBuildOptionsUseCase, required GetQuestsUseCase getQuestsUseCase, required NavigationService navigationService})`.
  - Tests: `MockNavigationService`; `ForestScenarioMock` (mundos y posiciones); `ForestBlocMock.make(World world, {required MockNavigationService navigationService, Object? loadError})`, `ForestBlocMock.tickFor(ForestBloc bloc, double totalMs)`, `ForestBlocMock.processEvents()`, `ForestBlocMock.collectEffects(ForestBloc bloc)`, `ForestBlocMock.shownMessages(MockNavigationService navigationService)`.

- [ ] **Step 1: Generar el mock de `NavigationService`**

Run: `grep -rln "MockSpec<NavigationService>\|GenerateMocks(\[.*NavigationService" test/mocks 2>/dev/null`
Expected: sin salida. (Si la fase 1 ya generó `MockNavigationService`, usar ese fichero y cambiar los imports de esta fase en vez de crear otro.)

```dart
// test/mocks/core/services/navigation_service_mocks.dart
import 'package:mockito/annotations.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';

@GenerateMocks([NavigationService])
void main() {}
```

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: termina con `Succeeded after ...` y existe `test/mocks/core/services/navigation_service_mocks.mocks.dart` con `class MockNavigationService`.

- [ ] **Step 2: Crear los escenarios de la pantalla**

Port de los mundos y clics que `ForestViewModelTests.kt` construía dentro de cada test. Cada método devuelve un `World` nuevo (es mutable).

```dart
// test/mocks/presentation/features/forest/forest_scenario_mock.dart
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../../domain/entities/item/ground_item_entity_mock.dart';
import '../../../domain/entities/player/player_entity_mock.dart';
import '../../../domain/entities/tree/tree_entity_mock.dart';
import '../../../domain/world/world_mock.dart';

abstract final class ForestScenarioMock {
  static const PositionEntity groundEast = PositionEntity(x: 150, y: 100);
  static const PositionEntity playerStart = PositionEntity(x: 100, y: 100);
  static const PositionEntity eastTreeCanopy = PositionEntity(x: 300, y: 80);
  static const PositionEntity axeSpot = PositionEntity(x: 110, y: 100);
  static const PositionEntity treeCanopy = PositionEntity(x: 200, y: 80);
  static const PositionEntity siteNextToFarTree = PositionEntity(x: 410, y: 400);
  static const PositionEntity freeSite = PositionEntity(x: 250, y: 250);
  static const PositionEntity farSite = PositionEntity(x: 500, y: 500);
  static const PositionEntity houseSiteEast = PositionEntity(x: 300, y: 100);

  static World empty() => WorldMock.make();

  static World treeEast() =>
      WorldMock.make(trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 300, y: 100))]);

  static World axeNextToPlayer() =>
      WorldMock.make(items: [GroundItemEntityMock.mock.copyWith(position: axeSpot)]);

  static World axeInHandWithTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(tools: {ToolKind.axe})),
    trees: [TreeEntityMock.mock],
  );

  static World tenWood() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(wood: 10)));

  static World fifteenWood() =>
      WorldMock.make(player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(wood: 15)));

  static World fifteenWoodWithFarTree() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(wood: 15)),
    trees: [TreeEntityMock.mock.copyWith(position: const PositionEntity(x: 400, y: 400))],
  );

  static World axeAndFifteenWood() => WorldMock.make(
    player: PlayerEntityMock.mock.copyWith(inventory: const InventoryEntity(wood: 15, tools: {ToolKind.axe})),
  );
}
```

- [ ] **Step 3: Crear el fixture del BLoC**

Port de `ForestViewModelFixture.kt`: BLoC con los casos de uso **reales** sobre repositorios mock; el repositorio de sesión guarda la partida que le pasa `StartGameUseCase`.

```dart
// test/mocks/presentation/features/forest/forest_bloc_mock.dart
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
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
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

import '../../../core/services/navigation_service_mocks.mocks.dart';
import '../../../domain/repositories/repository_mocks.mocks.dart';

abstract final class ForestBlocMock {
  static const double frameMs = 16;

  static ForestBloc make(World world, {required MockNavigationService navigationService, Object? loadError}) {
    final levelRepository = MockLevelRepository();
    final sessionRepository = MockGameSessionRepository();
    GameSessionEntity? session;
    if (loadError != null) {
      when(levelRepository.load()).thenThrow(loadError);
    } else {
      when(levelRepository.load()).thenReturn(world);
    }
    when(sessionRepository.save(any)).thenAnswer((invocation) {
      session = invocation.positionalArguments.first as GameSessionEntity;
    });
    when(sessionRepository.current()).thenAnswer((_) => session!);
    return ForestBloc(
      startGameUseCase: StartGameUseCase(levelRepository: levelRepository, sessionRepository: sessionRepository),
      movePlayerUseCase: MovePlayerUseCase(sessionRepository: sessionRepository),
      chopTreeUseCase: ChopTreeUseCase(sessionRepository: sessionRepository),
      canPlaceBuildingUseCase: CanPlaceBuildingUseCase(sessionRepository: sessionRepository),
      constructBuildingUseCase: ConstructBuildingUseCase(sessionRepository: sessionRepository),
      advanceGameUseCase: AdvanceGameUseCase(sessionRepository: sessionRepository),
      getPlayerStatusUseCase: GetPlayerStatusUseCase(sessionRepository: sessionRepository),
      getWorldSnapshotUseCase: GetWorldSnapshotUseCase(sessionRepository: sessionRepository),
      getBuildOptionsUseCase: GetBuildOptionsUseCase(sessionRepository: sessionRepository),
      getQuestsUseCase: GetQuestsUseCase(sessionRepository: sessionRepository),
      navigationService: navigationService,
    );
  }

  static void tickFor(ForestBloc bloc, double totalMs) {
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      bloc.add(const ForestTicked(deltaMs: frameMs));
      elapsed += frameMs;
    }
  }

  static Future<void> processEvents() => Future<void>.delayed(Duration.zero);

  static List<ForestEffect> collectEffects(ForestBloc bloc) {
    final effects = <ForestEffect>[];
    bloc.stream.listen((state) => effects.addAll(state.data.effects));
    return effects;
  }

  static List<String> shownMessages(MockNavigationService navigationService) {
    return verify(navigationService.showSnackbar(message: captureAnyNamed('message'))).captured.cast<String>();
  }
}
```

- [ ] **Step 4: Escribir los tests de arranque que fallan**

```dart
// test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';

void main() {
  late MockNavigationService navigationService;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenStartedThenEmitsInProgressAndThenTheFirstFrame',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.treeEast(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    expect: () => [isA<ForestInProgress>(), isA<ForestSuccess>()],
    verify: (bloc) {
      // then
      final data = bloc.state.data;
      expect(data.world!.trees.single.id, 'tree-1');
      expect(data.player!.position, ForestScenarioMock.playerStart);
      expect(data.player!.facing, Facing.down);
      expect(data.player!.pose, const IdlePose(withAxe: false));
      expect(data.hud!.questBadge, '0/3');
      expect(data.placement, isNull);
      expect(data.effects, isEmpty);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTheLevelCannotBeLoadedThenShowsTheErrorAndFails',
    build: () {
      // given
      return ForestBlocMock.make(
        ForestScenarioMock.empty(),
        navigationService: navigationService,
        loadError: const InvalidLevelException(data: 'missing width'),
      );
    },
    act: (bloc) {
      // when
      bloc.add(const ForestStarted());
    },
    expect: () => [isA<ForestInProgress>(), isA<ForestFailure>()],
    verify: (bloc) {
      // then
      expect((bloc.state as ForestFailure).exception, isA<InvalidLevelException>());
      verify(
        navigationService.showErrorPopUp(
          title: anyNamed('title'),
          message: anyNamed('message'),
          buttonTitle: anyNamed('buttonTitle'),
        ),
      ).called(1);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenTickedBeforeStartingThenIgnoresIt',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc.add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
    },
    expect: () => <ForestState>[],
    verify: (bloc) {
      // then
      expect(bloc.state, isA<ForestInitial>());
      verifyNever(navigationService.showSnackbar(message: anyNamed('message')));
    },
  );
}
```

- [ ] **Step 5: Ejecutar los tests y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart`
Expected: FAIL en compilación con `Error when reading 'lib/layers/presentation/features/forest/bloc/forest_bloc.dart': No such file or directory`.

- [ ] **Step 6: Crear eventos y estado**

```dart
// lib/layers/presentation/features/forest/bloc/forest_event.dart
part of 'forest_bloc.dart';

sealed class ForestEvent {
  const ForestEvent();
}

final class ForestStarted extends ForestEvent {
  const ForestStarted();
}

final class ForestTicked extends ForestEvent {
  final double deltaMs;

  const ForestTicked({required this.deltaMs});
}

final class ForestMapClicked extends ForestEvent {
  final PositionEntity position;
  final String? treeId;
  final bool isSecondary;

  const ForestMapClicked({required this.position, this.treeId, this.isSecondary = false});
}

final class ForestPointerMoved extends ForestEvent {
  final PositionEntity position;

  const ForestPointerMoved({required this.position});
}

final class ForestBuildRequested extends ForestEvent {
  final BlueprintId blueprint;

  const ForestBuildRequested({required this.blueprint});
}

final class ForestPlacementCancelled extends ForestEvent {
  const ForestPlacementCancelled();
}
```

```dart
// lib/layers/presentation/features/forest/bloc/forest_state.dart
part of 'forest_bloc.dart';

class ForestData {
  final WorldSnapshotEntity? world;
  final PlayerRenderData? player;
  final HudData? hud;
  final PlacementData? placement;
  final List<ForestEffect> effects;

  const ForestData({this.world, this.player, this.hud, this.placement, this.effects = const []});

  ForestData copyWith({
    ValueGetter<WorldSnapshotEntity?>? world,
    ValueGetter<PlayerRenderData?>? player,
    ValueGetter<HudData?>? hud,
    ValueGetter<PlacementData?>? placement,
    List<ForestEffect>? effects,
  }) {
    return ForestData(
      world: world != null ? world() : this.world,
      player: player != null ? player() : this.player,
      hud: hud != null ? hud() : this.hud,
      placement: placement != null ? placement() : this.placement,
      effects: effects ?? this.effects,
    );
  }
}

sealed class ForestState {
  final ForestData data;

  const ForestState({required this.data});
}

final class ForestInitial extends ForestState {
  const ForestInitial() : super(data: const ForestData());
}

final class ForestInProgress extends ForestState {
  const ForestInProgress({required super.data});
}

final class ForestSuccess extends ForestState {
  const ForestSuccess({required super.data});
}

final class ForestFailure extends ForestState {
  final CustomException exception;

  const ForestFailure({required super.data, required this.exception});
}
```

- [ ] **Step 7: Crear el BLoC con el arranque**

En esta tarea solo `ForestStarted` tiene comportamiento; los demás handlers devuelven sin hacer nada y la tarea 4 los completa.

```dart
// lib/layers/presentation/features/forest/bloc/forest_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../core/config/constants/enum/player_activity.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../../core/services/navigation/source/navigation_service.dart';
import '../../../../domain/entities/game/build_option_entity.dart';
import '../../../../domain/entities/game/player_status_entity.dart';
import '../../../../domain/entities/game/quest_progress_entity.dart';
import '../../../../domain/entities/game/world_snapshot_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/use-cases/game/advance_game_use_case.dart';
import '../../../../domain/use-cases/game/can_place_building_use_case.dart';
import '../../../../domain/use-cases/game/chop_tree_use_case.dart';
import '../../../../domain/use-cases/game/construct_building_use_case.dart';
import '../../../../domain/use-cases/game/get_build_options_use_case.dart';
import '../../../../domain/use-cases/game/get_player_status_use_case.dart';
import '../../../../domain/use-cases/game/get_quests_use_case.dart';
import '../../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
import '../../../../domain/use-cases/game/move_player_use_case.dart';
import '../../../../domain/use-cases/game/start_game_use_case.dart';
import '../models/build_item_data.dart';
import '../models/forest_effect.dart';
import '../models/hud_data.dart';
import '../models/placement_data.dart';
import '../models/player_pose.dart';
import '../models/player_render_data.dart';
import '../models/quest_item_data.dart';

part 'forest_event.dart';
part 'forest_state.dart';

class ForestBloc extends Bloc<ForestEvent, ForestState> {
  final StartGameUseCase _startGameUseCase;
  final MovePlayerUseCase _movePlayerUseCase;
  final ChopTreeUseCase _chopTreeUseCase;
  final CanPlaceBuildingUseCase _canPlaceBuildingUseCase;
  final ConstructBuildingUseCase _constructBuildingUseCase;
  final AdvanceGameUseCase _advanceGameUseCase;
  final GetPlayerStatusUseCase _getPlayerStatusUseCase;
  final GetWorldSnapshotUseCase _getWorldSnapshotUseCase;
  final GetBuildOptionsUseCase _getBuildOptionsUseCase;
  final GetQuestsUseCase _getQuestsUseCase;
  final NavigationService _navigationService;

  PositionEntity? _lastPosition;
  Facing _facing = Facing.down;
  PlacementData? _placement;

  ForestBloc({
    required this._startGameUseCase,
    required this._movePlayerUseCase,
    required this._chopTreeUseCase,
    required this._canPlaceBuildingUseCase,
    required this._constructBuildingUseCase,
    required this._advanceGameUseCase,
    required this._getPlayerStatusUseCase,
    required this._getWorldSnapshotUseCase,
    required this._getBuildOptionsUseCase,
    required this._getQuestsUseCase,
    required this._navigationService,
  }) : super(const ForestInitial()) {
    on<ForestEvent>((event, emit) async {
      await switch (event) {
        ForestStarted() => _onStarted(event, emit),
        ForestTicked() => _onTicked(event, emit),
        ForestMapClicked() => _onMapClicked(event, emit),
        ForestPointerMoved() => _onPointerMoved(event, emit),
        ForestBuildRequested() => _onBuildRequested(event, emit),
        ForestPlacementCancelled() => _onPlacementCancelled(event, emit),
      };
    });
  }

  Future<void> _onStarted(ForestStarted event, Emitter<ForestState> emit) async {
    emit(ForestInProgress(data: state.data));
    try {
      _startGameUseCase();
      _lastPosition = _getPlayerStatusUseCase().position;
      emit(ForestSuccess(data: _buildData(effects: const [])));
    } on AppException catch (exception) {
      _navigationService.showErrorPopUp(
        title: exception.title,
        message: exception.message,
        buttonTitle: Internationalize.commonError,
      );
      emit(ForestFailure(data: state.data, exception: exception));
    }
  }

  Future<void> _onTicked(ForestTicked event, Emitter<ForestState> emit) async {}

  Future<void> _onMapClicked(ForestMapClicked event, Emitter<ForestState> emit) async {}

  Future<void> _onPointerMoved(ForestPointerMoved event, Emitter<ForestState> emit) async {}

  Future<void> _onBuildRequested(ForestBuildRequested event, Emitter<ForestState> emit) async {}

  Future<void> _onPlacementCancelled(ForestPlacementCancelled event, Emitter<ForestState> emit) async {}

  ForestData _buildData({required List<ForestEffect> effects}) {
    final status = _getPlayerStatusUseCase();
    final quests = _getQuestsUseCase();
    return state.data.copyWith(
      world: () => _getWorldSnapshotUseCase(),
      player: () => _playerRenderData(status),
      hud: () => _hudData(status, quests),
      placement: () => _placement,
      effects: effects,
    );
  }

  PlayerRenderData _playerRenderData(PlayerStatusEntity status) {
    final lastPosition = _lastPosition ?? status.position;
    final dx = status.position.x - lastPosition.x;
    final dy = status.position.y - lastPosition.y;
    final isMoving = dx != 0 || dy != 0;
    _lastPosition = status.position;

    final isWorking = status.activity == PlayerActivity.chopping || status.activity == PlayerActivity.constructing;
    final target = status.target;
    if (isWorking && target != null) {
      _facing = _facingFor(target.x - status.position.x, target.y - status.position.y);
    } else if (isMoving) {
      _facing = _facingFor(dx, dy);
    }

    final PlayerPose pose = switch ((isWorking, isMoving)) {
      (true, _) => WorkPose(
        tool: status.activity == PlayerActivity.chopping ? WorkTool.axe : WorkTool.hammer,
        swingProgress: status.swingProgress,
      ),
      (false, true) => WalkPose(withAxe: status.hasAxe),
      (false, false) => IdlePose(withAxe: status.hasAxe),
    };
    return PlayerRenderData(position: status.position, facing: _facing, pose: pose);
  }

  Facing _facingFor(double dx, double dy) {
    if (dx.abs() > dy.abs()) return dx < 0 ? Facing.left : Facing.right;
    return dy < 0 ? Facing.up : Facing.down;
  }

  HudData _hudData(PlayerStatusEntity status, List<QuestProgressEntity> quests) {
    return HudData(
      wood: status.wood,
      hasAxe: status.hasAxe,
      questBadge: '${quests.where((quest) => quest.isCompleted).length}/${quests.length}',
      quests: [for (final quest in quests) _questItem(quest)],
      buildItems: [for (final option in _getBuildOptionsUseCase()) _buildItem(option, wood: status.wood)],
      isBuildLocked: _placement != null,
    );
  }

  QuestItemData _questItem(QuestProgressEntity quest) {
    return QuestItemData(
      title: Internationalize.forestQuestTitle(id: quest.id),
      progressText: switch (quest) {
        QuestProgressEntity(isCompleted: true) => Internationalize.forestQuestDone,
        QuestProgressEntity(target: > 1) => '${quest.progress}/${quest.target}',
        _ => '',
      },
      status: switch (quest) {
        QuestProgressEntity(isCompleted: true) => QuestItemStatus.done,
        QuestProgressEntity(isCurrent: true) => QuestItemStatus.current,
        _ => QuestItemStatus.pending,
      },
    );
  }

  BuildItemData _buildItem(BuildOptionEntity option, {required int wood}) {
    return BuildItemData(
      blueprint: option.blueprint,
      name: Internationalize.forestBlueprint(id: option.blueprint),
      costText: Internationalize.forestCost(wood: option.woodCost),
      missingText: option.isAffordable ? null : Internationalize.forestMissing(wood: option.woodCost - wood),
      isEnabled: option.isAffordable,
    );
  }
}
```

- [ ] **Step 8: Ejecutar los tests y ver que pasan**

Run: `flutter test test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart`
Expected: `All tests passed!` (3 tests).

- [ ] **Step 9: Formatear y analizar**

Run: `dart format --line-length 120 lib/layers/presentation/features/forest/bloc test/mocks test/layers/presentation/features/forest/bloc && flutter analyze`
Expected: única excepción temporal a "cero avisos" de todo el plan, porque los handlers de esta tarea están vacíos: `warning • The value of the field '_movePlayerUseCase' isn't used • unused_field` (y lo mismo para `_chopTreeUseCase`, `_canPlaceBuildingUseCase`, `_constructBuildingUseCase`, `_advanceGameUseCase`) e `info • The private field _placement could be 'final' • prefer_final_fields`. Ningún otro aviso. La tarea 4 los hace desaparecer (su Step 5 exige `No issues found!`); no se añaden `// ignore`.

- [ ] **Step 10: Commit**

```bash
git add lib/layers/presentation/features/forest/bloc test/mocks/core/services test/mocks/presentation test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart
git commit -m "[PROJECT-X]: Add the forest bloc and start the game from it"
```

---

### Task 4: `ForestBloc` — bucle, clics, colocación y mensajes (port de `ForestViewModelTests`)

**Files:**
- Modify: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart` (fichero completo abajo)
- Test: `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`

**Interfaces:**
- Consumes: todo lo de la tarea 3; `ChopResult`, `ConstructionRejection` (fase 2); `ConstructionStartedEntity` / `ConstructionRejectedEntity`, los subtipos de `GameEventEntity` con los campos de README §3.2 (`itemId`, `treeId`, `wood`, `buildingId`, `progress`, `blueprint`, `questId`); `Rules.chopIntervalMs`, `Rules.hitsToFellTree`, `Rules.hammerIntervalMs`.
- Produces (contrato para las fases 6 y 7):
  - `ForestTicked`: la primera vez lanza el snackbar de bienvenida; avanza la simulación; cada `GameEventEntity` produce su mensaje y/o efecto (tabla de abajo); `TreeHitEffect`/`TreeFelledEffect` llevan `fromX` = x del jugador **antes** del tick.
  - `ForestMapClicked`: con colocación activa, secundario cancela y primario intenta construir; sin colocación, secundario no hace nada, con `treeId` ordena talar (snackbar si no hay hacha) y sin `treeId` camina al punto.
  - `ForestPointerMoved`: mueve la colocación y recalcula `isValid`.
  - `ForestBuildRequested`: si no se puede pagar, snackbar; si se puede, abre la colocación en la posición del jugador, la valida y muestra el snackbar de colocación.
  - `ForestPlacementCancelled`: cierra la colocación.
  - Cada evento (salvo antes de arrancar) emite `ForestSuccess` con los efectos de ese evento.

| `GameEventEntity` | Snackbar | `ForestEffect` |
|---|---|---|
| `ItemPickedUpEventEntity` | `forestMessagePickedUpAxe` | `ItemPickedUpEffect(itemId)` |
| `PlayerBlockedEventEntity` | `forestMessageBlockedPath` | — |
| `TreeHitEventEntity` | — | `TreeHitEffect(treeId, fromX)` |
| `TreeFelledEventEntity` | `forestMessageWoodGained(wood)` | `TreeFelledEffect(treeId, fromX)` |
| `BuildingHammeredEventEntity` | — | `BuildingHammeredEffect(buildingId, progress)` |
| `BuildingCompletedEventEntity` | `forestMessageBuildingCompleted(nombre)` | `BuildingCompletedEffect(buildingId)` |
| `QuestCompletedEventEntity` | `forestMessageAllQuestsCompleted` si todas están hechas; si no, `forestMessageQuestCompleted(título)` | — |

- [ ] **Step 1: Escribir los tests que fallan**

Cada test de `ForestViewModelTests.kt` (9) con el mismo nombre, mismos datos y mismas comprobaciones, más tres nuevos: cancelar la colocación con el botón, el orden de eventos (README §6) y que cada emisión solo lleva sus propios efectos.

```dart
// test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
import 'package:rpg/layers/domain/rules/rules.dart';
import 'package:rpg/layers/domain/world/world.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../../mocks/presentation/features/forest/forest_bloc_mock.dart';
import '../../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';

void main() {
  late MockNavigationService navigationService;
  late List<ForestEffect> effects;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    navigationService = MockNavigationService();
    effects = [];
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenFirstTickThenGreetsAndShowsTheQuestList',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final hud = bloc.state.data.hud!;
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains('Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.'),
      );
      expect(hud.questBadge, '0/3');
      expect(hud.quests[0], const QuestItemData(title: 'Recoge el hacha', progressText: '', status: QuestItemStatus.current));
      expect(
        hud.quests[1],
        const QuestItemData(
          title: 'Consigue al menos 15 de madera',
          progressText: '0/15',
          status: QuestItemStatus.pending,
        ),
      );
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenClickingEmptyGroundThenWalksThereFacingIt',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast));
      ForestBlocMock.tickFor(bloc, 1000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.player!.position, ForestScenarioMock.groundEast);
      expect(bloc.state.data.player!.facing, Facing.right);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenClickingATreeWithoutAxeThenExplainsWhy',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.treeEast(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.eastTreeCanopy, treeId: 'tree-1'));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(ForestBlocMock.shownMessages(navigationService), contains('Necesitas un hacha para talar.'));
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenPickingUpTheAxeThenPlaysEffectAnnouncesAndHoldsIt',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.axeNextToPlayer(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      effects = ForestBlocMock.collectEffects(bloc);
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.axeSpot));
      ForestBlocMock.tickFor(bloc, 300);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(effects, contains(const ItemPickedUpEffect(itemId: 'axe-1')));
      expect(
        ForestBlocMock.shownMessages(navigationService),
        contains('¡Hacha recogida! Haz clic en un árbol para talarlo.'),
      );
      expect(bloc.state.data.hud!.hasAxe, isTrue);
      expect(bloc.state.data.player!.pose, const IdlePose(withAxe: true));
    },
  );

  group('testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall', () {
    late Facing facing;
    late PlayerPose pose;

    blocTest<ForestBloc, ForestState>(
      'testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall',
      build: () {
        // given
        return ForestBlocMock.make(ForestScenarioMock.axeInHandWithTree(), navigationService: navigationService);
      },
      act: (bloc) async {
        // when
        effects = ForestBlocMock.collectEffects(bloc);
        bloc
          ..add(const ForestStarted())
          ..add(const ForestMapClicked(position: ForestScenarioMock.treeCanopy, treeId: 'tree-1'));
        ForestBlocMock.tickFor(bloc, 1500);
        await ForestBlocMock.processEvents();
        facing = bloc.state.data.player!.facing;
        pose = bloc.state.data.player!.pose;
        ForestBlocMock.tickFor(bloc, Rules.chopIntervalMs * Rules.hitsToFellTree);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(facing, Facing.right);
        expect(pose, isA<WorkPose>());
        expect((pose as WorkPose).tool, WorkTool.axe);
        expect(effects.whereType<TreeHitEffect>().length, 5);
        expect(effects, contains(const TreeFelledEffect(treeId: 'tree-1', fromX: 180)));
        expect(bloc.state.data.hud!.wood, 6);
      },
    );
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenWoodIsNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.tenWood(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs))
        ..add(const ForestBuildRequested(blueprint: BlueprintId.house));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.hud!.buildItems, const [
        BuildItemData(
          blueprint: BlueprintId.house,
          name: 'Casa',
          costText: '15 de madera',
          missingText: 'Faltan 5',
          isEnabled: false,
        ),
      ]);
      expect(bloc.state.data.placement, isNull);
      expect(ForestBlocMock.shownMessages(navigationService), contains('No tienes madera suficiente.'));
    },
  );

  group('testWhenPlacingThenPreviewsValidityIgnoresBlockedSitesAndPlacesOnAFreeOne', () {
    late PlacementData? preview;
    late bool isLockedWhilePlacing;
    late PlacementData? stillPlacing;

    blocTest<ForestBloc, ForestState>(
      'testWhenPlacingThenPreviewsValidityIgnoresBlockedSitesAndPlacesOnAFreeOne',
      build: () {
        // given
        return ForestBlocMock.make(ForestScenarioMock.fifteenWoodWithFarTree(), navigationService: navigationService);
      },
      act: (bloc) async {
        // when
        effects = ForestBlocMock.collectEffects(bloc);
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestPointerMoved(position: ForestScenarioMock.siteNextToFarTree));
        await ForestBlocMock.processEvents();
        preview = bloc.state.data.placement;
        isLockedWhilePlacing = bloc.state.data.hud!.isBuildLocked;
        bloc.add(const ForestMapClicked(position: ForestScenarioMock.siteNextToFarTree));
        await ForestBlocMock.processEvents();
        stillPlacing = bloc.state.data.placement;
        bloc.add(const ForestMapClicked(position: ForestScenarioMock.freeSite));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(
          preview,
          const PlacementData(
            blueprint: BlueprintId.house,
            position: ForestScenarioMock.siteNextToFarTree,
            isValid: false,
          ),
        );
        expect(isLockedWhilePlacing, isTrue);
        expect(stillPlacing, isNotNull);
        expect(ForestBlocMock.shownMessages(navigationService), contains('Ahí no cabe. Busca un sitio despejado.'));
        final placed = effects.whereType<BuildingPlacedEffect>().single;
        expect(placed.building.id, 'building-1');
        expect(placed.building.position, ForestScenarioMock.freeSite);
        expect(bloc.state.data.placement, isNull);
      },
    );
  });

  group('testWhenSecondaryClickWhilePlacingThenCancelsWithoutBuilding', () {
    late World world;

    blocTest<ForestBloc, ForestState>(
      'testWhenSecondaryClickWhilePlacingThenCancelsWithoutBuilding',
      build: () {
        // given
        world = ForestScenarioMock.fifteenWood();
        return ForestBlocMock.make(world, navigationService: navigationService);
      },
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestMapClicked(position: ForestScenarioMock.farSite, isSecondary: true));
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.placement, isNull);
        expect(world.buildings, isEmpty);
        expect(bloc.state.data.hud!.isBuildLocked, isFalse);
      },
    );
  });

  group('testWhenCancellingThePlacementThenClosesItWithoutBuilding', () {
    late World world;

    blocTest<ForestBloc, ForestState>(
      'testWhenCancellingThePlacementThenClosesItWithoutBuilding',
      build: () {
        // given
        world = ForestScenarioMock.fifteenWood();
        return ForestBlocMock.make(world, navigationService: navigationService);
      },
      act: (bloc) {
        // when
        bloc
          ..add(const ForestStarted())
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestPlacementCancelled());
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(bloc.state.data.placement, isNull);
        expect(world.buildings, isEmpty);
        expect(bloc.state.data.hud!.isBuildLocked, isFalse);
        expect(
          ForestBlocMock.shownMessages(navigationService),
          contains('Elige dónde construir: Casa. Clic derecho o Esc para cancelar.'),
        );
      },
    );
  });

  group('testWhenTheLastQuestIsCompletedThenShowsTheFinalMessage', () {
    late String badgeBefore;

    blocTest<ForestBloc, ForestState>(
      'testWhenTheLastQuestIsCompletedThenShowsTheFinalMessage',
      build: () {
        // given
        return ForestBlocMock.make(ForestScenarioMock.axeAndFifteenWood(), navigationService: navigationService);
      },
      act: (bloc) async {
        // when
        effects = ForestBlocMock.collectEffects(bloc);
        bloc
          ..add(const ForestStarted())
          ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
        await ForestBlocMock.processEvents();
        badgeBefore = bloc.state.data.hud!.questBadge;
        bloc
          ..add(const ForestBuildRequested(blueprint: BlueprintId.house))
          ..add(const ForestMapClicked(position: ForestScenarioMock.houseSiteEast));
        ForestBlocMock.tickFor(bloc, 6000 + Rules.hammerIntervalMs * 8);
      },
      wait: Duration.zero,
      verify: (bloc) {
        // then
        expect(badgeBefore, '2/3');
        expect(effects, contains(const BuildingCompletedEffect(buildingId: 'building-1')));
        expect(bloc.state.data.hud!.questBadge, '3/3');
        expect(ForestBlocMock.shownMessages(navigationService).last, '¡Has completado todas las misiones!');
      },
    );
  });

  blocTest<ForestBloc, ForestState>(
    'testWhenEventsArriveInOrderThenTheLastClickWins',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.empty(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.groundEast));
      ForestBlocMock.tickFor(bloc, 320);
      bloc.add(const ForestMapClicked(position: ForestScenarioMock.playerStart));
      ForestBlocMock.tickFor(bloc, 1000);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.player!.position, ForestScenarioMock.playerStart);
      expect(bloc.state.data.player!.facing, Facing.left);
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenEachEventEmitsThenOnlyCarriesItsOwnEffects',
    build: () {
      // given
      return ForestBlocMock.make(ForestScenarioMock.axeNextToPlayer(), navigationService: navigationService);
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs))
        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      expect(bloc.state.data.effects, isEmpty);
    },
  );
}
```

`axeNextToPlayer` coloca el hacha a 10 unidades del jugador (dentro de `Rules.pickUpRange`): se recoge en el primer tick, así que el segundo no trae efectos.

- [ ] **Step 2: Ejecutar los tests y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`
Expected: FAIL. Fallan todos salvo `testWhenEachEventEmitsThenOnlyCarriesItsOwnEffects` y `testWhenSecondaryClickWhilePlacingThenCancelsWithoutBuilding` (con los handlers vacíos no hay colocación ni edificios, así que sus comprobaciones ya se cumplen; pasan de verdad tras el Step 3): p. ej. `testWhenFirstTickThenGreetsAndShowsTheQuestList` con `No matching calls` en `shownMessages` y `testWhenClickingEmptyGroundThenWalksThereFacingIt` con `Expected: PositionEntity(150.0, 100.0) Actual: PositionEntity(100.0, 100.0)` (el texto exacto depende del `toString` de la fase 2).

- [ ] **Step 3: Implementar el BLoC completo**

Sustituir el fichero entero por:

```dart
// lib/layers/presentation/features/forest/bloc/forest_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/chop_result.dart';
import '../../../../../core/config/constants/enum/construction_rejection.dart';
import '../../../../../core/config/constants/enum/forest/facing.dart';
import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../../../core/config/constants/enum/forest/work_tool.dart';
import '../../../../../core/config/constants/enum/player_activity.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../../core/services/navigation/source/navigation_service.dart';
import '../../../../domain/entities/game/build_option_entity.dart';
import '../../../../domain/entities/game/construction_result_entity.dart';
import '../../../../domain/entities/game/game_event_entity.dart';
import '../../../../domain/entities/game/player_status_entity.dart';
import '../../../../domain/entities/game/quest_progress_entity.dart';
import '../../../../domain/entities/game/world_snapshot_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/use-cases/game/advance_game_use_case.dart';
import '../../../../domain/use-cases/game/can_place_building_use_case.dart';
import '../../../../domain/use-cases/game/chop_tree_use_case.dart';
import '../../../../domain/use-cases/game/construct_building_use_case.dart';
import '../../../../domain/use-cases/game/get_build_options_use_case.dart';
import '../../../../domain/use-cases/game/get_player_status_use_case.dart';
import '../../../../domain/use-cases/game/get_quests_use_case.dart';
import '../../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
import '../../../../domain/use-cases/game/move_player_use_case.dart';
import '../../../../domain/use-cases/game/start_game_use_case.dart';
import '../models/build_item_data.dart';
import '../models/forest_effect.dart';
import '../models/hud_data.dart';
import '../models/placement_data.dart';
import '../models/player_pose.dart';
import '../models/player_render_data.dart';
import '../models/quest_item_data.dart';

part 'forest_event.dart';
part 'forest_state.dart';

class ForestBloc extends Bloc<ForestEvent, ForestState> {
  final StartGameUseCase _startGameUseCase;
  final MovePlayerUseCase _movePlayerUseCase;
  final ChopTreeUseCase _chopTreeUseCase;
  final CanPlaceBuildingUseCase _canPlaceBuildingUseCase;
  final ConstructBuildingUseCase _constructBuildingUseCase;
  final AdvanceGameUseCase _advanceGameUseCase;
  final GetPlayerStatusUseCase _getPlayerStatusUseCase;
  final GetWorldSnapshotUseCase _getWorldSnapshotUseCase;
  final GetBuildOptionsUseCase _getBuildOptionsUseCase;
  final GetQuestsUseCase _getQuestsUseCase;
  final NavigationService _navigationService;

  PositionEntity? _lastPosition;
  Facing _facing = Facing.down;
  PlacementData? _placement;
  bool _hasGreeted = false;

  ForestBloc({
    required this._startGameUseCase,
    required this._movePlayerUseCase,
    required this._chopTreeUseCase,
    required this._canPlaceBuildingUseCase,
    required this._constructBuildingUseCase,
    required this._advanceGameUseCase,
    required this._getPlayerStatusUseCase,
    required this._getWorldSnapshotUseCase,
    required this._getBuildOptionsUseCase,
    required this._getQuestsUseCase,
    required this._navigationService,
  }) : super(const ForestInitial()) {
    on<ForestEvent>((event, emit) async {
      await switch (event) {
        ForestStarted() => _onStarted(event, emit),
        ForestTicked() => _onTicked(event, emit),
        ForestMapClicked() => _onMapClicked(event, emit),
        ForestPointerMoved() => _onPointerMoved(event, emit),
        ForestBuildRequested() => _onBuildRequested(event, emit),
        ForestPlacementCancelled() => _onPlacementCancelled(event, emit),
      };
    });
  }

  Future<void> _onStarted(ForestStarted event, Emitter<ForestState> emit) async {
    emit(ForestInProgress(data: state.data));
    try {
      _startGameUseCase();
      _lastPosition = _getPlayerStatusUseCase().position;
      emit(ForestSuccess(data: _buildData(effects: const [])));
    } on AppException catch (exception) {
      _navigationService.showErrorPopUp(
        title: exception.title,
        message: exception.message,
        buttonTitle: Internationalize.commonError,
      );
      emit(ForestFailure(data: state.data, exception: exception));
    }
  }

  Future<void> _onTicked(ForestTicked event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    if (!_hasGreeted) {
      _hasGreeted = true;
      _showMessage(Internationalize.forestMessageWelcome);
    }
    final effects = <ForestEffect>[];
    final fromX = _getPlayerStatusUseCase().position.x;
    for (final gameEvent in _advanceGameUseCase(deltaMs: event.deltaMs)) {
      _react(gameEvent, fromX: fromX, effects: effects);
    }
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }

  Future<void> _onMapClicked(ForestMapClicked event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    final effects = <ForestEffect>[];
    final placement = _placement;
    if (placement != null) {
      if (event.isSecondary) {
        _placement = null;
      } else {
        _place(placement.blueprint, event.position, effects: effects);
      }
    } else if (!event.isSecondary) {
      _orderAt(event.position, treeId: event.treeId);
    }
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }

  Future<void> _onPointerMoved(ForestPointerMoved event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _movePlacement(event.position);
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }

  Future<void> _onBuildRequested(ForestBuildRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _openPlacement(event.blueprint);
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }

  Future<void> _onPlacementCancelled(ForestPlacementCancelled event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    _placement = null;
    emit(ForestSuccess(data: _buildData(effects: const [])));
  }

  void _orderAt(PositionEntity position, {required String? treeId}) {
    if (treeId == null) {
      _movePlayerUseCase(x: position.x, y: position.y);
      return;
    }
    if (_chopTreeUseCase(treeId: treeId) == ChopResult.noAxe) {
      _showMessage(Internationalize.forestMessageNeedAxe);
    }
  }

  void _movePlacement(PositionEntity position) {
    final placement = _placement;
    if (placement == null) return;
    _placement = placement.copyWith(
      position: position,
      isValid: _canPlaceBuildingUseCase(blueprint: placement.blueprint, x: position.x, y: position.y),
    );
  }

  void _openPlacement(BlueprintId blueprint) {
    final options = _getBuildOptionsUseCase().where((option) => option.blueprint == blueprint);
    if (options.isEmpty || !options.first.isAffordable) {
      _showMessage(Internationalize.forestMessageNotEnoughWood);
      return;
    }
    final position = _lastPosition ?? _getPlayerStatusUseCase().position;
    _placement = PlacementData(blueprint: blueprint, position: position, isValid: false);
    _movePlacement(position);
    _showMessage(Internationalize.forestMessagePlacing(name: Internationalize.forestBlueprint(id: blueprint)));
  }

  void _place(BlueprintId blueprint, PositionEntity position, {required List<ForestEffect> effects}) {
    switch (_constructBuildingUseCase(blueprint: blueprint, x: position.x, y: position.y)) {
      case ConstructionStartedEntity(:final building):
        _placement = null;
        _showMessage(Internationalize.forestMessageBuildingStarted);
        effects.add(BuildingPlacedEffect(building: building));
      case ConstructionRejectedEntity(reason: ConstructionRejection.blocked):
        _showMessage(Internationalize.forestMessageBlockedSite);
      case ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood):
        _placement = null;
        _showMessage(Internationalize.forestMessageNotEnoughWood);
    }
  }

  void _react(GameEventEntity gameEvent, {required double fromX, required List<ForestEffect> effects}) {
    switch (gameEvent) {
      case ItemPickedUpEventEntity(:final itemId):
        _showMessage(Internationalize.forestMessagePickedUpAxe);
        effects.add(ItemPickedUpEffect(itemId: itemId));
      case PlayerBlockedEventEntity():
        _showMessage(Internationalize.forestMessageBlockedPath);
      case TreeHitEventEntity(:final treeId):
        effects.add(TreeHitEffect(treeId: treeId, fromX: fromX));
      case TreeFelledEventEntity(:final treeId, :final wood):
        _showMessage(Internationalize.forestMessageWoodGained(wood: wood));
        effects.add(TreeFelledEffect(treeId: treeId, fromX: fromX));
      case BuildingHammeredEventEntity(:final buildingId, :final progress):
        effects.add(BuildingHammeredEffect(buildingId: buildingId, progress: progress));
      case BuildingCompletedEventEntity(:final buildingId, :final blueprint):
        _showMessage(
          Internationalize.forestMessageBuildingCompleted(name: Internationalize.forestBlueprint(id: blueprint)),
        );
        effects.add(BuildingCompletedEffect(buildingId: buildingId));
      case QuestCompletedEventEntity(:final questId):
        final allDone = _getQuestsUseCase().every((quest) => quest.isCompleted);
        _showMessage(
          allDone
              ? Internationalize.forestMessageAllQuestsCompleted
              : Internationalize.forestMessageQuestCompleted(title: Internationalize.forestQuestTitle(id: questId)),
        );
    }
  }

  void _showMessage(String message) {
    _navigationService.showSnackbar(message: message);
  }

  ForestData _buildData({required List<ForestEffect> effects}) {
    final status = _getPlayerStatusUseCase();
    final quests = _getQuestsUseCase();
    return state.data.copyWith(
      world: () => _getWorldSnapshotUseCase(),
      player: () => _playerRenderData(status),
      hud: () => _hudData(status, quests),
      placement: () => _placement,
      effects: effects,
    );
  }

  PlayerRenderData _playerRenderData(PlayerStatusEntity status) {
    final lastPosition = _lastPosition ?? status.position;
    final dx = status.position.x - lastPosition.x;
    final dy = status.position.y - lastPosition.y;
    final isMoving = dx != 0 || dy != 0;
    _lastPosition = status.position;

    final isWorking = status.activity == PlayerActivity.chopping || status.activity == PlayerActivity.constructing;
    final target = status.target;
    if (isWorking && target != null) {
      _facing = _facingFor(target.x - status.position.x, target.y - status.position.y);
    } else if (isMoving) {
      _facing = _facingFor(dx, dy);
    }

    final PlayerPose pose = switch ((isWorking, isMoving)) {
      (true, _) => WorkPose(
        tool: status.activity == PlayerActivity.chopping ? WorkTool.axe : WorkTool.hammer,
        swingProgress: status.swingProgress,
      ),
      (false, true) => WalkPose(withAxe: status.hasAxe),
      (false, false) => IdlePose(withAxe: status.hasAxe),
    };
    return PlayerRenderData(position: status.position, facing: _facing, pose: pose);
  }

  Facing _facingFor(double dx, double dy) {
    if (dx.abs() > dy.abs()) return dx < 0 ? Facing.left : Facing.right;
    return dy < 0 ? Facing.up : Facing.down;
  }

  HudData _hudData(PlayerStatusEntity status, List<QuestProgressEntity> quests) {
    return HudData(
      wood: status.wood,
      hasAxe: status.hasAxe,
      questBadge: '${quests.where((quest) => quest.isCompleted).length}/${quests.length}',
      quests: [for (final quest in quests) _questItem(quest)],
      buildItems: [for (final option in _getBuildOptionsUseCase()) _buildItem(option, wood: status.wood)],
      isBuildLocked: _placement != null,
    );
  }

  QuestItemData _questItem(QuestProgressEntity quest) {
    return QuestItemData(
      title: Internationalize.forestQuestTitle(id: quest.id),
      progressText: switch (quest) {
        QuestProgressEntity(isCompleted: true) => Internationalize.forestQuestDone,
        QuestProgressEntity(target: > 1) => '${quest.progress}/${quest.target}',
        _ => '',
      },
      status: switch (quest) {
        QuestProgressEntity(isCompleted: true) => QuestItemStatus.done,
        QuestProgressEntity(isCurrent: true) => QuestItemStatus.current,
        _ => QuestItemStatus.pending,
      },
    );
  }

  BuildItemData _buildItem(BuildOptionEntity option, {required int wood}) {
    return BuildItemData(
      blueprint: option.blueprint,
      name: Internationalize.forestBlueprint(id: option.blueprint),
      costText: Internationalize.forestCost(wood: option.woodCost),
      missingText: option.isAffordable ? null : Internationalize.forestMissing(wood: option.woodCost - wood),
      isEnabled: option.isAffordable,
    );
  }
}
```

- [ ] **Step 4: Ejecutar los tests y ver que pasan**

Run: `flutter test test/layers/presentation/features/forest`
Expected: `All tests passed!` (8 de modelos + 3 de arranque + 12 de comportamiento = 23 tests).

Si `testWhenEventsArriveInOrderThenTheLastClickWins` falla por la posición, comprobar la velocidad de `PlayerEntityMock.mock` (100 u/s): en 320 ms el jugador avanza 32 unidades hacia (150,100) y en 1000 ms vuelve de sobra a (100,100). Ese test **no** se ajusta cambiando números: si falla, los eventos se están procesando fuera de orden (p. ej. alguien añadió un `await` real a un handler o un `transformer:` a `on<ForestEvent>`).

- [ ] **Step 5: Formatear, analizar y suite completa**

Run: `dart format --line-length 120 lib/layers/presentation/features/forest test/layers/presentation/features/forest test/mocks && flutter analyze && flutter test`
Expected: `No issues found!` y `All tests passed!` (incluido `test/architecture_test.dart`: la presentación no importa `data/`).

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/features/forest/bloc/forest_bloc.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
git commit -m "[PROJECT-X]: Port the forest screen logic to the forest bloc"
```

---

### Task 5: Cierre de la fase

**Files:**
- Modify: `docs/boost/plans/2026-10-05-flutter-migration/README.md` (sección 7, solo si hubo desviaciones)

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: fase 5 cerrada; contrato del BLoC listo para las fases 6 (Flame lee `state.data.world`, `player`, `placement` y reproduce `effects` de cada emisión) y 7 (`ForestPage` crea el BLoC con `locator.get<T>()` y el HUD lee `state.data.hud`).

- [ ] **Step 1: Comprobar que no queda texto en español fuera de `es.json`**

Run: `grep -rnE "madera|hacha|Construir|Misiones|árbol" lib --include=*.dart`
Expected: sin salida.

- [ ] **Step 2: Comprobar que el BLoC no conoce Flame, datos ni widgets**

Run: `grep -nE "package:flame|layers/data|package:flutter/(material|widgets)" lib/layers/presentation/features/forest/bloc/*.dart lib/layers/presentation/features/forest/models/*.dart`
Expected: sin salida.

- [ ] **Step 3: Suite completa**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` y `All tests passed!`

- [ ] **Step 4: Anotar desviaciones**

Si durante la fase hubo que cambiar algún nombre o firma respecto a README §3, añadir una línea por desviación en la sección 7 del README (qué, por qué, commit). Si no hubo ninguna, no tocar el README.

```bash
git add docs/boost/plans/2026-10-05-flutter-migration/README.md
git commit -m "[PROJECT-X]: Record phase 5 notes in the Flutter migration plan"
```

(Solo si el README cambió.)
