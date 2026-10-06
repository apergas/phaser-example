# C7 · Misiones del héroe y equilibrado — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha.

| | |
|---|---|
| **Flujo** | D (héroe) |
| **Depende de** | C1, C3, C5. Si C4 o C6 llegan después, el test de equilibrado de esta fase los cubre automáticamente: recorre `ArenaLevels.all`. |
| **Issue / milestone** | `phase:C7` · `stream:D` · milestone `C7 Hero quests and balance` |

## Objetivo

Guiar al jugador por el modo nuevo con misiones propias y dejar los números (equipo, niveles, oro) equilibrados y protegidos por un test.

## Decisiones ya tomadas

**Líneas de misiones:**
- Enum de core `QuestLine { village, hero }`. `Quest` gana `QuestLine get line`, y las misiones existentes son `village`.
- `QuestLog` sigue siendo uno, pero el orden y "la actual" se calculan **por línea**.
- `QuestPanel` muestra dos secciones (*Aldea*, *Héroe*). Si F4 ya está, su recorte (completadas recogidas, actual y 2 pendientes) se aplica a cada sección.
- `QuestItemData` gana `line`.

**Misiones del héroe** (`QuestId` nuevos al final; entradas al final de `Quests.all`; todas miden el `World`):

| Misión | Qué pide |
|---|---|
| `buildForge` | Construye la Herrería. |
| `winFirstFight` | Gana un nivel de la arena (`hero.clearedLevels.isNotEmpty`). |
| `buyFirstWeapon` | Equipa la Espada corta (`hero.weaponTier >= 1`). |
| `buildArmory` | Construye la Armería. |
| `buildMageTower` | Construye la Torre de magia. |
| `learnASkill` | Aprende una habilidad. |
| `clearHalfArena` | Gana la mitad de los niveles de `ArenaLevels.all`. |
| `becomeChampion` | Gana `barbarianChief`. |

**Equilibrado:**
- `test/layers/domain/combat/balance_test.dart` simula cada nivel de `ArenaLevels.all` con 100 semillas para una tabla de "héroe esperado en ese punto" (`BalanceScenarioMock` en `test/mocks/`). Comprueba:
  - con el equipo esperado, se gana entre el **60 % y el 95 %** de las veces;
  - con el equipo del escalón anterior, menos del 50 %;
  - con el oro de la primera victoria de los niveles anteriores, más como mucho **3 repeticiones**, se puede pagar la siguiente mejora esperada.
- Los números de `Gear.all`, `Skills.all`, `ArenaLevels.all` y los costes de los edificios se ajustan hasta que el test pase. La tabla final se copia en `docs/GAME_DESIGN.md` (sección 3.8) y sustituye a la orientativa.
- Si C4 o C6 cambian los niveles después, deben mantener este test en verde.

**Persistencia:** las misiones completadas ya se guardan (F2); las nuevas no añaden estado.

## Ficheros previstos

- **Dominio:** `quests/quest.dart`, `quests/quests.dart`, `quests/quest_log.dart`; enums de core `quest_id.dart`, `quest_line.dart` (nuevo); y, si hace falta ajustar números, `rules/gear.dart`, `rules/skills.dart`, `rules/arena_levels.dart` y `rules/blueprints.dart`.
- **Presentación:** `features/forest/bloc/forest_bloc.dart` (`_hudData` por línea), `models/quest_item_data.dart`, `widgets/quest_panel.dart`.
- **Core:** `Internationalize` (`forestQuestTitle` y el nombre de cada línea), `es.json`.
- **Tests:** `balance_test.dart` (nuevo), `quest_log_test.dart`, `quest_panel_test.dart`, `internationalize_test.dart`, `forest_bloc_test.dart`.
- **Documentación:** `docs/GAME_DESIGN.md` (tabla final).

## Cómo probarlo

- Partida nueva: el panel de misiones muestra *Aldea* (talar, construir…) y *Héroe* (construir la Herrería).
- Jugar la cadena del héroe hasta *Campeón*.
- El test de equilibrado pasa y la tabla de `GAME_DESIGN.md` coincide con los números del código.
