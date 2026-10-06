# C1 · Motor de combate y niveles de la arena — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C0 |
| **Issue / milestone** | `phase:C1` · `stream:C` · milestone `C1 Combat engine` (un issue por tarea: TC1.1, TC1.2, TC1.3) |

**Goal:** Que el dominio sepa resolver una pelea y llevar la cuenta de la arena: qué niveles hay, cuáles están desbloqueados, cuánto se cobra y qué pasa al ganar o perder. **Sólo dominio**: la pantalla es C2. Al terminar, un test de flujo juega la arena entera sin interfaz.

**Architecture:**
- `lib/layers/domain/combat/combat.dart`: `abstract final class Combat` con dos funciones puras:
  - `resolve` simula la pelea entera con `SeededRandom(seed)` y devuelve un `FightLogEntity` con `reward: const {}`;
  - `adviceFor` lee un registro perdido y devuelve un `FightAdvice`.
- Catálogo `ArenaLevels` en `domain/rules/` (como `Gear`); el **orden de la lista es el orden de juego**.
- Extensión `ArenaRules` sobre `HeroEntity` en `domain/world/extensions/`: desbloqueo, niveles ganados, recompensa (completa o un tercio) y `afterFight` (apunta la pelea en el héroe).
- Casos de uso síncronos en `use-cases/arena/`: `GetArenaUseCase` (estado de la arena) y `StartFightUseCase` (resolver, cobrar con `World.earn`, desbloquear con `World.updateHero`). Una sola llamada deja el `World` actualizado.
- Sin eventos: la arena no avanza con `advance(deltaMs)`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `injectable`, `collection`, `flutter_test` + `mockito`.

**Precondición: C0 fusionada en `develop`.** Este plan usa exactamente los nombres de *Interfaces → Produces* de [C0-contract.md](C0-contract.md) (TC0.1 y TC0.2) y sus mocks. Antes de empezar, comprueba que no han cambiado al implementar C0:
- enums `SkillId`, `EnemyKind`, `ArenaLevelId`, `FightSide`, `FightAction`, `FightOutcome`, `Resource.gold`;
- entidades `CombatStatsEntity`, `EnemyEntity`, `ArenaLevelEntity` (con `power` y el `assert` de 1 a 3 enemigos), `FightTurnEntity`, `FightLogEntity` (con `copyWith`, `isVictory`, `rounds`), `HeroEntity` (con `copyWith`);
- `HeroRules.stats` / `power`, `World.hero` / `updateHero` / `funds` / `earn`, `InventoryRules.amount`;
- mocks `CombatStatsEntityMock`, `HeroEntityMock` (`mock`, `veteran`, `withShortSwordAndLeather`, `fullyGeared`), `EnemyEntityMock`, `ArenaLevelEntityMock`, `FightTurnEntityMock` (`heroHits`, `enemyHits`), `FightLogEntityMock`, `FundsMock`, `WorldMock.withHero`, `GameSessionEntityMock.playing`.

Si alguna firma o valor ha cambiado, adapta los fragmentos de este plan **y recalcula los registros dorados** (sección *Resultados dorados*), y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- Sólo hay tests, porque no hay interfaz hasta C2.
- `flutter test` en verde, incluidos `combat_test.dart`, `arena_levels_test.dart`, `arena_rules_test.dart`, los tests de los dos casos de uso y `arena_flow_test.dart` (un héroe con todo el equipo y las tres habilidades gana los seis niveles en orden y cobra 285 de oro).
- En Chrome, el emulador Android y el simulador iOS el juego se comporta como tras C0 (esta fase no toca la presentación).

## Decisiones del plan

Lo que este plan fija o añade sobre la ficha (todo lo demás de la ficha se mantiene tal cual):

1. **Catálogo verificado, sin cambios de números.** Los Poderes de la ficha son correctos (19, 41, 78, 82, 136, 173 con `power = ataque × 3 + defensa × 4 + vida ~/ 2`). Con el motor de este plan, el héroe con todo el equipo (14/8/75) y las tres habilidades gana los seis niveles con las semillas 0–5 del test de flujo, y también con 100 semillas por nivel (incluso sin habilidades). Cada nivel se puede ganar con algún escalón de equipo y el héroe base sólo gana `banditRookie`. El jefe exige el equipo completo: es el final del modo, así que no se considera trivial. C7 equilibra.
2. **Tres constantes más en `Rules`** además de las seis de la ficha, para no dejar números mágicos en el motor y que C7 pueda ajustarlas: `doubleStrikeEvery = 3`, `almostThereShare = 0.25`, `weakHitDamage = 2`.
3. **`ArenaRules.afterFight(FightLogEntity log)`**: la operación que suma 1 a `fightsFought` y, si se ganó, añade el nivel a `clearedLevels`. Va en la extensión (E2) para que el caso de uso no haga `copyWith` a mano.
4. **Doble golpe:** cuenta sólo los golpes normales del héroe (sale en las rondas 3, 6, 9…). Si con el golpe normal caen todos los enemigos, no hay doble golpe.
5. **Esquiva:** turno con `actor: enemy` (el que falla), `damage: 0` y `targetHealthAfter` = vida actual del héroe.
6. **Segundo aliento:** se comprueba después de cada ataque enemigo; condición `0 < vida < vidaMáxima × 0,3` (estricta, en `double`); cura `(vidaMáxima × 0,4).round()`, con tope en la vida máxima. Turno con `actor` y `target` el héroe, `damage: 0`.
7. **Fin de la pelea:** el bucle se para cuando el héroe llega a 0, todos los enemigos a 0 o se completa la ronda `Rules.maxFightRounds`. Si en ese momento queda algún enemigo vivo, es derrota.
8. **`adviceFor` devuelve `FightAdvice?`:** `null` si el registro es una victoria. La vida que le queda a cada enemigo es el `targetHealthAfter` del último turno que lo tuvo de objetivo (o su vida completa si nadie le golpeó). El daño medio se calcula sobre los turnos `hit` y `doubleStrike` del héroe contra enemigos.
9. **Los tests del motor usan `ArenaLevelEntityMock`, no `ArenaLevels`:** así los registros dorados no cambian cuando C7 reequilibre el catálogo. Los tests de casos de uso y el de flujo sí usan el catálogo, y C7 los actualiza si cambia sus números.
10. **`FightPlayedEntity` / `FightLockedEntity`** siguen el patrón de `ConstructionResultEntity`: sin `copyWith`, con `==`/`hashCode` escritos a mano.
11. **Persistencia:** C1 no añade campos a `HeroEntity`. Si F2 está fusionada, `clearedLevels` y `fightsFought` ya los guarda el `HeroDBO` (README, sección 3.2). TC1.3 sólo lo comprueba.

## Resultados dorados

Calculados a mano simulando `SeededRandom` (LCG `state = (state × 1664525 + 1013904223) & 0xFFFFFFFF`, `next() = state / 2³²`) con el algoritmo exacto de TC1.1, y comprobados ejecutando una copia del motor en Dart 3.13 fuera del proyecto. Con `.round()` de Dart (mitades hacia fuera de cero). Si se cambia el orden de las llamadas a `random.next()`, cambian todos:

| Pelea (stats del héroe, habilidades, nivel, semilla) | Resultado |
|---|---|
| base 4/1/30, ninguna, `banditRookie` (3/0/20), 0 | victoria en 5 rondas, 9 turnos; idéntica a `FightTurnEntityMock.victoryOverBandit()` |
| base, ninguna, `banditRookie`, 1 | victoria en 6 rondas |
| base, ninguna, `banditRookie`, 3 | victoria en 6 rondas |
| base, `doubleStrike`, `banditRookie`, 0 | victoria en 4 rondas; el turno 5 (índice) es `doubleStrike`, ronda 3, daño 4, vida 4 |
| base, ninguna, jefe 12/5/70 + 2 × 6/2/30, 0 | derrota en 2 rondas, 6 turnos; el héroe hace 1 por golpe |
| 14/8/75, ninguna, muro 2/20/100, 0 | derrota en 30 rondas, 60 turnos, todos de 1; héroe 45, muro 70 |
| 14/8/75, `dodge`, muro, 0 | derrota en 30 rondas; esquivas en las rondas 11, 16, 18, 21, 22, 23; héroe 51 |
| base, `secondWind`, bandido veterano 6/2/30, 0 | derrota en 9 rondas; un solo `secondWind` (índice 10, ronda 5, vida 5 → 17); después baja a 1 sin otra cura |
| base, ninguna, bandido veterano, 3 | derrota en 6 rondas; al enemigo le quedan 18; daño medio del héroe 2 → `needAttack` |
| 7/3/40, ninguna, 3 × bandido 3/0/20, 0 | victoria en 9 rondas; el héroe apunta a 0, 0, 0, 1, 1, 1, 2, 2, 2 |
| 7/3/40, `doubleStrike`, 3 × bandido, 0 | victoria en 7 rondas; el doble golpe de la ronda 3 cae sobre el enemigo 1 (el 0 acaba de caer); dobles golpes en las rondas 3 y 6 |
| base, ninguna, duelista 8/0/24, 0 | derrota en 5 rondas; al duelista le quedan 4 (17 %) → `almostThere` |
| 14/8/75, ninguna, bruto 31/6/55, 0 | derrota en 4 rondas; al bruto le quedan 23 (42 %), daño medio 8 → `needDefense` |
| 14/8/75, las tres, `ArenaLevels.all` en orden, semillas 0–5 | seis victorias (2, 3, 5, 5, 8 y 11 rondas) |

## Reparto

| Tarea | Capa | Depende de | Paralelizable |
|---|---|---|---|
| TC1.1 Motor de combate y constantes | domain (`combat/`, `rules.dart`) + core (`FightAdvice`) | C0 | Sí, con TC1.2 (sólo comparten el final de `rules.dart`: cambio aditivo) |
| TC1.2 Niveles de la arena y sus reglas | domain (`arena_levels.dart`, `arena_rules.dart`, `rules.dart`) | C0 | Sí, con TC1.1 |
| TC1.3 Casos de uso de la arena y test de flujo | domain (entidades, `use-cases/arena/`) + DI + `CLAUDE.md` | TC1.1, TC1.2 | No |

Cada tarea sale de `develop` en su rama y deja `develop` en verde al fusionarse.

---

### Task TC1.1: Motor de combate y constantes

**Files:**
- Create:
  - `lib/core/config/constants/enum/fight_advice.dart`
  - `lib/layers/domain/combat/combat.dart`
  - `test/layers/domain/combat/combat_test.dart`
- Modify:
  - `lib/layers/domain/rules/rules.dart`: ocho constantes al final.
  - Mocks de C0 (se amplían, sin cambiar lo que ya hay):
    - `test/mocks/domain/entities/hero/combat_stats_entity_mock.dart`
    - `test/mocks/domain/entities/combat/enemy_entity_mock.dart`
    - `test/mocks/domain/entities/combat/arena_level_entity_mock.dart`
    - `test/mocks/domain/entities/combat/fight_turn_entity_mock.dart`
    - `test/mocks/domain/entities/combat/fight_log_entity_mock.dart`

**Interfaces:**
- Consumes (de C0): `ArenaLevelEntity`, `CombatStatsEntity`, `EnemyEntity`, `FightTurnEntity`, `FightLogEntity` (`copyWith`, `isVictory`, `rounds`), `SkillId`, `FightSide`, `FightAction`, `FightOutcome`; `SeededRandom` (`lib/core/utils/seeded_random.dart`).
- Produces:
  ```dart
  // lib/core/config/constants/enum/fight_advice.dart
  enum FightAdvice { almostThere, needAttack, needDefense }

  // lib/layers/domain/rules/rules.dart (al final)
  static const double damageSpread = 0.15;
  static const int maxFightRounds = 30;
  static const double dodgeChance = 0.2;
  static const double secondWindThreshold = 0.3;
  static const double secondWindHeal = 0.4;
  static const int doubleStrikeEvery = 3;
  static const double almostThereShare = 0.25;
  static const double weakHitDamage = 2;

  // lib/layers/domain/combat/combat.dart
  abstract final class Combat {
    static FightLogEntity resolve({
      required ArenaLevelEntity level,
      required CombatStatsEntity heroStats,
      required Set<SkillId> skills,
      required int seed,
    });                                                   // reward: const {}
    static FightAdvice? adviceFor(FightLogEntity log);    // null si es victoria
  }

  // mocks nuevos
  CombatStatsEntityMock.veteranBandit / .barbarianGuard / .barbarianChief / .duelist / .wall
  EnemyEntityMock.veteranBandit / .barbarianGuard / .barbarianChief / .duelist / .wall
  ArenaLevelEntityMock.banditVeteran / .barbarianChief / .duel / .wall / .brute
  FightTurnEntityMock.almostBeatDuelist() / .defeatByBruteFullyGeared()
  FightLogEntityMock.victoryOverBanditBeforeReward() / .almostBeatDuelist() / .defeatByBruteFullyGeared()
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-c1-engine
```

- [ ] **Step 2: Ampliar los datos de prueba**

En `test/mocks/domain/entities/hero/combat_stats_entity_mock.dart`, al final de la clase:

```dart
  static const CombatStatsEntity veteranBandit = CombatStatsEntity(attack: 6, defense: 2, health: 30);

  static const CombatStatsEntity barbarianGuard = CombatStatsEntity(attack: 6, defense: 2, health: 30);

  static const CombatStatsEntity barbarianChief = CombatStatsEntity(attack: 12, defense: 5, health: 70);

  static const CombatStatsEntity duelist = CombatStatsEntity(attack: 8, defense: 0, health: 24);

  static const CombatStatsEntity wall = CombatStatsEntity(attack: 2, defense: 20, health: 100);
```

En `test/mocks/domain/entities/combat/enemy_entity_mock.dart`, al final de la clase:

```dart
  static const EnemyEntity veteranBandit = EnemyEntity(
    kind: EnemyKind.bandit,
    stats: CombatStatsEntityMock.veteranBandit,
  );

  static const EnemyEntity barbarianGuard = EnemyEntity(
    kind: EnemyKind.barbarian,
    stats: CombatStatsEntityMock.barbarianGuard,
  );

  static const EnemyEntity barbarianChief = EnemyEntity(
    kind: EnemyKind.barbarianChief,
    stats: CombatStatsEntityMock.barbarianChief,
  );

  static const EnemyEntity duelist = EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntityMock.duelist);

  static const EnemyEntity wall = EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntityMock.wall);
```

En `test/mocks/domain/entities/combat/arena_level_entity_mock.dart`, al final de la clase. `banditVeteran` y `barbarianChief` copian los números de la ficha, pero son datos de prueba: si C7 cambia el catálogo, estos no cambian.

```dart
  static const ArenaLevelEntity banditVeteran = ArenaLevelEntity(
    id: ArenaLevelId.banditVeteran,
    enemies: [EnemyEntityMock.veteranBandit],
    reward: {Resource.gold: 20},
  );

  static const ArenaLevelEntity barbarianChief = ArenaLevelEntity(
    id: ArenaLevelId.barbarianChief,
    enemies: [EnemyEntityMock.barbarianChief, EnemyEntityMock.barbarianGuard, EnemyEntityMock.barbarianGuard],
    reward: {Resource.gold: 100},
  );

  static const ArenaLevelEntity duel = ArenaLevelEntity(
    id: ArenaLevelId.banditVeteran,
    enemies: [EnemyEntityMock.duelist],
    reward: {Resource.gold: 20},
  );

  static const ArenaLevelEntity wall = ArenaLevelEntity(
    id: ArenaLevelId.barbarian,
    enemies: [EnemyEntityMock.wall],
    reward: {Resource.gold: 50},
  );

  static const ArenaLevelEntity brute = ArenaLevelEntity(
    id: ArenaLevelId.barbarian,
    enemies: [EnemyEntityMock.brute],
    reward: {Resource.gold: 50},
  );
```

En `test/mocks/domain/entities/combat/fight_turn_entity_mock.dart`, al final de la clase. Son los registros reales del motor con semilla 0 (ver *Resultados dorados*):

```dart
  static List<FightTurnEntity> almostBeatDuelist() => [
    heroHits(round: 1, damage: 4, enemyHealthAfter: 20),
    enemyHits(round: 1, damage: 7, heroHealthAfter: 23),
    heroHits(round: 2, damage: 4, enemyHealthAfter: 16),
    enemyHits(round: 2, damage: 7, heroHealthAfter: 16),
    heroHits(round: 3, damage: 4, enemyHealthAfter: 12),
    enemyHits(round: 3, damage: 7, heroHealthAfter: 9),
    heroHits(round: 4, damage: 4, enemyHealthAfter: 8),
    enemyHits(round: 4, damage: 7, heroHealthAfter: 2),
    heroHits(round: 5, damage: 4, enemyHealthAfter: 4),
    enemyHits(round: 5, damage: 2, heroHealthAfter: 0),
  ];

  static List<FightTurnEntity> defeatByBruteFullyGeared() => [
    heroHits(round: 1, damage: 7, enemyHealthAfter: 48),
    enemyHits(round: 1, damage: 21, heroHealthAfter: 54),
    heroHits(round: 2, damage: 9, enemyHealthAfter: 39),
    enemyHits(round: 2, damage: 24, heroHealthAfter: 30),
    heroHits(round: 3, damage: 8, enemyHealthAfter: 31),
    enemyHits(round: 3, damage: 24, heroHealthAfter: 6),
    heroHits(round: 4, damage: 8, enemyHealthAfter: 23),
    enemyHits(round: 4, damage: 6, heroHealthAfter: 0),
  ];
```

En `test/mocks/domain/entities/combat/fight_log_entity_mock.dart`, al final de la clase:

```dart
  static FightLogEntity victoryOverBanditBeforeReward() => victoryOverBandit().copyWith(reward: const {});

  static FightLogEntity almostBeatDuelist() => FightLogEntity(
    levelId: ArenaLevelId.banditVeteran,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.duelist],
    turns: FightTurnEntityMock.almostBeatDuelist(),
    outcome: FightOutcome.defeat,
    reward: const {},
  );

  static FightLogEntity defeatByBruteFullyGeared() => FightLogEntity(
    levelId: ArenaLevelId.barbarian,
    heroStats: CombatStatsEntityMock.heroFullyGeared,
    enemies: const [EnemyEntityMock.brute],
    turns: FightTurnEntityMock.defeatByBruteFullyGeared(),
    outcome: FightOutcome.defeat,
    reward: const {},
  );
```

- [ ] **Step 3: Escribir los tests del motor que fallan**

`test/layers/domain/combat/combat_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_action.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/core/config/constants/enum/fight_outcome.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/combat/combat.dart';
import 'package:rpg/layers/domain/rules/rules.dart';

import '../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';
import '../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';
import '../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';

void main() {
  group('resolve', () {
    test('testWhenTheBaseHeroFightsTheRookieBanditThenTheGoldenLogIsAVictory', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);

      // then
      expect(log, FightLogEntityMock.victoryOverBanditBeforeReward());
    });

    test('testWhenResolvingTwiceWithTheSameSeedThenTheLogsAreEqual', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final first = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {SkillId.doubleStrike, SkillId.dodge},
        seed: 7,
      );
      final second = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {SkillId.doubleStrike, SkillId.dodge},
        seed: 7,
      );

      // then
      expect(second, first);
    });

    test('testWhenTheSeedChangesThenTheLogChanges', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 1);

      // then
      expect(log, isNot(FightLogEntityMock.victoryOverBanditBeforeReward()));
      expect((log.outcome, log.rounds), (FightOutcome.victory, 6));
    });

    test('testWhenTheBaseHeroFightsTheChiefThenItLosesInTwoRounds', () {
      // given
      const level = ArenaLevelEntityMock.barbarianChief;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);

      // then
      expect((log.outcome, log.rounds, log.turns.length), (FightOutcome.defeat, 2, 6));
      expect(log.turns.last.target, FightSide.hero);
      expect(log.turns.last.targetHealthAfter, 0);
      expect(log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.damage), [1, 1]);
    });

    test('testWhenTheBaseHeroDuelsThenTheGoldenLogIsANarrowDefeat', () {
      // given
      const level = ArenaLevelEntityMock.duel;

      // when
      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);

      // then
      expect(log, FightLogEntityMock.almostBeatDuelist());
    });

    test('testWhenAFullyGearedHeroFightsTheBruteThenTheGoldenLogIsADefeat', () {
      // given
      const level = ArenaLevelEntityMock.brute;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skills: const {},
        seed: 0,
      );

      // then
      expect(log, FightLogEntityMock.defeatByBruteFullyGeared());
    });

    test('testWhenTheHeroHasDoubleStrikeThenTheExtraHitFollowsTheThirdAttack', () {
      // given
      const level = ArenaLevelEntityMock.banditRookie;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skills: const {SkillId.doubleStrike},
        seed: 0,
      );

      // then
      final extra = log.turns[5];
      expect((extra.action, extra.round, extra.actor, extra.damage, extra.targetHealthAfter), (
        FightAction.doubleStrike,
        3,
        FightSide.hero,
        4,
        4,
      ));
      expect(log.turns.where((turn) => turn.action == FightAction.doubleStrike), hasLength(1));
      expect((log.outcome, log.rounds), (FightOutcome.victory, 4));
    });

    test('testWhenTheTargetFallsBeforeTheDoubleStrikeThenItHitsTheNextAliveEnemy', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {SkillId.doubleStrike},
        seed: 0,
      );

      // then
      final kill = log.turns[8];
      final extra = log.turns[9];
      expect((kill.action, kill.targetIndex, kill.targetHealthAfter), (FightAction.hit, 0, 0));
      expect((extra.action, extra.round, extra.targetIndex, extra.damage, extra.targetHealthAfter), (
        FightAction.doubleStrike,
        3,
        1,
        7,
        13,
      ));
      expect(log.turns.where((turn) => turn.action == FightAction.doubleStrike).map((turn) => turn.round), [3, 6]);
      expect((log.outcome, log.rounds), (FightOutcome.victory, 7));
    });

    test('testWhenTheHeroHasDodgeThenSomeEnemyAttacksAreDodgedWithoutDamage', () {
      // given
      const level = ArenaLevelEntityMock.wall;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skills: const {SkillId.dodge},
        seed: 0,
      );

      // then
      final dodges = log.turns.where((turn) => turn.action == FightAction.dodge).toList();
      expect(dodges.map((turn) => turn.round), [11, 16, 18, 21, 22, 23]);
      expect(dodges.every((turn) => turn.actor == FightSide.enemy && turn.damage == 0), isTrue);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.hero).targetHealthAfter, 51);
    });

    test('testWhenTheHeroHasSecondWindThenItHealsOnlyOnce', () {
      // given
      const level = ArenaLevelEntityMock.banditVeteran;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroBase,
        skills: const {SkillId.secondWind},
        seed: 0,
      );

      // then
      final heals = log.turns.where((turn) => turn.action == FightAction.secondWind).toList();
      expect(heals, hasLength(1));
      expect((heals.single.round, heals.single.actor, heals.single.target, heals.single.targetHealthAfter), (
        5,
        FightSide.hero,
        FightSide.hero,
        17,
      ));
      expect(log.turns[9].targetHealthAfter, 5);
      expect(log.turns[16].targetHealthAfter, 1);
      expect((log.outcome, log.rounds), (FightOutcome.defeat, 9));
    });

    test('testWhenNobodyCanHurtTheOtherThenTheFightStopsAtTheRoundLimitAsADefeat', () {
      // given
      const level = ArenaLevelEntityMock.wall;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroFullyGeared,
        skills: const {},
        seed: 0,
      );

      // then
      expect((log.outcome, log.rounds, log.turns.length), (FightOutcome.defeat, Rules.maxFightRounds, 60));
      expect(log.turns.every((turn) => turn.damage == 1), isTrue);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.hero).targetHealthAfter, 45);
      expect(log.turns.lastWhere((turn) => turn.target == FightSide.enemy).targetHealthAfter, 70);
    });

    test('testWhenAnEnemyFallsThenItNoLongerAttacks', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {},
        seed: 0,
      );

      // then
      final fall = log.turns.indexWhere((turn) => turn.target == FightSide.enemy && turn.targetHealthAfter == 0);
      final afterFall = log.turns.skip(fall + 1);
      expect(fall, 8);
      expect(afterFall.where((turn) => turn.actor == FightSide.enemy && turn.actorIndex == 0), isEmpty);
      expect((log.outcome, log.rounds), (FightOutcome.victory, 9));
    });

    test('testWhenTheFirstEnemyFallsThenTheHeroTargetsTheNextAliveOne', () {
      // given
      const level = ArenaLevelEntityMock.banditTrio;

      // when
      final log = Combat.resolve(
        level: level,
        heroStats: CombatStatsEntityMock.heroWithShortSwordAndLeather,
        skills: const {},
        seed: 0,
      );

      // then
      final targets = log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.targetIndex);
      expect(targets, [0, 0, 0, 1, 1, 1, 2, 2, 2]);
    });
  });

  group('adviceFor', () {
    test('testWhenTheHeroWonThenThereIsNoAdvice', () {
      // given
      final log = FightLogEntityMock.victoryOverBandit();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, isNull);
    });

    test('testWhenTheEnemiesHadAQuarterOfTheirHealthLeftThenTheHeroWasAlmostThere', () {
      // given
      final log = FightLogEntityMock.almostBeatDuelist();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.almostThere);
    });

    test('testWhenTheHeroHitForTwoOrLessThenItNeedsAttack', () {
      // given
      final log = FightLogEntityMock.defeatByBrute();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.needAttack);
    });

    test('testWhenTheHeroHitHardButFellEarlyThenItNeedsDefense', () {
      // given
      final log = FightLogEntityMock.defeatByBruteFullyGeared();

      // when
      final advice = Combat.adviceFor(log);

      // then
      expect(advice, FightAdvice.needDefense);
    });
  });
}
```

- [ ] **Step 4: Ver que fallan**

Run: `flutter test test/layers/domain/combat/combat_test.dart`
Expected: FAIL al compilar (`combat.dart`, `fight_advice.dart` y las constantes de `Rules` no existen).

- [ ] **Step 5: `FightAdvice` y las constantes de `Rules`**

`lib/core/config/constants/enum/fight_advice.dart`:

```dart
enum FightAdvice { almostThere, needAttack, needDefense }
```

En `lib/layers/domain/rules/rules.dart`, al final de la clase (después de `powerPerSkill`, que añadió C0):

```dart
  static const double damageSpread = 0.15;
  static const int maxFightRounds = 30;
  static const double dodgeChance = 0.2;
  static const double secondWindThreshold = 0.3;
  static const double secondWindHeal = 0.4;
  static const int doubleStrikeEvery = 3;
  static const double almostThereShare = 0.25;
  static const double weakHitDamage = 2;
```

- [ ] **Step 6: Implementar el motor**

`lib/layers/domain/combat/combat.dart`. `_Fight` es el estado mutable de una sola pelea; vive y muere dentro de `resolve`. El orden de las llamadas a `random.next()` es el del contrato: una por golpe (en `_damage`) y, si el héroe sabe esquivar, una por ataque enemigo antes del daño.

```dart
import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../../core/config/constants/enum/fight_action.dart';
import '../../../core/config/constants/enum/fight_advice.dart';
import '../../../core/config/constants/enum/fight_outcome.dart';
import '../../../core/config/constants/enum/fight_side.dart';
import '../../../core/config/constants/enum/skill_id.dart';
import '../../../core/utils/seeded_random.dart';
import '../entities/combat/arena_level_entity.dart';
import '../entities/combat/enemy_entity.dart';
import '../entities/combat/fight_log_entity.dart';
import '../entities/combat/fight_turn_entity.dart';
import '../entities/hero/combat_stats_entity.dart';
import '../rules/rules.dart';

abstract final class Combat {
  static FightLogEntity resolve({
    required ArenaLevelEntity level,
    required CombatStatsEntity heroStats,
    required Set<SkillId> skills,
    required int seed,
  }) {
    final fight = _Fight(level: level, heroStats: heroStats, skills: skills, random: SeededRandom(seed))..play();
    return FightLogEntity(
      levelId: level.id,
      heroStats: heroStats,
      enemies: level.enemies,
      turns: List.unmodifiable(fight.turns),
      outcome: fight.enemiesDefeated ? FightOutcome.victory : FightOutcome.defeat,
      reward: const {},
    );
  }

  static FightAdvice? adviceFor(FightLogEntity log) {
    if (log.isVictory) return null;
    final totalHealth = log.enemies.fold(0, (sum, enemy) => sum + enemy.stats.health);
    final healthLeft = log.enemies.indexed.fold(0, (sum, entry) => sum + _healthLeft(log, entry.$1, entry.$2));
    if (healthLeft <= totalHealth * Rules.almostThereShare) return FightAdvice.almostThere;
    final strikes = log.turns.where((turn) => turn.actor == FightSide.hero && turn.target == FightSide.enemy).toList();
    final totalDamage = strikes.fold(0, (sum, turn) => sum + turn.damage);
    final averageDamage = strikes.isEmpty ? 0.0 : totalDamage / strikes.length;
    if (averageDamage <= Rules.weakHitDamage) return FightAdvice.needAttack;
    return FightAdvice.needDefense;
  }

  static int _healthLeft(FightLogEntity log, int index, EnemyEntity enemy) {
    final lastHit = log.turns.lastWhereOrNull((turn) => turn.target == FightSide.enemy && turn.targetIndex == index);
    return lastHit?.targetHealthAfter ?? enemy.stats.health;
  }
}

final class _Fight {
  final ArenaLevelEntity level;
  final CombatStatsEntity heroStats;
  final Set<SkillId> skills;
  final SeededRandom random;
  final List<FightTurnEntity> turns = [];
  final List<int> enemyHealth;
  int heroHealth;
  int heroAttacks = 0;
  int round = 0;
  bool secondWindUsed = false;

  _Fight({required this.level, required this.heroStats, required this.skills, required this.random})
    : enemyHealth = [for (final enemy in level.enemies) enemy.stats.health],
      heroHealth = heroStats.health;

  bool get enemiesDefeated => enemyHealth.every((health) => health == 0);

  bool get isOver => heroHealth == 0 || enemiesDefeated || round == Rules.maxFightRounds;

  void play() {
    while (!isOver) {
      round++;
      _heroAttacks();
      _enemiesAttack();
    }
  }

  void _heroAttacks() {
    _heroStrikes(FightAction.hit);
    heroAttacks++;
    if (skills.contains(SkillId.doubleStrike) && heroAttacks % Rules.doubleStrikeEvery == 0) {
      _heroStrikes(FightAction.doubleStrike);
    }
  }

  void _heroStrikes(FightAction action) {
    final target = enemyHealth.indexWhere((health) => health > 0);
    if (target < 0) return;
    final damage = _damage(
      attack: heroStats.attack,
      defense: level.enemies[target].stats.defense,
      healthLeft: enemyHealth[target],
    );
    enemyHealth[target] -= damage;
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.hero,
        actorIndex: 0,
        target: FightSide.enemy,
        targetIndex: target,
        action: action,
        damage: damage,
        targetHealthAfter: enemyHealth[target],
      ),
    );
  }

  void _enemiesAttack() {
    for (var index = 0; index < level.enemies.length; index++) {
      if (heroHealth == 0) return;
      if (enemyHealth[index] == 0) continue;
      _enemyStrikes(index);
      _catchSecondWind();
    }
  }

  void _enemyStrikes(int index) {
    final dodged = skills.contains(SkillId.dodge) && random.next() < Rules.dodgeChance;
    final damage = dodged
        ? 0
        : _damage(attack: level.enemies[index].stats.attack, defense: heroStats.defense, healthLeft: heroHealth);
    heroHealth -= damage;
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: index,
        target: FightSide.hero,
        targetIndex: 0,
        action: dodged ? FightAction.dodge : FightAction.hit,
        damage: damage,
        targetHealthAfter: heroHealth,
      ),
    );
  }

  void _catchSecondWind() {
    if (!skills.contains(SkillId.secondWind) || secondWindUsed) return;
    if (heroHealth == 0 || heroHealth >= heroStats.health * Rules.secondWindThreshold) return;
    secondWindUsed = true;
    heroHealth = math.min(heroStats.health, heroHealth + (heroStats.health * Rules.secondWindHeal).round());
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.hero,
        actorIndex: 0,
        target: FightSide.hero,
        targetIndex: 0,
        action: FightAction.secondWind,
        damage: 0,
        targetHealthAfter: heroHealth,
      ),
    );
  }

  int _damage({required int attack, required int defense, required int healthLeft}) {
    final spread = 1 + (random.next() * 2 - 1) * Rules.damageSpread;
    return math.min(healthLeft, math.max(1, ((attack - defense) * spread).round()));
  }
}
```

- [ ] **Step 7: Ver que pasan**

Run: `flutter test test/layers/domain/combat/combat_test.dart`
Expected: PASS (17 tests). Si falla un dorado, **no se cambia el valor esperado**: se compara el motor con el Step 6 (orden de `random.next()`, `round()`, condición de fin) hasta encontrar la diferencia.

- [ ] **Step 8: Comprobar que la regla de arquitectura cubre `domain/combat/`**

`violations(folder: 'lib/layers/domain', …)` recorre la carpeta de forma recursiva, así que `combat/` ya está cubierta. Para verlo:
1. añade temporalmente `import 'package:flutter/foundation.dart';` al principio de `combat.dart`;
2. `flutter test test/architecture_test.dart` → Expected: FAIL en `testWhenCheckingDomainThenItImportsNothingFromDataPresentationOrPlatforms`, con `lib/layers/domain/combat/combat.dart -> package:flutter/foundation.dart`;
3. quita el import y repite → Expected: PASS.

- [ ] **Step 9: Verificación completa**

```bash
dart format --line-length 120 lib/core/config/constants/enum/fight_advice.dart lib/layers/domain/combat/combat.dart lib/layers/domain/rules/rules.dart test/layers/domain/combat/combat_test.dart test/mocks/domain/entities/hero/combat_stats_entity_mock.dart test/mocks/domain/entities/combat
flutter analyze
flutter test
```

Expected: `No issues found!` y todos los tests en verde.

- [ ] **Step 10: Commit**

```bash
git add lib/core/config/constants/enum/fight_advice.dart lib/layers/domain/combat lib/layers/domain/rules/rules.dart test/layers/domain/combat test/mocks/domain/entities/hero/combat_stats_entity_mock.dart test/mocks/domain/entities/combat
git commit -m "[PROJECT-X]: Resolve arena fights with a seeded combat engine"
```

---

### Task TC1.2: Niveles de la arena y sus reglas

**Files:**
- Create:
  - `lib/layers/domain/rules/arena_levels.dart`
  - `lib/layers/domain/world/extensions/arena_rules.dart`
  - `test/layers/domain/rules/arena_levels_test.dart`
  - `test/layers/domain/world/extensions/arena_rules_test.dart`
- Modify:
  - `lib/layers/domain/rules/rules.dart`: `repeatRewardDivisor` al final.
  - Mocks (se amplían): `test/mocks/domain/entities/hero/hero_entity_mock.dart`, `test/mocks/domain/entities/combat/arena_level_entity_mock.dart`, `test/mocks/domain/world/funds_mock.dart`.

**Interfaces:**
- Consumes (de C0): `ArenaLevelEntity`, `EnemyEntity`, `CombatStatsEntity`, `HeroEntity` (`clearedLevels`, `fightsFought`, `copyWith`), `FightLogEntity` (`levelId`, `isVictory`), `ArenaLevelId`, `EnemyKind`, `Resource.gold`.
- Produces:
  ```dart
  // lib/layers/domain/rules/rules.dart (al final)
  static const int repeatRewardDivisor = 3;

  // lib/layers/domain/rules/arena_levels.dart
  abstract final class ArenaLevels {
    static const List<ArenaLevelEntity> all;          // el orden de la lista es el orden de juego
    static ArenaLevelEntity byId(ArenaLevelId id);
  }

  // lib/layers/domain/world/extensions/arena_rules.dart
  extension ArenaRules on HeroEntity {
    bool isUnlocked(ArenaLevelEntity level);           // el primero siempre; los demás si se ganó el anterior
    bool hasCleared(ArenaLevelId id);
    Map<Resource, int> rewardFor(ArenaLevelEntity level);   // completo la 1.ª vez; luego ~/ 3, sin ceros
    HeroEntity afterFight(FightLogEntity log);         // fightsFought + 1 y, si ganó, el nivel en clearedLevels
  }

  // mocks nuevos
  HeroEntityMock.afterFirstVictory / .afterFirstDefeat / .veteranAfterAnotherFight
  ArenaLevelEntityMock.banditRookieWithWood
  FundsMock.threeGold
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-c1-levels
```

- [ ] **Step 2: Ampliar los datos de prueba**

En `test/mocks/domain/entities/hero/hero_entity_mock.dart`, al final de la clase:

```dart
  static const HeroEntity afterFirstVictory = HeroEntity(clearedLevels: {ArenaLevelId.banditRookie}, fightsFought: 1);

  static const HeroEntity afterFirstDefeat = HeroEntity(fightsFought: 1);

  static const HeroEntity veteranAfterAnotherFight = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie},
    fightsFought: 4,
  );
```

En `test/mocks/domain/entities/combat/arena_level_entity_mock.dart`, al final de la clase:

```dart
  static const ArenaLevelEntity banditRookieWithWood = ArenaLevelEntity(
    id: ArenaLevelId.banditRookie,
    enemies: [EnemyEntityMock.bandit],
    reward: {Resource.wood: 2, Resource.gold: 10},
  );
```

En `test/mocks/domain/world/funds_mock.dart`, al final de la clase:

```dart
  static const Map<Resource, int> threeGold = {Resource.gold: 3};
```

- [ ] **Step 3: Escribir los tests que fallan**

`test/layers/domain/rules/arena_levels_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';

void main() {
  test('testWhenListingLevelsThenEveryArenaLevelIdAppearsOnce', () {
    // given
    final ids = ArenaLevels.all.map((level) => level.id).toList();

    // when
    final unique = ids.toSet();

    // then
    expect(ids, hasLength(ArenaLevelId.values.length));
    expect(unique, ArenaLevelId.values.toSet());
  });

  test('testWhenListingLevelsThenEachOneHasBetweenOneAndThreeEnemies', () {
    for (final level in ArenaLevels.all) {
      // given
      final enemies = level.enemies;

      // when
      final count = enemies.length;

      // then
      expect(count, inInclusiveRange(1, 3), reason: '${level.id}');
    }
  });

  test('testWhenListingLevelsThenEachOnePaysSomeGold', () {
    for (final level in ArenaLevels.all) {
      // given
      final reward = level.reward;

      // when
      final gold = reward[Resource.gold] ?? 0;

      // then
      expect(gold, greaterThan(0), reason: '${level.id}');
    }
  });

  test('testWhenListingLevelsThenTheRookieBanditOpensTheArena', () {
    // given
    final levels = ArenaLevels.all;

    // when
    final first = levels.first.id;

    // then
    expect(first, ArenaLevelId.banditRookie);
  });

  test('testWhenFindingByIdThenItReturnsThatLevel', () {
    // given
    const id = ArenaLevelId.barbarianChief;

    // when
    final level = ArenaLevels.byId(id);

    // then
    expect((level.id, level.enemies.length, level.power), (ArenaLevelId.barbarianChief, 3, 173));
  });
}
```

`test/layers/domain/world/extensions/arena_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/world/extensions/arena_rules.dart';

import '../../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';
import '../../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  group('isUnlocked', () {
    test('testWhenTheHeroIsNewThenOnlyTheFirstLevelIsUnlocked', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final unlocked = ArenaLevels.all.where(hero.isUnlocked).map((level) => level.id);

      // then
      expect(unlocked, [ArenaLevels.all.first.id]);
    });

    test('testWhenTheHeroClearedTheFirstLevelThenTheSecondIsUnlockedButNotTheThird', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final unlocked = (hero.isUnlocked(ArenaLevels.all[1]), hero.isUnlocked(ArenaLevels.all[2]));

      // then
      expect(unlocked, (true, false));
    });
  });

  group('hasCleared', () {
    test('testWhenTheHeroWonALevelThenItHasClearedItAndNoOther', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final cleared = (hero.hasCleared(ArenaLevelId.banditRookie), hero.hasCleared(ArenaLevelId.banditVeteran));

      // then
      expect(cleared, (true, false));
    });
  });

  group('rewardFor', () {
    test('testWhenTheLevelIsNotClearedThenTheRewardIsComplete', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final reward = hero.rewardFor(ArenaLevelEntityMock.banditRookie);

      // then
      expect(reward, FundsMock.tenGold);
    });

    test('testWhenTheLevelIsClearedThenTheRewardIsAThird', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final reward = hero.rewardFor(ArenaLevelEntityMock.banditRookie);

      // then
      expect(reward, FundsMock.threeGold);
    });

    test('testWhenARepeatedRewardRoundsToZeroThenThatResourceIsDropped', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final reward = hero.rewardFor(ArenaLevelEntityMock.banditRookieWithWood);

      // then
      expect(reward, FundsMock.threeGold);
    });
  });

  group('afterFight', () {
    test('testWhenTheHeroWinsThenTheLevelIsClearedAndTheFightCounted', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final after = hero.afterFight(FightLogEntityMock.victoryOverBandit());

      // then
      expect(after, HeroEntityMock.afterFirstVictory);
    });

    test('testWhenTheHeroLosesThenOnlyTheFightIsCounted', () {
      // given
      const hero = HeroEntityMock.mock;

      // when
      final after = hero.afterFight(FightLogEntityMock.defeatByBrute());

      // then
      expect(after, HeroEntityMock.afterFirstDefeat);
    });

    test('testWhenTheHeroWinsAClearedLevelAgainThenOnlyTheFightIsCounted', () {
      // given
      const hero = HeroEntityMock.veteran;

      // when
      final after = hero.afterFight(FightLogEntityMock.victoryOverBandit());

      // then
      expect(after, HeroEntityMock.veteranAfterAnotherFight);
    });
  });
}
```

- [ ] **Step 4: Ver que fallan**

Run: `flutter test test/layers/domain/rules/arena_levels_test.dart test/layers/domain/world/extensions/arena_rules_test.dart`
Expected: FAIL al compilar (`ArenaLevels`, `ArenaRules` y los mocks nuevos no existen).

- [ ] **Step 5: Implementar `ArenaLevels`, `Rules.repeatRewardDivisor` y `ArenaRules`**

En `lib/layers/domain/rules/rules.dart`, al final de la clase:

```dart
  static const int repeatRewardDivisor = 3;
```

`lib/layers/domain/rules/arena_levels.dart` (valores orientativos de la ficha; C7 los equilibra):

```dart
import '../../../core/config/constants/enum/arena_level_id.dart';
import '../../../core/config/constants/enum/enemy_kind.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/combat/arena_level_entity.dart';
import '../entities/combat/enemy_entity.dart';
import '../entities/hero/combat_stats_entity.dart';

abstract final class ArenaLevels {
  static const List<ArenaLevelEntity> all = [
    ArenaLevelEntity(
      id: ArenaLevelId.banditRookie,
      enemies: [
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 3, defense: 0, health: 20)),
      ],
      reward: {Resource.gold: 10},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.banditVeteran,
      enemies: [
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
      ],
      reward: {Resource.gold: 20},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.banditTrio,
      enemies: [
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
      ],
      reward: {Resource.gold: 40},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.barbarian,
      enemies: [
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 12, defense: 4, health: 60)),
      ],
      reward: {Resource.gold: 50},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.barbarianPair,
      enemies: [
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 9, defense: 4, health: 50)),
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 9, defense: 4, health: 50)),
      ],
      reward: {Resource.gold: 65},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.barbarianChief,
      enemies: [
        EnemyEntity(kind: EnemyKind.barbarianChief, stats: CombatStatsEntity(attack: 12, defense: 5, health: 70)),
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
      ],
      reward: {Resource.gold: 100},
    ),
  ];

  static ArenaLevelEntity byId(ArenaLevelId id) => all.firstWhere((level) => level.id == id);
}
```

`lib/layers/domain/world/extensions/arena_rules.dart`:

```dart
import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import '../../entities/combat/arena_level_entity.dart';
import '../../entities/combat/fight_log_entity.dart';
import '../../entities/hero/hero_entity.dart';
import '../../rules/arena_levels.dart';
import '../../rules/rules.dart';

extension ArenaRules on HeroEntity {
  bool isUnlocked(ArenaLevelEntity level) {
    final index = ArenaLevels.all.indexWhere((candidate) => candidate.id == level.id);
    if (index < 0) return false;
    return index == 0 || hasCleared(ArenaLevels.all[index - 1].id);
  }

  bool hasCleared(ArenaLevelId id) => clearedLevels.contains(id);

  Map<Resource, int> rewardFor(ArenaLevelEntity level) {
    if (!hasCleared(level.id)) return level.reward;
    return {
      for (final MapEntry(key: resource, value: amount) in level.reward.entries)
        if (amount ~/ Rules.repeatRewardDivisor > 0) resource: amount ~/ Rules.repeatRewardDivisor,
    };
  }

  HeroEntity afterFight(FightLogEntity log) => copyWith(
    clearedLevels: log.isVictory ? {...clearedLevels, log.levelId} : clearedLevels,
    fightsFought: fightsFought + 1,
  );
}
```

- [ ] **Step 6: Ver que pasan**

Run: `flutter test test/layers/domain/rules/arena_levels_test.dart test/layers/domain/world/extensions/arena_rules_test.dart`
Expected: PASS (14 tests).

- [ ] **Step 7: Verificación completa**

```bash
dart format --line-length 120 lib/layers/domain/rules/arena_levels.dart lib/layers/domain/rules/rules.dart lib/layers/domain/world/extensions/arena_rules.dart test/layers/domain/rules/arena_levels_test.dart test/layers/domain/world/extensions/arena_rules_test.dart test/mocks/domain/entities/hero/hero_entity_mock.dart test/mocks/domain/entities/combat/arena_level_entity_mock.dart test/mocks/domain/world/funds_mock.dart
flutter analyze
flutter test
```

Expected: `No issues found!` y todos los tests en verde. Si TC1.1 se fusionó antes, `rules.dart` tiene sus ocho constantes y `repeatRewardDivisor` va después; si hay conflicto al fusionar, se conservan las dos tandas.

- [ ] **Step 8: Commit**

```bash
git add lib/layers/domain/rules/arena_levels.dart lib/layers/domain/rules/rules.dart lib/layers/domain/world/extensions/arena_rules.dart test/layers/domain/rules/arena_levels_test.dart test/layers/domain/world/extensions/arena_rules_test.dart test/mocks/domain/entities/hero/hero_entity_mock.dart test/mocks/domain/entities/combat/arena_level_entity_mock.dart test/mocks/domain/world/funds_mock.dart
git commit -m "[PROJECT-X]: Add the arena levels and their unlock and reward rules"
```

---

### Task TC1.3: Casos de uso de la arena y test de flujo

**Files:**
- Create:
  - Entidades (`lib/layers/domain/entities/combat/`): `arena_level_status_entity.dart`, `arena_entity.dart`, `fight_result_entity.dart`.
  - Casos de uso (`lib/layers/domain/use-cases/arena/`): `get_arena_use_case.dart`, `start_fight_use_case.dart`.
  - Tests (en `test/`):
    - `layers/domain/entities/combat/arena_level_status_entity_test.dart`, `arena_entity_test.dart`, `fight_result_entity_test.dart`;
    - `layers/domain/use-cases/arena/get_arena_use_case_test.dart`, `start_fight_use_case_test.dart`, `arena_flow_test.dart`;
    - mocks `mocks/domain/entities/combat/arena_level_status_entity_mock.dart`, `arena_entity_mock.dart`, `fight_result_entity_mock.dart`.
- Modify:
  - `lib/core/config/di/di.config.dart`: regenerado.
  - `test/core/config/di/di_test.dart`: los dos casos de uso nuevos.
  - `CLAUDE.md`: *Architecture*.

**Interfaces:**
- Consumes: `Combat.resolve` / `adviceFor`, `FightAdvice` (TC1.1); `ArenaLevels`, `ArenaRules` (TC1.2); `HeroRules.stats` / `power`, `World.hero` / `updateHero` / `earn` / `funds`, `GameSessionRepository.current()` (C0 y anteriores).
- Produces:
  ```dart
  // entities/combat
  ArenaLevelStatusEntity({required ArenaLevelEntity level, required bool isUnlocked, required bool isCleared,
                          required Map<Resource, int> nextReward});            // copyWith
  ArenaEntity({required int heroPower, required List<ArenaLevelStatusEntity> levels});   // copyWith
  sealed class FightResultEntity;
  final class FightPlayedEntity extends FightResultEntity { FightPlayedEntity({required FightLogEntity log, FightAdvice? advice}); }
  final class FightLockedEntity extends FightResultEntity { const FightLockedEntity(); }

  // use-cases/arena
  @Injectable() final class GetArenaUseCase { ArenaEntity call(); }
  @Injectable() final class StartFightUseCase { FightResultEntity call({required ArenaLevelId levelId}); }

  // mocks
  ArenaLevelStatusEntityMock.rookieForNewHero / .rookieForVeteran
  ArenaEntityMock.onlyRookie
  FightResultEntityMock.locked / .victoryOverBandit() / .almostBeatDuelist()
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-c1-fights
```

- [ ] **Step 2: Escribir los mocks de las entidades nuevas**

`test/mocks/domain/entities/combat/arena_level_status_entity_mock.dart`. `ArenaLevelEntityMock.banditRookie` es igual al primer nivel de `ArenaLevels.all`:

```dart
import 'package:rpg/layers/domain/entities/combat/arena_level_status_entity.dart';

import '../../world/funds_mock.dart';
import 'arena_level_entity_mock.dart';

abstract final class ArenaLevelStatusEntityMock {
  static const ArenaLevelStatusEntity rookieForNewHero = ArenaLevelStatusEntity(
    level: ArenaLevelEntityMock.banditRookie,
    isUnlocked: true,
    isCleared: false,
    nextReward: FundsMock.tenGold,
  );

  static const ArenaLevelStatusEntity rookieForVeteran = ArenaLevelStatusEntity(
    level: ArenaLevelEntityMock.banditRookie,
    isUnlocked: true,
    isCleared: true,
    nextReward: FundsMock.threeGold,
  );
}
```

`test/mocks/domain/entities/combat/arena_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/combat/arena_entity.dart';

import 'arena_level_status_entity_mock.dart';

abstract final class ArenaEntityMock {
  static const ArenaEntity onlyRookie = ArenaEntity(
    heroPower: 31,
    levels: [ArenaLevelStatusEntityMock.rookieForNewHero],
  );
}
```

`test/mocks/domain/entities/combat/fight_result_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';

import 'fight_log_entity_mock.dart';

abstract final class FightResultEntityMock {
  static const FightLockedEntity locked = FightLockedEntity();

  static FightPlayedEntity victoryOverBandit() => FightPlayedEntity(log: FightLogEntityMock.victoryOverBandit());

  static FightPlayedEntity almostBeatDuelist() =>
      FightPlayedEntity(log: FightLogEntityMock.almostBeatDuelist(), advice: FightAdvice.almostThere);
}
```

- [ ] **Step 3: Escribir los tests de entidades que fallan**

`test/layers/domain/entities/combat/arena_level_status_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/arena_level_status_entity_mock.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  test('testWhenCopyingWithClearedAndAThirdOfTheRewardThenTheLevelIsKept', () {
    // given
    const status = ArenaLevelStatusEntityMock.rookieForNewHero;

    // when
    final copy = status.copyWith(isCleared: true, nextReward: FundsMock.threeGold);

    // then
    expect(copy, ArenaLevelStatusEntityMock.rookieForVeteran);
    expect(copy.hashCode, ArenaLevelStatusEntityMock.rookieForVeteran.hashCode);
  });
}
```

`test/layers/domain/entities/combat/arena_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/arena_entity_mock.dart';
import '../../../../mocks/domain/entities/combat/arena_level_status_entity_mock.dart';

void main() {
  test('testWhenCopyingWithTheSameLevelsThenTheArenaIsEqual', () {
    // given
    const arena = ArenaEntityMock.onlyRookie;

    // when
    final copy = arena.copyWith(levels: [ArenaLevelStatusEntityMock.rookieForNewHero]);

    // then
    expect(copy, arena);
    expect(copy.hashCode, arena.hashCode);
  });

  test('testWhenALevelStatusDiffersThenTheArenasAreNotEqual', () {
    // given
    const arena = ArenaEntityMock.onlyRookie;

    // when
    final copy = arena.copyWith(levels: [ArenaLevelStatusEntityMock.rookieForVeteran]);

    // then
    expect(copy == arena, isFalse);
  });
}
```

`test/layers/domain/entities/combat/fight_result_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';

import '../../../../mocks/domain/entities/combat/fight_result_entity_mock.dart';

void main() {
  test('testWhenTwoPlayedFightsHaveTheSameLogAndAdviceThenTheyAreEqual', () {
    // given
    final result = FightResultEntityMock.almostBeatDuelist();

    // when
    final other = FightResultEntityMock.almostBeatDuelist();

    // then
    expect(other, result);
    expect(other.hashCode, result.hashCode);
  });

  test('testWhenTheLogsDifferThenThePlayedFightsAreNotEqual', () {
    // given
    final result = FightResultEntityMock.victoryOverBandit();

    // when
    final equal = result == FightResultEntityMock.almostBeatDuelist();

    // then
    expect(equal, isFalse);
  });

  test('testWhenComparingALockedFightWithAPlayedOneThenTheyAreNotEqual', () {
    // given
    const FightResultEntity locked = FightResultEntityMock.locked;

    // when
    final equal = locked == FightResultEntityMock.victoryOverBandit();

    // then
    expect(equal, isFalse);
    expect(locked, FightResultEntityMock.locked);
  });
}
```

Run: `flutter test test/layers/domain/entities/combat`
Expected: FAIL al compilar (las tres entidades no existen).

- [ ] **Step 4: Implementar las entidades**

`lib/layers/domain/entities/combat/arena_level_status_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import 'arena_level_entity.dart';

class ArenaLevelStatusEntity {
  final ArenaLevelEntity level;
  final bool isUnlocked;
  final bool isCleared;
  final Map<Resource, int> nextReward;

  const ArenaLevelStatusEntity({
    required this.level,
    required this.isUnlocked,
    required this.isCleared,
    required this.nextReward,
  });

  ArenaLevelStatusEntity copyWith({
    ArenaLevelEntity? level,
    bool? isUnlocked,
    bool? isCleared,
    Map<Resource, int>? nextReward,
  }) {
    return ArenaLevelStatusEntity(
      level: level ?? this.level,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCleared: isCleared ?? this.isCleared,
      nextReward: nextReward ?? this.nextReward,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaLevelStatusEntity &&
      other.level == level &&
      other.isUnlocked == isUnlocked &&
      other.isCleared == isCleared &&
      const MapEquality<Resource, int>().equals(other.nextReward, nextReward);

  @override
  int get hashCode =>
      Object.hash(level, isUnlocked, isCleared, const MapEquality<Resource, int>().hash(nextReward));
}
```

`lib/layers/domain/entities/combat/arena_entity.dart`:

```dart
import 'package:collection/collection.dart';

import 'arena_level_status_entity.dart';

class ArenaEntity {
  final int heroPower;
  final List<ArenaLevelStatusEntity> levels;

  const ArenaEntity({required this.heroPower, required this.levels});

  ArenaEntity copyWith({int? heroPower, List<ArenaLevelStatusEntity>? levels}) {
    return ArenaEntity(heroPower: heroPower ?? this.heroPower, levels: levels ?? this.levels);
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaEntity &&
      other.heroPower == heroPower &&
      const ListEquality<ArenaLevelStatusEntity>().equals(other.levels, levels);

  @override
  int get hashCode => Object.hash(heroPower, const ListEquality<ArenaLevelStatusEntity>().hash(levels));
}
```

`lib/layers/domain/entities/combat/fight_result_entity.dart` (E8: la jerarquía entera en un fichero):

```dart
import '../../../../core/config/constants/enum/fight_advice.dart';
import 'fight_log_entity.dart';

sealed class FightResultEntity {
  const FightResultEntity();
}

final class FightPlayedEntity extends FightResultEntity {
  final FightLogEntity log;
  final FightAdvice? advice;

  const FightPlayedEntity({required this.log, this.advice});

  @override
  bool operator ==(Object other) => other is FightPlayedEntity && other.log == log && other.advice == advice;

  @override
  int get hashCode => Object.hash(FightPlayedEntity, log, advice);
}

final class FightLockedEntity extends FightResultEntity {
  const FightLockedEntity();

  @override
  bool operator ==(Object other) => other is FightLockedEntity;

  @override
  int get hashCode => (FightLockedEntity).hashCode;
}
```

Run: `flutter test test/layers/domain/entities/combat test/architecture_test.dart`
Expected: PASS (las entidades no tienen campos mutables).

- [ ] **Step 5: Tests de los casos de uso que fallan**

`test/layers/domain/use-cases/arena/get_arena_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/entities/combat/arena_level_status_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetArenaUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetArenaUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenTheHeroIsNewThenEveryLevelIsListedAndOnlyTheFirstIsOpen', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock)));

    // when
    final arena = sut();

    // then
    expect(arena.heroPower, 31);
    expect(arena.levels.map((status) => status.level), ArenaLevels.all);
    expect(arena.levels.first, ArenaLevelStatusEntityMock.rookieForNewHero);
    expect(arena.levels.where((status) => status.isUnlocked).map((status) => status.level.id), [
      ArenaLevels.all.first.id,
    ]);
    expect(arena.levels.where((status) => status.isCleared), isEmpty);
  });

  test('testWhenTheHeroClearedTheFirstLevelThenItPaysAThirdAndOpensTheSecond', () {
    // given
    when(
      sessionRepository.current(),
    ).thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.veteran)));

    // when
    final arena = sut();

    // then
    expect(arena.levels.first, ArenaLevelStatusEntityMock.rookieForVeteran);
    expect(arena.levels.where((status) => status.isUnlocked).map((status) => status.level.id), [
      ArenaLevels.all[0].id,
      ArenaLevels.all[1].id,
    ]);
    expect(arena.levels.where((status) => status.isCleared).map((status) => status.level.id), [
      ArenaLevelId.banditRookie,
    ]);
  });
}
```

`test/layers/domain/use-cases/arena/start_fight_use_case_test.dart`. Las semillas son `hero.fightsFought`: 0 para `HeroEntityMock.mock` y 3 para `HeroEntityMock.veteran` (ver *Resultados dorados*):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/entities/combat/fight_result_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/funds_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late StartFightUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = StartFightUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut(levelId: ArenaLevelId.banditRookie);

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenTheLevelIsLockedThenTheFightIsRefusedAndNothingChanges', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditVeteran);

    // then
    expect(result, FightResultEntityMock.locked);
    expect(session.world.hero, HeroEntityMock.mock);
    expect(session.world.funds.amount(Resource.gold), 0);
  });

  test('testWhenTheHeroWinsALevelForTheFirstTimeThenItIsPaidInFullAndCleared', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditRookie);

    // then
    expect(result, FightResultEntityMock.victoryOverBandit());
    expect(session.world.funds.amount(Resource.gold), 10);
    expect(session.world.hero, HeroEntityMock.afterFirstVictory);
  });

  test('testWhenTheHeroWinsAClearedLevelAgainThenItIsPaidAThird', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.veteran));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditRookie);

    // then
    final played = result as FightPlayedEntity;
    expect((played.log.isVictory, played.log.rounds, played.advice), (true, 6, null));
    expect(played.log.reward, FundsMock.threeGold);
    expect(session.world.funds.amount(Resource.gold), 3);
    expect(session.world.hero, HeroEntityMock.veteranAfterAnotherFight);
  });

  test('testWhenTheHeroLosesThenNothingIsPaidAndAdviceIsGiven', () {
    // given
    final session = GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.veteran));
    when(sessionRepository.current()).thenReturn(session);

    // when
    final result = sut(levelId: ArenaLevelId.banditVeteran);

    // then
    final played = result as FightPlayedEntity;
    expect((played.log.isVictory, played.log.rounds, played.advice), (false, 6, FightAdvice.needAttack));
    expect(played.log.reward, isEmpty);
    expect(session.world.funds.amount(Resource.gold), 0);
    expect(session.world.hero, HeroEntityMock.veteranAfterAnotherFight);
  });
}
```

`test/layers/domain/use-cases/arena/arena_flow_test.dart`. Usa los casos de uso reales sobre `MockGameSessionRepository`, como `game_flow_test.dart`. Con el catálogo de TC1.2 el oro esperado es 10 + 20 + 40 + 50 + 65 + 100 = 285; se calcula desde `ArenaLevels.all` para que C4 (niveles nuevos) no tenga que cambiar la suma, sólo comprobar que sigue ganando:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../../mocks/domain/entities/combat/fight_result_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late StartFightUseCase startFight;
  late GetArenaUseCase getArena;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    startFight = StartFightUseCase(sessionRepository: sessionRepository);
    getArena = GetArenaUseCase(sessionRepository: sessionRepository);
  });

  GameSessionEntity playingWith(HeroEntity hero) {
    final session = GameSessionEntityMock.playing(WorldMock.withHero(hero));
    when(sessionRepository.current()).thenReturn(session);
    return session;
  }

  test('testWhenAFullyGearedHeroFightsEveryLevelInOrderThenItClearsTheWholeArena', () {
    // given
    final session = playingWith(HeroEntityMock.fullyGeared);
    final expectedGold = ArenaLevels.all.fold(0, (sum, level) => sum + (level.reward[Resource.gold] ?? 0));

    // when
    final results = [for (final level in ArenaLevels.all) startFight(levelId: level.id)];

    // then
    expect(results.every((result) => result is FightPlayedEntity && result.log.isVictory), isTrue);
    expect(session.world.funds.amount(Resource.gold), expectedGold);
    expect(session.world.hero.clearedLevels, ArenaLevels.all.map((level) => level.id).toSet());
    expect(session.world.hero.fightsFought, ArenaLevels.all.length);
    expect(getArena().levels.every((status) => status.isUnlocked && status.isCleared), isTrue);
  });

  test('testWhenTheArenaIsClearedThenReplayingTheFirstLevelPaysAThird', () {
    // given
    final session = playingWith(HeroEntityMock.fullyGeared);
    for (final level in ArenaLevels.all) {
      startFight(levelId: level.id);
    }
    final goldBefore = session.world.funds.amount(Resource.gold);

    // when
    final result = startFight(levelId: ArenaLevelId.banditRookie);

    // then
    expect(result is FightPlayedEntity && result.log.isVictory, isTrue);
    expect(session.world.funds.amount(Resource.gold), goldBefore + 3);
  });

  test('testWhenANewHeroTriesTheLastLevelThenItIsLockedAndNothingChanges', () {
    // given
    final session = playingWith(HeroEntityMock.mock);

    // when
    final result = startFight(levelId: ArenaLevels.all.last.id);

    // then
    expect(result, FightResultEntityMock.locked);
    expect(session.world.hero, HeroEntityMock.mock);
  });
}
```

Run: `flutter test test/layers/domain/use-cases/arena`
Expected: FAIL al compilar (los casos de uso no existen).

- [ ] **Step 6: Implementar los casos de uso**

`lib/layers/domain/use-cases/arena/get_arena_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../entities/combat/arena_entity.dart';
import '../../entities/combat/arena_level_status_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/arena_levels.dart';
import '../../world/extensions/arena_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class GetArenaUseCase {
  final GameSessionRepository _sessionRepository;

  const GetArenaUseCase({required this._sessionRepository});

  ArenaEntity call() {
    final hero = _sessionRepository.current().world.hero;
    return ArenaEntity(
      heroPower: hero.power,
      levels: [
        for (final level in ArenaLevels.all)
          ArenaLevelStatusEntity(
            level: level,
            isUnlocked: hero.isUnlocked(level),
            isCleared: hero.hasCleared(level.id),
            nextReward: hero.rewardFor(level),
          ),
      ],
    );
  }
}
```

`lib/layers/domain/use-cases/arena/start_fight_use_case.dart`. La recompensa se calcula **antes** de `afterFight`; si no, una primera victoria cobraría ya un tercio:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../combat/combat.dart';
import '../../entities/combat/fight_result_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/arena_levels.dart';
import '../../world/extensions/arena_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class StartFightUseCase {
  final GameSessionRepository _sessionRepository;

  const StartFightUseCase({required this._sessionRepository});

  FightResultEntity call({required ArenaLevelId levelId}) {
    final world = _sessionRepository.current().world;
    final hero = world.hero;
    final level = ArenaLevels.byId(levelId);
    if (!hero.isUnlocked(level)) return const FightLockedEntity();
    final fight = Combat.resolve(level: level, heroStats: hero.stats, skills: hero.skills, seed: hero.fightsFought);
    final log = fight.isVictory ? fight.copyWith(reward: hero.rewardFor(level)) : fight;
    if (log.isVictory) world.earn(log.reward);
    world.updateHero((current) => current.afterFight(log));
    return FightPlayedEntity(log: log, advice: Combat.adviceFor(log));
  }
}
```

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/layers/domain/use-cases/arena
```

Expected: PASS (11 tests); `di.config.dart` registra `GetArenaUseCase` y `StartFightUseCase`.

- [ ] **Step 7: Registrar los casos de uso en el test de DI**

En `test/core/config/di/di_test.dart`, añadir los imports

```dart
import 'package:rpg/layers/domain/use-cases/arena/get_arena_use_case.dart';
import 'package:rpg/layers/domain/use-cases/arena/start_fight_use_case.dart';
```

y, en `testWhenConfiguringDependenciesThenEveryGameDependencyIsRegistered`, después de `locator.isRegistered<GetQuestsUseCase>(),` (y de la línea de `GetHeroStatusUseCase` si C0 la añadió):

```dart
      locator.isRegistered<GetArenaUseCase>(),
      locator.isRegistered<StartFightUseCase>(),
```

Run: `flutter test test/core/config/di/di_test.dart`
Expected: PASS.

- [ ] **Step 8: Comprobar la persistencia del héroe**

```bash
grep -rn "fightsFought\|clearedLevels" lib/layers/data
```

- Sin resultados y sin `HeroDBO` en `lib/layers/data`: F2 aún no está; no hay nada que hacer (F2 guardará el héroe entero, README 3.2).
- Con `HeroDBO` que ya tiene los dos campos: nada que hacer.
- Con `HeroDBO` al que le falta alguno: es una desviación de C0/F2. Se para la tarea, se avisa al otro flujo y se apunta en la sección 5 del README antes de seguir.

- [ ] **Step 9: Documentar en `CLAUDE.md`**

En *Architecture* → `lib/layers/domain/`:
- `entities/<feature>/`: en combat, añadir `ArenaEntity`, `ArenaLevelStatusEntity` y sealed `FightResultEntity` (`FightPlayedEntity` with an optional `FightAdvice`, `FightLockedEntity`).
- Nueva línea `combat/`: "`Combat`, pure functions: `resolve` plays a whole fight with `SeededRandom(hero.fightsFought)` and returns a `FightLogEntity` (the call order of `next()` is part of the contract: one per hit, plus one per enemy attack when the hero can dodge); `adviceFor` reads a lost fight."
- `world/extensions/`: añadir `ArenaRules` (`isUnlocked`, `hasCleared`, `rewardFor`, `afterFight`).
- `rules/`: añadir `ArenaLevels` (the list order is the play order) y las constantes de combate de `Rules`.
- `use-cases/`: añadir `arena/` (`GetArenaUseCase`, `StartFightUseCase`: resolves, pays with `World.earn` and records the fight with `World.updateHero` in one synchronous call).
- E1: comprobar que ya nombra `domain/combat/` (lo hizo C0); si no, añadirlo.
- En *Key cross-cutting conventions*, añadir: "Arena fights are deterministic: same hero and seed, same log; golden tests in `test/layers/domain/combat/combat_test.dart`."

- [ ] **Step 10: Verificación completa**

```bash
dart format --line-length 120 lib/layers/domain/entities/combat/arena_level_status_entity.dart lib/layers/domain/entities/combat/arena_entity.dart lib/layers/domain/entities/combat/fight_result_entity.dart lib/layers/domain/use-cases/arena test/layers/domain/entities/combat test/layers/domain/use-cases/arena test/mocks/domain/entities/combat test/core/config/di/di_test.dart
dart run build_runner build --delete-conflicting-outputs
git diff --stat -- lib/core/config/di/di.config.dart
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: el diff de `di.config.dart` sólo registra `GetArenaUseCase` y `StartFightUseCase`; `No issues found!` y todo en verde.

- [ ] **Step 11: Commit**

```bash
git add lib/layers/domain/entities/combat lib/layers/domain/use-cases/arena lib/core/config/di/di.config.dart test/layers/domain/entities/combat test/layers/domain/use-cases/arena test/mocks/domain/entities/combat test/core/config/di/di_test.dart
git commit -m "[PROJECT-X]: Fight arena levels through use cases that pay and unlock"
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the combat engine and arena use cases in the project guide"
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code
```

Expected: el último comando termina sin salida (lo generado está al día, como exige la CI).

Prueba manual en Chrome, en el emulador Android y en el simulador iOS: el juego se comporta igual que tras C0.

---

## Al cerrar C1

- Marca los checkboxes de las tres tareas.
- Avisa a quien lleve C2: `StartFightUseCase` y `GetArenaUseCase` ya existen; la escena puede dejar `FightLogEntityMock` y usar el registro real.
- Avisa a quien lleve C7: los dorados de `combat_test.dart` no dependen del catálogo, pero `start_fight_use_case_test.dart` (semillas 0 y 3 sobre `banditRookie` y `banditVeteran`) y `arena_flow_test.dart` sí. Si C7 cambia `ArenaLevels.all`, recalcula esos resultados con el motor.
- C4 inserta niveles en `ArenaLevels.all`: cambian las semillas del test de flujo (una por pelea), así que C4 vuelve a comprobar que el héroe con todo el equipo gana todos los niveles.
- Si alguna firma de *Interfaces* cambió al implementar, actualízala en este fichero **y** en las fichas de C2, C4, C6 y C7, y apúntalo en la sección 5 del README.
