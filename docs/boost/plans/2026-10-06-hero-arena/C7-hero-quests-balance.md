# C7 · Misiones del héroe y equilibrado — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | D (héroe) |
| **Depende de** | C1, C3, C5 y, como ya están en `feature/PROJECT-X-arena`, también C4 y C6 (el test de equilibrado recorre `ArenaLevels.all`) |
| **Issue / milestone** | `phase:C7` · `stream:D` · milestone `C7 Hero quests and balance` (issue #40 para toda la fase) |

**Goal:** Guiar al jugador por el modo nuevo con una línea de misiones del héroe y dejar los números de la arena (daño, equipo, niveles y oro) equilibrados y protegidos por un test.

**Architecture:**
- **Daño por rangos (ARENA-FIXES §4):** `CombatStatsEntity` y `GearEntity` cambian `attack` por `attackMin` / `attackMax`. `Combat._damage` elige un valor del rango del atacante con el mismo `next()` de siempre (el orden de llamadas no cambia) y hace `max(1, valor − defensa)`, sin el ±15 % (`Rules.damageSpread` desaparece). El Poder usa el ataque medio. El panel *Héroe* y las opciones de compra muestran "Ataque 3–5".
- **Líneas de misiones:** enum de core `QuestLine { village, hero }`; `Quest.line`; ocho `QuestId` nuevos al final con sus misiones al final de `Quests.all`. `QuestLog` calcula "la actual" **por línea** y `QuestProgressEntity` / `QuestItemData` llevan la línea. `QuestPanel` pinta una sección por línea (*Aldea*, *Héroe*). Al terminar todas las misiones de una línea sale "¡Has completado las misiones de {línea}!".
- **Equipo sólo con oro y equilibrado (ARENA-FIXES §2):** `Gear.all` deja de pedir madera. `test/layers/domain/combat/balance_test.dart` simula cada nivel con 100 semillas para el héroe esperado de `BalanceScenarioMock` y comprueba victorias, derrotas con un escalón menos y que el oro alcanza. Los números de `Gear.all` y `ArenaLevels.all` son los que hacen pasar ese test; la tabla final va a `docs/GAME_DESIGN.md` (sección 3.8).

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, `easy_localization`; tests con `flutter_test`, `bloc_test`, `mockito`. Sin arte nuevo.

**Precondición: C6 fusionada en `feature/PROJECT-X-arena`** (merge de la #51, `17b6f09`). Este plan usa exactamente estas firmas. Antes de empezar, comprueba que no han cambiado:
- `CombatStatsEntity({required attack, required defense, required health})` con `power => attack * 3 + defense * 4 + health ~/ 2`; `GearEntity({…, attack = 0, defense = 0, health = 0})`; `HeroRules.stats` / `power` / `tierOf`;
- `Combat._damage({required int attack, required int defense, required int healthLeft})` con `Rules.damageSpread = 0.15`;
- `Gear.all` con costes de madera y oro; `Skills.all` (60 / 90 / 130 de oro); `Blueprints.mageTower` (30 de madera y 40 de oro); `ArenaLevels.all` (10 niveles, `championship = barbarianChief`);
- `Quest { id, target, progress(World) }`, `Quests.all` (3 misiones), `QuestLog.status` con una sola misión actual, `QuestProgressEntity(id, progress, target, isCompleted, isCurrent)`, `QuestItemData(title, progressText, status)`, `QuestPanel(quests:)`;
- `HeroPanelData.attack` (`int`), `Internationalize.forestHeroWeaponStats({required int attack})`, `forestMessageAllQuestsCompleted`;
- mocks `CombatStatsEntityMock`, `FightTurnEntityMock`, `FighterRenderDataMock`, `ArenaEffectMock`, `ArenaLevelItemDataMock`, `ArenaResultDataMock`, `FundsMock`, `GearItemDataMock`, `HeroPanelDataMock`, `QuestProgressEntityMock`, `QuestItemDataMock`.

Si algo ha cambiado, los parches de este plan no se aplicarán limpios: adapta los fragmentos y apúntalo en la sección 5 del README.

**Cómo probar la fase entera:**
- `flutter test` en verde: **637 tests** (630 antes; TC7.1 +1, TC7.2 +2, TC7.3 +4), con el test de equilibrado.
- La prueba manual de la sección *Prueba manual* en Chrome y Android (iOS se comporta igual).

**Cómo se ha comprobado este plan (2026-10-09):** en un worktree desechable sobre `feature/PROJECT-C6-barbarians` (`c2afe99`, mismo árbol que `17b6f09`):
- se aplicaron las tres tareas en orden, con un commit por tarea; los parches de este documento son exactamente esos commits (`git diff`), separados en tests, código y documentación;
- tras cada tarea, `flutter analyze` → `No issues found!` y `flutter test` en verde: **631** (TC7.1), **633** (TC7.2) y **637** (TC7.3). `build_runner` no cambia nada (no hay clases inyectables nuevas);
- los números de TC7.3 salieron de una búsqueda por simulación (ataque y vida de cada enemigo, con su defensa fija) que buscaba un 70–90 % de victorias con el héroe esperado y menos del 45 % con el escalón anterior, prefiriendo los valores más cercanos a los de C1/C4/C6. La economía se cuadró a mano (decisión 6) y la comprueba el test.

## Decisiones del plan

1. **Rangos de ataque.** `attackMin` / `attackMax` en `CombatStatsEntity` y `GearEntity` (`assert(attackMax >= attackMin)`). En cada golpe: `valor = attackMin + floor(next() × (attackMax − attackMin + 1))` y `daño = min(vida que le queda, max(1, valor − defensa))`. Sigue siendo **un `next()` por golpe** y otro por ataque enemigo cuando el héroe puede esquivar: el contrato de `CLAUDE.md` no cambia.
2. **Poder:** `(attackMin + attackMax) × 3 ~/ 2 + defensa × 4 + vida ~/ 2`. Con rangos centrados en el ataque de antes (hacha 3–5, espada corta 6–8, de hierro 9–11, de acero 12–16) el Poder del héroe no cambia (31 al empezar, 144 con todo y tres habilidades).
3. **Textos:** `forest.hero.attackRange` = "{min}–{max}" (el panel *Héroe*: "Ataque 3–5"); `forest.hero.weaponStats` = "Ataque {min}–{max}". `HeroPanelData.attack` pasa a `String` (el texto del rango) y `HeroPanel._stat` recibe el valor ya formateado.
4. **TC7.1 convierte los números sin equilibrarlos:** las armas, con los rangos de la decisión 2; los enemigos, `ataque ± 1` (`± 2` desde 9 de ataque). Los mocks de tests del motor (`CombatStatsEntityMock`) hacen lo mismo y los registros dorados (`FightTurnEntityMock.victoryOverBandit`, `almostBeatDuelist`, `defeatByBruteFullyGeared`) se recalculan con la semilla de siempre. El equilibrado de verdad es TC7.3.
5. **Misiones del héroe** (al final de `QuestId` y de `Quests.all`, línea `hero`, todas miden el `World`):

   | Misión | Mide | Objetivo | Texto |
   |---|---|---|---|
   | `buildForge` | Herrería terminada | 1 | Construye la Herrería |
   | `winFirstFight` | `hero.clearedLevels.isNotEmpty` | 1 | Gana un nivel de la arena |
   | `buyFirstWeapon` | `hero.weaponTier >= 1` | 1 | Compra la Espada corta |
   | `buildArmory` | Armería terminada | 1 | Construye la Armería |
   | `buildMageTower` | Torre de magia terminada | 1 | Construye la Torre de magia |
   | `learnASkill` | `hero.skills.isNotEmpty` | 1 | Aprende una habilidad |
   | `clearHalfArena` | niveles ganados | `ArenaLevels.all.length ~/ 2` (5) | Gana la mitad de los niveles de la arena |
   | `becomeChampion` | `hero.isChampion` (C6) | 1 | Gana al Jefe bárbaro |

   - Los edificios se miden con `BuildingListRules.hasComplete` (C3); `buildHouse` pasa a usar el mismo helper (antes contaba casas; con objetivo 1 no cambia nada).
   - `QuestLog.status`: la misión actual es la primera pendiente **de cada línea**, así que al empezar hay dos actuales (`pickUpAxe` y `buildForge`). El orden de `Quests.all` sigue siendo el de la lista.
   - El distintivo del botón *Misiones* cuenta todas ("0/11").
   - **Mensaje de cierre por línea:** `forest.message.allQuestsCompleted` se sustituye por `forest.message.questLineCompleted` = "¡Has completado las misiones de {line}!" ({line} = *Aldea* / *Héroe*, `forest.questLine.*`). Sale cuando se completa la última misión de esa línea; el resto, "Misión completada: …" como siempre.
   - F4 (misiones del capítulo 1) no está: el recorte de la ficha (completadas recogidas, actual y dos pendientes) se aplicará por sección cuando llegue.
6. **Economía (equipo sólo con oro):**
   - Precios: espada corta **30**, de hierro **60**, de acero **110**; cuero **40**, cota de malla **70**, placas **120**. Habilidades sin cambios (60 / 90 / 130). Edificios sin cambios (la Torre sigue pidiendo 30 de madera y 40 de oro).
   - Recompensas (primera vez): 10, 20, 30, 40, 55, 75, 90, 100, 120, 150. Repetir da un tercio (`Rules.repeatRewardDivisor`), como siempre.
   - Héroe esperado (`BalanceScenarioMock.expectedHero`): inicial en los niveles 1 y 2; espada corta en el 3; + cuero en el 4; + espada de hierro en el 5; + cota de malla en el 6; + *Golpe doble* en el 7; + *Esquiva* en el 8; + espada de acero en el 9; + placas en el 10. *Segundo aliento* queda como mejora opcional (no se necesita para el jefe).
   - Comprobación: oro gastado en el héroe esperado (equipo, habilidades y el oro de la Torre si tiene habilidades) ≤ primeras victorias de los niveles anteriores + 3 repeticiones del anterior. Por niveles: 0 ≤ 0, 0 ≤ 19, 30 ≤ 48, 70 ≤ 90, 130 ≤ 139, 200 ≤ 209, 300 ≤ 305, 390 ≤ 410, 500 ≤ 519 y 620 ≤ 660.
7. **Enemigos (Ataque / Defensa / Vida, Poder del nivel):**

   | Nivel | Enemigos | Poder | Oro |
   |---|---|---|---|
   | Bandido novato | 2–4 / 0 / 20 | 19 | 10 |
   | Lobo | 4–6 / 1 / 20 | 29 | 20 |
   | Bandido veterano | 4–6 / 2 / 36 | 41 | 30 |
   | Pareja de lobos | 2 × 6–8 / 1 / 18 | 68 | 40 |
   | Oso | 8–12 / 3 / 40 | 62 | 55 |
   | Trío de bandidos | 3 × 7–9 / 1 / 26 | 123 | 75 |
   | Bárbaro | 10–14 / 4 / 58 | 81 | 90 |
   | Manada de lobos | 3 × 8–12 / 1 / 22 | 135 | 100 |
   | Pareja de bárbaros | 2 × 8–12 / 4 / 52 | 144 | 120 |
   | Jefe bárbaro | 16–20 / 5 / 72 + 2 × 7–11 / 2 / 31 | 210 | 150 |

   - El primer nivel **no cambia** (sigue siendo el de los registros dorados) y queda exento del tope del 95 %: la primera pelea se gana siempre con el héroe inicial, a propósito. Los demás, entre el 60 % y el 95 %.
   - El Poder no sube siempre de un nivel al siguiente (el oso es uno solo; los grupos suman a todos). La lista sigue ordenada por dificultad real, que es la de la simulación.
8. **Test de equilibrado** (`balance_test.dart` + `test/mocks/domain/game/balance_scenario_mock.dart`): 100 semillas (0–99) por caso; cuatro tests (la tabla cubre todos los niveles; victorias con el héroe esperado; derrotas con el héroe del nivel anterior cuando es distinto; el oro alcanza). Los umbrales viven en el mock (`minWinRate`, `maxWinRate`, `maxWinRateOneStepBehind`, `maxRepeats`). Si alguien cambia `Gear`, `Skills`, `ArenaLevels` o los costes de los edificios, este test le avisa.
9. **Mocks que cambian por los números** (TC7.3): precios de `FundsMock` (`shortSwordPrice` = 30 de oro), costes de `GearItemDataMock`, poder y oro de `ArenaLevelItemDataMock`, `ArenaResultDataMock` del jefe (150 la primera vez, 50 al repetir: se renombran a `championHundredFiftyGold` / `victoryFiftyGold`) y salud de `FighterRenderDataMock` (veterano 36, lobo 20).
10. **Documentación:** `docs/GAME_DESIGN.md` 3.8 (atributos, tabla de equipo y precios, tabla de niveles); `CLAUDE.md` en cada tarea; `ARENA-FIXES.md` §2 y §4 hechos en C7; README 3.2 (la piedra de F5 va a los edificios, no al equipo).

## Reparto

| Tarea | Qué | Depende de | Paralelizable |
|---|---|---|---|
| TC7.1 Daño por rangos | entidades, `Combat`, `Rules`, `Gear` y `ArenaLevels` convertidos, panel *Héroe* y opciones de compra, mocks y registros dorados | C6 | No: TC7.3 cambia los mismos números |
| TC7.2 Líneas de misiones | `QuestLine`, `QuestId`, `Quest`, `Quests`, `QuestLog`, `QuestProgressEntity`, `QuestItemData`, `QuestPanel`, `ForestBloc`, textos | C6 | Sí, con TC7.1 (sólo comparten `es.json`, `internationalize.dart`, su test y `forest_bloc.dart`, en trozos distintos) |
| TC7.3 Equipo sólo con oro y equilibrado | `Gear` (precios), `ArenaLevels` (números finales), test de equilibrado, mocks, `GAME_DESIGN.md`, `ARENA-FIXES.md`, README | TC7.1 | No |

Los parches se ensayaron en el orden TC7.1 → TC7.2 → TC7.3. Si TC7.1 y TC7.2 se hacen a la vez, la segunda en llegar puede necesitar `git apply --3way` o resolver a mano los cuatro ficheros compartidos (cambios aditivos).

**Ramas (README, sección 3.0, y regla de nombres del 2026-10-09):**
- Rama de fase `feature/PROJECT-C7-hero-quests-balance`, desde `feature/PROJECT-X-arena`. Su PR va a `feature/PROJECT-X-arena`. Las tres tareas, una detrás de otra, en esa rama.
- Commits `[PROJECT-C7]: Imperative description`, sin atribución a IA; `CLAUDE.md` se añade al índice **en un comando aparte**.
- **Cómo aplicar los parches:** guarda cada bloque `diff` en un fichero fuera del repo (por ejemplo `/tmp/c7-t1-test.diff`) y ejecuta `git apply --check <fichero> && git apply <fichero>` desde la raíz. Si `--check` falla, para: algo ha cambiado desde el ensayo (ver *Precondición*).
- Nunca se pasa `dart format` por una carpeta entera de `test/` o `lib/`: reformatea `*.mocks.dart` y `di.config.dart`. Los parches ya están formateados.

---

### Task TC7.1: Daño por rangos

**Files:**
  - Modify: `lib/core/assets/i18n/internationalize.dart`
  - Modify: `lib/core/assets/i18n/translations/es.json`
  - Modify: `lib/layers/domain/combat/combat.dart`
  - Modify: `lib/layers/domain/entities/gear/gear_entity.dart`
  - Modify: `lib/layers/domain/entities/hero/combat_stats_entity.dart`
  - Modify: `lib/layers/domain/rules/arena_levels.dart`
  - Modify: `lib/layers/domain/rules/gear.dart`
  - Modify: `lib/layers/domain/rules/rules.dart`
  - Modify: `lib/layers/domain/world/extensions/hero_rules.dart`
  - Modify: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - Modify: `lib/layers/presentation/features/forest/models/hero_panel_data.dart`
  - Modify: `lib/layers/presentation/features/forest/widgets/hero_panel.dart`
  - Modify: `test/core/assets/i18n/internationalize_test.dart`
  - Modify: `test/layers/domain/combat/combat_test.dart`
  - Modify: `test/layers/domain/entities/hero/combat_stats_entity_test.dart`
  - Modify: `test/layers/domain/use-cases/hero/gear_flow_test.dart`
  - Modify: `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - Modify: `test/layers/presentation/features/arena/models/arena_effect_test.dart`
  - Modify: `test/layers/presentation/features/arena/models/fight_replay_data_test.dart`
  - Modify: `test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart`
  - Modify: `test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart`
  - Modify: `test/mocks/domain/entities/combat/fight_turn_entity_mock.dart`
  - Modify: `test/mocks/domain/entities/hero/combat_stats_entity_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_effect_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`
  - Modify: `test/mocks/presentation/features/forest/gear_item_data_mock.dart`
  - Modify: `test/mocks/presentation/features/forest/hero_panel_data_mock.dart`
  - Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `SeededRandom.next()`, `HeroRules.stats`, `Internationalize`.
- Produces:
  ```dart
  const CombatStatsEntity({required int attackMin, required int attackMax, required int defense, required int health});
  int get power; // (attackMin + attackMax) * 3 ~/ 2 + defense * 4 + health ~/ 2
  const GearEntity({…, int attackMin = 0, int attackMax = 0, int defense = 0, int health = 0});
  static String forestHeroAttackRange({required int min, required int max}); // '3–5'
  static String forestHeroWeaponStats({required int min, required int max}); // 'Ataque 3–5'
  final String attack; // HeroPanelData
  ```
  - mocks nuevos: `ArenaEffectMock.banditHitForThree` / `banditHitForFive` / `heroHitForOne` / `heroHitForThree`, `FighterRenderDataMock.rookieBanditAfterFirstBlow`.

- [ ] **Step 1: Rama**

```bash
git switch feature/PROJECT-X-arena && git pull
git switch -c feature/PROJECT-C7-hero-quests-balance   # si no existe ya
flutter pub get
```

- [ ] **Step 2: Tests y mocks (rojo)**

Aplica este parche (sólo `test/`):

```diff
diff --git a/test/core/assets/i18n/internationalize_test.dart b/test/core/assets/i18n/internationalize_test.dart
index d8e9b47..9776a5a 100644
--- a/test/core/assets/i18n/internationalize_test.dart
+++ b/test/core/assets/i18n/internationalize_test.dart
@@ -167,7 +167,8 @@ void main() {
       Internationalize.forestHeroAttack,
       Internationalize.forestHeroDefense,
       Internationalize.forestHeroHealth,
-      Internationalize.forestHeroWeaponStats(attack: 7),
+      Internationalize.forestHeroAttackRange(min: 6, max: 8),
+      Internationalize.forestHeroWeaponStats(min: 6, max: 8),
       Internationalize.forestHeroArmorStats(defense: 3, health: 40),
       for (final slot in GearSlot.values) Internationalize.forestHeroSlot(slot: slot),
       for (final section in HeroPanelSection.values) Internationalize.forestHeroSection(section: section),
@@ -191,7 +192,8 @@ void main() {
       'Ataque',
       'Defensa',
       'Vida',
-      'Ataque 7',
+      '6–8',
+      'Ataque 6–8',
       'Defensa 3 · Vida 40',
       'Arma',
       'Armadura',
diff --git a/test/layers/domain/combat/combat_test.dart b/test/layers/domain/combat/combat_test.dart
index e13133f..e02fe85 100644
--- a/test/layers/domain/combat/combat_test.dart
+++ b/test/layers/domain/combat/combat_test.dart
@@ -24,6 +24,20 @@ void main() {
       expect(log, FightLogEntityMock.victoryOverBanditBeforeReward());
     });
 
+    test('testWhenAttackIsARangeThenEveryBlowPicksAValueInsideIt', () {
+      // given
+      const level = ArenaLevelEntityMock.duel;
+
+      // when
+      final log = Combat.resolve(level: level, heroStats: CombatStatsEntityMock.heroBase, skills: const {}, seed: 0);
+
+      // then
+      final heroDamage = log.turns.where((turn) => turn.actor == FightSide.hero).map((turn) => turn.damage).toSet();
+      final enemyDamage = log.turns.where((turn) => turn.actor == FightSide.enemy).map((turn) => turn.damage).toList();
+      expect(heroDamage, {3, 4, 5});
+      expect(enemyDamage.take(4).every((damage) => damage >= 6 && damage <= 8), isTrue);
+    });
+
     test('testWhenResolvingTwiceWithTheSameSeedThenTheLogsAreEqual', () {
       // given
       const level = ArenaLevelEntityMock.banditTrio;
@@ -207,8 +221,8 @@ void main() {
         ),
       );
       expect(log.turns[9].targetHealthAfter, 5);
-      expect(log.turns[16].targetHealthAfter, 1);
-      expect((log.outcome, log.rounds), (FightOutcome.defeat, 9));
+      expect(log.turns[16].targetHealthAfter, 0);
+      expect((log.outcome, log.rounds), (FightOutcome.defeat, 8));
     });
 
     test('testWhenNobodyCanHurtTheOtherThenTheFightStopsAtTheRoundLimitAsADefeat', () {
diff --git a/test/layers/domain/entities/hero/combat_stats_entity_test.dart b/test/layers/domain/entities/hero/combat_stats_entity_test.dart
index 2bcd3b6..f431bdf 100644
--- a/test/layers/domain/entities/hero/combat_stats_entity_test.dart
+++ b/test/layers/domain/entities/hero/combat_stats_entity_test.dart
@@ -19,7 +19,7 @@ void main() {
     const stats = CombatStatsEntityMock.heroBase;
 
     // when
-    final copy = stats.copyWith(attack: 7, defense: 3, health: 40);
+    final copy = stats.copyWith(attackMin: 6, attackMax: 8, defense: 3, health: 40);
 
     // then
     expect(copy, CombatStatsEntityMock.heroWithShortSwordAndLeather);
diff --git a/test/layers/domain/use-cases/hero/gear_flow_test.dart b/test/layers/domain/use-cases/hero/gear_flow_test.dart
index 6e99212..fee2f43 100644
--- a/test/layers/domain/use-cases/hero/gear_flow_test.dart
+++ b/test/layers/domain/use-cases/hero/gear_flow_test.dart
@@ -43,7 +43,7 @@ void main() {
     final after = heroStatus();
     expect(ironSwordBefore, BuyGearResult.notNextTier);
     expect(result, BuyGearResult.ok);
-    expect((before.stats.attack, after.stats.attack), (4, 7));
+    expect((before.stats.attackMin, after.stats.attackMax), (3, 8));
     expect((before.power, after.power), (31, 40));
     expect(options().first, GearOptionEntityMock.equipped(GearId.shortSword));
     expect(options()[1].state, GearOptionState.unaffordable);
diff --git a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
index 95091f0..67e83e0 100644
--- a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
+++ b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
@@ -218,8 +218,8 @@ void main() {
       final fighters = bloc.state.data.fighters;
       expect(fighters[0].pose, FighterPose.attack);
       expect(fighters[0].swingProgress, closeTo(320 / 600, 1e-9));
-      expect(fighters[1], FighterRenderDataMock.rookieBanditHurt);
-      expect(effects, [ArenaEffectMock.banditHitForFour]);
+      expect(fighters[1], FighterRenderDataMock.rookieBanditAfterFirstBlow);
+      expect(effects, [ArenaEffectMock.banditHitForThree]);
     },
   );
 
diff --git a/test/layers/presentation/features/arena/models/arena_effect_test.dart b/test/layers/presentation/features/arena/models/arena_effect_test.dart
index f1c308c..4379dc2 100644
--- a/test/layers/presentation/features/arena/models/arena_effect_test.dart
+++ b/test/layers/presentation/features/arena/models/arena_effect_test.dart
@@ -13,7 +13,14 @@ void main() {
     final hits = effects.whereType<HitEffect>().toSet();
 
     // then
-    expect(hits, {ArenaEffectMock.banditHitForFour, ArenaEffectMock.heroHitForTwo});
+    expect(hits, {
+      ArenaEffectMock.banditHitForThree,
+      ArenaEffectMock.heroHitForOne,
+      ArenaEffectMock.banditHitForFive,
+      ArenaEffectMock.heroHitForThree,
+      ArenaEffectMock.banditHitForFour,
+      ArenaEffectMock.heroHitForTwo,
+    });
     expect(ArenaEffectMock.won, isNot(ArenaEffectMock.lost));
     expect(ArenaEffectMock.heroDodged.side, FightSide.hero);
     expect(ArenaEffectMock.heroHealedTwelve.hashCode, ArenaEffectMock.heroHealedTwelve.hashCode);
diff --git a/test/layers/presentation/features/arena/models/fight_replay_data_test.dart b/test/layers/presentation/features/arena/models/fight_replay_data_test.dart
index 5045b90..de56a87 100644
--- a/test/layers/presentation/features/arena/models/fight_replay_data_test.dart
+++ b/test/layers/presentation/features/arena/models/fight_replay_data_test.dart
@@ -28,7 +28,7 @@ void main() {
     expect((halfway.turnIndex, halfway.swingingTurn), (-1, 0));
     expect(halfway.healthOf(FightSide.enemy, 0), 20);
     expect((landed.turnIndex, landed.swingingTurn, landed.swingProgress), (0, 0, 0.5));
-    expect(landed.healthOf(FightSide.enemy, 0), 16);
+    expect(landed.healthOf(FightSide.enemy, 0), 17);
   });
 
   test('testWhenAdvancedPastTheEndThenStopsThereWithEveryTurnPlayed', () {
diff --git a/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart b/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
index 8d2e4ca..9551760 100644
--- a/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
+++ b/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
@@ -109,7 +109,7 @@ void main() {
         ForestBlocMock.shownMessages(navigationService),
         contains(Internationalize.forestMessageGearPurchased(name: Internationalize.forestGear(id: GearId.shortSword))),
       );
-      expect((hero.attack, hero.power), (7, 40));
+      expect((hero.attack, hero.power), (Internationalize.forestHeroAttackRange(min: 6, max: 8), 40));
       expect(hero.rows.first.equipped, GearItemDataMock.shortSwordEquipped);
     },
   );
@@ -140,7 +140,7 @@ void main() {
           Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.armory)),
         ),
       );
-      expect(bloc.state.data.hud!.hero.attack, 4);
+      expect(bloc.state.data.hud!.hero.attack, Internationalize.forestHeroAttackRange(min: 3, max: 5));
     },
   );
 
diff --git a/test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart b/test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart
index 8a08f29..56a2357 100644
--- a/test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart
+++ b/test/layers/presentation/features/forest/bloc/forest_bloc_skill_test.dart
@@ -91,7 +91,7 @@ void main() {
           Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: SkillId.doubleStrike)),
         ),
       );
-      expect((hero.attack, hero.power), (4, 34));
+      expect((hero.attack, hero.power), (Internationalize.forestHeroAttackRange(min: 3, max: 5), 34));
       expect(hero.skills, SkillItemDataMock.afterLearningDoubleStrike);
     },
   );
diff --git a/test/mocks/domain/entities/combat/fight_turn_entity_mock.dart b/test/mocks/domain/entities/combat/fight_turn_entity_mock.dart
index ded7520..0d48c8a 100644
--- a/test/mocks/domain/entities/combat/fight_turn_entity_mock.dart
+++ b/test/mocks/domain/entities/combat/fight_turn_entity_mock.dart
@@ -28,10 +28,10 @@ abstract final class FightTurnEntityMock {
       );
 
   static List<FightTurnEntity> victoryOverBandit() => [
-    heroHits(round: 1, damage: 4, enemyHealthAfter: 16),
-    enemyHits(round: 1, damage: 2, heroHealthAfter: 28),
-    heroHits(round: 2, damage: 4, enemyHealthAfter: 12),
-    enemyHits(round: 2, damage: 2, heroHealthAfter: 26),
+    heroHits(round: 1, damage: 3, enemyHealthAfter: 17),
+    enemyHits(round: 1, damage: 1, heroHealthAfter: 29),
+    heroHits(round: 2, damage: 5, enemyHealthAfter: 12),
+    enemyHits(round: 2, damage: 3, heroHealthAfter: 26),
     heroHits(round: 3, damage: 4, enemyHealthAfter: 8),
     enemyHits(round: 3, damage: 2, heroHealthAfter: 24),
     heroHits(round: 4, damage: 4, enemyHealthAfter: 4),
@@ -84,10 +84,10 @@ abstract final class FightTurnEntityMock {
   ];
 
   static List<FightTurnEntity> almostBeatDuelist() => [
-    heroHits(round: 1, damage: 4, enemyHealthAfter: 20),
-    enemyHits(round: 1, damage: 7, heroHealthAfter: 23),
-    heroHits(round: 2, damage: 4, enemyHealthAfter: 16),
-    enemyHits(round: 2, damage: 7, heroHealthAfter: 16),
+    heroHits(round: 1, damage: 3, enemyHealthAfter: 21),
+    enemyHits(round: 1, damage: 6, heroHealthAfter: 24),
+    heroHits(round: 2, damage: 5, enemyHealthAfter: 16),
+    enemyHits(round: 2, damage: 8, heroHealthAfter: 16),
     heroHits(round: 3, damage: 4, enemyHealthAfter: 12),
     enemyHits(round: 3, damage: 7, heroHealthAfter: 9),
     heroHits(round: 4, damage: 4, enemyHealthAfter: 8),
@@ -98,12 +98,12 @@ abstract final class FightTurnEntityMock {
 
   static List<FightTurnEntity> defeatByBruteFullyGeared() => [
     heroHits(round: 1, damage: 7, enemyHealthAfter: 48),
-    enemyHits(round: 1, damage: 21, heroHealthAfter: 54),
-    heroHits(round: 2, damage: 9, enemyHealthAfter: 39),
-    enemyHits(round: 2, damage: 24, heroHealthAfter: 30),
-    heroHits(round: 3, damage: 8, enemyHealthAfter: 31),
-    enemyHits(round: 3, damage: 24, heroHealthAfter: 6),
-    heroHits(round: 4, damage: 8, enemyHealthAfter: 23),
+    enemyHits(round: 1, damage: 22, heroHealthAfter: 53),
+    heroHits(round: 2, damage: 10, enemyHealthAfter: 38),
+    enemyHits(round: 2, damage: 24, heroHealthAfter: 29),
+    heroHits(round: 3, damage: 7, enemyHealthAfter: 31),
+    enemyHits(round: 3, damage: 23, heroHealthAfter: 6),
+    heroHits(round: 4, damage: 7, enemyHealthAfter: 24),
     enemyHits(round: 4, damage: 6, heroHealthAfter: 0),
   ];
 }
diff --git a/test/mocks/domain/entities/hero/combat_stats_entity_mock.dart b/test/mocks/domain/entities/hero/combat_stats_entity_mock.dart
index a34e006..3385f56 100644
--- a/test/mocks/domain/entities/hero/combat_stats_entity_mock.dart
+++ b/test/mocks/domain/entities/hero/combat_stats_entity_mock.dart
@@ -1,25 +1,45 @@
 import 'package:rpg/layers/domain/entities/hero/combat_stats_entity.dart';
 
 abstract final class CombatStatsEntityMock {
-  static const CombatStatsEntity heroBase = CombatStatsEntity(attack: 4, defense: 1, health: 30);
+  static const CombatStatsEntity heroBase = CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 30);
 
-  static const CombatStatsEntity heroWithShortSwordAndLeather = CombatStatsEntity(attack: 7, defense: 3, health: 40);
+  static const CombatStatsEntity heroWithShortSwordAndLeather = CombatStatsEntity(
+    attackMin: 6,
+    attackMax: 8,
+    defense: 3,
+    health: 40,
+  );
 
-  static const CombatStatsEntity heroFullyGeared = CombatStatsEntity(attack: 14, defense: 8, health: 75);
+  static const CombatStatsEntity heroFullyGeared = CombatStatsEntity(
+    attackMin: 12,
+    attackMax: 16,
+    defense: 8,
+    health: 75,
+  );
 
-  static const CombatStatsEntity bandit = CombatStatsEntity(attack: 3, defense: 0, health: 20);
+  static const CombatStatsEntity bandit = CombatStatsEntity(attackMin: 2, attackMax: 4, defense: 0, health: 20);
 
-  static const CombatStatsEntity brute = CombatStatsEntity(attack: 31, defense: 6, health: 55);
+  static const CombatStatsEntity brute = CombatStatsEntity(attackMin: 30, attackMax: 32, defense: 6, health: 55);
 
-  static const CombatStatsEntity veteranBandit = CombatStatsEntity(attack: 6, defense: 2, health: 30);
+  static const CombatStatsEntity veteranBandit = CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30);
 
-  static const CombatStatsEntity barbarianGuard = CombatStatsEntity(attack: 6, defense: 2, health: 30);
+  static const CombatStatsEntity barbarianGuard = CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30);
 
-  static const CombatStatsEntity barbarianChief = CombatStatsEntity(attack: 12, defense: 5, health: 70);
+  static const CombatStatsEntity barbarianChief = CombatStatsEntity(
+    attackMin: 10,
+    attackMax: 14,
+    defense: 5,
+    health: 70,
+  );
 
-  static const CombatStatsEntity duelist = CombatStatsEntity(attack: 8, defense: 0, health: 24);
+  static const CombatStatsEntity duelist = CombatStatsEntity(attackMin: 7, attackMax: 9, defense: 0, health: 24);
 
-  static const CombatStatsEntity wall = CombatStatsEntity(attack: 2, defense: 20, health: 100);
+  static const CombatStatsEntity wall = CombatStatsEntity(attackMin: 1, attackMax: 3, defense: 20, health: 100);
 
-  static const CombatStatsEntity heroWithShortSword = CombatStatsEntity(attack: 7, defense: 1, health: 30);
+  static const CombatStatsEntity heroWithShortSword = CombatStatsEntity(
+    attackMin: 6,
+    attackMax: 8,
+    defense: 1,
+    health: 30,
+  );
 }
diff --git a/test/mocks/presentation/features/arena/arena_effect_mock.dart b/test/mocks/presentation/features/arena/arena_effect_mock.dart
index b5a69c5..d3ec224 100644
--- a/test/mocks/presentation/features/arena/arena_effect_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_effect_mock.dart
@@ -7,6 +7,14 @@ abstract final class ArenaEffectMock {
 
   static const HitEffect heroHitForTwo = HitEffect(side: FightSide.hero, index: 0, damage: 2);
 
+  static const HitEffect banditHitForThree = HitEffect(side: FightSide.enemy, index: 0, damage: 3);
+
+  static const HitEffect banditHitForFive = HitEffect(side: FightSide.enemy, index: 0, damage: 5);
+
+  static const HitEffect heroHitForOne = HitEffect(side: FightSide.hero, index: 0, damage: 1);
+
+  static const HitEffect heroHitForThree = HitEffect(side: FightSide.hero, index: 0, damage: 3);
+
   static const DodgeEffect heroDodged = DodgeEffect(side: FightSide.hero, index: 0);
 
   static const HealEffect heroHealedTwelve = HealEffect(side: FightSide.hero, index: 0, amount: 12);
@@ -24,10 +32,10 @@ abstract final class ArenaEffectMock {
   static const FightEndedEffect lost = FightEndedEffect(isVictory: false);
 
   static const List<ArenaEffect> victoryOverBandit = [
-    banditHitForFour,
-    heroHitForTwo,
-    banditHitForFour,
-    heroHitForTwo,
+    banditHitForThree,
+    heroHitForOne,
+    banditHitForFive,
+    heroHitForThree,
     banditHitForFour,
     heroHitForTwo,
     banditHitForFour,
diff --git a/test/mocks/presentation/features/arena/fighter_render_data_mock.dart b/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
index 14e159f..447eeb4 100644
--- a/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
+++ b/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
@@ -53,6 +53,16 @@ abstract final class FighterRenderDataMock {
     isTargeted: true,
   );
 
+  static const FighterRenderData rookieBanditAfterFirstBlow = FighterRenderData(
+    side: FightSide.enemy,
+    index: 0,
+    enemyKind: EnemyKind.bandit,
+    health: 17,
+    maxHealth: 20,
+    pose: FighterPose.hurt,
+    isTargeted: true,
+  );
+
   static const FighterRenderData rookieBanditDown = FighterRenderData(
     side: FightSide.enemy,
     index: 0,
@@ -94,7 +104,7 @@ abstract final class FighterRenderDataMock {
     side: FightSide.enemy,
     index: 0,
     enemyKind: EnemyKind.wolf,
-    health: 19,
+    health: 20,
     maxHealth: 22,
     pose: FighterPose.attack,
     swingProgress: swingProgress,
diff --git a/test/mocks/presentation/features/forest/gear_item_data_mock.dart b/test/mocks/presentation/features/forest/gear_item_data_mock.dart
index 0c9589f..8cdb5b1 100644
--- a/test/mocks/presentation/features/forest/gear_item_data_mock.dart
+++ b/test/mocks/presentation/features/forest/gear_item_data_mock.dart
@@ -8,14 +8,14 @@ abstract final class GearItemDataMock {
   static GearItemData get woodcutterAxe => GearItemData(
     id: GearId.woodcutterAxe,
     name: Internationalize.forestGear(id: GearId.woodcutterAxe),
-    statsText: Internationalize.forestHeroWeaponStats(attack: 4),
+    statsText: Internationalize.forestHeroWeaponStats(min: 3, max: 5),
     canBuy: false,
   );
 
   static GearItemData get shortSwordEquipped => GearItemData(
     id: GearId.shortSword,
     name: Internationalize.forestGear(id: GearId.shortSword),
-    statsText: Internationalize.forestHeroWeaponStats(attack: 7),
+    statsText: Internationalize.forestHeroWeaponStats(min: 6, max: 8),
     canBuy: false,
   );
 
@@ -36,7 +36,7 @@ abstract final class GearItemDataMock {
   static GearItemData get steelSword => GearItemData(
     id: GearId.steelSword,
     name: Internationalize.forestGear(id: GearId.steelSword),
-    statsText: Internationalize.forestHeroWeaponStats(attack: 14),
+    statsText: Internationalize.forestHeroWeaponStats(min: 12, max: 16),
     canBuy: false,
   );
 
@@ -64,7 +64,7 @@ abstract final class GearItemDataMock {
   static GearItemData _shortSword({required String? reasonText, required bool canBuy}) => GearItemData(
     id: GearId.shortSword,
     name: Internationalize.forestGear(id: GearId.shortSword),
-    statsText: Internationalize.forestHeroWeaponStats(attack: 7),
+    statsText: Internationalize.forestHeroWeaponStats(min: 6, max: 8),
     costText: [
       Internationalize.forestAmount(resource: Resource.wood, amount: 20),
       Internationalize.forestAmount(resource: Resource.gold, amount: 10),
diff --git a/test/mocks/presentation/features/forest/hero_panel_data_mock.dart b/test/mocks/presentation/features/forest/hero_panel_data_mock.dart
index ba05338..8f52477 100644
--- a/test/mocks/presentation/features/forest/hero_panel_data_mock.dart
+++ b/test/mocks/presentation/features/forest/hero_panel_data_mock.dart
@@ -1,3 +1,4 @@
+import 'package:rpg/core/assets/i18n/internationalize.dart';
 import 'package:rpg/layers/presentation/features/forest/models/hero_panel_data.dart';
 
 import 'gear_row_data_mock.dart';
@@ -6,7 +7,7 @@ import 'skill_item_data_mock.dart';
 abstract final class HeroPanelDataMock {
   static HeroPanelData get newHero => HeroPanelData(
     power: 31,
-    attack: 4,
+    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
     defense: 1,
     health: 30,
     rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
@@ -15,7 +16,7 @@ abstract final class HeroPanelDataMock {
 
   static HeroPanelData get newHeroCopy => HeroPanelData(
     power: 31,
-    attack: 4,
+    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
     defense: 1,
     health: 30,
     rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
@@ -24,7 +25,7 @@ abstract final class HeroPanelDataMock {
 
   static HeroPanelData get newChampion => HeroPanelData(
     power: 31,
-    attack: 4,
+    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
     defense: 1,
     health: 30,
     rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
@@ -34,7 +35,7 @@ abstract final class HeroPanelDataMock {
 
   static HeroPanelData get readyToBuySword => HeroPanelData(
     power: 31,
-    attack: 4,
+    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
     defense: 1,
     health: 30,
     rows: [GearRowDataMock.weaponReadyToBuy, GearRowDataMock.armorNeedsArmory],
@@ -43,7 +44,7 @@ abstract final class HeroPanelDataMock {
 
   static HeroPanelData get readyToLearnDoubleStrike => HeroPanelData(
     power: 31,
-    attack: 4,
+    attack: Internationalize.forestHeroAttackRange(min: 3, max: 5),
     defense: 1,
     health: 30,
     rows: [GearRowDataMock.weaponNeedsForge, GearRowDataMock.armorNeedsArmory],
```

Run: `flutter test test/layers/domain/combat test/layers/domain/entities/hero`
Expected: no compila (`attackMin`, `forestHeroAttackRange`… no existen).

- [ ] **Step 3: Código (verde)**

Aplica este parche (sólo `lib/`):

```diff
diff --git a/lib/core/assets/i18n/internationalize.dart b/lib/core/assets/i18n/internationalize.dart
index a272b7a..dceb37e 100644
--- a/lib/core/assets/i18n/internationalize.dart
+++ b/lib/core/assets/i18n/internationalize.dart
@@ -92,8 +92,10 @@ class Internationalize {
   static String get forestHeroAttack => '$_forest.hero.attack'.tr();
   static String get forestHeroDefense => '$_forest.hero.defense'.tr();
   static String get forestHeroHealth => '$_forest.hero.health'.tr();
-  static String forestHeroWeaponStats({required int attack}) =>
-      '$_forest.hero.weaponStats'.tr(namedArgs: {'attack': '$attack'});
+  static String forestHeroAttackRange({required int min, required int max}) =>
+      '$_forest.hero.attackRange'.tr(namedArgs: {'min': '$min', 'max': '$max'});
+  static String forestHeroWeaponStats({required int min, required int max}) =>
+      '$_forest.hero.weaponStats'.tr(namedArgs: {'min': '$min', 'max': '$max'});
   static String forestHeroArmorStats({required int defense, required int health}) =>
       '$_forest.hero.armorStats'.tr(namedArgs: {'defense': '$defense', 'health': '$health'});
   static String forestHeroSlot({required GearSlot slot}) => switch (slot) {
diff --git a/lib/core/assets/i18n/translations/es.json b/lib/core/assets/i18n/translations/es.json
index 1f34e7e..404f922 100644
--- a/lib/core/assets/i18n/translations/es.json
+++ b/lib/core/assets/i18n/translations/es.json
@@ -75,7 +75,8 @@
       "defense": "Defensa",
       "health": "Vida",
       "champion": "Campeón de la arena",
-      "weaponStats": "Ataque {attack}",
+      "attackRange": "{min}–{max}",
+      "weaponStats": "Ataque {min}–{max}",
       "armorStats": "Defensa {defense} · Vida {health}",
       "slot": {
         "weapon": "Arma",
diff --git a/lib/layers/domain/combat/combat.dart b/lib/layers/domain/combat/combat.dart
index de9112f..c58da8b 100644
--- a/lib/layers/domain/combat/combat.dart
+++ b/lib/layers/domain/combat/combat.dart
@@ -91,7 +91,7 @@ final class _Fight {
     final target = enemyHealth.indexWhere((health) => health > 0);
     if (target < 0) return;
     final damage = _damage(
-      attack: heroStats.attack,
+      attacker: heroStats,
       defense: level.enemies[target].stats.defense,
       healthLeft: enemyHealth[target],
     );
@@ -123,7 +123,7 @@ final class _Fight {
     final dodged = skills.contains(SkillId.dodge) && random.next() < Rules.dodgeChance;
     final damage = dodged
         ? 0
-        : _damage(attack: level.enemies[index].stats.attack, defense: heroStats.defense, healthLeft: heroHealth);
+        : _damage(attacker: level.enemies[index].stats, defense: heroStats.defense, healthLeft: heroHealth);
     heroHealth -= damage;
     turns.add(
       FightTurnEntity(
@@ -158,8 +158,8 @@ final class _Fight {
     );
   }
 
-  int _damage({required int attack, required int defense, required int healthLeft}) {
-    final spread = 1 + (random.next() * 2 - 1) * Rules.damageSpread;
-    return math.min(healthLeft, math.max(1, ((attack - defense) * spread).round()));
+  int _damage({required CombatStatsEntity attacker, required int defense, required int healthLeft}) {
+    final attack = attacker.attackMin + (random.next() * (attacker.attackMax - attacker.attackMin + 1)).floor();
+    return math.min(healthLeft, math.max(1, attack - defense));
   }
 }
diff --git a/lib/layers/domain/entities/gear/gear_entity.dart b/lib/layers/domain/entities/gear/gear_entity.dart
index 57114c5..eedca90 100644
--- a/lib/layers/domain/entities/gear/gear_entity.dart
+++ b/lib/layers/domain/entities/gear/gear_entity.dart
@@ -9,7 +9,8 @@ class GearEntity {
   final GearSlot slot;
   final int tier;
   final Map<Resource, int> cost;
-  final int attack;
+  final int attackMin;
+  final int attackMax;
   final int defense;
   final int health;
 
@@ -18,11 +19,13 @@ class GearEntity {
     required this.slot,
     required this.tier,
     required this.cost,
-    this.attack = 0,
+    this.attackMin = 0,
+    this.attackMax = 0,
     this.defense = 0,
     this.health = 0,
   }) : assert(tier >= 0),
-       assert(attack >= 0),
+       assert(attackMin >= 0),
+       assert(attackMax >= attackMin),
        assert(defense >= 0),
        assert(health >= 0);
 
@@ -31,7 +34,8 @@ class GearEntity {
     GearSlot? slot,
     int? tier,
     Map<Resource, int>? cost,
-    int? attack,
+    int? attackMin,
+    int? attackMax,
     int? defense,
     int? health,
   }) {
@@ -40,7 +44,8 @@ class GearEntity {
       slot: slot ?? this.slot,
       tier: tier ?? this.tier,
       cost: cost ?? this.cost,
-      attack: attack ?? this.attack,
+      attackMin: attackMin ?? this.attackMin,
+      attackMax: attackMax ?? this.attackMax,
       defense: defense ?? this.defense,
       health: health ?? this.health,
     );
@@ -53,11 +58,12 @@ class GearEntity {
       other.slot == slot &&
       other.tier == tier &&
       const MapEquality<Resource, int>().equals(other.cost, cost) &&
-      other.attack == attack &&
+      other.attackMin == attackMin &&
+      other.attackMax == attackMax &&
       other.defense == defense &&
       other.health == health;
 
   @override
   int get hashCode =>
-      Object.hash(id, slot, tier, const MapEquality<Resource, int>().hash(cost), attack, defense, health);
+      Object.hash(id, slot, tier, const MapEquality<Resource, int>().hash(cost), attackMin, attackMax, defense, health);
 }
diff --git a/lib/layers/domain/entities/hero/combat_stats_entity.dart b/lib/layers/domain/entities/hero/combat_stats_entity.dart
index 34cf64a..688ef5d 100644
--- a/lib/layers/domain/entities/hero/combat_stats_entity.dart
+++ b/lib/layers/domain/entities/hero/combat_stats_entity.dart
@@ -1,18 +1,25 @@
 class CombatStatsEntity {
-  final int attack;
+  final int attackMin;
+  final int attackMax;
   final int defense;
   final int health;
 
-  const CombatStatsEntity({required this.attack, required this.defense, required this.health})
-    : assert(attack >= 0),
-      assert(defense >= 0),
-      assert(health > 0);
+  const CombatStatsEntity({
+    required this.attackMin,
+    required this.attackMax,
+    required this.defense,
+    required this.health,
+  }) : assert(attackMin >= 0),
+       assert(attackMax >= attackMin),
+       assert(defense >= 0),
+       assert(health > 0);
 
-  int get power => attack * 3 + defense * 4 + health ~/ 2;
+  int get power => (attackMin + attackMax) * 3 ~/ 2 + defense * 4 + health ~/ 2;
 
-  CombatStatsEntity copyWith({int? attack, int? defense, int? health}) {
+  CombatStatsEntity copyWith({int? attackMin, int? attackMax, int? defense, int? health}) {
     return CombatStatsEntity(
-      attack: attack ?? this.attack,
+      attackMin: attackMin ?? this.attackMin,
+      attackMax: attackMax ?? this.attackMax,
       defense: defense ?? this.defense,
       health: health ?? this.health,
     );
@@ -20,11 +27,16 @@ class CombatStatsEntity {
 
   @override
   bool operator ==(Object other) =>
-      other is CombatStatsEntity && other.attack == attack && other.defense == defense && other.health == health;
+      other is CombatStatsEntity &&
+      other.attackMin == attackMin &&
+      other.attackMax == attackMax &&
+      other.defense == defense &&
+      other.health == health;
 
   @override
-  int get hashCode => Object.hash(attack, defense, health);
+  int get hashCode => Object.hash(attackMin, attackMax, defense, health);
 
   @override
-  String toString() => 'CombatStatsEntity(attack: $attack, defense: $defense, health: $health)';
+  String toString() =>
+      'CombatStatsEntity(attackMin: $attackMin, attackMax: $attackMax, defense: $defense, health: $health)';
 }
diff --git a/lib/layers/domain/rules/arena_levels.dart b/lib/layers/domain/rules/arena_levels.dart
index 985dc6c..052ff11 100644
--- a/lib/layers/domain/rules/arena_levels.dart
+++ b/lib/layers/domain/rules/arena_levels.dart
@@ -12,78 +12,114 @@ abstract final class ArenaLevels {
     ArenaLevelEntity(
       id: ArenaLevelId.banditRookie,
       enemies: [
-        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 3, defense: 0, health: 20)),
+        EnemyEntity(
+          kind: EnemyKind.bandit,
+          stats: CombatStatsEntity(attackMin: 2, attackMax: 4, defense: 0, health: 20),
+        ),
       ],
       reward: {Resource.gold: 10},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.wolf,
       enemies: [
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 22)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 22)),
       ],
       reward: {Resource.gold: 15},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.banditVeteran,
       enemies: [
-        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
+        EnemyEntity(
+          kind: EnemyKind.bandit,
+          stats: CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30),
+        ),
       ],
       reward: {Resource.gold: 20},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.wolfPair,
       enemies: [
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 22)),
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 22)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 22)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 22)),
       ],
       reward: {Resource.gold: 25},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.bear,
       enemies: [
-        EnemyEntity(kind: EnemyKind.bear, stats: CombatStatsEntity(attack: 9, defense: 3, health: 40)),
+        EnemyEntity(
+          kind: EnemyKind.bear,
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 3, health: 40),
+        ),
       ],
       reward: {Resource.gold: 35},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.banditTrio,
       enemies: [
-        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
-        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
-        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
+        EnemyEntity(
+          kind: EnemyKind.bandit,
+          stats: CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 20),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.bandit,
+          stats: CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 20),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.bandit,
+          stats: CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 20),
+        ),
       ],
       reward: {Resource.gold: 40},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarian,
       enemies: [
-        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 12, defense: 4, health: 60)),
+        EnemyEntity(
+          kind: EnemyKind.barbarian,
+          stats: CombatStatsEntity(attackMin: 10, attackMax: 14, defense: 4, health: 60),
+        ),
       ],
       reward: {Resource.gold: 50},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.wolfPack,
       enemies: [
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 18)),
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 18)),
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attack: 5, defense: 1, health: 18)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 18)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 18)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 18)),
       ],
       reward: {Resource.gold: 55},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarianPair,
       enemies: [
-        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 9, defense: 4, health: 50)),
-        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 9, defense: 4, health: 50)),
+        EnemyEntity(
+          kind: EnemyKind.barbarian,
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 4, health: 50),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.barbarian,
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 4, health: 50),
+        ),
       ],
       reward: {Resource.gold: 65},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarianChief,
       enemies: [
-        EnemyEntity(kind: EnemyKind.barbarianChief, stats: CombatStatsEntity(attack: 12, defense: 5, health: 70)),
-        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
-        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
+        EnemyEntity(
+          kind: EnemyKind.barbarianChief,
+          stats: CombatStatsEntity(attackMin: 10, attackMax: 14, defense: 5, health: 70),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.barbarian,
+          stats: CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.barbarian,
+          stats: CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30),
+        ),
       ],
       reward: {Resource.gold: 100},
     ),
diff --git a/lib/layers/domain/rules/gear.dart b/lib/layers/domain/rules/gear.dart
index bfada8e..fb12335 100644
--- a/lib/layers/domain/rules/gear.dart
+++ b/lib/layers/domain/rules/gear.dart
@@ -6,27 +6,30 @@ import '../entities/gear/gear_entity.dart';
 
 abstract final class Gear {
   static const List<GearEntity> all = [
-    GearEntity(id: GearId.woodcutterAxe, slot: GearSlot.weapon, tier: 0, cost: {}, attack: 4),
+    GearEntity(id: GearId.woodcutterAxe, slot: GearSlot.weapon, tier: 0, cost: {}, attackMin: 3, attackMax: 5),
     GearEntity(
       id: GearId.shortSword,
       slot: GearSlot.weapon,
       tier: 1,
       cost: {Resource.wood: 20, Resource.gold: 10},
-      attack: 7,
+      attackMin: 6,
+      attackMax: 8,
     ),
     GearEntity(
       id: GearId.ironSword,
       slot: GearSlot.weapon,
       tier: 2,
       cost: {Resource.wood: 30, Resource.gold: 40},
-      attack: 10,
+      attackMin: 9,
+      attackMax: 11,
     ),
     GearEntity(
       id: GearId.steelSword,
       slot: GearSlot.weapon,
       tier: 3,
       cost: {Resource.wood: 40, Resource.gold: 120},
-      attack: 14,
+      attackMin: 12,
+      attackMax: 16,
     ),
     GearEntity(id: GearId.workClothes, slot: GearSlot.armor, tier: 0, cost: {}, defense: 1, health: 30),
     GearEntity(
diff --git a/lib/layers/domain/rules/rules.dart b/lib/layers/domain/rules/rules.dart
index 7f61309..a97a6ae 100644
--- a/lib/layers/domain/rules/rules.dart
+++ b/lib/layers/domain/rules/rules.dart
@@ -9,7 +9,6 @@ abstract final class Rules {
   static const double playerRadius = 8;
   static const double treeTrunkRadius = 12;
   static const double powerPerSkill = 0.1;
-  static const double damageSpread = 0.15;
   static const int maxFightRounds = 30;
   static const double dodgeChance = 0.2;
   static const double secondWindThreshold = 0.3;
diff --git a/lib/layers/domain/world/extensions/hero_rules.dart b/lib/layers/domain/world/extensions/hero_rules.dart
index ef79b45..89c5dc5 100644
--- a/lib/layers/domain/world/extensions/hero_rules.dart
+++ b/lib/layers/domain/world/extensions/hero_rules.dart
@@ -19,7 +19,8 @@ extension HeroRules on HeroEntity {
     final weapon = equipped(GearSlot.weapon);
     final armor = equipped(GearSlot.armor);
     return CombatStatsEntity(
-      attack: weapon.attack + armor.attack,
+      attackMin: weapon.attackMin + armor.attackMin,
+      attackMax: weapon.attackMax + armor.attackMax,
       defense: weapon.defense + armor.defense,
       health: weapon.health + armor.health,
     );
diff --git a/lib/layers/presentation/features/forest/bloc/forest_bloc.dart b/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
index 50bd6b9..eea6001 100644
--- a/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
+++ b/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
@@ -400,7 +400,7 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     final options = _getGearOptionsUseCase();
     return HeroPanelData(
       power: status.power,
-      attack: status.stats.attack,
+      attack: Internationalize.forestHeroAttackRange(min: status.stats.attackMin, max: status.stats.attackMax),
       defense: status.stats.defense,
       health: status.stats.health,
       rows: [
@@ -430,7 +430,7 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
       id: gear.id,
       name: Internationalize.forestGear(id: gear.id),
       statsText: switch (gear.slot) {
-        GearSlot.weapon => Internationalize.forestHeroWeaponStats(attack: gear.attack),
+        GearSlot.weapon => Internationalize.forestHeroWeaponStats(min: gear.attackMin, max: gear.attackMax),
         GearSlot.armor => Internationalize.forestHeroArmorStats(defense: gear.defense, health: gear.health),
       },
       costText: option.state == GearOptionState.equipped ? null : _amounts(gear.cost),
diff --git a/lib/layers/presentation/features/forest/models/hero_panel_data.dart b/lib/layers/presentation/features/forest/models/hero_panel_data.dart
index 09cbe5e..1b330da 100644
--- a/lib/layers/presentation/features/forest/models/hero_panel_data.dart
+++ b/lib/layers/presentation/features/forest/models/hero_panel_data.dart
@@ -5,7 +5,7 @@ import 'skill_item_data.dart';
 
 class HeroPanelData {
   final int power;
-  final int attack;
+  final String attack;
   final int defense;
   final int health;
   final List<GearRowData> rows;
diff --git a/lib/layers/presentation/features/forest/widgets/hero_panel.dart b/lib/layers/presentation/features/forest/widgets/hero_panel.dart
index 399d9c2..154a2be 100644
--- a/lib/layers/presentation/features/forest/widgets/hero_panel.dart
+++ b/lib/layers/presentation/features/forest/widgets/hero_panel.dart
@@ -103,18 +103,22 @@ class _HeroPanelState extends State<HeroPanel> {
       runSpacing: 4,
       crossAxisAlignment: WrapCrossAlignment.center,
       children: [
-        _stat(label: Internationalize.forestHeroPower, value: hero.power, style: CustomTextStyles.system18w600),
+        _stat(label: Internationalize.forestHeroPower, value: '${hero.power}', style: CustomTextStyles.system18w600),
         _stat(label: Internationalize.forestHeroAttack, value: hero.attack, style: CustomTextStyles.system15w600),
-        _stat(label: Internationalize.forestHeroDefense, value: hero.defense, style: CustomTextStyles.system15w600),
-        _stat(label: Internationalize.forestHeroHealth, value: hero.health, style: CustomTextStyles.system15w600),
+        _stat(
+          label: Internationalize.forestHeroDefense,
+          value: '${hero.defense}',
+          style: CustomTextStyles.system15w600,
+        ),
+        _stat(label: Internationalize.forestHeroHealth, value: '${hero.health}', style: CustomTextStyles.system15w600),
       ],
     );
   }
 
-  Widget _stat({required String label, required int value, required TextStyle style}) {
+  Widget _stat({required String label, required String value, required TextStyle style}) {
     return Semantics(
       label: label,
-      value: '$value',
+      value: value,
       excludeSemantics: true,
       child: Row(
         mainAxisSize: MainAxisSize.min,
@@ -122,7 +126,7 @@ class _HeroPanelState extends State<HeroPanel> {
         children: [
           Text(label, style: CustomTextStyles.system13w500.copyWith(color: CustomColors.hudMuted)),
           Text(
-            '$value',
+            value,
             style: style.copyWith(color: CustomColors.hudAccent, fontFeatures: const [FontFeature.tabularFigures()]),
           ),
         ],
```

Run: `flutter test`
Expected: **631 tests** en verde.

- [ ] **Step 4: Guía**

En `CLAUDE.md`:
- `entities/<feature>/`: `hero (`CombatStatsEntity`` pasa a `hero (`CombatStatsEntity` with an attack range, `attackMin`–`attackMax``.
- `combat/`: tras `one per hit, plus one per enemy attack when the hero can dodge)` añade `; each blow picks a value in the attacker's `attackMin`–`attackMax` with its `next()` and deals `max(1, value − defense)`, capped at the health left`.

- [ ] **Step 5: Verificación completa**

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart '*.mocks.dart'
flutter analyze
flutter test
```

Expected: sin cambios en generados, `No issues found!`, 631 en verde.

- [ ] **Step 6: Commit**

```bash
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-C7]: Roll each blow from the attacker's attack range"
```

---

### Task TC7.2: Líneas de misiones

**Files:**
  - Modify: `lib/core/assets/i18n/internationalize.dart`
  - Modify: `lib/core/assets/i18n/translations/es.json`
  - Modify: `lib/core/config/constants/enum/quest_id.dart`
  - Create: `lib/core/config/constants/enum/quest_line.dart`
  - Modify: `lib/layers/domain/entities/game/quest_progress_entity.dart`
  - Modify: `lib/layers/domain/quests/quest.dart`
  - Modify: `lib/layers/domain/quests/quest_log.dart`
  - Modify: `lib/layers/domain/quests/quests.dart`
  - Modify: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - Modify: `lib/layers/presentation/features/forest/models/quest_item_data.dart`
  - Modify: `lib/layers/presentation/features/forest/widgets/quest_panel.dart`
  - Modify: `test/core/assets/i18n/internationalize_test.dart`
  - Modify: `test/layers/domain/quests/quest_log_test.dart`
  - Modify: `test/layers/domain/use-cases/game/game_flow_test.dart`
  - Modify: `test/layers/domain/use-cases/game/get_quests_use_case_test.dart`
  - Modify: `test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart`
  - Modify: `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`
  - Modify: `test/layers/presentation/features/forest/widgets/quest_panel_test.dart`
  - Modify: `test/mocks/domain/entities/game/quest_progress_entity_mock.dart`
  - Modify: `test/mocks/presentation/features/forest/quest_item_data_mock.dart`
  - Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `World.hero` / `buildings`, `BuildingListRules.hasComplete` (C3), `ArenaRules.isChampion` (C6), `ArenaLevels.all`.
- Produces:
  ```dart
  enum QuestLine { village, hero }                     // lib/core/config/constants/enum/quest_line.dart
  enum QuestId { …, buildForge, winFirstFight, buyFirstWeapon, buildArmory, buildMageTower, learnASkill, clearHalfArena, becomeChampion }
  QuestLine get line;                                    // Quest
  const QuestProgressEntity({required id, required line, required progress, required target, required isCompleted, required isCurrent});
  const QuestItemData({required line, required title, required progressText, required status});
  static String forestQuestLine({required QuestLine line});
  static String forestMessageQuestLineCompleted({required QuestLine line});
  ```
  - mocks nuevos: `QuestProgressEntityMock.buildForgeCurrent`, `QuestItemDataMock.buildForgeCurrent` / `withBothLines`.

- [ ] **Step 1: Rama**

Sigue en `feature/PROJECT-C7-hero-quests-balance` (con TC7.1 hecha, como en el ensayo).

- [ ] **Step 2: Tests y mocks (rojo)**

```diff
diff --git a/test/core/assets/i18n/internationalize_test.dart b/test/core/assets/i18n/internationalize_test.dart
index 9776a5a..75a4810 100644
--- a/test/core/assets/i18n/internationalize_test.dart
+++ b/test/core/assets/i18n/internationalize_test.dart
@@ -8,6 +8,7 @@ import 'package:rpg/core/config/constants/enum/forest/hero_panel_section.dart';
 import 'package:rpg/core/config/constants/enum/gear_id.dart';
 import 'package:rpg/core/config/constants/enum/gear_slot.dart';
 import 'package:rpg/core/config/constants/enum/quest_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/core/config/constants/enum/resource.dart';
 import 'package:rpg/core/config/constants/enum/skill_id.dart';
 import 'package:rpg/core/config/constants/enum/tool_kind.dart';
@@ -44,7 +45,20 @@ void main() {
 
     // then
     expect(name, 'Casa');
-    expect(quests, ['Recoge el hacha', 'Consigue al menos 15 de madera', 'Construye una casa']);
+    expect(quests, [
+      'Recoge el hacha',
+      'Consigue al menos 15 de madera',
+      'Construye una casa',
+      'Construye la Herrería',
+      'Gana un nivel de la arena',
+      'Compra la Espada corta',
+      'Construye la Armería',
+      'Construye la Torre de magia',
+      'Aprende una habilidad',
+      'Gana la mitad de los niveles de la arena',
+      'Gana al Jefe bárbaro',
+    ]);
+    expect(QuestLine.values.map((line) => Internationalize.forestQuestLine(line: line)), ['Aldea', 'Héroe']);
   });
 
   test('testWhenFormattingMessagesWithNamesThenInsertsThem', () {
@@ -93,7 +107,7 @@ void main() {
       Internationalize.forestMessageBlockedSite,
       Internationalize.forestMessageNotEnoughResources,
       Internationalize.forestMessageBuildingStarted,
-      Internationalize.forestMessageAllQuestsCompleted,
+      Internationalize.forestMessageQuestLineCompleted(line: QuestLine.village),
       Internationalize.forestPlacementConfirm,
       Internationalize.forestPlacementCancel,
       Internationalize.forestAccessibilityGameWorld,
@@ -118,7 +132,7 @@ void main() {
       'Ahí no cabe. Busca un sitio despejado.',
       'No tienes recursos suficientes.',
       'Manos a la obra…',
-      '¡Has completado todas las misiones!',
+      '¡Has completado las misiones de Aldea!',
       'Construir aquí',
       'Cancelar',
       'Mundo de juego: bosque con árboles, el personaje y los edificios',
diff --git a/test/layers/domain/quests/quest_log_test.dart b/test/layers/domain/quests/quest_log_test.dart
index cb60aec..0ca486d 100644
--- a/test/layers/domain/quests/quest_log_test.dart
+++ b/test/layers/domain/quests/quest_log_test.dart
@@ -1,5 +1,6 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:rpg/core/config/constants/enum/quest_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/core/config/constants/enum/resource.dart';
 import 'package:rpg/core/config/constants/enum/tool_kind.dart';
 import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
@@ -10,11 +11,12 @@ import 'package:rpg/layers/domain/world/extensions/player_rules.dart';
 
 import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
 import '../../../mocks/domain/entities/game/quest_progress_entity_mock.dart';
+import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
 import '../../../mocks/domain/entities/player/inventory_entity_mock.dart';
 import '../../../mocks/domain/world/world_mock.dart';
 
 void main() {
-  test('testWhenGameStartsThenEveryQuestIsPendingAndTheFirstIsCurrent', () {
+  test('testWhenGameStartsThenEveryQuestIsPendingAndEachLineHasItsFirstQuestCurrent', () {
     // given
     final world = WorldMock.make();
 
@@ -22,11 +24,27 @@ void main() {
     final status = QuestLog().status(world);
 
     // then
-    expect(status, const [
+    expect(status.where((quest) => quest.line == QuestLine.village), const [
       QuestProgressEntityMock.pickUpAxePending,
       QuestProgressEntityMock.gatherWoodPending,
       QuestProgressEntityMock.buildHousePending,
     ]);
+    expect(status.where((quest) => quest.line == QuestLine.hero).first, QuestProgressEntityMock.buildForgeCurrent);
+    expect(status.where((quest) => quest.isCurrent), hasLength(2));
+  });
+
+  test('testWhenTheHeroHasBecomeChampionThenItsQuestsAreFulfilledAndTheArenaOneCountsLevels', () {
+    // given
+    final world = WorldMock.withHero(HeroEntityMock.champion);
+    final questLog = QuestLog();
+
+    // when
+    final completed = questLog.update(world).map((event) => event.questId);
+    final halfArena = questLog.status(world).firstWhere((quest) => quest.id == QuestId.clearHalfArena);
+
+    // then
+    expect(completed, [QuestId.winFirstFight, QuestId.buyFirstWeapon, QuestId.learnASkill, QuestId.becomeChampion]);
+    expect((halfArena.progress, halfArena.target, halfArena.isCurrent), (2, 5, false));
   });
 
   test('testWhenQuestIsFulfilledThenItIsReportedOnlyOnce', () {
diff --git a/test/layers/domain/use-cases/game/game_flow_test.dart b/test/layers/domain/use-cases/game/game_flow_test.dart
index 33d55dc..3ec44d1 100644
--- a/test/layers/domain/use-cases/game/game_flow_test.dart
+++ b/test/layers/domain/use-cases/game/game_flow_test.dart
@@ -1,6 +1,7 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:mockito/mockito.dart';
 import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/core/config/constants/enum/chop_result.dart';
 import 'package:rpg/core/config/constants/enum/resource.dart';
 import 'package:rpg/layers/domain/entities/game/construction_result_entity.dart';
@@ -76,6 +77,6 @@ void main() {
     expect(events, contains(GameEventEntityMock.buildingCompleted));
     expect(events, contains(GameEventEntityMock.buildHouseCompleted));
     expect(getPlayerStatus().inventory.amount(Resource.wood), 3);
-    expect(getQuests().every((quest) => quest.isCompleted), isTrue);
+    expect(getQuests().where((quest) => quest.line == QuestLine.village).every((quest) => quest.isCompleted), isTrue);
   });
 }
diff --git a/test/layers/domain/use-cases/game/get_quests_use_case_test.dart b/test/layers/domain/use-cases/game/get_quests_use_case_test.dart
index b2c9a1d..597a2dd 100644
--- a/test/layers/domain/use-cases/game/get_quests_use_case_test.dart
+++ b/test/layers/domain/use-cases/game/get_quests_use_case_test.dart
@@ -24,8 +24,8 @@ void main() {
     final quests = sut();
 
     // then
-    expect(quests.map((quest) => quest.id), [QuestId.pickUpAxe, QuestId.gatherWood, QuestId.buildHouse]);
+    expect(quests.map((quest) => quest.id), QuestId.values);
     expect(quests.any((quest) => quest.isCompleted), isFalse);
-    expect(quests.first.isCurrent, isTrue);
+    expect(quests.where((quest) => quest.isCurrent).map((quest) => quest.id), [QuestId.pickUpAxe, QuestId.buildForge]);
   });
 }
diff --git a/test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart b/test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart
index a29d54c..5ccb611 100644
--- a/test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart
+++ b/test/layers/presentation/features/forest/bloc/forest_bloc_start_test.dart
@@ -40,7 +40,7 @@ void main() {
       expect(data.player!.position, ForestScenarioMock.playerStart);
       expect(data.player!.facing, Facing.down);
       expect(data.player!.pose, PlayerPoseMock.idleWithoutAxe);
-      expect(data.hud!.questBadge, '0/3');
+      expect(data.hud!.questBadge, '0/11');
       expect(data.placement, isNull);
       expect(data.effects, isEmpty);
     },
diff --git a/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart b/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
index 07f7384..56fb6a4 100644
--- a/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
+++ b/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
@@ -3,6 +3,7 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:mockito/mockito.dart';
 import 'package:rpg/core/assets/i18n/internationalize.dart';
 import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/core/config/constants/enum/forest/facing.dart';
 import 'package:rpg/core/config/constants/enum/forest/work_tool.dart';
 import 'package:rpg/layers/domain/rules/rules.dart';
@@ -53,9 +54,10 @@ void main() {
       // then
       final hud = bloc.state.data.hud!;
       expect(ForestBlocMock.shownMessages(navigationService), contains(Internationalize.forestMessageWelcome));
-      expect(hud.questBadge, '0/3');
+      expect(hud.questBadge, '0/11');
       expect(hud.quests[0], QuestItemDataMock.pickUpAxeCurrent);
       expect(hud.quests[1], QuestItemDataMock.gatherWoodPending);
+      expect(hud.quests[3], QuestItemDataMock.buildForgeCurrent);
     },
   );
 
@@ -314,10 +316,13 @@ void main() {
       wait: Duration.zero,
       verify: (bloc) {
         // then
-        expect(badgeBefore, '2/3');
+        expect(badgeBefore, '2/11');
         expect(effects, contains(ForestEffectMock.buildingCompleted));
-        expect(bloc.state.data.hud!.questBadge, '3/3');
-        expect(ForestBlocMock.shownMessages(navigationService).last, Internationalize.forestMessageAllQuestsCompleted);
+        expect(bloc.state.data.hud!.questBadge, '3/11');
+        expect(
+          ForestBlocMock.shownMessages(navigationService).last,
+          Internationalize.forestMessageQuestLineCompleted(line: QuestLine.village),
+        );
       },
     );
   });
diff --git a/test/layers/presentation/features/forest/widgets/quest_panel_test.dart b/test/layers/presentation/features/forest/widgets/quest_panel_test.dart
index 55e1622..4dbacf4 100644
--- a/test/layers/presentation/features/forest/widgets/quest_panel_test.dart
+++ b/test/layers/presentation/features/forest/widgets/quest_panel_test.dart
@@ -1,6 +1,8 @@
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:rpg/core/assets/i18n/internationalize.dart';
+import 'package:rpg/core/config/constants/enum/quest_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/layers/presentation/features/forest/widgets/quest_panel.dart';
 import 'package:rpg/layers/presentation/features/forest/widgets/quest_row.dart';
 
@@ -22,4 +24,21 @@ void main() {
     expect(find.text(Internationalize.forestQuests.toUpperCase()), findsOneWidget);
     expect(find.byType(QuestRow), findsNWidgets(3));
   });
+
+  testWidgets('testWhenBothLinesHaveQuestsThenEachIsListedUnderItsOwnHeading', (tester) async {
+    // given
+    final panel = QuestPanel(quests: QuestItemDataMock.withBothLines);
+
+    // when
+    await tester.pumpHud(Center(child: panel));
+
+    // then
+    expect(find.text(Internationalize.forestQuestLine(line: QuestLine.village)), findsOneWidget);
+    expect(find.text(Internationalize.forestQuestLine(line: QuestLine.hero)), findsOneWidget);
+    expect(find.byType(QuestRow), findsNWidgets(4));
+    expect(
+      tester.getTopLeft(find.text(Internationalize.forestQuestLine(line: QuestLine.hero))).dy,
+      greaterThan(tester.getTopLeft(find.text(Internationalize.forestQuestTitle(id: QuestId.buildHouse))).dy),
+    );
+  });
 }
diff --git a/test/mocks/domain/entities/game/quest_progress_entity_mock.dart b/test/mocks/domain/entities/game/quest_progress_entity_mock.dart
index b064f0e..08070c4 100644
--- a/test/mocks/domain/entities/game/quest_progress_entity_mock.dart
+++ b/test/mocks/domain/entities/game/quest_progress_entity_mock.dart
@@ -1,8 +1,10 @@
 import 'package:rpg/core/config/constants/enum/quest_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';
 
 abstract final class QuestProgressEntityMock {
   static const QuestProgressEntity mock = QuestProgressEntity(
+    line: QuestLine.village,
     id: QuestId.gatherWood,
     progress: 3,
     target: 15,
@@ -11,6 +13,7 @@ abstract final class QuestProgressEntityMock {
   );
 
   static const QuestProgressEntity pickUpAxePending = QuestProgressEntity(
+    line: QuestLine.village,
     id: QuestId.pickUpAxe,
     progress: 0,
     target: 1,
@@ -19,6 +22,7 @@ abstract final class QuestProgressEntityMock {
   );
 
   static const QuestProgressEntity gatherWoodPending = QuestProgressEntity(
+    line: QuestLine.village,
     id: QuestId.gatherWood,
     progress: 0,
     target: 15,
@@ -27,6 +31,7 @@ abstract final class QuestProgressEntityMock {
   );
 
   static const QuestProgressEntity gatherWoodCurrent = QuestProgressEntity(
+    line: QuestLine.village,
     id: QuestId.gatherWood,
     progress: 0,
     target: 15,
@@ -35,6 +40,7 @@ abstract final class QuestProgressEntityMock {
   );
 
   static const QuestProgressEntity buildHousePending = QuestProgressEntity(
+    line: QuestLine.village,
     id: QuestId.buildHouse,
     progress: 0,
     target: 1,
@@ -43,6 +49,7 @@ abstract final class QuestProgressEntityMock {
   );
 
   static const QuestProgressEntity gatherWoodCompleted = QuestProgressEntity(
+    line: QuestLine.village,
     id: QuestId.gatherWood,
     progress: 15,
     target: 15,
@@ -50,8 +57,18 @@ abstract final class QuestProgressEntityMock {
     isCurrent: false,
   );
 
+  static const QuestProgressEntity buildForgeCurrent = QuestProgressEntity(
+    id: QuestId.buildForge,
+    line: QuestLine.hero,
+    progress: 0,
+    target: 1,
+    isCompleted: false,
+    isCurrent: true,
+  );
+
   static QuestProgressEntity make({bool isCurrent = true}) {
     return QuestProgressEntity(
+      line: QuestLine.village,
       id: QuestId.gatherWood,
       progress: 3,
       target: 15,
diff --git a/test/mocks/presentation/features/forest/quest_item_data_mock.dart b/test/mocks/presentation/features/forest/quest_item_data_mock.dart
index a2b98e0..ead361e 100644
--- a/test/mocks/presentation/features/forest/quest_item_data_mock.dart
+++ b/test/mocks/presentation/features/forest/quest_item_data_mock.dart
@@ -1,38 +1,53 @@
 import 'package:rpg/core/assets/i18n/internationalize.dart';
 import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
 import 'package:rpg/core/config/constants/enum/quest_id.dart';
+import 'package:rpg/core/config/constants/enum/quest_line.dart';
 import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';
 
 abstract final class QuestItemDataMock {
   static QuestItemData get done => QuestItemData(
+    line: QuestLine.village,
     title: Internationalize.forestQuestTitle(id: QuestId.pickUpAxe),
     progressText: Internationalize.forestQuestDone,
     status: QuestItemStatus.done,
   );
 
   static QuestItemData get current => QuestItemData(
+    line: QuestLine.village,
     title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
     progressText: '6/15',
     status: QuestItemStatus.current,
   );
 
   static QuestItemData get pending => QuestItemData(
+    line: QuestLine.village,
     title: Internationalize.forestQuestTitle(id: QuestId.buildHouse),
     progressText: '',
     status: QuestItemStatus.pending,
   );
 
   static QuestItemData get pickUpAxeCurrent => QuestItemData(
+    line: QuestLine.village,
     title: Internationalize.forestQuestTitle(id: QuestId.pickUpAxe),
     progressText: '',
     status: QuestItemStatus.current,
   );
 
   static QuestItemData get gatherWoodPending => QuestItemData(
+    line: QuestLine.village,
     title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
     progressText: '0/15',
     status: QuestItemStatus.pending,
   );
 
+  static QuestItemData get buildForgeCurrent => QuestItemData(
+    line: QuestLine.hero,
+    title: Internationalize.forestQuestTitle(id: QuestId.buildForge),
+    progressText: '',
+    status: QuestItemStatus.current,
+  );
+
+  static List<QuestItemData> get withBothLines => [done, current, pending, buildForgeCurrent];
+
   static List<QuestItemData> get all => [done, current, pending];
 }
```

Run: `flutter test test/layers/domain/quests`
Expected: no compila (`QuestLine`, `line` no existen).

- [ ] **Step 3: Código (verde)**

```diff
diff --git a/lib/core/assets/i18n/internationalize.dart b/lib/core/assets/i18n/internationalize.dart
index dceb37e..e2c6ded 100644
--- a/lib/core/assets/i18n/internationalize.dart
+++ b/lib/core/assets/i18n/internationalize.dart
@@ -8,6 +8,7 @@ import '../../config/constants/enum/forest/hero_panel_section.dart';
 import '../../config/constants/enum/gear_id.dart';
 import '../../config/constants/enum/gear_slot.dart';
 import '../../config/constants/enum/quest_id.dart';
+import '../../config/constants/enum/quest_line.dart';
 import '../../config/constants/enum/resource.dart';
 import '../../config/constants/enum/skill_id.dart';
 import '../../config/constants/enum/tool_kind.dart';
@@ -65,6 +66,18 @@ class Internationalize {
     QuestId.pickUpAxe => '$_forest.quest.pickUpAxe'.tr(),
     QuestId.gatherWood => '$_forest.quest.gatherWood'.tr(),
     QuestId.buildHouse => '$_forest.quest.buildHouse'.tr(),
+    QuestId.buildForge => '$_forest.quest.buildForge'.tr(),
+    QuestId.winFirstFight => '$_forest.quest.winFirstFight'.tr(),
+    QuestId.buyFirstWeapon => '$_forest.quest.buyFirstWeapon'.tr(),
+    QuestId.buildArmory => '$_forest.quest.buildArmory'.tr(),
+    QuestId.buildMageTower => '$_forest.quest.buildMageTower'.tr(),
+    QuestId.learnASkill => '$_forest.quest.learnASkill'.tr(),
+    QuestId.clearHalfArena => '$_forest.quest.clearHalfArena'.tr(),
+    QuestId.becomeChampion => '$_forest.quest.becomeChampion'.tr(),
+  };
+  static String forestQuestLine({required QuestLine line}) => switch (line) {
+    QuestLine.village => '$_forest.questLine.village'.tr(),
+    QuestLine.hero => '$_forest.questLine.hero'.tr(),
   };
   static String get forestMessageWelcome => '$_forest.message.welcome'.tr();
   static String get forestMessageNeedAxe => '$_forest.message.needAxe'.tr();
@@ -73,7 +86,8 @@ class Internationalize {
   static String get forestMessageBlockedSite => '$_forest.message.blockedSite'.tr();
   static String get forestMessageNotEnoughResources => '$_forest.message.notEnoughResources'.tr();
   static String get forestMessageBuildingStarted => '$_forest.message.buildingStarted'.tr();
-  static String get forestMessageAllQuestsCompleted => '$_forest.message.allQuestsCompleted'.tr();
+  static String forestMessageQuestLineCompleted({required QuestLine line}) =>
+      '$_forest.message.questLineCompleted'.tr(namedArgs: {'line': forestQuestLine(line: line)});
   static String forestMessageWoodGained({required int wood}) =>
       '$_forest.message.woodGained'.tr(namedArgs: {'wood': '$wood'});
   static String forestMessagePlacing({required String name}) =>
diff --git a/lib/core/assets/i18n/translations/es.json b/lib/core/assets/i18n/translations/es.json
index 404f922..0d02925 100644
--- a/lib/core/assets/i18n/translations/es.json
+++ b/lib/core/assets/i18n/translations/es.json
@@ -48,7 +48,19 @@
     "quest": {
       "pickUpAxe": "Recoge el hacha",
       "gatherWood": "Consigue al menos 15 de madera",
-      "buildHouse": "Construye una casa"
+      "buildHouse": "Construye una casa",
+      "buildForge": "Construye la Herrería",
+      "winFirstFight": "Gana un nivel de la arena",
+      "buyFirstWeapon": "Compra la Espada corta",
+      "buildArmory": "Construye la Armería",
+      "buildMageTower": "Construye la Torre de magia",
+      "learnASkill": "Aprende una habilidad",
+      "clearHalfArena": "Gana la mitad de los niveles de la arena",
+      "becomeChampion": "Gana al Jefe bárbaro"
+    },
+    "questLine": {
+      "village": "Aldea",
+      "hero": "Héroe"
     },
     "message": {
       "welcome": "Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.",
@@ -58,7 +70,7 @@
       "blockedSite": "Ahí no cabe. Busca un sitio despejado.",
       "notEnoughResources": "No tienes recursos suficientes.",
       "buildingStarted": "Manos a la obra…",
-      "allQuestsCompleted": "¡Has completado todas las misiones!",
+      "questLineCompleted": "¡Has completado las misiones de {line}!",
       "woodGained": "+{wood} de madera",
       "placing": "Elige dónde construir: {name}. Clic derecho o Esc para cancelar.",
       "buildingCompleted": "Construcción terminada: {name}",
diff --git a/lib/core/config/constants/enum/quest_id.dart b/lib/core/config/constants/enum/quest_id.dart
index 3149baf..d533eb0 100644
--- a/lib/core/config/constants/enum/quest_id.dart
+++ b/lib/core/config/constants/enum/quest_id.dart
@@ -1 +1,13 @@
-enum QuestId { pickUpAxe, gatherWood, buildHouse }
+enum QuestId {
+  pickUpAxe,
+  gatherWood,
+  buildHouse,
+  buildForge,
+  winFirstFight,
+  buyFirstWeapon,
+  buildArmory,
+  buildMageTower,
+  learnASkill,
+  clearHalfArena,
+  becomeChampion,
+}
diff --git a/lib/core/config/constants/enum/quest_line.dart b/lib/core/config/constants/enum/quest_line.dart
new file mode 100644
index 0000000..3a535e2
--- /dev/null
+++ b/lib/core/config/constants/enum/quest_line.dart
@@ -0,0 +1 @@
+enum QuestLine { village, hero }
diff --git a/lib/layers/domain/entities/game/quest_progress_entity.dart b/lib/layers/domain/entities/game/quest_progress_entity.dart
index 4fe986f..6c08c0f 100644
--- a/lib/layers/domain/entities/game/quest_progress_entity.dart
+++ b/lib/layers/domain/entities/game/quest_progress_entity.dart
@@ -1,7 +1,9 @@
 import '../../../../core/config/constants/enum/quest_id.dart';
+import '../../../../core/config/constants/enum/quest_line.dart';
 
 class QuestProgressEntity {
   final QuestId id;
+  final QuestLine line;
   final int progress;
   final int target;
   final bool isCompleted;
@@ -9,6 +11,7 @@ class QuestProgressEntity {
 
   const QuestProgressEntity({
     required this.id,
+    required this.line,
     required this.progress,
     required this.target,
     required this.isCompleted,
@@ -19,16 +22,17 @@ class QuestProgressEntity {
   bool operator ==(Object other) =>
       other is QuestProgressEntity &&
       other.id == id &&
+      other.line == line &&
       other.progress == progress &&
       other.target == target &&
       other.isCompleted == isCompleted &&
       other.isCurrent == isCurrent;
 
   @override
-  int get hashCode => Object.hash(id, progress, target, isCompleted, isCurrent);
+  int get hashCode => Object.hash(id, line, progress, target, isCompleted, isCurrent);
 
   @override
   String toString() =>
-      'QuestProgressEntity(id: $id, progress: $progress, target: $target, '
+      'QuestProgressEntity(id: $id, line: $line, progress: $progress, target: $target, '
       'isCompleted: $isCompleted, isCurrent: $isCurrent)';
 }
diff --git a/lib/layers/domain/quests/quest.dart b/lib/layers/domain/quests/quest.dart
index 3fc1279..de9c773 100644
--- a/lib/layers/domain/quests/quest.dart
+++ b/lib/layers/domain/quests/quest.dart
@@ -1,9 +1,12 @@
 import '../../../core/config/constants/enum/quest_id.dart';
+import '../../../core/config/constants/enum/quest_line.dart';
 import '../world/world.dart';
 
 abstract interface class Quest {
   QuestId get id;
 
+  QuestLine get line;
+
   int get target;
 
   int progress(World world);
diff --git a/lib/layers/domain/quests/quest_log.dart b/lib/layers/domain/quests/quest_log.dart
index 729b119..668463f 100644
--- a/lib/layers/domain/quests/quest_log.dart
+++ b/lib/layers/domain/quests/quest_log.dart
@@ -1,6 +1,7 @@
 import 'dart:math';
 
 import '../../../core/config/constants/enum/quest_id.dart';
+import '../../../core/config/constants/enum/quest_line.dart';
 import '../entities/game/game_event_entity.dart';
 import '../entities/game/quest_progress_entity.dart';
 import '../world/world.dart';
@@ -22,21 +23,19 @@ class QuestLog {
   }
 
   List<QuestProgressEntity> status(World world) {
-    QuestId? currentId;
+    final current = <QuestLine, QuestId>{};
     for (final quest in _quests) {
-      if (!_completed.contains(quest.id)) {
-        currentId = quest.id;
-        break;
-      }
+      if (!_completed.contains(quest.id)) current.putIfAbsent(quest.line, () => quest.id);
     }
     return [
       for (final quest in _quests)
         QuestProgressEntity(
           id: quest.id,
+          line: quest.line,
           progress: _completed.contains(quest.id) ? quest.target : min(quest.progress(world), quest.target),
           target: quest.target,
           isCompleted: _completed.contains(quest.id),
-          isCurrent: quest.id == currentId,
+          isCurrent: current[quest.line] == quest.id,
         ),
     ];
   }
diff --git a/lib/layers/domain/quests/quests.dart b/lib/layers/domain/quests/quests.dart
index 36f3298..be2c37a 100644
--- a/lib/layers/domain/quests/quests.dart
+++ b/lib/layers/domain/quests/quests.dart
@@ -1,7 +1,11 @@
 import '../../../core/config/constants/enum/blueprint_id.dart';
 import '../../../core/config/constants/enum/quest_id.dart';
+import '../../../core/config/constants/enum/quest_line.dart';
 import '../../../core/config/constants/enum/resource.dart';
 import '../../../core/config/constants/enum/tool_kind.dart';
+import '../rules/arena_levels.dart';
+import '../world/extensions/arena_rules.dart';
+import '../world/extensions/building_rules.dart';
 import '../world/extensions/inventory_rules.dart';
 import '../world/world.dart';
 import 'quest.dart';
@@ -10,29 +14,84 @@ abstract final class Quests {
   static final List<Quest> all = List.unmodifiable([
     _MeasuredQuest(
       id: QuestId.pickUpAxe,
+      line: QuestLine.village,
       target: 1,
       measure: (world) => world.player.inventory.hasTool(ToolKind.axe) ? 1 : 0,
     ),
     _MeasuredQuest(
       id: QuestId.gatherWood,
+      line: QuestLine.village,
       target: 15,
       measure: (world) => world.player.inventory.amount(Resource.wood),
     ),
     _MeasuredQuest(
       id: QuestId.buildHouse,
+      line: QuestLine.village,
       target: 1,
-      measure: (world) =>
-          world.buildings.where((building) => building.isComplete && building.blueprint.id == BlueprintId.house).length,
+      measure: (world) => _built(world, BlueprintId.house),
+    ),
+    _MeasuredQuest(
+      id: QuestId.buildForge,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => _built(world, BlueprintId.forge),
+    ),
+    _MeasuredQuest(
+      id: QuestId.winFirstFight,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => world.hero.clearedLevels.isNotEmpty ? 1 : 0,
+    ),
+    _MeasuredQuest(
+      id: QuestId.buyFirstWeapon,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => world.hero.weaponTier >= 1 ? 1 : 0,
+    ),
+    _MeasuredQuest(
+      id: QuestId.buildArmory,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => _built(world, BlueprintId.armory),
+    ),
+    _MeasuredQuest(
+      id: QuestId.buildMageTower,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => _built(world, BlueprintId.mageTower),
+    ),
+    _MeasuredQuest(
+      id: QuestId.learnASkill,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => world.hero.skills.isNotEmpty ? 1 : 0,
+    ),
+    _MeasuredQuest(
+      id: QuestId.clearHalfArena,
+      line: QuestLine.hero,
+      target: ArenaLevels.all.length ~/ 2,
+      measure: (world) => world.hero.clearedLevels.length,
+    ),
+    _MeasuredQuest(
+      id: QuestId.becomeChampion,
+      line: QuestLine.hero,
+      target: 1,
+      measure: (world) => world.hero.isChampion ? 1 : 0,
     ),
   ]);
+
+  static int _built(World world, BlueprintId id) => world.buildings.hasComplete(id) ? 1 : 0;
 }
 
 final class _MeasuredQuest implements Quest {
-  const _MeasuredQuest({required this.id, required this.target, required this.measure});
+  const _MeasuredQuest({required this.id, required this.line, required this.target, required this.measure});
 
   @override
   final QuestId id;
 
+  @override
+  final QuestLine line;
+
   @override
   final int target;
 
diff --git a/lib/layers/presentation/features/forest/bloc/forest_bloc.dart b/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
index eea6001..91a217e 100644
--- a/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
+++ b/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
@@ -308,10 +308,12 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
         );
         effects.add(BuildingCompletedEffect(buildingId: buildingId));
       case QuestCompletedEventEntity(:final questId):
-        final allDone = _getQuestsUseCase().every((quest) => quest.isCompleted);
+        final quests = _getQuestsUseCase();
+        final line = quests.firstWhere((quest) => quest.id == questId).line;
+        final lineDone = quests.where((quest) => quest.line == line).every((quest) => quest.isCompleted);
         _showMessage(
-          allDone
-              ? Internationalize.forestMessageAllQuestsCompleted
+          lineDone
+              ? Internationalize.forestMessageQuestLineCompleted(line: line)
               : Internationalize.forestMessageQuestCompleted(title: Internationalize.forestQuestTitle(id: questId)),
         );
     }
@@ -466,6 +468,7 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
 
   QuestItemData _questItem(QuestProgressEntity quest) {
     return QuestItemData(
+      line: quest.line,
       title: Internationalize.forestQuestTitle(id: quest.id),
       progressText: switch (quest) {
         QuestProgressEntity(isCompleted: true) => Internationalize.forestQuestDone,
diff --git a/lib/layers/presentation/features/forest/models/quest_item_data.dart b/lib/layers/presentation/features/forest/models/quest_item_data.dart
index a798a80..62d0941 100644
--- a/lib/layers/presentation/features/forest/models/quest_item_data.dart
+++ b/lib/layers/presentation/features/forest/models/quest_item_data.dart
@@ -1,17 +1,23 @@
 import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
+import '../../../../../core/config/constants/enum/quest_line.dart';
 
 class QuestItemData {
+  final QuestLine line;
   final String title;
   final String progressText;
   final QuestItemStatus status;
 
-  const QuestItemData({required this.title, required this.progressText, required this.status});
+  const QuestItemData({required this.line, required this.title, required this.progressText, required this.status});
 
   @override
   bool operator ==(Object other) =>
       identical(this, other) ||
-      other is QuestItemData && other.title == title && other.progressText == progressText && other.status == status;
+      other is QuestItemData &&
+          other.line == line &&
+          other.title == title &&
+          other.progressText == progressText &&
+          other.status == status;
 
   @override
-  int get hashCode => Object.hash(title, progressText, status);
+  int get hashCode => Object.hash(line, title, progressText, status);
 }
diff --git a/lib/layers/presentation/features/forest/widgets/quest_panel.dart b/lib/layers/presentation/features/forest/widgets/quest_panel.dart
index 0d7f4fe..c7317f0 100644
--- a/lib/layers/presentation/features/forest/widgets/quest_panel.dart
+++ b/lib/layers/presentation/features/forest/widgets/quest_panel.dart
@@ -1,6 +1,7 @@
 import 'package:flutter/material.dart';
 
 import '../../../../../core/assets/i18n/internationalize.dart';
+import '../../../../../core/config/constants/enum/quest_line.dart';
 import '../../../theme/colors/custom_colors.dart';
 import '../../../theme/styles/custom_text_styles.dart';
 import '../models/quest_item_data.dart';
@@ -24,7 +25,7 @@ class QuestPanel extends StatelessWidget {
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               _title(),
-              for (final quest in quests) QuestRow(quest: quest),
+              for (final line in QuestLine.values) ..._section(line),
             ],
           ),
         ),
@@ -32,6 +33,21 @@ class QuestPanel extends StatelessWidget {
     );
   }
 
+  List<Widget> _section(QuestLine line) {
+    final rows = quests.where((quest) => quest.line == line);
+    if (rows.isEmpty) return const [];
+    return [
+      Padding(
+        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
+        child: Text(
+          Internationalize.forestQuestLine(line: line),
+          style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudAccent),
+        ),
+      ),
+      for (final quest in rows) QuestRow(quest: quest),
+    ];
+  }
+
   Widget _title() {
     return Padding(
       padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
```

Run: `flutter test`
Expected: **633 tests** en verde.

- [ ] **Step 4: Guía**

En `CLAUDE.md`:
- `quests/` (`Quest`, `Quests`, `QuestLog` with sticky completion) pasa a `quests/` (`Quest` with its `QuestLine`, `Quests` (village line, then the hero line), `QuestLog` with sticky completion and one current quest per line).
- `QuestPanel` + `QuestRow` pasa a `QuestPanel` (one section per `QuestLine`) + `QuestRow`.

- [ ] **Step 5: Verificación completa**

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart '*.mocks.dart'
flutter analyze
flutter test
```

- [ ] **Step 6: Commit**

```bash
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-C7]: Add the hero quest line next to the village one"
```

---

### Task TC7.3: Equipo sólo con oro y equilibrado

**Files:**
  - Modify: `docs/GAME_DESIGN.md`
  - Modify: `lib/layers/domain/rules/arena_levels.dart`
  - Modify: `lib/layers/domain/rules/gear.dart`
  - Create: `test/layers/domain/combat/balance_test.dart`
  - Modify: `test/layers/domain/rules/arena_levels_test.dart`
  - Modify: `test/layers/domain/use-cases/arena/start_fight_use_case_test.dart`
  - Modify: `test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart`
  - Modify: `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - Create: `test/mocks/domain/game/balance_scenario_mock.dart`
  - Modify: `test/mocks/domain/world/funds_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_result_data_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`
  - Modify: `test/mocks/presentation/features/forest/gear_item_data_mock.dart`
  - Modify: `CLAUDE.md`, `docs/boost/plans/2026-10-06-hero-arena/ARENA-FIXES.md`, `docs/boost/plans/2026-10-06-hero-arena/README.md`

**Interfaces:**
- Consumes: `Combat.resolve`, `HeroRules.stats` / `tierOf`, `Gear.of`, `Skills.byId`, `Skills.building`, `Blueprints.of`, `Rules.repeatRewardDivisor`, `ArenaLevels.all`.
- Produces:
  - `BalanceScenarioMock` (`seeds`, `minWinRate`, `maxWinRate`, `maxWinRateOneStepBehind`, `maxRepeats`, `expectedHero`);
  - `Gear.all` y `ArenaLevels.all` con los números de las decisiones 6 y 7;
  - `ArenaResultDataMock.championHundredFiftyGold` / `victoryFiftyGold` (antes `championHundredGold` / `victoryThirtyThreeGold`).

- [ ] **Step 1: Rama**

Sigue en `feature/PROJECT-C7-hero-quests-balance` (con TC7.1 y TC7.2 hechas).

- [ ] **Step 2: Test de equilibrado y mocks (rojo)**

```diff
diff --git a/test/layers/domain/combat/balance_test.dart b/test/layers/domain/combat/balance_test.dart
new file mode 100644
index 0000000..2928b7e
--- /dev/null
+++ b/test/layers/domain/combat/balance_test.dart
@@ -0,0 +1,113 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:rpg/core/config/constants/enum/gear_slot.dart';
+import 'package:rpg/core/config/constants/enum/resource.dart';
+import 'package:rpg/layers/domain/combat/combat.dart';
+import 'package:rpg/layers/domain/entities/combat/arena_level_entity.dart';
+import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
+import 'package:rpg/layers/domain/rules/arena_levels.dart';
+import 'package:rpg/layers/domain/rules/blueprints.dart';
+import 'package:rpg/layers/domain/rules/gear.dart';
+import 'package:rpg/layers/domain/rules/rules.dart';
+import 'package:rpg/layers/domain/rules/skills.dart';
+import 'package:rpg/layers/domain/world/extensions/hero_rules.dart';
+
+import '../../../mocks/domain/game/balance_scenario_mock.dart';
+
+double _winRate(ArenaLevelEntity level, HeroEntity hero) {
+  var wins = 0;
+  for (var seed = 0; seed < BalanceScenarioMock.seeds; seed++) {
+    final log = Combat.resolve(level: level, heroStats: hero.stats, skills: hero.skills, seed: seed);
+    if (log.isVictory) wins++;
+  }
+  return wins / BalanceScenarioMock.seeds;
+}
+
+int _gold(Map<Resource, int> cost) => cost[Resource.gold] ?? 0;
+
+int _goldSpentOn(HeroEntity hero) {
+  var total = 0;
+  for (final slot in GearSlot.values) {
+    for (var tier = 1; tier <= hero.tierOf(slot); tier++) {
+      total += _gold(Gear.of(slot, tier).cost);
+    }
+  }
+  for (final skill in hero.skills) {
+    total += _gold(Skills.byId(skill).cost);
+  }
+  if (hero.skills.isNotEmpty) total += _gold(Blueprints.of(Skills.building).cost);
+  return total;
+}
+
+HeroEntity _expectedHero(ArenaLevelEntity level) => BalanceScenarioMock.expectedHero[level.id]!;
+
+void main() {
+  const levels = ArenaLevels.all;
+
+  test('testWhenTheTableIsReadThenEveryArenaLevelHasAnExpectedHero', () {
+    // given
+    final table = BalanceScenarioMock.expectedHero;
+
+    // when
+    final ids = table.keys.toList();
+
+    // then
+    expect(ids, levels.map((level) => level.id));
+  });
+
+  test('testWhenTheHeroHasTheExpectedGearThenEachLevelIsWonMostButNotAllOfTheTime', () {
+    // given
+    final later = levels.skip(1);
+
+    // when
+    final first = _winRate(levels.first, _expectedHero(levels.first));
+    final rates = {for (final level in later) level.id: _winRate(level, _expectedHero(level))};
+
+    // then
+    expect(first, greaterThanOrEqualTo(BalanceScenarioMock.minWinRate), reason: 'the first fight is meant to be won');
+    for (final MapEntry(key: id, value: rate) in rates.entries) {
+      expect(
+        rate,
+        inInclusiveRange(BalanceScenarioMock.minWinRate, BalanceScenarioMock.maxWinRate),
+        reason: '${id.name} with the expected hero',
+      );
+    }
+  });
+
+  test('testWhenTheHeroIsOneStepBehindThenEachLevelIsLostMostOfTheTime', () {
+    // given
+    final pairs = [
+      for (var index = 1; index < levels.length; index++)
+        if (_expectedHero(levels[index - 1]) != _expectedHero(levels[index]))
+          (levels[index], _expectedHero(levels[index - 1])),
+    ];
+
+    // when
+    final rates = {for (final (level, hero) in pairs) level.id: _winRate(level, hero)};
+
+    // then
+    expect(rates, isNotEmpty);
+    for (final MapEntry(key: id, value: rate) in rates.entries) {
+      expect(rate, lessThan(BalanceScenarioMock.maxWinRateOneStepBehind), reason: '${id.name} one step behind');
+    }
+  });
+
+  test('testWhenEveryEarlierLevelIsWonOnceAndTheLastOneRepeatedThenTheExpectedGearIsAffordable', () {
+    // given
+    var firstRewards = 0;
+    final budgets = <(String, int, int)>[];
+
+    // when
+    for (final (index, level) in levels.indexed) {
+      final repeats = index == 0
+          ? 0
+          : BalanceScenarioMock.maxRepeats * (_gold(levels[index - 1].reward) ~/ Rules.repeatRewardDivisor);
+      budgets.add((level.id.name, _goldSpentOn(_expectedHero(level)), firstRewards + repeats));
+      firstRewards += _gold(level.reward);
+    }
+
+    // then
+    for (final (name, spent, earned) in budgets) {
+      expect(spent, lessThanOrEqualTo(earned), reason: '$name: gear and skills cost $spent, the arena paid $earned');
+    }
+  });
+}
diff --git a/test/layers/domain/rules/arena_levels_test.dart b/test/layers/domain/rules/arena_levels_test.dart
index 4199938..0f48cdf 100644
--- a/test/layers/domain/rules/arena_levels_test.dart
+++ b/test/layers/domain/rules/arena_levels_test.dart
@@ -90,7 +90,12 @@ void main() {
       [EnemyKind.bear],
       [EnemyKind.wolf, EnemyKind.wolf, EnemyKind.wolf],
     ]);
-    expect(levels.map((level) => (level.power, level.reward[Resource.gold])), [(30, 15), (60, 25), (59, 35), (84, 55)]);
+    expect(levels.map((level) => (level.power, level.reward[Resource.gold])), [
+      (29, 20),
+      (68, 40),
+      (62, 55),
+      (135, 100),
+    ]);
   });
 
   test('testWhenFindingByIdThenItReturnsThatLevel', () {
@@ -101,6 +106,6 @@ void main() {
     final level = ArenaLevels.byId(id);
 
     // then
-    expect((level.id, level.enemies.length, level.power), (ArenaLevelId.barbarianChief, 3, 173));
+    expect((level.id, level.enemies.length, level.power), (ArenaLevelId.barbarianChief, 3, 210));
   });
 }
diff --git a/test/layers/domain/use-cases/arena/start_fight_use_case_test.dart b/test/layers/domain/use-cases/arena/start_fight_use_case_test.dart
index 4eb0f51..937a767 100644
--- a/test/layers/domain/use-cases/arena/start_fight_use_case_test.dart
+++ b/test/layers/domain/use-cases/arena/start_fight_use_case_test.dart
@@ -90,7 +90,7 @@ void main() {
 
     // then
     final played = result as FightPlayedEntity;
-    expect((played.log.isVictory, played.log.rounds, played.advice), (false, 6, FightAdvice.needAttack));
+    expect((played.log.isVictory, played.log.rounds, played.advice), (false, 7, FightAdvice.needAttack));
     expect(played.log.reward, isEmpty);
     expect(session.world.funds.amount(Resource.gold), 0);
     expect(session.world.hero, HeroEntityMock.wolfHunterAfterAnotherFight);
diff --git a/test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart b/test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart
index 702659f..d63b49e 100644
--- a/test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart
+++ b/test/layers/domain/use-cases/hero/buy_gear_use_case_test.dart
@@ -39,7 +39,7 @@ void main() {
     // then
     expect(result, BuyGearResult.missingBuilding);
     expect(world.hero, HeroEntityMock.mock);
-    expect(world.funds.amount(Resource.gold), 10);
+    expect(world.funds.amount(Resource.gold), 30);
   });
 
   test('testWhenTheForgeIsStillBeingBuiltThenTheSwordNeedsTheBuilding', () {
@@ -73,7 +73,7 @@ void main() {
 
     // then
     expect(result, BuyGearResult.notNextTier);
-    expect(world.funds.amount(Resource.gold), 10);
+    expect(world.funds.amount(Resource.gold), 30);
   });
 
   test('testWhenBuyingTheEquippedGearAgainThenItIsNotTheNextTier', () {
@@ -97,7 +97,7 @@ void main() {
     // then
     expect(result, BuyGearResult.notEnoughResources);
     expect(world.hero, HeroEntityMock.mock);
-    expect((world.funds.amount(Resource.wood), world.funds.amount(Resource.gold)), (20, 5));
+    expect((world.funds.amount(Resource.wood), world.funds.amount(Resource.gold)), (0, 25));
   });
 
   test('testWhenSeveralChecksFailThenTheyAreReportedInOrder', () {
diff --git a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
index 67e83e0..8096719 100644
--- a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
+++ b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
@@ -362,7 +362,7 @@ void main() {
     verify: (bloc) {
       // then
       expect(effects, [ArenaEffectMock.won, ArenaEffectMock.champion]);
-      expect(bloc.state.data.result, ArenaResultDataMock.championHundredGold);
+      expect(bloc.state.data.result, ArenaResultDataMock.championHundredFiftyGold);
     },
   );
 
@@ -386,7 +386,7 @@ void main() {
     verify: (bloc) {
       // then
       expect(effects, [ArenaEffectMock.won]);
-      expect(bloc.state.data.result, ArenaResultDataMock.victoryThirtyThreeGold);
+      expect(bloc.state.data.result, ArenaResultDataMock.victoryFiftyGold);
     },
   );
 
@@ -528,13 +528,13 @@ void main() {
         ..add(const ArenaStarted())
         ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 12000);
+      ArenaBlocMock.tickFor(bloc, 15000);
     },
     wait: Duration.zero,
     verify: (bloc) {
       // then
-      expect(effects[10], ArenaEffectMock.heroHealedTwelve);
-      expect(effects[11], ArenaEffectMock.secondWindUsed);
+      expect(effects[12], ArenaEffectMock.heroHealedTwelve);
+      expect(effects[13], ArenaEffectMock.secondWindUsed);
       expect(effects.last, ArenaEffectMock.lost);
     },
   );
diff --git a/test/mocks/domain/game/balance_scenario_mock.dart b/test/mocks/domain/game/balance_scenario_mock.dart
new file mode 100644
index 0000000..7b31425
--- /dev/null
+++ b/test/mocks/domain/game/balance_scenario_mock.dart
@@ -0,0 +1,36 @@
+import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
+import 'package:rpg/core/config/constants/enum/skill_id.dart';
+import 'package:rpg/layers/domain/entities/hero/hero_entity.dart';
+
+abstract final class BalanceScenarioMock {
+  static const int seeds = 100;
+
+  static const double minWinRate = 0.6;
+
+  static const double maxWinRate = 0.95;
+
+  static const double maxWinRateOneStepBehind = 0.5;
+
+  static const int maxRepeats = 3;
+
+  static const Map<ArenaLevelId, HeroEntity> expectedHero = {
+    ArenaLevelId.banditRookie: HeroEntity(),
+    ArenaLevelId.wolf: HeroEntity(),
+    ArenaLevelId.banditVeteran: HeroEntity(weaponTier: 1),
+    ArenaLevelId.wolfPair: HeroEntity(weaponTier: 1, armorTier: 1),
+    ArenaLevelId.bear: HeroEntity(weaponTier: 2, armorTier: 1),
+    ArenaLevelId.banditTrio: HeroEntity(weaponTier: 2, armorTier: 2),
+    ArenaLevelId.barbarian: HeroEntity(weaponTier: 2, armorTier: 2, skills: {SkillId.doubleStrike}),
+    ArenaLevelId.wolfPack: HeroEntity(weaponTier: 2, armorTier: 2, skills: {SkillId.doubleStrike, SkillId.dodge}),
+    ArenaLevelId.barbarianPair: HeroEntity(
+      weaponTier: 3,
+      armorTier: 2,
+      skills: {SkillId.doubleStrike, SkillId.dodge},
+    ),
+    ArenaLevelId.barbarianChief: HeroEntity(
+      weaponTier: 3,
+      armorTier: 3,
+      skills: {SkillId.doubleStrike, SkillId.dodge},
+    ),
+  };
+}
diff --git a/test/mocks/domain/world/funds_mock.dart b/test/mocks/domain/world/funds_mock.dart
index c50f735..24f5554 100644
--- a/test/mocks/domain/world/funds_mock.dart
+++ b/test/mocks/domain/world/funds_mock.dart
@@ -15,9 +15,9 @@ abstract final class FundsMock {
 
   static const Map<Resource, int> threeGold = {Resource.gold: 3};
 
-  static const Map<Resource, int> shortSwordPrice = {Resource.wood: 20, Resource.gold: 10};
+  static const Map<Resource, int> shortSwordPrice = {Resource.gold: 30};
 
-  static const Map<Resource, int> fiveGoldShortOfShortSword = {Resource.wood: 20, Resource.gold: 5};
+  static const Map<Resource, int> fiveGoldShortOfShortSword = {Resource.gold: 25};
 
   static const Map<Resource, int> doubleStrikePrice = {Resource.gold: 60};
 
diff --git a/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart b/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
index cc15491..e343b64 100644
--- a/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
@@ -32,7 +32,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
     powerText: Internationalize.arenaPower(power: 41),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 20),
+    rewardText: Internationalize.arenaReward(amount: 30),
     status: ArenaLevelItemStatus.locked,
   );
 
@@ -42,7 +42,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
     powerText: Internationalize.arenaPower(power: 41),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 20),
+    rewardText: Internationalize.arenaReward(amount: 30),
     status: ArenaLevelItemStatus.open,
   );
 
@@ -50,9 +50,9 @@ abstract final class ArenaLevelItemDataMock {
     id: ArenaLevelId.banditTrio,
     name: Internationalize.arenaLevel(id: ArenaLevelId.banditTrio),
     enemiesText: Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit)),
-    powerText: Internationalize.arenaPower(power: 78),
+    powerText: Internationalize.arenaPower(power: 123),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 40),
+    rewardText: Internationalize.arenaReward(amount: 75),
     status: ArenaLevelItemStatus.locked,
   );
 
@@ -60,9 +60,9 @@ abstract final class ArenaLevelItemDataMock {
     id: ArenaLevelId.wolf,
     name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
-    powerText: Internationalize.arenaPower(power: 30),
+    powerText: Internationalize.arenaPower(power: 29),
     tone: PowerTone.easy,
-    rewardText: Internationalize.arenaReward(amount: 15),
+    rewardText: Internationalize.arenaReward(amount: 20),
     status: ArenaLevelItemStatus.locked,
   );
 
@@ -70,9 +70,9 @@ abstract final class ArenaLevelItemDataMock {
     id: ArenaLevelId.wolf,
     name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
-    powerText: Internationalize.arenaPower(power: 30),
+    powerText: Internationalize.arenaPower(power: 29),
     tone: PowerTone.easy,
-    rewardText: Internationalize.arenaReward(amount: 15),
+    rewardText: Internationalize.arenaReward(amount: 20),
     status: ArenaLevelItemStatus.open,
   );
 
@@ -83,9 +83,9 @@ abstract final class ArenaLevelItemDataMock {
       Internationalize.arenaEnemy(kind: EnemyKind.barbarianChief),
       Internationalize.arenaEnemyCount(count: 2, name: Internationalize.arenaEnemy(kind: EnemyKind.barbarian)),
     ].join(', '),
-    powerText: Internationalize.arenaPower(power: 173),
+    powerText: Internationalize.arenaPower(power: 210),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 100),
+    rewardText: Internationalize.arenaReward(amount: 150),
     status: ArenaLevelItemStatus.locked,
   );
 }
diff --git a/test/mocks/presentation/features/arena/arena_result_data_mock.dart b/test/mocks/presentation/features/arena/arena_result_data_mock.dart
index eef83a9..164a006 100644
--- a/test/mocks/presentation/features/arena/arena_result_data_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_result_data_mock.dart
@@ -9,16 +9,16 @@ abstract final class ArenaResultDataMock {
     detail: Internationalize.arenaReward(amount: 10),
   );
 
-  static ArenaResultData get championHundredGold => ArenaResultData(
+  static ArenaResultData get championHundredFiftyGold => ArenaResultData(
     isVictory: true,
     title: Internationalize.arenaChampion,
-    detail: Internationalize.arenaReward(amount: 100),
+    detail: Internationalize.arenaReward(amount: 150),
   );
 
-  static ArenaResultData get victoryThirtyThreeGold => ArenaResultData(
+  static ArenaResultData get victoryFiftyGold => ArenaResultData(
     isVictory: true,
     title: Internationalize.arenaVictory,
-    detail: Internationalize.arenaReward(amount: 33),
+    detail: Internationalize.arenaReward(amount: 50),
   );
 
   static ArenaResultData get defeatNeedAttack => ArenaResultData(
diff --git a/test/mocks/presentation/features/arena/fighter_render_data_mock.dart b/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
index 447eeb4..b178561 100644
--- a/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
+++ b/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
@@ -27,8 +27,8 @@ abstract final class FighterRenderDataMock {
     side: FightSide.enemy,
     index: 0,
     enemyKind: EnemyKind.bandit,
-    health: 30,
-    maxHealth: 30,
+    health: 36,
+    maxHealth: 36,
     pose: FighterPose.idle,
     isTargeted: true,
   );
@@ -37,8 +37,8 @@ abstract final class FighterRenderDataMock {
     side: FightSide.enemy,
     index: 0,
     enemyKind: EnemyKind.wolf,
-    health: 22,
-    maxHealth: 22,
+    health: 20,
+    maxHealth: 20,
     pose: FighterPose.idle,
     isTargeted: true,
   );
@@ -104,8 +104,8 @@ abstract final class FighterRenderDataMock {
     side: FightSide.enemy,
     index: 0,
     enemyKind: EnemyKind.wolf,
-    health: 20,
-    maxHealth: 22,
+    health: 18,
+    maxHealth: 20,
     pose: FighterPose.attack,
     swingProgress: swingProgress,
     isTargeted: true,
diff --git a/test/mocks/presentation/features/forest/gear_item_data_mock.dart b/test/mocks/presentation/features/forest/gear_item_data_mock.dart
index 8cdb5b1..0847651 100644
--- a/test/mocks/presentation/features/forest/gear_item_data_mock.dart
+++ b/test/mocks/presentation/features/forest/gear_item_data_mock.dart
@@ -51,10 +51,7 @@ abstract final class GearItemDataMock {
     id: GearId.leatherArmor,
     name: Internationalize.forestGear(id: GearId.leatherArmor),
     statsText: Internationalize.forestHeroArmorStats(defense: 3, health: 40),
-    costText: [
-      Internationalize.forestAmount(resource: Resource.wood, amount: 15),
-      Internationalize.forestAmount(resource: Resource.gold, amount: 15),
-    ].join(', '),
+    costText: Internationalize.forestAmount(resource: Resource.gold, amount: 40),
     reasonText: Internationalize.forestHeroNeedsBuilding(
       name: Internationalize.forestBlueprint(id: BlueprintId.armory),
     ),
@@ -65,10 +62,7 @@ abstract final class GearItemDataMock {
     id: GearId.shortSword,
     name: Internationalize.forestGear(id: GearId.shortSword),
     statsText: Internationalize.forestHeroWeaponStats(min: 6, max: 8),
-    costText: [
-      Internationalize.forestAmount(resource: Resource.wood, amount: 20),
-      Internationalize.forestAmount(resource: Resource.gold, amount: 10),
-    ].join(', '),
+    costText: Internationalize.forestAmount(resource: Resource.gold, amount: 30),
     reasonText: reasonText,
     canBuy: canBuy,
   );
```

Run: `flutter test test/layers/domain/combat/balance_test.dart`
Expected: FAIL (con los números de TC7.1 hay niveles que se ganan siempre o nunca, y el oro no alcanza).

- [ ] **Step 3: Números (verde)**

```diff
diff --git a/lib/layers/domain/rules/arena_levels.dart b/lib/layers/domain/rules/arena_levels.dart
index 052ff11..495ebe4 100644
--- a/lib/layers/domain/rules/arena_levels.dart
+++ b/lib/layers/domain/rules/arena_levels.dart
@@ -22,106 +22,115 @@ abstract final class ArenaLevels {
     ArenaLevelEntity(
       id: ArenaLevelId.wolf,
       enemies: [
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 22)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 20)),
       ],
-      reward: {Resource.gold: 15},
+      reward: {Resource.gold: 20},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.banditVeteran,
       enemies: [
         EnemyEntity(
           kind: EnemyKind.bandit,
-          stats: CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30),
+          stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 2, health: 36),
         ),
       ],
-      reward: {Resource.gold: 20},
+      reward: {Resource.gold: 30},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.wolfPair,
       enemies: [
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 22)),
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 22)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 6, attackMax: 8, defense: 1, health: 18)),
+        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 6, attackMax: 8, defense: 1, health: 18)),
       ],
-      reward: {Resource.gold: 25},
+      reward: {Resource.gold: 40},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.bear,
       enemies: [
         EnemyEntity(
           kind: EnemyKind.bear,
-          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 3, health: 40),
+          stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 3, health: 40),
         ),
       ],
-      reward: {Resource.gold: 35},
+      reward: {Resource.gold: 55},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.banditTrio,
       enemies: [
         EnemyEntity(
           kind: EnemyKind.bandit,
-          stats: CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 20),
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 9, defense: 1, health: 26),
         ),
         EnemyEntity(
           kind: EnemyKind.bandit,
-          stats: CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 20),
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 9, defense: 1, health: 26),
         ),
         EnemyEntity(
           kind: EnemyKind.bandit,
-          stats: CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 20),
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 9, defense: 1, health: 26),
         ),
       ],
-      reward: {Resource.gold: 40},
+      reward: {Resource.gold: 75},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarian,
       enemies: [
         EnemyEntity(
           kind: EnemyKind.barbarian,
-          stats: CombatStatsEntity(attackMin: 10, attackMax: 14, defense: 4, health: 60),
+          stats: CombatStatsEntity(attackMin: 10, attackMax: 14, defense: 4, health: 58),
         ),
       ],
-      reward: {Resource.gold: 50},
+      reward: {Resource.gold: 90},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.wolfPack,
       enemies: [
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 18)),
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 18)),
-        EnemyEntity(kind: EnemyKind.wolf, stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 1, health: 18)),
+        EnemyEntity(
+          kind: EnemyKind.wolf,
+          stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 1, health: 22),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.wolf,
+          stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 1, health: 22),
+        ),
+        EnemyEntity(
+          kind: EnemyKind.wolf,
+          stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 1, health: 22),
+        ),
       ],
-      reward: {Resource.gold: 55},
+      reward: {Resource.gold: 100},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarianPair,
       enemies: [
         EnemyEntity(
           kind: EnemyKind.barbarian,
-          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 4, health: 50),
+          stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 4, health: 52),
         ),
         EnemyEntity(
           kind: EnemyKind.barbarian,
-          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 4, health: 50),
+          stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 4, health: 52),
         ),
       ],
-      reward: {Resource.gold: 65},
+      reward: {Resource.gold: 120},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarianChief,
       enemies: [
         EnemyEntity(
           kind: EnemyKind.barbarianChief,
-          stats: CombatStatsEntity(attackMin: 10, attackMax: 14, defense: 5, health: 70),
+          stats: CombatStatsEntity(attackMin: 16, attackMax: 20, defense: 5, health: 72),
         ),
         EnemyEntity(
           kind: EnemyKind.barbarian,
-          stats: CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30),
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 2, health: 31),
         ),
         EnemyEntity(
           kind: EnemyKind.barbarian,
-          stats: CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30),
+          stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 2, health: 31),
         ),
       ],
-      reward: {Resource.gold: 100},
+      reward: {Resource.gold: 150},
     ),
   ];
 
diff --git a/lib/layers/domain/rules/gear.dart b/lib/layers/domain/rules/gear.dart
index fb12335..2da05ce 100644
--- a/lib/layers/domain/rules/gear.dart
+++ b/lib/layers/domain/rules/gear.dart
@@ -11,7 +11,7 @@ abstract final class Gear {
       id: GearId.shortSword,
       slot: GearSlot.weapon,
       tier: 1,
-      cost: {Resource.wood: 20, Resource.gold: 10},
+      cost: {Resource.gold: 30},
       attackMin: 6,
       attackMax: 8,
     ),
@@ -19,7 +19,7 @@ abstract final class Gear {
       id: GearId.ironSword,
       slot: GearSlot.weapon,
       tier: 2,
-      cost: {Resource.wood: 30, Resource.gold: 40},
+      cost: {Resource.gold: 60},
       attackMin: 9,
       attackMax: 11,
     ),
@@ -27,7 +27,7 @@ abstract final class Gear {
       id: GearId.steelSword,
       slot: GearSlot.weapon,
       tier: 3,
-      cost: {Resource.wood: 40, Resource.gold: 120},
+      cost: {Resource.gold: 110},
       attackMin: 12,
       attackMax: 16,
     ),
@@ -36,7 +36,7 @@ abstract final class Gear {
       id: GearId.leatherArmor,
       slot: GearSlot.armor,
       tier: 1,
-      cost: {Resource.wood: 15, Resource.gold: 15},
+      cost: {Resource.gold: 40},
       defense: 3,
       health: 40,
     ),
@@ -44,7 +44,7 @@ abstract final class Gear {
       id: GearId.chainMail,
       slot: GearSlot.armor,
       tier: 2,
-      cost: {Resource.wood: 30, Resource.gold: 50},
+      cost: {Resource.gold: 70},
       defense: 5,
       health: 55,
     ),
@@ -52,7 +52,7 @@ abstract final class Gear {
       id: GearId.plateArmor,
       slot: GearSlot.armor,
       tier: 3,
-      cost: {Resource.wood: 40, Resource.gold: 150},
+      cost: {Resource.gold: 120},
       defense: 8,
       health: 75,
     ),
```

Run: `flutter test`
Expected: **637 tests** en verde.

- [ ] **Step 4: Documentación**

`docs/GAME_DESIGN.md`:

```diff
diff --git a/docs/GAME_DESIGN.md b/docs/GAME_DESIGN.md
index 729b935..c39914b 100644
--- a/docs/GAME_DESIGN.md
+++ b/docs/GAME_DESIGN.md
@@ -186,15 +186,16 @@ Aldea: madera / piedra ──▶ Herrería, Armería, Torre de magia ──▶ e
 
 | Atributo | Para qué sirve |
 |---|---|
-| **Ataque** | Daño de cada golpe. |
+| **Ataque** | Un rango "de tanto a tanto" (hacha 3–5): cada golpe elige un valor del rango. |
 | **Defensa** | Se resta al daño recibido (cada golpe hace al menos 1). |
 | **Vida** | Golpes que aguanta. Se recupera entera al terminar cada pelea. |
-| **Poder** | Resumen que se ve en el HUD y junto a cada nivel: `ataque × 3 + defensa × 4 + vida / 2`, +10 % por habilidad. Sirve para orientarse; quien decide la pelea es la simulación. |
+| **Poder** | Resumen que se ve en el HUD y junto a cada nivel: `ataque medio × 3 + defensa × 4 + vida / 2`, +10 % por habilidad. Sirve para orientarse; quien decide la pelea es la simulación. |
 
-Valores de partida orientativos: Ataque 4, Defensa 1, Vida 30 (Poder ≈ 31). Con todo el equipo y las tres habilidades
-el Poder ronda 150. Las cifras finales se fijan al equilibrar (fase C7 del plan).
+Valores de partida: Ataque 3–5, Defensa 1, Vida 30 (Poder 31). Con todo el equipo y las tres habilidades, Ataque
+12–16, Defensa 8, Vida 75 (Poder 144). Las cifras son las del equilibrado de la fase C7, protegidas por
+`test/layers/domain/combat/balance_test.dart`.
 
-**Edificios de mejora** (de la aldea; cuestan madera, y oro a partir del segundo nivel de mejora):
+**Edificios de mejora** (se construyen con recursos de la aldea; lo que venden se paga **sólo con oro** de la arena):
 
 | Edificio | Qué vende | Niveles |
 |---|---|---|
@@ -203,22 +204,39 @@ el Poder ronda 150. Las cifras finales se fijan al equilibrar (fase C7 del plan)
 | **Torre de magia** | Habilidades pasivas | *Golpe doble* (cada tercer ataque golpea dos veces), *Segundo aliento* (una vez por pelea, al bajar del 30 % de vida recupera el 40 %), *Esquiva* (20 % de evitar un golpe) |
 
 Se llama *Torre de magia* y no "taller mágico" para no confundirla con el *Taller* de herramientas (sección 3.2).
-Si existe la piedra, el equipo de nivel alto también pide piedra.
+Si existe la piedra, la piden los edificios, no el equipo.
 
-**Niveles de la arena** (orientativo; empieza con enemigos humanos porque reutilizan el arte del héroe):
-
-| Nivel | Enemigos | Poder aprox. | Recompensa (primera vez) |
-|---|---|---|---|
-| 1 | Bandido novato | 20 | 10 de oro |
-| 2 | Lobo | 30 | 15 de oro |
-| 3 | Bandido veterano | 40 | 20 de oro |
-| 4 | Dos lobos | 60 | 25 de oro |
-| 5 | Oso | 70 | 35 de oro |
-| 6 | Tres bandidos | 90 | 40 de oro |
-| 7 | Bárbaro | 100 | 50 de oro |
-| 8 | Manada de tres lobos | 110 | 55 de oro |
-| 9 | Dos bárbaros | 130 | 65 de oro |
-| 10 | Jefe bárbaro y su guardia | 150 | 100 de oro |
+| Pieza | Ataque / Defensa · Vida | Precio |
+|---|---|---|
+| Hacha de leñador (inicial) | Ataque 3–5 | — |
+| Espada corta | Ataque 6–8 | 30 de oro |
+| Espada de hierro | Ataque 9–11 | 60 de oro |
+| Espada de acero | Ataque 12–16 | 110 de oro |
+| Ropa de trabajo (inicial) | Defensa 1 · Vida 30 | — |
+| Armadura de cuero | Defensa 3 · Vida 40 | 40 de oro |
+| Cota de malla | Defensa 5 · Vida 55 | 70 de oro |
+| Armadura de placas | Defensa 8 · Vida 75 | 120 de oro |
+| *Golpe doble* / *Esquiva* / *Segundo aliento* | — | 60 / 90 / 130 de oro (con la Torre de magia: 30 de madera y 40 de oro) |
+
+**Niveles de la arena** (equilibrados en la fase C7; cada enemigo: Ataque / Defensa / Vida):
+
+| Nivel | Enemigos | Poder | Recompensa (primera vez) | Héroe esperado | Gana con él | Con un escalón menos |
+|---|---|---|---|---|---|---|
+| 1 | Bandido novato (2–4 / 0 / 20) | 19 | 10 de oro | Inicial | casi siempre | — |
+| 2 | Lobo (4–6 / 1 / 20) | 29 | 20 de oro | Inicial | 60–95 % | — |
+| 3 | Bandido veterano (4–6 / 2 / 36) | 41 | 30 de oro | Espada corta | 60–95 % | < 50 % |
+| 4 | Dos lobos (6–8 / 1 / 18) | 68 | 40 de oro | + Armadura de cuero | 60–95 % | < 50 % |
+| 5 | Oso (8–12 / 3 / 40) | 62 | 55 de oro | + Espada de hierro | 60–95 % | < 50 % |
+| 6 | Tres bandidos (7–9 / 1 / 26) | 123 | 75 de oro | + Cota de malla | 60–95 % | < 50 % |
+| 7 | Bárbaro (10–14 / 4 / 58) | 81 | 90 de oro | + *Golpe doble* | 60–95 % | < 50 % |
+| 8 | Manada de tres lobos (8–12 / 1 / 22) | 135 | 100 de oro | + *Esquiva* | 60–95 % | < 50 % |
+| 9 | Dos bárbaros (8–12 / 4 / 52) | 144 | 120 de oro | + Espada de acero | 60–95 % | < 50 % |
+| 10 | Jefe bárbaro (16–20 / 5 / 72) y dos guardias (7–11 / 2 / 31) | 210 | 150 de oro | + Armadura de placas | 60–95 % | < 50 % |
+
+- "Gana con él" y "con un escalón menos" son el porcentaje de victorias en 100 peleas (semillas 0–99). El Poder del
+  nivel no sube siempre: el oso pega fuerte pero es uno solo, y los grupos cuentan a todos sus miembros.
+- Con el oro de la primera victoria de cada nivel anterior, más repetir como mucho tres veces el último, se paga el
+  héroe esperado del nivel siguiente. *Segundo aliento* queda como mejora opcional para el final.
 
 - Un nivel se desbloquea al ganar el anterior. Repetir un nivel ganado da un tercio del oro.
 - Perder no quita nada: se vuelve a la aldea con un consejo ("Te falta Defensa", "Prueba con la Cota de malla").
@@ -229,7 +247,7 @@ Si existe la piedra, el equipo de nivel alto también pide piedra.
    habilidades y resultado. Es una simulación por turnos con semilla:
    - el héroe golpea primero, siempre al primer enemigo que queda en pie;
    - después golpea cada enemigo vivo;
-   - daño = `max(1, ataque − defensa)`, ±15 % de azar;
+   - daño = `max(1, valor − defensa)`, con un valor al azar del rango de ataque del atacante;
    - como mucho 30 rondas; si nadie cae, cuenta como derrota.
 3. La pantalla **reproduce** ese registro en 5–8 segundos: el héroe y los enemigos frente a frente, la animación
    `slash` que ya existe, unas gotas de sangre en cada impacto, barras de vida, números de daño flotando, y al final
```

`ARENA-FIXES.md`: en las secciones 2 y 4, la nota "Pasa a C7 (decidido el 2026-10-08)…" pasa a "**Hecho en C7 (2026-10-09).** Los números finales están en `docs/GAME_DESIGN.md` (sección 3.8)."

README de la arena, sección 3.2, fila *Piedra (F5) ↔ coste del equipo (C3)*: la columna "C3 pone piedra…" pasa a "Desde C7 el equipo se paga sólo con oro." y la de la aldea a "F5 pone la piedra en los edificios (Herrería, Armería, Torre de magia), no en `Gear.all`, y mantiene en verde `balance_test.dart`."

`CLAUDE.md`:
- `Gear` catalogue (`workshopFor`: weapons at the forge, armor at the armory) pasa a `Gear` catalogue (gold only; `workshopFor`: weapons at the forge, armor at the armory).
- tras la línea **Arena fights are deterministic:** añade:
  `- **Arena balance:** `test/layers/domain/combat/balance_test.dart` plays every arena level with 100 seeds for the expected hero of `BalanceScenarioMock` (60–95 % of wins, the first level may always be won; under 50 % one step behind; the gold of earlier first wins plus three repeats pays the expected gear). Any change to `Gear`, `Skills`, `ArenaLevels` or building costs must keep it green; the final table lives in `docs/GAME_DESIGN.md` 3.8.`

- [ ] **Step 5: Verificación completa**

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart '*.mocks.dart'
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `No issues found!`, **637** en verde y los de Chrome en verde.

- [ ] **Step 6: Commit**

```bash
git add lib test docs
git add CLAUDE.md
git commit -m "[PROJECT-C7]: Pay gear with gold only and balance the arena numbers"
```

## Prueba manual

Chrome (`flutter run -d chrome`) y emulador Android, en horizontal:

1. **Misiones:** partida nueva → panel *Misiones* con dos secciones, *Aldea* (*Recoge el hacha*, actual) y *Héroe* (*Construye la Herrería*, actual). El botón dice 0/11.
2. **Cadena del héroe:** construir la Herrería, ganar el primer nivel, comprar la espada corta (30 de oro, sin madera), Armería, Torre, una habilidad… cada misión se marca y avanza la actual de su línea. Al terminar la casa sale "¡Has completado las misiones de Aldea!".
3. **Panel *Héroe*:** "Ataque 3–5" con el hacha; la espada corta dice "Ataque 6–8" y "30 de oro".
4. **Arena:** los números de daño varían de un golpe a otro dentro del rango. Los niveles muestran el Poder y el oro de la decisión 7.
5. Para llegar rápido al final, un héroe de prueba **sólo en local** (sin commit), como en C6.

## Al cerrar C7

- Marca los checkboxes, actualiza `docs/boost/plans/PROGRESS.md` (C7 ✅) y la tabla del README, y apunta las desviaciones en la sección 5 del README (`/cerrar-tarea`).
- PR de `feature/PROJECT-C7-hero-quests-balance` a `feature/PROJECT-X-arena`. Con C7 la hoja de ruta de la arena queda completa: lo siguiente es el pulido de `ARENA-FIXES.md` y, después, la PR de `feature/PROJECT-X-arena` a `develop`.
