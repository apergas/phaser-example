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

**`StatsEntity`:**
- Nueva entidad `StatsEntity(treesFelled: int, treesFelledByKind: Map<TreeKind, int>, buildingsCompleted: int, treesRegrown: int)` en `domain/entities/game/`.
- La actualiza `World` a partir de sus propios eventos y la expone con un *getter*.
- Las misiones que cuentan cosas acumuladas miden `StatsEntity`, no el inventario, porque el inventario se gasta.

**Misiones nuevas**, después de `buildHouse`, como valores nuevos de `QuestId` (core) y entradas de `Quests.all`. El orden y los objetivos finales se fijan en el plan.

| Misión | Qué pide |
|---|---|
| `fellTenTrees` | Tala 10 árboles. |
| `fellAnOak` | Tala un roble. |
| `gatherFortyWood` | Ten 40 de madera a la vez. |
| `buildTwoHouses` | Ten 2 casas terminadas. |
| `seeATreeRegrow` | Ve rebrotar un árbol (necesita F3). |

**Textos:** en `es.json` (`forest.quest.*`) y en el `switch` de `Internationalize.forestQuestTitle`. El test `internationalize_test.dart` que lista los títulos se amplía.

**HUD:**
- Con 8 misiones, la lista muestra las completadas recogidas, la actual y 2 pendientes como máximo.
- `QuestItemData` ya trae `status`. El recorte lo hace `ForestBloc._hudData`, no `QuestPanel`, para que la vista no tenga lógica. La insignia (`questBadge`) sigue contando todas.

**Persistencia:** `StatsEntity` se guarda.

## Ficheros previstos

- **Nuevo:** `lib/layers/domain/entities/game/stats_entity.dart`.
- **Se modifican:**
  - `lib/layers/domain/world/world.dart` (y `world_state.dart` si hace falta)
  - `lib/layers/domain/quests/quests.dart`
  - `lib/core/config/constants/enum/quest_id.dart`
  - `lib/core/assets/i18n/internationalize.dart` y `es.json`
  - `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
- **Tests:** `quest_log_test.dart`, `forest_bloc_test.dart`, `internationalize_test.dart`, `quest_panel_test.dart` (comprobar que la lista recortada se ve bien).

## Cómo probarlo

- Jugar la cadena entera: la insignia pasa de 3/8 a 8/8 y la lista muestra la misión actual.
- Gastar madera no deshace las misiones ya completadas.
- Si F2 ya está fusionada, el progreso se conserva al volver a abrir el juego.
