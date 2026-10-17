# F4 · Misiones, capítulo 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 1) |
| **Rama** | `feature/PROJECT-F4-quests-chapter-1`, desde `feature/PROJECT-X-town` (develop con la arena C0–C13, "empezar con el hacha", F1 y F3) |
| **Depende de** | F3 |
| **Issue / milestone** | `phase:F4` · milestone `F4 Quests chapter 1` |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-village/F4-quests-chapter-1.md`, merge `3e60655` (`[PROJECT-F4]: Merge the first quest chapter`), commits `19f276d` (estadísticas), `ba4b176` (misiones), `a38f26b` (panel plegado) |

**Goal:** Que haya metas después de la primera casa, usando solo mecánicas que ya existen.

**Architecture:** Dominio: `StatsEntity` en `WorldState.stats` (expuesta por `World.stats`), que un sistema interno `StatsRecording` actualiza **al final** de `World.advance` con los eventos del tick; cinco misiones nuevas de la aldea en `Quests.all` que miden `stats`, `funds` y las casas terminadas (`BuildingListRules.completeCount`). Presentación: `ForestBloc._hudData` recorta las filas por línea (una fila plegada "N hechas", la actual y como mucho dos pendientes) y `QuestRow` pinta la fila plegada.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`, `easy_localization` (`plural`). Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario, 2026-10-17):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Mientras `test/` no compila no se usa `flutter analyze` a secas.
- No cambia la inyección de dependencias (ningún constructor de caso de uso cambia): no se tocan `di.config.dart` ni `*.mocks.dart`.
- Textos solo en `es.json`, leídos por `Internationalize`; el plural con `plural()` de `easy_localization`.
- Sin comentarios en `lib/`; imports relativos; `switch` exhaustivos en el orden de declaración; títulos de commit `[PROJECT-F4]: <frase en inglés en imperativo>`.

## Decisiones

Las de la ficha (comprobadas en iOS) más las que salen de Flutter:

1. **Estadísticas:** `StatsEntity({treesFelled = 0, treesFelledByKind = const {}, buildingsCompleted = 0, treesRegrown = 0})` en `domain/entities/game/stats_entity.dart`, con `copyWith`, `==`/`hashCode` (`MapEquality`, como `HeroEntity`) y `assert` de no negativos.
   - **Desviación:** iOS también comprueba que los valores por tipo son > 0 y que su suma no pasa de `treesFelled`. Aquí el constructor es `const` (convención de entidades y `const StatsEntity()` en `WorldState`) y un `assert` que recorre el mapa no es constante, así que esas dos comprobaciones no están; las mantiene `StatsRules`, la única que crea estadísticas.
2. **Operaciones** en la extensión `StatsRules` (`domain/world/extensions/stats_rules.dart`, E2), como `Stats+Rules.swift`: `treesFelledOf(kind)` (0 si no hay), `fellingTree(TreeKind? kind)` (sin tipo, solo sube `treesFelled`), `completingBuilding()`, `regrowingTree()`. El mapa nuevo es `Map.unmodifiable`.
3. **`StatsRecording`** (`domain/world/stats_recording.dart`, `abstract final class` con `static void record(WorldState, List<GameEventEntity>)`; pieza interna, se añade a `_worldInternals` de `test/architecture_test.dart` en T1). Va **al final** de `World.advance`, después de `pickUpItems`, y recorre los eventos en orden con un `switch` exhaustivo. El tipo del árbol talado sale del tocón de F3 (`state.stumps[treeId]?.kind`), que siempre existe al final del tick de la tala (`Regrowth` va lo primero). Cuenta `TreeFelledEventEntity`, `BuildingCompletedEventEntity` y `TreeRegrownEventEntity`; el resto no cambia nada. `buildingsCompleted` se guarda aunque ninguna misión lo lea todavía.
4. **Mismo tick:** `AdvanceGameUseCase` llama a `QuestLog.update` después de `World.advance`, así que la misión que lee `stats` se cumple en el tick del evento. No cambia ningún caso de uso.
5. **Misiones nuevas** (`QuestLine.village`), en `Quests.all` justo después de `buildHouse` y antes de `buildForge`; en `QuestId`, al final del enum, en este orden:

| Misión | Objetivo | Texto (`forest.quest.*`) | Mide |
|---|---|---|---|
| `fellTenTrees` | 10 | Tala 10 árboles | `world.stats.treesFelled` |
| `fellAnOak` | 1 | Tala un roble | `world.stats.treesFelledOf(TreeKind.oak)` |
| `gatherFortyWood` | 40 | Ten 40 de madera a la vez | `world.funds.amount(Resource.wood)` (el inventario hasta F6, el almacén desde F6 sin tocar la misión) |
| `buildTwoHouses` | 2 | Ten 2 casas terminadas | `world.buildings.completeCount(BlueprintId.house)` (nuevo en `BuildingListRules`) |
| `seeATreeRegrow` | 1 | Ve rebrotar un árbol | `world.stats.treesRegrown` |

   - La aldea pasa a 7 misiones y el total a 15 (`0/15` al empezar; la insignia sigue contando todas). Se pueden cumplir fuera de orden; `QuestLog` es pegajoso, así que gastar madera no deshace `gatherFortyWood`.
   - El aviso de línea completa ("¡Has completado las misiones de Aldea!") llega ahora con la séptima: `_announceQuests` ya mira la línea entera, no cambia.
   - Diferencia con iOS ya presente en Flutter: no hay misión del hacha (iOS tiene 8 en la aldea y 16 en total).
6. **Panel plegado:** el recorte lo hace `ForestBloc._hudData` (la vista no tiene lógica). Por línea, en el orden de `QuestLine.values`:
   - si hay hechas, **una** fila `QuestItemStatus.folded` (al final del enum) con título `Internationalize.forestQuestsDone(count:)` y `progressText` vacío;
   - después la actual;
   - después como mucho `HudData.pendingQuestsShown = 2` pendientes, en el orden del catálogo.
   - Con la línea entera hecha queda solo la plegada. `QuestItemStatus.done` y su rama de `_questItem` se mantienen en el modelo aunque el HUD ya no los enseñe.
   - **Desviación:** iOS crea la fila plegada con `QuestItemData.init(line:doneCount:)`, que lee el texto. Aquí los modelos no leen `Internationalize` (los arma el bloc, como `_questItem`), así que `quest_item_data.dart` no cambia y la fila se construye en el bloc.
7. **Fila plegada** (`QuestRow`): casilla marcada (como `done`, color `questDone`), título apagado (`hudMuted`) **sin tachar**, sin progreso.
8. **Plural:** `forest.hud.questsDone` = `{"one": "{count} hecha", "other": "{count} hechas"}`, leído con `'…'.plural(count, namedArgs: {'count': '$count'})`.
9. **Guardado:** en F2 (`WorldState.stats` y las misiones completadas).

## Reparto

| Tarea | Qué |
|---|---|
| TF4.1 | Estadísticas del mundo (dominio) |
| TF4.2 | Cinco misiones nuevas de la aldea |
| TF4.3 | Misiones hechas plegadas en el panel |
| TF4.4 | Cierre: T1, `PROGRESS.md`, README, `CLAUDE.md` |

---

### Task TF4.1: Estadísticas del mundo

**Files:**
- Create: `lib/layers/domain/entities/game/stats_entity.dart`, `lib/layers/domain/world/extensions/stats_rules.dart`, `lib/layers/domain/world/stats_recording.dart`
- Modify: `lib/layers/domain/world/world_state.dart`, `lib/layers/domain/world/world.dart`

**Interfaces:**
- Consumes: `WorldState.stumps` (F3), los eventos de `game_event_entity.dart`.
- Produces:
  - `StatsEntity({int treesFelled = 0, Map<TreeKind, int> treesFelledByKind = const {}, int buildingsCompleted = 0, int treesRegrown = 0})`.
  - `extension StatsRules on StatsEntity { int treesFelledOf(TreeKind kind); StatsEntity fellingTree(TreeKind? kind); StatsEntity completingBuilding(); StatsEntity regrowingTree(); }`.
  - `WorldState.stats` (`StatsEntity`, mutable, `const StatsEntity()` al empezar), `World.stats`.
  - `StatsRecording.record(WorldState state, List<GameEventEntity> events)`.

- [ ] **Step 1: `stats_entity.dart`** (nuevo)

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/tree_kind.dart';

class StatsEntity {
  final int treesFelled;
  final Map<TreeKind, int> treesFelledByKind;
  final int buildingsCompleted;
  final int treesRegrown;

  const StatsEntity({
    this.treesFelled = 0,
    this.treesFelledByKind = const {},
    this.buildingsCompleted = 0,
    this.treesRegrown = 0,
  }) : assert(treesFelled >= 0),
       assert(buildingsCompleted >= 0),
       assert(treesRegrown >= 0);

  StatsEntity copyWith({
    int? treesFelled,
    Map<TreeKind, int>? treesFelledByKind,
    int? buildingsCompleted,
    int? treesRegrown,
  }) {
    return StatsEntity(
      treesFelled: treesFelled ?? this.treesFelled,
      treesFelledByKind: treesFelledByKind ?? this.treesFelledByKind,
      buildingsCompleted: buildingsCompleted ?? this.buildingsCompleted,
      treesRegrown: treesRegrown ?? this.treesRegrown,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StatsEntity &&
      other.treesFelled == treesFelled &&
      const MapEquality<TreeKind, int>().equals(other.treesFelledByKind, treesFelledByKind) &&
      other.buildingsCompleted == buildingsCompleted &&
      other.treesRegrown == treesRegrown;

  @override
  int get hashCode => Object.hash(
    treesFelled,
    const MapEquality<TreeKind, int>().hash(treesFelledByKind),
    buildingsCompleted,
    treesRegrown,
  );
}
```

- [ ] **Step 2: `stats_rules.dart`** (nuevo)

```dart
import '../../../../core/config/constants/enum/tree_kind.dart';
import '../../entities/game/stats_entity.dart';

extension StatsRules on StatsEntity {
  int treesFelledOf(TreeKind kind) => treesFelledByKind[kind] ?? 0;

  StatsEntity fellingTree(TreeKind? kind) => copyWith(
    treesFelled: treesFelled + 1,
    treesFelledByKind: kind == null ? null : Map.unmodifiable({...treesFelledByKind, kind: treesFelledOf(kind) + 1}),
  );

  StatsEntity completingBuilding() => copyWith(buildingsCompleted: buildingsCompleted + 1);

  StatsEntity regrowingTree() => copyWith(treesRegrown: treesRegrown + 1);
}
```

- [ ] **Step 3: `stats_recording.dart`** (nuevo)

```dart
import '../entities/game/game_event_entity.dart';
import '../entities/game/stats_entity.dart';
import 'extensions/stats_rules.dart';
import 'world_state.dart';

abstract final class StatsRecording {
  static void record(WorldState state, List<GameEventEntity> events) {
    for (final event in events) {
      state.stats = _recorded(event, state);
    }
  }

  static StatsEntity _recorded(GameEventEntity event, WorldState state) {
    final stats = state.stats;
    return switch (event) {
      ItemPickedUpEventEntity() || PlayerBlockedEventEntity() || TreeHitEventEntity() => stats,
      TreeFelledEventEntity(:final treeId) => stats.fellingTree(state.stumps[treeId]?.kind),
      BuildingHammeredEventEntity() => stats,
      BuildingCompletedEventEntity() => stats.completingBuilding(),
      QuestCompletedEventEntity() || TreeSproutedEventEntity() => stats,
      TreeRegrownEventEntity() => stats.regrowingTree(),
    };
  }
}
```

- [ ] **Step 4: `world_state.dart`** — import `../entities/game/stats_entity.dart` y, tras `stumps`:

```dart
  StatsEntity stats = const StatsEntity();
```

- [ ] **Step 5: `world.dart`** — imports `../entities/game/stats_entity.dart` y `stats_recording.dart`; getter tras `stumps`:

```dart
  StatsEntity get stats => _state.stats;
```

y en `advance`, tras `pickUpItems(_state, events);`:

```dart
    StatsRecording.record(_state, events);
```

- [ ] **Step 6: Verificar**

```sh
dart format --line-length 120 lib/layers/domain/entities/game/stats_entity.dart lib/layers/domain/world/extensions/stats_rules.dart lib/layers/domain/world/stats_recording.dart lib/layers/domain/world/world_state.dart lib/layers/domain/world/world.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 7: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-F4]: Keep world stats for the quests"`.

### Task TF4.2: Cinco misiones nuevas de la aldea

**Files:**
- Modify: `lib/core/config/constants/enum/quest_id.dart`, `lib/layers/domain/world/extensions/building_rules.dart`, `lib/layers/domain/quests/quests.dart`, `lib/core/assets/i18n/internationalize.dart`, `lib/core/assets/i18n/translations/es.json`

**Interfaces:**
- Consumes: `World.stats`, `StatsRules.treesFelledOf` (TF4.1), `World.funds`, `InventoryRules.amount`.
- Produces: `QuestId.fellTenTrees`, `fellAnOak`, `gatherFortyWood`, `buildTwoHouses`, `seeATreeRegrow` (al final); `BuildingListRules.completeCount(BlueprintId id) → int`.

- [ ] **Step 1: `quest_id.dart`** — tras `becomeChampion`:

```dart
  fellTenTrees,
  fellAnOak,
  gatherFortyWood,
  buildTwoHouses,
  seeATreeRegrow,
```

- [ ] **Step 2: `building_rules.dart`** — en `BuildingListRules`, tras `hasComplete`:

```dart
  int completeCount(BlueprintId id) =>
      where((building) => building.blueprint.id == id && building.isComplete).length;
```

- [ ] **Step 3: `quests.dart`** — imports `../../../core/config/constants/enum/tree_kind.dart` y `../world/extensions/stats_rules.dart`; tras la misión `buildHouse`:

```dart
    _MeasuredQuest(
      id: QuestId.fellTenTrees,
      line: QuestLine.village,
      target: 10,
      measure: (world) => world.stats.treesFelled,
    ),
    _MeasuredQuest(
      id: QuestId.fellAnOak,
      line: QuestLine.village,
      target: 1,
      measure: (world) => world.stats.treesFelledOf(TreeKind.oak),
    ),
    _MeasuredQuest(
      id: QuestId.gatherFortyWood,
      line: QuestLine.village,
      target: 40,
      measure: (world) => world.funds.amount(Resource.wood),
    ),
    _MeasuredQuest(
      id: QuestId.buildTwoHouses,
      line: QuestLine.village,
      target: 2,
      measure: (world) => world.buildings.completeCount(BlueprintId.house),
    ),
    _MeasuredQuest(
      id: QuestId.seeATreeRegrow,
      line: QuestLine.village,
      target: 1,
      measure: (world) => world.stats.treesRegrown,
    ),
```

- [ ] **Step 4: `internationalize.dart`** — en `forestQuestTitle`, tras `becomeChampion`:

```dart
    QuestId.fellTenTrees => '$_forest.quest.fellTenTrees'.tr(),
    QuestId.fellAnOak => '$_forest.quest.fellAnOak'.tr(),
    QuestId.gatherFortyWood => '$_forest.quest.gatherFortyWood'.tr(),
    QuestId.buildTwoHouses => '$_forest.quest.buildTwoHouses'.tr(),
    QuestId.seeATreeRegrow => '$_forest.quest.seeATreeRegrow'.tr(),
```

- [ ] **Step 5: `es.json`** — en `forest.quest`, tras `becomeChampion`:

```json
      "fellTenTrees": "Tala 10 árboles",
      "fellAnOak": "Tala un roble",
      "gatherFortyWood": "Ten 40 de madera a la vez",
      "buildTwoHouses": "Ten 2 casas terminadas",
      "seeATreeRegrow": "Ve rebrotar un árbol"
```

- [ ] **Step 6: Verificar**

```sh
dart format --line-length 120 lib/core/config/constants/enum/quest_id.dart lib/layers/domain/world/extensions/building_rules.dart lib/layers/domain/quests/quests.dart lib/core/assets/i18n/internationalize.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 7: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-F4]: Add the first village chapter quests"`.

### Task TF4.3: Misiones hechas plegadas en el panel

**Files:**
- Modify: `lib/core/config/constants/enum/forest/quest_item_status.dart`, `lib/layers/presentation/features/forest/models/hud_data.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/widgets/quest_row.dart`, `lib/core/assets/i18n/internationalize.dart`, `lib/core/assets/i18n/translations/es.json`

**Interfaces:**
- Consumes: `QuestProgressEntity` (`line`, `isCompleted`, `isCurrent`), `ForestBloc._questItem`.
- Produces: `QuestItemStatus.folded` (al final), `HudData.pendingQuestsShown = 2`, `Internationalize.forestQuestsDone({required int count})`.

- [ ] **Step 1: `quest_item_status.dart`**

```dart
enum QuestItemStatus { done, current, pending, folded }
```

- [ ] **Step 2: `hud_data.dart`** — primera línea de la clase:

```dart
  static const int pendingQuestsShown = 2;
```

- [ ] **Step 3: `internationalize.dart`** — tras `forestQuestDone`:

```dart
  static String forestQuestsDone({required int count}) =>
      '$_forest.hud.questsDone'.plural(count, namedArgs: {'count': '$count'});
```

- [ ] **Step 4: `es.json`** — en `forest.hud`, tras `questDone`:

```json
      "questsDone": {
        "one": "{count} hecha",
        "other": "{count} hechas"
      },
```

- [ ] **Step 5: `forest_bloc.dart`** — en `_hudData`, `quests: _questRows(quests),` y, antes de `_questItem`:

```dart
  List<QuestItemData> _questRows(List<QuestProgressEntity> quests) => [
    for (final line in QuestLine.values) ..._questRowsOf(line, quests.where((quest) => quest.line == line)),
  ];

  List<QuestItemData> _questRowsOf(QuestLine line, Iterable<QuestProgressEntity> quests) {
    final doneCount = quests.where((quest) => quest.isCompleted).length;
    final open = quests.where((quest) => !quest.isCompleted);
    return [
      if (doneCount > 0)
        QuestItemData(
          line: line,
          title: Internationalize.forestQuestsDone(count: doneCount),
          progressText: '',
          status: QuestItemStatus.folded,
        ),
      for (final quest in open.where((quest) => quest.isCurrent)) _questItem(quest),
      for (final quest in open.where((quest) => !quest.isCurrent).take(HudData.pendingQuestsShown)) _questItem(quest),
    ];
  }
```

- [ ] **Step 6: `quest_row.dart`**
  - Getter nuevo tras `_isDone`: `bool get _isChecked => _isDone || quest.status == QuestItemStatus.folded;`; la casilla usa `_isChecked` en vez de `_isDone` para el relleno.
  - `_check()`, rama nueva al final: `QuestItemStatus.folded => CustomColors.questDone,`.
  - `_titleStyle()`: `QuestItemStatus.done || QuestItemStatus.pending || QuestItemStatus.folded => CustomColors.hudMuted,` (en el orden de declaración: `done || pending` → `current` → `folded`); el tachado sigue solo con `_isDone`.

- [ ] **Step 7: Verificar**

```sh
dart format --line-length 120 lib/core/config/constants/enum/forest/quest_item_status.dart lib/layers/presentation/features/forest/models/hud_data.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart lib/layers/presentation/features/forest/widgets/quest_row.dart lib/core/assets/i18n/internationalize.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 8: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-F4]: Fold done quests in the panel"`.

### Task TF4.4: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-04-game-design/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, `CLAUDE.md` (y `F8-workshop.md` si algo de lo que da por hecho de F4 cambió).

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **F4** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F4 → `✅`, `feature/PROJECT-F4-quests-chapter-1`, nota "Sin tests (T1)"; `README.md`: icono de F4 → ✅.
- [ ] **Step 3:** `CLAUDE.md`: `StatsEntity` / `StatsRules`, `WorldState.stats` / `World.stats`, `StatsRecording` (último en `advance`, tipo desde el tocón), `BuildingListRules.completeCount`, las cinco misiones (aldea 7, total 15), `QuestItemStatus.folded`, `HudData.pendingQuestsShown` y el recorte por línea en `ForestBloc`. Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); `git commit -m "[PROJECT-F4]: Close the first quest chapter phase"` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque de la aldea, en Chrome y Android:

1. La insignia empieza en `0/15`. El panel de *Aldea* enseña la actual (*Consigue al menos 15 de madera*) y dos pendientes; *Héroe*, la suya y dos pendientes.
2. Al cumplir misiones aparece "1 hecha" / "N hechas" (casilla marcada, título apagado, sin tachar) encima de la actual; con la línea entera hecha solo queda "7 hechas".
3. *Tala 10 árboles*, *Tala un roble* y *Ve rebrotar un árbol* se cumplen en el mismo tick del evento (aviso al caer el árbol o al rebrotar). Se pueden cumplir fuera de orden.
4. Gastar madera (construir) no deshace *Ten 40 de madera a la vez*.
5. La séptima misión de la aldea anuncia "¡Has completado las misiones de Aldea!".

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F4 (no se ha tocado `test/`; los de iOS valen como referencia, con la aldea de 7 y no de 8). Datos en `test/mocks/**` (p. ej. `StatsEntityMock` en `test/mocks/domain/entities/game/stats_entity_mock.dart`: `empty`, `afterOnePine`, `afterTenTrees`), nunca en línea:

- `test/architecture_test.dart`: añadir `lib/layers/domain/world/stats_recording.dart` a `_worldInternals`.
- `stats_entity_test.dart`: `copyWith`, `==`/`hashCode` con el mapa, `assert` de no negativos. `stats_rules_test.dart`: `treesFelledOf` 0 sin datos; `fellingTree(null)` sube solo `treesFelled`; `fellingTree(oak)` sube los dos; `completingBuilding`, `regrowingTree`.
- `stats_recording_test.dart` / `world_test.dart`: talar suma `treesFelled` y el tipo del tocón; terminar una casa suma `buildingsCompleted`; rebrotar suma `treesRegrown`; todo en el mismo `advance` del evento; un evento sin tocón (no debería pasar) cuenta solo en `treesFelled`.
- `quests_test.dart` / `quest_log_test.dart`: 15 misiones, aldea con 7 (`gatherWood`, `buildHouse`, `fellTenTrees`, `fellAnOak`, `gatherFortyWood`, `buildTwoHouses`, `seeATreeRegrow`) antes de las del héroe; cada una con su objetivo y medida; se cumplen fuera de orden; gastar madera no deshace `gatherFortyWood`; la misión de `stats` sale en el mismo `AdvanceGameUseCase` que el evento. Cambian los conteos antiguos (10 → 15, aldea 2 → 7). `building_rules_test.dart`: `completeCount` (sin terminar no cuenta).
- `forest_bloc_test.dart`: insignia `x/15`; recorte por línea (plegada "N hechas" con `QuestItemStatus.folded` y `progressText` vacío, la actual, como mucho dos pendientes; línea entera hecha → solo la plegada); el aviso de línea completa llega con la séptima de la aldea (cambian los tests que lo esperaban con `buildHouse`). Cambian los `HudData` esperados (`hud_data_mock.dart`, `quest_item_data_mock.dart`): ahora salen menos filas.
- `quest_row_test.dart`: fila plegada con la casilla rellena, título `hudMuted` sin tachado. `quest_panel_test.dart` / `hud_overlay_test.dart` / `forest_page_test.dart`, si cuentan filas o la insignia `0/10`.
- `internationalize_test.dart`: los cinco títulos y `forestQuestsDone(count: 1)` = "1 hecha", `(count: 3)` = "3 hechas".

## Para F2

- Guardar `WorldState.stats` (los cuatro campos, `treesFelledByKind` por nombre de `TreeKind`) y las misiones completadas de `QuestLog`; al cargar, las misiones pegajosas vuelven hechas aunque ya no se cumplan.
