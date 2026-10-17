# F8 · Taller y mejoras de herramientas — Implementation Plan

> **Implementado el 2026-10-17 sin tests (regla del usuario); lo que falta de test está en *Para T1*.** Una sola rama `feature/PROJECT-F8-workshop`: el plan primero (escrito con el código tras F7 y el plan iOS `$IOS/docs/plans/2026-10-12-village/F8-workshop.md`, `819a4aa`; en iOS solo estaba hecha la tarea 1, `0234537`), un commit por tarea (TF8.1–TF8.5) y el cierre. El código se aplicó tal como está en el plan (solo `dart format` partió la línea de `_toolName`). Desvíos respecto a iOS, en *Desvíos respecto a iOS*: dos casos de uso en vez de métodos de `GameUseCase`, `World.updatePlayer` sin `@visibleForTesting`, claves `forest.upgrade.<id>.name`, título del panel en mayúsculas, `withToolLevel` con `ArgumentError`, el nombre mejorado lo pone el bloc, umbrales 1700 / 1100 px medidos con Roboto, insignia `x/19`. Cifras, orden de las comprobaciones, textos y arte (`workshop` 120 × 191; ningún frame anterior cambia), los de iOS.

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 2) |
| **Rama** | `feature/PROJECT-F8-workshop`, desde `feature/PROJECT-X-town` (arena C0–C13, "empezar con el hacha", F1, F3, F4, F5, F6 y F7) |
| **Depende de** | F7 (cantera, `BlueprintId` detrás de `quarry`, `World.spend` paga del almacén desde F6) |
| **Issue / milestone** | `phase:F8` · milestone `F8 Workshop` |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura), rama `feature/PROJECT-F8-workshop`: plan `819a4aa`, tarea 1 `0234537` (`[PROJECT-F8]: Add the workshop and the tool levels`). Las tareas 2–6 de iOS solo existen en su plan. |

**Goal:** Un taller (20 de madera y 10 de piedra) donde se compran el hacha y el pico de hierro, que talan y pican con un 40 % menos de golpes, y el segundo capítulo de misiones de la aldea.

**Architecture:** Dominio: `BlueprintId.workshop` (cuarto en `Blueprints.all`), `InventoryEntity.toolLevels` (un nivel que falta es el 1) con `toolLevel`, `withToolLevel` y `hitsNeeded` en `InventoryRules` (`max(1, ⌈golpes × 60 %⌉)` en enteros, `Rules.upgradedHitsPercent`), que `Woodcutting` y `Mining` leen en cada golpe (`TreeEntity`/`RockEntity` no cambian); `UpgradeEntity` + `UpgradeOptionEntity`, el catálogo `Upgrades`, los enums `UpgradeId`, `UpgradeResult` y `UpgradeOptionState` (core), `BuyUpgradeUseCase` y `GetUpgradeOptionsUseCase` (pagan con `World.spend` y suben el nivel con `World.updatePlayer`); cuatro misiones nuevas al final de `QuestId` y de la línea de la aldea. Presentación: `HudMenu.upgrades`, `UpgradeItemData`, `HudData.upgradeItems`, el nombre mejorado de la herramienta en la barra, `ForestUpgradeRequested`, `UpgradePurchasedEffect` con las chispas de comprar equipo, `UpgradeMenu` + `UpgradeOptionTile`, el quinto botón *Taller* y los umbrales del HUD medidos de nuevo. Arte: frame `workshop` desde `build_assets.py` e icono `workshop.svg`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`, `easy_localization`, `injectable`; Pillow para `build_assets.py`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*. La única excepción es medir los umbrales del HUD con un test de widget de usar y tirar en el *scratchpad* (no se guarda; ya hecho al escribir este plan, decisión 12).
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque 2 de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. TF8.2 añade dos casos de uso `@Injectable()`: `dart run build_runner build --delete-conflicting-outputs` y se commitea `di.config.dart` tal cual (nunca se formatea). TF8.3 cambia `build_assets.py`: regenerar y comprobar que solo aparece el frame nuevo.
- **Determinismo:** F8 no añade ni reordena ninguna tirada de `SeededRandom` y no toca el nivel. Con las herramientas básicas (nivel 1) talar y picar dan exactamente los mismos golpes y eventos que antes. **El balance de la arena no cambia:** el hacha de hierro no es equipo del héroe.
- `World`, `WorldState`, `Work` y los sistemas solo se tocan dentro de `domain/world/`. Las compras usan la API pública de `World` (`spend`, `updatePlayer`, `buildings`, `funds`, `player`).
- Casos nuevos de enum **al final**: `BlueprintId.workshop`, `HudMenu.upgrades`, `QuestId.{gatherTwentyStone, buildQuarry, buildWorkshop, upgradeAxe}`; `UpgradePurchasedEffect` y `ForestUpgradeRequested`, al final de sus jerarquías `sealed`. `switch` exhaustivos en el orden de declaración.
- Textos solo en `es.json`, leídos por `Internationalize`; ninguno de los textos nuevos dice cómo interactuar, así que no llevan variante `…Touch`.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-F8]: <frase en inglés en imperativo>`; el commit, en un comando aparte del `git add`.

## Decisiones

Las del plan iOS (que recoge la ficha) más las que salen de Flutter:

1. **Taller:** `BlueprintId.workshop` (al final del enum), 20 de madera + 10 de piedra, 10 golpes (como la herrería y la armería), radio 40, `accepts` vacío y `AnywherePlacementRuleEntity` (los valores por defecto, nota de F7). **Cuarto** en `Blueprints.all` y en el menú: tras la cantera y antes de los edificios del héroe. No es el primer coste con dos recursos (desde F5 la herrería, la armería y la torre de magia cuestan piedra).
2. **Nivel de las herramientas:** `InventoryEntity.toolLevels: Map<ToolKind, int>` (por defecto `const {}`, en `==`/`hashCode` con `MapEquality`); un nivel que falta es el 1. Va aparte de tener la herramienta (`tools`) y del equipo del héroe (el hacha de hierro no cambia el ataque). Todas las operaciones de `InventoryRules` pasan por `copyWith` y conservan los niveles (entregar en el almacén no los pierde). `InventoryRules.toolLevel(tool)`, `withToolLevel(tool, level)` (`ArgumentError` por debajo de 1, como `add` con negativos; el `assert` de iOS no cabe en un constructor `const`).
3. **Golpes con mejora:** `InventoryRules.hitsNeeded(tool, hits)`: con nivel 1, `hits`; si no, `max(1, (hits * 60 + 99) ~/ 100)` (`Rules.upgradedHitsPercent = 60`), en enteros para no depender del redondeo de `double`. `TreeEntity.hitsToFell` y `RockEntity.hitsToBreak` no cambian (los guardará F2): `Woodcutting`/`Mining` comparan los golpes recibidos con `hitsNeeded` en cada golpe, y `TreeHitEventEntity.hitsRemaining` lleva los golpes que faltan con la herramienta actual (`max(0, …)`). Pino 3 → 2, árboles de 5 → 3, roble 7 → 5, viejo y grande 8 → 5, roca 8 → 5. Un árbol a medio talar al comprar la mejora cae en cuanto lleva los golpes nuevos. El intervalo de trabajo no cambia (la cantera de F7 sigue acelerando el picado aparte).
4. **Mejorar antes de recoger la herramienta:** se puede (`UpgradeResult` no tiene caso "sin herramienta"); sirve en cuanto se recoge. Hoy el jugador empieza con el hacha y el pico está en el suelo.
5. **Mejoras:** `UpgradeEntity(id, tool, level, cost)` en `domain/entities/upgrade/` (`level > 1`), catálogo `Upgrades` en `domain/rules/upgrades.dart` (`building` = `BlueprintId.workshop`, `ironAxe` 15 de madera + 15 de piedra → hacha nivel 2, `ironPickaxe` 10 de madera + 20 de piedra → pico nivel 2, `all`, `of(id)`, `reached(tool, level)` = la última mejora del catálogo de esa herramienta con nivel alcanzado). Enums en core: `UpgradeId { ironAxe, ironPickaxe }`, `UpgradeResult { ok, notEnoughResources, noWorkshop, alreadyOwned }`, `UpgradeOptionState { available, needsBuilding, unaffordable, owned }`.
6. **Comprar:** `BuyUpgradeUseCase.call({required UpgradeId id}) → UpgradeResult` comprueba, en este orden: ya comprada (nivel ≥ el de la mejora) → sin taller terminado → sin recursos en el almacén (`World.spend`, que no cobra nada si falta algo). Sube el nivel con `World.updatePlayer`. `World` no gana nada: **`updatePlayer` pierde el `@visibleForTesting`** (en iOS es pública; con la anotación, `flutter analyze` avisaría al usarla desde un caso de uso) y con él el import de `package:meta`.
7. **Listar:** `GetUpgradeOptionsUseCase.call() → List<UpgradeOptionEntity>`, una por mejora en el orden de `Upgrades.all`: `owned` (sin `missing`), si no `needsBuilding` sin taller terminado, `unaffordable` si falta algo en el almacén, `available`; `missing` medido contra el almacén como `GearOptionEntity`. `UpgradeOptionEntity.canBuy` = `available`. Los dos casos de uso van en `use-cases/game/` (son del jugador, no del héroe).
8. **La mejora se ve en la barra, sin recolorear el sprite:** `ForestBloc` llama a la herramienta por el nombre de `Upgrades.reached(tool, level)` ("Hacha de hierro" / "Pico de hierro") o, sin mejora, por el de siempre. `ToolItemData` no cambia.
9. **Menú:** `HudMenu.upgrades`; quinto botón **Taller**, **tercero** (*Misiones*, *Construir*, *Taller*, *Héroe*, *Arena*), siempre visible, con icono `CustomIcons.workshop`. `UpgradeMenu` (panel de 260–340 px de ancho como el de construir, con su propio desplazamiento) con el título "MEJORAS DE HERRAMIENTAS" (mayúsculas y estilo del título del *Héroe*) y un `UpgradeOptionTile` por mejora: nombre, efecto, coste (o "Comprada") y el motivo si no se puede ("Construye el Taller", "Faltan …"), con el botón *Comprar* (`UpgradeOptionTile.buyKey(id)`). Comprar no cierra el panel, como en *Héroe*.
10. **Efecto:** `ForestUpgradeRequested(upgrade:)` → `UpgradePurchasedEffect(upgrade:)` solo con `ok`, que la escena pinta con las chispas de comprar equipo sobre el jugador (`ParticleKind.sparkle`, sin `ParticleKind` nuevo). Avisos: `ok` "Has mejorado tu herramienta: Hacha de hierro"; `notEnoughResources` el de siempre; `noWorkshop` "Construye el Taller"; `alreadyOwned` "Ya tienes esa mejora.".
11. **Textos:** `forest.blueprint.workshop` y `forest.hud.workshop` "Taller"; `forest.upgrade.title` "Mejoras de herramientas", `forest.upgrade.ironAxe.name` "Hacha de hierro", `forest.upgrade.ironPickaxe.name` "Pico de hierro", `forest.upgrade.ironAxe.effect` "Talas con un {percent} % menos de golpes", `forest.upgrade.ironPickaxe.effect` "Picas con un {percent} % menos de golpes" (`percent` = `100 − Rules.upgradedHitsPercent`), `forest.upgrade.owned` "Comprada", `forest.upgrade.needsWorkshop` "Construye el Taller"; `forest.message.upgradePurchased` "Has mejorado tu herramienta: {name}", `forest.message.upgradeOwned` "Ya tienes esa mejora."; y las cuatro misiones. En el JSON anidado una clave no puede ser texto y grupo a la vez, así que el nombre va en `….name` (como `forest.skill.<id>.name`), no en `forest.upgrade.ironAxe`.
12. **Umbrales del HUD**, medidos con Roboto (test de usar y tirar en el *scratchpad* con `test/helpers/roboto_font.dart`) con 9999 de cada recurso, "Carga 10/10", la insignia `19/19` y las dos herramientas mejoradas: barra con nombres **1042,1** px (909,8 con las básicas), barra sin nombres 548,5, los cinco botones **593,9** (484,8 con cuatro). En una línea hacen falta 12 + 1042,1 + 8 + 593,9 + 12 = 1668,0, más la holgura de 24 → **`buttonsBelowWidth = 1700`** (antes 1460). La barra con nombres más márgenes, 1066,1, más 24 → **`narrowWidth = 1100`** (antes 960). La regla de 640 px del README de la arena se cumple aparte: por debajo, la barra sin nombres (572,5 con márgenes) y la fila de botones (617,9) caben en un móvil apaisado de 640 sin encogerse. En iOS, con SF Pro, 1800 y 1200 pt.
13. **Arte** (sin autores nuevos; el código es el de iOS, tarea 3 de su plan): `workshop` = la casita de `build_cottage()` con el muro de piedra y entramado de la herrería (`FORGE_WALL_BOX`) y el tejado de paja recoloreado en **verde** (`WORKSHOP_ROOF`), sin chimenea: 120 × 191, pivote (0.5, 1). `SpriteNames.building(workshop) == 'workshop'`, `buildingFrontOffset` 24 (es una casita). Icono `workshop.svg` (22 × 22, martillo y llave cruzados), el SVG del plan iOS.
14. **Misiones del capítulo 2**, al final de `QuestId` y detrás de las siete de F4 en `QuestLine.village` (la aldea pasa de 7 a 11; la insignia, a `x/19`): `gatherTwentyStone` (20, "Ten 20 de piedra en el almacén", `world.funds` como `gatherFortyWood`: sin estadística nueva, la compleción es pegajosa), `buildQuarry` (1, "Construye una cantera"), `buildWorkshop` (1, "Construye el Taller") y `upgradeAxe` (1, "Compra el Hacha de hierro", nivel del hacha ≥ el de `Upgrades.ironAxe`).
15. **Guardado (F2):** `toolLevels` (clave = nombre del `ToolKind`; al cargar, un nivel sin mejora en el catálogo se recorta al máximo de `Upgrades`), el taller como cualquier edificio y las misiones nuevas. Las mejoras compradas se deducen de los niveles. La ficha de F2 ya lo recoge.

### Desvíos respecto a iOS

- Las mejoras van en dos casos de uso (`BuyUpgradeUseCase`, `GetUpgradeOptionsUseCase`) en vez de dos métodos de `GameUseCase`: en Flutter hay una clase por acción.
- `World.updatePlayer` pierde el `@visibleForTesting` (decisión 6).
- Claves `forest.upgrade.<id>.name` (decisión 11) y el título del panel en mayúsculas, como el del *Héroe* (decisión 9).
- `withToolLevel` lanza `ArgumentError` en vez de un `assert` en el constructor (decisión 2).
- El nombre mejorado lo pone `ForestBloc` y no `ToolItemData` (en Flutter los modelos de vista no leen el dominio).
- Umbrales 1700 / 1100 px medidos con Roboto (iOS: 1800 / 1200 pt).
- Insignia `x/19` y la aldea en 11: Flutter no tiene la misión de recoger el hacha.

## Reparto

| Tarea | Qué |
|---|---|
| TF8.1 | El taller y el nivel de las herramientas (dominio, golpes, nombre, frame y pie) |
| TF8.2 | Las mejoras: entidades, catálogo, comprar y listar (DI) |
| TF8.3 | Arte del taller e icono del botón *Taller* |
| TF8.4 | El menú del taller: textos, panel, quinto botón, bloc, efecto y umbrales |
| TF8.5 | El segundo capítulo de misiones de la aldea |
| TF8.6 | Cierre: T1, `PROGRESS.md`, README, F2, `CLAUDE.md` |

---

### Task TF8.1: El taller y el nivel de las herramientas

**Files:**
- Modify: `lib/core/config/constants/enum/blueprint_id.dart`, `lib/layers/domain/rules/blueprints.dart`, `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/entities/player/inventory_entity.dart`, `lib/layers/domain/world/extensions/inventory_rules.dart`, `lib/layers/domain/world/woodcutting.dart`, `lib/layers/domain/world/mining.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`, `lib/layers/presentation/features/forest/game/render/render_constants.dart`
- No cambian: `tree_entity.dart`, `rock_entity.dart`, `tree_rules.dart`, `rock_rules.dart`, `work.dart`, `world.dart`, `world_state.dart`, `data/**`.

**Interfaces:**
- Consumes: `BlueprintEntity` (valores por defecto de `accepts` y `placementRule`), `TreeEntity.hitsToFell`/`hitsTaken`, `RockEntity.hitsToBreak`/`hitsTaken`, `TreeRules.hit()`, `RockRules.hit()`.
- Produces: `BlueprintId.workshop`; `Blueprints.workshop` (cuarto en `all`); `Rules.upgradedHitsPercent == 60`; `InventoryEntity({resources, tools, toolLevels})` y `copyWith(toolLevels:)`; `int InventoryRules.toolLevel(ToolKind tool)`, `InventoryEntity InventoryRules.withToolLevel(ToolKind tool, int level)`, `int InventoryRules.hitsNeeded(ToolKind tool, int hits)`; `Internationalize.forestBlueprint(id: BlueprintId.workshop)`.

- [ ] **Step 1: el taller** (caso al final):

```diff
-enum BlueprintId { house, forge, armory, mageTower, camp, storehouse, quarry }
+enum BlueprintId { house, forge, armory, mageTower, camp, storehouse, quarry, workshop }
```

`blueprints.dart`, detrás de `quarry`:

```dart
  static const BlueprintEntity workshop = BlueprintEntity(
    id: BlueprintId.workshop,
    cost: {Resource.wood: 20, Resource.stone: 10},
    hitsToBuild: 10,
    footprintRadius: 40,
  );
```

```diff
-  static const List<BlueprintEntity> all = [house, storehouse, quarry, forge, armory, mageTower, camp];
+  static const List<BlueprintEntity> all = [house, storehouse, quarry, workshop, forge, armory, mageTower, camp];
```

`rules.dart`, detrás de `quarryBoostRange`:

```dart
  static const int upgradedHitsPercent = 60;
```

- [ ] **Step 2: el nivel de las herramientas** — fichero completo `lib/layers/domain/entities/player/inventory_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final Map<Resource, int> resources;
  final Set<ToolKind> tools;
  final Map<ToolKind, int> toolLevels;

  const InventoryEntity({this.resources = const {}, this.tools = const {}, this.toolLevels = const {}});

  InventoryEntity copyWith({Map<Resource, int>? resources, Set<ToolKind>? tools, Map<ToolKind, int>? toolLevels}) {
    return InventoryEntity(
      resources: resources ?? this.resources,
      tools: tools ?? this.tools,
      toolLevels: toolLevels ?? this.toolLevels,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity &&
      const MapEquality<Resource, int>().equals(other.resources, resources) &&
      const SetEquality<ToolKind>().equals(other.tools, tools) &&
      const MapEquality<ToolKind, int>().equals(other.toolLevels, toolLevels);

  @override
  int get hashCode => Object.hash(
    const MapEquality<Resource, int>().hash(resources),
    const SetEquality<ToolKind>().hash(tools),
    const MapEquality<ToolKind, int>().hash(toolLevels),
  );
}
```

`inventory_rules.dart`, detrás de `hasTool` (ya importa `dart:math`, `tool_kind.dart` y `rules.dart`):

```dart
  int toolLevel(ToolKind tool) => toolLevels[tool] ?? 1;

  InventoryEntity withToolLevel(ToolKind tool, int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'A ${tool.name} level starts at 1');
    }
    return copyWith(toolLevels: {...toolLevels, tool: level});
  }

  int hitsNeeded(ToolKind tool, int hits) {
    if (toolLevel(tool) == 1) return hits;
    return max(1, (hits * Rules.upgradedHitsPercent + 99) ~/ 100);
  }
```

`(hits × 60 + 99) ~/ 100` es `⌈hits × 0,6⌉`: 1 → 1, 2 → 2, 3 → 2, 4 → 3, 5 → 3, 6 → 4, 7 → 5, 8 → 5, 9 → 6.

- [ ] **Step 3: talar y picar con los golpes de la herramienta** — `woodcutting.dart`, en `impact`:

```diff
     final tree = state.trees[intent.treeId]?.hit();
     if (tree == null) return true;
-    events.add(TreeHitEventEntity(treeId: tree.id, hitsRemaining: tree.hitsRemaining));
-    if (!tree.isFelled) {
+    final hitsRemaining = max(0, state.player.inventory.hitsNeeded(ToolKind.axe, tree.hitsToFell) - tree.hitsTaken);
+    events.add(TreeHitEventEntity(treeId: tree.id, hitsRemaining: hitsRemaining));
+    if (hitsRemaining > 0) {
       state.trees[tree.id] = tree;
       return false;
     }
```

`mining.dart`, en `impact`:

```diff
     events.add(RockHitEventEntity(rockId: rock.id));
-    if (!rock.isBroken) {
+    if (rock.hitsTaken < state.player.inventory.hitsNeeded(ToolKind.pickaxe, rock.hitsToBreak)) {
       state.rocks[rock.id] = rock;
       return false;
     }
```

Con nivel 1, `hitsNeeded` devuelve los mismos golpes y los dos sistemas hacen exactamente lo de antes (`hitsRemaining` = `tree.hitsRemaining`, `hitsTaken < hitsToBreak` = `!isBroken`). Los dos ficheros ya importan `dart:math`, `tool_kind.dart` e `inventory_rules.dart`.

- [ ] **Step 4: nombre, frame y pie** — `es.json`: `"workshop": "Taller"` detrás de `"quarry": "Cantera"` en `forest.blueprint`. `internationalize.dart`, en `forestBlueprint`:

```diff
     BlueprintId.quarry => '$_forest.blueprint.quarry'.tr(),
+    BlueprintId.workshop => '$_forest.blueprint.workshop'.tr(),
```

`sprite_names.dart`:

```diff
     BlueprintId.quarry => 'quarry',
+    BlueprintId.workshop => 'workshop',
```

`render_constants.dart`:

```diff
     BlueprintId.quarry => 16,
+    BlueprintId.workshop => 24,
```

El frame `workshop` llega en TF8.3; hasta entonces el taller no se dibuja (nadie ejecuta la app entre tareas).

- [ ] **Step 5: Verificar** — `dart format --line-length 120` sobre los diez ficheros `.dart`; `flutter analyze lib` → `No issues found!`; `grep -rn "isFelled\|isBroken" lib/layers/domain/world` solo con las guardas de `tree_rules.dart` y `rock_rules.dart`.
- [ ] **Step 6: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F8]: Add the workshop and the tool levels`.

### Task TF8.2: Las mejoras de herramientas

**Files:**
- Create: `lib/core/config/constants/enum/upgrade_id.dart`, `lib/core/config/constants/enum/upgrade_result.dart`, `lib/core/config/constants/enum/upgrade_option_state.dart`, `lib/layers/domain/entities/upgrade/upgrade_entity.dart`, `lib/layers/domain/entities/upgrade/upgrade_option_entity.dart`, `lib/layers/domain/rules/upgrades.dart`, `lib/layers/domain/use-cases/game/buy_upgrade_use_case.dart`, `lib/layers/domain/use-cases/game/get_upgrade_options_use_case.dart`
- Modify: `lib/layers/domain/world/world.dart`, `lib/core/config/di/di.config.dart` (regenerado)

**Interfaces:**
- Consumes: `InventoryRules.toolLevel` / `withToolLevel` (TF8.1), `BlueprintId.workshop` (TF8.1), `World.spend`, `World.funds`, `World.player`, `World.buildings`, `BuildingListRules.hasComplete`, `PlayerRules.withInventory`, `InventoryRules.missing`.
- Produces: `enum UpgradeId { ironAxe, ironPickaxe }`; `enum UpgradeResult { ok, notEnoughResources, noWorkshop, alreadyOwned }`; `enum UpgradeOptionState { available, needsBuilding, unaffordable, owned }`; `UpgradeEntity({id, tool, level, cost})`; `UpgradeOptionEntity({upgrade, state, missing})` con `canBuy`; `Upgrades.building`, `Upgrades.ironAxe`, `Upgrades.ironPickaxe`, `Upgrades.all`, `UpgradeEntity Upgrades.of(UpgradeId id)`, `UpgradeEntity? Upgrades.reached(ToolKind tool, int level)`; `UpgradeResult BuyUpgradeUseCase.call({required UpgradeId id})`; `List<UpgradeOptionEntity> GetUpgradeOptionsUseCase.call()`; `World.updatePlayer` sin `@visibleForTesting`.

- [ ] **Step 1: enums** — tres ficheros nuevos en `lib/core/config/constants/enum/`:

```dart
enum UpgradeId { ironAxe, ironPickaxe }
```

```dart
enum UpgradeResult { ok, notEnoughResources, noWorkshop, alreadyOwned }
```

```dart
enum UpgradeOptionState { available, needsBuilding, unaffordable, owned }
```

- [ ] **Step 2: entidades** — fichero completo `lib/layers/domain/entities/upgrade/upgrade_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../core/config/constants/enum/upgrade_id.dart';

class UpgradeEntity {
  final UpgradeId id;
  final ToolKind tool;
  final int level;
  final Map<Resource, int> cost;

  const UpgradeEntity({required this.id, required this.tool, required this.level, required this.cost})
    : assert(level > 1);

  UpgradeEntity copyWith({UpgradeId? id, ToolKind? tool, int? level, Map<Resource, int>? cost}) {
    return UpgradeEntity(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      level: level ?? this.level,
      cost: cost ?? this.cost,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpgradeEntity &&
      other.id == id &&
      other.tool == tool &&
      other.level == level &&
      const MapEquality<Resource, int>().equals(other.cost, cost);

  @override
  int get hashCode => Object.hash(id, tool, level, const MapEquality<Resource, int>().hash(cost));
}
```

Fichero completo `lib/layers/domain/entities/upgrade/upgrade_option_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/upgrade_option_state.dart';
import 'upgrade_entity.dart';

class UpgradeOptionEntity {
  final UpgradeEntity upgrade;
  final UpgradeOptionState state;
  final Map<Resource, int> missing;

  const UpgradeOptionEntity({required this.upgrade, required this.state, this.missing = const {}});

  bool get canBuy => state == UpgradeOptionState.available;

  UpgradeOptionEntity copyWith({UpgradeEntity? upgrade, UpgradeOptionState? state, Map<Resource, int>? missing}) {
    return UpgradeOptionEntity(
      upgrade: upgrade ?? this.upgrade,
      state: state ?? this.state,
      missing: missing ?? this.missing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpgradeOptionEntity &&
      other.upgrade == upgrade &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(upgrade, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'UpgradeOptionEntity(upgrade: ${upgrade.id}, state: $state, missing: $missing)';
}
```

- [ ] **Step 3: el catálogo** — fichero completo `lib/layers/domain/rules/upgrades.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../../../core/config/constants/enum/upgrade_id.dart';
import '../entities/upgrade/upgrade_entity.dart';

abstract final class Upgrades {
  static const BlueprintId building = BlueprintId.workshop;

  static const UpgradeEntity ironAxe = UpgradeEntity(
    id: UpgradeId.ironAxe,
    tool: ToolKind.axe,
    level: 2,
    cost: {Resource.wood: 15, Resource.stone: 15},
  );

  static const UpgradeEntity ironPickaxe = UpgradeEntity(
    id: UpgradeId.ironPickaxe,
    tool: ToolKind.pickaxe,
    level: 2,
    cost: {Resource.wood: 10, Resource.stone: 20},
  );

  static const List<UpgradeEntity> all = [ironAxe, ironPickaxe];

  static UpgradeEntity of(UpgradeId id) => all.firstWhere((upgrade) => upgrade.id == id);

  static UpgradeEntity? reached(ToolKind tool, int level) =>
      all.lastWhereOrNull((upgrade) => upgrade.tool == tool && upgrade.level <= level);
}
```

El efecto (−40 %) es el mismo para las dos y sale de `Rules.upgradedHitsPercent`, no de la mejora.

- [ ] **Step 4: comprar** — fichero completo `lib/layers/domain/use-cases/game/buy_upgrade_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../../core/config/constants/enum/upgrade_result.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/upgrades.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/extensions/player_rules.dart';

@Injectable()
final class BuyUpgradeUseCase {
  final GameSessionRepository _sessionRepository;

  const BuyUpgradeUseCase({required this._sessionRepository});

  UpgradeResult call({required UpgradeId id}) {
    final world = _sessionRepository.current().world;
    final upgrade = Upgrades.of(id);
    if (world.player.inventory.toolLevel(upgrade.tool) >= upgrade.level) return UpgradeResult.alreadyOwned;
    if (!world.buildings.hasComplete(Upgrades.building)) return UpgradeResult.noWorkshop;
    if (!world.spend(upgrade.cost)) return UpgradeResult.notEnoughResources;
    world.updatePlayer(
      (player) => player.withInventory(player.inventory.withToolLevel(upgrade.tool, upgrade.level)),
    );
    return UpgradeResult.ok;
  }
}
```

- [ ] **Step 5: listar** — fichero completo `lib/layers/domain/use-cases/game/get_upgrade_options_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/upgrade_option_state.dart';
import '../../entities/upgrade/upgrade_entity.dart';
import '../../entities/upgrade/upgrade_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/upgrades.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/world.dart';

@Injectable()
final class GetUpgradeOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetUpgradeOptionsUseCase({required this._sessionRepository});

  List<UpgradeOptionEntity> call() {
    final world = _sessionRepository.current().world;
    return [for (final upgrade in Upgrades.all) _option(world, upgrade)];
  }

  UpgradeOptionEntity _option(World world, UpgradeEntity upgrade) {
    if (world.player.inventory.toolLevel(upgrade.tool) >= upgrade.level) {
      return UpgradeOptionEntity(upgrade: upgrade, state: UpgradeOptionState.owned);
    }
    final missing = world.funds.missing(upgrade.cost);
    final UpgradeOptionState state;
    if (!world.buildings.hasComplete(Upgrades.building)) {
      state = UpgradeOptionState.needsBuilding;
    } else if (missing.isNotEmpty) {
      state = UpgradeOptionState.unaffordable;
    } else {
      state = UpgradeOptionState.available;
    }
    return UpgradeOptionEntity(upgrade: upgrade, state: state, missing: missing);
  }
}
```

- [ ] **Step 6: `World.updatePlayer` sin la anotación** — `world.dart`:

```diff
-import 'package:meta/meta.dart';
-
 import '../../../core/config/constants/enum/chop_result.dart';
```

```diff
-  @visibleForTesting
   void updatePlayer(PlayerEntity Function(PlayerEntity player) transform) {
```

- [ ] **Step 7: Verificar** — `dart run build_runner build --delete-conflicting-outputs` (el `di.config.dart` gana `BuyUpgradeUseCase` y `GetUpgradeOptionsUseCase`; no se formatea); `dart format --line-length 120` sobre los nueve ficheros escritos a mano; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 8: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F8]: Add the tool upgrades`.

### Task TF8.3: Arte del taller e icono del botón *Taller*

**Files:**
- Create: `lib/core/assets/images/icons/workshop.svg`
- Modify: `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/forest.png` y `forest.json` (regenerados), `lib/core/assets/images/lpc/CREDITS.md`, `lib/layers/presentation/theme/images/custom_icons.dart`

**Interfaces:**
- Consumes: `build_cottage()`, `FORGE_WALL_BOX`, `ROOF_RAMP` y `recolour()` del script; `SpriteNames.building(BlueprintId.workshop) == 'workshop'` (TF8.1).
- Produces: el frame `workshop` (120 × 191, pivote (0.5, 1)) en `forest.json`, que leen `BuildingComponent` y `PlacementGhostComponent`; `CustomIcons.workshop`.

- [ ] **Step 1: `build_assets.py`** (el código de iOS, tarea 3 de su plan; la parte del bosque del script es igual en los dos repos):

```diff
 FORGE_WALL_BOX = (0, 256, 96, 352)  # cottage.png, stone wall with timber frame
+WORKSHOP_ROOF = [(14, 30, 18), (18, 38, 24), (28, 62, 34), (36, 78, 42), (46, 96, 50), (54, 110, 56), (70, 134, 68), (96, 166, 86), (122, 188, 106)]
```

```diff
+def build_workshop() -> Image.Image:
+    return build_cottage(FORGE_WALL_BOX, WORKSHOP_ROOF)
+
+
 def build_storehouse(terrain: Image.Image) -> Image.Image:
```

```diff
     frames["quarry"] = build_quarry(terrain)
     pivots["quarry"] = {"x": 0.5, "y": 1}
+    frames["workshop"] = build_workshop()
+    pivots["workshop"] = {"x": 0.5, "y": 1}
```

```diff
-                                   the storehouse, the camp and the quarry (pivot = bottom centre)
+                                   the storehouse, the camp, the quarry and the workshop (pivot = bottom centre)
```

- [ ] **Step 2: regenerar** — `cd asset-packs/lpc && python3 build_assets.py`. `git status` enseña solo `forest.png`, `forest.json` y el script (si sale otra salida, `git restore` de esa ruta y se revisa). Con un script de usar y tirar en el *scratchpad* (Pillow) que compara cada frame del atlas anterior (`git show HEAD:…`) con el nuevo: añadido `workshop` (120 × 191, pivote (0.5, 1)), ningún frame anterior cambia. Mirar el recorte ampliado: la casita de piedra con el tejado verde, sin chimenea.
- [ ] **Step 3: créditos** (sin autores nuevos), detrás de la línea del almacén en la sección de las casas, y el título de la sección con el frame nuevo:

```diff
-## House, forge, armory, mage tower and storehouse (`house`, `forge`, `armory`, `mage-tower`, `storehouse` frames in `forest.png`)
+## House, forge, armory, mage tower, storehouse and workshop (`house`, `forge`, `armory`, `mage-tower`, `storehouse`, `workshop` frames in `forest.png`)
```

```diff
 The storehouse (`storehouse` frame) is the same cottage with the ochre wall and the thatched roof, with two
 closed chests of the LPC Tile Atlas above beside the door.
+The workshop (`workshop` frame) is the cottage with the forge's stone wall and the thatched roof recoloured green.
```

- [ ] **Step 4: el icono** — fichero completo `lib/core/assets/images/icons/workshop.svg` (SVG propio del proyecto, sin créditos, como los demás iconos del HUD; el de iOS):

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
  <path d="M4 19.5L13.5 10" stroke="#8A5A2B" stroke-width="2.6" stroke-linecap="round"/>
  <path d="M9.5 6L14 1.5L20.5 8L16 12.5Z" fill="#C9CED6"/>
  <path d="M5 4.5L17.5 17" stroke="#E2B33C" stroke-width="2.2" stroke-linecap="round"/>
  <circle cx="4.5" cy="4" r="2.6" fill="none" stroke="#E2B33C" stroke-width="1.8"/>
</svg>
```

`custom_icons.dart`, detrás de `lock`:

```dart
  static const String workshop = '$_path/workshop.svg';
```

`pubspec.yaml` ya declara la carpeta `lib/core/assets/images/icons/`.

- [ ] **Step 5: Verificar** — `dart format --line-length 120` sobre `custom_icons.dart`; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 6: Commit** — `git add asset-packs lib` y, aparte, el commit `[PROJECT-F8]: Add the workshop art`.

### Task TF8.4: El menú del taller

**Files:**
- Create: `lib/layers/presentation/features/forest/models/upgrade_item_data.dart`, `lib/layers/presentation/features/forest/widgets/upgrade_option_tile.dart`, `lib/layers/presentation/features/forest/widgets/upgrade_menu.dart`
- Modify: `lib/core/config/constants/enum/forest/hud_menu.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/models/hud_data.dart`, `lib/layers/presentation/features/forest/models/forest_effect.dart`, `lib/layers/presentation/features/forest/bloc/forest_event.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`, `lib/layers/presentation/features/forest/forest_page.dart`, `lib/layers/presentation/features/forest/game/forest_scene_component.dart`
- No cambian: `tool_item_data.dart`, `resource_bar.dart`, `hud_button.dart`, `particle_kind.dart`, `particle_bursts.dart`, el dominio.

**Interfaces:**
- Consumes: `GetUpgradeOptionsUseCase`, `BuyUpgradeUseCase`, `UpgradeOptionEntity`, `UpgradeOptionState`, `UpgradeResult`, `UpgradeId`, `Upgrades.reached` (TF8.2); `InventoryRules.toolLevel`, `Rules.upgradedHitsPercent` (TF8.1); `CustomIcons.workshop` (TF8.3); `Internationalize.forestMissing`, `forestHeroBuy`, `forestMessageNotEnoughResources`; `_sparkleOnPlayer` de la escena.
- Produces: `HudMenu.upgrades`; `UpgradeItemData({id, name, effectText, costText, reasonText, canBuy})`; `HudData(upgradeItems:)`; `UpgradePurchasedEffect({required UpgradeId upgrade})`; `ForestUpgradeRequested({required UpgradeId upgrade})`; `ForestBloc(getUpgradeOptionsUseCase:, buyUpgradeUseCase:)`; `UpgradeMenu({items, onBuy})`; `UpgradeOptionTile({item, onBuy})` y `UpgradeOptionTile.buyKey(UpgradeId)`; `HudOverlay(onUpgradeSelected:)`, `HudOverlay.narrowWidth == 1100`, `HudOverlay.buttonsBelowWidth == 1700`; `Internationalize.forestWorkshop`, `forestUpgradeTitle`, `forestUpgradeName({id})`, `forestUpgradeEffect({id, percent})`, `forestUpgradeOwned`, `forestUpgradeNeedsWorkshop`, `forestMessageUpgradePurchased({name})`, `forestMessageUpgradeOwned`.

- [ ] **Step 1: textos** — `es.json`: `"workshop": "Taller"` detrás de `"carry"` en `forest.hud`; en `forest.message`, detrás de `skillMaxLevel`, `"upgradePurchased": "Has mejorado tu herramienta: {name}"` y `"upgradeOwned": "Ya tienes esa mejora."`; y un grupo nuevo detrás de `forest.skill`:

```json
    "upgrade": {
      "title": "Mejoras de herramientas",
      "ironAxe": {
        "name": "Hacha de hierro",
        "effect": "Talas con un {percent} % menos de golpes"
      },
      "ironPickaxe": {
        "name": "Pico de hierro",
        "effect": "Picas con un {percent} % menos de golpes"
      },
      "owned": "Comprada",
      "needsWorkshop": "Construye el Taller"
    },
```

`internationalize.dart` (import de `upgrade_id.dart`), detrás de `forestArena`:

```dart
  static String get forestWorkshop => '$_forest.hud.workshop'.tr();
```

y detrás de `forestMessageSkillMaxLevel`:

```dart
  static String get forestUpgradeTitle => '$_forest.upgrade.title'.tr();
  static String forestUpgradeName({required UpgradeId id}) => switch (id) {
    UpgradeId.ironAxe => '$_forest.upgrade.ironAxe.name'.tr(),
    UpgradeId.ironPickaxe => '$_forest.upgrade.ironPickaxe.name'.tr(),
  };
  static String forestUpgradeEffect({required UpgradeId id, required int percent}) => switch (id) {
    UpgradeId.ironAxe => '$_forest.upgrade.ironAxe.effect'.tr(namedArgs: {'percent': '$percent'}),
    UpgradeId.ironPickaxe => '$_forest.upgrade.ironPickaxe.effect'.tr(namedArgs: {'percent': '$percent'}),
  };
  static String get forestUpgradeOwned => '$_forest.upgrade.owned'.tr();
  static String get forestUpgradeNeedsWorkshop => '$_forest.upgrade.needsWorkshop'.tr();
  static String forestMessageUpgradePurchased({required String name}) =>
      '$_forest.message.upgradePurchased'.tr(namedArgs: {'name': name});
  static String get forestMessageUpgradeOwned => '$_forest.message.upgradeOwned'.tr();
```

- [ ] **Step 2: modelos** — `hud_menu.dart`:

```diff
-enum HudMenu { quests, build, hero }
+enum HudMenu { quests, build, hero, upgrades }
```

Fichero completo `lib/layers/presentation/features/forest/models/upgrade_item_data.dart`:

```dart
import '../../../../../core/config/constants/enum/upgrade_id.dart';

class UpgradeItemData {
  final UpgradeId id;
  final String name;
  final String effectText;
  final String costText;
  final String? reasonText;
  final bool canBuy;

  const UpgradeItemData({
    required this.id,
    required this.name,
    required this.effectText,
    required this.costText,
    this.reasonText,
    required this.canBuy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpgradeItemData &&
          other.id == id &&
          other.name == name &&
          other.effectText == effectText &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.canBuy == canBuy;

  @override
  int get hashCode => Object.hash(id, name, effectText, costText, reasonText, canBuy);
}
```

`hud_data.dart` (import de `upgrade_item_data.dart`): campo `final List<UpgradeItemData> upgradeItems;` detrás de `buildItems`, `required this.upgradeItems,` en el constructor en el mismo sitio, y en `==` / `hashCode`:

```diff
           const ListEquality<BuildItemData>().equals(other.buildItems, buildItems) &&
+          const ListEquality<UpgradeItemData>().equals(other.upgradeItems, upgradeItems) &&
           other.isBuildLocked == isBuildLocked &&
```

```diff
     Object.hashAll(buildItems),
+    Object.hashAll(upgradeItems),
     isBuildLocked,
```

`forest_effect.dart` (import de `upgrade_id.dart`), al final:

```dart
final class UpgradePurchasedEffect extends ForestEffect {
  final UpgradeId upgrade;

  const UpgradePurchasedEffect({required this.upgrade});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UpgradePurchasedEffect && other.upgrade == upgrade;

  @override
  int get hashCode => Object.hash(UpgradePurchasedEffect, upgrade);
}
```

`forest_event.dart`, al final:

```dart
final class ForestUpgradeRequested extends ForestEvent {
  final UpgradeId upgrade;

  const ForestUpgradeRequested({required this.upgrade});
}
```

- [ ] **Step 3: la fila y el panel** — fichero completo `lib/layers/presentation/features/forest/widgets/upgrade_option_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/upgrade_item_data.dart';
import 'hud_button.dart';

class UpgradeOptionTile extends StatelessWidget {
  final UpgradeItemData item;
  final VoidCallback? onBuy;

  const UpgradeOptionTile({super.key, required this.item, this.onBuy});

  static Key buyKey(UpgradeId id) => Key('upgradeOptionTileBuy-${id.name}');

  @override
  Widget build(BuildContext context) {
    final reasonText = item.reasonText;
    return DecoratedBox(
      decoration: BoxDecoration(color: CustomColors.hudOptionBackground, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    item.name,
                    style: CustomTextStyles.system15w600.copyWith(
                      color: item.canBuy ? CustomColors.hudText : CustomColors.hudMuted,
                    ),
                  ),
                  Text(item.effectText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudMuted)),
                  Text(
                    item.costText,
                    style: CustomTextStyles.system13w500.copyWith(
                      color: item.canBuy ? CustomColors.hudAccent : CustomColors.hudMuted,
                    ),
                  ),
                  if (reasonText != null)
                    Text(reasonText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
                ],
              ),
            ),
            HudButton(
              key: buyKey(item.id),
              label: Internationalize.forestHeroBuy,
              onPressed: item.canBuy ? onBuy : null,
            ),
          ],
        ),
      ),
    );
  }
}
```

Fichero completo `lib/layers/presentation/features/forest/widgets/upgrade_menu.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/upgrade_item_data.dart';
import 'hud_panel.dart';
import 'upgrade_option_tile.dart';

class UpgradeMenu extends StatelessWidget {
  final List<UpgradeItemData> items;
  final ValueChanged<UpgradeId> onBuy;

  const UpgradeMenu({super.key, required this.items, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 340),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Semantics(
                  header: true,
                  child: Text(
                    Internationalize.forestUpgradeTitle.toUpperCase(),
                    style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78),
                  ),
                ),
              ),
              for (final item in items) UpgradeOptionTile(item: item, onBuy: () => onBuy(item.id)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: el bloc** — `forest_bloc.dart`. Imports: `upgrade_id.dart`, `upgrade_option_state.dart`, `upgrade_result.dart` (core), `entities/upgrade/upgrade_option_entity.dart`, `rules/upgrades.dart`, `use-cases/game/buy_upgrade_use_case.dart`, `use-cases/game/get_upgrade_options_use_case.dart`, `models/upgrade_item_data.dart`. Campos y parámetros nuevos detrás de `_learnSkillUseCase`:

```dart
  final GetUpgradeOptionsUseCase _getUpgradeOptionsUseCase;
  final BuyUpgradeUseCase _buyUpgradeUseCase;
```

```dart
    required this._getUpgradeOptionsUseCase,
    required this._buyUpgradeUseCase,
```

En el `switch` de eventos, al final:

```dart
        ForestUpgradeRequested() => _onUpgradeRequested(event, emit),
```

Detrás de `_learnSkill`:

```dart
  Future<void> _onUpgradeRequested(ForestUpgradeRequested event, Emitter<ForestState> emit) async {
    if (state is! ForestSuccess) return;
    final effects = <ForestEffect>[];
    _buyUpgrade(event.upgrade, effects: effects);
    emit(ForestSuccess(data: _buildData(effects: effects)));
  }

  void _buyUpgrade(UpgradeId id, {required List<ForestEffect> effects}) {
    switch (_buyUpgradeUseCase(id: id)) {
      case UpgradeResult.ok:
        _showMessage(Internationalize.forestMessageUpgradePurchased(name: Internationalize.forestUpgradeName(id: id)));
        effects.add(UpgradePurchasedEffect(upgrade: id));
      case UpgradeResult.notEnoughResources:
        _showMessage(Internationalize.forestMessageNotEnoughResources);
      case UpgradeResult.noWorkshop:
        _showMessage(Internationalize.forestUpgradeNeedsWorkshop);
      case UpgradeResult.alreadyOwned:
        _showMessage(Internationalize.forestMessageUpgradeOwned);
    }
  }
```

En `_hudData`, el nombre de la herramienta y las mejoras:

```diff
           ToolItemData(
             tool: tool,
-            name: Internationalize.forestTool(tool: tool),
+            name: _toolName(tool, level: status.inventory.toolLevel(tool)),
             isOwned: status.inventory.hasTool(tool),
           ),
```

```diff
       buildItems: [for (final option in _getBuildOptionsUseCase()) _buildItem(option)],
+      upgradeItems: [for (final option in _getUpgradeOptionsUseCase()) _upgradeItem(option)],
       isBuildLocked: _placement != null,
```

Y detrás de `_buildItem`:

```dart
  String _toolName(ToolKind tool, {required int level}) {
    final upgrade = Upgrades.reached(tool, level);
    return upgrade == null
        ? Internationalize.forestTool(tool: tool)
        : Internationalize.forestUpgradeName(id: upgrade.id);
  }

  UpgradeItemData _upgradeItem(UpgradeOptionEntity option) {
    final upgrade = option.upgrade;
    return UpgradeItemData(
      id: upgrade.id,
      name: Internationalize.forestUpgradeName(id: upgrade.id),
      effectText: Internationalize.forestUpgradeEffect(id: upgrade.id, percent: 100 - Rules.upgradedHitsPercent),
      costText: option.state == UpgradeOptionState.owned ? Internationalize.forestUpgradeOwned : _amounts(upgrade.cost),
      reasonText: switch (option.state) {
        UpgradeOptionState.needsBuilding => Internationalize.forestUpgradeNeedsWorkshop,
        UpgradeOptionState.unaffordable => Internationalize.forestMissing(amounts: _amounts(option.missing)),
        UpgradeOptionState.available || UpgradeOptionState.owned => null,
      },
      canBuy: option.canBuy,
    );
  }
```

`ForestBloc` ya importa `rules.dart` e `inventory_rules.dart`.

- [ ] **Step 5: el quinto botón y los umbrales** — `hud_overlay.dart` (imports de `upgrade_id.dart` y `upgrade_menu.dart`):

```diff
-  static const double narrowWidth = 960;
-  static const double buttonsBelowWidth = 1460;
+  static const double narrowWidth = 1100;
+  static const double buttonsBelowWidth = 1700;
```

Campo `final ValueChanged<UpgradeId> onUpgradeSelected;` y `required this.onUpgradeSelected,` detrás de `onSkillSelected`. En `_buttonRow`, detrás de *Construir*:

```dart
        HudButton(
          label: Internationalize.forestWorkshop,
          icon: CustomIcons.workshop,
          isActive: _openMenu == HudMenu.upgrades,
          onPressed: () => _toggle(HudMenu.upgrades),
        ),
```

En `_menu`, al final:

```dart
      HudMenu.upgrades => UpgradeMenu(items: widget.hud.upgradeItems, onBuy: widget.onUpgradeSelected),
```

Medida (decisión 12): barra con nombres 1042,1, botones 593,9 → 1700 y 1100.

- [ ] **Step 6: la página y la escena** — `forest_page.dart` (imports de `use-cases/game/buy_upgrade_use_case.dart` y `get_upgrade_options_use_case.dart`), detrás de `learnSkillUseCase`:

```dart
        getUpgradeOptionsUseCase: locator.get<GetUpgradeOptionsUseCase>(),
        buyUpgradeUseCase: locator.get<BuyUpgradeUseCase>(),
```

y en `_hudOverlay`, detrás de `onSkillSelected`:

```dart
      onUpgradeSelected: (upgrade) => bloc.add(ForestUpgradeRequested(upgrade: upgrade)),
```

`forest_scene_component.dart`, en `_play`, al final:

```dart
      case UpgradePurchasedEffect():
        _sparkleOnPlayer(ParticleKind.sparkle);
```

- [ ] **Step 7: Verificar** — `python3 -c "import json; json.load(open('lib/core/assets/i18n/translations/es.json'))"`; `dart format --line-length 120` sobre los doce ficheros `.dart`; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 8: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F8]: Add the upgrade menu`.

### Task TF8.5: El segundo capítulo de misiones de la aldea

**Files:**
- Modify: `lib/core/config/constants/enum/quest_id.dart`, `lib/layers/domain/quests/quests.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`
- No cambian: `quest_log.dart`, `stats_entity.dart`, `stats_recording.dart`, `forest_bloc.dart` (la insignia cuenta las misiones que haya: `x/19`; la aldea completa se anuncia con la undécima).

**Interfaces:**
- Consumes: `World.funds`, `World.player`, `BuildingListRules.hasComplete`, `BlueprintId.quarry` (F7), `BlueprintId.workshop`, `InventoryRules.toolLevel` (TF8.1), `Upgrades.ironAxe` (TF8.2).
- Produces: `QuestId.gatherTwentyStone`, `QuestId.buildQuarry`, `QuestId.buildWorkshop`, `QuestId.upgradeAxe` (al final); sus títulos en `Internationalize.forestQuestTitle`.

- [ ] **Step 1: las cuatro misiones** — `quest_id.dart`, detrás de `seeATreeRegrow`:

```dart
  gatherTwentyStone,
  buildQuarry,
  buildWorkshop,
  upgradeAxe,
```

`quests.dart` (imports de `tool_kind.dart` y `../rules/upgrades.dart`), detrás de `seeATreeRegrow` y antes de las del héroe:

```dart
    _MeasuredQuest(
      id: QuestId.gatherTwentyStone,
      line: QuestLine.village,
      target: 20,
      measure: (world) => world.funds.amount(Resource.stone),
    ),
    _MeasuredQuest(
      id: QuestId.buildQuarry,
      line: QuestLine.village,
      target: 1,
      measure: (world) => _built(world, BlueprintId.quarry),
    ),
    _MeasuredQuest(
      id: QuestId.buildWorkshop,
      line: QuestLine.village,
      target: 1,
      measure: (world) => _built(world, BlueprintId.workshop),
    ),
    _MeasuredQuest(
      id: QuestId.upgradeAxe,
      line: QuestLine.village,
      target: 1,
      measure: (world) => world.player.inventory.toolLevel(ToolKind.axe) >= Upgrades.ironAxe.level ? 1 : 0,
    ),
```

- [ ] **Step 2: títulos** — `es.json`, en `forest.quest`, detrás de `seeATreeRegrow`:

```json
      "gatherTwentyStone": "Ten 20 de piedra en el almacén",
      "buildQuarry": "Construye una cantera",
      "buildWorkshop": "Construye el Taller",
      "upgradeAxe": "Compra el Hacha de hierro"
```

`internationalize.dart`, en `forestQuestTitle`:

```diff
     QuestId.seeATreeRegrow => '$_forest.quest.seeATreeRegrow'.tr(),
+    QuestId.gatherTwentyStone => '$_forest.quest.gatherTwentyStone'.tr(),
+    QuestId.buildQuarry => '$_forest.quest.buildQuarry'.tr(),
+    QuestId.buildWorkshop => '$_forest.quest.buildWorkshop'.tr(),
+    QuestId.upgradeAxe => '$_forest.quest.upgradeAxe'.tr(),
```

- [ ] **Step 3: Verificar** — JSON válido; `dart format --line-length 120` sobre los tres ficheros `.dart`; `flutter analyze lib` → `No issues found!`.
- [ ] **Step 4: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F8]: Add the second village chapter quests`.

### Task TF8.6: Cierre de la fase

- [ ] **Step 1:** añadir a *Para T1* de `docs/boost/plans/2026-10-17-extras/T1-tests.md` el bullet `- **F8** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F8 → `✅`, `feature/PROJECT-F8-workshop`, nota "Bloque 2. Sin tests (T1)."; `README.md`: icono de F8 → ✅; cabecera de este plan con lo implementado y los desvíos; la ficha de F2 si cambió lo que hay que guardar (ya recoge `toolLevels`, el taller y las misiones: comprobarlo).
- [ ] **Step 3:** `CLAUDE.md`: el taller (`BlueprintId.workshop`, cuarto del menú), `InventoryEntity.toolLevels` y `InventoryRules.toolLevel` / `withToolLevel` / `hitsNeeded`, `Rules.upgradedHitsPercent`, `Woodcutting`/`Mining` con los golpes de la herramienta, `UpgradeEntity` / `UpgradeOptionEntity`, `Upgrades`, `BuyUpgradeUseCase` (orden de las comprobaciones) y `GetUpgradeOptionsUseCase`, `World.updatePlayer` público, `HudMenu.upgrades`, `UpgradeMenu` + `UpgradeOptionTile`, el quinto botón *Taller* y los umbrales 1700 / 1100, `ForestUpgradeRequested` / `UpgradePurchasedEffect`, el nombre mejorado en la barra, las misiones del capítulo 2 y el frame `workshop`. Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs asset-packs lib/core/assets/images/lpc` (lo que haya); `git add CLAUDE.md` (comando aparte); el commit `[PROJECT-F8]: Close the workshop phase` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque 2 de la aldea, en Chrome y Android:

1. "Taller" (20 de madera, 10 de piedra) es el cuarto del menú de construir, tras la cantera. Terminado es una casita de piedra con el tejado verde.
2. El botón *Taller* (tercero, con el icono de martillo y llave) abre el panel "MEJORAS DE HERRAMIENTAS" con el *Hacha de hierro* y el *Pico de hierro*, su efecto ("Talas con un 40 % menos de golpes") y su coste; sin taller terminado, "Construye el Taller" y *Comprar* desactivado; sin recursos, "Faltan …".
3. Con el taller, comprar el hacha descuenta 15 de madera y 15 de piedra del almacén (no de la carga), echa chispas sobre el jugador, avisa "Has mejorado tu herramienta: Hacha de hierro", el panel sigue abierto con "Comprada" y la barra dice "Hacha de hierro".
4. Después, un pino cae en 2 golpes, un roble en 5 y un árbol a medio talar cae en cuanto lleva los golpes nuevos; con el pico de hierro, una roca se rompe en 5. El ritmo de los golpes no cambia (junto a una cantera sigue yendo más rápido).
5. Las cuatro misiones nuevas avanzan en la línea de la aldea y la insignia llega a 19/19; con la undécima, "¡Has completado las misiones de Aldea!".
6. HUD: los cinco botones caben en la línea de la barra a partir de 1700 px y bajan debajo por debajo; los nombres de la barra se ocultan por debajo de 1100; en un móvil apaisado (640) la barra y los botones caben.
7. La arena no cambia: el ataque del héroe es el mismo con el hacha de hierro.

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F8 (no se ha tocado `test/`; los de iOS, en su *Para T1*, valen de referencia). Datos en `test/mocks/**` (p. ej. `InventoryEntityMock` con `toolLevels`, `UpgradeEntityMock`, `UpgradeOptionEntityMock`, `UpgradeItemDataMock`, `BuildingEntityMock.workshop` / `workshopSite`, `TreeEntityMock`, `RockEntityMock`), nunca en línea:

- **Compilación:** `ForestBloc(getUpgradeOptionsUseCase:, buyUpgradeUseCase:)` (`forest_bloc_test.dart`, `forest_page_test.dart` si construye el bloc); `HudData(upgradeItems:)` (`hud_data_mock.dart`, `forest_data_mock.dart`); `HudOverlay(onUpgradeSelected:)` (`hud_overlay_test.dart`, la medida del *scratchpad*); `di_test.dart` con `BuyUpgradeUseCase` y `GetUpgradeOptionsUseCase`.
- **Dominio:**
  - `inventory_rules_test.dart`: `toolLevel` 1 sin entrada; `withToolLevel` no toca recursos ni herramientas y lanza por debajo de 1; `hitsNeeded` con nivel 1 devuelve lo mismo y con nivel 2 la tabla 1→1, 2→2, 3→2, 4→3, 5→3, 6→4, 7→5, 8→5, 9→6; `add`, `adding`, `unloading`, `spend` y `addTool` conservan `toolLevels`; `inventory_entity_test.dart` (`==` con `toolLevels`);
  - `world_woodcutting_test.dart` / `world_mining_test.dart`: con nivel 1, los mismos golpes y eventos que antes; pino 3 → 2 y roble 7 → 5 (`TreeHitEventEntity.hitsRemaining` 4…0), roca 8 → 5; un árbol con 3 golpes recibidos cae en el siguiente al mejorar; el intervalo sigue en 750 (525 junto a una cantera);
  - `upgrades_test.dart` (costes, niveles, `of`, `reached`), `upgrade_entity_test.dart` / `upgrade_option_entity_test.dart` (`==`, `canBuy`); `blueprints_test.dart` (taller cuarto, 20 de madera y 10 de piedra, 10 golpes, radio 40, `accepts` vacío); `get_build_options_use_case_test.dart` (taller cuarto);
  - `buy_upgrade_use_case_test.dart`: `alreadyOwned` antes que `noWorkshop`, `noWorkshop` antes que `notEnoughResources` (también con el taller a medio hacer), `notEnoughResources` sin cobrar, `ok` cobra del almacén (no de la carga) y sube el nivel; mejorar sin tener el pico;
  - `get_upgrade_options_use_case_test.dart`: orden del catálogo, `needsBuilding`, `unaffordable` con lo que falta, `available`, `owned` sin `missing`;
  - `quests_test.dart` / `quest_log_test.dart`: 15 → 19 misiones, aldea 7 → 11, las cuatro nuevas al final de la aldea y medidas como en la decisión 14 (`gatherTwentyStone` pegajosa);
  - `balance_test.dart` sin cambios.
- **Presentación:** `forest_bloc_test.dart`: `ForestUpgradeRequested` avisa con el texto de cada `UpgradeResult` y publica `UpgradePurchasedEffect` solo con `ok`; `HudData.upgradeItems` con nombre, efecto ("Talas con un 40 % menos de golpes"), coste / "Comprada" y motivo por estado; la herramienta "Hacha de hierro" en `HudData.tools` con nivel 2; insignia `x/19`; aviso de la aldea completa con la undécima. `upgrade_menu_test.dart` (título, una fila por mejora, `onBuy` con el id) / `upgrade_option_tile_test.dart` (*Comprar* desactivado sin `canBuy`, motivo, `buyKey`). `hud_overlay_test.dart`: el botón *Taller* tercero abre y cierra el panel, comprar no lo cierra, *Arena* lo cierra; `buttonsBelowWidth` 1700 (tests de 1699 / 1700) y `narrowWidth` 1100. `forest_scene_component_test.dart` si mira las chispas (`UpgradePurchasedEffect`). `lpc_atlas_test.dart` (`workshop`), `sprite_names_test.dart` / `render_constants_test.dart` si existen (`'workshop'`, 24), `custom_icons_test.dart` (`workshop`), `internationalize_test.dart` (`forest.blueprint.workshop`, `forest.hud.workshop`, el grupo `forest.upgrade`, los dos avisos y las cuatro misiones). `LpcAssetsMock` construye `workshop` (ya lo hace para todo `BlueprintId`).

## Para F2

- `InventoryEntity.toolLevels` del jugador (clave = `ToolKind.name`, nivel ≥ 1; al cargar, un nivel sin mejora en el catálogo se recorta al máximo de `Upgrades`), el taller como cualquier edificio (`blueprint` = `'workshop'`, con su progreso) y las misiones completadas nuevas. Nada más: las mejoras compradas se deducen de los niveles.
