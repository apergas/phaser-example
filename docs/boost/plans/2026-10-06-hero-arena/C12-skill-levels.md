# C12 · Niveles de habilidad del héroe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (arena) |
| **Rama** | `feature/PROJECT-C12-skill-levels`, desde `feature/PROJECT-C11-enemy-skills` (C9, C10 y C11 dentro) |
| **Issue / milestone** | `phase:C12` · milestone `C12 Skill levels` · #59 |
| **Depende de** | C9 (costes con maná) y C11 (equilibrado con las habilidades de los enemigos) |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-arena/C12-skill-levels.md`, merge `c6a2107`, commits `c494924` (combate) y `6ff3310` (panel) |

**Goal:** Cada habilidad del héroe tiene 3 niveles: aprenderla es el nivel 1 y *Mejorar* sube al siguiente, pagando más oro y maná, con un efecto mayor.

**Architecture:** Dominio: `HeroEntity.skillLevels: Map<SkillId, int>` sustituye a `skills`, que pasa a ser un getter de `HeroRules` (con `levelOf`, `withSkill` y `power` por suma de niveles); `Rules` guarda los efectos por nivel; `Combat.resolve(skillLevels:)` aplica el nivel **sin tiradas nuevas**; `SkillEntity.costs` (un coste por nivel), `SkillOptionEntity` con `level`/`nextLevel`/`nextCost`, estados y resultados nuevos y `LearnSkillUseCase` que aprende o mejora. Presentación: `SkillItemData` con `levelText`, `nextText` y `buttonText`, `SkillTile` con *Aprender*/*Mejorar*/*Máximo* y el *snackbar* de la mejora en `ForestBloc`. Ni datos, ni DI, ni la arena.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, `easy_localization`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario, 2026-10-17):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar o cambien de resultado están listados en *Para T1*.
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, tras C12, con el bloque de la arena.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Mientras `test/` no compila no se usa `flutter analyze` a secas.
- **Determinismo:** ningún `next()` nuevo, quitado ni reordenado. El nivel solo cambia **números** que se aplican tras las mismas tiradas: un héroe con todas sus habilidades en nivel 1 da exactamente los mismos `FightLogEntity` que antes.
- Enums de core: `SkillOptionState` y `LearnSkillResult` pierden `known`/`alreadyKnown` y ganan los casos nuevos al final (aún no se guardan). `switch` exhaustivos en el orden de declaración.
- Textos nuevos solo en `es.json`, leídos con `Internationalize`. Ninguno dice cómo interactuar, así que no hay variante `…Touch`.
- Sin comentarios en `lib/`; imports relativos; títulos de commit `[PROJECT-C12]: <frase en inglés en imperativo>`.
- No se tocan `di.config.dart` ni `*.mocks.dart` (C12 no cambia DI: ningún constructor de caso de uso cambia).

## Decisiones

Las de la ficha (reglas del usuario, 2026-10-15), ya aplicadas en iOS, más las que salen de Flutter:

1. **Representación:** `HeroEntity.skillLevels: Map<SkillId, int>` (sin entrada = no aprendida; valores 1–3). En `HeroRules`: `levelOf(skill)` (0 si no la conoce), `skills` (getter, `Set<SkillId>` en el orden de `SkillId.values`, para misiones, el balance y quien solo pregunta si la conoce) y `withSkill(skill, level:)`. Siempre se recorre `SkillId.values`, nunca el mapa.
   - **Desviación:** la ficha pedía un `assert` de 1–3 en `HeroEntity`, pero un constructor `const` no admite `assert` sobre el contenido de un mapa (`invalid_constant`), y `HeroEntity` se usa como `const` en todas partes. El `assert(level >= 1 && level <= Skills.byId(skill).maxLevel)` va en `HeroRules.withSkill`, que es la única vía del juego para poner un nivel. F2 valida al cargar.
2. **Catálogo** (`Skills`): `SkillEntity.costs` (`costs[0]` es el nivel 1), `maxLevel` (= `costs.length`, 3) y `costOf(level)`. Oro / maná (×1,5 y ×2,25, los .5 hacia arriba al múltiplo de 5):

   | Habilidad | Nv 1 | Nv 2 | Nv 3 |
   |---|---|---|---|
   | *Golpe doble* | 60 / 20 | 90 / 30 | 135 / 45 |
   | *Esquiva* | 90 / 30 | 135 / 45 | 205 / 70 |
   | *Segundo aliento* | 130 / 45 | 195 / 70 | 295 / 100 |

   Subir las dos habilidades del héroe esperado a nivel 3 cuesta 565 / 190 (unas 10 repeticiones del jefe); todos los niveles de las tres, 1335 / 455.
3. **Efectos por nivel** (`Rules`, sustituyen a `dodgeChance` y `secondWindHeal`):
   - `doubleStrikeEvery` = 3 en todos los niveles; `doubleStrikeBonusByLevel = [0, 0.15, 0.3]`: el segundo golpe hace `(max(1, valor − defensa) × (1 + bonificación)).round()`, sin pasar de la vida que le queda al enemigo. Con bonificación 0 es el mismo número.
   - `dodgeChanceByLevel = [0.2, 0.25, 0.3]`: el mismo dado de antes, con otro umbral.
   - `secondWindHealByLevel = [0.4, 0.5, 0.6]`.
   - `enemySkillLevel = 1`: el *Segundo aliento* del jefe (C11) cura `secondWindHealByLevel[0]`; las probabilidades de C11 no cambian. El *Golpe doble* del enemigo no lleva bonificación.
4. **Firma del combate:** `Combat.resolve({level, heroStats, required Map<SkillId, int> skillLevels, seed})` (como iOS); `StartFightUseCase` pasa `hero.skillLevels`.
5. **Poder:** `HeroRules.power` = `stats.power × (1 + suma de niveles × Rules.powerPerSkill)`, redondeado. En nivel 1 da lo de siempre.
6. **Estados y resultados:** `SkillOptionState { available, needsBuilding, unaffordable, maxed }`; `LearnSkillResult { ok, missingBuilding, notEnoughResources, upgraded, maxed }`. `LearnSkillUseCase` comprueba torre de magia, máximo y recursos, en ese orden; `ok` al aprender el nivel 1, `upgraded` al subir al 2 o al 3. `GetSkillOptionsUseCase` da `maxed` en el máximo y si no los estados de siempre con el coste del **siguiente** nivel.
7. **Opción:** `SkillOptionEntity` gana `level` (obligatorio, 0 = sin aprender, `assert(level >= 0)`), `nextLevel` y `nextCost` (`null` en el máximo).
8. **Panel** (`SkillItemData`: `levelText`, `nextText`, `buttonText`; `isKnown` = nivel > 0):
   - nombre con "Nv 2/3" al lado (color de acento, cifras tabulares) solo si está aprendida;
   - descripción del nivel actual (la del 1 si no está aprendida);
   - "Nv 3: <efecto>" solo si está aprendida y no está al máximo;
   - coste del siguiente nivel (ninguno en el máximo) y el motivo si no se puede;
   - botón *Aprender* (nivel 0) o *Mejorar* (1–2) con la misma `SkillTile.learnKey`, o el texto *Máximo* (3) en `CustomColors.questDone`.
   - Al mejorar: *snackbar* "Has mejorado: Esquiva (Nv 2)" y `SkillLearnedEffect` (las mismas chispas azules). `maxed` da "Esa habilidad ya está al nivel máximo.".
9. **Textos:** `forest.hero.skillLevel` "Nv {level}/{max}", `forest.hero.skillMax` "Máximo", `forest.hero.skillNext` "Nv {level}: {effect}", `forest.hero.upgrade` "Mejorar", `forest.message.skillMaxLevel`, `forest.message.skillUpgraded` "Has mejorado: {name} (Nv {level})" y las descripciones de los niveles 2 y 3. Se quita `forest.message.skillAlreadyKnown` (y `Internationalize.forestMessageSkillAlreadyKnown`); `forest.hero.known` se queda sin uso.
   - **Desviación:** las claves de iOS `forest.skill.<habilidad>.description.level2/level3` no caben en el `es.json` anidado (`description` ya es un texto y `easy_localization` devolvería la descripción del nivel 1). En Flutter son `forest.skill.<habilidad>.descriptionLevel2` / `descriptionLevel3`, y `Internationalize.forestSkillDescription({id, level})` elige la clave.
10. **Equilibrado** (regla del test de balance más el techo nuevo: el héroe esperado con sus habilidades en **nivel 3** gana ≤ 95 % con las semillas 0–99 y 0–999). Medido con el dominio de esta rama (programa temporal fuera del repo, el héroe de `BalanceScenarioMock`); coincide **exactamente** con iOS:

    | Nivel | Nv 1 0–99 / 0–999 | Nv 2 0–99 / 0–999 | Nv 3 0–99 / 0–999 | Un paso por detrás 0–99 (Nv 1 / Nv 3) | Poder Nv 1 / 2 / 3 |
    |---|---|---|---|---|---|
    | 1–6 | sin habilidades: 100 / 86 / 77 / 84 / 79 / 89 % | = | = | 0 % (3–6) | 31 / 31 / 40 / 53 / 62 / 77 |
    | 7 *Bárbaro* | 73,0 / 75,1 % | 83,0 / 85,6 % | 88,0 / 91,5 % | 6,0 / 6,0 % | 85 / 92 / 100 |
    | 8 *Manada de tres lobos* | 78,0 / 71,9 % | 86,0 / 83,4 % | 94,0 / 93,3 % | 15,0 / 41,0 % | 92 / 108 / 123 |
    | 9 *Dos bárbaros* | 79,0 / 74,0 % | 86,0 / 86,8 % | 93,0 / 93,7 % | 2,0 / 32,0 % | 107 / 125 / 142 |
    | 10 *Jefe bárbaro* | 64,0 / 60,8 % | 80,0 / 76,8 % | 91,0 / 88,7 % | 0,0 / 1,0 % | 133 / 155 / 178 |

11. **Paridad con iOS:** el programa Dart de combate de la paridad de M2 (`$IOS/build/parity/dart/bin/combat.dart`) en un paquete temporal cuyo `lib` es el de esta rama. Antes de C12 su salida (19970 líneas) es idéntica al principio de `$IOS/build/c12-parity/out-final/m2-combat.txt`; con C12, pasando `skillLevels` (nivel 1) y añadiendo al final el bloque de iOS (héroes 2 y 3 con las tres habilidades en nivel 2 y 3 contra los 10 niveles y las semillas 0, 1, 7, 42, −3, y su poder), es **idéntica byte a byte** al fichero entero (22766 líneas), con y sin `--enable-asserts`. Poder: `hero Nv2 H2 power=99`, `Nv2 H3 178`, `Nv3 H2 118`, `Nv3 H3 211`.
12. **Guardado (F2):** el DBO del héroe guarda `skillLevels` desde su versión 1 y valida al cargar que cada nivel esté entre 1 y `Skills.byId(id).maxLevel`.

## Reparto

| Tarea | Qué |
|---|---|
| TC12.1 | Niveles de habilidad en el combate (dominio) |
| TC12.2 | Aprender y mejorar en el panel del héroe (catálogo, casos de uso, textos, panel) |
| TC12.3 | Cierre: T1, `PROGRESS.md`, README, `GAME_DESIGN.md` y `CLAUDE.md` |

---

### Task TC12.1: Niveles de habilidad en el combate

**Files:**
- Modify (sustituir entero): `lib/layers/domain/entities/hero/hero_entity.dart`, `lib/layers/domain/world/extensions/hero_rules.dart`
- Modify: `lib/layers/domain/rules/rules.dart`, `lib/layers/domain/combat/combat.dart`, `lib/layers/domain/use-cases/arena/start_fight_use_case.dart`, `lib/layers/domain/use-cases/hero/learn_skill_use_case.dart`, `lib/layers/domain/use-cases/hero/get_skill_options_use_case.dart`, `lib/layers/domain/quests/quests.dart` (estos tres, solo el import de `hero_rules.dart` y una línea)

**Interfaces:**
- Consumes: `SeededRandom.next()`, `_Fight` con las tiradas del enemigo (C11), `Rules.doubleStrikeEvery`/`secondWindThreshold`/`powerPerSkill`.
- Produces:
  - `HeroEntity({int weaponTier = 0, int armorTier = 0, Map<SkillId, int> skillLevels = const {}, Set<ArenaLevelId> clearedLevels = const {}, int fightsFought = 0})` y `copyWith({..., Map<SkillId, int>? skillLevels, ...})` (sin `skills`).
  - `extension HeroRules on HeroEntity { int levelOf(SkillId skill); Set<SkillId> get skills; int get power; HeroEntity withSkill(SkillId skill, {required int level}); }`.
  - `Rules.dodgeChanceByLevel`, `Rules.secondWindHealByLevel`, `Rules.doubleStrikeBonusByLevel` (`List<double>`), `Rules.enemySkillLevel = 1`.
  - `Combat.resolve({required ArenaLevelEntity level, required CombatStatsEntity heroStats, required Map<SkillId, int> skillLevels, required int seed})`.

- [ ] **Step 1: `hero_entity.dart`** (sustituir entero)

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class HeroEntity {
  final int weaponTier;
  final int armorTier;
  final Map<SkillId, int> skillLevels;
  final Set<ArenaLevelId> clearedLevels;
  final int fightsFought;

  const HeroEntity({
    this.weaponTier = 0,
    this.armorTier = 0,
    this.skillLevels = const {},
    this.clearedLevels = const {},
    this.fightsFought = 0,
  }) : assert(weaponTier >= 0),
       assert(armorTier >= 0),
       assert(fightsFought >= 0);

  HeroEntity copyWith({
    int? weaponTier,
    int? armorTier,
    Map<SkillId, int>? skillLevels,
    Set<ArenaLevelId>? clearedLevels,
    int? fightsFought,
  }) {
    return HeroEntity(
      weaponTier: weaponTier ?? this.weaponTier,
      armorTier: armorTier ?? this.armorTier,
      skillLevels: skillLevels ?? this.skillLevels,
      clearedLevels: clearedLevels ?? this.clearedLevels,
      fightsFought: fightsFought ?? this.fightsFought,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HeroEntity &&
      other.weaponTier == weaponTier &&
      other.armorTier == armorTier &&
      const MapEquality<SkillId, int>().equals(other.skillLevels, skillLevels) &&
      const SetEquality<ArenaLevelId>().equals(other.clearedLevels, clearedLevels) &&
      other.fightsFought == fightsFought;

  @override
  int get hashCode => Object.hash(
    weaponTier,
    armorTier,
    const MapEquality<SkillId, int>().hash(skillLevels),
    const SetEquality<ArenaLevelId>().hash(clearedLevels),
    fightsFought,
  );
}
```

- [ ] **Step 2: `hero_rules.dart`** (sustituir entero; TC12.2 completa el `assert` con el máximo del catálogo)

```dart
import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../core/config/constants/enum/skill_id.dart';
import '../../entities/gear/gear_entity.dart';
import '../../entities/hero/combat_stats_entity.dart';
import '../../entities/hero/hero_entity.dart';
import '../../rules/gear.dart';
import '../../rules/rules.dart';

extension HeroRules on HeroEntity {
  int tierOf(GearSlot slot) => switch (slot) {
    GearSlot.weapon => weaponTier,
    GearSlot.armor => armorTier,
  };

  GearEntity equipped(GearSlot slot) => Gear.of(slot, tierOf(slot));

  GearEntity? nextGear(GearSlot slot) => Gear.find(slot, tierOf(slot) + 1);

  int levelOf(SkillId skill) => skillLevels[skill] ?? 0;

  Set<SkillId> get skills => {
    for (final skill in SkillId.values)
      if (levelOf(skill) > 0) skill,
  };

  CombatStatsEntity get stats {
    final weapon = equipped(GearSlot.weapon);
    final armor = equipped(GearSlot.armor);
    return CombatStatsEntity(
      attackMin: weapon.attackMin + armor.attackMin,
      attackMax: weapon.attackMax + armor.attackMax,
      defense: weapon.defense + armor.defense,
      health: weapon.health + armor.health,
    );
  }

  int get power {
    final skillPoints = SkillId.values.fold(0, (sum, skill) => sum + levelOf(skill));
    return (stats.power * (1 + skillPoints * Rules.powerPerSkill)).round();
  }

  HeroEntity withGear(GearEntity gear) => switch (gear.slot) {
    GearSlot.weapon => copyWith(weaponTier: gear.tier),
    GearSlot.armor => copyWith(armorTier: gear.tier),
  };

  HeroEntity withSkill(SkillId skill, {required int level}) {
    assert(level >= 1);
    return copyWith(skillLevels: {...skillLevels, skill: level});
  }
}
```

- [ ] **Step 3: `rules.dart`**: tres líneas

| Antes | Después |
|---|---|
| `static const double dodgeChance = 0.2;` | `static const List<double> dodgeChanceByLevel = [0.2, 0.25, 0.3];` |
| `static const double secondWindHeal = 0.4;` | `static const List<double> secondWindHealByLevel = [0.4, 0.5, 0.6];` |
| `static const int doubleStrikeEvery = 3;` | la misma línea, seguida de `static const List<double> doubleStrikeBonusByLevel = [0, 0.15, 0.3];` y `static const int enemySkillLevel = 1;` |

- [ ] **Step 4: `combat.dart`**

`resolve` y el constructor de `_Fight`:

```dart
  static FightLogEntity resolve({
    required ArenaLevelEntity level,
    required CombatStatsEntity heroStats,
    required Map<SkillId, int> skillLevels,
    required int seed,
  }) {
    final fight = _Fight(level: level, heroStats: heroStats, skillLevels: skillLevels, random: SeededRandom(seed))
      ..play();
```

En `_Fight`, el campo `final Set<SkillId> skills;` pasa a `final Map<SkillId, int> skillLevels;` y el constructor a `_Fight({required this.level, required this.heroStats, required this.skillLevels, required this.random})` (el resto de la lista de inicialización no cambia).

`_heroAttacks`: la condición pasa a `if (_levelOf(SkillId.doubleStrike) > 0 && heroAttacks % Rules.doubleStrikeEvery == 0) {`.

`_heroStrikes`: la llamada a `_damage` gana la bonificación:

```dart
    final damage = _damage(
      attacker: heroStats,
      defense: level.enemies[target].stats.defense,
      healthLeft: enemyHealth[target],
      bonus: action == FightAction.doubleStrike
          ? Rules.doubleStrikeBonusByLevel[_levelOf(SkillId.doubleStrike) - 1]
          : 0,
    );
```

`_enemyStrikes`: la primera línea pasa a

```dart
    final dodgeLevel = _levelOf(SkillId.dodge);
    final dodged = dodgeLevel > 0 && random.next() < Rules.dodgeChanceByLevel[dodgeLevel - 1];
```

`_catchSecondWind`: la primera línea y la curación pasan a

```dart
    final secondWindLevel = _levelOf(SkillId.secondWind);
    if (secondWindLevel == 0 || secondWindUsed) return;
```

```dart
    heroHealth = math.min(
      heroStats.health,
      heroHealth + (heroStats.health * Rules.secondWindHealByLevel[secondWindLevel - 1]).round(),
    );
```

`_catchEnemySecondWind`: la curación pasa a `enemyHealth[index] + (enemy.stats.health * Rules.secondWindHealByLevel[Rules.enemySkillLevel - 1]).round(),`.

Antes de `_enemyRolls`, método nuevo, y `_damage` (sustituir entero):

```dart
  int _levelOf(SkillId skill) => skillLevels[skill] ?? 0;
```

```dart
  int _damage({
    required CombatStatsEntity attacker,
    required int defense,
    required int healthLeft,
    double bonus = 0,
  }) {
    final attack = attacker.attackMin + (random.next() * (attacker.attackMax - attacker.attackMin + 1)).floor();
    final hit = math.max(1, attack - defense);
    return math.min(healthLeft, (hit * (1 + bonus)).round());
  }
```

- [ ] **Step 5: casos de uso y misiones**
  - `start_fight_use_case.dart`: `skills: hero.skills` → `skillLevels: hero.skillLevels` en `Combat.resolve`.
  - `learn_skill_use_case.dart`: `world.updateHero((hero) => hero.copyWith(skills: {...hero.skills, id}));` → `world.updateHero((hero) => hero.withSkill(id, level: 1));` e `import '../../world/extensions/hero_rules.dart';` tras el de `building_rules.dart` (`world.hero.skills` es ahora el getter).
  - `get_skill_options_use_case.dart`: el mismo import (usa `world.hero.skills`).
  - `quests.dart`: `import '../world/extensions/hero_rules.dart';` tras el de `building_rules.dart` (*Aprende una habilidad* mira `world.hero.skills.isNotEmpty`).

- [ ] **Step 6: Verificar**

```sh
dart format --line-length 120 lib/layers/domain/entities/hero/hero_entity.dart lib/layers/domain/world/extensions/hero_rules.dart lib/layers/domain/rules/rules.dart lib/layers/domain/combat/combat.dart lib/layers/domain/use-cases lib/layers/domain/quests/quests.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 7: Paridad y equilibrado (temporal, fuera del repo; no se commitea)**: en el *scratchpad*, un paquete `parity` con `pubspec.yaml`/`pubspec.lock` de `$IOS/build/parity/dart/` y `lib` → enlace simbólico al `lib/` del repo. `bin/base.dart` = `$IOS/build/parity/dart/bin/combat.dart` tal cual (antes de C12: 19970 líneas iguales al principio de `out-final`). `bin/combat.dart` = el mismo con `skills: skills` → `skillLevels: {for (final skill in skills) skill: 1}` (también en `hero.copyWith`) y el bloque de niveles de la decisión 11 al final de `main`. Esperado: `dart run bin/combat.dart | cmp - $IOS/build/c12-parity/out-final/m2-combat.txt` sin diferencias. Un `bin/balance.dart` con la tabla de `BalanceScenarioMock` (subiendo a nivel N las habilidades que tenga) da la tabla de la decisión 10.

- [ ] **Step 8: Commit** — `git add lib/layers/domain` y, aparte, `git commit -m "[PROJECT-C12]: Give the hero skills three levels in combat"`.

### Task TC12.2: Aprender y mejorar en el panel del héroe

**Files:**
- Modify (sustituir entero): `lib/layers/domain/entities/hero/skill_entity.dart`, `lib/layers/domain/entities/hero/skill_option_entity.dart`, `lib/core/config/constants/enum/skill_option_state.dart`, `lib/core/config/constants/enum/learn_skill_result.dart`, `lib/layers/domain/rules/skills.dart`, `lib/layers/domain/use-cases/hero/learn_skill_use_case.dart`, `lib/layers/presentation/features/forest/models/skill_item_data.dart`, `lib/layers/presentation/features/forest/widgets/skill_tile.dart`
- Modify: `lib/layers/domain/world/extensions/hero_rules.dart` (`assert`), `lib/layers/domain/use-cases/hero/get_skill_options_use_case.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`

**Interfaces:**
- Consumes: `HeroRules.levelOf`/`withSkill` (TC12.1), `World.spend`, `funds.missing`, `GetHeroStatusUseCase` (`HeroStatusEntity.hero`), `SkillLearnedEffect`, `HudButton`.
- Produces:
  - `SkillEntity({required SkillId id, required List<Map<Resource, int>> costs})`, `int get maxLevel`, `Map<Resource, int> costOf(int level)`, `copyWith({SkillId? id, List<Map<Resource, int>>? costs})` (sin `cost`).
  - `SkillOptionEntity({required SkillEntity skill, required int level, required SkillOptionState state, Map<Resource, int> missing = const {}})`, `int? get nextLevel`, `Map<Resource, int>? get nextCost`, `bool get canLearn`.
  - `enum SkillOptionState { available, needsBuilding, unaffordable, maxed }`, `enum LearnSkillResult { ok, missingBuilding, notEnoughResources, upgraded, maxed }`.
  - `Internationalize.forestHeroUpgrade`, `forestHeroSkillMax`, `forestHeroSkillLevel({required int level, required int max})`, `forestHeroSkillNext({required int level, required String effect})`, `forestSkillDescription({required SkillId id, required int level})`, `forestMessageSkillUpgraded({required String name, required int level})`, `forestMessageSkillMaxLevel` (sin `forestMessageSkillAlreadyKnown`).
  - `SkillItemData({required id, required name, required description, String? levelText, String? nextText, String? costText, String? reasonText, String? buttonText, required bool isKnown, required bool canLearn})`.

- [ ] **Step 1: `skill_entity.dart`** (sustituir entero)

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class SkillEntity {
  final SkillId id;
  final List<Map<Resource, int>> costs;

  const SkillEntity({required this.id, required this.costs});

  int get maxLevel => costs.length;

  Map<Resource, int> costOf(int level) => costs[level - 1];

  SkillEntity copyWith({SkillId? id, List<Map<Resource, int>>? costs}) {
    return SkillEntity(id: id ?? this.id, costs: costs ?? this.costs);
  }

  static const ListEquality<Map<Resource, int>> _costsEquality = ListEquality(MapEquality<Resource, int>());

  @override
  bool operator ==(Object other) => other is SkillEntity && other.id == id && _costsEquality.equals(other.costs, costs);

  @override
  int get hashCode => Object.hash(id, _costsEquality.hash(costs));

  @override
  String toString() => 'SkillEntity(id: $id, costs: $costs)';
}
```

- [ ] **Step 2: `skill_option_entity.dart`** (sustituir entero)

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/skill_option_state.dart';
import 'skill_entity.dart';

class SkillOptionEntity {
  final SkillEntity skill;
  final int level;
  final SkillOptionState state;
  final Map<Resource, int> missing;

  const SkillOptionEntity({required this.skill, required this.level, required this.state, this.missing = const {}})
    : assert(level >= 0);

  int? get nextLevel => level < skill.maxLevel ? level + 1 : null;

  Map<Resource, int>? get nextCost {
    final next = nextLevel;
    return next == null ? null : skill.costOf(next);
  }

  bool get canLearn => state == SkillOptionState.available;

  SkillOptionEntity copyWith({SkillEntity? skill, int? level, SkillOptionState? state, Map<Resource, int>? missing}) {
    return SkillOptionEntity(
      skill: skill ?? this.skill,
      level: level ?? this.level,
      state: state ?? this.state,
      missing: missing ?? this.missing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SkillOptionEntity &&
      other.skill == skill &&
      other.level == level &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(skill, level, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'SkillOptionEntity(skill: ${skill.id}, level: $level, state: $state, missing: $missing)';
}
```

- [ ] **Step 3: enums** (sustituir enteros)

```dart
enum SkillOptionState { available, needsBuilding, unaffordable, maxed }
```

```dart
enum LearnSkillResult { ok, missingBuilding, notEnoughResources, upgraded, maxed }
```

- [ ] **Step 4: `skills.dart`** (sustituir entero)

```dart
import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/skill_id.dart';
import '../entities/hero/skill_entity.dart';

abstract final class Skills {
  static const BlueprintId building = BlueprintId.mageTower;

  static const SkillEntity doubleStrike = SkillEntity(
    id: SkillId.doubleStrike,
    costs: [
      {Resource.gold: 60, Resource.mana: 20},
      {Resource.gold: 90, Resource.mana: 30},
      {Resource.gold: 135, Resource.mana: 45},
    ],
  );

  static const SkillEntity dodge = SkillEntity(
    id: SkillId.dodge,
    costs: [
      {Resource.gold: 90, Resource.mana: 30},
      {Resource.gold: 135, Resource.mana: 45},
      {Resource.gold: 205, Resource.mana: 70},
    ],
  );

  static const SkillEntity secondWind = SkillEntity(
    id: SkillId.secondWind,
    costs: [
      {Resource.gold: 130, Resource.mana: 45},
      {Resource.gold: 195, Resource.mana: 70},
      {Resource.gold: 295, Resource.mana: 100},
    ],
  );

  static const List<SkillEntity> all = [doubleStrike, dodge, secondWind];

  static SkillEntity byId(SkillId id) => all.firstWhere((skill) => skill.id == id);
}
```

- [ ] **Step 5: `hero_rules.dart`**: el `assert` de `withSkill` pasa a `assert(level >= 1 && level <= Skills.byId(skill).maxLevel);` con `import '../../rules/skills.dart';` tras el de `rules.dart`.

- [ ] **Step 6: `learn_skill_use_case.dart`** (sustituir entero)

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/learn_skill_result.dart';
import '../../../../core/config/constants/enum/skill_id.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/skills.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class LearnSkillUseCase {
  final GameSessionRepository _sessionRepository;

  const LearnSkillUseCase({required this._sessionRepository});

  LearnSkillResult call({required SkillId id}) {
    final world = _sessionRepository.current().world;
    if (!world.buildings.hasComplete(Skills.building)) return LearnSkillResult.missingBuilding;
    final skill = Skills.byId(id);
    final level = world.hero.levelOf(id);
    if (level == skill.maxLevel) return LearnSkillResult.maxed;
    if (!world.spend(skill.costOf(level + 1))) return LearnSkillResult.notEnoughResources;
    world.updateHero((hero) => hero.withSkill(id, level: level + 1));
    return level == 0 ? LearnSkillResult.ok : LearnSkillResult.upgraded;
  }
}
```

- [ ] **Step 7: `get_skill_options_use_case.dart`**: en `_option`, las dos primeras líneas y el `return` final pasan a

```dart
    final level = world.hero.levelOf(skill.id);
    if (level == skill.maxLevel) return SkillOptionEntity(skill: skill, level: level, state: SkillOptionState.maxed);
    final missing = world.funds.missing(skill.costOf(level + 1));
```

```dart
    return SkillOptionEntity(skill: skill, level: level, state: state, missing: missing);
```

- [ ] **Step 8: `es.json`**
  - `forest.message`: quitar `"skillAlreadyKnown"` y añadir tras `"skillLearned"`: `"skillUpgraded": "Has mejorado: {name} (Nv {level})"`, `"skillMaxLevel": "Esa habilidad ya está al nivel máximo."`.
  - `forest.hero`: tras `"known"`: `"upgrade": "Mejorar"`, `"skillLevel": "Nv {level}/{max}"`, `"skillNext": "Nv {level}: {effect}"`, `"skillMax": "Máximo"`.
  - `forest.skill.<habilidad>`: tras `"description"`, `"descriptionLevel2"` y `"descriptionLevel3"`:

    | Habilidad | `descriptionLevel2` | `descriptionLevel3` |
    |---|---|---|
    | `doubleStrike` | Cada tercer ataque golpea dos veces y el segundo golpe hace un 15 % más de daño. | … un 30 % más de daño. |
    | `secondWind` | Una vez por pelea, por debajo del 30 % de vida recupera el 50 %. | … recupera el 60 %. |
    | `dodge` | Un 25 % de posibilidades de esquivar cada golpe. | Un 30 % de posibilidades de esquivar cada golpe. |

- [ ] **Step 9: `internationalize.dart`**: tras `forestHeroKnown`

```dart
  static String get forestHeroUpgrade => '$_forest.hero.upgrade'.tr();
  static String get forestHeroSkillMax => '$_forest.hero.skillMax'.tr();
  static String forestHeroSkillLevel({required int level, required int max}) =>
      '$_forest.hero.skillLevel'.tr(namedArgs: {'level': '$level', 'max': '$max'});
  static String forestHeroSkillNext({required int level, required String effect}) =>
      '$_forest.hero.skillNext'.tr(namedArgs: {'level': '$level', 'effect': effect});
```

`forestSkillDescription` (sustituir):

```dart
  static String forestSkillDescription({required SkillId id, required int level}) => switch ((id, level)) {
    (SkillId.doubleStrike, 1) => '$_forest.skill.doubleStrike.description'.tr(),
    (SkillId.doubleStrike, 2) => '$_forest.skill.doubleStrike.descriptionLevel2'.tr(),
    (SkillId.doubleStrike, _) => '$_forest.skill.doubleStrike.descriptionLevel3'.tr(),
    (SkillId.secondWind, 1) => '$_forest.skill.secondWind.description'.tr(),
    (SkillId.secondWind, 2) => '$_forest.skill.secondWind.descriptionLevel2'.tr(),
    (SkillId.secondWind, _) => '$_forest.skill.secondWind.descriptionLevel3'.tr(),
    (SkillId.dodge, 1) => '$_forest.skill.dodge.description'.tr(),
    (SkillId.dodge, 2) => '$_forest.skill.dodge.descriptionLevel2'.tr(),
    (SkillId.dodge, _) => '$_forest.skill.dodge.descriptionLevel3'.tr(),
  };
```

`forestMessageSkillAlreadyKnown` se sustituye por

```dart
  static String forestMessageSkillUpgraded({required String name, required int level}) =>
      '$_forest.message.skillUpgraded'.tr(namedArgs: {'name': name, 'level': '$level'});
  static String get forestMessageSkillMaxLevel => '$_forest.message.skillMaxLevel'.tr();
```

- [ ] **Step 10: `skill_item_data.dart`** (sustituir entero)

```dart
import '../../../../../core/config/constants/enum/skill_id.dart';

class SkillItemData {
  final SkillId id;
  final String name;
  final String description;
  final String? levelText;
  final String? nextText;
  final String? costText;
  final String? reasonText;
  final String? buttonText;
  final bool isKnown;
  final bool canLearn;

  const SkillItemData({
    required this.id,
    required this.name,
    required this.description,
    this.levelText,
    this.nextText,
    this.costText,
    this.reasonText,
    this.buttonText,
    required this.isKnown,
    required this.canLearn,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillItemData &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.levelText == levelText &&
          other.nextText == nextText &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.buttonText == buttonText &&
          other.isKnown == isKnown &&
          other.canLearn == canLearn;

  @override
  int get hashCode =>
      Object.hash(id, name, description, levelText, nextText, costText, reasonText, buttonText, isKnown, canLearn);

  @override
  String toString() =>
      'SkillItemData($id, $name, $levelText, $nextText, $costText, $reasonText, $buttonText, '
      'isKnown: $isKnown, canLearn: $canLearn)';
}
```

- [ ] **Step 11: `skill_tile.dart`** (sustituir entero)

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/skill_item_data.dart';
import 'hud_button.dart';

class SkillTile extends StatelessWidget {
  final SkillItemData item;
  final VoidCallback? onLearn;

  const SkillTile({super.key, required this.item, this.onLearn});

  static Key learnKey(SkillId id) => Key('skillTileLearn-${id.name}');

  @override
  Widget build(BuildContext context) {
    final levelText = item.levelText;
    final nextText = item.nextText;
    final costText = item.costText;
    final reasonText = item.reasonText;
    final buttonText = item.buttonText;
    return DecoratedBox(
      decoration: BoxDecoration(color: CustomColors.hudOptionBackground, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: CustomTextStyles.system15w600.copyWith(
                            color: item.isKnown || item.canLearn ? CustomColors.hudText : CustomColors.hudMuted,
                          ),
                        ),
                      ),
                      if (levelText != null)
                        Text(
                          levelText,
                          style: CustomTextStyles.system12w500.copyWith(
                            color: CustomColors.hudAccent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  Text(item.description, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudMuted)),
                  if (nextText != null)
                    Text(nextText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudText)),
                  if (costText != null)
                    Text(
                      costText,
                      style: CustomTextStyles.system13w500.copyWith(
                        color: item.canLearn ? CustomColors.hudAccent : CustomColors.hudMuted,
                      ),
                    ),
                  if (reasonText != null)
                    Text(reasonText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
                ],
              ),
            ),
            if (buttonText != null)
              HudButton(key: learnKey(item.id), label: buttonText, onPressed: item.canLearn ? onLearn : null)
            else
              Text(
                Internationalize.forestHeroSkillMax,
                style: CustomTextStyles.system12w500.copyWith(color: CustomColors.questDone),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 12: `forest_bloc.dart`**
  - Import `../../../../domain/world/extensions/hero_rules.dart` antes del de `inventory_rules.dart`.
  - `_learnSkill`: el `switch` queda (el caso `ok` no cambia)

```dart
      case LearnSkillResult.missingBuilding:
        _showMessage(Internationalize.forestHeroNeedsBuilding(name: _skillBuildingName));
      case LearnSkillResult.notEnoughResources:
        _showMessage(Internationalize.forestMessageNotEnoughResources);
      case LearnSkillResult.upgraded:
        _showMessage(
          Internationalize.forestMessageSkillUpgraded(
            name: Internationalize.forestSkillName(id: id),
            level: _getHeroStatusUseCase().hero.levelOf(id),
          ),
        );
        effects.add(SkillLearnedEffect(skill: id));
      case LearnSkillResult.maxed:
        _showMessage(Internationalize.forestMessageSkillMaxLevel);
```

  - `_skillItem` (sustituir entero):

```dart
  SkillItemData _skillItem(SkillOptionEntity option) {
    final skill = option.skill;
    final isKnown = option.level > 0;
    final nextLevel = option.nextLevel;
    final nextCost = option.nextCost;
    return SkillItemData(
      id: skill.id,
      name: Internationalize.forestSkillName(id: skill.id),
      description: Internationalize.forestSkillDescription(id: skill.id, level: isKnown ? option.level : 1),
      levelText: isKnown ? Internationalize.forestHeroSkillLevel(level: option.level, max: skill.maxLevel) : null,
      nextText: isKnown && nextLevel != null
          ? Internationalize.forestHeroSkillNext(
              level: nextLevel,
              effect: Internationalize.forestSkillDescription(id: skill.id, level: nextLevel),
            )
          : null,
      costText: nextCost == null ? null : _amounts(nextCost),
      reasonText: switch (option.state) {
        SkillOptionState.available => null,
        SkillOptionState.needsBuilding => Internationalize.forestHeroNeedsBuilding(name: _skillBuildingName),
        SkillOptionState.unaffordable => Internationalize.forestMissing(amounts: _amounts(option.missing)),
        SkillOptionState.maxed => null,
      },
      buttonText: switch (nextLevel) {
        null => null,
        _ when isKnown => Internationalize.forestHeroUpgrade,
        _ => Internationalize.forestHeroLearn,
      },
      isKnown: isKnown,
      canLearn: option.canLearn,
    );
  }
```

- [ ] **Step 13: Verificar**

```sh
dart format --line-length 120 lib/layers/domain/entities/hero lib/layers/domain/rules/skills.dart lib/layers/domain/world/extensions/hero_rules.dart lib/layers/domain/use-cases/hero lib/core/config/constants/enum/skill_option_state.dart lib/core/config/constants/enum/learn_skill_result.dart lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/forest/models/skill_item_data.dart lib/layers/presentation/features/forest/widgets/skill_tile.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart
flutter analyze lib
```
Esperado: `No issues found!`. `es.json` sigue siendo JSON válido (`python3 -c "import json; json.load(open('lib/core/assets/i18n/translations/es.json'))"`). La paridad del paso 7 de TC12.1 sigue idéntica con `dart run --enable-asserts`.

- [ ] **Step 14: Commit** — `git add lib` y, aparte, `git commit -m "[PROJECT-C12]: Learn and upgrade skill levels in the hero panel"`.

### Task TC12.3: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-06-hero-arena/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, `docs/GAME_DESIGN.md` (3.8), `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **C12** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila C12 → `✅`, `feature/PROJECT-C12-skill-levels`, nota "Sin tests (T1)"; `README.md`: icono de C12 → ✅.
- [ ] **Step 3:** `GAME_DESIGN.md` 3.8: Poder por nivel de habilidad, costes por nivel, efectos por nivel y la tabla de la decisión 10.
- [ ] **Step 4:** `CLAUDE.md`: `HeroEntity.skillLevels`, `HeroRules.levelOf`/`skills`/`withSkill`/`power`, `SkillEntity.costs`/`maxLevel`/`costOf`, `SkillOptionEntity.level`/`nextLevel`/`nextCost`, los estados `maxed`/resultado `upgraded`, `LearnSkillUseCase` (torre, máximo, recursos), los efectos por nivel de `Rules` y el *Golpe doble* con bonificación en `Combat`, `SkillTile` con *Mejorar*/*Máximo* y el techo del nivel 3 en la regla de equilibrado.
- [ ] **Step 5: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); `git commit -m "[PROJECT-C12]: Close the skill levels phase"` (comando aparte).

## Prueba manual

Se hace una vez tras C12 (comprobación por bloque), en Chrome y Android:

1. Con la torre de magia y oro y maná de sobra: *Golpe doble* enseña *Aprender* y 60 de oro y 20 de maná. Al aprender: "Has aprendido: Golpe doble", chispas azules, la ficha pasa a "Golpe doble Nv 1/3", "Nv 2: …15 % más de daño", 90 / 30 y *Mejorar*.
2. *Mejorar* dos veces: "Has mejorado: Golpe doble (Nv 2)" y "(Nv 3)", con chispas; cobra 90 / 30 y 135 / 45; al final "Nv 3/3", la descripción del 30 %, sin coste y *Máximo* en verde.
3. Sin recursos para el siguiente nivel: *Mejorar* desactivado y el texto de lo que falta.
4. El poder del panel y de la arena sube un 10 % del base por cada nivel.
5. Una pelea con *Esquiva* en nivel 3 esquiva más a menudo; *Segundo aliento* en nivel 3 sube la barra más que en nivel 1.

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por C12 (no se ha tocado `test/`):

- **No compilan:**
  - `HeroEntity(skills: …)` / `copyWith(skills:)` → `skillLevels: {SkillId.x: 1}`: `test/mocks/domain/entities/hero/hero_entity_mock.dart`, `test/mocks/domain/game/balance_scenario_mock.dart`, `hero_entity_test.dart`.
  - `Combat.resolve(skills:)` → `skillLevels:`: `combat_test.dart`, `balance_test.dart` (y su `_spentOn`, que usa `Skills.byId(skill).cost`: pasar a la suma de `costOf(1..levelOf(skill))`).
  - `SkillEntity(cost:)` → `costs:`: `skill_entity_mock.dart`, `skill_entity_test.dart`, `skills_test.dart`.
  - `SkillOptionEntity` sin `level` y `SkillOptionState.known`: `skill_option_entity_mock.dart`, `skill_option_entity_test.dart`, `get_skill_options_use_case_test.dart`.
  - `LearnSkillResult.alreadyKnown`: `learn_skill_use_case_test.dart`, `skill_flow_test.dart`, `forest_bloc_skill_test.dart`.
  - `Internationalize.forestSkillDescription(id:)` sin `level` y `forestMessageSkillAlreadyKnown`: `internationalize_test.dart`, `skill_item_data_mock.dart`, `hero_panel_data_mock.dart`, `forest_bloc_skill_test.dart`, `hero_panel_test.dart`, `hud_overlay_test.dart`, `forest_page_test.dart`, `skill_tile_test.dart` (el texto *Aprendida* ya no sale: *Máximo* o *Mejorar*).
- `hero_entity_test.dart`: `skillLevels` en `copyWith`, `==` y `hashCode`.
- `hero_rules_test.dart`: `levelOf` (0 sin aprender), `skills` en el orden de `SkillId.values` y solo con nivel > 0, `withSkill` (añade y sube; `AssertionError` con 0 y con 4) y `power` con niveles: los héroes 2 y 3 de la paridad (`HeroEntity(weaponTier: 2, armorTier: 1)` y `(3, 3)`) con las tres en nivel 2 → 99 y 178, en nivel 3 → 118 y 211; el héroe esperado del jefe → 133 / 155 / 178.
- `skills_test.dart`: `maxLevel` 3 y los costes de la decisión 2; `costOf(1)` es el coste de antes.
- `skill_option_entity_test.dart`: `nextLevel`/`nextCost` (nivel 0 → 1 y `costs[0]`; nivel 3 → `null`), `canLearn`, `assert(level >= 0)`.
- `learn_skill_use_case_test.dart`: aprender (`ok`, nivel 1, cobra `costOf(1)`), mejorar (`upgraded`, nivel 2 y 3, cobra 90 / 30 y 135 / 45 del *Golpe doble*), `maxed` sin cobrar, `notEnoughResources` sin cambiar nada, y el orden: sin torre da `missingBuilding` aunque esté al máximo; al máximo da `maxed` aunque no haya recursos.
- `get_skill_options_use_case_test.dart`: `level` en cada opción, `maxed` en el máximo (sin `missing`), `missing` del siguiente nivel.
- `combat_test.dart`, goldens (héroe `HeroEntity(weaponTier: 2, armorTier: 2)` salvo el último):
  - *Bárbaro* (`ArenaLevels.byId(ArenaLevelId.barbarian)`), semilla 0, solo *Golpe doble*: turno 5 (ronda 3) héroe → enemigo 0 `doubleStrike` con daño 6 / 7 / 8 y vida 34 / 33 / 32 en nivel 1 / 2 / 3; 17 / 15 / 15 turnos, victoria.
  - *Manada de tres lobos*, semilla 0, solo *Esquiva*: 3 / 5 / 5 esquivas del héroe en nivel 1 / 2 / 3; nivel 1 y 2 derrota (`almostThere`, 23 y 24 turnos, primera esquiva en el turno 6, enemigo 1); nivel 3 victoria en 25 turnos, primera esquiva en el turno 1 (enemigo 0, vida 55).
  - *Jefe bárbaro*, semilla 0, héroe `HeroEntity(weaponTier: 3, armorTier: 3)`, solo *Segundo aliento*: turno 16 (ronda 4) `secondWind` del héroe desde 21 de vida a 51 / 59 / 66 en nivel 1 / 2 / 3; nivel 1 derrota (`almostThere`, 46 turnos), 2 y 3 victoria (49 turnos).
  - con todas las habilidades en nivel 1 el registro es el de antes de C12 (todos los goldens actuales pasan cambiando solo `skills:` por `skillLevels:` con nivel 1).
  - los enemigos curan con `Rules.enemySkillLevel` (los goldens de C11 del jefe no cambian).
- `balance_test.dart`: sigue en verde (columna *Nv 1* de la decisión 10); test nuevo: el héroe esperado con sus habilidades en nivel 3 gana ≤ 95 % con las semillas 0–99 y 0–999 (tabla de la decisión 10); un paso por detrás con nivel 3 sigue < 50 %. Si se añade un `BalanceScenarioMock.maxedSkillLevel = 3`, va en el mock.
- `skill_tile_test.dart`: nombre con "Nv 2/3" solo si está aprendida; "Nv 3: …" solo en nivel 1–2; *Aprender* con nivel 0, *Mejorar* con 1–2 (misma `learnKey`, desactivado sin `canLearn`) y *Máximo* sin botón en el 3. Mocks nuevos en `skill_item_data_mock.dart` (aprendida en nivel 1, en nivel 2, al máximo).
- `forest_bloc_skill_test.dart`: `SkillItemData` por nivel y estado (textos de `Internationalize`), el *snackbar* "Has mejorado" con el nivel nuevo y `SkillLearnedEffect` al mejorar, "Esa habilidad ya está al nivel máximo." con `maxed`.
- `internationalize_test.dart`: las claves nuevas (`skillLevel`, `skillNext`, `skillMax`, `upgrade`, `skillUpgraded`, `skillMaxLevel`, las seis `descriptionLevel2/3`) y sin `skillAlreadyKnown`.
