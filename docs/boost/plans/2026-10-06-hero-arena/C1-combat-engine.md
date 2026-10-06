# C1 · Motor de combate y niveles de la arena — ficha

> **Plan detallado: pendiente.** Al empezar la fase, `/siguiente-tarea` ejecuta `boost:writing-plans` sobre esta ficha, cambia este aviso por la cabecera *For agentic workers*, divide el trabajo en tareas TC1.x y crea sus issues en GitHub.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C0 |
| **Issue / milestone** | `phase:C1` · `stream:C` · milestone `C1 Combat engine` |

## Objetivo

Que el dominio sepa resolver una pelea y llevar la cuenta de la arena: qué niveles hay, cuáles están desbloqueados, cuánto se cobra y qué pasa al ganar o perder. **Sólo dominio**: la pantalla es C2. Al terminar, un test de flujo puede jugar la arena entera sin interfaz.

## Decisiones ya tomadas

**Motor** (`lib/layers/domain/combat/combat.dart`):
- `abstract final class Combat` con un único punto de entrada:

  ```dart
  static FightLogEntity resolve({
    required ArenaLevelEntity level,
    required CombatStatsEntity heroStats,
    required Set<SkillId> skills,
    required int seed,
  });
  ```

  El `reward` del registro lo pone el caso de uso, no el motor. El motor devuelve `reward: const {}`.
- Simulación por rondas con `SeededRandom(seed)`, el de `core/utils/seeded_random.dart`:
  1. Golpea el héroe. El objetivo es el primer enemigo vivo (`targetIndex` más bajo con vida > 0).
  2. Si el héroe tiene `SkillId.doubleStrike` y es su tercer, sexto, noveno… ataque, sigue un turno `FightAction.doubleStrike` contra el mismo objetivo (o contra el siguiente vivo, si cayó).
  3. Golpea cada enemigo vivo, en orden de índice. Si el héroe tiene `SkillId.dodge` y `random.next() < Rules.dodgeChance` (0,2), el turno es `FightAction.dodge` con daño 0.
  4. Si el héroe tiene `SkillId.secondWind`, no lo ha usado en esta pelea y su vida baja de `Rules.secondWindThreshold` (30 %) sin llegar a 0, sigue un turno `FightAction.secondWind` que cura `Rules.secondWindHeal` (40 %) de su vida máxima, con tope en la vida máxima.
  5. Daño de un golpe: `max(1, (ataque − defensa) × (1 + (random.next() × 2 − 1) × Rules.damageSpread)).round()`, con `Rules.damageSpread = 0.15`, y tope en la vida que le queda al objetivo.
  6. Termina en victoria cuando todos los enemigos están a 0; en derrota cuando el héroe está a 0 o al llegar a `Rules.maxFightRounds` (30) rondas.
- El orden de llamadas a `random.next()` forma parte del contrato: **una por golpe** (para el daño) y **una por ataque enemigo si hay esquiva** (antes del daño). Si se cambia, cambian todos los resultados dorados de los tests.
- Constantes nuevas al final de `Rules`: `damageSpread`, `maxFightRounds`, `dodgeChance`, `secondWindThreshold`, `secondWindHeal`, `repeatRewardDivisor` (3).

**Catálogo** `lib/layers/domain/rules/arena_levels.dart`: `abstract final class ArenaLevels` con `static const List<ArenaLevelEntity> all` (el **orden de la lista es el orden de juego**) y `static ArenaLevelEntity byId(ArenaLevelId id)`. Niveles de C1, sólo humanos (orientativo; C7 equilibra):

| `ArenaLevelId` | Enemigos (`EnemyKind`: ataque / defensa / vida) | Poder aprox. | Oro |
|---|---|---|---|
| `banditRookie` | bandit 3/0/20 | 19 | 10 |
| `banditVeteran` | bandit 6/2/30 | 41 | 20 |
| `banditTrio` | 3 × bandit 4/1/20 | 78 | 40 |
| `barbarian` | barbarian 12/4/60 | 82 | 50 |
| `barbarianPair` | 2 × barbarian 9/4/50 | 136 | 65 |
| `barbarianChief` | barbarianChief 12/5/70 + 2 × barbarian 6/2/30 | 173 | 100 |

El Poder de un grupo es la suma de sus miembros. Con defensa alta, el daño mínimo de 1 hace que un grupo débil sea menos peligroso de lo que dice la suma: por eso el jefe (173) se puede ganar con el equipo completo (144). Lo confirma el test de flujo y lo ajusta C7.

C4 inserta los niveles de animales **en medio** de la lista (por eso el progreso se guarda como un `Set<ArenaLevelId>` y no como un número).

**Reglas de la arena** (`lib/layers/domain/world/extensions/arena_rules.dart`, extensión sobre `HeroEntity`):
- `bool isUnlocked(ArenaLevelEntity level)`: el primero de `ArenaLevels.all` siempre; los demás, si el anterior de la lista está en `clearedLevels`.
- `bool hasCleared(ArenaLevelId id)`.
- `Map<Resource, int> rewardFor(ArenaLevelEntity level)`: el `reward` completo la primera vez; repetido, cada cantidad `~/ Rules.repeatRewardDivisor`, quitando las que quedan a 0.

**Casos de uso** (`lib/layers/domain/use-cases/arena/`):
- `GetArenaUseCase` → `ArenaEntity` (nueva, en `entities/combat/`):
  - `heroPower`;
  - `levels: List<ArenaLevelStatusEntity(level, isUnlocked, isCleared, nextReward)>`.
- `StartFightUseCase.call({required ArenaLevelId levelId})` → `FightResultEntity`, una jerarquía `sealed` en un solo fichero (E8):
  - `FightPlayedEntity(log)`;
  - `FightLockedEntity()` si el nivel no está desbloqueado.

  Si se juega:
  1. Resuelve con `seed: hero.fightsFought`.
  2. Si gana, cobra con `world.earn(reward)` y apunta el nivel en `clearedLevels`.
  3. Siempre suma 1 a `fightsFought` con `world.updateHero`.
  4. Devuelve el registro con el `reward` cobrado.
- **Consejo tras una derrota:** `FightPlayedEntity` lleva `advice: FightAdvice?` (enum de core `FightAdvice { almostThere, needAttack, needDefense }`), `null` si gana. Lo calcula `Combat.adviceFor(FightLogEntity log)`:
  - `almostThere`: a los enemigos les queda como mucho el 25 % de su vida total;
  - `needAttack`: si no, cuando el daño medio de los golpes del héroe es 2 o menos;
  - `needDefense`: en el resto de casos.
- Una sola llamada deja el `World` ya actualizado. La pantalla reproduce el registro **después**: si el jugador cierra la app a media animación, el resultado ya está aplicado.

**Eventos:** ninguno. La arena no avanza con `advance(deltaMs)`; el resultado vuelve directamente del caso de uso.

**Persistencia:** `clearedLevels` y `fightsFought` ya están en `HeroEntity` (C0). Si F2 está fusionada y C0 no los guardó, esta fase los añade al `HeroDBO`.

## Ficheros previstos

**Dominio:**
- `lib/layers/domain/combat/combat.dart` (nuevo)
- `lib/layers/domain/rules/arena_levels.dart` (nuevo), `rules/rules.dart`
- `lib/layers/domain/world/extensions/arena_rules.dart` (nuevo)
- `lib/layers/domain/entities/combat/arena_entity.dart`, `arena_level_status_entity.dart`, `fight_result_entity.dart` (nuevos)
- `lib/layers/domain/use-cases/arena/get_arena_use_case.dart`, `start_fight_use_case.dart` (nuevos)

**Core:** enum `lib/core/config/constants/enum/fight_advice.dart` (nuevo); `di.config.dart` regenerado.

**Documentación:** `CLAUDE.md` (*Architecture*: `domain/combat/`, `use-cases/arena/`, E1).

**Tests:** `test/architecture_test.dart` no cambia: `domain/combat/` ya cae en las reglas del dominio. Comprueba que el test lo recorre.

## Cómo probarlo

Sólo hay tests, porque no hay interfaz hasta C2:
- `combat_test.dart`, con resultados **dorados** (la misma semilla da el mismo registro):
  - héroe base contra `banditRookie` gana;
  - héroe base contra `barbarianChief` pierde;
  - con `doubleStrike` aparece el golpe extra en el tercer ataque;
  - con `dodge` aparece al menos una esquiva en 30 rondas;
  - `secondWind` cura una sola vez;
  - con daño mínimo se llega a 30 rondas y cuenta como derrota;
  - un enemigo muerto no ataca;
  - el héroe cambia de objetivo al caer el primero;
  - `adviceFor` da cada uno de los tres consejos.
- `arena_levels_test.dart`: los ids son únicos, cubren todo `ArenaLevelId` y hay entre 1 y 3 enemigos por nivel.
- `arena_rules_test.dart` (desbloqueo y recompensa repetida) y los tests de los dos casos de uso.
- `arena_flow_test.dart`: un héroe con todo el equipo y las tres habilidades gana todos los niveles en orden, y el oro acumulado es la suma esperada.
