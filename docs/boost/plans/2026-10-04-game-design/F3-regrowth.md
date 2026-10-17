# F3 · Rebrote de árboles — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 1) |
| **Rama** | `feature/PROJECT-F3-regrowth`, desde `feature/PROJECT-X-town` (develop con la arena C0–C13, "empezar con el hacha" y F1) |
| **Depende de** | F1 |
| **Issue / milestone** | `phase:F3` · milestone `F3 Regrowth` |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-village/F3-regrowth.md`, merge `80de0c2` (`[PROJECT-F3]: Merge the regrowth`), commits `bcee57f` (dominio), `42c594a` (frame), `1e0ced3` (escena) |

**Goal:** Que el bosque deje de agotarse: un tocón brota y, con el tiempo, vuelve a ser el mismo árbol.

**Architecture:** Dominio: el tocón pasa a ser estado (`StumpEntity` en `WorldState.stumps`, expuesto en `WorldSnapshotEntity.stumps`); un sistema interno `Regrowth`, lo primero de `World.advance`, lo hace crecer y lo convierte en árbol cuando el sitio está libre, con los eventos `TreeSproutedEventEntity` / `TreeRegrownEventEntity`; `Woodcutting` deja el tocón y `Construction.place` borra los que quedan bajo el edificio. Arte: frame `sapling` en `forest.png`. Presentación: `ForestBloc` traduce los eventos a dos efectos sin *snackbar*; la escena reconcilia tocones y brotes por id con `StumpComponent` y los hace crecer con `GrowthMotion`, igual que al árbol que vuelve.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario, 2026-10-17):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Mientras `test/` no compila no se usa `flutter analyze` a secas.
- No cambia la inyección de dependencias (ningún constructor de caso de uso cambia): no se tocan `di.config.dart` ni `*.mocks.dart`.
- Sin textos nuevos (sin *snackbar* en el rebrote).
- Sin comentarios en `lib/`; imports relativos; `switch` exhaustivos en el orden de declaración; títulos de commit `[PROJECT-F3]: <frase en inglés en imperativo>`.

## Decisiones

Las de la ficha (comprobadas en iOS) más las que salen de Flutter:

1. **Tocón en el dominio:** `StumpEntity(id, kind: TreeKind, position, elapsedMs = 0)` en `domain/entities/tree/stump_entity.dart`, con `assert(elapsedMs >= 0)`, `copyWith`, `==`/`hashCode`. Se guarda en `WorldState.stumps` (`Map<String, StumpEntity>`, que en Dart conserva el orden de inserción) y sale en `World.stumps` y `WorldSnapshotEntity.stumps` (obligatorio, como el resto de campos).
   - **Desviación:** en iOS `isSapling` es una propiedad de `Stump`. Aquí las entidades no leen `Rules` (ninguna lo hace), así que `isSapling`, `isReadyToRegrow` y `grown(deltaMs)` van en la extensión `StumpRules` (`domain/world/extensions/stump_rules.dart`, E2). La escena la importa como ya importa `HeroRules`.
2. **Tiempos** (`Rules`, `double`, contados desde la tala): `sproutAfterMs = 60000` (tocón → brote) y `regrowAfterMs = 180000` (brote → árbol). Para probar a mano se acortan ahí, sin commitearlo, nunca con lógica de depuración.
3. **Ids:** el tocón lleva el id del árbol talado y el árbol que vuelve, el del tocón (`tree-37` → tocón `tree-37` → árbol `tree-37`). No se usa `WorldState.nextId('tree')`: los ids del nivel los pone el repositorio por índice. El árbol que vuelve se da de alta otra vez en `WorldState.trees`, así que va **al final** y sale el último en la instantánea.
4. **Árbol que vuelve:** mismo tipo y sitio, `trunkRadius: Rules.treeTrunkRadius`, madera y golpes de `Rules.treeKindStats` (F1), `hitsTaken` 0. Si un tipo faltara en la tabla, el brote se queda esperando (sin `!`).
5. **Sistema `Regrowth`** (`domain/world/regrowth.dart`, `abstract final class Regrowth` con `static void advance(WorldState, double deltaMs, List<GameEventEntity>)`; pieza interna, se añade a `_worldInternals` de `test/architecture_test.dart` en T1). Es **lo primero** de `World.advance`, antes del trabajo, del paso del jugador y de recoger objetos: un tocón creado en el tick *t* termina ese tick con `elapsedMs = 0`. Recorre una copia de los valores (`toList()`), porque quitar del mapa mientras se itera lanza `ConcurrentModificationError`; reasignar una clave existente conserva su sitio.
6. **Sitio ocupado:** el árbol no aparece si su tronco bloquea al jugador con la regla de `Navigation` (`distancia < 12 + 8`) o si `WorldState.isBlocked(posición, 12)` (edificios y árboles). Mientras espera, `elapsedMs` se queda en `regrowAfterMs` (`grown` lo limita) y se reintenta cada tick, sin límite. El jugador que tala se queda a 22 (`Rules.workGap` + radios) y no bloquea.
7. **Construir borra el tocón:** `Construction.place` quita, tras dar de alta el edificio, cada tocón cuyo árbol futuro chocaría con él: `building.footprint.blocks(stump.position, Rules.treeTrunkRadius)` (distancia < 40 + 12 con los edificios de hoy).
8. Tocones y brotes **no bloquean** ni el paso (`obstacles()` no cambia) ni la colocación (`canPlace` no cambia).
9. **Eventos:** `TreeSproutedEventEntity(stumpId)` y `TreeRegrownEventEntity(tree)`, al final de `game_event_entity.dart`. `ForestBloc` los traduce a `TreeSproutedEffect(stumpId)` / `TreeRegrownEffect(treeId)` **sin snackbar**. En la tarea de dominio el `switch` del bloc los recibe con un `break` provisional, para que cada commit compile (como iOS).
10. **Escena:**
    - `_onTreeFelled` deja de añadir el tocón decorativo; `_clutter` queda solo para la decoración.
    - `StumpComponent` (tocón o brote) en `game/components/`, prioridad `RenderDepth.bySortY(y − 1)` (el árbol que cae se dibuja encima). No cambia de frame: si su tocón desaparece de la instantánea o pasa a brote, se quita y se crea otro.
    - Los efectos se reproducen antes de reconciliar, así que `TreeSproutedEffect`/`TreeRegrownEffect` solo apuntan el id (`_sprouting`/`_regrowing`) y la reconciliación hace crecer el componente que crea con ese id; los dos conjuntos se vacían al final de cada reconciliación.
    - **Crecimiento** (`render/growth_motion.dart`, junto a `TreeMotion`): escala de 0,35 a 1 en 600 ms con `Easing.backOut` (se pasa un 6 % y vuelve), dentro de `update(dt)` con el `dt` limitado de `ForestGame`. Flame escala desde el `anchor`, que `AtlasSpriteComponent` pone en el pivote del frame: crece desde la base del tronco. Lo usan `StumpComponent.grow()` y `TreeComponent.grow()`. Si un árbol cae mientras crece, gana caer (la rama de caída va primero y hace `return`).
    - La pausa de la arena pausa el rebrote sola: mientras otra ruta está encima, `ForestGame` no manda `ForestTicked`.
11. **Arte:** `sapling` = la celda (13, 25) de `terrain_atlas.png` (caja `(416, 800, 448, 832)`, el arbolito de tallo marrón del *LPC Tile Atlas*, de Daniel Eddeland, ya acreditado). Recortado queda en 18 × 30, con pivote en la base del tallo (`trunk_base`: `x 0.3889`, `y 0.9`). `SpriteNames.sapling`; una línea en `CREDITS.md`. Al regenerar, solo cambian `forest.png` y `forest.json`: el frame nuevo y cinco frames pequeños que cambian de sitio (mismo tamaño y pivote).
12. **Guardado:** en F2 (tocones en orden con `id`, `kind`, `position` y `elapsedMs`; el orden de árboles es el de `World.trees`).

Diferencias con iOS ya presentes en Flutter, que F3 no toca: el jugador empieza con el hacha (sin objeto ni misión del hacha) y hay 2 misiones de la aldea / 10 en total antes de F4.

## Reparto

| Tarea | Qué |
|---|---|
| TF3.1 | Tocón que brota y vuelve a ser árbol (dominio) |
| TF3.2 | Frame del brote en el atlas |
| TF3.3 | Tocones y brotes en la escena |
| TF3.4 | Cierre: T1, `PROGRESS.md`, README, `CLAUDE.md` |

---

### Task TF3.1: Tocón que brota y vuelve a ser árbol

**Files:**
- Create: `lib/layers/domain/entities/tree/stump_entity.dart`, `lib/layers/domain/world/extensions/stump_rules.dart`, `lib/layers/domain/world/regrowth.dart`
- Modify: `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/entities/game/game_event_entity.dart`, `lib/layers/domain/entities/game/world_snapshot_entity.dart`, `lib/layers/domain/world/world_state.dart`, `lib/layers/domain/world/world.dart`, `lib/layers/domain/world/woodcutting.dart`, `lib/layers/domain/world/construction.dart`, `lib/layers/domain/use-cases/game/get_world_snapshot_use_case.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart` (dos casos provisionales)

**Interfaces:**
- Consumes: `Rules.treeKindStats`, `Rules.treeTrunkRadius`, `ObstacleRules.blocks(position, radius)`, `WorldState.isBlocked(position, radius)`.
- Produces:
  - `StumpEntity({required String id, required TreeKind kind, required PositionEntity position, double elapsedMs = 0})`.
  - `extension StumpRules on StumpEntity { bool get isSapling; bool get isReadyToRegrow; StumpEntity grown(double deltaMs); }`.
  - `Rules.sproutAfterMs = 60000`, `Rules.regrowAfterMs = 180000`.
  - `TreeSproutedEventEntity({required String stumpId})`, `TreeRegrownEventEntity({required TreeEntity tree})`.
  - `WorldState.stumps: Map<String, StumpEntity>`, `World.stumps: List<StumpEntity>`, `WorldSnapshotEntity.stumps: List<StumpEntity>` (obligatorio).
  - `Regrowth.advance(WorldState state, double deltaMs, List<GameEventEntity> events)`.

- [ ] **Step 1: `stump_entity.dart`** (nuevo)

```dart
import '../../../../core/config/constants/enum/tree_kind.dart';
import '../geometry/position_entity.dart';

class StumpEntity {
  final String id;
  final TreeKind kind;
  final PositionEntity position;
  final double elapsedMs;

  const StumpEntity({required this.id, required this.kind, required this.position, this.elapsedMs = 0})
    : assert(elapsedMs >= 0);

  StumpEntity copyWith({String? id, TreeKind? kind, PositionEntity? position, double? elapsedMs}) {
    return StumpEntity(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      position: position ?? this.position,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StumpEntity &&
      other.id == id &&
      other.kind == kind &&
      other.position == position &&
      other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(id, kind, position, elapsedMs);
}
```

- [ ] **Step 2: `rules.dart`** — tras `treeTrunkRadius`:

```dart
  static const double sproutAfterMs = 60000;
  static const double regrowAfterMs = 180000;
```

- [ ] **Step 3: `stump_rules.dart`** (nuevo)

```dart
import 'dart:math';

import '../../entities/tree/stump_entity.dart';
import '../../rules/rules.dart';

extension StumpRules on StumpEntity {
  bool get isSapling => elapsedMs >= Rules.sproutAfterMs;

  bool get isReadyToRegrow => elapsedMs >= Rules.regrowAfterMs;

  StumpEntity grown(double deltaMs) => copyWith(elapsedMs: min(elapsedMs + deltaMs, Rules.regrowAfterMs));
}
```

- [ ] **Step 4: `game_event_entity.dart`** — import `../tree/tree_entity.dart` y, al final:

```dart
final class TreeSproutedEventEntity extends GameEventEntity {
  final String stumpId;

  const TreeSproutedEventEntity({required this.stumpId});

  @override
  bool operator ==(Object other) => other is TreeSproutedEventEntity && other.stumpId == stumpId;

  @override
  int get hashCode => Object.hash(TreeSproutedEventEntity, stumpId);
}

final class TreeRegrownEventEntity extends GameEventEntity {
  final TreeEntity tree;

  const TreeRegrownEventEntity({required this.tree});

  @override
  bool operator ==(Object other) => other is TreeRegrownEventEntity && other.tree == tree;

  @override
  int get hashCode => Object.hash(TreeRegrownEventEntity, tree);
}
```

- [ ] **Step 5: `world_snapshot_entity.dart`** — import `../tree/stump_entity.dart`; campo `final List<StumpEntity> stumps;` tras `buildings`, `required this.stumps` en el constructor, `const ListEquality<StumpEntity>().equals(other.stumps, stumps)` en `==` y `const ListEquality<StumpEntity>().hash(stumps)` en `hashCode`.

- [ ] **Step 6: `world_state.dart`** — import `../entities/tree/stump_entity.dart` y, tras `buildings`:

```dart
  final Map<String, StumpEntity> stumps = {};
```

- [ ] **Step 7: `regrowth.dart`** (nuevo)

```dart
import '../entities/game/game_event_entity.dart';
import '../entities/tree/stump_entity.dart';
import '../entities/tree/tree_entity.dart';
import '../rules/rules.dart';
import 'extensions/obstacle_rules.dart';
import 'extensions/stump_rules.dart';
import 'world_state.dart';

abstract final class Regrowth {
  static void advance(WorldState state, double deltaMs, List<GameEventEntity> events) {
    for (final stump in state.stumps.values.toList()) {
      final grown = stump.grown(deltaMs);
      if (!stump.isSapling && grown.isSapling) events.add(TreeSproutedEventEntity(stumpId: stump.id));
      final tree = grown.isReadyToRegrow ? _regrownTree(state, grown) : null;
      if (tree == null) {
        state.stumps[stump.id] = grown;
        continue;
      }
      state.stumps.remove(stump.id);
      state.trees[tree.id] = tree;
      events.add(TreeRegrownEventEntity(tree: tree));
    }
  }

  static TreeEntity? _regrownTree(WorldState state, StumpEntity stump) {
    final stats = Rules.treeKindStats[stump.kind];
    if (stats == null) return null;
    final tree = TreeEntity(
      id: stump.id,
      kind: stump.kind,
      position: stump.position,
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: stats.woodYield,
      hitsToFell: stats.hitsToFell,
    );
    final player = state.player;
    if (tree.footprint.blocks(player.position, player.radius) || state.isBlocked(tree.position, tree.trunkRadius)) {
      return null;
    }
    return tree;
  }
}
```

- [ ] **Step 8: `world.dart`** — imports `../entities/tree/stump_entity.dart` y `regrowth.dart`; getter tras `buildings`:

```dart
  List<StumpEntity> get stumps => _state.stumps.values.toList();
```

  y primera línea de `advance` tras crear `events`:

```dart
    Regrowth.advance(_state, deltaMs, events);
```

- [ ] **Step 9: `woodcutting.dart`** — import `../entities/tree/stump_entity.dart`; tras `state.trees.remove(tree.id);`:

```dart
    state.stumps[tree.id] = StumpEntity(id: tree.id, kind: tree.kind, position: tree.position);
```

- [ ] **Step 10: `construction.dart`** — import `extensions/obstacle_rules.dart`; tras `state.buildings[building.id] = building;`:

```dart
    state.stumps.removeWhere((_, stump) => building.footprint.blocks(stump.position, Rules.treeTrunkRadius));
```

- [ ] **Step 11: `get_world_snapshot_use_case.dart`** — `stumps: world.stumps,` tras `buildings`.

- [ ] **Step 12: `forest_bloc.dart`** (provisional, la tarea TF3.3 lo sustituye) — en `_react`, tras el caso `QuestCompletedEventEntity()`:

```dart
      case TreeSproutedEventEntity():
        break;
      case TreeRegrownEventEntity():
        break;
```

- [ ] **Step 13: Verificar**

```sh
dart format --line-length 120 lib/layers/domain/entities/tree/stump_entity.dart lib/layers/domain/world lib/layers/domain/rules/rules.dart lib/layers/domain/entities/game lib/layers/domain/use-cases/game/get_world_snapshot_use_case.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 14: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-F3]: Turn felled trees into stumps that regrow"`.

### Task TF3.2: Frame del brote en el atlas

**Files:**
- Modify: `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/forest.png` y `forest.json` (regenerados), `lib/core/assets/images/lpc/CREDITS.md`, `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`

**Interfaces:**
- Consumes: `trim`, `trunk_base` y `build_forest()` de `build_assets.py`.
- Produces: `SpriteNames.sapling = 'sapling'` y el frame `sapling` en `forest.json` (18 × 30, pivote `x 0.3889`, `y 0.9`).

- [ ] **Step 1: `build_assets.py`**
  - Docstring: `trees (pivot = trunk base), decor, stump,` → `trees and sapling (pivot = trunk base), decor, stump,`.
  - Tras `STUMP_BOX`:

```python
SAPLING_BOX = (416, 800, 448, 832)  # terrain_atlas.png, a young woody plant among the farm crops
```

  - Tras `pivots["stump"] = …`:

```python
    sapling = trim(terrain.crop(SAPLING_BOX), "sapling")
    frames["sapling"] = sapling
    base_x, base_y = trunk_base(sapling)
    pivots["sapling"] = {"x": round(base_x / sapling.width, 4), "y": round(base_y / sapling.height, 4)}
```

- [ ] **Step 2: Regenerar y comprobar**

```sh
cd asset-packs/lpc && python3 build_assets.py && cd ../..
git status --short
python3 -c "import json; f = json.load(open('lib/core/assets/images/lpc/forest.json'))['frames']; print(f['sapling']['frame']['w'], f['sapling']['frame']['h'], f['sapling']['pivot'], f['stump']['frame']['w'], f['stump']['frame']['h'])"
```
Esperado: solo ` M lib/core/assets/images/lpc/forest.json` y ` M …/forest.png`; `18 30 {'x': 0.3889, 'y': 0.9} 50 41`. Comparar los frames de antes y de después (`git show HEAD:…/forest.json`): solo el nuevo y unos pocos pequeños que cambian de `x`/`y`, con el mismo tamaño y pivote; mirar un recorte del `sapling` en el *scratchpad*.

- [ ] **Step 3: `CREDITS.md`** — tras la línea del tocón:

```markdown
The sapling (`sapling` frame) is a young plant from the farming crops of the LPC Tile Atlas above (Daniel Eddeland).
```

- [ ] **Step 4: `sprite_names.dart`** — tras `stump`:

```dart
  static const String sapling = 'sapling';
```

- [ ] **Step 5: Verificar** — `dart format --line-length 120 lib/layers/presentation/features/forest/game/atlas/sprite_names.dart` y `flutter analyze lib` → `No issues found!`.

- [ ] **Step 6: Commit** — `git add asset-packs lib` y, aparte, `git commit -m "[PROJECT-F3]: Add the sapling frame"`.

### Task TF3.3: Tocones y brotes en la escena

**Files:**
- Create: `lib/layers/presentation/features/forest/game/render/growth_motion.dart`, `lib/layers/presentation/features/forest/game/components/stump_component.dart`
- Modify: `lib/layers/presentation/features/forest/models/forest_effect.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/game/components/tree_component.dart`, `lib/layers/presentation/features/forest/game/forest_scene_component.dart`

**Interfaces:**
- Consumes: `WorldSnapshotEntity.stumps`, `StumpRules.isSapling`, `SpriteNames.sapling`/`stump`, `Easing.backOut`, los eventos de TF3.1.
- Produces:
  - `TreeSproutedEffect({required String stumpId})`, `TreeRegrownEffect({required String treeId})` (al final de `forest_effect.dart`).
  - `GrowthMotion.growMs = 600`, `GrowthMotion.startScale = 0.35`, `GrowthMotion.scale(double elapsedMs)`, `GrowthMotion.hasGrown(double elapsedMs)`.
  - `StumpComponent({required LpcAssets assets, required StumpEntity stump})` con `stumpId`, `isSapling` y `grow()`; `TreeComponent.grow()`; `ForestSceneComponent.stumps: Map<String, StumpComponent>`.

- [ ] **Step 1: `forest_effect.dart`** — al final:

```dart
final class TreeSproutedEffect extends ForestEffect {
  final String stumpId;

  const TreeSproutedEffect({required this.stumpId});

  @override
  bool operator ==(Object other) => identical(this, other) || other is TreeSproutedEffect && other.stumpId == stumpId;

  @override
  int get hashCode => Object.hash(TreeSproutedEffect, stumpId);
}

final class TreeRegrownEffect extends ForestEffect {
  final String treeId;

  const TreeRegrownEffect({required this.treeId});

  @override
  bool operator ==(Object other) => identical(this, other) || other is TreeRegrownEffect && other.treeId == treeId;

  @override
  int get hashCode => Object.hash(TreeRegrownEffect, treeId);
}
```

- [ ] **Step 2: `forest_bloc.dart`** — los dos casos provisionales de TF3.1 pasan a:

```dart
      case TreeSproutedEventEntity(:final stumpId):
        effects.add(TreeSproutedEffect(stumpId: stumpId));
      case TreeRegrownEventEntity(:final tree):
        effects.add(TreeRegrownEffect(treeId: tree.id));
```

- [ ] **Step 3: `growth_motion.dart`** (nuevo)

```dart
import 'easing.dart';

abstract final class GrowthMotion {
  static const double growMs = 600;
  static const double startScale = 0.35;

  static double scale(double elapsedMs) =>
      startScale + (1 - startScale) * Easing.backOut((elapsedMs / growMs).clamp(0, 1).toDouble());

  static bool hasGrown(double elapsedMs) => elapsedMs >= growMs;
}
```

- [ ] **Step 4: `stump_component.dart`** (nuevo)

```dart
import '../../../../../domain/entities/tree/stump_entity.dart';
import '../../../../../domain/world/extensions/stump_rules.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/growth_motion.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';

class StumpComponent extends AtlasSpriteComponent {
  final String stumpId;
  final bool isSapling;
  double? _growElapsedMs;

  StumpComponent({required LpcAssets assets, required StumpEntity stump})
    : stumpId = stump.id,
      isSapling = stump.isSapling,
      super.fromFrame(
        frame: assets.frame(_frameName(stump)),
        sprite: assets.sprite(_frameName(stump)),
        position: stump.position.toVector2(),
        priority: RenderDepth.bySortY(stump.position.y - 1),
      );

  static String _frameName(StumpEntity stump) => stump.isSapling ? SpriteNames.sapling : SpriteNames.stump;

  void grow() {
    _growElapsedMs = 0;
    scale.setAll(GrowthMotion.startScale);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final growElapsed = _growElapsedMs;
    if (growElapsed == null) return;
    final total = growElapsed + dt * 1000;
    scale.setAll(GrowthMotion.scale(total));
    _growElapsedMs = GrowthMotion.hasGrown(total) ? null : total;
  }
}
```

- [ ] **Step 5: `tree_component.dart`** — import `../render/growth_motion.dart`; campo `double? _growElapsedMs;` tras `_fallElapsedMs`; método tras `fell`:

```dart
  void grow() {
    _growElapsedMs = 0;
    scale.setAll(GrowthMotion.startScale);
  }
```

  y en `update`, tras el bloque de la caída (que hace `return`) y antes de leer `_hitElapsedMs`:

```dart
    final growElapsed = _growElapsedMs;
    if (growElapsed != null) {
      final total = growElapsed + elapsedMs;
      scale.setAll(GrowthMotion.scale(total));
      _growElapsedMs = GrowthMotion.hasGrown(total) ? null : total;
    }
```

- [ ] **Step 6: `forest_scene_component.dart`**
  - Import `components/stump_component.dart` y `../../../../domain/world/extensions/stump_rules.dart`.
  - Campos tras `_buildings`: `final Map<String, StumpComponent> _stumps = {};`, `final Set<String> _sprouting = {};`, `final Set<String> _regrowing = {};`; getter `Map<String, StumpComponent> get stumps => Map.unmodifiable(_stumps);` tras `buildings`.
  - `_play`, al final del `switch`:

```dart
      case TreeSproutedEffect(:final stumpId):
        _sprouting.add(stumpId);
      case TreeRegrownEffect(:final treeId):
        _regrowing.add(treeId);
```

  - `_onTreeFelled`: quitar `_addClutter(SpriteNames.stump, tree.base, tree.base.y - 1);`.
  - `_reconcile`: el alta de árboles pasa a

```dart
    for (final tree in world.trees) {
      _trees.putIfAbsent(tree.id, () {
        final component = TreeComponent(assets: _assets, tree: tree);
        if (_regrowing.contains(tree.id)) component.grow();
        return _added(component);
      });
    }

    final saplings = {for (final stump in world.stumps) stump.id: stump.isSapling};
    final staleStumps = [
      for (final MapEntry(key: id, value: component) in _stumps.entries)
        if (saplings[id] != component.isSapling) id,
    ];
    for (final id in staleStumps) {
      _stumps.remove(id)!.removeFromParent();
    }
    for (final stump in world.stumps) {
      _stumps.putIfAbsent(stump.id, () {
        final component = StumpComponent(assets: _assets, stump: stump);
        if (_sprouting.contains(stump.id)) component.grow();
        return _added(component);
      });
    }
    _sprouting.clear();
    _regrowing.clear();
```

- [ ] **Step 7: Verificar**

```sh
dart format --line-length 120 lib/layers/presentation/features/forest/models/forest_effect.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart lib/layers/presentation/features/forest/game/render/growth_motion.dart lib/layers/presentation/features/forest/game/components/stump_component.dart lib/layers/presentation/features/forest/game/components/tree_component.dart lib/layers/presentation/features/forest/game/forest_scene_component.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 8: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-F3]: Show stumps and saplings that grow back into trees"`.

### Task TF3.4: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-04-game-design/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **F3** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F3 → `✅`, `feature/PROJECT-F3-regrowth`, nota "Sin tests (T1)"; `README.md`: icono de F3 → ✅.
- [ ] **Step 3:** `CLAUDE.md`: `StumpEntity`, `WorldState.stumps`/`World.stumps`/`WorldSnapshotEntity.stumps`, `Regrowth` (primero en `advance`, sitio ocupado), `StumpRules`, los tiempos de `Rules`, los eventos y efectos nuevos (sin *snackbar*), `Construction.place` borra tocones, `StumpComponent` y `GrowthMotion`, el tocón ya no es decoración, el frame `sapling`. Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); `git commit -m "[PROJECT-F3]: Close the regrowth phase"` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque de la aldea, en Chrome y Android, con las duraciones acortadas en `Rules` (sin commitearlas):

1. Talar deja un tocón; a los `sproutAfterMs` es un arbolito que crece con un pequeño rebote; a los `regrowAfterMs` vuelve el mismo árbol, en su sitio, creciendo desde la base del tronco, y se puede volver a talar con sus golpes y su madera.
2. Se camina por encima del tocón y del brote. De pie sobre el tocón, el árbol espera y aparece en cuanto el jugador se aparta.
3. Construir encima borra el tocón (y no impide colocar).
4. Con la arena abierta nada brota ni rebrota hasta volver.
5. Sin *snackbar* al brotar ni al rebrotar.

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F3 (no se ha tocado `test/`; los goldens de iOS valen tal cual: mismo dominio). Datos en `test/mocks/**` (p. ej. `StumpEntityMock` en `test/mocks/domain/entities/tree/stump_entity_mock.dart`: `fresh`, `almostSapling` (59 999), `sapling` (60 000), `ready` (180 000)), nunca en línea:

- **No compilan:** `WorldSnapshotEntity` sin `stumps` en `test/mocks/domain/entities/game/world_snapshot_entity_mock.dart` y `test/mocks/presentation/features/forest/game/forest_data_mock.dart` (`stumps: const []` o tocones de mock).
- `test/architecture_test.dart`: añadir `lib/layers/domain/world/regrowth.dart` a `_worldInternals`.
- `stump_entity_test.dart`: `copyWith`, `==`, `hashCode`, `assert(elapsedMs >= 0)`. `stump_rules_test.dart`: `isSapling` falso en 59 999 y cierto en 60 000; `grown` suma y se queda en 180 000 (`ready` + 5000 → 180 000); `isReadyToRegrow` desde 180 000.
- `world_regrowth_test.dart`, con ticks de 50 ms:
  - el pino `tree-37` talado en t = 5500 brota en 65 500 y vuelve en 185 500;
  - el tocón del tick de la tala acaba ese tick con `elapsedMs` 0; talar deja `StumpEntity(id: tree.id, kind: tree.kind, position: tree.position)`;
  - `TreeSproutedEventEntity` sale una sola vez, en el tick que cruza 60 000; un `advance` que cruce los dos umbrales da los dos eventos en ese orden; los eventos del rebrote van antes que los del trabajo del jugador;
  - el árbol que vuelve tiene id, tipo y sitio del tocón, madera y golpes de `Rules.treeKindStats`, `hitsTaken` 0, y sale el último en `World.trees` y en la instantánea;
  - con el jugador a menos de 20 del centro no rebrota y `elapsedMs` se queda en 180 000; a 22 (sitio de talar), sí;
  - una casa a menos de 52 borra el tocón; a más de 52 se queda;
  - los tocones nunca bloquean ni el camino (`obstacles()` sin tocones) ni `canPlace`.
- `get_world_snapshot_use_case_test.dart`: `stumps` refleja `World.stumps` en orden; `world_snapshot_entity_test.dart`: `stumps` en `==`/`hashCode`.
- `game_event_entity_test.dart` / `forest_effect_test.dart` (si existen): los dos eventos y efectos nuevos.
- `forest_bloc_test.dart`: `TreeSproutedEventEntity` → `TreeSproutedEffect(stumpId)` y `TreeRegrownEventEntity` → `TreeRegrownEffect(treeId: tree.id)`, sin *snackbar*.
- `growth_motion_test.dart`: `scale(0) = 0.35`, `scale(600) = 1`, pico > 1 antes de 600, `hasGrown(600)`.
- `stump_component_test.dart` (`testWithFlameGame`): tamaño 50 × 41 del tocón y 18 × 30 del brote, prioridad `bySortY(y − 1)`, y el crecimiento de 0,35 a 1 en 600 ms. `tree_component_test.dart`: `grow()` y caer a la vez (gana caer).
- `forest_scene_component_test.dart`: reconcilia tocones y brotes por id (un tocón que pasa a brote se sustituye; uno que desaparece se quita); con `TreeSproutedEffect`/`TreeRegrownEffect` el componente nuevo empieza en escala 0,35; la tala ya no añade nada a `clutter`.
- `lpc_atlas_test.dart`: el frame `sapling` existe; `LpcAssetsMock` debe tener un frame `sapling` si algún test pinta un brote.

## Para F2 y F4

- **F2 (guardado):** guardar `WorldState.stumps` en su orden, con `id`, `kind`, `position` y `elapsedMs`, y darlos de alta en ese orden al cargar. Un árbol que rebrotó lleva el id de su tocón y va al final de `trees`: el orden guardado de árboles es el de `World.trees`, no el del nivel. Al cargar, la escena crea los `StumpComponent` sin crecer (no hay efecto).
- **F4:** si una misión cuenta árboles talados o pide ver rebrotar uno, los eventos son `TreeFelledEventEntity` y `TreeRegrownEventEntity`; el número de árboles del mapa ya no baja siempre.
