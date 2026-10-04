# F4 · Misiones, capítulo 1 — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | A |
| **Depende de** | F3 |
| **Issue / milestone** | `phase:F4` · milestone `F4 Quests chapter 1` |

## Objetivo

Que haya metas después de la primera casa, usando sólo mecánicas que ya existen.

## Decisiones ya tomadas

**`Stats`:**
- Nueva entidad `Stats(treesFelled: Int, treesFelledByKind: Map<TreeKind, Int>, buildingsCompleted: Int)` en `domain/entities/game/`.
- La actualiza `World` a partir de sus propios eventos.
- Las misiones que cuentan cosas acumuladas miden `Stats`, no el inventario, porque el inventario se gasta.

**Misiones nuevas**, después de `BuildHouse`. El orden y los objetivos finales se fijan en el plan.

| Misión | Qué pide |
|---|---|
| `FellTenTrees` | Tala 10 árboles. |
| `FellAnOak` | Tala un roble. |
| `GatherFortyWood` | Ten 40 de madera a la vez. |
| `BuildTwoHouses` | Ten 2 casas terminadas. |
| `SeeATreeRegrow` | Ve rebrotar un árbol (necesita F3). |

**Textos:** en `ForestLabels.questTitle`.

**HUD:**
- Con 8 misiones, la lista muestra las completadas recogidas, la actual y 2 pendientes como máximo.
- `HudState.quests` ya trae `status`. El recorte lo hace el view model, para que las tres apps no repitan la lógica.

**Persistencia:** `Stats` se guarda.

## Ficheros previstos

- **Nuevo:** `shared/.../domain/entities/game/Stats.kt`.
- **Se modifican:**
  - `World.kt`
  - `quests/Quest.kt`
  - `quests/QuestId.kt`
  - `ForestLabels.kt`
  - `ForestViewModel.kt`
- **Tests:** `QuestLogTests` y `ForestViewModelTests`.
- **Apps:** no deberían cambiar. Sólo hay que comprobar que la lista se ve bien.

## Cómo probarlo

- Jugar la cadena entera: la insignia pasa de 3/8 a 8/8 y la lista muestra la misión actual.
- Gastar madera no deshace las misiones ya completadas.
- Si F2 ya está fusionada, el progreso se conserva al volver a abrir el juego.
