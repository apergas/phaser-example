# F7 · Cantera — Implementation Plan

> **Implementado el 2026-10-17 sin tests (regla del usuario); lo que falta de test está en *Para T1*.** Una sola rama `feature/PROJECT-F7-quarry`: el plan primero (escrito leyendo la ficha, el código tras F6 y la versión iOS, merge `ad3be22`), un commit por tarea (TF7.1–TF7.5) y el cierre. El código se aplicó tal como está en el plan, sin cambios. Desvíos respecto a iOS: la regla es una jerarquía `sealed` en vez de un `enum` con valor asociado (decisión 1); `cargoFor` en lugar de `cargo(for:)` (decisión 6); `Work.intervalMs` recibe también el *intent* (decisión 8); `PlacementData` sin `copyWith` como en iOS; en la web el motivo solo sale en el *snackbar*, porque no hay barra (decisión 11). Cifras, orden de los rechazos y `forest.png` (idéntico byte a byte al de iOS en `ad3be22`; solo se añade `quarry`), iguales a iOS.

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 2) |
| **Rama** | `feature/PROJECT-F7-quarry`, desde `feature/PROJECT-X-town` (arena C0–C13, "empezar con el hacha", F1, F3, F4, F5 y F6) |
| **Depende de** | F5 (piedra, rocas, `Mining`) y F6 (carga, almacén, entregas) |
| **Issue / milestone** | `phase:F7` · milestone `F7 Quarry` |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-village/F7-quarry.md`, merge `ad3be22` (`[PROJECT-F7]: Merge the quarry`), commits `a8cc24a` (reglas y cantera), `c2bbf58` (solo piedra), `6d0289a` (picar más rápido), `8bf7ac4` (arte), `4afbf4f` (motivo en la barra) |

**Goal:** Una cantera que solo se puede colocar junto a una roca, que solo recibe piedra y que hace más rápido picar las rocas que tiene cerca. Mientras se coloca, la barra explica por qué un sitio no vale.

**Architecture:** Dominio: `PlacementRuleEntity` (`sealed`: `AnywherePlacementRuleEntity`, `NearRockPlacementRuleEntity(range)`) en `BlueprintEntity.placementRule`, evaluada por `PlacementRuleRules.rejection` en `domain/world/extensions/`; `Construction.rejection` (sustituye a `canPlace`) devuelve el motivo en orden fijo y `World.placementRejection` lo expone; `CanPlaceBuildingUseCase` devuelve `ConstructionRejection?`. `BlueprintEntity.isDropOff` pasa a `accepts: Set<Resource>` y `Depositing` entrega solo lo aceptado (`InventoryRules.cargoFor` / `unloading(accepted)`). `Work.intervalMs(state, intent)` deja que `Mining` pique a 525 ms con una cantera terminada cerca de la roca (`BuildingRules.boostsMining`). Presentación: `PlacementData.invalidReason`, `Internationalize.forestPlacementRejection`, la `PlacementBar` con el rótulo del motivo y el aviso al intentar colocar. Arte: frame `quarry` desde `build_assets.py`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`, `easy_localization`, `injectable`; Pillow para `build_assets.py`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque 2 de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. La inyección no cambia (`CanPlaceBuildingUseCase` solo cambia el tipo que devuelve), así que no hace falta `build_runner`; si `di.config.dart` cambiara, se regenera y se commitea tal cual. Si cambia `build_assets.py` (TF7.4): regenerar y comprobar que solo aparece el frame nuevo.
- **Determinismo:** F7 no añade ni reordena ninguna tirada de `SeededRandom` y no toca el nivel: árboles, rocas, decoración y campamento salen igual. El intervalo de picado depende solo del estado.
- `PlacementRuleRules` vive en `domain/world/extensions/` porque lee `WorldState`; fuera del mundo solo se lee `World.placementRejection`.
- Casos nuevos de enum **al final**: `BlueprintId.quarry`, `ConstructionRejection.needsNearbyRock`. `switch` exhaustivos en el orden de declaración. Jerarquía `sealed` en un solo fichero (E8).
- Textos solo en `es.json`, leídos por `Internationalize`; los dos textos nuevos no dicen cómo interactuar, así que no llevan variante `…Touch`.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-F7]: <frase en inglés en imperativo>`; el commit, en un comando aparte del `git add`.

## Decisiones

Las de la ficha (comprobadas en iOS) más las que salen de Flutter:

1. **Reglas de colocación.** `PlacementRuleEntity` (`entities/building/placement_rule_entity.dart`, `sealed`, con `==`/`hashCode` a mano como `IntentEntity`): `AnywherePlacementRuleEntity` (por defecto) y `NearRockPlacementRuleEntity(range)`. `BlueprintEntity.placementRule` entra en `==` y `hashCode`. `PlacementRuleRules.rejection(WorldState, PositionEntity)` → `ConstructionRejection?` (`switch` exhaustivo). En iOS es un `enum` con valor asociado; en Dart, la jerarquía `sealed` de la ficha.
2. **"Junto a una roca":** distancia de centro a centro **estrictamente** menor que `Rules.quarryRockRange = 120` contra `WorldState.rocks` (una roca rota ya no está). Con radios 40 y 22, el centro de la cantera vale entre 62 (más cerca choca con la roca: `blocked`) y 120.
3. **Orden de los rechazos** (`Construction.rejection`, que sustituye a `canPlace`): no construible → `blocked` (campamento); la regla del plano → su motivo; fuera del mapa, encima de un obstáculo, del jugador o de un objeto → `blocked`. `place` comprueba antes el almacén (`notEnoughResources`). `World.canPlace` pasa a `World.placementRejection`; `CanPlaceBuildingUseCase` conserva el nombre y devuelve `ConstructionRejection?` (`null` = se puede). La inyección no cambia.
4. **Cantera:** `BlueprintId.quarry` (al final), 25 de madera, 8 golpes, radio 40, `NearRockPlacementRuleEntity(range: Rules.quarryRockRange)`, **tercera** en `Blueprints.all` y en el menú (tras el almacén).
5. **Qué recibe cada edificio:** `BlueprintEntity.isDropOff` pasa a `accepts: Set<Resource>` (por defecto `const <Resource>{}`, en `==`/`hashCode` con `SetEquality`): campamento y almacén `{wood, stone}`, cantera `{stone}`, los demás vacío. `BuildingRules.acceptsDeposits` = terminado y `accepts` no vacío.
6. **Entregar en la cantera:** `InventoryRules.cargoFor(accepted)` (la carga que el edificio acepta) y `unloading(accepted)` (sustituye a `unloading()`: quita solo lo que ocupa carga **y** el edificio acepta). `Depositing.check` da `emptyLoad` si no lleva nada aceptado (el aviso de siempre, "No llevas nada que guardar."); `impact` entrega solo lo aceptado y la madera se queda en la carga. Sin caso nuevo en `DepositResult`. (iOS: `cargo(for:)`; en Dart no se puede sobrecargar el getter `cargo`.)
7. **Picar más rápido:** `Rules.quarryMineIntervalMs = 525` (750 − 30 %) cuando hay una cantera **terminada** a menos de `Rules.quarryBoostRange = 160` de la **roca** (`BuildingRules.boostsMining(PositionEntity)`). 160 > 120: la roca junto a la que se colocó siempre queda dentro.
8. **`Work.intervalMs(WorldState state, I intent)`** sustituye al getter; `BoundWork.intervalMs(WorldState state)`. Talar (750), construir (650) y entregar (400) no cambian. `World._work` lee el intervalo una vez por tick y `workProgress` usa el mismo.
9. **Arte** (sin autores nuevos; el código es el de iOS): `quarry` = la roca grande (`ROCK_BOX`) entre dos bloques de piedra agrietada (`CHIMNEY_BOX`) tras dos tramos de la valla de la arena (`ARENA_FENCE_BOX`), 128 × 63, pivote (0.5, 1). `forest.png` sale idéntico al de iOS en `ad3be22` y ningún frame anterior cambia. `SpriteNames.building(quarry) == 'quarry'`, `buildingFrontOffset` 16 (es bajita).
10. **El motivo en los datos:** `PlacementData.invalidReason: ConstructionRejection?` con `isValid` calculado (lo sigue leyendo `PlacementGhostComponent`); `copyWith` desaparece (su único uso era `_movePlacement`, que ahora construye el valor entero, como iOS; así no hace falta un `ValueGetter`). Al abrir la colocación empieza en `blocked` y se recalcula al momento.
11. **El motivo en pantalla:** `Internationalize.forestPlacementRejection(rejection:)`, un texto por motivo (`notEnoughResources` y `blocked` reutilizan los avisos de siempre). La `PlacementBar` (táctil) gana `reason: String?` y enseña un rótulo (`HudPanel`, `system15w600` en `hudWarning`, centrado) sobre los botones para **cualquier** motivo; ocupa siempre su hueco (`Opacity` 0 y `ExcludeSemantics` si el sitio vale) para que la barra no cambie de altura y el *snackbar* no salte. En la web, sin barra, el motivo sale en el *snackbar* al intentar colocar.
12. **Intentar colocar** (`ForestBloc._place`): `notEnoughResources` cierra la colocación como hoy; cualquier otro motivo (`blocked`, `needsNearbyRock`) avisa con su texto y la colocación sigue abierta.
13. **Textos:** `forest.blueprint.quarry` "Cantera", `forest.placement.needsRock` "La cantera tiene que ir junto a una roca.".
14. **HUD:** no cambia (la cantera solo añade una fila al menú de construir y la `PlacementBar` no cuenta para los umbrales), así que no se vuelven a medir.
15. **Guardado (F2):** la cantera es un edificio más. Al cargar no se vuelve a comprobar la regla: una cantera guardada se queda aunque su roca ya esté rota.

## Reparto

| Tarea | Qué |
|---|---|
| TF7.1 | Reglas de colocación y la cantera (dominio, caso de uso, textos, menú) |
| TF7.2 | La cantera recibe solo piedra (`accepts`) |
| TF7.3 | Picar más rápido junto a una cantera |
| TF7.4 | Frame `quarry` |
| TF7.5 | El motivo en la barra de colocación |
| TF7.6 | Cierre: T1, `PROGRESS.md`, README, `CLAUDE.md` |

---

### Task TF7.1: Reglas de colocación y la cantera

**Files:**
- Create: `lib/layers/domain/entities/building/placement_rule_entity.dart`, `lib/layers/domain/world/extensions/placement_rule_rules.dart`
- Modify: `lib/core/config/constants/enum/blueprint_id.dart`, `lib/core/config/constants/enum/construction_rejection.dart`, `lib/layers/domain/entities/building/blueprint_entity.dart`, `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/rules/blueprints.dart`, `lib/layers/domain/world/construction.dart`, `lib/layers/domain/world/world.dart`, `lib/layers/domain/use-cases/game/can_place_building_use_case.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`, `lib/layers/presentation/features/forest/game/render/render_constants.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`

**Interfaces:**
- Produces: `BlueprintId.quarry`; `ConstructionRejection.needsNearbyRock`; `PlacementRuleEntity` / `AnywherePlacementRuleEntity` / `NearRockPlacementRuleEntity({required double range})`; `BlueprintEntity.placementRule`; `Rules.quarryRockRange == 120`; `Blueprints.quarry`; `PlacementRuleRules.rejection(WorldState state, PositionEntity position) → ConstructionRejection?`; `static ConstructionRejection? Construction.rejection(WorldState, BlueprintEntity, PositionEntity)`; `ConstructionRejection? World.placementRejection(BlueprintEntity, PositionEntity)`; `ConstructionRejection? CanPlaceBuildingUseCase.call({blueprint, x, y})`; `Internationalize.forestPlacementRejection({required ConstructionRejection rejection})`.

- [ ] **Step 1: enums** (casos al final):

```diff
-enum BlueprintId { house, forge, armory, mageTower, camp, storehouse }
+enum BlueprintId { house, forge, armory, mageTower, camp, storehouse, quarry }
```

```diff
-enum ConstructionRejection { notEnoughResources, blocked }
+enum ConstructionRejection { notEnoughResources, blocked, needsNearbyRock }
```

- [ ] **Step 2: la regla** — fichero completo `lib/layers/domain/entities/building/placement_rule_entity.dart`:

```dart
sealed class PlacementRuleEntity {
  const PlacementRuleEntity();
}

final class AnywherePlacementRuleEntity extends PlacementRuleEntity {
  const AnywherePlacementRuleEntity();

  @override
  bool operator ==(Object other) => other is AnywherePlacementRuleEntity;

  @override
  int get hashCode => (AnywherePlacementRuleEntity).hashCode;
}

final class NearRockPlacementRuleEntity extends PlacementRuleEntity {
  final double range;

  const NearRockPlacementRuleEntity({required this.range});

  @override
  bool operator ==(Object other) => other is NearRockPlacementRuleEntity && other.range == range;

  @override
  int get hashCode => Object.hash(NearRockPlacementRuleEntity, range);
}
```

Fichero completo `lib/layers/domain/world/extensions/placement_rule_rules.dart`:

```dart
import '../../../../core/config/constants/enum/construction_rejection.dart';
import '../../entities/building/placement_rule_entity.dart';
import '../../entities/geometry/position_entity.dart';
import '../world_state.dart';
import 'position_geometry.dart';

extension PlacementRuleRules on PlacementRuleEntity {
  ConstructionRejection? rejection(WorldState state, PositionEntity position) => switch (this) {
    AnywherePlacementRuleEntity() => null,
    NearRockPlacementRuleEntity(:final range) =>
      state.rocks.values.any((rock) => position.distanceTo(rock.position) < range)
          ? null
          : ConstructionRejection.needsNearbyRock,
  };
}
```

- [ ] **Step 3: el plano** — `blueprint_entity.dart` gana `placementRule` (por defecto `AnywherePlacementRuleEntity`), en `==` y `hashCode`:

```diff
 import '../../../../core/config/constants/enum/resource.dart';
+import 'placement_rule_entity.dart';
 ...
   final bool isDropOff;
+  final PlacementRuleEntity placementRule;
 ...
     this.isDropOff = false,
+    this.placementRule = const AnywherePlacementRuleEntity(),
   });
 ...
-      other.isDropOff == isDropOff;
+      other.isDropOff == isDropOff &&
+      other.placementRule == placementRule;
 ...
     isDropOff,
+    placementRule,
   );
```

`rules.dart`, detrás de `carryCapacity`:

```dart
  static const double quarryRockRange = 120;
```

`blueprints.dart` (imports de `placement_rule_entity.dart` y `rules.dart`), detrás de `storehouse`, y tercera en `all`:

```dart
  static const BlueprintEntity quarry = BlueprintEntity(
    id: BlueprintId.quarry,
    cost: {Resource.wood: 25},
    hitsToBuild: 8,
    footprintRadius: 40,
    placementRule: NearRockPlacementRuleEntity(range: Rules.quarryRockRange),
  );
```

```diff
-  static const List<BlueprintEntity> all = [house, storehouse, forge, armory, mageTower, camp];
+  static const List<BlueprintEntity> all = [house, storehouse, quarry, forge, armory, mageTower, camp];
```

- [ ] **Step 4: el motivo en `Construction`** — `canPlace` pasa a `rejection` (import de `extensions/placement_rule_rules.dart`):

```dart
  static ConstructionRejection? rejection(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
    if (!blueprint.isBuildable) return ConstructionRejection.blocked;
    final ruleRejection = blueprint.placementRule.rejection(state, position);
    if (ruleRejection != null) return ruleRejection;
    final radius = blueprint.footprintRadius;
    final player = state.player;
    final overlapsPlayer = position.distanceTo(player.position) < radius + player.radius;
    final overlapsItem = state.items.values.any((item) => position.distanceTo(item.position) < radius);
    final fits = state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem;
    return fits ? null : ConstructionRejection.blocked;
  }

  static ConstructionResultEntity place(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
    if (state.stock.missing(blueprint.cost).isNotEmpty) {
      return const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources);
    }
    final reason = rejection(state, blueprint, position);
    if (reason != null) return ConstructionRejectedEntity(reason: reason);
    ...
```

`world.dart` (import de `construction_rejection.dart`):

```diff
-  bool canPlace(BlueprintEntity blueprint, PositionEntity position) =>
-      Construction.canPlace(_state, blueprint, position);
+  ConstructionRejection? placementRejection(BlueprintEntity blueprint, PositionEntity position) =>
+      Construction.rejection(_state, blueprint, position);
```

`can_place_building_use_case.dart` (import de `construction_rejection.dart`):

```dart
  ConstructionRejection? call({required BlueprintId blueprint, required double x, required double y}) {
    return _sessionRepository.current().world.placementRejection(Blueprints.of(blueprint), PositionEntity(x: x, y: y));
  }
```

- [ ] **Step 5: textos y escena** — `es.json`: `"quarry": "Cantera"` detrás de `storehouse` en `forest.blueprint`; `"needsRock": "La cantera tiene que ir junto a una roca."` detrás de `cancel` en `forest.placement`. `internationalize.dart` (import de `construction_rejection.dart`):

```dart
    BlueprintId.quarry => '$_forest.blueprint.quarry'.tr(),
```

```dart
  static String forestPlacementRejection({required ConstructionRejection rejection}) => switch (rejection) {
    ConstructionRejection.notEnoughResources => forestMessageNotEnoughResources,
    ConstructionRejection.blocked => forestMessageBlockedSite,
    ConstructionRejection.needsNearbyRock => '$_forest.placement.needsRock'.tr(),
  };
```

`sprite_names.dart`: `BlueprintId.quarry => 'quarry',`; `render_constants.dart`: `BlueprintId.quarry => 16,` (el frame llega en TF7.4).

- [ ] **Step 6: el bloc** — `_movePlacement` sigue con `isValid` hasta TF7.5 y `_place` avisa de cualquier motivo salvo `notEnoughResources`:

```diff
-      isValid: _canPlaceBuildingUseCase(blueprint: placement.blueprint, x: position.x, y: position.y),
+      isValid: _canPlaceBuildingUseCase(blueprint: placement.blueprint, x: position.x, y: position.y) == null,
```

```dart
      case ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources):
        _placement = null;
        _showMessage(Internationalize.forestMessageNotEnoughResources);
      case ConstructionRejectedEntity(:final reason):
        _showMessage(Internationalize.forestPlacementRejection(rejection: reason));
```

- [ ] **Step 7: Verificar** — `dart format --line-length 120` sobre los ficheros de `lib/` tocados; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 8: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F7]: Add placement rules and the quarry`.

### Task TF7.2: La cantera recibe solo piedra

**Files:**
- Modify: `lib/layers/domain/entities/building/blueprint_entity.dart`, `lib/layers/domain/rules/blueprints.dart`, `lib/layers/domain/world/extensions/building_rules.dart`, `lib/layers/domain/world/extensions/inventory_rules.dart`, `lib/layers/domain/world/depositing.dart`

**Interfaces:**
- Consumes: `Blueprints.quarry` (TF7.1).
- Produces: `BlueprintEntity.accepts: Set<Resource>` (sin `isDropOff`); `InventoryRules.cargoFor(Set<Resource> accepted) → Map<Resource, int>`; `InventoryRules.unloading(Set<Resource> accepted) → InventoryEntity` (sin `unloading()`).

- [ ] **Step 1: `accepts`** — en `blueprint_entity.dart`, `isDropOff` → `accepts`:

```diff
-  final bool isDropOff;
+  final Set<Resource> accepts;
 ...
-    this.isDropOff = false,
+    this.accepts = const <Resource>{},
 ...
-      other.isDropOff == isDropOff &&
+      const SetEquality<Resource>().equals(other.accepts, accepts) &&
 ...
-    isDropOff,
+    const SetEquality<Resource>().hash(accepts),
```

`blueprints.dart`: `storehouse` y `camp` con `accepts: {Resource.wood, Resource.stone}` en lugar de `isDropOff: true`; `quarry` con `accepts: {Resource.stone}`.

`building_rules.dart`:

```diff
-  bool get acceptsDeposits => isComplete && blueprint.isDropOff;
+  bool get acceptsDeposits => isComplete && blueprint.accepts.isNotEmpty;
```

- [ ] **Step 2: la carga aceptada** — `inventory_rules.dart`, en lugar de `unloading()`:

```dart
  Map<Resource, int> cargoFor(Set<Resource> accepted) => {
    for (final MapEntry(key: resource, value: quantity) in cargo.entries)
      if (accepted.contains(resource)) resource: quantity,
  };

  InventoryEntity unloading(Set<Resource> accepted) => copyWith(
    resources: {...resources}..removeWhere((resource, _) => resource.takesCargo && accepted.contains(resource)),
  );
```

- [ ] **Step 3: `Depositing`**:

```diff
-    if (state.player.inventory.load == 0) return DepositResult.emptyLoad;
+    if (state.player.inventory.cargoFor(building.blueprint.accepts).isEmpty) return DepositResult.emptyLoad;
```

```dart
  @override
  bool impact(WorldState state, DepositIntentEntity intent, List<GameEventEntity> events) {
    final accepted = state.buildings[intent.buildingId]?.blueprint.accepts;
    if (accepted == null) return true;
    final load = state.player.inventory.cargoFor(accepted);
    if (load.isEmpty) return true;
    state.player = state.player.withInventory(state.player.inventory.unloading(accepted));
    state.stock = state.stock.adding(load);
    events.add(DepositedEventEntity(buildingId: intent.buildingId, load: load));
    return true;
  }
```

- [ ] **Step 4: Verificar** — `dart format --line-length 120` sobre los cinco ficheros; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 5: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F7]: Take only stone at the quarry`.

### Task TF7.3: Picar más rápido junto a una cantera

**Files:**
- Modify: `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/world/extensions/building_rules.dart`, `lib/layers/domain/world/work.dart`, `lib/layers/domain/world/woodcutting.dart`, `lib/layers/domain/world/construction.dart`, `lib/layers/domain/world/mining.dart`, `lib/layers/domain/world/depositing.dart`, `lib/layers/domain/world/world.dart`

**Interfaces:**
- Produces: `Rules.quarryMineIntervalMs == 525`, `Rules.quarryBoostRange == 160`; `BuildingRules.boostsMining(PositionEntity rockPosition) → bool`; `Work.intervalMs(WorldState state, I intent) → double`; `BoundWork.intervalMs(WorldState state) → double`.

- [ ] **Step 1: reglas** — `rules.dart`: `quarryMineIntervalMs = 525` detrás de `depositIntervalMs`; `quarryBoostRange = 160` detrás de `quarryRockRange`. `building_rules.dart` (imports de `position_entity.dart`, `rules.dart` y `position_geometry.dart`):

```dart
  bool boostsMining(PositionEntity rockPosition) =>
      isComplete && blueprint.id == BlueprintId.quarry && position.distanceTo(rockPosition) < Rules.quarryBoostRange;
```

- [ ] **Step 2: el intervalo depende del estado** — `work.dart`:

```diff
-  double get intervalMs;
+  double intervalMs(WorldState state, I intent);
 ...
-  double get intervalMs => _work.intervalMs;
+  double intervalMs(WorldState state) => _work.intervalMs(state, _intent);
```

`woodcutting.dart`, `construction.dart`, `depositing.dart`:

```dart
  @override
  double intervalMs(WorldState state, ChopIntentEntity intent) => Rules.chopIntervalMs;
```

```dart
  @override
  double intervalMs(WorldState state, ConstructIntentEntity intent) => Rules.hammerIntervalMs;
```

```dart
  @override
  double intervalMs(WorldState state, DepositIntentEntity intent) => Rules.depositIntervalMs;
```

`mining.dart` (import de `extensions/building_rules.dart`):

```dart
  @override
  double intervalMs(WorldState state, MineIntentEntity intent) {
    final rock = state.rocks[intent.rockId];
    if (rock == null) return Rules.mineIntervalMs;
    final isBoosted = state.buildings.values.any((building) => building.boostsMining(rock.position));
    return isBoosted ? Rules.quarryMineIntervalMs : Rules.mineIntervalMs;
  }
```

`world.dart`:

```diff
-    return activity.elapsedMs / workFor(activity.intent).intervalMs;
+    return activity.elapsedMs / workFor(activity.intent).intervalMs(_state);
 ...
     final elapsed = activity.elapsedMs + deltaMs;
-    if (elapsed < work.intervalMs) {
+    final intervalMs = work.intervalMs(_state);
+    if (elapsed < intervalMs) {
       _state.player = _state.player.continueWork(elapsed);
       return;
     }
-    _state.player = _state.player.continueWork(elapsed - work.intervalMs);
+    _state.player = _state.player.continueWork(elapsed - intervalMs);
```

- [ ] **Step 3: Verificar** — `dart format --line-length 120` sobre los ocho ficheros; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 4: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F7]: Speed up mining near a quarry`.

### Task TF7.4: Frame `quarry`

**Files:**
- Modify: `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/forest.{png,json}` (generados), `lib/core/assets/images/lpc/CREDITS.md`

**Interfaces:**
- Produces: frame `quarry` (128 × 63, pivote (0.5, 1)) en `forest.json`, el que leen `SpriteNames.building(BlueprintId.quarry)` y `LpcAtlas`.

- [ ] **Step 1: `build_assets.py`** (el código de iOS, tarea 4 de su plan; la parte del bosque del script es igual en los dos repos):

```diff
-                                   the storehouse and the camp (pivot = bottom centre)
+                                   the storehouse, the camp and the quarry (pivot = bottom centre)
 ...
 CAMP_STUMP_OVERLAP = 6  # the stump stands in front of the log pile
+QUARRY_FENCE_TILES = 2  # the quarry is two arena fence pieces wide
+QUARRY_BLOCK_DROP = 10  # the stone blocks beside the boulder sit this much lower than its top
+QUARRY_BLOCK_INSET = 4  # distance from each stone block to the side of the quarry image
+QUARRY_FENCE_OVERLAP = 14  # the fence covers the foot of the rock pile
 ...
+def build_quarry(terrain: Image.Image) -> Image.Image:
+    """A pile of rocks (the large boulder between two cracked stone blocks) behind a wooden fence."""
+    boulder = trim(terrain.crop(ROCK_BOX), "quarry boulder")
+    block = trim(terrain.crop(CHIMNEY_BOX), "quarry block")
+    fence = trim(terrain.crop(ARENA_FENCE_BOX), "quarry fence")
+    width = fence.width * QUARRY_FENCE_TILES
+    pile = max(boulder.height, block.height + QUARRY_BLOCK_DROP)
+    image = Image.new("RGBA", (width, pile + fence.height - QUARRY_FENCE_OVERLAP))
+    image.alpha_composite(block, (QUARRY_BLOCK_INSET, pile - block.height))
+    image.alpha_composite(block, (width - QUARRY_BLOCK_INSET - block.width, pile - block.height))
+    image.alpha_composite(boulder, ((width - boulder.width) // 2, pile - boulder.height))
+    for index in range(QUARRY_FENCE_TILES):
+        image.alpha_composite(fence, (index * fence.width, image.height - fence.height))
+    return image
+
+
 def build_forest() -> None:
 ...
     pivots["camp"] = {"x": 0.5, "y": 1}
+    frames["quarry"] = build_quarry(terrain)
+    pivots["quarry"] = {"x": 0.5, "y": 1}
```

(`ARENA_FENCE_BOX` está definido más abajo en el módulo; se lee al ejecutar `build_forest`, como en iOS.)

- [ ] **Step 2: regenerar** — `cd asset-packs/lpc && python3 build_assets.py`. `git status` enseña solo `forest.png`, `forest.json` y el script. Con un script de usar y tirar en el *scratchpad* (Pillow) que compara cada frame del atlas anterior (`git show HEAD:…`) con el nuevo: añadido `quarry` (128 × 63), ningún frame anterior cambia; `forest.png` idéntico byte a byte al de `$IOS` en `ad3be22`. Mirar el recorte ampliado.
- [ ] **Step 3: créditos** (sin autores nuevos), detrás de la línea del campamento:

```diff
 The camp (`camp` frame) is that stump in front of three logs cut from a tree trunk of the LPC Tile Atlas above.
+The quarry (`quarry` frame) is the large boulder between two cracked stone blocks behind two pieces of the arena
+fence, all from the LPC Tile Atlas above.
```

- [ ] **Step 4: Commit** — `git add asset-packs lib/core/assets/images/lpc` y, aparte, el commit `[PROJECT-F7]: Add the quarry art`.

### Task TF7.5: El motivo en la barra de colocación

**Files:**
- Modify: `lib/layers/presentation/features/forest/models/placement_data.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/widgets/placement_bar.dart`, `lib/layers/presentation/features/forest/forest_page.dart`
- No cambian: `PlacementGhostComponent` (sigue leyendo `placement.isValid`, ahora calculado), `HudOverlay`.

**Interfaces:**
- Consumes: `CanPlaceBuildingUseCase` → `ConstructionRejection?` y `Internationalize.forestPlacementRejection` (TF7.1).
- Produces: `PlacementData({blueprint, position, required ConstructionRejection? invalidReason})` con `bool get isValid` y sin `copyWith`; `PlacementBar({required String? reason, required onConfirm, required onCancel})`.

- [ ] **Step 1: `PlacementData`** — fichero completo:

```dart
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/construction_rejection.dart';
import '../../../../domain/entities/geometry/position_entity.dart';

class PlacementData {
  final BlueprintId blueprint;
  final PositionEntity position;
  final ConstructionRejection? invalidReason;

  const PlacementData({required this.blueprint, required this.position, required this.invalidReason});

  bool get isValid => invalidReason == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementData &&
          other.blueprint == blueprint &&
          other.position == position &&
          other.invalidReason == invalidReason;

  @override
  int get hashCode => Object.hash(blueprint, position, invalidReason);
}
```

- [ ] **Step 2: el bloc**:

```dart
  void _movePlacement(PositionEntity position) {
    final placement = _placement;
    if (placement == null) return;
    _placement = PlacementData(
      blueprint: placement.blueprint,
      position: position,
      invalidReason: _canPlaceBuildingUseCase(blueprint: placement.blueprint, x: position.x, y: position.y),
    );
  }
```

```diff
-    _placement = PlacementData(blueprint: blueprint, position: position, isValid: false);
+    _placement = PlacementData(blueprint: blueprint, position: position, invalidReason: ConstructionRejection.blocked);
```

- [ ] **Step 3: `PlacementBar`** — fichero completo:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_button.dart';
import 'hud_panel.dart';

class PlacementBar extends StatelessWidget {
  final String? reason;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PlacementBar({super.key, required this.reason, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _reasonLabel(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: [
                HudButton(label: Internationalize.forestPlacementConfirm, isActive: true, onPressed: onConfirm),
                HudButton(label: Internationalize.forestPlacementCancel, onPressed: onCancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonLabel() {
    final text = reason;
    return ExcludeSemantics(
      excluding: text == null,
      child: Opacity(
        opacity: text == null ? 0 : 1,
        child: HudPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            text ?? ' ',
            textAlign: TextAlign.center,
            style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudWarning),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: la página** — `_placementActions` pasa el texto del motivo:

```dart
  Widget _placementActions({required PlacementData? placement}) {
    if (placement == null) return const SizedBox.shrink();
    final reason = placement.invalidReason;
    return PlacementBar(
      reason: reason == null ? null : Internationalize.forestPlacementRejection(rejection: reason),
      onConfirm: () => bloc.add(ForestMapClicked(position: placement.position)),
      onCancel: () => bloc.add(const ForestPlacementCancelled()),
    );
  }
```

- [ ] **Step 5: Verificar** — `dart format --line-length 120` sobre los cuatro ficheros; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 6: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F7]: Explain why a quarry cannot be placed`.

### Task TF7.6: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-04-game-design/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, este plan, `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **F7** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F7 → `✅`, `feature/PROJECT-F7-quarry`, nota "Bloque 2. Sin tests (T1)."; `README.md`: icono de F7 → ✅; cabecera de este plan con lo implementado y los desvíos.
- [ ] **Step 3:** `CLAUDE.md`: la cantera (`BlueprintId.quarry`, tercera del menú), `PlacementRuleEntity` + `PlacementRuleRules`, `Construction.rejection` y su orden, `World.placementRejection`, `CanPlaceBuildingUseCase` → `ConstructionRejection?`, `BlueprintEntity.accepts` en lugar de `isDropOff`, `InventoryRules.cargoFor` / `unloading(accepted)`, `Work.intervalMs(state, intent)` y `BuildingRules.boostsMining`, `PlacementData.invalidReason`, `Internationalize.forestPlacementRejection` y el rótulo de la `PlacementBar`. Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); el commit `[PROJECT-F7]: Close the quarry phase` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque 2 de la aldea, en Chrome y Android:

1. "Cantera" (25 de madera) es la tercera del menú de construir, tras el almacén.
2. Lejos de las rocas la silueta sale roja; en Android, la barra dice sobre los botones "La cantera tiene que ir junto a una roca." en color de aviso, y tocar o *Construir aquí* avisa y no coloca. Junto a una roca (a menos de 120 de su centro) sale verde y el rótulo desaparece sin que la barra cambie de altura ni salte el *snackbar*. Sobre un árbol o el jugador, "Ahí no cabe. Busca un sitio despejado.".
3. En Chrome no hay barra: hacer clic lejos de las rocas avisa con el *snackbar* y la colocación sigue abierta.
4. La cantera es un peñasco gris entre dos bloques, tras una valla.
5. Terminada, tocarla con piedra y madera en la carga entrega solo la piedra ("Guardado en el almacén: 8 de piedra") y la madera se queda; con solo madera avisa "No llevas nada que guardar.".
6. Picar una roca a menos de 160 de una cantera terminada va visiblemente más rápido (525 ms frente a 750); con la cantera a medio hacer, al ritmo de siempre. Talar y construir no cambian.

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F7 (no se ha tocado `test/`; los de iOS valen como referencia). Datos en `test/mocks/**` (p. ej. `BlueprintEntityMock`, `BuildingEntityMock.quarry` / `quarrySite`, `RockEntityMock`, `InventoryEntityMock` con madera y piedra, `PlacementDataMock` con `invalidReason`), nunca en línea:

- **Compilación:** `PlacementData(invalidReason:)` sin `isValid` ni `copyWith` (`placement_data_mock.dart`, `placement_data_test.dart`, `forest_data_mock.dart`, `forest_bloc_mock.dart`); `PlacementBar(reason:)` (`placement_bar_test.dart`); `CanPlaceBuildingUseCase` devuelve `ConstructionRejection?` (`can_place_building_use_case_test.dart`); `World.canPlace` → `placementRejection`; `BlueprintEntity(accepts:)` sin `isDropOff`; `InventoryRules.unloading(accepted)`; `Work.intervalMs(state, intent)` si algún test lo lee.
- **Dominio:**
  - `placement_rule_rules_test.dart`: `AnywherePlacementRuleEntity` → `null` siempre; `NearRockPlacementRuleEntity(120)` → `null` a 61, 62 y 119,9 de la roca, `needsNearbyRock` a 120 y sin rocas; una roca rota (quitada de `rocks`) no cuenta; `placement_rule_entity_test.dart` (`==`);
  - `construction_test.dart` / `world_construction_test.dart`: el orden de los rechazos (no construible → `blocked` antes que la regla; la regla antes que el sitio; a 50 de la roca `blocked`); `place` con el almacén vacío → `notEnoughResources` aunque falte la roca; lejos → `needsNearbyRock` sin cobrar;
  - `blueprints_test.dart` (cantera tercera, 25 de madera, 8 golpes, radio 40, `accepts` de cada plano), `blueprint_entity_test.dart` (`==` con `accepts` y `placementRule`), `building_rules_test.dart` (`acceptsDeposits` con `accepts` vacío → `false`; `boostsMining` solo para una cantera terminada a < 160);
  - `inventory_rules_test.dart`: `cargoFor({stone})` solo con piedra > 0; `unloading({stone})` deja la madera, las herramientas, el oro y el maná (sustituye a los tests de `unloading()`);
  - `world_deposit_test.dart`: cantera terminada con solo madera → `emptyLoad`; con madera y piedra → `DepositedEventEntity(load: {stone: n})`, la madera sigue en la carga y el almacén suma solo piedra; campamento y almacén siguen recibiendo todo; cantera a medio hacer → `notADropOff`;
  - `world_mining_test.dart`: golpes cada 525 ms con una cantera terminada a < 160 de la roca; 750 a 160 o más y con la cantera a medio hacer; `workProgress` usa el mismo intervalo; talar 750, construir 650 y entregar 400 con una cantera cerca;
  - `can_place_building_use_case_test.dart` (`null` / el motivo); `get_build_options_use_case_test.dart` (cantera tercera).
- **Presentación:** `forest_bloc_test.dart`: `ForestPointerMoved` publica `invalidReason` (`needsNearbyRock` lejos, `null` cerca); abrir la colocación empieza en `blocked` y lo recalcula; tocar con `needsNearbyRock` → aviso "La cantera tiene que ir junto a una roca." y la colocación sigue abierta. `placement_data_test.dart`: `isValid == (invalidReason == null)`. `placement_bar_test.dart`: el rótulo con el motivo, oculto (y fuera de la semántica) sin motivo, y la barra con la misma altura con y sin motivo. `forest_page_test.dart` si mira la barra. `lpc_atlas_test.dart` (`quarry`), `sprite_names_test.dart` / `render_constants_test.dart` si existen (`'quarry'`, 16), `internationalize_test.dart` (`forest.blueprint.quarry`, `forest.placement.needsRock` y `forestPlacementRejection` de cada motivo). `LpcAssetsMock` construye `quarry` (ya lo hace para todo `BlueprintId`).

## Para F8 y F2

- **F8 (taller):** las mejoras que cambien ritmos de trabajo siguen el patrón de `Work.intervalMs(state, intent)` (leer el estado, sin tiradas); un edificio nuevo declara `accepts` y `placementRule` solo si los necesita (por defecto vacío y `AnywherePlacementRuleEntity`). `BlueprintId` nuevos van detrás de `quarry`; en el menú, el orden de `Blueprints.all`.
- **F2 (guardado):** la cantera se guarda como cualquier edificio (`blueprint` = `'quarry'`, con su progreso); nada más que guardar (la aceleración y la regla salen del estado). Al cargar no se vuelve a comprobar la regla de colocación.
