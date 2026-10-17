# C11 · Habilidades de los enemigos — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (arena) |
| **Rama** | `feature/PROJECT-C11-enemy-skills`, desde `feature/PROJECT-C10-no-skip` (C9 y C10 dentro) |
| **Issue / milestone** | `phase:C11` · milestone `C11 Enemy skills` · #58 |
| **Depende de** | C10 (la repetición) y C9 |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-arena/C11-enemy-skills.md`, merge `283d176`, commits `d82c751` (combate) y `80eda2b` (repetición) |

**Goal:** Desde *Tres bandidos* (nivel 6 del orden de juego) los enemigos usan la habilidad propia de su tipo, con una probabilidad que sube por nivel, y la repetición lo enseña igual que las habilidades del héroe.

**Architecture:** Dominio: `ArenaLevelEntity.enemySkillChance` (0 por defecto; solo la ponen los niveles 6–10 de `ArenaLevels`), `EnemyKindRules.skills` (extensión nueva en `domain/world/extensions/`) y `Combat.resolve` con las tiradas del enemigo en un orden fijo, detrás de guardas que no se cumplen con probabilidad 0. `FightTurnEntity`/`FightAction` no cambian. Presentación: `SkillUsedEffect` gana `side` e `index`, `ArenaBloc` lo emite con el actor del turno y `ArenaSceneComponent` pinta el nombre sobre ese luchador. Ni datos, ni DI, ni casos de uso, ni textos.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario, 2026-10-17):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar o cambien de resultado están listados en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, tras C12.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Mientras `test/` no compila no se usa `flutter analyze` a secas.
- **Determinismo:** las tiradas nuevas usan el mismo `SeededRandom` del combate, en el orden de la decisión 3. Nunca se reordena ni se quita una tirada existente y nunca se tira un dado nuevo si la probabilidad del nivel es 0 o el tipo no tiene la habilidad: los niveles 1–5 (y cualquier `ArenaLevelEntity` sin `enemySkillChance`) dan exactamente los mismos `FightLogEntity` que antes.
- Enums sin valores nuevos (`FightAction`, `FightSide`, `EnemyKind`, `SkillId`); `switch` exhaustivos en el orden de declaración.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-C11]: <frase en inglés en imperativo>`.
- No se tocan `di.config.dart` ni `*.mocks.dart` (C11 no cambia DI).

## Decisiones

Las de la ficha (reglas del usuario, 2026-10-15/16), ya aplicadas en iOS:

1. **Habilidades por tipo:** `EnemyKindRules.skills` (`domain/world/extensions/enemy_kind_rules.dart`, junto a `HeroRules`), un `Set<SkillId>` que reutiliza las tres habilidades del héroe con los mismos efectos (`Rules.secondWindThreshold`, `Rules.secondWindHeal`):

   | Tipo | Habilidades |
   |---|---|
   | `bandit`, `banditVeteran` | *Esquiva* (el veterano está en el nivel 3, sin probabilidad) |
   | `barbarian`, `wolf`, `bear` | *Golpe doble* |
   | `barbarianChief` | *Golpe doble* + *Segundo aliento* |

2. **Probabilidad por nivel:** `ArenaLevelEntity.enemySkillChance` (`double` en `0..1` con `assert`, por defecto `0`, también en `copyWith`, `==` y `hashCode`). Solo la pone `ArenaLevels` en los niveles 6–10: **0,015 / 0,02 / 0,025 / 0,03 / 0,035** (`banditTrio`, `barbarian`, `wolfPack`, `barbarianPair`, `barbarianChief`). No va en `Rules` porque depende del nivel.
3. **Orden de las tiradas** (todas con el `SeededRandom` del combate). Un dado de X solo existe si `enemySkillChance > 0` **y** el tipo tiene X, y sale si `random.next() < enemySkillChance` (`_enemyRolls`):
   - **Golpe del héroe** (el normal y el de su *Golpe doble*) al primer enemigo vivo `t`: (a) dado de *Esquiva* de `t`; si sale, turno del héroe hacia `t` con `FightAction.dodge`, daño 0, vida sin cambiar y **sin** dado de daño; (b) si no, dado de daño como siempre; (c) después del golpe, si `t` tiene *Segundo aliento*, no lo ha tirado aún, sigue vivo y quedó por debajo de `Rules.secondWindThreshold` de su vida máxima, se marca como tirado y se tira el dado; si sale, se cura `Rules.secondWindHeal` de su vida máxima (`round()`, sin pasar del máximo) con un turno `secondWind` del enemigo sobre sí mismo.
   - **Ataque del enemigo `i`** (vivo y con el héroe en pie, como antes): (a) su golpe normal igual que antes (dado de *Esquiva* del héroe si la tiene, dado de daño); (b) el *Segundo aliento* del héroe igual que antes; (c) si el héroe sigue en pie, dado de *Golpe doble* de `i`; si sale, un segundo golpe con acción `doubleStrike` que repite (a) y (b).
4. **Sin casos nuevos en `FightAction`:** la esquiva del enemigo es un turno del héroe con `dodge` hacia ese enemigo; el *Segundo aliento* del jefe, un turno del enemigo sobre sí mismo; un golpe doble esquivado queda como `dodge` (se ve *¡Esquiva!*, no el nombre del golpe). `FightReplayData`, las poses y los efectos `DodgeEffect`/`HealEffect` (que ya llevan bando e índice del objetivo) funcionan sin cambios.
5. ***Segundo aliento* del jefe: una sola tirada por pelea**, la primera vez que queda por debajo del umbral tras un golpe del héroe (si muere de ese golpe no hay tirada). Si falla no se vuelve a tirar.
6. **Consejo tras perder:** `Combat.adviceFor` no cuenta los golpes del héroe esquivados (`dodge`) en el daño medio.
7. **Presentación:** `SkillUsedEffect({skill, side, index})`. `ArenaBloc._effectsFor` lo emite para `doubleStrike` y `secondWind` de **cualquier** actor con `side: turn.actor, index: turn.actorIndex`. `ArenaSceneComponent._floatSkillName` busca el luchador por bando e índice y pinta el nombre (`Internationalize.arenaSkillUsed`) a la misma altura sobre su cabeza (`ArenaRenderConstants.skillNameLift`). Sin textos nuevos. (La ficha decía `arena_state_listener.dart`; los efectos se pintan en `arena_scene_component.dart`, que es donde se cambia.)
8. **Equilibrado** (regla del test de balance + ≥ 60 % también con las semillas 0–999). Medido con el dominio real de esta rama (programa temporal fuera del repo, mismo `BalanceScenarioMock`); coincide **exactamente** con iOS:

   | Nivel | Prob. | Victorias 0–99 | Victorias 0–999 | Un paso por detrás 0–99 | Golpes dobles del enemigo (100 peleas) | Esquivas del enemigo (100 peleas) | Peleas con *Segundo aliento* del jefe (0–99) |
   |---|---|---|---|---|---|---|---|
   | 1–5 | 0 | 100 / 86 / 77 / 84 / 79 % | 100 / 92,7 / 83,9 / 90,2 / 85,0 % | 0 % (3–5) | — | — | — |
   | 6 *Tres bandidos* | 1,5 % | 89,0 % | 86,6 % | 0,0 % | — | 12 de 931 golpes del héroe | — |
   | 7 *Bárbaro* | 2 % | 73,0 % | 75,1 % | 6,0 % | 16 de 732 | — | — |
   | 8 *Manada de tres lobos* | 2,5 % | 78,0 % | 71,9 % | 15,0 % | 18 de 1210 | — | — |
   | 9 *Dos bárbaros* | 3 % | 79,0 % | 74,0 % | 2,0 % | 23 de 1184 | — | — |
   | 10 *Jefe bárbaro* | 3,5 % | 64,0 % | 60,8 % | 0,0 % | 60 de 2360 | — | 5 % |

9. **Paridad con iOS:** el programa Dart de combate de la paridad de M2 (`$IOS/build/parity/dart/bin/combat.dart`) se ejecuta en un paquete temporal (fuera del repo) cuyo `lib/` es el de esta rama. Antes de C11 su salida es idéntica byte a byte a `$IOS/build/c11-parity/out-base/m2-combat.txt` (20031 líneas); con C11, a `$IOS/build/c11-parity/out-real/m2-combat.txt` (19970 líneas); y con las cinco probabilidades quitadas (control), otra vez a la base.

## Reparto

| Tarea | Qué |
|---|---|
| TC11.1 | Habilidades de los enemigos en el combate (dominio) |
| TC11.2 | La repetición enseña las habilidades del enemigo (presentación) |
| TC11.3 | Cierre: T1, `PROGRESS.md`, README, `GAME_DESIGN.md` y `CLAUDE.md` |

---

### Task TC11.1: Habilidades de los enemigos en el combate

**Files:**
- Modify (sustituir entero): `lib/layers/domain/entities/combat/arena_level_entity.dart`
- Create: `lib/layers/domain/world/extensions/enemy_kind_rules.dart`
- Modify: `lib/layers/domain/combat/combat.dart`
- Modify: `lib/layers/domain/rules/arena_levels.dart` (niveles 6–10)

**Interfaces:**
- Consumes: `SeededRandom.next()`, `Rules.secondWindThreshold`/`secondWindHeal`/`dodgeChance`/`doubleStrikeEvery`/`maxFightRounds`, `ArenaLevels.all` (con las recompensas de C9).
- Produces:
  - `ArenaLevelEntity({required ArenaLevelId id, required List<EnemyEntity> enemies, required Map<Resource, int> reward, double enemySkillChance = 0})`, `copyWith({..., double? enemySkillChance})`.
  - `extension EnemyKindRules on EnemyKind { Set<SkillId> get skills }`.
  - `Combat.resolve` y `Combat.adviceFor` con la misma firma (decisiones 3–6).

- [ ] **Step 1: `arena_level_entity.dart`** (sustituir entero)

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'enemy_entity.dart';

class ArenaLevelEntity {
  final ArenaLevelId id;
  final List<EnemyEntity> enemies;
  final Map<Resource, int> reward;
  final double enemySkillChance;

  const ArenaLevelEntity({required this.id, required this.enemies, required this.reward, this.enemySkillChance = 0})
    : assert(enemySkillChance >= 0 && enemySkillChance <= 1);

  int get power => enemies.fold(0, (sum, enemy) => sum + enemy.stats.power);

  ArenaLevelEntity copyWith({
    ArenaLevelId? id,
    List<EnemyEntity>? enemies,
    Map<Resource, int>? reward,
    double? enemySkillChance,
  }) {
    return ArenaLevelEntity(
      id: id ?? this.id,
      enemies: enemies ?? this.enemies,
      reward: reward ?? this.reward,
      enemySkillChance: enemySkillChance ?? this.enemySkillChance,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaLevelEntity &&
      other.id == id &&
      const ListEquality<EnemyEntity>().equals(other.enemies, enemies) &&
      const MapEquality<Resource, int>().equals(other.reward, reward) &&
      other.enemySkillChance == enemySkillChance;

  @override
  int get hashCode => Object.hash(
    id,
    const ListEquality<EnemyEntity>().hash(enemies),
    const MapEquality<Resource, int>().hash(reward),
    enemySkillChance,
  );
}
```

- [ ] **Step 2: `enemy_kind_rules.dart`** (nuevo)

```dart
import '../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

extension EnemyKindRules on EnemyKind {
  Set<SkillId> get skills => switch (this) {
    EnemyKind.bandit => const {SkillId.dodge},
    EnemyKind.barbarian => const {SkillId.doubleStrike},
    EnemyKind.barbarianChief => const {SkillId.doubleStrike, SkillId.secondWind},
    EnemyKind.wolf => const {SkillId.doubleStrike},
    EnemyKind.bear => const {SkillId.doubleStrike},
    EnemyKind.banditVeteran => const {SkillId.dodge},
  };
}
```

- [ ] **Step 3: `arena_levels.dart`**: añadir `enemySkillChance` detrás del `reward` de los cinco últimos niveles, con la sangría del `reward`:

| Nivel | Línea tras la que va | Línea nueva |
|---|---|---|
| `banditTrio` | `reward: {Resource.gold: 75, Resource.mana: 20},` | `enemySkillChance: 0.015,` |
| `barbarian` | `reward: {Resource.gold: 90, Resource.mana: 25},` | `enemySkillChance: 0.02,` |
| `wolfPack` | `reward: {Resource.gold: 100, Resource.mana: 30},` | `enemySkillChance: 0.025,` |
| `barbarianPair` | `reward: {Resource.gold: 120, Resource.mana: 35},` | `enemySkillChance: 0.03,` |
| `barbarianChief` | `reward: {Resource.gold: 150, Resource.mana: 50},` | `enemySkillChance: 0.035,` |

- [ ] **Step 4: `combat.dart`**

Import nuevo, tras `import '../rules/rules.dart';`:

```dart
import '../world/extensions/enemy_kind_rules.dart';
```

En `adviceFor`, la línea de `strikes` pasa a ser (decisión 6):

```dart
    final strikes = log.turns
        .where(
          (turn) => turn.actor == FightSide.hero && turn.target == FightSide.enemy && turn.action != FightAction.dodge,
        )
        .toList();
```

En `_Fight`, campo nuevo tras `final List<int> enemyHealth;` y su inicialización tras la de `enemyHealth`:

```dart
  final List<bool> enemySecondWindUsed;
```

```dart
      enemySecondWindUsed = [for (final _ in level.enemies) false],
```

`_heroStrikes`, `_enemiesAttack` y `_enemyStrikes` (sustituir los tres enteros) y dos métodos nuevos antes de `_damage` (`_heroAttacks`, `_catchSecondWind`, `_damage` y `play` no cambian):

```dart
  void _heroStrikes(FightAction action) {
    final target = enemyHealth.indexWhere((health) => health > 0);
    if (target < 0) return;
    if (_enemyRolls(SkillId.dodge, target)) {
      turns.add(
        FightTurnEntity(
          round: round,
          actor: FightSide.hero,
          actorIndex: 0,
          target: FightSide.enemy,
          targetIndex: target,
          action: FightAction.dodge,
          damage: 0,
          targetHealthAfter: enemyHealth[target],
        ),
      );
      return;
    }
    final damage = _damage(
      attacker: heroStats,
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
    _catchEnemySecondWind(target);
  }

  void _enemiesAttack() {
    for (var index = 0; index < level.enemies.length; index++) {
      if (heroHealth == 0) return;
      if (enemyHealth[index] == 0) continue;
      _enemyStrikes(index, FightAction.hit);
      _catchSecondWind();
      if (heroHealth > 0 && _enemyRolls(SkillId.doubleStrike, index)) {
        _enemyStrikes(index, FightAction.doubleStrike);
        _catchSecondWind();
      }
    }
  }

  void _enemyStrikes(int index, FightAction action) {
    final dodged = skills.contains(SkillId.dodge) && random.next() < Rules.dodgeChance;
    final damage = dodged
        ? 0
        : _damage(attacker: level.enemies[index].stats, defense: heroStats.defense, healthLeft: heroHealth);
    heroHealth -= damage;
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: index,
        target: FightSide.hero,
        targetIndex: 0,
        action: dodged ? FightAction.dodge : action,
        damage: damage,
        targetHealthAfter: heroHealth,
      ),
    );
  }
```

```dart
  void _catchEnemySecondWind(int index) {
    final enemy = level.enemies[index];
    if (!enemy.kind.skills.contains(SkillId.secondWind) || enemySecondWindUsed[index]) return;
    if (enemyHealth[index] == 0 || enemyHealth[index] >= enemy.stats.health * Rules.secondWindThreshold) return;
    enemySecondWindUsed[index] = true;
    if (!_enemyRolls(SkillId.secondWind, index)) return;
    enemyHealth[index] = math.min(
      enemy.stats.health,
      enemyHealth[index] + (enemy.stats.health * Rules.secondWindHeal).round(),
    );
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: index,
        target: FightSide.enemy,
        targetIndex: index,
        action: FightAction.secondWind,
        damage: 0,
        targetHealthAfter: enemyHealth[index],
      ),
    );
  }

  bool _enemyRolls(SkillId skill, int index) =>
      level.enemySkillChance > 0 &&
      level.enemies[index].kind.skills.contains(skill) &&
      random.next() < level.enemySkillChance;
```

- [ ] **Step 5: Verificar**

```sh
dart format --line-length 120 lib/layers/domain/entities/combat/arena_level_entity.dart lib/layers/domain/world/extensions/enemy_kind_rules.dart lib/layers/domain/combat/combat.dart lib/layers/domain/rules/arena_levels.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 6: Paridad y equilibrado (temporal, fuera del repo; no se commitea)**: en el *scratchpad*, un paquete `parity` con `pubspec.yaml` y `bin/combat.dart` copiados de `$IOS/build/parity/dart/` y `lib` → enlace simbólico al `lib/` del repo; `dart pub get --offline` y `dart run bin/combat.dart > real.txt`. Esperado: `cmp real.txt $IOS/build/c11-parity/out-real/m2-combat.txt` sin diferencias (19970 líneas); con una copia de `lib/` sin las cinco líneas `enemySkillChance:` de `arena_levels.dart`, igual a `out-base/m2-combat.txt` (20031 líneas). Un `bin/balance.dart` con la tabla de `BalanceScenarioMock` da la tabla de la decisión 8.

- [ ] **Step 7: Commit** — `git add lib/layers/domain` y, aparte, `git commit -m "[PROJECT-C11]: Let the enemies use skills"`.

### Task TC11.2: La repetición enseña las habilidades del enemigo

**Files:**
- Modify: `lib/layers/presentation/features/arena/models/arena_effect.dart` (`SkillUsedEffect`)
- Modify: `lib/layers/presentation/features/arena/bloc/arena_bloc.dart` (`_effectsFor`)
- Modify: `lib/layers/presentation/features/arena/game/arena_scene_component.dart` (`_play`, `_floatSkillName`)

**Interfaces:**
- Consumes: TC11.1 (turnos `doubleStrike`/`secondWind` con actor enemigo).
- Produces: `SkillUsedEffect({required SkillId skill, required FightSide side, required int index})`.

- [ ] **Step 1: `arena_effect.dart`**: sustituir `SkillUsedEffect` (el fichero ya importa `fight_side.dart`)

```dart
final class SkillUsedEffect extends ArenaEffect {
  final SkillId skill;
  final FightSide side;
  final int index;

  const SkillUsedEffect({required this.skill, required this.side, required this.index});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillUsedEffect && other.skill == skill && other.side == side && other.index == index;

  @override
  int get hashCode => Object.hash(SkillUsedEffect, skill, side, index);
}
```

- [ ] **Step 2: `arena_bloc.dart`**: sustituir `_effectsFor`

```dart
  List<ArenaEffect> _effectsFor(FightReplayData replay, int turnIndex) {
    final effect = _effectFor(replay, turnIndex);
    final turn = replay.log.turns[turnIndex];
    return switch (turn.action) {
      FightAction.hit => [effect],
      FightAction.doubleStrike => [
        effect,
        SkillUsedEffect(skill: SkillId.doubleStrike, side: turn.actor, index: turn.actorIndex),
      ],
      FightAction.dodge => [effect],
      FightAction.secondWind => [
        effect,
        SkillUsedEffect(skill: SkillId.secondWind, side: turn.actor, index: turn.actorIndex),
      ],
    };
  }
```

- [ ] **Step 3: `arena_scene_component.dart`**: en `_play`, el caso pasa a

```dart
      case SkillUsedEffect(:final skill, :final side, :final index):
        _floatSkillName(skill, side, index);
```

y la cabecera de `_floatSkillName` (hasta `final head`) a

```dart
  void _floatSkillName(SkillId skill, FightSide side, int index) {
    final fighter = _fighters[FighterRenderData.keyOf(side, index)];
    if (fighter == null) return;
    final head = fighter.headPoint;
```
El resto (el `FloatingTextComponent` a `skillNameLift` sobre la cabeza) no cambia.

- [ ] **Step 4: Verificar**

```sh
dart format --line-length 120 lib/layers/presentation/features/arena/models/arena_effect.dart lib/layers/presentation/features/arena/bloc/arena_bloc.dart lib/layers/presentation/features/arena/game/arena_scene_component.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 5: Commit** — `git add lib/layers/presentation/features/arena` y, aparte, `git commit -m "[PROJECT-C11]: Show the enemy skills in the replay"`.

### Task TC11.3: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-06-hero-arena/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, `docs/GAME_DESIGN.md` (3.8), `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **C11** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila C11 → `✅`, `feature/PROJECT-C11-enemy-skills`, nota "Sin tests (T1)"; `README.md`: icono de C11 → ✅.
- [ ] **Step 3:** `GAME_DESIGN.md` 3.8: habilidades de los enemigos y la tabla de la decisión 8.
- [ ] **Step 4:** `CLAUDE.md`: `ArenaLevelEntity.enemySkillChance`, `EnemyKindRules.skills`, el orden de las tiradas del enemigo en `Combat`, `adviceFor` sin los `dodge`, `SkillUsedEffect` con bando e índice y las probabilidades en la regla de equilibrado; *New enemy kind* también necesita su caso en `EnemyKindRules.skills`.
- [ ] **Step 5: Commit** — `git add docs/boost/plans docs/GAME_DESIGN.md`; `git add CLAUDE.md` (comando aparte); `git commit -m "[PROJECT-C11]: Close the enemy skills phase"` (comando aparte).

## Prueba manual

Se hace una vez tras C12 (comprobación por bloque), en Chrome y Android:

1. Niveles 1–5: ningún enemigo esquiva, golpea dos veces ni se cura.
2. Niveles 6–10, varias peleas: de vez en cuando un bandido esquiva (*¡Esquiva!* sobre él, sin número de daño), un bárbaro o un lobo golpea dos veces (*¡Golpe doble!* sobre él) y el jefe se cura una vez como mucho (*¡Segundo aliento!* sobre él y el número verde de la cura).
3. Un golpe doble esquivado enseña *¡Esquiva!*, no *¡Golpe doble!*.
4. Las barras de vida siguen a la repetición (la cura del jefe sube su barra).

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por C11 (no se ha tocado `test/`):

- **No compilan:** `test/mocks/presentation/features/arena/arena_effect_mock.dart` (`doubleStrikeUsed`, `doubleStrikeUsedCopy`, `secondWindUsed` necesitan `side: FightSide.hero, index: 0`; añadir variantes de enemigo, p. ej. `enemyDoubleStrikeUsed` con `side: FightSide.enemy, index: 2`) y por tanto `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart` (línea ~514) y todo test que importe ese mock.
- **Pueden cambiar de resultado** (pelean con los niveles reales 6–10 de `ArenaLevels`): `arena_flow_test.dart` (juega todos los niveles), `start_fight_use_case_test.dart` (jefe, líneas ~105–119), `arena_bloc_test.dart` (`banditTrio`, `wolfPack`, `barbarianChief`). Revisar resultados y semillas.
- `test/layers/domain/rules/arena_levels_test.dart`: probabilidades 0 en los niveles 1–5 y 0,015 / 0,02 / 0,025 / 0,03 / 0,035 en los 6–10, crecientes.
- `test/layers/domain/entities/combat/arena_level_entity_test.dart`: `enemySkillChance` por defecto 0, en `copyWith`, `==` y `hashCode`. Mocks nuevos en `arena_level_entity_mock.dart` con probabilidad (los mocks actuales no la llevan y sus goldens de `combat_test.dart` siguen valiendo).
- `test/layers/domain/world/extensions/enemy_kind_rules_test.dart` (nuevo): las habilidades de cada `EnemyKind` (tabla de la decisión 1).
- `test/layers/domain/combat/combat_test.dart`, goldens con los niveles reales y el héroe esperado de `BalanceScenarioMock` (semillas medidas):
  - *Tres bandidos*, semilla 0: turno 11 (ronda 4) héroe → enemigo 1 `dodge`, daño 0, vida 26; 27 turnos, victoria.
  - *Bárbaro*, semilla 25: turno 7 (ronda 3) enemigo 0 → héroe `doubleStrike`, daño 5, vida 32; 18 turnos, victoria.
  - *Manada de tres lobos*, semilla 1: turno 4 (ronda 1) enemigo 2 → héroe `doubleStrike`, daño 4, vida 41; 22 turnos, victoria.
  - *Dos bárbaros*, semilla 8: turno 18 (ronda 6) enemigo 1 → héroe `doubleStrike`, daño 6, vida 5; 23 turnos, derrota, consejo `almostThere`.
  - *Jefe bárbaro*, semilla 1: turno 4 (ronda 1) enemigo 2 → héroe `doubleStrike`, daño 1, vida 63; turno 24 (ronda 6) enemigo 0 → enemigo 0 `secondWind`, vida 44; 31 turnos, derrota, consejo `needDefense`.
  - el mismo nivel con `copyWith(enemySkillChance: 0)` da exactamente el registro anterior a C11 (y los niveles 1–5 no cambian);
  - el jefe tira *Segundo aliento* una sola vez por pelea (como mucho un turno `secondWind` de enemigo en cualquier semilla);
  - `adviceFor` ignora los `dodge` del héroe en el daño medio.
- `test/layers/domain/combat/balance_test.dart`: con las probabilidades sigue en verde (tabla de la decisión 8); añadir el ≥ 60 % con las semillas 0–999 para el héroe esperado.
- `arena_bloc_test.dart`: `SkillUsedEffect` con `side: FightSide.enemy` y el índice del enemigo en un golpe doble enemigo, y del jefe en su *Segundo aliento*.
- `test/layers/presentation/features/arena/game/arena_scene_component_test.dart`: el nombre flota sobre el enemigo indicado (misma altura que sobre el héroe).
