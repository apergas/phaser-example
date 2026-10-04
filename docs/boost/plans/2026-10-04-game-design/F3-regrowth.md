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
- El tocón pasa a ser **estado del dominio**: `Stump(id, kind: TreeKind, position, elapsedMs)` en `domain/entities/tree/`.
- Hoy cada app crea sus tocones al recibir `TreeFelled`. Dejan de hacerlo y los dibujan desde `WorldSnapshot.stumps`.
- Fases, con las duraciones en `Rules`:
  1. Tocón.
  2. Brote, a los `SPROUT_AFTER_MS` (≈ 60 s). No bloquea el paso.
  3. Árbol, a los `REGROW_AFTER_MS` (≈ 180 s). Conserva `kind` y posición.
- Si cuando toca crecer el jugador o un edificio ocupa el sitio, se espera.
- Construir encima de un tocón o de un brote lo elimina, igual que ya se limpia la decoración.

**Eventos:**
- `GameEvent.TreeSprouted(stumpId)` y `GameEvent.TreeRegrown(tree)`.
- Cada uno tiene su `ForestEffect`, para animar la aparición con una escala que crece.

**Arte:**
- Brote: buscar en `terrain_atlas.png` una planta pequeña (hay matas y brotes).
- Si no hay nada adecuado, se usa el frame del árbol escalado al 35 %.
- Se añaden `SpriteNames.sapling()` y `SpriteNames.stump()`.

**Depuración:** para probar se pueden acortar las duraciones desde `Rules`, siempre como constantes y sin meter lógica de depuración en producción.

**Persistencia:** los tocones y los brotes se guardan (ver la regla de persistencia en el README).

## Ficheros previstos

**`shared`:**
- `shared/.../domain/entities/tree/Stump.kt` (nuevo)
- `World.kt`, `WorldState.kt`, `Rules.kt` y un sistema `internal` nuevo, `Regrowth.kt`
- `WorldSnapshot.kt`, `GameEvent.kt`, `ForestContract.kt`, `ForestViewModel.kt` y `SpriteNames.kt`

**Arte:** `asset-packs/lpc/build_assets.py` (frame `sapling`).

**Apps:**
- Web: `TreeView.ts` y `ForestScene.ts`.
- Android: `WorldSceneState.kt` y `WorldCanvas.kt`.
- iOS: `ForestScene.swift`.

## Cómo probarlo

Con las duraciones acortadas:
- Talar un árbol deja un tocón, que brota y luego crece.
- El árbol nuevo se puede volver a talar.
- Se puede caminar por encima del brote.
- Construir encima del tocón lo borra.

Tests en `WorldRegrowthTests`: tiempos, sitio ocupado y que construir borra el tocón.
