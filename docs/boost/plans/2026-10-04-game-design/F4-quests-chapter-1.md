# F4 · Misiones, capítulo 1 — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-village/F4-quests-chapter-1.md`); esta ficha manda sobre la versión anterior.

| | |
|---|---|
| **Rama** | `feature/PROJECT-F4-quests-chapter-1`, desde `feature/PROJECT-X-town` |
| **Depende de** | F3 |
| **Issue / milestone** | `phase:F4` · milestone `F4 Quests chapter 1` |
| **Referencia iOS** | merge `3e60655` (`[PROJECT-F4]: Merge the first quest chapter`), commits `19f276d` (estadísticas), `ba4b176` (misiones), `a38f26b` (panel plegado) |

## Objetivo

Que haya metas después de la primera casa, usando solo mecánicas que ya existen.

## Decisiones ya tomadas

**Estadísticas del mundo:**
- `StatsEntity(treesFelled, treesFelledByKind: Map<TreeKind, int>, buildingsCompleted, treesRegrown)` en `domain/entities/game/`, guardada en `WorldState` y expuesta por `World.stats`.
- La actualiza un sistema interno `StatsRecording` (`domain/world/stats_recording.dart`, se añade a `architecture_test.dart`) **al final** de `World.advance`, después de recoger objetos, con todos los eventos del tick en orden.
- Como `QuestLog.update` va después del mundo, la misión que mide `stats` se cumple en el mismo tick que el evento.
- **Tipo del árbol talado sin tocar el evento:** `TreeFelledEventEntity` no lleva el tipo; `StatsRecording` lo saca del tocón de F3 (`state.stumps[treeId]?.kind`), que siempre está al final del tick. Si faltara, cuenta en `treesFelled` pero no por tipo.
- `buildingsCompleted` se guarda aunque todavía no lo use ninguna misión (capítulos siguientes y F2).

**Misiones nuevas** (`QuestLine.village`):
- En `Quests.all`, justo después de `buildHouse` y antes de `buildForge`.
- En `QuestId`, al final del enum (después de `becomeChampion`), en este orden:

| Misión | Objetivo | Texto | Mide |
|---|---|---|---|
| `fellTenTrees` | 10 | Tala 10 árboles | `stats.treesFelled` |
| `fellAnOak` | 1 | Tala un roble | `stats.treesFelledByKind[oak]` |
| `gatherFortyWood` | 40 | Ten 40 de madera a la vez | `world.funds` (madera): el inventario hasta F6 y el almacén desde F6, sin tocar la misión |
| `buildTwoHouses` | 2 | Ten 2 casas terminadas | casas terminadas que hay (`BuildingListRules.completeCount(house)`, nuevo) |
| `seeATreeRegrow` | 1 | Ve rebrotar un árbol | `stats.treesRegrown` |

- La línea de la aldea pasa a 8 misiones y el total a 16. Se pueden cumplir fuera de orden; `QuestLog` sigue siendo pegajoso, así que gastar madera no deshace `gatherFortyWood`.

**Panel de misiones** (el recorte lo hace `ForestBloc._hudData`; la vista no tiene lógica). Por línea, en el orden de `QuestLine.values`:
- si hay hechas, **una** fila plegada (`QuestItemStatus.folded`, al final del enum) con la casilla marcada y el título apagado, sin tachar y sin progreso: "1 hecha" / "3 hechas";
- después la actual;
- después como mucho `HudData.pendingQuestsShown = 2` pendientes, en el orden del catálogo.
- Con la línea entera hecha solo queda "8 hechas". El estado `done` se mantiene en el modelo, aunque el HUD ya no lo enseña.
- La insignia sigue contando todas (`0/16` al empezar).

**Textos:**
- Las cinco misiones.
- `forest.hud.questsDone` con plural de `easy_localization` (`one`: "{count} hecha", `other`: "{count} hechas", con `plural()`).
- El aviso de línea completa ("¡Has completado las misiones de Aldea!") llega ahora con la octava misión de la aldea.

**Guardado:** en F2 (estadísticas y misiones completadas).

## Ficheros previstos

- **Dominio:** `entities/game/stats_entity.dart` (nuevo), `world/world.dart`, `world_state.dart`, `stats_recording.dart` (nuevo), `world/extensions/building_rules.dart` (`BuildingListRules`), `quests/quests.dart`.
- **Core:** `quest_id.dart`, `forest/quest_item_status.dart`, `internationalize.dart`, `es.json`.
- **Presentación:** `bloc/forest_bloc.dart` (recorte), `models/quest_item_data.dart`, `models/hud_data.dart`, `widgets/quest_row.dart` (fila plegada).
- **Tests:** `architecture_test.dart` y mocks de `StatsEntity`.

## Cómo probarlo

- Jugar la cadena: la insignia pasa de 0/16 y el panel enseña "N hechas", la actual y dos pendientes; la octava misión de la aldea anuncia la línea completa.
- Gastar madera no deshace *Ten 40 de madera a la vez*.
- Tests:
  - `stats_recording_test.dart`: talados, por tipo, edificios terminados y rebrotados; en el mismo tick que el evento;
  - `quest_log_test.dart` / `quests_test.dart`: las cinco misiones, su orden y fuera de orden;
  - `forest_bloc_test.dart`: recorte por línea (plegada, actual, dos pendientes), insignia `x/16`;
  - `quest_row_test.dart`: fila plegada;
  - `internationalize_test.dart`: títulos y plural.
