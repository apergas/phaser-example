# F6 · Almacén y capacidad de carga — Implementation Plan

> **Quitado el 2026-10-18** por la mejora [Recursos directos al almacén](../2026-10-17-extras/auto-stock.md): la carga, la entrega (`Depositing`) y el almacén (`BlueprintId.storehouse`) ya no existen; lo talado y lo picado va entero al almacén de la aldea y el campamento queda en el mapa sin función. Las partidas guardadas con almacenes se migran al cargar (versión 1 → 2). Este plan queda como historia.

> **Implementado el 2026-10-17 sin tests (regla del usuario); lo que falta de test está en *Para T1*.** Una sola rama `feature/PROJECT-F6-storehouse`, un commit por tarea (TF6.1–TF6.5) y el cierre; el plan se escribió a partir del código ya compilado, así que su commit quedó detrás de los de las tareas. Desvíos respecto a iOS y a la ficha: `BuildingDBO` con `x`/`y` sueltos y `BlueprintId.name` en lugar de un valor bruto (decisiones 4 y 7); `DepositResult` en el orden de la ficha y el evento `DepositedEventEntity`, que la ficha no nombraba (decisión 5); tocar una casa terminada sigue andando como antes en Flutter (decisión 6); umbrales del HUD medidos con Roboto: 1460 y 960 en vez de 1500 y 1000 pt (decisión 13). Planos, campamento, decoración quitada, frames (`forest.png` idéntico byte a byte) y cifras, idénticos a iOS.

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 2) |
| **Rama** | `feature/PROJECT-F6-storehouse`, desde `feature/PROJECT-X-town` (develop con la arena C0–C13, "empezar con el hacha", F1, F3, F4 y F5) |
| **Depende de** | F5. Ya **no** depende de F2: el guardado va el último y guarda el almacén entonces. |
| **Issue / milestone** | `phase:F6` · milestone `F6 Storehouse` |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-village/F6-storehouse.md`, merge `020d442` (`[PROJECT-F6]: Merge the storehouse and the carried load`), commits `a19b855` (carga y almacén), `ea9ceb2` (entregar), `8b90e60` (arte), `7546d3f` (campamento en el nivel), `fc443ff` (HUD) |

**Goal:** El bucle de *Age of Empires*: recoger, llevarlo al almacén y volver. El jugador solo carga 10 de madera y piedra; lo que entrega en el campamento o en un almacén va al almacén de la aldea, que paga edificios, equipo y habilidades y recibe el oro y el maná de la arena. Así importa dónde se coloca cada edificio.

**Architecture:** Dominio: `Rules.carryCapacity`, `ResourceRules.takesCargo`, la carga en `InventoryRules` (`load`, `freeLoad`, `isLoadFull`, `cargo`, `adding`, `unloading`), `WorldState.stock` con **una** regla de pago (`WorldState.pay`) que usan `World.spend` y `Construction.place`, `World.stock` (`funds` pasa a ser el almacén y `earn` cobra en él), `carryFull` en `ChopResult` / `MineResult`, los planos `storehouse` y `camp` con `BlueprintEntity.isBuildable` / `isDropOff`, `BuildingRules.acceptsDeposits`, `DepositIntentEntity`, `PlayerActivity.depositing`, el sistema interno `Depositing`, `DepositResult`, `DepositedEventEntity`, `World.orderDeposit`, edificios de partida en `World(buildings:)`, `DepositUseCase` y `GetStockUseCase`. Datos: `BuildingDBO`, `LevelDBO.buildings` y `BuildingMapperDBO`: el campamento terminado junto al inicio. Presentación: tocar un edificio entrega antes de reanudar la obra, avisos de carga llena y de entrega, `HudData.stock` + `CarryItemData` en la barra ("Almacén … | Carga 7/10"), umbrales del HUD medidos de nuevo y el `BuildingComponent` que nace terminado. Arte: frames `storehouse` y `camp` desde `build_assets.py`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`, `easy_localization`, `injectable`; Pillow para `build_assets.py`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*. La única excepción es medir los umbrales del HUD con un test de widget de usar y tirar en el *scratchpad* (no se guarda).
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque 2 de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Si cambia la inyección (TF6.1, TF6.2, TF6.4): `dart run build_runner build --delete-conflicting-outputs` y commit de `di.config.dart` tal cual (nunca formateado ni editado a mano). Si cambia `build_assets.py` (TF6.3): regenerar y comprobar que solo aparecen los frames nuevos.
- **Una sola regla de pago:** `WorldState.pay`; `World.spend` y `Construction.place` la usan. Nadie paga del inventario del jugador. `GearUseCase`s, `LearnSkillUseCase` y `StartFightUseCase` **no cambian** (ya pasan por `World.funds` / `spend` / `earn`): el oro y el maná de la arena entran en el almacén, nunca cuentan para la carga, y `balance_test.dart` no se mueve.
- **Determinismo:** F6 no añade ni reordena ninguna tirada de `SeededRandom`; el campamento es una posición fija y la decoración que cae encima se quita **al final**, sin volver a tirar.
- `Depositing` vive en `domain/world/depositing.dart` y es interno: fuera del mundo solo se leen `World.stock` / `funds` y `World.orderDeposit`.
- Textos solo en `es.json`, leídos por `Internationalize`; los textos nuevos no dicen cómo interactuar, así que no llevan variante `…Touch`.
- Sin comentarios en `lib/`; imports relativos; `switch` exhaustivos en el orden de declaración; enums nuevos al final; títulos de commit `[PROJECT-F6]: <frase en inglés en imperativo>`; el commit, en un comando aparte del `git add`.

## Decisiones

Las de la ficha (comprobadas en iOS) más las que salen de Flutter:

1. **Carga.** `PlayerEntity.inventory` es la carga, con sus herramientas. Admite `Rules.carryCapacity = 10` sumando lo que ocupa carga según `ResourceRules.takesCargo` (`domain/world/extensions/resource_rules.dart`): madera y piedra sí, oro y maná no; las herramientas no ocupan. `InventoryRules` gana `load`, `freeLoad` (nunca negativa), `isLoadFull`, `cargo` (solo lo que ocupa carga, con cantidad > 0, en el orden de `Resource.values`), `adding(Map)` (salta cantidades ≤ 0) y `unloading()` (quita lo que ocupa carga y conserva oro, maná y herramientas).
2. **Lo que no cabe se pierde.** `Woodcutting` y `Mining` suman `min(rendimiento, freeLoad)` y `TreeFelledEventEntity.wood` / `RockBrokenEventEntity.stone` llevan lo que **entra** (lo que dicen el aviso y el "+N"). Con la carga llena, talar y picar se rechazan con `carryFull` (al final de `ChopResult` y `MineResult`, comprobado después de `unknown…` y `no…`). Tocar un árbol o una roca con la carga llena avisa con `forest.message.carryFull`; el árbol o la roca que llenan la carga avisan también, después del "+N" y antes de las misiones (`ForestBloc._isGathering` + `isLoadFull` tras reaccionar a los eventos del tick).
3. **El almacén** es `WorldState.stock` (un `InventoryEntity` que solo usa recursos), expuesto por `World.stock`. `World.funds` = `World.stock` (se conservan los dos nombres: `funds` es lo que se puede gastar), `earn` = `stock.adding(reward)` y `spend` = `WorldState.pay`. `Construction.place` comprueba primero `stock.missing(cost)` (`notEnoughResources`), luego el sitio (`blocked`) y cobra con `pay`. `GetBuildOptionsUseCase` mide lo que falta contra `funds`; `GetStockUseCase` (nuevo) lee el almacén; `GetPlayerStatusUseCase` sigue dando el inventario del jugador, que ahora es la carga.
4. **Edificios nuevos** (al final de `BlueprintId`: `camp`, `storehouse`). `BlueprintEntity` gana `isBuildable` (por defecto `true`) e `isDropOff` (por defecto `false`), en `==` y `hashCode`. `Blueprints.storehouse`: 20 de madera, 8 golpes, radio 40, punto de entrega; segundo en `Blueprints.all` y en el menú. `Blueprints.camp`: sin coste, 1 golpe, radio 30, no construible, punto de entrega; último de `all`. `GetBuildOptionsUseCase` solo ofrece los construibles; `Construction.canPlace` da `false` para un plano no construible, así que construir el campamento da el `blocked` de siempre (sin rechazo nuevo). Hasta F7, "punto de entrega" es este booleano. **Diferencia con iOS:** allí `BlueprintId` gana `String` como valor bruto para el DBO; en Dart basta `BlueprintId.name`.
5. **Entregar.** `DepositIntentEntity(buildingId)` + `Depositing` (como `Construction`: el jugador se pone delante, `y + radio + 8 + 2`) y a los 400 ms (`Rules.depositIntervalMs`) pasa **toda** la carga (`cargo`) al almacén y emite `DepositedEventEntity(buildingId, load)` (el evento no estaba en la ficha; lo pide el aviso del final). Si la carga ya está vacía al llegar, no hay evento. `BuildingRules.acceptsDeposits` = terminado y `isDropOff`; si deja de recibir (no puede pasar hoy), el trabajo se para. `DepositResult { ok, unknownBuilding, notADropOff, emptyLoad }` (core, orden de la ficha; iOS los declara en otro orden) y `World.orderDeposit`: edificio desconocido → no recibe (obra a medias o casa) → carga vacía. `PlayerActivity.depositing` (al final) se pinta con la pose quieta (`ForestBloc._workTool` → `null`). `StatsRecording` lo ignora.
6. **Tocar un edificio** (`ForestBloc._orderAtBuilding`): primero `DepositUseCase`. `ok` no dice nada (el aviso "Guardado en el almacén: 7 de madera" llega con el evento); `emptyLoad` avisa "No llevas nada que guardar."; `notADropOff` sigue con `ResumeConstructionUseCase` como hoy (una obra de almacén se reanuda). **Diferencia con iOS:** si la obra no se reanuda (`alreadyComplete`, una casa terminada) o el edificio es desconocido, el toque sigue como en Flutter hasta ahora (roca → árbol → andar), en vez de no hacer nada. Sin efecto en la escena.
7. **El campamento en el nivel.** `BuildingDBO({id, blueprint, x, y})` con `x`/`y` sueltos, como `RockDBO` (la ficha decía `position`). `LevelDBO.buildings: List<BuildingDBO>?` con `BuildingDBO(id: 'camp', blueprint: 'camp', x: 700, y: 592)`, 100 a la izquierda del inicio. `BuildingMapperDBO` (inyectado en `LevelMapperDBO`): sin id, `level-building-<n>`; sin posición, (0, 0); un `blueprint` que no es el `name` de ningún `BlueprintId` es `InvalidLevelException('unknown blueprint <id>: "<blueprint>"')`; llega **terminado** (`hitsDone = hitsToBuild`). `World` y `WorldState` reciben `buildings` (en `World` con `const []` por defecto). Se quita la decoración a menos de 64 del campamento, al final y sin volver a tirar: se va además la 78 y quedan 93 (idéntico a iOS). Árboles, rocas y el pico no cambian.
8. **`BuildingComponent` que nace terminado:** el constructor copia `building.isComplete`; queda opaco, sin barra de obra ni rebote. Lo necesitará también F2.
9. **Misiones:** `gatherWood` mide `world.stock` y su texto pasa a "Lleva 15 de madera al almacén"; `gatherFortyWood` ya medía `funds` y su texto pasa a "Ten 40 de madera en el almacén".
10. **Arte** (sin autores nuevos; el código es el de iOS): `storehouse` = `build_cottage()` con la pared ocre de postes, el techo de paja sin recolorear y dos cajas cerradas del *LPC Tile Atlas* junto a la puerta (120 × 191, pivote (0.5, 1)); `camp` = el tocón de siempre delante de tres troncos hechos con un tramo de tronco del atlas tumbado (106 × 41, pivote (0.5, 1)). `forest.png` sale idéntico al de iOS en `020d442` (99 461 bytes) y ningún frame anterior cambia. `buildingFrontOffset`: almacén 24, campamento 12.
11. **Textos:** `forest.blueprint.camp` "Campamento", `forest.blueprint.storehouse` "Almacén", `forest.hud.stock` "Almacén", `forest.hud.carry` "Carga {amount}/{capacity}", `forest.message.carryFull` "Llevas la carga llena. Déjala en el campamento o en un almacén.", `forest.message.deposited` "Guardado en el almacén: {amounts}" (con `ForestBloc._amounts`, en el orden de `Resource`), `forest.message.nothingToDeposit` "No llevas nada que guardar.".
12. **HUD:** `HudData.stock: List<ResourceItemData>` (del almacén) + `HudData.carry: CarryItemData(text, isFull)` en lugar de `resources`. `ResourceBar(stock:, carry:, tools:, showLabels:)`: rótulo "Almacén" en `hudMuted` (solo con nombres), los cuatro recursos del almacén, "Carga 7/10" tras una raya `hudBorder` (12 de separación; `hudWarning` si está llena; `ResourceBar.carryKey`), y las herramientas. La carga no se desglosa por recurso.
13. **Umbrales del HUD**, medidos con Roboto (test de usar y tirar en el *scratchpad* con `test/helpers/roboto_font.dart`) con 9999 de cada recurso, "Carga 10/10", las dos herramientas y la insignia `15/15`: barra con nombres 909,8 px, botones 484,8 px, barra sin nombres 548,5 px. En una línea hacen falta 12 + 909,8 + 8 + 484,8 + 12 = 1426,6, más la holgura de 24 → **`buttonsBelowWidth = 1460`** (antes 1260). La barra con nombres más márgenes mide 933,8, más 24 → **`narrowWidth = 960`** (antes 770); por debajo, la barra sin nombres (548,5 + 24) cabe en cualquier móvil apaisado. En iOS, con SF Pro, 1500 y 1000 pt.
14. **Navegación** sin cambios (línea recta): desde lejos, el camino al campamento puede quedar cortado ("Hay algo en medio").
15. **Guardado:** en F2 (almacén, carga y edificios con el campamento).

## Reparto

| Tarea | Qué |
|---|---|
| TF6.1 | La carga del jugador y el almacén de la aldea (dominio, misiones, avisos de carga llena) |
| TF6.2 | Entregar en el campamento y en el almacén (planos, sistema, caso de uso, toque) |
| TF6.3 | Frames `storehouse` y `camp` |
| TF6.4 | El campamento en el nivel y el edificio que nace terminado |
| TF6.5 | La carga y el almacén en el HUD (umbrales medidos) |
| TF6.6 | Cierre: T1, `PROGRESS.md`, README, `CLAUDE.md` |

---

### Task TF6.1: La carga del jugador y el almacén de la aldea

**Files:**
- Create: `lib/layers/domain/world/extensions/resource_rules.dart`, `lib/layers/domain/use-cases/game/get_stock_use_case.dart`
- Modify: `lib/core/config/constants/enum/chop_result.dart`, `lib/core/config/constants/enum/mine_result.dart`, `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/world/extensions/inventory_rules.dart`, `lib/layers/domain/world/world_state.dart`, `lib/layers/domain/world/world.dart`, `lib/layers/domain/world/construction.dart`, `lib/layers/domain/world/woodcutting.dart`, `lib/layers/domain/world/mining.dart`, `lib/layers/domain/quests/quests.dart`, `lib/layers/domain/use-cases/game/get_build_options_use_case.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/core/config/di/di.config.dart` (generado)

**Interfaces:**
- Produces: `Rules.carryCapacity == 10`; `ResourceRules.takesCargo`; `InventoryRules.load` / `freeLoad` / `isLoadFull` / `cargo` / `adding(Map<Resource, int>)` / `unloading()`; `WorldState.stock` y `bool WorldState.pay(Map<Resource, int>)`; `World.stock`; `ChopResult.carryFull`, `MineResult.carryFull`; `GetStockUseCase` (`InventoryEntity call()`); `Internationalize.forestMessageCarryFull`.

- [ ] **Step 1: enums y regla** — `carryFull` al final de los dos resultados y `carryCapacity` detrás de `rockHitsToBreak`:

`chop_result.dart`:

```diff
@@ -1 +1 @@
-enum ChopResult { ok, noAxe, unknownTree }
+enum ChopResult { ok, noAxe, unknownTree, carryFull }
```
`mine_result.dart`:

```diff
@@ -1 +1 @@
-enum MineResult { ok, noPickaxe, unknownRock }
+enum MineResult { ok, noPickaxe, unknownRock, carryFull }
```
`rules.dart`:

```diff
@@ -17,4 +17,5 @@ abstract final class Rules {
   static const int rockStoneYield = 8;
   static const int rockHitsToBreak = 8;
+  static const int carryCapacity = 10;
   static const Map<TreeKind, TreeStatsEntity> treeKindStats = {
     TreeKind.slim: TreeStatsEntity(woodYield: 4, hitsToFell: 3),
```
- [ ] **Step 2: qué ocupa carga** (decisión 1) — `resource_rules.dart` nuevo y la carga en `InventoryRules`:

`resource_rules.dart` (nuevo):

```dart
import '../../../../core/config/constants/enum/resource.dart';

extension ResourceRules on Resource {
  bool get takesCargo => switch (this) {
    Resource.wood => true,
    Resource.gold => false,
    Resource.mana => false,
    Resource.stone => true,
  };
}
```
`inventory_rules.dart`:

```diff
@@ -1,7 +1,23 @@
+import 'dart:math';
+
 import '../../../../core/config/constants/enum/resource.dart';
 import '../../../../core/config/constants/enum/tool_kind.dart';
 import '../../entities/player/inventory_entity.dart';
+import '../../rules/rules.dart';
+import 'resource_rules.dart';
 
 extension InventoryRules on InventoryEntity {
+  int get load =>
+      Resource.values.where((resource) => resource.takesCargo).fold(0, (sum, resource) => sum + amount(resource));
+
+  int get freeLoad => max(0, Rules.carryCapacity - load);
+
+  bool get isLoadFull => freeLoad == 0;
+
+  Map<Resource, int> get cargo => {
+    for (final resource in Resource.values)
+      if (resource.takesCargo && amount(resource) > 0) resource: amount(resource),
+  };
+
   int amount(Resource resource) => resources[resource] ?? 0;
 
@@ -14,4 +30,15 @@ extension InventoryRules on InventoryEntity {
   }
 
+  InventoryEntity adding(Map<Resource, int> amounts) {
+    var inventory = this;
+    for (final resource in Resource.values) {
+      final quantity = amounts[resource] ?? 0;
+      if (quantity > 0) inventory = inventory.add(resource, quantity);
+    }
+    return inventory;
+  }
+
+  InventoryEntity unloading() => copyWith(resources: {...resources}..removeWhere((resource, _) => resource.takesCargo));
+
   Map<Resource, int> missing(Map<Resource, int> cost) {
     for (final MapEntry(key: resource, value: quantity) in cost.entries) {
```
- [ ] **Step 3: el almacén y la regla de pago** (decisión 3):

`world_state.dart`:

```diff
@@ -1,4 +1,5 @@
 import 'dart:math';
 
+import '../../../core/config/constants/enum/resource.dart';
 import '../entities/building/building_entity.dart';
 import '../entities/decoration/decoration_entity.dart';
@@ -8,8 +9,10 @@ import '../entities/geometry/position_entity.dart';
 import '../entities/hero/hero_entity.dart';
 import '../entities/item/ground_item_entity.dart';
+import '../entities/player/inventory_entity.dart';
 import '../entities/player/player_entity.dart';
 import '../entities/rock/rock_entity.dart';
 import '../entities/tree/stump_entity.dart';
 import '../entities/tree/tree_entity.dart';
+import 'extensions/inventory_rules.dart';
 import 'extensions/obstacle_rules.dart';
 
@@ -41,4 +44,5 @@ class WorldState {
   final Map<String, StumpEntity> stumps = {};
   StatsEntity stats = const StatsEntity();
+  InventoryEntity stock = const InventoryEntity();
   final Map<String, int> _idCounters = {};
 
@@ -59,4 +63,11 @@ class WorldState {
   bool isInside(PositionEntity position, double margin) => clamp(position, margin) == position;
 
+  bool pay(Map<Resource, int> cost) {
+    final remaining = stock.spend(cost);
+    if (remaining == null) return false;
+    stock = remaining;
+    return true;
+  }
+
   String nextId(String prefix) {
     final next = (_idCounters[prefix] ?? 0) + 1;
```
`world.dart`:

```diff
@@ -82,4 +82,6 @@ class World {
   StatsEntity get stats => _state.stats;
 
+  InventoryEntity get stock => _state.stock;
+
   HeroEntity get hero => _state.hero;
 
@@ -131,20 +133,11 @@ class World {
       Construction.canPlace(_state, blueprint, position);
 
-  InventoryEntity get funds => _state.player.inventory;
+  InventoryEntity get funds => _state.stock;
 
   void earn(Map<Resource, int> reward) {
-    var inventory = _state.player.inventory;
-    for (final MapEntry(key: resource, value: quantity) in reward.entries) {
-      if (quantity > 0) inventory = inventory.add(resource, quantity);
-    }
-    _state.player = _state.player.copyWith(inventory: inventory);
+    _state.stock = _state.stock.adding(reward);
   }
 
-  bool spend(Map<Resource, int> cost) {
-    final remaining = _state.player.inventory.spend(cost);
-    if (remaining == null) return false;
-    _state.player = _state.player.copyWith(inventory: remaining);
-    return true;
-  }
+  bool spend(Map<Resource, int> cost) => _state.pay(cost);
 
   void updateHero(HeroEntity Function(HeroEntity hero) transform) {
```
`construction.dart`:

```diff
@@ -11,5 +11,4 @@ import 'extensions/building_rules.dart';
 import 'extensions/inventory_rules.dart';
 import 'extensions/obstacle_rules.dart';
-import 'extensions/player_rules.dart';
 import 'extensions/position_geometry.dart';
 import 'work.dart';
@@ -28,10 +27,11 @@ final class Construction implements Work<ConstructIntentEntity> {
 
   static ConstructionResultEntity place(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
-    final paid = state.player.inventory.spend(blueprint.cost);
-    if (paid == null) return const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources);
+    if (state.stock.missing(blueprint.cost).isNotEmpty) {
+      return const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughResources);
+    }
     if (!canPlace(state, blueprint, position)) {
       return const ConstructionRejectedEntity(reason: ConstructionRejection.blocked);
     }
-    state.player = state.player.withInventory(paid);
+    state.pay(blueprint.cost);
     final building = BuildingEntity(id: state.nextId('building'), blueprint: blueprint, position: position);
     state.buildings[building.id] = building;
```
- [ ] **Step 4: lo que no cabe se pierde** (decisión 2):

`woodcutting.dart`:

```diff
@@ -1,2 +1,4 @@
+import 'dart:math';
+
 import '../../../core/config/constants/enum/chop_result.dart';
 import '../../../core/config/constants/enum/resource.dart';
@@ -20,4 +22,5 @@ final class Woodcutting implements Work<ChopIntentEntity> {
     if (!state.trees.containsKey(treeId)) return ChopResult.unknownTree;
     if (!state.player.inventory.hasTool(ToolKind.axe)) return ChopResult.noAxe;
+    if (state.player.inventory.isLoadFull) return ChopResult.carryFull;
     return ChopResult.ok;
   }
@@ -49,6 +52,7 @@ final class Woodcutting implements Work<ChopIntentEntity> {
     state.trees.remove(tree.id);
     state.stumps[tree.id] = StumpEntity(id: tree.id, kind: tree.kind, position: tree.position);
-    state.player = state.player.withInventory(state.player.inventory.add(Resource.wood, tree.woodYield));
-    events.add(TreeFelledEventEntity(treeId: tree.id, wood: tree.woodYield));
+    final wood = min(tree.woodYield, state.player.inventory.freeLoad);
+    state.player = state.player.withInventory(state.player.inventory.add(Resource.wood, wood));
+    events.add(TreeFelledEventEntity(treeId: tree.id, wood: wood));
     return true;
   }
```
`mining.dart`:

```diff
@@ -1,2 +1,4 @@
+import 'dart:math';
+
 import '../../../core/config/constants/enum/mine_result.dart';
 import '../../../core/config/constants/enum/resource.dart';
@@ -19,4 +21,5 @@ final class Mining implements Work<MineIntentEntity> {
     if (!state.rocks.containsKey(rockId)) return MineResult.unknownRock;
     if (!state.player.inventory.hasTool(ToolKind.pickaxe)) return MineResult.noPickaxe;
+    if (state.player.inventory.isLoadFull) return MineResult.carryFull;
     return MineResult.ok;
   }
@@ -47,6 +50,7 @@ final class Mining implements Work<MineIntentEntity> {
     }
     state.rocks.remove(rock.id);
-    state.player = state.player.withInventory(state.player.inventory.add(Resource.stone, rock.stoneYield));
-    events.add(RockBrokenEventEntity(rockId: rock.id, stone: rock.stoneYield));
+    final stone = min(rock.stoneYield, state.player.inventory.freeLoad);
+    state.player = state.player.withInventory(state.player.inventory.add(Resource.stone, stone));
+    events.add(RockBrokenEventEntity(rockId: rock.id, stone: stone));
     return true;
   }
```
- [ ] **Step 5: misiones, opciones de construcción y `GetStockUseCase`** (decisiones 3 y 9):

`quests.dart`:

```diff
@@ -19,5 +19,5 @@ abstract final class Quests {
       line: QuestLine.village,
       target: 15,
-      measure: (world) => world.player.inventory.amount(Resource.wood),
+      measure: (world) => world.stock.amount(Resource.wood),
     ),
     _MeasuredQuest(
```
`get_build_options_use_case.dart`:

```diff
@@ -13,5 +13,5 @@ final class GetBuildOptionsUseCase {
 
   List<BuildOptionEntity> call() {
-    final inventory = _sessionRepository.current().world.player.inventory;
+    final funds = _sessionRepository.current().world.funds;
     return Blueprints.all
         .map(
@@ -19,5 +19,5 @@ final class GetBuildOptionsUseCase {
             blueprint: blueprint.id,
             cost: blueprint.cost,
-            missing: inventory.missing(blueprint.cost),
+            missing: funds.missing(blueprint.cost),
           ),
         )
```
`get_stock_use_case.dart` (nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../entities/player/inventory_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class GetStockUseCase {
  final GameSessionRepository _sessionRepository;

  const GetStockUseCase({required this._sessionRepository});

  InventoryEntity call() => _sessionRepository.current().world.stock;
}
```
- [ ] **Step 6: textos y avisos de carga llena** (decisiones 2, 9 y 11):

`es.json`:

```diff
@@ -56,5 +56,5 @@
     },
     "quest": {
-      "gatherWood": "Consigue al menos 15 de madera",
+      "gatherWood": "Lleva 15 de madera al almacén",
       "buildHouse": "Construye una casa",
       "buildForge": "Construye la Herrería",
@@ -68,5 +68,5 @@
       "fellTenTrees": "Tala 10 árboles",
       "fellAnOak": "Tala un roble",
-      "gatherFortyWood": "Ten 40 de madera a la vez",
+      "gatherFortyWood": "Ten 40 de madera en el almacén",
       "buildTwoHouses": "Ten 2 casas terminadas",
       "seeATreeRegrow": "Ve rebrotar un árbol"
@@ -91,4 +91,5 @@
       "woodGained": "+{wood} de madera",
       "stoneGained": "+{amount} de piedra",
+      "carryFull": "Llevas la carga llena. Déjala en el campamento o en un almacén.",
       "placing": "Elige dónde construir: {name}. Clic derecho o Esc para cancelar.",
       "placingTouch": "Elige dónde construir: {name}. Arrastra el dedo para moverlo y toca Construir aquí o Cancelar.",
```
`internationalize.dart`:

```diff
@@ -108,4 +108,5 @@ class Internationalize {
   static String forestMessageStoneGained({required int amount}) =>
       '$_forest.message.stoneGained'.tr(namedArgs: {'amount': '$amount'});
+  static String get forestMessageCarryFull => '$_forest.message.carryFull'.tr();
   static String forestMessagePlacing({required String name}) =>
       '$_forest.message.placing'.tr(namedArgs: {'name': name});
```
`forest_bloc.dart`:

```diff
@@ -170,4 +170,7 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
       _react(gameEvent, fromX: fromX, effects: effects);
     }
+    if (gameEvents.any(_isGathering) && _getPlayerStatusUseCase().inventory.isLoadFull) {
+      _showMessage(Internationalize.forestMessageCarryFull);
+    }
     _announceQuests([
       for (final gameEvent in gameEvents)
@@ -228,6 +231,11 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     }
     if (rockId != null) {
-      if (_mineRockUseCase(rockId: rockId) == MineResult.noPickaxe) {
-        _showMessage(Internationalize.forestMessageNeedPickaxe);
+      switch (_mineRockUseCase(rockId: rockId)) {
+        case MineResult.ok || MineResult.unknownRock:
+          break;
+        case MineResult.noPickaxe:
+          _showMessage(Internationalize.forestMessageNeedPickaxe);
+        case MineResult.carryFull:
+          _showMessage(Internationalize.forestMessageCarryFull);
       }
       return;
@@ -237,6 +245,11 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
       return;
     }
-    if (_chopTreeUseCase(treeId: treeId) == ChopResult.noAxe) {
-      _showMessage(Internationalize.forestMessageNeedAxe);
+    switch (_chopTreeUseCase(treeId: treeId)) {
+      case ChopResult.ok || ChopResult.unknownTree:
+        break;
+      case ChopResult.noAxe:
+        _showMessage(Internationalize.forestMessageNeedAxe);
+      case ChopResult.carryFull:
+        _showMessage(Internationalize.forestMessageCarryFull);
     }
   }
@@ -372,4 +385,7 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
   }
 
+  bool _isGathering(GameEventEntity gameEvent) =>
+      gameEvent is TreeFelledEventEntity || gameEvent is RockBrokenEventEntity;
+
   void _announceQuests(List<QuestId> completed) {
     if (completed.isEmpty) return;
```
- [ ] **Step 7: Verificar**

```sh
dart run build_runner build --delete-conflicting-outputs   # registra GetStockUseCase
dart format --line-length 120 lib/layers/domain lib/core/config/constants/enum lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 8: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F6]: Split the carried load from the village stock`.

### Task TF6.2: Entregar en el campamento y en el almacén

**Files:**
- Create: `lib/core/config/constants/enum/deposit_result.dart`, `lib/layers/domain/world/depositing.dart`, `lib/layers/domain/use-cases/game/deposit_use_case.dart`
- Modify: `lib/core/config/constants/enum/blueprint_id.dart`, `lib/core/config/constants/enum/player_activity.dart`, `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/entities/building/blueprint_entity.dart`, `lib/layers/domain/rules/blueprints.dart`, `lib/layers/domain/world/extensions/building_rules.dart`, `lib/layers/domain/entities/player/intent_entity.dart`, `lib/layers/domain/entities/game/game_event_entity.dart`, `lib/layers/domain/world/stats_recording.dart`, `lib/layers/domain/world/extensions/activity_rules.dart`, `lib/layers/domain/world/work.dart`, `lib/layers/domain/world/world_state.dart`, `lib/layers/domain/world/world.dart`, `lib/layers/domain/world/construction.dart`, `lib/layers/domain/use-cases/game/get_build_options_use_case.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`, `lib/layers/presentation/features/forest/game/render/render_constants.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/forest_page.dart`, `lib/core/config/di/di.config.dart` (generado)

**Interfaces:**
- Consumes: TF6.1 (`InventoryRules.load` / `cargo` / `adding` / `unloading`, `WorldState.stock`).
- Produces: `enum BlueprintId { house, forge, armory, mageTower, camp, storehouse }`; `enum PlayerActivity { …, mining, depositing }`; `enum DepositResult { ok, unknownBuilding, notADropOff, emptyLoad }`; `BlueprintEntity.isBuildable` / `isDropOff`; `Blueprints.storehouse` / `Blueprints.camp`; `BuildingRules.acceptsDeposits`; `DepositIntentEntity(buildingId)`; `DepositedEventEntity(buildingId, load)`; `World({…, List<BuildingEntity> buildings = const []})`; `DepositResult World.orderDeposit(String buildingId)`; `DepositUseCase` (`DepositResult call({required String buildingId})`); `SpriteNames.building(BlueprintId.camp) == 'camp'`, `…storehouse == 'storehouse'` (los frames llegan en TF6.3; el campamento sale en el nivel en TF6.4); `ForestBloc(depositUseCase:)`.

- [ ] **Step 1: enums, resultado y regla** (decisiones 4 y 5):

`blueprint_id.dart`:

```diff
@@ -1 +1 @@
-enum BlueprintId { house, forge, armory, mageTower }
+enum BlueprintId { house, forge, armory, mageTower, camp, storehouse }
```
`player_activity.dart`:

```diff
@@ -1 +1 @@
-enum PlayerActivity { idle, walking, chopping, constructing, mining }
+enum PlayerActivity { idle, walking, chopping, constructing, mining, depositing }
```
`deposit_result.dart` (nuevo):

```dart
enum DepositResult { ok, unknownBuilding, notADropOff, emptyLoad }
```
`rules.dart`:

```diff
@@ -6,4 +6,5 @@ abstract final class Rules {
   static const double hammerIntervalMs = 650;
   static const double mineIntervalMs = 750;
+  static const double depositIntervalMs = 400;
   static const double workGap = 2;
   static const double reachTolerance = 6;
```
- [ ] **Step 2: planos** (decisión 4):

`blueprint_entity.dart`:

```diff
@@ -9,4 +9,6 @@ class BlueprintEntity {
   final int hitsToBuild;
   final double footprintRadius;
+  final bool isBuildable;
+  final bool isDropOff;
 
   const BlueprintEntity({
@@ -15,4 +17,6 @@ class BlueprintEntity {
     required this.hitsToBuild,
     required this.footprintRadius,
+    this.isBuildable = true,
+    this.isDropOff = false,
   });
 
@@ -23,7 +27,16 @@ class BlueprintEntity {
       const MapEquality<Resource, int>().equals(other.cost, cost) &&
       other.hitsToBuild == hitsToBuild &&
-      other.footprintRadius == footprintRadius;
+      other.footprintRadius == footprintRadius &&
+      other.isBuildable == isBuildable &&
+      other.isDropOff == isDropOff;
 
   @override
-  int get hashCode => Object.hash(id, const MapEquality<Resource, int>().hash(cost), hitsToBuild, footprintRadius);
+  int get hashCode => Object.hash(
+    id,
+    const MapEquality<Resource, int>().hash(cost),
+    hitsToBuild,
+    footprintRadius,
+    isBuildable,
+    isDropOff,
+  );
 }
```
`blueprints.dart`:

```diff
@@ -11,4 +11,12 @@ abstract final class Blueprints {
   );
 
+  static const BlueprintEntity storehouse = BlueprintEntity(
+    id: BlueprintId.storehouse,
+    cost: {Resource.wood: 20},
+    hitsToBuild: 8,
+    footprintRadius: 40,
+    isDropOff: true,
+  );
+
   static const BlueprintEntity forge = BlueprintEntity(
     id: BlueprintId.forge,
@@ -32,5 +40,14 @@ abstract final class Blueprints {
   );
 
-  static const List<BlueprintEntity> all = [house, forge, armory, mageTower];
+  static const BlueprintEntity camp = BlueprintEntity(
+    id: BlueprintId.camp,
+    cost: {},
+    hitsToBuild: 1,
+    footprintRadius: 30,
+    isBuildable: false,
+    isDropOff: true,
+  );
+
+  static const List<BlueprintEntity> all = [house, storehouse, forge, armory, mageTower, camp];
 
   static BlueprintEntity of(BlueprintId id) => all.firstWhere((blueprint) => blueprint.id == id);
```
`building_rules.dart`:

```diff
@@ -3,4 +3,6 @@ import '../../entities/building/building_entity.dart';
 
 extension BuildingRules on BuildingEntity {
+  bool get acceptsDeposits => isComplete && blueprint.isDropOff;
+
   BuildingEntity hammer() => isComplete ? this : copyWith(hitsDone: hitsDone + 1);
 }
```
- [ ] **Step 3: intención, evento y actividad** (decisión 5):

`intent_entity.dart`:

```diff
@@ -38,2 +38,14 @@ final class MineIntentEntity extends IntentEntity {
   int get hashCode => Object.hash(MineIntentEntity, rockId);
 }
+
+final class DepositIntentEntity extends IntentEntity {
+  final String buildingId;
+
+  const DepositIntentEntity({required this.buildingId});
+
+  @override
+  bool operator ==(Object other) => other is DepositIntentEntity && other.buildingId == buildingId;
+
+  @override
+  int get hashCode => Object.hash(DepositIntentEntity, buildingId);
+}
```
`game_event_entity.dart`:

```diff
@@ -1,4 +1,7 @@
+import 'package:collection/collection.dart';
+
 import '../../../../core/config/constants/enum/blueprint_id.dart';
 import '../../../../core/config/constants/enum/quest_id.dart';
+import '../../../../core/config/constants/enum/resource.dart';
 import '../../../../core/config/constants/enum/tool_kind.dart';
 import '../tree/tree_entity.dart';
@@ -146,2 +149,18 @@ final class RockBrokenEventEntity extends GameEventEntity {
   int get hashCode => Object.hash(RockBrokenEventEntity, rockId, stone);
 }
+
+final class DepositedEventEntity extends GameEventEntity {
+  final String buildingId;
+  final Map<Resource, int> load;
+
+  const DepositedEventEntity({required this.buildingId, required this.load});
+
+  @override
+  bool operator ==(Object other) =>
+      other is DepositedEventEntity &&
+      other.buildingId == buildingId &&
+      const MapEquality<Resource, int>().equals(other.load, load);
+
+  @override
+  int get hashCode => Object.hash(DepositedEventEntity, buildingId, const MapEquality<Resource, int>().hash(load));
+}
```
`stats_recording.dart`:

```diff
@@ -20,5 +20,5 @@ abstract final class StatsRecording {
       QuestCompletedEventEntity() || TreeSproutedEventEntity() => stats,
       TreeRegrownEventEntity() => stats.regrowingTree(),
-      RockHitEventEntity() || RockBrokenEventEntity() => stats,
+      RockHitEventEntity() || RockBrokenEventEntity() || DepositedEventEntity() => stats,
     };
   }
```
`activity_rules.dart`:

```diff
@@ -11,4 +11,5 @@ extension ActivityRules on ActivityEntity {
       ConstructIntentEntity() => PlayerActivity.constructing,
       MineIntentEntity() => PlayerActivity.mining,
+      DepositIntentEntity() => PlayerActivity.depositing,
     },
   };
```
- [ ] **Step 4: el sistema `Depositing`** (decisión 5):

`depositing.dart` (nuevo):

```dart
import '../../../core/config/constants/enum/deposit_result.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/building_rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'work.dart';
import 'world_state.dart';

final class Depositing implements Work<DepositIntentEntity> {
  const Depositing();

  static DepositResult check(WorldState state, String buildingId) {
    final building = state.buildings[buildingId];
    if (building == null) return DepositResult.unknownBuilding;
    if (!building.acceptsDeposits) return DepositResult.notADropOff;
    if (state.player.inventory.load == 0) return DepositResult.emptyLoad;
    return DepositResult.ok;
  }

  @override
  double get intervalMs => Rules.depositIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, DepositIntentEntity intent) {
    final building = state.buildings[intent.buildingId];
    if (building == null || !building.acceptsDeposits) return null;
    return building.footprint;
  }

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) => [
    PositionEntity(x: target.position.x, y: target.position.y + distance),
  ];

  @override
  bool impact(WorldState state, DepositIntentEntity intent, List<GameEventEntity> events) {
    final load = state.player.inventory.cargo;
    if (load.isEmpty) return true;
    state.player = state.player.withInventory(state.player.inventory.unloading());
    state.stock = state.stock.adding(load);
    events.add(DepositedEventEntity(buildingId: intent.buildingId, load: load));
    return true;
  }
}
```
`work.dart`:

```diff
@@ -4,4 +4,5 @@ import '../entities/geometry/position_entity.dart';
 import '../entities/player/intent_entity.dart';
 import 'construction.dart';
+import 'depositing.dart';
 import 'mining.dart';
 import 'woodcutting.dart';
@@ -38,3 +39,4 @@ BoundWork<IntentEntity> workFor(IntentEntity intent) => switch (intent) {
   ConstructIntentEntity() => BoundWork<ConstructIntentEntity>(const Construction(), intent),
   MineIntentEntity() => BoundWork<MineIntentEntity>(const Mining(), intent),
+  DepositIntentEntity() => BoundWork<DepositIntentEntity>(const Depositing(), intent),
 };
```
- [ ] **Step 5: edificios de partida, `orderDeposit` y planos no construibles** (decisiones 4, 5 y 7):

`world_state.dart`:

```diff
@@ -26,4 +26,5 @@ class WorldState {
     required List<DecorationEntity> decorations,
     required List<RockEntity> rocks,
+    required List<BuildingEntity> buildings,
     this.hero = const HeroEntity(),
   }) : assert(width > 0 && height > 0),
@@ -31,4 +32,5 @@ class WorldState {
        items = {for (final item in items) item.id: item},
        rocks = {for (final rock in rocks) rock.id: rock},
+       buildings = {for (final building in buildings) building.id: building},
        decorations = List.unmodifiable(decorations);
 
@@ -41,5 +43,5 @@ class WorldState {
   final Map<String, GroundItemEntity> items;
   final Map<String, RockEntity> rocks;
-  final Map<String, BuildingEntity> buildings = {};
+  final Map<String, BuildingEntity> buildings;
   final Map<String, StumpEntity> stumps = {};
   StatsEntity stats = const StatsEntity();
```
`world.dart`:

```diff
@@ -2,4 +2,5 @@ import 'package:meta/meta.dart';
 
 import '../../../core/config/constants/enum/chop_result.dart';
+import '../../../core/config/constants/enum/deposit_result.dart';
 import '../../../core/config/constants/enum/mine_result.dart';
 import '../../../core/config/constants/enum/resource.dart';
@@ -23,4 +24,5 @@ import '../entities/tree/stump_entity.dart';
 import '../entities/tree/tree_entity.dart';
 import 'construction.dart';
+import 'depositing.dart';
 import 'mining.dart';
 import 'extensions/inventory_rules.dart';
@@ -43,4 +45,5 @@ class World {
     List<DecorationEntity> decorations = const [],
     List<RockEntity> rocks = const [],
+    List<BuildingEntity> buildings = const [],
     HeroEntity hero = const HeroEntity(),
   }) : this._(
@@ -53,4 +56,5 @@ class World {
            decorations: decorations,
            rocks: rocks,
+           buildings: buildings,
            hero: hero,
          ),
@@ -114,4 +118,10 @@ class World {
   }
 
+  DepositResult orderDeposit(String buildingId) {
+    final result = Depositing.check(_state, buildingId);
+    if (result == DepositResult.ok) _navigation.goWorkOn(DepositIntentEntity(buildingId: buildingId));
+    return result;
+  }
+
   ConstructionResultEntity orderConstruction(BlueprintEntity blueprint, PositionEntity position) {
     final result = Construction.place(_state, blueprint, position);
```
`construction.dart`:

```diff
@@ -23,5 +23,9 @@ final class Construction implements Work<ConstructIntentEntity> {
     final overlapsPlayer = position.distanceTo(player.position) < radius + player.radius;
     final overlapsItem = state.items.values.any((item) => position.distanceTo(item.position) < radius);
-    return state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem;
+    return blueprint.isBuildable &&
+        state.isInside(position, radius) &&
+        !state.isBlocked(position, radius) &&
+        !overlapsPlayer &&
+        !overlapsItem;
   }
 
```
`get_build_options_use_case.dart`:

```diff
@@ -15,4 +15,5 @@ final class GetBuildOptionsUseCase {
     final funds = _sessionRepository.current().world.funds;
     return Blueprints.all
+        .where((blueprint) => blueprint.isBuildable)
         .map(
           (blueprint) => BuildOptionEntity(
```
`deposit_use_case.dart` (nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/deposit_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class DepositUseCase {
  final GameSessionRepository _sessionRepository;

  const DepositUseCase({required this._sessionRepository});

  DepositResult call({required String buildingId}) => _sessionRepository.current().world.orderDeposit(buildingId);
}
```
- [ ] **Step 6: nombres, frames y pie de los edificios nuevos** (decisiones 10 y 11):

`es.json`:

```diff
@@ -53,5 +53,7 @@
       "forge": "Herrería",
       "armory": "Armería",
-      "mageTower": "Torre de magia"
+      "mageTower": "Torre de magia",
+      "camp": "Campamento",
+      "storehouse": "Almacén"
     },
     "quest": {
@@ -92,4 +94,6 @@
       "stoneGained": "+{amount} de piedra",
       "carryFull": "Llevas la carga llena. Déjala en el campamento o en un almacén.",
+      "deposited": "Guardado en el almacén: {amounts}",
+      "nothingToDeposit": "No llevas nada que guardar.",
       "placing": "Elige dónde construir: {name}. Clic derecho o Esc para cancelar.",
       "placingTouch": "Elige dónde construir: {name}. Arrastra el dedo para moverlo y toca Construir aquí o Cancelar.",
```
`internationalize.dart`:

```diff
@@ -69,4 +69,6 @@ class Internationalize {
     BlueprintId.armory => '$_forest.blueprint.armory'.tr(),
     BlueprintId.mageTower => '$_forest.blueprint.mageTower'.tr(),
+    BlueprintId.camp => '$_forest.blueprint.camp'.tr(),
+    BlueprintId.storehouse => '$_forest.blueprint.storehouse'.tr(),
   };
   static String forestQuestTitle({required QuestId id}) => switch (id) {
@@ -109,4 +111,7 @@ class Internationalize {
       '$_forest.message.stoneGained'.tr(namedArgs: {'amount': '$amount'});
   static String get forestMessageCarryFull => '$_forest.message.carryFull'.tr();
+  static String forestMessageDeposited({required String amounts}) =>
+      '$_forest.message.deposited'.tr(namedArgs: {'amounts': amounts});
+  static String get forestMessageNothingToDeposit => '$_forest.message.nothingToDeposit'.tr();
   static String forestMessagePlacing({required String name}) =>
       '$_forest.message.placing'.tr(namedArgs: {'name': name});
```
`sprite_names.dart`:

```diff
@@ -19,4 +19,6 @@ abstract final class SpriteNames {
     BlueprintId.armory => 'armory',
     BlueprintId.mageTower => 'mage-tower',
+    BlueprintId.camp => 'camp',
+    BlueprintId.storehouse => 'storehouse',
   };
 
```
`render_constants.dart`:

```diff
@@ -30,4 +30,6 @@ abstract final class RenderConstants {
     BlueprintId.armory => 24,
     BlueprintId.mageTower => 24,
+    BlueprintId.camp => 12,
+    BlueprintId.storehouse => 24,
   };
 
```
- [ ] **Step 7: tocar un edificio entrega** (decisiones 5 y 6):

`forest_bloc.dart`:

```diff
@@ -8,4 +8,5 @@ import '../../../../../core/config/constants/enum/buy_gear_result.dart';
 import '../../../../../core/config/constants/enum/chop_result.dart';
 import '../../../../../core/config/constants/enum/construction_rejection.dart';
+import '../../../../../core/config/constants/enum/deposit_result.dart';
 import '../../../../../core/config/constants/enum/forest/facing.dart';
 import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
@@ -44,4 +45,5 @@ import '../../../../domain/use-cases/game/chop_tree_use_case.dart';
 import '../../../../domain/use-cases/game/resume_construction_use_case.dart';
 import '../../../../domain/use-cases/game/construct_building_use_case.dart';
+import '../../../../domain/use-cases/game/deposit_use_case.dart';
 import '../../../../domain/use-cases/game/get_build_options_use_case.dart';
 import '../../../../domain/use-cases/game/get_player_status_use_case.dart';
@@ -84,4 +86,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
   final ConstructBuildingUseCase _constructBuildingUseCase;
   final ResumeConstructionUseCase _resumeConstructionUseCase;
+  final DepositUseCase _depositUseCase;
   final AdvanceGameUseCase _advanceGameUseCase;
   final GetPlayerStatusUseCase _getPlayerStatusUseCase;
@@ -110,4 +113,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     required this._constructBuildingUseCase,
     required this._resumeConstructionUseCase,
+    required this._depositUseCase,
     required this._advanceGameUseCase,
     required this._getPlayerStatusUseCase,
@@ -227,7 +231,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     required String? rockId,
   }) {
-    if (buildingId != null && _resumeConstructionUseCase(buildingId: buildingId) == ResumeConstructionResult.ok) {
-      return;
-    }
+    if (buildingId != null && _orderAtBuilding(buildingId)) return;
     if (rockId != null) {
       switch (_mineRockUseCase(rockId: rockId)) {
@@ -255,4 +257,18 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
   }
 
+  bool _orderAtBuilding(String buildingId) {
+    switch (_depositUseCase(buildingId: buildingId)) {
+      case DepositResult.ok:
+        return true;
+      case DepositResult.unknownBuilding:
+        return false;
+      case DepositResult.notADropOff:
+        return _resumeConstructionUseCase(buildingId: buildingId) == ResumeConstructionResult.ok;
+      case DepositResult.emptyLoad:
+        _showMessage(Internationalize.forestMessageNothingToDeposit);
+        return true;
+    }
+  }
+
   void _movePlacement(PositionEntity position) {
     final placement = _placement;
@@ -382,4 +398,6 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
         _showMessage(Internationalize.forestMessageStoneGained(amount: stone));
         effects.add(RockBrokenEffect(rockId: rockId, stone: stone));
+      case DepositedEventEntity(:final load):
+        _showMessage(Internationalize.forestMessageDeposited(amounts: _amounts(load)));
     }
   }
@@ -454,4 +472,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     PlayerActivity.constructing => WorkTool.hammer,
     PlayerActivity.mining => WorkTool.pickaxe,
+    PlayerActivity.depositing => null,
   };
 
```
`forest_page.dart`:

```diff
@@ -15,4 +15,5 @@ import '../../../domain/use-cases/game/mine_rock_use_case.dart';
 import '../../../domain/use-cases/game/resume_construction_use_case.dart';
 import '../../../domain/use-cases/game/construct_building_use_case.dart';
+import '../../../domain/use-cases/game/deposit_use_case.dart';
 import '../../../domain/use-cases/game/get_build_options_use_case.dart';
 import '../../../domain/use-cases/game/get_player_status_use_case.dart';
@@ -54,4 +55,5 @@ class ForestPage extends StatelessWidget {
         constructBuildingUseCase: locator.get<ConstructBuildingUseCase>(),
         resumeConstructionUseCase: locator.get<ResumeConstructionUseCase>(),
+        depositUseCase: locator.get<DepositUseCase>(),
         advanceGameUseCase: locator.get<AdvanceGameUseCase>(),
         getPlayerStatusUseCase: locator.get<GetPlayerStatusUseCase>(),
```
- [ ] **Step 8: Verificar**

```sh
dart run build_runner build --delete-conflicting-outputs   # registra DepositUseCase
dart format --line-length 120 lib/layers/domain lib/core/config/constants/enum lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/forest
flutter analyze lib
```
Esperado: `No issues found!` (el analizador señala cualquier `switch` sobre `BlueprintId`, `PlayerActivity`, `IntentEntity` o `GameEventEntity` que falte).

- [ ] **Step 9: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F6]: Deposit the load at the camp and the storehouse`.

### Task TF6.3: Frames `storehouse` y `camp`

**Files:**
- Modify: `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/forest.{png,json}` (generados), `lib/core/assets/images/lpc/CREDITS.md`

**Interfaces:**
- Produces: frames `storehouse` (120 × 191, pivote (0.5, 1)) y `camp` (106 × 41, pivote (0.5, 1)) en `forest.json`.

- [ ] **Step 1: `build_assets.py`** (el código de iOS, tarea 3 de su plan; la parte del bosque del script es igual en los dos repos):

`build_assets.py`:

```diff
@@ -10,6 +10,6 @@ Outputs (into lib/core/assets/images/lpc/, the one copy the Flutter app reads on
                                    back and front layers (same layout as the LPC generator)
   forest.png + forest.json         JSON-hash atlas (TexturePacker format): trees and sapling (pivot = trunk base), decor, stump,
-                                   large rock, axe and pickaxe pickups, the house, the forge, the armory and the mage tower
-                                   (pivot = bottom centre)
+                                   large rock, axe and pickaxe pickups, the house, the forge, the armory, the mage tower,
+                                   the storehouse and the camp (pivot = bottom centre)
   ground.png                       grass tile(s) for the tilemap (32x32 each, in a row)
   arena.png + arena.json           JSON-hash atlas for the arena: the hero (with the axe and each sword, in
@@ -194,4 +194,12 @@ MAGE_TOWER_ROOF = [(30, 16, 40), (38, 20, 52), (62, 30, 92), (78, 40, 112), (96,
 MAGE_TOWER_WALL_BOX = (96, 256, 192, 352)  # cottage.png, stone wall with long diagonal braces
 MAGE_TOWER_ROOF_STRETCH = 1.4  # the violet roof is drawn 40 % taller, like a spire
+STOREHOUSE_WALL_BOX = (288, 0, 384, 96)  # cottage.png, ochre wall with vertical posts
+CRATE_BOX = (672, 576, 704, 608)  # terrain_atlas.png, a closed wooden chest with iron bands
+CRATE_SCALE = 0.75  # the crates beside the storehouse door are drawn at three quarters of their size
+CRATE_INSET = 14  # distance from each crate to the side of the storehouse image
+CAMP_LOG_BOX = (776, 576, 792, 606)  # terrain_atlas.png, a straight piece of trunk; lying down it is a log
+CAMP_LOG_GAP = 2  # pixels between the two bottom logs
+CAMP_LOG_OVERLAP = 4  # the top log sinks into the two below
+CAMP_STUMP_OVERLAP = 6  # the stump stands in front of the log pile
 
 
@@ -286,4 +294,27 @@ def build_mage_tower() -> Image.Image:
 
 
+def build_storehouse(terrain: Image.Image) -> Image.Image:
+    image = build_cottage(STOREHOUSE_WALL_BOX)
+    crate = trim(terrain.crop(CRATE_BOX), "crate")
+    crate = crate.resize((round(crate.width * CRATE_SCALE), round(crate.height * CRATE_SCALE)), Image.NEAREST)
+    image.alpha_composite(crate, (CRATE_INSET, image.height - crate.height))
+    image.alpha_composite(crate, (image.width - CRATE_INSET - crate.width, image.height - crate.height))
+    return image
+
+
+def build_camp(terrain: Image.Image) -> Image.Image:
+    """The first drop-off point: the tree stump in front of a pile of three logs."""
+    log = trim(terrain.crop(CAMP_LOG_BOX), "camp log").rotate(90, expand=True)
+    pile = Image.new("RGBA", (log.width * 2 + CAMP_LOG_GAP, log.height * 2 - CAMP_LOG_OVERLAP))
+    pile.alpha_composite(log, (0, log.height - CAMP_LOG_OVERLAP))
+    pile.alpha_composite(log, (log.width + CAMP_LOG_GAP, log.height - CAMP_LOG_OVERLAP))
+    pile.alpha_composite(log, ((pile.width - log.width) // 2, 0))
+    stump = terrain.crop(STUMP_BOX)
+    image = Image.new("RGBA", (stump.width + pile.width - CAMP_STUMP_OVERLAP, max(stump.height, pile.height)))
+    image.alpha_composite(pile, (stump.width - CAMP_STUMP_OVERLAP, image.height - pile.height))
+    image.alpha_composite(stump, (0, image.height - stump.height))
+    return image
+
+
 def build_forest() -> None:
     trees_sheet = Image.open(SOURCES / "terrain" / "trees-green.png").convert("RGBA")
@@ -325,4 +356,8 @@ def build_forest() -> None:
     frames["mage-tower"] = build_mage_tower()
     pivots["mage-tower"] = {"x": 0.5, "y": 1}
+    frames["storehouse"] = build_storehouse(terrain)
+    pivots["storehouse"] = {"x": 0.5, "y": 1}
+    frames["camp"] = build_camp(terrain)
+    pivots["camp"] = {"x": 0.5, "y": 1}
 
     write_atlas("forest", frames, pivots)
```
- [ ] **Step 2: regenerar** — `cd asset-packs/lpc && python3 build_assets.py`. `git status` enseña solo `forest.png`, `forest.json` y el script. Con un script de usar y tirar en el *scratchpad* (Pillow) que compara cada frame del atlas anterior (`git show HEAD:…`) con el nuevo: añadidos `camp` y `storehouse`, ningún frame anterior cambia; `forest.png` es idéntico byte a byte al de `$IOS` en `020d442` (`git -C $IOS show 020d442:Farming/Resources/Art/forest.png`). Mirar los dos recortes ampliados.
- [ ] **Step 3: créditos** (sin autores nuevos):

`CREDITS.md`:

```diff
@@ -46,5 +46,5 @@ CC-BY-SA 3.0 / GPL 3.0 — <https://opengameart.org/content/lpc-tile-atlas>. Ful
 `asset-packs/lpc/sources/terrain/Attribution.txt`.
 
-## House, forge, armory and mage tower (`house`, `forge`, `armory`, `mage-tower` frames in `forest.png`)
+## House, forge, armory, mage tower and storehouse (`house`, `forge`, `armory`, `mage-tower`, `storehouse` frames in `forest.png`)
 
 Assembled from "[LPC] Thatched-roof Cottage" (timber-frame and stone walls, thatched roof) and
@@ -55,6 +55,9 @@ The forge and armory roofs are recoloured (dark grey, red); the forge chimney is
 from the LPC Tile Atlas above.
 The mage tower roof is recoloured violet and stretched 40 % taller.
+The storehouse (`storehouse` frame) is the same cottage with the ochre wall and the thatched roof, with two
+closed chests of the LPC Tile Atlas above beside the door.
 
 The stump (`stump` frame) comes from the LPC Tile Atlas above.
+The camp (`camp` frame) is that stump in front of three logs cut from a tree trunk of the LPC Tile Atlas above.
 The large rock (`rock-large` frame) is a grey boulder of the LPC Tile Atlas above.
 The sapling (`sapling` frame) is a young plant from the farming crops of the LPC Tile Atlas above (Daniel Eddeland).
```
- [ ] **Step 4: Commit** — `git add asset-packs lib/core/assets/images/lpc` y, aparte, el commit `[PROJECT-F6]: Add the camp and storehouse art`.

### Task TF6.4: El campamento en el nivel y el edificio que nace terminado

**Files:**
- Create: `lib/layers/data/datasources/level/local/dbo/building_dbo.dart`, `lib/layers/data/repositories/level/mappers/building_mapper_dbo.dart`
- Modify: `lib/layers/data/datasources/level/local/dbo/level_dbo.dart`, `lib/layers/data/datasources/level/local/level_local_datasource_impl.dart`, `lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart`, `lib/layers/presentation/features/forest/game/components/building_component.dart`, `lib/core/config/di/di.config.dart` (generado)

**Interfaces:**
- Consumes: TF6.2 (`World(buildings:)`, `Blueprints.of`, `BlueprintId.camp`), TF6.3 (frame `camp`).
- Produces: `BuildingDBO({id, blueprint, x, y})`; `LevelDBO.buildings`; `BuildingMapperDBO.toEntity(BuildingDBO, {required int index})`; `LevelMapperDBO(buildingMapperDBO:)`; el campamento `camp` terminado en (700, 592).

- [ ] **Step 1: DBO y *mapper*** (decisión 7):

`building_dbo.dart` (nuevo):

```dart
class BuildingDBO {
  final String? id;
  final String? blueprint;
  final double? x;
  final double? y;

  const BuildingDBO({this.id, this.blueprint, this.x, this.y});

  @override
  bool operator ==(Object other) =>
      other is BuildingDBO && other.id == id && other.blueprint == blueprint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, blueprint, x, y);

  @override
  String toString() => 'BuildingDBO(id: $id, blueprint: $blueprint, x: $x, y: $y)';
}
```
`level_dbo.dart`:

```diff
@@ -1,4 +1,5 @@
 import 'package:collection/collection.dart';
 
+import 'building_dbo.dart';
 import 'decoration_dbo.dart';
 import 'item_dbo.dart';
@@ -15,4 +16,5 @@ class LevelDBO {
   final List<DecorationDBO>? decorations;
   final List<RockDBO>? rocks;
+  final List<BuildingDBO>? buildings;
 
   const LevelDBO({
@@ -24,4 +26,5 @@ class LevelDBO {
     this.decorations,
     this.rocks,
+    this.buildings,
   });
 
@@ -35,5 +38,6 @@ class LevelDBO {
       const ListEquality<ItemDBO>().equals(other.items, items) &&
       const ListEquality<DecorationDBO>().equals(other.decorations, decorations) &&
-      const ListEquality<RockDBO>().equals(other.rocks, rocks);
+      const ListEquality<RockDBO>().equals(other.rocks, rocks) &&
+      const ListEquality<BuildingDBO>().equals(other.buildings, buildings);
 
   @override
@@ -46,4 +50,5 @@ class LevelDBO {
     const ListEquality<DecorationDBO>().hash(decorations),
     const ListEquality<RockDBO>().hash(rocks),
+    const ListEquality<BuildingDBO>().hash(buildings),
   );
 
@@ -51,4 +56,4 @@ class LevelDBO {
   String toString() =>
       'LevelDBO(width: $width, height: $height, playerStart: $playerStart, trees: $trees, items: $items, '
-      'decorations: $decorations, rocks: $rocks)';
+      'decorations: $decorations, rocks: $rocks, buildings: $buildings)';
 }
```
`building_mapper_dbo.dart` (nuevo):

```dart
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/building/building_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/rules/blueprints.dart';
import '../../../datasources/level/local/dbo/building_dbo.dart';

@Injectable()
class BuildingMapperDBO {
  BuildingEntity toEntity(BuildingDBO dbo, {required int index}) {
    final buildingId = dbo.id ?? 'level-building-${index + 1}';
    final blueprintId =
        BlueprintId.values.firstWhereOrNull((id) => id.name == dbo.blueprint) ??
        (throw InvalidLevelException(data: 'unknown blueprint $buildingId: "${dbo.blueprint ?? ''}"'));
    final blueprint = Blueprints.of(blueprintId);
    return BuildingEntity(
      id: buildingId,
      blueprint: blueprint,
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      hitsDone: blueprint.hitsToBuild,
    );
  }
}
```
`level_mapper_dbo.dart`:

```diff
@@ -8,4 +8,5 @@ import '../../../../domain/rules/rules.dart';
 import '../../../../domain/world/world.dart';
 import '../../../datasources/level/local/dbo/level_dbo.dart';
+import 'building_mapper_dbo.dart';
 import 'decoration_mapper_dbo.dart';
 import 'ground_item_mapper_dbo.dart';
@@ -21,4 +22,5 @@ class LevelMapperDBO {
   final GroundItemMapperDBO _groundItemMapperDBO;
   final RockMapperDBO _rockMapperDBO;
+  final BuildingMapperDBO _buildingMapperDBO;
 
   const LevelMapperDBO({
@@ -28,4 +30,5 @@ class LevelMapperDBO {
     required this._groundItemMapperDBO,
     required this._rockMapperDBO,
+    required this._buildingMapperDBO,
   });
 
@@ -38,4 +41,5 @@ class LevelMapperDBO {
     final decorations = dbo.decorations ?? const [];
     final rocks = dbo.rocks ?? const [];
+    final buildings = dbo.buildings ?? const [];
     return World(
       width: width,
@@ -54,4 +58,8 @@ class LevelMapperDBO {
       ],
       rocks: [for (var index = 0; index < rocks.length; index++) _rockMapperDBO.toEntity(rocks[index], index: index)],
+      buildings: [
+        for (var index = 0; index < buildings.length; index++)
+          _buildingMapperDBO.toEntity(buildings[index], index: index),
+      ],
     );
   }
```
- [ ] **Step 2: el campamento y la decoración quitada** (decisión 7):

`level_local_datasource_impl.dart`:

```diff
@@ -5,4 +5,5 @@ import 'package:injectable/injectable.dart';
 import '../../../../../core/utils/seeded_random.dart';
 import '../source/level_local_datasource.dart';
+import 'dbo/building_dbo.dart';
 import 'dbo/decoration_dbo.dart';
 import 'dbo/item_dbo.dart';
@@ -46,4 +47,5 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
   static const double _rockItemClearance = 80;
   static const double _rockDecorationClearance = 48;
+  static const double _campDecorationClearance = 64;
   static const int _decorationSeed = 1337;
   static const int _decorationAttempts = 107;
@@ -69,4 +71,5 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
   static const PointDBO _playerStart = PointDBO(x: _spawnX, y: _spawnY);
   static const ItemDBO _pickaxe = ItemDBO(id: 'pickaxe', kind: 'pickaxe', x: _spawnX + 212, y: _spawnY + 212);
+  static const BuildingDBO _camp = BuildingDBO(id: 'camp', blueprint: 'camp', x: _spawnX - 100, y: _spawnY - 8);
 
   const LevelLocalDatasourceImpl();
@@ -84,4 +87,5 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
       decorations: _scatterDecorations(trees).where((decoration) => _isClear(decoration, rocks)).toList(),
       rocks: rocks,
+      buildings: const [_camp],
     );
   }
@@ -134,5 +138,6 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
     final onRock = rocks.any((rock) => _distance(x, y, rock.x!, rock.y!) < _rockDecorationClearance);
     final onPickaxe = _distance(x, y, _pickaxe.x!, _pickaxe.y!) < _decorationSpacing;
-    return !onRock && !onPickaxe;
+    final onCamp = _distance(x, y, _camp.x!, _camp.y!) < _campDecorationClearance;
+    return !onRock && !onPickaxe && !onCamp;
   }
 
```
- [ ] **Step 3: el edificio que nace terminado** (decisión 8):

`building_component.dart`:

```diff
@@ -46,4 +46,5 @@ class BuildingComponent extends AtlasSpriteComponent {
       ) {
     progress = building.progress;
+    _isComplete = building.isComplete;
   }
 
```
- [ ] **Step 4: Verificar**

```sh
dart run build_runner build --delete-conflicting-outputs   # inyecta BuildingMapperDBO en LevelMapperDBO
dart format --line-length 120 lib/layers/data lib/layers/presentation/features/forest/game/components/building_component.dart
flutter analyze lib
```
Esperado: `No issues found!`. Comprobar las cifras con un script de usar y tirar en el *scratchpad* (`dart run --packages=.dart_tool/package_config.json <script>` que llama a `LevelLocalDatasourceImpl().fetch()`): `buildings` = el campamento en (700, 592); 93 decoraciones, sin los ids 6, 12, 17, 30, 34, 37, 40, 42, 49, 68, **78**, 81, 85 y 105; 70 árboles, 12 rocas y el pico en (1012, 812), como en F5.

- [ ] **Step 5: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F6]: Place the camp in the level`.

### Task TF6.5: La carga y el almacén en el HUD

**Files:**
- Create: `lib/layers/presentation/features/forest/models/carry_item_data.dart`
- Modify: `lib/layers/presentation/features/forest/models/hud_data.dart`, `lib/layers/presentation/features/forest/widgets/resource_bar.dart`, `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/forest_page.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`

**Interfaces:**
- Consumes: TF6.1 (`GetStockUseCase`, `InventoryRules.load` / `isLoadFull`, `Rules.carryCapacity`).
- Produces: `CarryItemData({text, isFull})`; `HudData({stock, carry, …})` sin `resources`; `ResourceBar({stock, carry, tools, showLabels})` y `ResourceBar.carryKey`; `Internationalize.forestStock` / `forestCarry({amount, capacity})`; `ForestBloc(getStockUseCase:)`; `HudOverlay.narrowWidth == 960`, `HudOverlay.buttonsBelowWidth == 1460`.

- [ ] **Step 1: modelos** (decisión 12):

`carry_item_data.dart` (nuevo):

```dart
class CarryItemData {
  final String text;
  final bool isFull;

  const CarryItemData({required this.text, required this.isFull});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CarryItemData && other.text == text && other.isFull == isFull;

  @override
  int get hashCode => Object.hash(text, isFull);
}
```
`hud_data.dart`:

```diff
@@ -2,4 +2,5 @@ import 'package:collection/collection.dart';
 
 import 'build_item_data.dart';
+import 'carry_item_data.dart';
 import 'hero_panel_data.dart';
 import 'quest_item_data.dart';
@@ -10,5 +11,6 @@ class HudData {
   static const int pendingQuestsShown = 2;
 
-  final List<ResourceItemData> resources;
+  final List<ResourceItemData> stock;
+  final CarryItemData carry;
   final List<ToolItemData> tools;
   final String questBadge;
@@ -19,5 +21,6 @@ class HudData {
 
   const HudData({
-    required this.resources,
+    required this.stock,
+    required this.carry,
     required this.tools,
     required this.questBadge,
@@ -32,5 +35,6 @@ class HudData {
       identical(this, other) ||
       other is HudData &&
-          const ListEquality<ResourceItemData>().equals(other.resources, resources) &&
+          const ListEquality<ResourceItemData>().equals(other.stock, stock) &&
+          other.carry == carry &&
           const ListEquality<ToolItemData>().equals(other.tools, tools) &&
           other.questBadge == questBadge &&
@@ -42,5 +46,6 @@ class HudData {
   @override
   int get hashCode => Object.hash(
-    Object.hashAll(resources),
+    Object.hashAll(stock),
+    carry,
     Object.hashAll(tools),
     questBadge,
```
- [ ] **Step 2: textos** (decisión 11):

`es.json`:

```diff
@@ -31,5 +31,7 @@
       },
       "missing": "Faltan {amounts}",
-      "arena": "Arena"
+      "arena": "Arena",
+      "stock": "Almacén",
+      "carry": "Carga {amount}/{capacity}"
     },
     "resource": {
```
`internationalize.dart`:

```diff
@@ -54,4 +54,7 @@ class Internationalize {
   static String get forestQuests => '$_forest.hud.quests'.tr();
   static String get forestArena => '$_forest.hud.arena'.tr();
+  static String get forestStock => '$_forest.hud.stock'.tr();
+  static String forestCarry({required int amount, required int capacity}) =>
+      '$_forest.hud.carry'.tr(namedArgs: {'amount': '$amount', 'capacity': '$capacity'});
   static String get forestQuestDone => '$_forest.hud.questDone'.tr();
   static String forestQuestsDone({required int count}) =>
```
- [ ] **Step 3: el bloc lee el almacén**:

`forest_bloc.dart`:

```diff
@@ -39,4 +39,5 @@ import '../../../../domain/entities/geometry/position_entity.dart';
 import '../../../../domain/entities/hero/skill_option_entity.dart';
 import '../../../../domain/rules/gear.dart';
+import '../../../../domain/rules/rules.dart';
 import '../../../../domain/rules/skills.dart';
 import '../../../../domain/use-cases/game/advance_game_use_case.dart';
@@ -49,4 +50,5 @@ import '../../../../domain/use-cases/game/get_build_options_use_case.dart';
 import '../../../../domain/use-cases/game/get_player_status_use_case.dart';
 import '../../../../domain/use-cases/game/get_quests_use_case.dart';
+import '../../../../domain/use-cases/game/get_stock_use_case.dart';
 import '../../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
 import '../../../../domain/use-cases/game/mine_rock_use_case.dart';
@@ -62,4 +64,5 @@ import '../../../../domain/world/extensions/inventory_rules.dart';
 import '../../arena/arena_page.dart';
 import '../models/build_item_data.dart';
+import '../models/carry_item_data.dart';
 import '../models/forest_effect.dart';
 import '../models/gear_item_data.dart';
@@ -91,4 +94,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
   final GetWorldSnapshotUseCase _getWorldSnapshotUseCase;
   final GetBuildOptionsUseCase _getBuildOptionsUseCase;
+  final GetStockUseCase _getStockUseCase;
   final GetQuestsUseCase _getQuestsUseCase;
   final GetHeroStatusUseCase _getHeroStatusUseCase;
@@ -118,4 +122,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     required this._getWorldSnapshotUseCase,
     required this._getBuildOptionsUseCase,
+    required this._getStockUseCase,
     required this._getQuestsUseCase,
     required this._getHeroStatusUseCase,
@@ -481,13 +486,18 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
 
   HudData _hudData(PlayerStatusEntity status, List<QuestProgressEntity> quests) {
+    final stock = _getStockUseCase();
     return HudData(
-      resources: [
+      stock: [
         for (final resource in Resource.values)
           ResourceItemData(
             resource: resource,
             name: Internationalize.forestResource(resource: resource),
-            amount: status.inventory.amount(resource),
+            amount: stock.amount(resource),
           ),
       ],
+      carry: CarryItemData(
+        text: Internationalize.forestCarry(amount: status.inventory.load, capacity: Rules.carryCapacity),
+        isFull: status.inventory.isLoadFull,
+      ),
       tools: [
         for (final tool in ToolKind.values)
```
`forest_page.dart`:

```diff
@@ -19,4 +19,5 @@ import '../../../domain/use-cases/game/get_build_options_use_case.dart';
 import '../../../domain/use-cases/game/get_player_status_use_case.dart';
 import '../../../domain/use-cases/game/get_quests_use_case.dart';
+import '../../../domain/use-cases/game/get_stock_use_case.dart';
 import '../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
 import '../../../domain/use-cases/game/move_player_use_case.dart';
@@ -60,4 +61,5 @@ class ForestPage extends StatelessWidget {
         getWorldSnapshotUseCase: locator.get<GetWorldSnapshotUseCase>(),
         getBuildOptionsUseCase: locator.get<GetBuildOptionsUseCase>(),
+        getStockUseCase: locator.get<GetStockUseCase>(),
         getQuestsUseCase: locator.get<GetQuestsUseCase>(),
         getHeroStatusUseCase: locator.get<GetHeroStatusUseCase>(),
```
- [ ] **Step 4: la barra** (decisión 12):

`resource_bar.dart`:

```diff
@@ -2,8 +2,10 @@ import 'package:flutter/material.dart';
 import 'package:flutter_svg/flutter_svg.dart';
 
+import '../../../../../core/assets/i18n/internationalize.dart';
 import '../../../../../core/config/constants/enum/tool_kind.dart';
 import '../../../theme/colors/custom_colors.dart';
 import '../../../theme/images/custom_icons.dart';
 import '../../../theme/styles/custom_text_styles.dart';
+import '../models/carry_item_data.dart';
 import '../models/resource_item_data.dart';
 import '../models/tool_item_data.dart';
@@ -11,9 +13,18 @@ import 'hud_panel.dart';
 
 class ResourceBar extends StatelessWidget {
-  final List<ResourceItemData> resources;
+  static const Key carryKey = Key('resourceBarCarry');
+
+  final List<ResourceItemData> stock;
+  final CarryItemData carry;
   final List<ToolItemData> tools;
   final bool showLabels;
 
-  const ResourceBar({super.key, required this.resources, required this.tools, this.showLabels = true});
+  const ResourceBar({
+    super.key,
+    required this.stock,
+    required this.carry,
+    required this.tools,
+    this.showLabels = true,
+  });
 
   static Key toolKey(ToolKind tool) => Key('resourceBarTool-${tool.name}');
@@ -26,5 +37,14 @@ class ResourceBar extends StatelessWidget {
         mainAxisSize: MainAxisSize.min,
         spacing: 16,
-        children: [for (final resource in resources) _resource(resource), for (final tool in tools) _tool(tool)],
+        children: [
+          if (showLabels)
+            Text(
+              Internationalize.forestStock,
+              style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudMuted),
+            ),
+          for (final resource in stock) _resource(resource),
+          _carry(),
+          for (final tool in tools) _tool(tool),
+        ],
       ),
     );
@@ -57,4 +77,21 @@ class ResourceBar extends StatelessWidget {
   }
 
+  Widget _carry() {
+    return Container(
+      key: carryKey,
+      padding: const EdgeInsets.only(left: 12),
+      decoration: const BoxDecoration(
+        border: Border(left: BorderSide(color: CustomColors.hudBorder)),
+      ),
+      child: Text(
+        carry.text,
+        style: CustomTextStyles.system15w600.copyWith(
+          color: carry.isFull ? CustomColors.hudWarning : CustomColors.hudText,
+          fontFeatures: const [FontFeature.tabularFigures()],
+        ),
+      ),
+    );
+  }
+
   Widget _tool(ToolItemData tool) {
     return Opacity(
```
- [ ] **Step 5: umbrales del HUD** (decisión 13). Medir con un test de widget de usar y tirar en el *scratchpad* (`flutter test <ruta absoluta>` desde la raíz del repo; importa `test/helpers/roboto_font.dart` y `spanish_translations.dart` con `file:///…`) que pinta `HudOverlay` a 3000 × 720 con `ResourceItemData(…, amount: 9999)` de cada `Resource`, `CarryItemData(text: Internationalize.forestCarry(amount: 10, capacity: 10), isFull: true)`, `ToolItemData(…, isOwned: true)` de cada `ToolKind` e insignia `15/15`, y lee el ancho de `ResourceBar`, el de la fila de botones (el `Row` antecesor del botón *Misiones*) y el de `ResourceBar(showLabels: false)`. Con los resultados:

`hud_overlay.dart`:

```diff
@@ -16,6 +16,6 @@ import 'resource_bar.dart';
 
 class HudOverlay extends StatefulWidget {
-  static const double narrowWidth = 770;
-  static const double buttonsBelowWidth = 1260;
+  static const double narrowWidth = 960;
+  static const double buttonsBelowWidth = 1460;
   static const double _margin = 12;
 
@@ -54,5 +54,6 @@ class _HudOverlayState extends State<HudOverlay> {
     final width = MediaQuery.sizeOf(context).width;
     final resourceBar = ResourceBar(
-      resources: widget.hud.resources,
+      stock: widget.hud.stock,
+      carry: widget.hud.carry,
       tools: widget.hud.tools,
       showLabels: width >= HudOverlay.narrowWidth,
```
- [ ] **Step 6: Verificar**

```sh
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/forest
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 7: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F6]: Show the load and the stock in the HUD`.

### Task TF6.6: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-04-game-design/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, este plan, `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **F6** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F6 → `✅`, `feature/PROJECT-F6-storehouse`, nota "Bloque 2. Sin tests (T1)."; `README.md`: icono de F6 → ✅; cabecera de este plan con lo implementado y los desvíos.
- [ ] **Step 3:** `CLAUDE.md`: la carga y el almacén (`Rules.carryCapacity`, `ResourceRules.takesCargo`, `InventoryRules` de carga, `WorldState.stock` / `pay`, `World.stock` / `funds` / `earn` / `spend` sobre el almacén, sin las notas "hasta F6"), `Depositing` / `World.orderDeposit` / `DepositUseCase` / `GetStockUseCase`, los planos `storehouse` y `camp` (`isBuildable`, `isDropOff`), el campamento del nivel (`BuildingDBO`, `BuildingMapperDBO`), tocar un edificio (entregar → reanudar), el `BuildingComponent` que nace terminado, la barra del HUD y los umbrales (1460 / 960). Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); el commit `[PROJECT-F6]: Close the storehouse phase` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque 2 de la aldea, en Chrome y Android:

1. Junto al inicio, a la izquierda, está el campamento (un tocón delante de tres troncos), terminado, sin barra de obra y sin decoración encima.
2. La barra dice "Almacén Madera 0 … | Carga 0/10 Hacha Pico". Por debajo de 960 px de ancho va sin nombres (ni el rótulo "Almacén"); por debajo de 1460 los botones van debajo de la barra.
3. Al talar, la carga sube y el almacén no. Con 10 en la carga, el árbol que la llena da "+N" (solo lo que cabe) y avisa "Llevas la carga llena…"; tocar otro árbol o una roca también avisa y el jugador no se mueve. "Carga 10/10" sale en color de aviso.
4. Tocar el campamento lleva al jugador delante y, al momento, "Guardado en el almacén: 10 de madera": la carga vuelve a 0 y el almacén sube. Tocarlo vacío avisa "No llevas nada que guardar.".
5. *Lleva 15 de madera al almacén* se cumple al segundo viaje.
6. El Almacén (20 de madera) es el segundo del menú de construir; el campamento no sale. A medio hacer, tocarlo sigue la obra; terminado recibe la carga. Tocar una casa terminada anda hasta allí, como antes.
7. El oro de la arena aparece en el almacén y la carga no cambia; el equipo y las habilidades se pagan del almacén.
8. Desde lejos, el camino recto al campamento puede quedar cortado ("Hay algo en medio").

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F6 (no se ha tocado `test/`; los de iOS valen como referencia). Datos en `test/mocks/**` (p. ej. `InventoryEntityMock` con una carga llena y una con oro, `BuildingEntityMock.camp` / `storehouseSite`, `BuildingDBOMock`, `CarryItemDataMock`), nunca en línea:

- **Compilación:** `ForestBloc` pide `depositUseCase` y `getStockUseCase` (todos los `ForestBloc(...)` de los tests del bosque); `HudData` pide `stock` y `carry` en lugar de `resources` (`hud_data_mock.dart`, `forest_data_mock.dart`); `ResourceBar(stock:, carry:)` (`resource_bar_test.dart`); `WorldState` pide `buildings` si algún test lo construye; `LevelMapperDBO` pide `buildingMapperDBO`; `di_test.dart` resuelve `DepositUseCase`, `GetStockUseCase` y `BuildingMapperDBO`. `architecture_test.dart`: `world/depositing.dart` en `_worldInternals`.
- **Dominio:**
  - `resource_rules_test.dart` (`takesCargo` de cada recurso) e `inventory_rules_test.dart`: `load` suma madera y piedra y no oro ni maná, `freeLoad` nunca negativa, `isLoadFull` a 10, `cargo` solo con lo que ocupa carga y cantidad > 0, `adding` salta cantidades ≤ 0, `unloading()` conserva herramientas, oro y maná;
  - `world_deposit_test.dart` (ticks de 50 ms): capacidad, un roble de 8 con 9 en la carga da `TreeFelledEventEntity(wood: 1)` y deja 10, una roca de 8 con 6 da `RockBrokenEventEntity(stone: 4)`, `carryFull` después de `unknownTree` / `noAxe` y `unknownRock` / `noPickaxe`; `orderDeposit` → `unknownBuilding` / `notADropOff` (casa terminada y almacén a medio hacer) / `emptyLoad` / `ok`; con `ok` el jugador va delante del edificio, `PlayerActivity.depositing`, a los 400 ms un único `DepositedEventEntity` con toda la carga, la carga queda a 0 con las herramientas y el almacén suma; en el campamento y en un almacén terminado; el oro y el maná no ocupan carga;
  - `world_funds_test.dart`: compara con `world.stock`; `funds == stock`, `earn` suma al almacén (no al jugador) saltando cantidades ≤ 0, `spend` resta del almacén y sin fondos no toca nada; `construction_test` / `world_construction_test`: `place` comprueba el almacén antes que el sitio y cobra del almacén sin tocar el inventario del jugador; `canPlace` con `camp` → `false`; construir el campamento → `blocked`;
  - `blueprints_test.dart` (`storehouse` segundo, `camp` último, `isBuildable` / `isDropOff`), `blueprint_entity_test.dart` (`==` con los dos campos), `building_rules_test.dart` (`acceptsDeposits`), `stats_recording_test.dart` (el evento de entrega no cambia nada);
  - `quests_test.dart`: `gatherWood` y `gatherFortyWood` miden el almacén (10 en la carga y 0 en el almacén → 0);
  - `get_build_options_use_case_test.dart`: sin el campamento, el almacén segundo con 20 de madera y lo que falta medido en el almacén; `deposit_use_case_test.dart`, `get_stock_use_case_test.dart`; los flujos que construyen o compran (`hero_flow` / `skill_flow`, `buy_gear_use_case_test.dart`, `learn_skill_use_case_test.dart`, `start_fight_use_case_test.dart`, escenarios de `ForestScenarioMock` / `GameScenarioMock`) ponen los recursos en el almacén y leen el oro de él; `balance_test.dart` sin cambios.
- **Datos:** `level_local_datasource_impl_test.dart`: `buildings` = el campamento en (700, 592); 93 decoraciones (falta además la 78) y ninguna a menos de 64 del campamento; árboles, rocas y pico como en F5; los goldens de decoración (VM y Chrome) se actualizan. `building_mapper_dbo_test.dart`: sin id → `level-building-<n>`, sin posición → (0, 0), `blueprint` desconocido → `InvalidLevelException`, llega terminado; `level_repository_impl_test.dart` / `level_mapper_dbo_test.dart`: sin `buildings` → mundo sin edificios; `==` de `LevelDBO` con `buildings`.
- **Presentación:** `forest_bloc_test.dart`: tocar un árbol o una roca con `carryFull` avisa; el árbol que llena la carga da "+N de madera" y después el aviso de carga llena; tocar un edificio entrega (`ok` sin aviso), avisa con la carga vacía, reanuda una obra (`notADropOff`) y anda si la casa está terminada; `DepositedEventEntity` → "Guardado en el almacén: 10 de madera"; `HudData.stock` del almacén y `carry` ("Carga 7/10", `isFull`); la pose quieta al entregar. `building_component_test.dart`: el campamento nace terminado, opaco y sin barra ni rebote. `resource_bar_test.dart`: rótulo "Almacén" solo con nombres, la carga en color de aviso llena (`ResourceBar.carryKey`). `hud_overlay_test.dart`: `buttonsBelowWidth` 1460 (tests de 1459 / 1460) y `narrowWidth` 960. `LpcAssetsMock` construye `camp` y `storehouse` (ya lo hace para todo `BlueprintId`); `lpc_atlas_test.dart` e `internationalize_test.dart` (las siete claves nuevas y los dos textos de misión cambiados).

## Para F2, F7 y F8

- **F2 (guardado):** guardar `WorldState.stock` (con oro y maná) y la carga (`player.inventory`, con sus herramientas); los edificios guardados llevan su progreso (el `BuildingComponent` ya nace terminado si `isComplete`); el campamento es un edificio más (id `camp`, `BuildingDBO` ya existe). Validar al cargar que la carga no pase de `Rules.carryCapacity`.
- **F7 (cantera):** la cantera recibe **solo piedra**: `BlueprintEntity.isDropOff` pasa a decir qué recibe (p. ej. `accepts: Set<Resource>`), `Depositing.impact` deja en la carga lo que el edificio no acepta y `check` da `emptyLoad` si no lleva nada que ese edificio acepte.
- **F8 (taller):** las mejoras pagan con `World.spend` (el almacén). Una misión de "picar N de piedra" no puede medir el almacén ni la carga: necesita `Stats`.
