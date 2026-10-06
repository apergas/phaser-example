# C0 · Contrato común: oro y héroe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

**Goal:** Fijar los nombres, tipos y datos que comparten los dos flujos del plan (arena y héroe), para que después cada desarrollador trabaje en sus propios ficheros. Para ello se añade el oro, una "caja" única para pagar y cobrar, el héroe dentro del `World` y las entidades del combate. **Sin jugabilidad nueva**: sólo aparece "Oro 0" en el HUD.

**Architecture:**
- `Resource.gold`. El `World` gana `funds` / `earn` / `spend`: hoy usan el inventario del jugador; con F6, el stock de la aldea.
- `HeroEntity` (niveles de equipo, habilidades, niveles de arena ganados, peleas jugadas) en `WorldState.hero`, expuesto por `World.hero` y modificado sólo con `World.updateHero`.
- Las entidades del combate se usan ya en C0 como contrato y como mocks: `CombatStatsEntity`, `GearEntity`, `EnemyEntity`, `ArenaLevelEntity`, `FightTurnEntity`, `FightLogEntity` y `HeroStatusEntity`.
- Catálogo `Gear` con las 8 piezas de equipo. Extensión `HeroRules` con `stats`, `power`, `equipped`, `nextGear` y `withGear`.
- `GetHeroStatusUseCase`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `injectable`, `collection`, `flutter_test` + `mockito`.

**Precondición:** F0 fusionada en `develop`. Este plan usa su API: `Resource`, `InventoryEntity.resources`, `InventoryRules.amount` / `add` / `spend`, y los `switch` sobre `Resource` en `Internationalize` y `CustomIcons` (ver *Interfaces* de T0.1 y T0.2 en [F0-generalize.md](../2026-10-04-game-design/F0-generalize.md)). Antes de empezar, confirma que esas firmas no han cambiado al implementar F0. Si han cambiado, adapta los fragmentos de este plan y apúntalo en las desviaciones del README.

**Cómo probar la fase entera:**
- En Chrome, en el emulador Android y en el simulador iOS el juego se comporta como antes. El HUD muestra además el oro (0) con su icono.
- `flutter test` en verde, incluidos los tests nuevos de héroe, equipo y cajas.

## Reparto

| Tarea | Capa | Depende de | Paralelizable |
|---|---|---|---|
| TC0.1 Oro y caja del `World` | domain + core (i18n, iconos) | F0 | No |
| TC0.2 Héroe, equipo y entidades de combate | domain + `CLAUDE.md` | TC0.1 | No (mismos ficheros calientes: `world.dart`, `world_state.dart`, `rules.dart`) |

Mientras se hace C0, el otro desarrollador escribe los planes detallados de C1 y C3 (con `boost:writing-plans`) a partir de las *Interfaces* de este fichero.

---

### Task TC0.1: Oro y caja del `World`

**Files:**
- Modify:
  - `lib/core/config/constants/enum/resource.dart`: añadir `gold` al final.
  - `lib/layers/domain/world/world.dart`: `funds`, `earn`, `spend`.
  - `lib/core/assets/i18n/internationalize.dart` y `lib/core/assets/i18n/translations/es.json`: el caso `Resource.gold` de cada `switch` sobre `Resource` que haya creado F0.
  - `lib/layers/presentation/theme/images/custom_icons.dart`: el caso `Resource.gold` en `CustomIcons.resource`.
- Create:
  - `lib/core/assets/images/icons/gold.svg`
  - `test/layers/domain/world/world_funds_test.dart`
  - `test/mocks/domain/world/funds_mock.dart`
- Test (se amplían):
  - `test/core/assets/i18n/internationalize_test.dart` (el nombre "Oro").
  - `test/layers/presentation/theme/images/custom_icons_test.dart`, si F0 lo creó: el icono del oro existe en el bundle.

**Interfaces:**
- Consumes (de F0): `enum Resource`, `InventoryEntity.resources`, `InventoryRules.amount(Resource)`, `InventoryRules.add(Resource, int)`, `InventoryRules.spend(Map<Resource, int>) → InventoryEntity?`.
- Produces:
  ```dart
  // lib/core/config/constants/enum/resource.dart
  enum Resource { wood, /* stone si F5 ya está, */ gold }

  // lib/layers/domain/world/world.dart
  InventoryEntity get funds;                    // lo que se puede gastar: hoy player.inventory, con F6 el stock
  void earn(Map<Resource, int> reward);         // suma cada cantidad > 0
  bool spend(Map<Resource, int> cost);          // false y sin cambios si falta algo

  // Internationalize
  static String forestResource({required Resource resource});   // Resource.gold -> "Oro"
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-c0-gold
```

- [ ] **Step 2: Escribir los datos de prueba**

`test/mocks/domain/world/funds_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/resource.dart';

abstract final class FundsMock {
  static const Map<Resource, int> tenGold = {Resource.gold: 10};

  static const Map<Resource, int> fourGold = {Resource.gold: 4};

  static const Map<Resource, int> twentyGold = {Resource.gold: 20};

  static const Map<Resource, int> fiveWoodAndFourGold = {Resource.wood: 5, Resource.gold: 4};

  static const Map<Resource, int> zeroGold = {Resource.gold: 0};
}
```

- [ ] **Step 3: Escribir los tests que fallan**

`test/layers/domain/world/world_funds_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/world/funds_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenEarningGoldThenFundsHaveThatGold', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.tenGold);

    // then
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenEarningZeroThenFundsDoNotChange', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.zeroGold);

    // then
    expect(world.funds.resources.containsKey(Resource.gold), isFalse);
  });

  test('testWhenSpendingAffordableCostThenItIsSubtractedAndReturnsTrue', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.earn(FundsMock.tenGold);

    // when
    final paid = world.spend(FundsMock.fiveWoodAndFourGold);

    // then
    expect(paid, isTrue);
    expect(world.funds.amount(Resource.wood), 12);
    expect(world.funds.amount(Resource.gold), 6);
  });

  test('testWhenSpendingMoreThanFundsThenNothingChangesAndReturnsFalse', () {
    // given
    final world = WorldMock.make();
    world.earn(FundsMock.tenGold);

    // when
    final paid = world.spend(FundsMock.twentyGold);

    // then
    expect(paid, isFalse);
    expect(world.funds.amount(Resource.gold), 10);
  });

  test('testWhenEarningThenTheFundsAreThePlayerInventory', () {
    // given
    final world = WorldMock.make();

    // when
    world.earn(FundsMock.fourGold);

    // then
    expect(world.funds, world.player.inventory);
  });
}
```

El último test fija que, **antes de F6**, la caja es el inventario del jugador. F6 lo cambia por `world.stock` en el mismo PR que mueve la caja.

- [ ] **Step 4: Ver que fallan**

Run: `flutter test test/layers/domain/world/world_funds_test.dart`
Expected: FAIL al compilar (`Resource.gold`, `earn`, `spend` y `funds` no existen).

- [ ] **Step 5: Añadir `Resource.gold`**

En `lib/core/config/constants/enum/resource.dart`, añadir `gold` como **último** valor del enum.

Run: `flutter analyze`
Expected: errores de `switch` no exhaustivo en `Internationalize` y `CustomIcons`. Es la lista de sitios del Step 6.

- [ ] **Step 6: Textos e icono**

Para cada `switch` sobre `Resource` que señale `flutter analyze`, añade el caso `Resource.gold` **al final**:

- `Internationalize.forestResource` → `'$_forest.resource.gold'.tr()`.
- Si F0 creó un texto de cantidad por recurso (por ejemplo `forestAmount`, que F5 usa como `forest.amount.stone`), su caso `gold` → `'$_forest.amount.gold'.tr(namedArgs: {'amount': '$amount'})`.
- `CustomIcons.resource` → `Resource.gold => gold`, con `static const String gold = '$_path/gold.svg';` junto a `wood`.

En `es.json`, dentro de `forest.resource` y (si existe) `forest.amount`, al final de cada bloque:

```json
"gold": "Oro"
```

```json
"gold": "{amount} de oro"
```

`lib/core/assets/images/icons/gold.svg` (22×14, como `wood.svg`):

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="14" viewBox="0 0 22 14">
  <ellipse cx="8" cy="9.5" rx="7" ry="4" fill="#9A6B12"/>
  <ellipse cx="8" cy="8" rx="7" ry="4" fill="#E2B33C"/>
  <ellipse cx="8" cy="8" rx="4.6" ry="2.4" fill="#F4D77A"/>
  <ellipse cx="15" cy="6" rx="6.4" ry="3.8" fill="#9A6B12"/>
  <ellipse cx="15" cy="4.5" rx="6.4" ry="3.8" fill="#E2B33C"/>
  <ellipse cx="15" cy="4.5" rx="4.2" ry="2.2" fill="#F4D77A"/>
</svg>
```

Ampliar `internationalize_test.dart` con el nombre "Oro" (es el único test que escribe textos en español), siguiendo el patrón que dejó F0 para "Madera".

- [ ] **Step 7: Implementar la caja en `World`**

En `lib/layers/domain/world/world.dart`, después de `canPlace`:

```dart
  InventoryEntity get funds => _state.player.inventory;

  void earn(Map<Resource, int> reward) {
    var inventory = _state.player.inventory;
    for (final MapEntry(key: resource, value: quantity) in reward.entries) {
      if (quantity > 0) inventory = inventory.add(resource, quantity);
    }
    _state.player = _state.player.copyWith(inventory: inventory);
  }

  bool spend(Map<Resource, int> cost) {
    final remaining = _state.player.inventory.spend(cost);
    if (remaining == null) return false;
    _state.player = _state.player.copyWith(inventory: remaining);
    return true;
  }
```

con los imports de `../../../core/config/constants/enum/resource.dart`, `../entities/player/inventory_entity.dart` y `extensions/inventory_rules.dart`.

Si F6 ya está fusionada, los tres métodos usan `_state.stock` en lugar de `_state.player.inventory`, y el último test del Step 3 compara con `world.stock`.

- [ ] **Step 8: Ver que pasan**

Run: `flutter test test/layers/domain/world/world_funds_test.dart test/core/assets/i18n/internationalize_test.dart`
Expected: PASS.

- [ ] **Step 9: Verificación completa**

```bash
dart format --line-length 120 lib/layers/domain/world/world.dart lib/core/config/constants/enum/resource.dart lib/core/assets/i18n/internationalize.dart lib/layers/presentation/theme/images/custom_icons.dart test/layers/domain/world/world_funds_test.dart test/mocks/domain/world/funds_mock.dart
flutter analyze
flutter test
```

Expected: `No issues found!` y todos los tests en verde. En Chrome (`flutter run -d chrome`), el HUD muestra el oro con su icono y el juego funciona como antes.

- [ ] **Step 10: Commit**

```bash
git add lib/core/config/constants/enum/resource.dart lib/layers/domain/world/world.dart lib/core/assets/i18n lib/core/assets/images/icons/gold.svg lib/layers/presentation/theme/images/custom_icons.dart test/layers/domain/world/world_funds_test.dart test/mocks/domain/world/funds_mock.dart test/core
git commit -m "[PROJECT-X]: Add gold and a single place to earn and spend resources"
```

---

### Task TC0.2: Héroe, equipo y entidades de combate

**Files:**
- Create:
  - Enums de core (`lib/core/config/constants/enum/`): `gear_slot.dart`, `gear_id.dart`, `skill_id.dart`, `enemy_kind.dart`, `arena_level_id.dart`, `fight_side.dart`, `fight_action.dart`, `fight_outcome.dart`.
  - Entidades:
    - `lib/layers/domain/entities/hero/combat_stats_entity.dart`, `hero_entity.dart`, `hero_status_entity.dart`;
    - `lib/layers/domain/entities/gear/gear_entity.dart`;
    - `lib/layers/domain/entities/combat/enemy_entity.dart`, `arena_level_entity.dart`, `fight_turn_entity.dart`, `fight_log_entity.dart`.
  - `lib/layers/domain/rules/gear.dart`
  - `lib/layers/domain/world/extensions/hero_rules.dart`
  - `lib/layers/domain/use-cases/hero/get_hero_status_use_case.dart`
- Modify:
  - `lib/layers/domain/world/world_state.dart`, `world.dart`: el héroe.
  - `lib/layers/domain/rules/rules.dart`: `powerPerSkill` al final.
  - `lib/core/config/di/di.config.dart`: regenerado.
  - `CLAUDE.md`: *Architecture* (entidades, `World`, `rules/`, `use-cases/hero/`).
- Test (en `test/`):
  - `layers/domain/entities/hero/combat_stats_entity_test.dart`, `hero_entity_test.dart`
  - `layers/domain/entities/combat/arena_level_entity_test.dart`, `fight_log_entity_test.dart`
  - `layers/domain/rules/gear_test.dart`
  - `layers/domain/world/extensions/hero_rules_test.dart`
  - `layers/domain/world/world_hero_test.dart`
  - `layers/domain/use-cases/hero/get_hero_status_use_case_test.dart`
  - Mocks:
    - `mocks/domain/entities/hero/combat_stats_entity_mock.dart`, `hero_entity_mock.dart`, `hero_status_entity_mock.dart`;
    - `mocks/domain/entities/combat/enemy_entity_mock.dart`, `arena_level_entity_mock.dart`, `fight_turn_entity_mock.dart`, `fight_log_entity_mock.dart`;
    - `mocks/domain/world/world_mock.dart` (ampliado).

**Interfaces:**
- Consumes (de TC0.1): `Resource.gold`, `World.funds` / `earn` / `spend`.
- Produces (lo que usan C1–C7; **los nombres no se cambian sin actualizar este plan y avisar al otro flujo**):
  ```dart
  // core enums
  enum GearSlot { weapon, armor }
  enum GearId { woodcutterAxe, shortSword, ironSword, steelSword, workClothes, leatherArmor, chainMail, plateArmor }
  enum SkillId { doubleStrike, secondWind, dodge }
  enum EnemyKind { bandit, barbarian, barbarianChief }                 // C4 añade wolf, bear al final
  enum ArenaLevelId { banditRookie, banditVeteran, banditTrio, barbarian, barbarianPair, barbarianChief }   // C4 añade las de animales al final
  enum FightSide { hero, enemy }
  enum FightAction { hit, doubleStrike, dodge, secondWind }
  enum FightOutcome { victory, defeat }

  // entities
  CombatStatsEntity({required int attack, required int defense, required int health});   // int get power
  GearEntity({required GearId id, required GearSlot slot, required int tier, required Map<Resource, int> cost,
              int attack = 0, int defense = 0, int health = 0});
  HeroEntity({int weaponTier = 0, int armorTier = 0, Set<SkillId> skills = const {},
              Set<ArenaLevelId> clearedLevels = const {}, int fightsFought = 0});        // copyWith
  HeroStatusEntity({required HeroEntity hero, required CombatStatsEntity stats, required int power});
  EnemyEntity({required EnemyKind kind, required CombatStatsEntity stats});
  ArenaLevelEntity({required ArenaLevelId id, required List<EnemyEntity> enemies, required Map<Resource, int> reward});  // int get power
  FightTurnEntity({required int round, required FightSide actor, required int actorIndex, required FightSide target,
                   required int targetIndex, required FightAction action, required int damage, required int targetHealthAfter});
  FightLogEntity({required ArenaLevelId levelId, required CombatStatsEntity heroStats, required List<EnemyEntity> enemies,
                  required List<FightTurnEntity> turns, required FightOutcome outcome, required Map<Resource, int> reward});
                  // bool get isVictory, int get rounds

  // lib/layers/domain/rules/gear.dart
  abstract final class Gear {
    static const List<GearEntity> all;
    static GearEntity byId(GearId id);
    static GearEntity of(GearSlot slot, int tier);          // existe para todo tier en 0..maxTier
    static GearEntity? find(GearSlot slot, int tier);        // null fuera de rango
    static int maxTier(GearSlot slot);
  }

  // lib/layers/domain/world/extensions/hero_rules.dart
  extension HeroRules on HeroEntity {
    int tierOf(GearSlot slot);
    GearEntity equipped(GearSlot slot);
    GearEntity? nextGear(GearSlot slot);                     // null si ya tiene el máximo
    CombatStatsEntity get stats;                             // suma del arma y la armadura equipadas
    int get power;                                           // (stats.power * (1 + skills.length * Rules.powerPerSkill)).round()
    HeroEntity withGear(GearEntity gear);
  }

  // World
  HeroEntity get hero;
  void updateHero(HeroEntity Function(HeroEntity hero) transform);
  World({..., HeroEntity hero = const HeroEntity()});

  // use case
  @Injectable() final class GetHeroStatusUseCase { HeroStatusEntity call(); }

  // mocks
  HeroEntityMock.mock / .withShortSwordAndLeather / .fullyGeared / .withTwoSkills
  CombatStatsEntityMock.heroBase / .bandit / .brute
  EnemyEntityMock.bandit / .brute
  ArenaLevelEntityMock.banditRookie / .banditTrio
  FightTurnEntityMock.* (las jugadas de los registros)
  FightLogEntityMock.victoryOverBandit / .defeatByBrute / .allActions
  HeroStatusEntityMock.base
  WorldMock.withHero(HeroEntity hero)
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-c0-hero
```

- [ ] **Step 2: Enums de core**

Un fichero por enum en `lib/core/config/constants/enum/`, sin nada más que la declaración:

```dart
// gear_slot.dart
enum GearSlot { weapon, armor }

// gear_id.dart
enum GearId { woodcutterAxe, shortSword, ironSword, steelSword, workClothes, leatherArmor, chainMail, plateArmor }

// skill_id.dart
enum SkillId { doubleStrike, secondWind, dodge }

// enemy_kind.dart
enum EnemyKind { bandit, barbarian, barbarianChief }

// arena_level_id.dart
enum ArenaLevelId { banditRookie, banditVeteran, banditTrio, barbarian, barbarianPair, barbarianChief }

// fight_side.dart
enum FightSide { hero, enemy }

// fight_action.dart
enum FightAction { hit, doubleStrike, dodge, secondWind }

// fight_outcome.dart
enum FightOutcome { victory, defeat }
```

Significado de `FightAction` (lo implementa el motor de C1; aquí sólo se documenta el contrato):
- `hit`: golpe normal; `damage` es lo que pierde el objetivo.
- `doubleStrike`: el golpe extra del héroe, inmediatamente después de su `hit`.
- `dodge`: el héroe esquiva; `damage` es 0 y `actor` es el enemigo que falla.
- `secondWind`: el héroe se cura; `actor` y `target` son el héroe, `damage` es 0 y `targetHealthAfter` es la vida tras curarse.

- [ ] **Step 3: Escribir los mocks de entidades**

Las entidades todavía no existen, así que estos ficheros no compilan: es lo esperado en TDD.

`test/mocks/domain/entities/hero/combat_stats_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/hero/combat_stats_entity.dart';

abstract final class CombatStatsEntityMock {
  static const CombatStatsEntity heroBase = CombatStatsEntity(attack: 4, defense: 1, health: 30);

  static const CombatStatsEntity heroWithShortSwordAndLeather = CombatStatsEntity(attack: 7, defense: 3, health: 40);

  static const CombatStatsEntity heroFullyGeared = CombatStatsEntity(attack: 14, defense: 8, health: 75);

  static const CombatStatsEntity bandit = CombatStatsEntity(attack: 3, defense: 0, health: 20);

  static const CombatStatsEntity brute = CombatStatsEntity(attack: 31, defense: 6, health: 55);
}
```

`test/mocks/domain/entities/hero/hero_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';

abstract final class HeroEntityMock {
  static const HeroEntity mock = HeroEntity();

  static const HeroEntity withShortSwordAndLeather = HeroEntity(weaponTier: 1, armorTier: 1);

  static const HeroEntity fullyGeared = HeroEntity(
    weaponTier: 3,
    armorTier: 3,
    skills: {SkillId.doubleStrike, SkillId.secondWind, SkillId.dodge},
  );

  static const HeroEntity withTwoSkills = HeroEntity(
    weaponTier: 1,
    armorTier: 1,
    skills: {SkillId.doubleStrike, SkillId.dodge},
  );

  static const HeroEntity veteran = HeroEntity(
    clearedLevels: {ArenaLevelId.banditRookie},
    fightsFought: 3,
  );
}
```

`test/mocks/domain/entities/hero/hero_status_entity_mock.dart`:

```dart
import 'package:rpg/layers/domain/entities/hero/hero_status_entity.dart';

import 'combat_stats_entity_mock.dart';
import 'hero_entity_mock.dart';

abstract final class HeroStatusEntityMock {
  static const HeroStatusEntity base = HeroStatusEntity(
    hero: HeroEntityMock.mock,
    stats: CombatStatsEntityMock.heroBase,
    power: 31,
  );
}
```

`test/mocks/domain/entities/combat/enemy_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/domain/entities/combat/enemy_entity.dart';

import '../hero/combat_stats_entity_mock.dart';

abstract final class EnemyEntityMock {
  static const EnemyEntity bandit = EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntityMock.bandit);

  static const EnemyEntity brute = EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntityMock.brute);
}
```

`test/mocks/domain/entities/combat/arena_level_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/combat/arena_level_entity.dart';

import 'enemy_entity_mock.dart';

abstract final class ArenaLevelEntityMock {
  static const ArenaLevelEntity banditRookie = ArenaLevelEntity(
    id: ArenaLevelId.banditRookie,
    enemies: [EnemyEntityMock.bandit],
    reward: {Resource.gold: 10},
  );

  static const ArenaLevelEntity banditTrio = ArenaLevelEntity(
    id: ArenaLevelId.banditTrio,
    enemies: [EnemyEntityMock.bandit, EnemyEntityMock.bandit, EnemyEntityMock.bandit],
    reward: {Resource.gold: 40},
  );
}
```

`test/mocks/domain/entities/combat/fight_turn_entity_mock.dart`. Registro sin azar de héroe base (4/1/30) contra un bandido (3/0/20): el héroe quita 4 por golpe; el bandido, `max(1, 3 − 1) = 2`.

```dart
import 'package:rpg/core/config/constants/enum/fight_action.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/domain/entities/combat/fight_turn_entity.dart';

abstract final class FightTurnEntityMock {
  static FightTurnEntity heroHits({required int round, required int damage, required int enemyHealthAfter}) =>
      FightTurnEntity(
        round: round,
        actor: FightSide.hero,
        actorIndex: 0,
        target: FightSide.enemy,
        targetIndex: 0,
        action: FightAction.hit,
        damage: damage,
        targetHealthAfter: enemyHealthAfter,
      );

  static FightTurnEntity enemyHits({required int round, required int damage, required int heroHealthAfter}) =>
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: 0,
        target: FightSide.hero,
        targetIndex: 0,
        action: FightAction.hit,
        damage: damage,
        targetHealthAfter: heroHealthAfter,
      );

  static List<FightTurnEntity> victoryOverBandit() => [
    heroHits(round: 1, damage: 4, enemyHealthAfter: 16),
    enemyHits(round: 1, damage: 2, heroHealthAfter: 28),
    heroHits(round: 2, damage: 4, enemyHealthAfter: 12),
    enemyHits(round: 2, damage: 2, heroHealthAfter: 26),
    heroHits(round: 3, damage: 4, enemyHealthAfter: 8),
    enemyHits(round: 3, damage: 2, heroHealthAfter: 24),
    heroHits(round: 4, damage: 4, enemyHealthAfter: 4),
    enemyHits(round: 4, damage: 2, heroHealthAfter: 22),
    heroHits(round: 5, damage: 4, enemyHealthAfter: 0),
  ];

  static List<FightTurnEntity> defeatByBrute() => [
    heroHits(round: 1, damage: 1, enemyHealthAfter: 54),
    enemyHits(round: 1, damage: 30, heroHealthAfter: 0),
  ];

  static List<FightTurnEntity> allActions() => [
    heroHits(round: 1, damage: 4, enemyHealthAfter: 16),
    const FightTurnEntity(
      round: 1,
      actor: FightSide.enemy,
      actorIndex: 0,
      target: FightSide.hero,
      targetIndex: 0,
      action: FightAction.dodge,
      damage: 0,
      targetHealthAfter: 30,
    ),
    heroHits(round: 2, damage: 4, enemyHealthAfter: 12),
    enemyHits(round: 2, damage: 22, heroHealthAfter: 8),
    const FightTurnEntity(
      round: 2,
      actor: FightSide.hero,
      actorIndex: 0,
      target: FightSide.hero,
      targetIndex: 0,
      action: FightAction.secondWind,
      damage: 0,
      targetHealthAfter: 20,
    ),
    heroHits(round: 3, damage: 4, enemyHealthAfter: 8),
    const FightTurnEntity(
      round: 3,
      actor: FightSide.hero,
      actorIndex: 0,
      target: FightSide.enemy,
      targetIndex: 0,
      action: FightAction.doubleStrike,
      damage: 4,
      targetHealthAfter: 4,
    ),
    enemyHits(round: 3, damage: 2, heroHealthAfter: 18),
    heroHits(round: 4, damage: 4, enemyHealthAfter: 0),
  ];
}
```

`test/mocks/domain/entities/combat/fight_log_entity_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/fight_outcome.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/combat/fight_log_entity.dart';

import '../hero/combat_stats_entity_mock.dart';
import 'enemy_entity_mock.dart';
import 'fight_turn_entity_mock.dart';

abstract final class FightLogEntityMock {
  static FightLogEntity victoryOverBandit() => FightLogEntity(
    levelId: ArenaLevelId.banditRookie,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.bandit],
    turns: FightTurnEntityMock.victoryOverBandit(),
    outcome: FightOutcome.victory,
    reward: const {Resource.gold: 10},
  );

  static FightLogEntity defeatByBrute() => FightLogEntity(
    levelId: ArenaLevelId.barbarian,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.brute],
    turns: FightTurnEntityMock.defeatByBrute(),
    outcome: FightOutcome.defeat,
    reward: const {},
  );

  static FightLogEntity allActions() => FightLogEntity(
    levelId: ArenaLevelId.banditRookie,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.bandit],
    turns: FightTurnEntityMock.allActions(),
    outcome: FightOutcome.victory,
    reward: const {Resource.gold: 10},
  );
}
```

En `test/mocks/domain/world/world_mock.dart`, añadir el parámetro `HeroEntity hero = HeroEntityMock.mock` a `make` (pasado a `World(...)`) y:

```dart
  static World withHero(HeroEntity hero) => make(hero: hero);
```

- [ ] **Step 4: Escribir los tests de entidades que fallan**

`test/layers/domain/entities/hero/combat_stats_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';

void main() {
  test('testWhenComputingPowerThenItWeighsAttackDefenseAndHalfTheHealth', () {
    // given
    const stats = CombatStatsEntityMock.heroBase;

    // when
    final power = stats.power;

    // then
    expect(power, 31);
  });

  test('testWhenCopyingWithAttackThenDefenseAndHealthAreKept', () {
    // given
    const stats = CombatStatsEntityMock.heroBase;

    // when
    final copy = stats.copyWith(attack: 7, defense: 3, health: 40);

    // then
    expect(copy, CombatStatsEntityMock.heroWithShortSwordAndLeather);
    expect(copy.hashCode, CombatStatsEntityMock.heroWithShortSwordAndLeather.hashCode);
  });
}
```

`test/layers/domain/entities/hero/hero_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';

import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';

void main() {
  test('testWhenCreatingAHeroThenItStartsWithBasicGearNoSkillsAndNoFights', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final values = (hero.weaponTier, hero.armorTier, hero.skills, hero.clearedLevels, hero.fightsFought);

    // then
    expect(values, (0, 0, isEmpty, isEmpty, 0));
  });

  test('testWhenCopyingWithTiersThenSkillsAndProgressAreKept', () {
    // given
    const hero = HeroEntityMock.withTwoSkills;

    // when
    final copy = hero.copyWith(weaponTier: 3, armorTier: 3, skills: {...hero.skills, SkillId.secondWind});

    // then
    expect(copy, HeroEntityMock.fullyGeared);
    expect(copy.hashCode, HeroEntityMock.fullyGeared.hashCode);
  });

  test('testWhenSkillsDifferThenHeroesAreNotEqual', () {
    // given
    const hero = HeroEntityMock.withShortSwordAndLeather;

    // when
    final equal = hero == HeroEntityMock.withTwoSkills;

    // then
    expect(equal, isFalse);
  });
}
```

`test/layers/domain/entities/combat/arena_level_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/arena_level_entity_mock.dart';

void main() {
  test('testWhenComputingLevelPowerThenItAddsThePowerOfEveryEnemy', () {
    // given
    const level = ArenaLevelEntityMock.banditTrio;

    // when
    final power = level.power;

    // then
    expect(power, 57);
  });
}
```

Cálculo: un bandido es `3 × 3 + 0 × 4 + 20 ~/ 2 = 19`; tres, 57.

`test/layers/domain/entities/combat/fight_log_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/fight_log_entity_mock.dart';

void main() {
  test('testWhenTheHeroWinsThenTheLogIsAVictoryWithItsLastRound', () {
    // given
    final log = FightLogEntityMock.victoryOverBandit();

    // when
    final summary = (log.isVictory, log.rounds);

    // then
    expect(summary, (true, 5));
  });

  test('testWhenTheHeroLosesThenTheLogIsNotAVictory', () {
    // given
    final log = FightLogEntityMock.defeatByBrute();

    // when
    final summary = (log.isVictory, log.rounds);

    // then
    expect(summary, (false, 1));
  });

  test('testWhenTwoLogsHaveTheSameTurnsThenTheyAreEqual', () {
    // given
    final log = FightLogEntityMock.victoryOverBandit();

    // when
    final other = FightLogEntityMock.victoryOverBandit();

    // then
    expect(other, log);
    expect(other.hashCode, log.hashCode);
  });
}
```

- [ ] **Step 5: Ver que fallan**

Run: `flutter test test/layers/domain/entities/hero test/layers/domain/entities/combat`
Expected: FAIL al compilar (las entidades no existen).

- [ ] **Step 6: Implementar las entidades**

Todas siguen el patrón de `PlayerEntity`: campos `final`, constructor `const`, `copyWith`, `==`/`hashCode` escritos a mano (colecciones con `ListEquality` / `SetEquality` / `MapEquality` de `package:collection`, como `InventoryEntity`). Sin comentarios.

`lib/layers/domain/entities/hero/combat_stats_entity.dart`:

```dart
class CombatStatsEntity {
  final int attack;
  final int defense;
  final int health;

  const CombatStatsEntity({required this.attack, required this.defense, required this.health})
    : assert(attack >= 0),
      assert(defense >= 0),
      assert(health > 0);

  int get power => attack * 3 + defense * 4 + health ~/ 2;

  CombatStatsEntity copyWith({int? attack, int? defense, int? health}) {
    return CombatStatsEntity(
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      health: health ?? this.health,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CombatStatsEntity && other.attack == attack && other.defense == defense && other.health == health;

  @override
  int get hashCode => Object.hash(attack, defense, health);

  @override
  String toString() => 'CombatStatsEntity(attack: $attack, defense: $defense, health: $health)';
}
```

`lib/layers/domain/entities/hero/hero_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

class HeroEntity {
  final int weaponTier;
  final int armorTier;
  final Set<SkillId> skills;
  final Set<ArenaLevelId> clearedLevels;
  final int fightsFought;

  const HeroEntity({
    this.weaponTier = 0,
    this.armorTier = 0,
    this.skills = const {},
    this.clearedLevels = const {},
    this.fightsFought = 0,
  }) : assert(weaponTier >= 0),
       assert(armorTier >= 0),
       assert(fightsFought >= 0);

  HeroEntity copyWith({
    int? weaponTier,
    int? armorTier,
    Set<SkillId>? skills,
    Set<ArenaLevelId>? clearedLevels,
    int? fightsFought,
  }) {
    return HeroEntity(
      weaponTier: weaponTier ?? this.weaponTier,
      armorTier: armorTier ?? this.armorTier,
      skills: skills ?? this.skills,
      clearedLevels: clearedLevels ?? this.clearedLevels,
      fightsFought: fightsFought ?? this.fightsFought,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HeroEntity &&
      other.weaponTier == weaponTier &&
      other.armorTier == armorTier &&
      const SetEquality<SkillId>().equals(other.skills, skills) &&
      const SetEquality<ArenaLevelId>().equals(other.clearedLevels, clearedLevels) &&
      other.fightsFought == fightsFought;

  @override
  int get hashCode => Object.hash(
    weaponTier,
    armorTier,
    const SetEquality<SkillId>().hash(skills),
    const SetEquality<ArenaLevelId>().hash(clearedLevels),
    fightsFought,
  );
}
```

`lib/layers/domain/entities/hero/hero_status_entity.dart`: campos `hero`, `stats`, `power`; `copyWith`, `==`, `hashCode`, igual que las anteriores.

`lib/layers/domain/entities/gear/gear_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/gear_id.dart';
import '../../../../core/config/constants/enum/gear_slot.dart';
import '../../../../core/config/constants/enum/resource.dart';

class GearEntity {
  final GearId id;
  final GearSlot slot;
  final int tier;
  final Map<Resource, int> cost;
  final int attack;
  final int defense;
  final int health;

  const GearEntity({
    required this.id,
    required this.slot,
    required this.tier,
    required this.cost,
    this.attack = 0,
    this.defense = 0,
    this.health = 0,
  }) : assert(tier >= 0),
       assert(attack >= 0),
       assert(defense >= 0),
       assert(health >= 0);

  GearEntity copyWith({
    GearId? id,
    GearSlot? slot,
    int? tier,
    Map<Resource, int>? cost,
    int? attack,
    int? defense,
    int? health,
  }) {
    return GearEntity(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      tier: tier ?? this.tier,
      cost: cost ?? this.cost,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      health: health ?? this.health,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GearEntity &&
      other.id == id &&
      other.slot == slot &&
      other.tier == tier &&
      const MapEquality<Resource, int>().equals(other.cost, cost) &&
      other.attack == attack &&
      other.defense == defense &&
      other.health == health;

  @override
  int get hashCode =>
      Object.hash(id, slot, tier, const MapEquality<Resource, int>().hash(cost), attack, defense, health);
}
```

`lib/layers/domain/entities/combat/enemy_entity.dart`: campos `kind: EnemyKind`, `stats: CombatStatsEntity`; `copyWith`, `==`, `hashCode`.

`lib/layers/domain/entities/combat/arena_level_entity.dart`:

```dart
import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'enemy_entity.dart';

class ArenaLevelEntity {
  final ArenaLevelId id;
  final List<EnemyEntity> enemies;
  final Map<Resource, int> reward;

  const ArenaLevelEntity({required this.id, required this.enemies, required this.reward})
    : assert(enemies.length >= 1 && enemies.length <= 3);

  int get power => enemies.fold(0, (sum, enemy) => sum + enemy.stats.power);

  ArenaLevelEntity copyWith({ArenaLevelId? id, List<EnemyEntity>? enemies, Map<Resource, int>? reward}) {
    return ArenaLevelEntity(id: id ?? this.id, enemies: enemies ?? this.enemies, reward: reward ?? this.reward);
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaLevelEntity &&
      other.id == id &&
      const ListEquality<EnemyEntity>().equals(other.enemies, enemies) &&
      const MapEquality<Resource, int>().equals(other.reward, reward);

  @override
  int get hashCode => Object.hash(
    id,
    const ListEquality<EnemyEntity>().hash(enemies),
    const MapEquality<Resource, int>().hash(reward),
  );
}
```

`lib/layers/domain/entities/combat/fight_turn_entity.dart`: los 8 campos de *Interfaces*, `assert(damage >= 0)` y `assert(targetHealthAfter >= 0)`, `copyWith`, `==`, `hashCode` y `toString` (ayuda a leer los fallos de los tests del motor).

`lib/layers/domain/entities/combat/fight_log_entity.dart`: los 6 campos de *Interfaces* y

```dart
  bool get isVictory => outcome == FightOutcome.victory;

  int get rounds => turns.isEmpty ? 0 : turns.last.round;
```

con `copyWith`, `==` y `hashCode` (`ListEquality` en `enemies` y `turns`, `MapEquality` en `reward`).

- [ ] **Step 7: Ver que pasan**

Run: `flutter test test/layers/domain/entities/hero test/layers/domain/entities/combat`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/config/constants/enum lib/layers/domain/entities/hero lib/layers/domain/entities/gear lib/layers/domain/entities/combat test/layers/domain/entities/hero test/layers/domain/entities/combat test/mocks/domain/entities/hero test/mocks/domain/entities/combat
git commit -m "[PROJECT-X]: Add the hero and combat entities"
```

- [ ] **Step 9: Tests del catálogo `Gear` y de `HeroRules` que fallan**

`test/layers/domain/rules/gear_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/layers/domain/rules/gear.dart';

void main() {
  test('testWhenListingGearThenEveryGearIdAppearsOnce', () {
    // given
    final ids = Gear.all.map((gear) => gear.id).toList();

    // when
    final unique = ids.toSet();

    // then
    expect(ids, hasLength(GearId.values.length));
    expect(unique, GearId.values.toSet());
  });

  test('testWhenListingEachSlotThenTiersGoFromZeroToMaxWithoutGaps', () {
    for (final slot in GearSlot.values) {
      // given
      final tiers = Gear.all.where((gear) => gear.slot == slot).map((gear) => gear.tier).toList()..sort();

      // when
      final expected = List.generate(Gear.maxTier(slot) + 1, (tier) => tier);

      // then
      expect(tiers, expected);
    }
  });

  test('testWhenLookingAtTierZeroThenItIsFree', () {
    for (final slot in GearSlot.values) {
      // given
      final basic = Gear.of(slot, 0);

      // when
      final cost = basic.cost;

      // then
      expect(cost, isEmpty);
    }
  });

  test('testWhenLookingForATierOutOfRangeThenThereIsNone', () {
    // given
    const slot = GearSlot.weapon;

    // when
    final gear = Gear.find(slot, Gear.maxTier(slot) + 1);

    // then
    expect(gear, isNull);
  });

  test('testWhenFindingByIdThenItReturnsThatGear', () {
    // given
    const id = GearId.chainMail;

    // when
    final gear = Gear.byId(id);

    // then
    expect((gear.slot, gear.tier), (GearSlot.armor, 2));
  });
}
```

`test/layers/domain/world/extensions/hero_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/layers/domain/rules/gear.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';

import '../../../../mocks/domain/entities/hero/combat_stats_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';

void main() {
  test('testWhenTheHeroHasBasicGearThenStatsAreTheBaseStats', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final stats = hero.stats;

    // then
    expect(stats, CombatStatsEntityMock.heroBase);
    expect(hero.power, 31);
  });

  test('testWhenTheHeroHasShortSwordAndLeatherThenStatsAddBothPieces', () {
    // given
    const hero = HeroEntityMock.withShortSwordAndLeather;

    // when
    final stats = hero.stats;

    // then
    expect(stats, CombatStatsEntityMock.heroWithShortSwordAndLeather);
  });

  test('testWhenTheHeroKnowsTwoSkillsThenPowerGrowsTwentyPercent', () {
    // given
    const hero = HeroEntityMock.withTwoSkills;

    // when
    final power = hero.power;

    // then
    expect(power, 64);
  });

  test('testWhenTheHeroIsFullyGearedThenThereIsNoNextGear', () {
    // given
    const hero = HeroEntityMock.fullyGeared;

    // when
    final next = (hero.nextGear(GearSlot.weapon), hero.nextGear(GearSlot.armor));

    // then
    expect(next, (null, null));
    expect(hero.stats, CombatStatsEntityMock.heroFullyGeared);
    expect(hero.power, 144);
  });

  test('testWhenEquippingGearThenOnlyItsSlotTierChanges', () {
    // given
    const hero = HeroEntityMock.mock;

    // when
    final equipped = hero.withGear(Gear.byId(GearId.ironSword));

    // then
    expect((equipped.tierOf(GearSlot.weapon), equipped.tierOf(GearSlot.armor)), (2, 0));
    expect(equipped.equipped(GearSlot.weapon).id, GearId.ironSword);
  });
}
```

Cálculos: 7 × 3 + 3 × 4 + 40 / 2 = 53 → × 1,2 = 63,6 → 64. Equipo completo: 14 × 3 + 8 × 4 + 75 ~/ 2 = 42 + 32 + 37 = 111 → × 1,3 = 144,3 → 144.

Run: `flutter test test/layers/domain/rules/gear_test.dart test/layers/domain/world/extensions/hero_rules_test.dart`
Expected: FAIL al compilar.

- [ ] **Step 10: Implementar `Gear`, `Rules.powerPerSkill` y `HeroRules`**

`lib/layers/domain/rules/gear.dart` (valores orientativos; C7 los equilibra):

```dart
import '../../../core/config/constants/enum/gear_id.dart';
import '../../../core/config/constants/enum/gear_slot.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/gear/gear_entity.dart';

abstract final class Gear {
  static const List<GearEntity> all = [
    GearEntity(id: GearId.woodcutterAxe, slot: GearSlot.weapon, tier: 0, cost: {}, attack: 4),
    GearEntity(
      id: GearId.shortSword,
      slot: GearSlot.weapon,
      tier: 1,
      cost: {Resource.wood: 20, Resource.gold: 10},
      attack: 7,
    ),
    GearEntity(
      id: GearId.ironSword,
      slot: GearSlot.weapon,
      tier: 2,
      cost: {Resource.wood: 30, Resource.gold: 40},
      attack: 10,
    ),
    GearEntity(
      id: GearId.steelSword,
      slot: GearSlot.weapon,
      tier: 3,
      cost: {Resource.wood: 40, Resource.gold: 120},
      attack: 14,
    ),
    GearEntity(id: GearId.workClothes, slot: GearSlot.armor, tier: 0, cost: {}, defense: 1, health: 30),
    GearEntity(
      id: GearId.leatherArmor,
      slot: GearSlot.armor,
      tier: 1,
      cost: {Resource.wood: 15, Resource.gold: 15},
      defense: 3,
      health: 40,
    ),
    GearEntity(
      id: GearId.chainMail,
      slot: GearSlot.armor,
      tier: 2,
      cost: {Resource.wood: 30, Resource.gold: 50},
      defense: 5,
      health: 55,
    ),
    GearEntity(
      id: GearId.plateArmor,
      slot: GearSlot.armor,
      tier: 3,
      cost: {Resource.wood: 40, Resource.gold: 150},
      defense: 8,
      health: 75,
    ),
  ];

  static GearEntity byId(GearId id) => all.firstWhere((gear) => gear.id == id);

  static GearEntity of(GearSlot slot, int tier) => find(slot, tier)!;

  static GearEntity? find(GearSlot slot, int tier) =>
      all.where((gear) => gear.slot == slot && gear.tier == tier).firstOrNull;

  static int maxTier(GearSlot slot) =>
      all.where((gear) => gear.slot == slot).fold(0, (max, gear) => gear.tier > max ? gear.tier : max);
}
```

En `lib/layers/domain/rules/rules.dart`, al final de la clase:

```dart
  static const double powerPerSkill = 0.1;
```

`lib/layers/domain/world/extensions/hero_rules.dart`:

```dart
import '../../../../core/config/constants/enum/gear_slot.dart';
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

  CombatStatsEntity get stats {
    final weapon = equipped(GearSlot.weapon);
    final armor = equipped(GearSlot.armor);
    return CombatStatsEntity(
      attack: weapon.attack + armor.attack,
      defense: weapon.defense + armor.defense,
      health: weapon.health + armor.health,
    );
  }

  int get power => (stats.power * (1 + skills.length * Rules.powerPerSkill)).round();

  HeroEntity withGear(GearEntity gear) => switch (gear.slot) {
    GearSlot.weapon => copyWith(weaponTier: gear.tier),
    GearSlot.armor => copyWith(armorTier: gear.tier),
  };
}
```

Run: `flutter test test/layers/domain/rules/gear_test.dart test/layers/domain/world/extensions/hero_rules_test.dart`
Expected: PASS.

- [ ] **Step 11: El héroe dentro del `World`**

Test que falla, `test/layers/domain/world/world_hero_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/layers/domain/rules/gear.dart';
import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';

import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenCreatingAWorldWithoutHeroThenTheHeroIsTheBasicOne', () {
    // given
    final world = WorldMock.make();

    // when
    final hero = world.hero;

    // then
    expect(hero, HeroEntityMock.mock);
  });

  test('testWhenCreatingAWorldWithAHeroThenItKeepsThatHero', () {
    // given
    final world = WorldMock.withHero(HeroEntityMock.veteran);

    // when
    final hero = world.hero;

    // then
    expect(hero, HeroEntityMock.veteran);
  });

  test('testWhenUpdatingTheHeroThenTheWorldKeepsTheNewHero', () {
    // given
    final world = WorldMock.make();

    // when
    world.updateHero((hero) => hero.withGear(Gear.byId(GearId.shortSword)).withGear(Gear.byId(GearId.leatherArmor)));

    // then
    expect(world.hero, HeroEntityMock.withShortSwordAndLeather);
  });
}
```

Run: `flutter test test/layers/domain/world/world_hero_test.dart`
Expected: FAIL al compilar.

Implementación:
- `WorldState`: parámetro `HeroEntity hero = const HeroEntity()` en el constructor (inicializa el campo) y campo mutable `HeroEntity hero;`, junto a `player`.
- `World`: parámetro `HeroEntity hero = const HeroEntity()` en el constructor público, pasado a `WorldState`; y, después de `buildings`:

```dart
  HeroEntity get hero => _state.hero;
```

  y, después de `spend`:

```dart
  void updateHero(HeroEntity Function(HeroEntity hero) transform) {
    _state.hero = transform(_state.hero);
  }
```

Run: `flutter test test/layers/domain/world`
Expected: PASS (los tests de mundo que ya había siguen igual).

- [ ] **Step 12: `GetHeroStatusUseCase`**

Test que falla, `test/layers/domain/use-cases/hero/get_hero_status_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/domain/use-cases/hero/get_hero_status_use_case.dart';

import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../mocks/domain/entities/hero/hero_status_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetHeroStatusUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetHeroStatusUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenNoGameInProgressThenFailsWithNoGameInProgress', () {
    // given
    when(sessionRepository.current()).thenThrow(AppExceptionMock.noGameInProgress);

    // when
    void action() => sut();

    // then
    expect(action, throwsA(isA<NoGameInProgressException>()));
  });

  test('testWhenTheHeroHasBasicGearThenStatusHasBaseStatsAndPower', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(WorldMock.withHero(HeroEntityMock.mock)));

    // when
    final status = sut();

    // then
    expect(status, HeroStatusEntityMock.base);
  });
}
```

Implementación, `lib/layers/domain/use-cases/hero/get_hero_status_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../entities/hero/hero_status_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class GetHeroStatusUseCase {
  final GameSessionRepository _sessionRepository;

  const GetHeroStatusUseCase({required this._sessionRepository});

  HeroStatusEntity call() {
    final hero = _sessionRepository.current().world.hero;
    return HeroStatusEntity(hero: hero, stats: hero.stats, power: hero.power);
  }
}
```

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/layers/domain/use-cases/hero test/core/config/di/di_test.dart
```

Expected: PASS; `di.config.dart` registra `GetHeroStatusUseCase`.

- [ ] **Step 13: Documentar en `CLAUDE.md`**

En *Architecture* → `lib/layers/domain/`:
- `entities/<feature>/`: añadir hero (`CombatStatsEntity`, `HeroEntity`, `HeroStatusEntity`), gear (`GearEntity`) y combat (`EnemyEntity`, `ArenaLevelEntity`, `FightTurnEntity`, `FightLogEntity`).
- `world/`: "`World` also owns the hero (`hero`, `updateHero`) and the funds (`funds`, `earn`, `spend`: the only way to pay or get paid)". `world/extensions/` gana `HeroRules`.
- `rules/`: añadir `Gear`.
- `use-cases/`: añadir `hero/` (`GetHeroStatusUseCase`).
- E1: "`domain/world/`, `domain/quests/`, `domain/rules/` (and `domain/combat/` from the arena plan) exist besides…".

Commit de `CLAUDE.md` **en un comando aparte** del resto (regla del hook de git).

- [ ] **Step 14: Verificación completa y commit**

```bash
dart format --line-length 120 $(git diff --name-only --diff-filter=AM develop -- 'lib/**/*.dart' 'test/**/*.dart' | grep -v -e 'di.config.dart' -e '.mocks.dart')
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `No issues found!` y todo en verde.

```bash
git add lib test
git commit -m "[PROJECT-X]: Keep the hero and its gear inside the world"
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the hero, gear and funds in the project guide"
```

Prueba manual en Chrome, en el emulador Android y en el simulador iOS: el juego se comporta igual que tras TC0.1.

---

## Al cerrar C0

- Marca los checkboxes de las dos tareas.
- Avisa al otro desarrollador: desde aquí, el flujo C (C1) y el flujo D (C3) arrancan en paralelo.
- Si alguna firma de *Interfaces* cambió al implementar, actualízala en este fichero **y** en las fichas de C1–C7 que la usan, y apúntalo en la sección 5 del README.
