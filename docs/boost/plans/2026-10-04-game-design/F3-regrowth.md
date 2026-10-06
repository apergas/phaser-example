# F3 · Rebrote de árboles — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F1 |
| **Issue / milestone** | `phase:F3` · milestone `F3 Regrowth` |

## Objetivo

Que el bosque deje de agotarse: un tocón brota y, con el tiempo, vuelve a ser un árbol.

## Decisiones ya tomadas

**Dominio:**
- El tocón pasa a ser **estado del dominio**: `StumpEntity(id, kind: TreeKind, position, elapsedMs)` en `domain/entities/tree/`.
- Hoy el tocón sólo existe en la vista: `ForestSceneComponent._onTreeFelled` añade un sprite `SpriteNames.stump` como decoración al recibir `TreeFelledEffect`, y `_clearClutterUnder` lo borra al construir encima. Deja de hacerlo: los tocones y brotes se dibujan desde `WorldSnapshotEntity.stumps` y se reconcilian por id, como los árboles.
- Fases, con las duraciones en `Rules`:
  1. Tocón.
  2. Brote, a los `Rules.sproutAfterMs` (≈ 60 s). No bloquea el paso.
  3. Árbol, a los `Rules.regrowAfterMs` (≈ 180 s). Conserva `kind` y posición, con la madera y los golpes de `Rules.treeKindStats` (F1).
- Si cuando toca crecer el jugador o un edificio ocupa el sitio, se espera.
- Construir encima de un tocón o de un brote lo elimina.
- Un sistema nuevo `Regrowth` en `domain/world/regrowth.dart`, interno como `Woodcutting`: se añade a la lista de piezas internas de `test/architecture_test.dart`.

**Eventos:**
- `TreeSproutedEventEntity(stumpId)` y `TreeRegrownEventEntity(tree)` en `game_event_entity.dart`.
- Cada uno tiene su `ForestEffect` (`TreeSproutedEffect`, `TreeRegrownEffect`), para animar la aparición con una escala que crece (`ScaleEffect` de Flame o la easing de `render/easing.dart`).

**Arte:**
- Brote: buscar en `terrain_atlas.png` una planta pequeña (hay matas y brotes).
- Si no hay nada adecuado, se usa el frame del árbol escalado al 35 %.
- `SpriteNames.stump` ya existe; se añade `SpriteNames.sapling`.

**Depuración:** para probar se pueden acortar las duraciones desde `Rules`, siempre como constantes y sin meter lógica de depuración en producción.

**Persistencia:** los tocones y los brotes se guardan (ver la regla de persistencia en el README).

## Ficheros previstos

**Dominio:**
- `lib/layers/domain/entities/tree/stump_entity.dart` (nuevo)
- `lib/layers/domain/world/world.dart`, `world_state.dart`, `regrowth.dart` (nuevo) y `extensions/` si hace falta una operación del tocón
- `lib/layers/domain/rules/rules.dart`
- `lib/layers/domain/entities/game/world_snapshot_entity.dart` y `game_event_entity.dart`
- `lib/layers/domain/use-cases/game/get_world_snapshot_use_case.dart`

**Presentación:**
- `models/forest_effect.dart`, `bloc/forest_bloc.dart`
- `game/atlas/sprite_names.dart`
- `game/forest_scene_component.dart` y un componente de tocón/brote en `game/components/`

**Arte:** `asset-packs/lpc/build_assets.py` (frame `sapling`).

**Tests:** `test/architecture_test.dart` (nueva pieza interna).

## Cómo probarlo

Con las duraciones acortadas:
- Talar un árbol deja un tocón, que brota y luego crece.
- El árbol nuevo se puede volver a talar.
- Se puede caminar por encima del brote.
- Construir encima del tocón lo borra.

Tests en `test/layers/domain/world/world_regrowth_test.dart`: tiempos, sitio ocupado y que construir borra el tocón. Componentes con `testWithFlameGame`.
