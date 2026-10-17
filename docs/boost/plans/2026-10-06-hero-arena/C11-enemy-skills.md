# C11 · Habilidades de los enemigos — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `boost:writing-plans` sobre esta ficha. **Ya está hecha en iOS** (`$IOS/docs/plans/2026-10-12-arena/C11-enemy-skills.md`, con las tablas de equilibrado completas).

| | |
|---|---|
| **Rama** | `feature/PROJECT-C11-enemy-skills`, desde `feature/PROJECT-X-arena` |
| **Depende de** | C10 (la repetición) y C9 |
| **Issue / milestone** | `phase:C11` · milestone `C11 Enemy skills` · #58 |
| **Referencia iOS** | merge `283d176` (`[PROJECT-C11]: Merge the enemy skills`), commits `d82c751` (combate) y `80eda2b` (repetición) |

## Objetivo

Desde *Tres bandidos* (nivel 6 del orden de juego), los enemigos usan la habilidad propia de su tipo, con una probabilidad que sube por nivel. La repetición lo enseña igual que las habilidades del héroe.

## Decisiones ya tomadas

**Habilidades por tipo:** `EnemyKindRules.skills` (`domain/world/extensions/`, junto a `HeroRules`), un `Set<SkillId>` que reutiliza las tres habilidades del héroe con los mismos efectos:

| Tipo | Habilidades |
|---|---|
| `bandit`, `banditVeteran` | *Esquiva* (el veterano está en el nivel 3, que no tiene probabilidad) |
| `barbarian`, `wolf`, `bear` | *Golpe doble* |
| `barbarianChief` | *Golpe doble* + *Segundo aliento* |

**Probabilidad por nivel:** `ArenaLevelEntity.enemySkillChance` (`double` en `0..1`, por defecto `0`, también en `copyWith`). Solo la pone `ArenaLevels` en los niveles 6–10: **1,5 / 2 / 2,5 / 3 / 3,5 %**. La propuesta inicial (10–30 %) hundía al héroe esperado (17–62 % de victorias); el jefe marca el techo (con 4 % bajaba a 59,7 %).

**Orden de las tiradas** (todas con el `SeededRandom` del combate; nunca se reordenan). Un dado de X solo existe si la probabilidad del nivel es > 0 **y** el tipo tiene X, y sale si `random.next() < enemySkillChance`:
1. **Golpe del héroe** (el normal y el de su *Golpe doble*) al primer enemigo vivo `t`:
   - dado de *Esquiva* de `t`; si sale, turno del héroe hacia `t` con `FightAction.dodge`, daño 0 y **sin** dado de daño;
   - si no, dado de daño como siempre;
   - después del golpe, si `t` tiene *Segundo aliento*, no lo ha tirado aún, sigue vivo y quedó por debajo de `Rules.secondWindThreshold`, se marca como tirado y se tira el dado. Si sale, se cura `Rules.secondWindHeal` (redondeado, sin pasar del máximo), con un turno `secondWind` del enemigo sobre sí mismo. **Una sola tirada por pelea.**
2. **Ataque del enemigo `i`**, vivo y con el héroe en pie:
   - su golpe normal como antes (dado de *Esquiva* del héroe si la tiene, dado de daño);
   - el *Segundo aliento* del héroe, como antes;
   - si el héroe sigue en pie, dado de *Golpe doble* de `i`; si sale, un segundo golpe con acción `doubleStrike` que repite los dos pasos anteriores.
3. En los niveles sin probabilidad la secuencia de `next()` es exactamente la de hoy: **las peleas de los niveles 1–5 no cambian** y sus goldens siguen valiendo.

**Sin casos nuevos en `FightAction`:**
- la esquiva del enemigo es un turno del héroe con `dodge` hacia ese enemigo;
- el *Segundo aliento* del jefe es un turno del enemigo sobre sí mismo;
- un golpe doble esquivado queda como `dodge` (se ve *¡Esquiva!*, no el nombre del golpe).

**Consejo tras perder:** `Combat.adviceFor` no cuenta los golpes del héroe esquivados (`dodge`) en el daño medio.

**Presentación:**
- `SkillUsedEffect` gana el bando y el índice de quien la usa (`side`, `index`).
- `ArenaBloc` lo emite para `doubleStrike` y `secondWind` de **cualquier** actor del turno.
- `ArenaStateListener` pinta el nombre (`Internationalize.arenaSkillUsed`) sobre ese luchador, a la misma altura que sobre el héroe.
- Sin textos nuevos.

**Equilibrado** (regla del test de balance + ≥ 60 % también con las semillas 0–999). Victorias del héroe esperado con semillas 0–99 / 0–999:

| Nivel | Probabilidad | Victorias |
|---|---|---|
| 6 | 1,5 % | 89,0 / 86,6 % |
| 7 | 2 % | 73,0 / 75,1 % |
| 8 | 2,5 % | 78,0 / 71,9 % |
| 9 | 3 % | 79,0 / 74,0 % |
| 10 | 3,5 % | 64,0 / 60,8 % |

Un paso por detrás gana < 50 % en todos. Como Dart y Swift comparten el `SeededRandom` y el orden de tiradas, Flutter debe dar **exactamente** estas cifras: si no salen, el orden de tiradas está mal. Se actualiza la tabla de `docs/GAME_DESIGN.md` 3.8.

**Comprobación cruzada (opcional):** el programa Dart del combate que usó iOS para la paridad (`$IOS/build/parity/dart`, ignorado por git: puede no existir) imprime el mismo formato que la traza Swift de referencia `$IOS/build/c11-parity/out-real/m2-combat.txt` (19970 líneas). Ejecutarlo contra el dominio de Flutter de esta fase y comparar es la prueba más fuerte de que el combate es el mismo.

## Ficheros previstos

- **Dominio:** `entities/combat/arena_level_entity.dart`, `rules/arena_levels.dart`, `combat/combat.dart`, `world/extensions/enemy_kind_rules.dart` (nuevo).
- **Presentación:** `features/arena/models/arena_effect.dart`, `features/arena/bloc/arena_bloc.dart`, `features/arena/game/arena_state_listener.dart`.
- **Tests:** mocks de `ArenaLevelEntity` con probabilidad, goldens nuevos de combate.
- **Docs:** `docs/GAME_DESIGN.md` 3.8, `CLAUDE.md` (habilidades de los enemigos y el orden de las tiradas en *Architecture*).

## Cómo probarlo

- Jugar los niveles 6–10 varias veces: de vez en cuando un bandido esquiva (*¡Esquiva!* sobre él), un bárbaro o un lobo golpea dos veces (*¡Golpe doble!* encima) y el jefe se cura una vez.
- Tests:
  - `combat_test.dart`:
    - goldens de los niveles 6–10 con una semilla que enseñe cada habilidad;
    - un nivel sin probabilidad da exactamente el registro de antes;
    - el jefe tira *Segundo aliento* una sola vez;
    - `adviceFor` ignora los `dodge` del héroe;
  - `enemy_kind_rules_test.dart`: las habilidades de cada `EnemyKind`;
  - `balance_test.dart` con las probabilidades (≥ 60 % con 0–99 y 0–999);
  - `arena_bloc_test.dart`: `SkillUsedEffect` con bando enemigo e índice;
  - `arena_state_listener_test.dart`: el nombre flota sobre el enemigo.
