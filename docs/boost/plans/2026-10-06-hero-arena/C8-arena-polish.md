# C8 · Pulido de la arena — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | C (arena) |
| **Depende de** | C0–C7 (ya en `develop` con la #53) |
| **Issue / milestone** | sin issue: fase añadida al terminar la hoja de ruta, a partir de [`ARENA-FIXES.md`](ARENA-FIXES.md) |

**Goal:** Aplicar el pulido de `ARENA-FIXES.md` que no hizo C7: cada luchador con su aspecto y su arma, peleas en las que el atacante se acerca a golpear, el HUD del móvil alineado a la izquierda, un solo mensaje cuando se cierra una línea de misiones y los pendientes de C2/C3.

**Architecture:**
- **Arte (§1):** `build_assets.py` compone cada luchador de la arena con su arma (`ARENA_FIGHTERS` gana `weapon`): el hacha de siempre o la espada *arming* de LPC (bronce, hierro, acero) en `sources/tools/sword-*.png`. Todos los humanos tienen además frames de andar (`<luchador>-walk-{0..8}`). El héroe tiene un juego por arma (`hero`, `hero-short-sword`, `hero-iron-sword`, `hero-steel-sword`); el veterano es un `EnemyKind` nuevo (`banditVeteran`, camisa azul y espada de hierro).
- **El arma en la escena:** `FighterRenderData.weapon` (`GearId?`) lleva el arma equipada del héroe; `ArenaBloc` la lee de `GetHeroStatusUseCase` (`Gear.of(GearSlot.weapon, hero.weaponTier)`) y `ArenaSpriteNames.fighter(kind, weapon:)` elige los frames.
- **Acercarse a golpear (§3):** `ArenaRenderConstants.turnMs` pasa a 800. Las personas andan hasta su objetivo en el primer 35 % del turno (`ArenaFrames.approachReach`, frames `walk`), golpean con los frames `slash` entre el 35 % y el 65 % (el impacto sigue a mitad del turno) y vuelven después, parándose a 30 px (`approachGap`). Los animales siguen saltando como en C4.
- **HUD (§5):** por debajo de 920 px, botones y menú alineados a la izquierda, bajo la barra de recursos.
- **Mensajes (§6):** `ForestBloc._announceQuests` junta las misiones completadas en el mismo tick: un mensaje por línea que cierran o, si no, uno por misión.
- **Pendientes (§7):** `ArenaBloc._emitReplay` captura el fallo al refrescar la lista; la escena no enseña "−0"; las decisiones provisionales de C2 se dan por buenas.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`; tests con `flutter_test`, `bloc_test`, `mockito`, `flame_test`. Arte con `asset-packs/lpc/build_assets.py` (Pillow).

**Precondición: C7 y la #53 fusionadas** (`9a9248d` en `develop` y en `feature/PROJECT-X-arena`). Este plan usa exactamente estas firmas. Antes de empezar, comprueba que no han cambiado:
- `enum EnemyKind { bandit, barbarian, barbarianChief, wolf, bear }`; `ArenaLevels.all` con el veterano como `EnemyKind.bandit`;
- `ArenaSpriteNames.fighter(EnemyKind?)`, `idle`, `slash`, `attack`, `down`; `ArenaFrames.frameName`, `groundSpot`, `leapReach`, `lift`; `ArenaRenderConstants.turnMs = 600`, `leapOutShare` / `leapBackShare` / `leapGap`;
- `FighterRenderData(side, index, enemyKind, health, maxHealth, pose, swingProgress = 0, targetIndex = 0, isTargeted = false)`;
- `ArenaBloc._previewFighters`, `_replayFighter`, `_emitReplay`; `ArenaBlocMock.make(world, {navigationService, error})`, `tickFor` (pasos de 16 ms);
- `HudOverlay` con `buttonsBelowWidth = 920` y la rama estrecha alineada a la derecha; `ForestBloc._react` con el caso `QuestCompletedEventEntity`;
- `build_assets.py` con `body_sheet(animation, recolours, layers)`, `with_idle_axe`, `work_sheet`, `ARENA_FIGHTERS` como `(recolours, row, layers)`.

**Cómo probar la fase entera:**
- `flutter test` en verde: **645 tests** (639 antes; TC8.1 +3, TC8.2 +0 (cambia 2), TC8.3 +0 (cambia 2), TC8.4 +1, TC8.5 +2).
- La prueba manual de la sección *Prueba manual* en Chrome y Android.

**Cómo se ha comprobado este plan (2026-10-09):** en un worktree desechable sobre `feature/PROJECT-X-arena` (`9a9248d`):
- se descargaron las hojas con los comandos de TC8.1 (sha256 de abajo) y se aplicaron las cinco tareas en orden, con un commit por tarea; los parches de este documento son esos commits, separados en tests y código (sin los PNG ni `arena.json`, que se generan);
- `python3 build_assets.py`: sólo cambian `arena.png` (1024 × 1370, 152 frames) y `arena.json`. Se miró el atlas: el héroe con el hacha y con las tres espadas, el veterano con camisa azul y espada, los bárbaros andando;
- tras cada tarea, `flutter analyze` → `No issues found!` y `flutter test` en verde: **642**, **642**, **642**, **643** y **645**.

## Decisiones del plan

Decididas con el usuario el 2026-10-09:

1. **Veterano:** camisa azul (`VETERAN_RECOLOURS`) y espada de hierro. `EnemyKind.banditVeteran` al final del enum, con sus casos en `ArenaSpriteNames.enemy` (`bandit-veteran`), `fighterScale` (1), `leapSequence` (`null`), `Internationalize.arenaEnemy` y `es.json` ("Bandido veterano"). `ArenaLevels.banditVeteran` usa ese tipo; sus números no cambian (el test de equilibrado sigue en verde).
2. **Espadas del héroe:** la espada *arming* de LPC (ElizaWy, OGA-BY 3.0) en bronce (espada corta), hierro (de hierro) y acero (de acero). Con el hacha de leñador sigue con el hacha. `ArenaSpriteNames.heroWith(GearId?)` es un `switch` exhaustivo sobre `GearId` (las armaduras y `null` dan `hero`).
3. **Turnos de 800 ms** para que se lea el ir y volver: una pelea dura un tercio más.
4. **Decisiones provisionales de C2** (pausa con `RouteObserver`, panel de victoria sin botón, umbral ámbar ×1,25): se quedan.

Del plan:

5. **Frames de andar:** columnas 0–8 de la hoja `walk` en la fila del luchador; la animación usa 1–8 a 10 fps (`PlayerFrames.walkColumn`), como en el bosque. Para los bárbaros se bajan también las hojas `walk` de sus seis capas.
6. **Al volver el luchador anda de espaldas** (sigue mirando al enemigo): no hay frames que miren al otro lado en el atlas, y de espaldas se lee bien en 280 ms.
7. **Frame propio de "recibir el golpe" (§7): descartado.** Habría que bajar la animación `hurt` de todas las capas; el parpadeo basta.
8. **Error al refrescar la lista:** `_emitReplay` pone primero el resultado y después intenta `GetArenaUseCase`; si falla, `showErrorPopUp` y la lista se queda como estaba.
9. **"−0":** `_onHit` no hace nada si el daño es 0 (ni número ni gotas).
10. **Mensajes de misiones:** `_react` ya no anuncia misiones; `_onTicked` llama a `_announceQuests` con las del tick. Por cada línea con misiones completadas: si la línea queda completa, un solo "¡Has completado las misiones de {línea}!"; si no, un "Misión completada: …" por misión.

## Reparto

| Tarea | Qué | Depende de |
|---|---|---|
| TC8.1 Arte y armas | espadas y hojas `walk` descargadas, `build_assets.py`, atlas, `CREDITS.md`, `EnemyKind.banditVeteran`, `ArenaSpriteNames`, `FighterRenderData.weapon`, `ArenaBloc`, textos, tests | — |
| TC8.2 Acercarse a golpear | `turnMs`, `ArenaFrames` (andar, golpear, volver), tests de tiempos | TC8.1 (frames `walk`) |
| TC8.3 HUD alineado a la izquierda | `HudOverlay`, `hud_overlay_test.dart` | — |
| TC8.4 Mensajes de misiones agrupados | `ForestBloc._announceQuests`, test del BLoC | — |
| TC8.5 Pendientes | `ArenaBloc._emitReplay`, `ArenaSceneComponent._onHit`, `ArenaBlocMock`, tests, `ARENA-FIXES.md` | TC8.1, TC8.2 (mismo `arena_bloc_test.dart`) |

Todo en `feature/PROJECT-X-arena`, una tarea detrás de otra, en el orden de la tabla (decisión del usuario: sin rama de fase ni PR por ahora). Commits `[PROJECT-C8]: …`, sin atribución a IA; `CLAUDE.md` se añade en un comando aparte. Al terminar cada tarea, su fila en `docs/boost/plans/PROGRESS.md`.

**Cómo aplicar los parches:** guarda cada bloque `diff` en un fichero fuera del repo y ejecuta `git apply --check <fichero> && git apply <fichero>` desde la raíz. Si `--check` falla, para. Nunca `dart format` sobre carpetas enteras.

---

### Task TC8.1: Arte y armas

**Files:**
  - Modify: `CLAUDE.md`
  - Modify: `asset-packs/lpc/build_assets.py`
  - Modify: `asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt`
  - Modify: `lib/core/assets/i18n/internationalize.dart`
  - Modify: `lib/core/assets/i18n/translations/es.json`
  - Modify: `lib/core/assets/images/lpc/CREDITS.md`
  - Modify: `lib/core/config/constants/enum/enemy_kind.dart`
  - Modify: `lib/layers/domain/rules/arena_levels.dart`
  - Modify: `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
  - Modify: `lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart`
  - Modify: `lib/layers/presentation/features/arena/game/render/arena_frames.dart`
  - Modify: `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - Modify: `lib/layers/presentation/features/arena/models/fighter_render_data.dart`
  - Modify: `test/core/assets/i18n/internationalize_test.dart`
  - Modify: `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - Modify: `test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart`
  - Modify: `test/layers/presentation/features/arena/game/render/arena_frames_test.dart`
  - Modify: `test/layers/presentation/features/arena/widgets/level_list_test.dart`
  - Modify: `test/layers/presentation/features/arena/widgets/level_tile_test.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/fighter_render_data_mock.dart`
  - Create (descargados): `asset-packs/lpc/sources/tools/sword-{bronze,iron,steel}_{bg,fg,idle_bg,idle_fg,walk_bg,walk_fg}.png`, `asset-packs/lpc/sources/barbarians/*__walk.png`
  - Modify (generados): `lib/core/assets/images/lpc/arena.png`, `arena.json`

- [ ] **Step 1: Descargar las espadas y las hojas de andar de los bárbaros**

```bash
B=https://raw.githubusercontent.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator/58ce1aa479e4df32845a73a5d0afc221c3a893c2/spritesheets
cd asset-packs/lpc/sources/tools
for metal in bronze iron steel; do
  curl -sfL "$B/weapon/sword/arming/attack_slash/bg/$metal.png" -o "sword-${metal}_bg.png"
  curl -sfL "$B/weapon/sword/arming/attack_slash/fg/$metal.png" -o "sword-${metal}_fg.png"
  for animation in idle walk; do
    curl -sfL "$B/weapon/sword/arming/universal/bg/$animation/$metal.png" -o "sword-${metal}_${animation}_bg.png"
    curl -sfL "$B/weapon/sword/arming/universal/fg/$animation/$metal.png" -o "sword-${metal}_${animation}_fg.png"
  done
done
cd ../barbarians
for pair in "legs/shorts/shorts/male:legs_shorts_male" "torso/armour/leather/male:torso_armour_leather_male" \
  "arms/bracers/male:arms_bracers_male" "beards/beard/winter/male:beards_beard_winter_male" \
  "hat/helmet/barbarian/adult:hat_helmet_barbarian_adult" "hat/helmet/barbarian_viking/adult:hat_helmet_barbarian_viking_adult"; do
  curl -sfL "$B/${pair%%:*}/walk.png" -o "${pair##*:}__walk.png"
done
cd ../../../..
shasum -a 256 asset-packs/lpc/sources/tools/sword-*.png asset-packs/lpc/sources/barbarians/*__walk.png
```

Expected (las espadas `_bg`/`_fg` 768 × 512, `idle` 128 × 256, `walk` 576 × 256):

```
1ea13c9103e4ae24bfee07269e5a2add4d4e71d0ccbdc349045cf0057a4884d3  sword-bronze_bg.png
1a2a5d1f247a03be5a1d637ac11730c7cd016d1dcfadbdb8030aa98a40203fc5  sword-bronze_fg.png
c5036b155aa5c4df783c2a97542f8fa92e4d34dc6803bc9785c28da32c91e636  sword-bronze_idle_bg.png
4caecafd5b332ad5124666cdf631ccdb879083f36a8a429dea6f4ef5e172f5b4  sword-bronze_idle_fg.png
43f12f9479540e67a23f796d463c365dadd794ed74e0aae986c67cd12c3766ca  sword-bronze_walk_bg.png
3532b86e2f1a1c5c2b4e0a3f0499d432065cadc877191b1b8d8e5f292a39e14a  sword-bronze_walk_fg.png
a4998a9916a239f6a8e35deb211d02872115ec85fb61a352ffe63f646428628d  sword-iron_bg.png
8091dd98e7a450207967b592a81d24ac833394457ccb6aa1504bd8ed9c2f3707  sword-iron_fg.png
8bfe353daa295ef937fdd72f5a128bba5c99529a677c53e486eb64e1ff5e34dd  sword-iron_idle_bg.png
304e2e72eea780bea44d79de23f2c08376ebd1dca4987acf8d7ea0e9c343ba3d  sword-iron_idle_fg.png
a72c1b8a835f553a9fd2af59ab197584738cb4d63da97c3a19dfb39f242e5f10  sword-iron_walk_bg.png
acfa58fd2bab0257b74ed6e76b1988079ead60c538e7ca146d8ed5684aace89e  sword-iron_walk_fg.png
51ceabbb583527f2c3b310ff34d4abc0db35c9cf75a34b8c9855be0890386f22  sword-steel_bg.png
7f9dc95ee8c48284384510e191c51a02fe6325f7c9d37c2933aa0ff22d40bec2  sword-steel_fg.png
293c4871661f1cb143f3eba173c3a69c3a135cb347ad9d3526bd2382ebebcafd  sword-steel_idle_bg.png
23647973359172fb7d0dd1fb1909a7c9e575d399c58d39d69649a230549d3c74  sword-steel_idle_fg.png
71257c6808917c0d4887f446d4d2db6e82b16cc7de8a24c88986ca9bc633d589  sword-steel_walk_bg.png
d1ce1d2499af5ab8f07610881b9a4a49c88537525456991f76a3bce1841d3ac0  sword-steel_walk_fg.png
fe4028e7fb473816ec37c0ebf050a38aab282072d79fc8c2b60d026c20a29d29  arms_bracers_male__walk.png
cd3b32ffd85f5d6cb4a3c5c1d6d462cfd5b8eb33a2ca429d91735f2924b7ba1f  beards_beard_winter_male__walk.png
ff32f0b0907f9abd529996028d2d049e07d8ba7b8ef3d64bcda4ec44f3a863fd  hat_helmet_barbarian_adult__walk.png
876c125104c3e599dda149674f22a2cc52406bcd0f6da54978802e9bad8c6dd6  hat_helmet_barbarian_viking_adult__walk.png
1d72031ba3af2d0e7a41d7148556b51641ba2dedb8f12554c60cc22c3e78781a  legs_shorts_male__walk.png
160490073860adb9bc702716f5df0f8e01e2fb8f3a6a2b2aaa0343d131c7477c  torso_armour_leather_male__walk.png
```

Si un sha256 no coincide, para. No se ejecuta nada de lo descargado.

- [ ] **Step 2: Tests y mocks (rojo)**

```diff
diff --git a/test/core/assets/i18n/internationalize_test.dart b/test/core/assets/i18n/internationalize_test.dart
index 75a4810..f26c475 100644
--- a/test/core/assets/i18n/internationalize_test.dart
+++ b/test/core/assets/i18n/internationalize_test.dart
@@ -302,7 +302,7 @@ void main() {
       'Oso',
       'Manada de lobos',
     ]);
-    expect(enemies, ['Bandido', 'Bárbaro', 'Jefe bárbaro', 'Lobo', 'Oso']);
+    expect(enemies, ['Bandido', 'Bárbaro', 'Jefe bárbaro', 'Lobo', 'Oso', 'Bandido veterano']);
     expect(advice, [
       '¡Casi lo tienes! Vuelve a intentarlo.',
       'Te falta Ataque: visita la Herrería.',
diff --git a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
index 8096719..2d3d7cd 100644
--- a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
+++ b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
@@ -4,6 +4,7 @@ import 'package:mockito/mockito.dart';
 import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
 import 'package:rpg/core/config/constants/enum/arena/power_tone.dart';
 import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
+import 'package:rpg/core/config/constants/enum/gear_id.dart';
 import 'package:rpg/core/config/constants/enum/resource.dart';
 import 'package:rpg/layers/domain/rules/arena_levels.dart';
 import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
@@ -539,6 +540,24 @@ void main() {
     },
   );
 
+  blocTest<ArenaBloc, ArenaState>(
+    'testWhenTheHeroHasBoughtTheShortSwordThenItHoldsItInTheArena',
+    build: () {
+      // given
+      world = WorldMock.withHero(HeroEntityMock.withShortSword);
+      return ArenaBlocMock.make(world, navigationService: navigationService);
+    },
+    act: (bloc) {
+      // when
+      bloc.add(const ArenaStarted());
+    },
+    wait: Duration.zero,
+    verify: (bloc) {
+      // then
+      expect(bloc.state.data.fighters.first.weapon, GearId.shortSword);
+    },
+  );
+
   blocTest<ArenaBloc, ArenaState>(
     'testWhenClosedThenGoesBackToTheForest',
     build: () {
diff --git a/test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart b/test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart
index f6098dd..380022f 100644
--- a/test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart
+++ b/test/layers/presentation/features/arena/game/atlas/arena_sprite_names_test.dart
@@ -3,6 +3,7 @@ import 'dart:io';
 
 import 'package:flutter_test/flutter_test.dart';
 import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
+import 'package:rpg/core/config/constants/enum/gear_id.dart';
 import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';
 import 'package:rpg/layers/presentation/features/arena/game/render/arena_render_constants.dart';
 import 'package:rpg/layers/presentation/features/forest/game/render/render_constants.dart';
@@ -16,19 +17,45 @@ void main() {
     final names = [ArenaSpriteNames.fighter(null), for (final kind in kinds) ArenaSpriteNames.fighter(kind)];
 
     // then
-    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian-chief', 'wolf', 'bear']);
+    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian-chief', 'wolf', 'bear', 'bandit-veteran']);
     expect(ArenaSpriteNames.idle('bandit', 1), 'bandit-idle-1');
     expect(ArenaSpriteNames.slash('hero', 5), 'hero-slash-5');
   });
 
+  test('testWhenTheHeroHoldsAWeaponThenItsArtFollowsTheWeapon', () {
+    // given
+    const weapons = [GearId.woodcutterAxe, GearId.shortSword, GearId.ironSword, GearId.steelSword];
+
+    // when
+    final names = weapons.map((weapon) => ArenaSpriteNames.fighter(null, weapon: weapon)).toList();
+
+    // then
+    expect(names, ['hero', 'hero-short-sword', 'hero-iron-sword', 'hero-steel-sword']);
+    expect(ArenaSpriteNames.fighter(null), 'hero');
+    expect(ArenaSpriteNames.walk('hero', 3), 'hero-walk-3');
+  });
+
   test('testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists', () {
     // given
     final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
     final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
     const kinds = <EnemyKind?>[null, ...EnemyKind.values];
+    const heroWeapons = [GearId.shortSword, GearId.ironSword, GearId.steelSword];
 
     // when
     final wanted = [
+      for (final weapon in heroWeapons) ...[
+        for (var column = 0; column < RenderConstants.idleColumns; column++)
+          ArenaSpriteNames.idle(ArenaSpriteNames.heroWith(weapon), column),
+        for (var column = 0; column < RenderConstants.workColumns; column++)
+          ArenaSpriteNames.slash(ArenaSpriteNames.heroWith(weapon), column),
+      ],
+      for (final weapon in <GearId?>[null, ...heroWeapons])
+        for (var column = 0; column < RenderConstants.walkColumns; column++)
+          ArenaSpriteNames.walk(ArenaSpriteNames.heroWith(weapon), column),
+      for (final kind in EnemyKind.values.where((kind) => ArenaRenderConstants.leapSequence(kind) == null))
+        for (var column = 0; column < RenderConstants.walkColumns; column++)
+          ArenaSpriteNames.walk(ArenaSpriteNames.enemy(kind), column),
       ArenaSpriteNames.grass,
       ArenaSpriteNames.fence,
       for (final kind in kinds) ...[
diff --git a/test/layers/presentation/features/arena/game/render/arena_frames_test.dart b/test/layers/presentation/features/arena/game/render/arena_frames_test.dart
index 0703bda..eccaca4 100644
--- a/test/layers/presentation/features/arena/game/render/arena_frames_test.dart
+++ b/test/layers/presentation/features/arena/game/render/arena_frames_test.dart
@@ -116,4 +116,15 @@ void main() {
     // then
     expect((spot, lift), (const PositionEntity(x: 190, y: 170), 0.0));
   });
+
+  test('testWhenTheHeroHoldsASwordThenItsFramesAreTheSwordOnes', () {
+    // given
+    const hero = FighterRenderDataMock.heroWithSteelSwordIdle;
+
+    // when
+    final name = ArenaFrames.frameName(hero, 0);
+
+    // then
+    expect(name, 'hero-steel-sword-idle-0');
+  });
 }
diff --git a/test/layers/presentation/features/arena/widgets/level_list_test.dart b/test/layers/presentation/features/arena/widgets/level_list_test.dart
index eeebb36..b990046 100644
--- a/test/layers/presentation/features/arena/widgets/level_list_test.dart
+++ b/test/layers/presentation/features/arena/widgets/level_list_test.dart
@@ -19,7 +19,7 @@ void main() {
     );
 
     // when
-    await tester.tap(find.text(levels[1].name));
+    await tester.tap(find.text(levels[1].name).first);
 
     // then
     expect(selected, [ArenaLevelId.banditVeteran]);
@@ -35,7 +35,7 @@ void main() {
     );
 
     // when
-    await tester.tap(find.text(levels[1].name));
+    await tester.tap(find.text(levels[1].name).first);
 
     // then
     expect(selected, isEmpty);
diff --git a/test/layers/presentation/features/arena/widgets/level_tile_test.dart b/test/layers/presentation/features/arena/widgets/level_tile_test.dart
index 521bd9f..46dfd5e 100644
--- a/test/layers/presentation/features/arena/widgets/level_tile_test.dart
+++ b/test/layers/presentation/features/arena/widgets/level_tile_test.dart
@@ -22,7 +22,7 @@ void main() {
         child: LevelTile(level: level, isSelected: true, isEnabled: true, onTap: () => taps++),
       ),
     );
-    await tester.tap(find.text(level.name));
+    await tester.tap(find.text(level.name).first);
 
     // then
     expect(find.text(level.enemiesText), findsOneWidget);
@@ -42,7 +42,7 @@ void main() {
         child: LevelTile(level: level, isSelected: false, isEnabled: true, onTap: () => taps++),
       ),
     );
-    await tester.tap(find.text(level.name));
+    await tester.tap(find.text(level.name).first);
 
     // then
     expect(find.bySemanticsLabel(Internationalize.arenaLocked), findsOneWidget);
diff --git a/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart b/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
index e343b64..c3ad561 100644
--- a/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
@@ -29,7 +29,7 @@ abstract final class ArenaLevelItemDataMock {
   static ArenaLevelItemData get veteranLocked => ArenaLevelItemData(
     id: ArenaLevelId.banditVeteran,
     name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
-    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
+    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
     powerText: Internationalize.arenaPower(power: 41),
     tone: PowerTone.hard,
     rewardText: Internationalize.arenaReward(amount: 30),
@@ -39,7 +39,7 @@ abstract final class ArenaLevelItemDataMock {
   static ArenaLevelItemData get veteranOpen => ArenaLevelItemData(
     id: ArenaLevelId.banditVeteran,
     name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
-    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
+    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
     powerText: Internationalize.arenaPower(power: 41),
     tone: PowerTone.hard,
     rewardText: Internationalize.arenaReward(amount: 30),
diff --git a/test/mocks/presentation/features/arena/fighter_render_data_mock.dart b/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
index b178561..7bb1287 100644
--- a/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
+++ b/test/mocks/presentation/features/arena/fighter_render_data_mock.dart
@@ -1,6 +1,7 @@
 import 'package:rpg/core/config/constants/enum/arena/fighter_pose.dart';
 import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
 import 'package:rpg/core/config/constants/enum/fight_side.dart';
+import 'package:rpg/core/config/constants/enum/gear_id.dart';
 import 'package:rpg/layers/presentation/features/arena/models/fighter_render_data.dart';
 
 abstract final class FighterRenderDataMock {
@@ -11,6 +12,17 @@ abstract final class FighterRenderDataMock {
     health: 30,
     maxHealth: 30,
     pose: FighterPose.idle,
+    weapon: GearId.woodcutterAxe,
+  );
+
+  static const FighterRenderData heroWithSteelSwordIdle = FighterRenderData(
+    side: FightSide.hero,
+    index: 0,
+    enemyKind: null,
+    health: 30,
+    maxHealth: 30,
+    pose: FighterPose.idle,
+    weapon: GearId.steelSword,
   );
 
   static const FighterRenderData rookieBanditIdle = FighterRenderData(
@@ -26,7 +38,7 @@ abstract final class FighterRenderDataMock {
   static const FighterRenderData veteranBanditIdle = FighterRenderData(
     side: FightSide.enemy,
     index: 0,
-    enemyKind: EnemyKind.bandit,
+    enemyKind: EnemyKind.banditVeteran,
     health: 36,
     maxHealth: 36,
     pose: FighterPose.idle,
@@ -79,6 +91,7 @@ abstract final class FighterRenderDataMock {
     health: 22,
     maxHealth: 30,
     pose: FighterPose.idle,
+    weapon: GearId.woodcutterAxe,
   );
 
   static FighterRenderData heroSwinging(double swingProgress) => FighterRenderData(
@@ -89,6 +102,7 @@ abstract final class FighterRenderDataMock {
     maxHealth: 30,
     pose: FighterPose.attack,
     swingProgress: swingProgress,
+    weapon: GearId.woodcutterAxe,
   );
 
   static const FighterRenderData chiefIdle = FighterRenderData(
```

Run: `flutter test test/layers/presentation/features/arena`
Expected: no compila (`GearId` en `FighterRenderData`, `heroWith`, `walk`, `banditVeteran` no existen).

- [ ] **Step 3: Script, código y textos**

```diff
diff --git a/CLAUDE.md b/CLAUDE.md
index da271a1..b781466 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -70,7 +70,7 @@ Key cross-cutting conventions:
 - **Positions are feet / trunk bases**, in world units = native art pixels; the domain and Flame are both Y-down (no conversion). The same point drives collision, sprite anchoring and draw order (component `priority` = base `y`).
 - **New resource, tool or building:** a `Resource`/`ToolKind`/`BlueprintId` is the enum value (appended at the end) + its cases in `Internationalize` and `es.json`, `CustomIcons` (+ SVG in `lib/core/assets/images/icons/`), `SpriteNames` (+ atlas frame via `build_assets.py`) and, for buildings, `RenderConstants.buildingFrontOffset`; `lpc_atlas_test.dart`, `internationalize_test.dart` and `custom_icons_test.dart` fail if any piece is missing. `LpcAssetsMock` builds a frame for every `BlueprintId`, and new buildings reuse `build_cottage()` in `build_assets.py` (recoloured roof via `ROOF_RAMP`, taller with `roof_stretch`).
 - **The map is level data:** tree positions, wood, kinds and ground decoration come from the data layer; the view never picks art or places decor itself (`SpriteNames` maps kind → atlas frame).
-- **Rendering constants** (`features/forest/game/render/render_constants.dart`, art-specific so not in `core`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px); sprites drawn with `FilterQuality.none`. Arena: `arena/game/render/arena_render_constants.dart` (400 ms lead-in, 600 ms per turn, impact at half the turn; 480×270 stage framed with a cover zoom between 1 and 3; hero facing right, enemies facing left; barbarians wear their own LPC layers (leather armour, beard, helmet) and the barbarian chief has his own frames (viking helmet, black beard) drawn ×1.25; wolves and bears (`ArenaRenderConstants.leapSequence`, an exhaustive `switch` on `EnemyKind`) bite or swipe with their own `attack-*` frames while `ArenaFrames.groundSpot` / `lift` make them leap at their target (`FighterRenderData.targetIndex`) during the first 40 % of the turn, stopping 30 px short, and back after 60 %, and they lie on their own `down` frame instead of tipping over; the hero's target, the first enemy still standing, has a ring under its feet (`TargetRingComponent`, `FighterRenderData.isTargeted`), and fallen fighters are drawn at half alpha).
+- **Rendering constants** (`features/forest/game/render/render_constants.dart`, art-specific so not in `core`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px); sprites drawn with `FilterQuality.none`. Arena: `arena/game/render/arena_render_constants.dart` (400 ms lead-in, 600 ms per turn, impact at half the turn; 480×270 stage framed with a cover zoom between 1 and 3; hero facing right, enemies facing left; people have idle, walk and slash frames and hold their weapon: the hero the axe or the LPC arming sword of its equipped weapon (`FighterRenderData.weapon`, `ArenaSpriteNames.heroWith`: bronze short sword, iron, steel), the veteran bandit (`EnemyKind.banditVeteran`, blue shirt) an iron sword; barbarians wear their own LPC layers (leather armour, beard, helmet) and the barbarian chief has his own frames (viking helmet, black beard) drawn ×1.25; wolves and bears (`ArenaRenderConstants.leapSequence`, an exhaustive `switch` on `EnemyKind`) bite or swipe with their own `attack-*` frames while `ArenaFrames.groundSpot` / `lift` make them leap at their target (`FighterRenderData.targetIndex`) during the first 40 % of the turn, stopping 30 px short, and back after 60 %, and they lie on their own `down` frame instead of tipping over; the hero's target, the first enemy still standing, has a ring under its feet (`TargetRingComponent`, `FighterRenderData.isTargeted`), and fallen fighters are drawn at half alpha).
 - **New enemy kind:** the `EnemyKind` value (appended at the end) + its cases in `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale` and `leapSequence`, `Internationalize.arenaEnemy` and `es.json`, and its frames in `arena.png` (`build_assets.py`, credited in `CREDITS.md`); `arena_sprite_names_test.dart` and `internationalize_test.dart` fail if any piece is missing.
 - `GameWidget(autofocus: false)` is deliberate: with autofocus Flame swallows every key and Esc never reaches the page's `CallbackShortcuts`.
 - Tree taps/clicks are pixel-accurate (texture alpha), so shadows and gaps between leaves fall through to movement. On the web, right click or Esc cancels placement; touch screens get the placement bar.
diff --git a/asset-packs/lpc/build_assets.py b/asset-packs/lpc/build_assets.py
index 52dcd2d..27018fd 100644
--- a/asset-packs/lpc/build_assets.py
+++ b/asset-packs/lpc/build_assets.py
@@ -12,8 +12,9 @@ Outputs (into lib/core/assets/images/lpc/, the one copy the Flutter app reads on
                                    axe pickup, the house, the forge, the armory and the mage tower
                                    (pivot = bottom centre)
   ground.png                       grass tile(s) for the tilemap (32x32 each, in a row)
-  arena.png + arena.json           JSON-hash atlas for the arena: hero, bandit, barbarian and barbarian chief idle
-                                   (64px, axe in hand) and slash (128px) frames in their one facing (pivot = feet), the wolf
+  arena.png + arena.json           JSON-hash atlas for the arena: the hero (with the axe and each sword), bandit,
+                                   veteran bandit, barbarian and barbarian chief idle and walk (64px, weapon in hand) and
+                                   slash (128px) frames in their one facing (pivot = feet), the wolf
                                    and bear idle, attack and down frames facing left, the grass cell and a fence
                                    segment
 
@@ -107,6 +108,22 @@ def work_sheet(slash: Image.Image, tool_name: str) -> Image.Image:
     return sheet
 
 
+def with_weapon(body: Image.Image, weapon: str, animation: str) -> Image.Image:
+    """The body between a sword's back and front layers (sources/tools/<weapon>_<animation>_{bg,fg}.png)."""
+    sheet = tool(f"{weapon}_{animation}_bg")
+    sheet.alpha_composite(body)
+    sheet.alpha_composite(tool(f"{weapon}_{animation}_fg"))
+    return sheet
+
+
+def armed_sheets(recolours: dict, layers: list, weapon: str) -> tuple:
+    """Idle, walk and slash sheets of a fighter holding the axe or one of the swords."""
+    idle, walk, slash = (body_sheet(animation, recolours, layers) for animation in ("idle", "walk", "slash"))
+    if weapon == "axe":
+        return with_idle_axe(idle), Image.alpha_composite(walk, tool("axe_walk")), work_sheet(slash, "axe")
+    return with_weapon(idle, weapon, "idle"), with_weapon(walk, weapon, "walk"), work_sheet(slash, weapon)
+
+
 def build_character() -> None:
     walk, idle, slash = body_sheet("walk"), body_sheet("idle"), body_sheet("slash")
     walk.save(OUT / "hero-walk.png")
@@ -330,6 +347,10 @@ BANDIT_RECOLOURS = {
     "legs_pants_male": (CLOTH_RAMP, [(28, 22, 24), (44, 34, 36), (62, 48, 48), (82, 64, 62), (104, 82, 78)]),
     "hair_plain_adult": (HAIR_RAMP, [(20, 16, 16), (32, 26, 24), (46, 38, 34), (60, 50, 44), (76, 64, 56)]),
 }
+VETERAN_RECOLOURS = {
+    **BANDIT_RECOLOURS,
+    "torso_clothes_longsleeve_longsleeve_male": (CLOTH_RAMP, [(18, 26, 52), (28, 42, 82), (40, 60, 112), (56, 82, 140), (76, 106, 168)]),
+}
 BARBARIAN_SKIN = [(78, 38, 30), (120, 72, 50), (146, 96, 66), (172, 122, 88), (196, 156, 126)]
 # Barbarians: leather armour, shorts, bracers, a long beard and a helmet instead of hair (sources/barbarians). The
 # chief swaps the helmet for the viking one and wears a black beard and red shorts; the arena draws him x1.25.
@@ -355,12 +376,17 @@ CHIEF_RECOLOURS = {
     "legs_shorts_male": (CLOTH_RAMP, [(48, 14, 16), (82, 22, 24), (112, 32, 30), (140, 46, 40), (168, 64, 54)]),
     "beards_beard_winter_male": (HAIR_RAMP, [(20, 16, 16), (32, 26, 24), (46, 38, 34), (60, 50, 44), (76, 64, 56)]),
 }
-# Fighter -> (recolours, LPC row, layers): the hero faces right (row 3), the enemies face left (row 1).
+# Fighter -> (recolours, LPC row, layers, weapon): the hero faces right (row 3), the enemies face left (row 1). The
+# weapon is the axe or a sword sheet in sources/tools (the LPC arming sword in bronze, iron or steel).
 ARENA_FIGHTERS = {
-    "hero": (RECOLOURS, 3, CHARACTER_LAYERS),
-    "bandit": (BANDIT_RECOLOURS, 1, CHARACTER_LAYERS),
-    "barbarian": (BARBARIAN_RECOLOURS, 1, BARBARIAN_LAYERS),
-    "barbarian-chief": (CHIEF_RECOLOURS, 1, CHIEF_LAYERS),
+    "hero": (RECOLOURS, 3, CHARACTER_LAYERS, "axe"),
+    "hero-short-sword": (RECOLOURS, 3, CHARACTER_LAYERS, "sword-bronze"),
+    "hero-iron-sword": (RECOLOURS, 3, CHARACTER_LAYERS, "sword-iron"),
+    "hero-steel-sword": (RECOLOURS, 3, CHARACTER_LAYERS, "sword-steel"),
+    "bandit": (BANDIT_RECOLOURS, 1, CHARACTER_LAYERS, "axe"),
+    "bandit-veteran": (VETERAN_RECOLOURS, 1, CHARACTER_LAYERS, "sword-iron"),
+    "barbarian": (BARBARIAN_RECOLOURS, 1, BARBARIAN_LAYERS, "axe"),
+    "barbarian-chief": (CHIEF_RECOLOURS, 1, CHIEF_LAYERS, "axe"),
 }
 ARENA_GRASS = (1, 23)  # (column, row) of terrain_atlas.png, the same grass as the forest ground
 ARENA_FENCE_BOX = (480, 608, 544, 640)  # terrain_atlas.png: a post and a rail, 64x32, tiles horizontally
@@ -404,11 +430,12 @@ def add_beasts(frames: dict, pivots: dict) -> None:
 def build_arena() -> None:
     terrain = Image.open(SOURCES / "terrain" / "terrain_atlas.png").convert("RGBA")
     frames, pivots = {}, {}
-    for fighter, (recolours, row, layers) in ARENA_FIGHTERS.items():
-        idle = with_idle_axe(body_sheet("idle", recolours, layers))
-        slash = work_sheet(body_sheet("slash", recolours, layers), "axe")
+    for fighter, (recolours, row, layers, weapon) in ARENA_FIGHTERS.items():
+        idle, walk, slash = armed_sheets(recolours, layers, weapon)
         for column, image in enumerate(cells(idle, row, FRAME)):
             frames[f"{fighter}-idle-{column}"], pivots[f"{fighter}-idle-{column}"] = image, IDLE_PIVOT
+        for column, image in enumerate(cells(walk, row, FRAME)):
+            frames[f"{fighter}-walk-{column}"], pivots[f"{fighter}-walk-{column}"] = image, IDLE_PIVOT
         for column, image in enumerate(cells(slash, row, WORK_FRAME)):
             frames[f"{fighter}-slash-{column}"], pivots[f"{fighter}-slash-{column}"] = image, SLASH_PIVOT
     add_beasts(frames, pivots)
diff --git a/asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt b/asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt
index 6f8058c..efed9c1 100644
--- a/asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt
+++ b/asset-packs/lpc/sources/barbarians/CREDITS-barbarians.txt
@@ -3,7 +3,7 @@ Arena barbarians (used by build_assets.py -> arena.png)
 
 Layers of the Universal LPC Spritesheet Character Generator, commit 58ce1aa479e4df32845a73a5d0afc221c3a893c2:
 https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator
-Each file is spritesheets/<path>/{idle,slash}.png, renamed to <name>__{idle,slash}.png.
+Each file is spritesheets/<path>/{idle,walk,slash}.png, renamed to <name>__{idle,walk,slash}.png.
 
 legs_shorts_male            <- legs/shorts/shorts/male
   JaidynReiman, ElizaWy, bluecarrot16, Johannes Sjölund (wulax), Stephen Challener (Redshrike)
diff --git a/lib/core/assets/i18n/internationalize.dart b/lib/core/assets/i18n/internationalize.dart
index e2c6ded..cff460a 100644
--- a/lib/core/assets/i18n/internationalize.dart
+++ b/lib/core/assets/i18n/internationalize.dart
@@ -191,6 +191,7 @@ class Internationalize {
     EnemyKind.barbarianChief => '$_arena.enemy.barbarianChief'.tr(),
     EnemyKind.wolf => '$_arena.enemy.wolf'.tr(),
     EnemyKind.bear => '$_arena.enemy.bear'.tr(),
+    EnemyKind.banditVeteran => '$_arena.enemy.banditVeteran'.tr(),
   };
   static String arenaAdvice({required FightAdvice advice}) => switch (advice) {
     FightAdvice.almostThere => '$_arena.advice.almostThere'.tr(),
diff --git a/lib/core/assets/i18n/translations/es.json b/lib/core/assets/i18n/translations/es.json
index 0d02925..5d63687 100644
--- a/lib/core/assets/i18n/translations/es.json
+++ b/lib/core/assets/i18n/translations/es.json
@@ -173,7 +173,8 @@
       "barbarian": "Bárbaro",
       "barbarianChief": "Jefe bárbaro",
       "wolf": "Lobo",
-      "bear": "Oso"
+      "bear": "Oso",
+      "banditVeteran": "Bandido veterano"
     },
     "advice": {
       "almostThere": "¡Casi lo tienes! Vuelve a intentarlo.",
diff --git a/lib/core/assets/images/lpc/CREDITS.md b/lib/core/assets/images/lpc/CREDITS.md
index 3e74028..fe82669 100644
--- a/lib/core/assets/images/lpc/CREDITS.md
+++ b/lib/core/assets/images/lpc/CREDITS.md
@@ -59,9 +59,20 @@ The stump (`stump` frame) comes from the LPC Tile Atlas above.
 ## Arena (`arena.png`)
 
 Fighters composed by `build_assets.py` from the same character layers and axe as `hero-*.png`
-(see *Character* above), each kept in one facing. The bandit is a recolour of those layers
-(clothes and hair). Same authors and licences as the character layers. The barbarian and the
-barbarian chief add their own layers (see *Barbarians* below).
+(see *Character* above), each kept in one facing, standing, walking and striking. The bandit and
+the veteran bandit are recolours of those layers (clothes and hair). Same authors and licences as
+the character layers. The barbarian and the barbarian chief add their own layers (see
+*Barbarians* below); the hero's swords and the veteran's sword are the arming sword (see *Swords*
+below).
+
+### Swords (`hero-short-sword-*`, `hero-iron-sword-*`, `hero-steel-sword-*`, `bandit-veteran-*`)
+
+"Arming Sword" of the [Universal LPC Spritesheet Character Generator](https://github.com/liberatedpixelcup/Universal-LPC-Spritesheet-Character-Generator)
+(commit 58ce1aa), in its bronze (short sword), iron (iron sword and the veteran bandit) and steel
+(steel sword) variants: `asset-packs/lpc/sources/tools/sword-*.png`. By ElizaWy; walk by
+JaidynReiman. OGA-BY 3.0 —
+<https://github.com/ElizaWy/LPC/tree/main/Characters/Props/Sword%2001%20-%20Arming%20Sword>,
+<https://opengameart.org/content/lpc-expanded-sit-run-jump-more>.
 
 The grass (`arena-grass`) and the fence (`arena-fence`) come from the LPC Tile Atlas (see
 *Ground and decor* above). CC-BY-SA 3.0 / GPL 3.0.
diff --git a/lib/core/config/constants/enum/enemy_kind.dart b/lib/core/config/constants/enum/enemy_kind.dart
index 1d71ba2..f2e47fb 100644
--- a/lib/core/config/constants/enum/enemy_kind.dart
+++ b/lib/core/config/constants/enum/enemy_kind.dart
@@ -1 +1 @@
-enum EnemyKind { bandit, barbarian, barbarianChief, wolf, bear }
+enum EnemyKind { bandit, barbarian, barbarianChief, wolf, bear, banditVeteran }
diff --git a/lib/layers/domain/rules/arena_levels.dart b/lib/layers/domain/rules/arena_levels.dart
index 495ebe4..93ce2c9 100644
--- a/lib/layers/domain/rules/arena_levels.dart
+++ b/lib/layers/domain/rules/arena_levels.dart
@@ -30,7 +30,7 @@ abstract final class ArenaLevels {
       id: ArenaLevelId.banditVeteran,
       enemies: [
         EnemyEntity(
-          kind: EnemyKind.bandit,
+          kind: EnemyKind.banditVeteran,
           stats: CombatStatsEntity(attackMin: 4, attackMax: 6, defense: 2, health: 36),
         ),
       ],
diff --git a/lib/layers/presentation/features/arena/bloc/arena_bloc.dart b/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
index 021d871..3d82b86 100644
--- a/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
+++ b/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
@@ -11,6 +11,8 @@ import '../../../../../core/config/constants/enum/enemy_kind.dart';
 import '../../../../../core/config/constants/enum/fight_action.dart';
 import '../../../../../core/config/constants/enum/fight_advice.dart';
 import '../../../../../core/config/constants/enum/fight_side.dart';
+import '../../../../../core/config/constants/enum/gear_id.dart';
+import '../../../../../core/config/constants/enum/gear_slot.dart';
 import '../../../../../core/config/constants/enum/resource.dart';
 import '../../../../../core/config/constants/enum/skill_id.dart';
 import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
@@ -22,6 +24,7 @@ import '../../../../domain/entities/combat/arena_level_status_entity.dart';
 import '../../../../domain/entities/combat/fight_result_entity.dart';
 import '../../../../domain/use-cases/arena/get_arena_use_case.dart';
 import '../../../../domain/use-cases/arena/start_fight_use_case.dart';
+import '../../../../domain/rules/gear.dart';
 import '../../../../domain/use-cases/hero/get_hero_status_use_case.dart';
 import '../game/render/arena_render_constants.dart';
 import '../models/arena_effect.dart';
@@ -44,6 +47,7 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
   ArenaEntity? _arena;
   FightAdvice? _advice;
   bool _isFirstChampionship = false;
+  GearId _heroWeapon = GearId.woodcutterAxe;
 
   ArenaBloc({
     required this._getArenaUseCase,
@@ -266,7 +270,9 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
   }
 
   List<FighterRenderData> _previewFighters(ArenaEntity arena, ArenaLevelId? selected) {
-    final heroHealth = _getHeroStatusUseCase().stats.health;
+    final status = _getHeroStatusUseCase();
+    final heroHealth = status.stats.health;
+    _heroWeapon = Gear.of(GearSlot.weapon, status.hero.weaponTier).id;
     final level = arena.levels.firstWhereOrNull((status) => status.level.id == selected)?.level;
     return [
       FighterRenderData(
@@ -276,6 +282,7 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
         health: heroHealth,
         maxHealth: heroHealth,
         pose: FighterPose.idle,
+        weapon: _heroWeapon,
       ),
       if (level != null)
         for (final (index, enemy) in level.enemies.indexed)
@@ -339,6 +346,7 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
       swingProgress: pose == FighterPose.attack ? progress : 0,
       targetIndex: pose == FighterPose.attack ? turn?.targetIndex ?? 0 : 0,
       isTargeted: isTargeted,
+      weapon: side == FightSide.hero ? _heroWeapon : null,
     );
   }
 }
diff --git a/lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart b/lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart
index f098cb6..4795dee 100644
--- a/lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart
+++ b/lib/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart
@@ -1,4 +1,5 @@
 import '../../../../../../core/config/constants/enum/enemy_kind.dart';
+import '../../../../../../core/config/constants/enum/gear_id.dart';
 
 abstract final class ArenaSpriteNames {
   static const String hero = 'hero';
@@ -11,12 +12,27 @@ abstract final class ArenaSpriteNames {
     EnemyKind.barbarianChief => 'barbarian-chief',
     EnemyKind.wolf => 'wolf',
     EnemyKind.bear => 'bear',
+    EnemyKind.banditVeteran => 'bandit-veteran',
   };
 
-  static String fighter(EnemyKind? kind) => kind == null ? hero : enemy(kind);
+  static String heroWith(GearId? weapon) => switch (weapon) {
+    GearId.shortSword => 'hero-short-sword',
+    GearId.ironSword => 'hero-iron-sword',
+    GearId.steelSword => 'hero-steel-sword',
+    null ||
+    GearId.woodcutterAxe ||
+    GearId.workClothes ||
+    GearId.leatherArmor ||
+    GearId.chainMail ||
+    GearId.plateArmor => hero,
+  };
+
+  static String fighter(EnemyKind? kind, {GearId? weapon}) => kind == null ? heroWith(weapon) : enemy(kind);
 
   static String idle(String fighter, int column) => '$fighter-idle-$column';
 
+  static String walk(String fighter, int column) => '$fighter-walk-$column';
+
   static String slash(String fighter, int column) => '$fighter-slash-$column';
 
   static String attack(String fighter, int column) => '$fighter-attack-$column';
diff --git a/lib/layers/presentation/features/arena/game/render/arena_frames.dart b/lib/layers/presentation/features/arena/game/render/arena_frames.dart
index 6edb094..95a0020 100644
--- a/lib/layers/presentation/features/arena/game/render/arena_frames.dart
+++ b/lib/layers/presentation/features/arena/game/render/arena_frames.dart
@@ -13,7 +13,7 @@ import 'arena_render_constants.dart';
 
 abstract final class ArenaFrames {
   static String frameName(FighterRenderData fighter, double animationSeconds) {
-    final name = ArenaSpriteNames.fighter(fighter.enemyKind);
+    final name = ArenaSpriteNames.fighter(fighter.enemyKind, weapon: fighter.weapon);
     final leap = ArenaRenderConstants.leapSequence(fighter.enemyKind);
     return switch (fighter.pose) {
       FighterPose.attack when leap != null => ArenaSpriteNames.attack(
diff --git a/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart b/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart
index 6475ca0..29eb036 100644
--- a/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart
+++ b/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart
@@ -22,7 +22,7 @@ abstract final class ArenaRenderConstants {
   static const double chiefScale = 1.25;
 
   static double fighterScale(EnemyKind? kind) => switch (kind) {
-    null || EnemyKind.bandit || EnemyKind.barbarian => 1,
+    null || EnemyKind.bandit || EnemyKind.banditVeteran || EnemyKind.barbarian => 1,
     EnemyKind.barbarianChief => chiefScale,
     EnemyKind.wolf || EnemyKind.bear => 1,
   };
@@ -31,7 +31,7 @@ abstract final class ArenaRenderConstants {
   static const List<int> bearSwipeSequence = [0, 1, 1, 2, 2, 2, 1, 0];
 
   static List<int>? leapSequence(EnemyKind? kind) => switch (kind) {
-    null || EnemyKind.bandit || EnemyKind.barbarian || EnemyKind.barbarianChief => null,
+    null || EnemyKind.bandit || EnemyKind.banditVeteran || EnemyKind.barbarian || EnemyKind.barbarianChief => null,
     EnemyKind.wolf => wolfBiteSequence,
     EnemyKind.bear => bearSwipeSequence,
   };
diff --git a/lib/layers/presentation/features/arena/models/fighter_render_data.dart b/lib/layers/presentation/features/arena/models/fighter_render_data.dart
index 1ceb034..0823697 100644
--- a/lib/layers/presentation/features/arena/models/fighter_render_data.dart
+++ b/lib/layers/presentation/features/arena/models/fighter_render_data.dart
@@ -1,6 +1,7 @@
 import '../../../../../core/config/constants/enum/arena/fighter_pose.dart';
 import '../../../../../core/config/constants/enum/enemy_kind.dart';
 import '../../../../../core/config/constants/enum/fight_side.dart';
+import '../../../../../core/config/constants/enum/gear_id.dart';
 
 class FighterRenderData {
   final FightSide side;
@@ -12,6 +13,7 @@ class FighterRenderData {
   final double swingProgress;
   final int targetIndex;
   final bool isTargeted;
+  final GearId? weapon;
 
   const FighterRenderData({
     required this.side,
@@ -23,6 +25,7 @@ class FighterRenderData {
     this.swingProgress = 0,
     this.targetIndex = 0,
     this.isTargeted = false,
+    this.weapon,
   });
 
   static String keyOf(FightSide side, int index) => '${side.name}-$index';
@@ -41,9 +44,10 @@ class FighterRenderData {
           other.pose == pose &&
           other.swingProgress == swingProgress &&
           other.targetIndex == targetIndex &&
-          other.isTargeted == isTargeted;
+          other.isTargeted == isTargeted &&
+          other.weapon == weapon;
 
   @override
   int get hashCode =>
-      Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress, targetIndex, isTargeted);
+      Object.hash(side, index, enemyKind, health, maxHealth, pose, swingProgress, targetIndex, isTargeted, weapon);
 }
```

- [ ] **Step 4: Generar el atlas (verde)**

```bash
cd asset-packs/lpc && python3 build_assets.py && cd ../.. && git status --short
flutter test
```

Expected: sólo cambian `arena.png` (1024 × 1370) y `arena.json` además de lo anterior; **642 tests** en verde. Abre `arena.png` y comprueba el héroe con el hacha y las tres espadas, el veterano (camisa azul, espada) y los bárbaros andando.

- [ ] **Step 5: Verificación y commit**

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart '*.mocks.dart'
flutter analyze
git add asset-packs lib test
git add CLAUDE.md
git commit -m "[PROJECT-C8]: Arm the arena fighters and give the veteran his own look"
```

---

### Task TC8.2: Acercarse a golpear

**Files:**
  - Modify: `CLAUDE.md`
  - Modify: `lib/layers/presentation/features/arena/game/render/arena_frames.dart`
  - Modify: `lib/layers/presentation/features/arena/game/render/arena_render_constants.dart`
  - Modify: `test/layers/presentation/features/arena/arena_page_test.dart`
  - Modify: `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - Modify: `test/layers/presentation/features/arena/game/render/arena_frames_test.dart`
  - Modify: `test/layers/presentation/features/arena/models/fight_replay_data_test.dart`

- [ ] **Step 1: Tests (rojo)**

```diff
diff --git a/test/layers/presentation/features/arena/arena_page_test.dart b/test/layers/presentation/features/arena/arena_page_test.dart
index 4aceeef..d3b5c17 100644
--- a/test/layers/presentation/features/arena/arena_page_test.dart
+++ b/test/layers/presentation/features/arena/arena_page_test.dart
@@ -90,7 +90,7 @@ void main() {
 
     // when
     await tester.tap(find.text(Internationalize.arenaFight));
-    for (var frame = 0; frame < 70 && find.byType(ResultPanel).evaluate().isEmpty; frame++) {
+    for (var frame = 0; frame < 90 && find.byType(ResultPanel).evaluate().isEmpty; frame++) {
       await tester.pump(const Duration(milliseconds: 100));
     }
 
diff --git a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
index 2d3d7cd..956f99d 100644
--- a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
+++ b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
@@ -211,14 +211,14 @@ void main() {
       bloc
         ..add(const ArenaStarted())
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 720);
+      ArenaBlocMock.tickFor(bloc, 880);
     },
     wait: Duration.zero,
     verify: (bloc) {
       // then
       final fighters = bloc.state.data.fighters;
       expect(fighters[0].pose, FighterPose.attack);
-      expect(fighters[0].swingProgress, closeTo(320 / 600, 1e-9));
+      expect(fighters[0].swingProgress, closeTo(480 / 800, 1e-9));
       expect(fighters[1], FighterRenderDataMock.rookieBanditAfterFirstBlow);
       expect(effects, [ArenaEffectMock.banditHitForThree]);
     },
@@ -236,13 +236,13 @@ void main() {
       bloc
         ..add(const ArenaStarted())
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 1248);
+      ArenaBlocMock.tickFor(bloc, 1536);
     },
     wait: Duration.zero,
     verify: (bloc) {
       // then
       expect(bloc.state.data.selected, ArenaLevelId.wolf);
-      expect(bloc.state.data.fighters[1], FighterRenderDataMock.wolfLeaping(248 / 600));
+      expect(bloc.state.data.fighters[1], FighterRenderDataMock.wolfLeaping(336 / 800));
     },
   );
 
@@ -259,7 +259,7 @@ void main() {
         ..add(const ArenaStarted())
         ..add(const ArenaLevelSelected(levelId: ArenaLevelId.wolfPack))
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 4848);
+      ArenaBlocMock.tickFor(bloc, 6336);
     },
     wait: Duration.zero,
     verify: (bloc) {
@@ -282,7 +282,7 @@ void main() {
         ..add(const ArenaStarted())
         ..add(const ArenaLevelSelected(levelId: ArenaLevelId.wolfPack))
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 4848);
+      ArenaBlocMock.tickFor(bloc, 6336);
     },
     wait: Duration.zero,
     verify: (bloc) {
@@ -304,7 +304,7 @@ void main() {
       bloc
         ..add(const ArenaStarted())
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 6000);
+      ArenaBlocMock.tickFor(bloc, 8000);
     },
     wait: Duration.zero,
     verify: (bloc) {
@@ -479,7 +479,7 @@ void main() {
       bloc
         ..add(const ArenaStarted())
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 7000);
+      ArenaBlocMock.tickFor(bloc, 9400);
     },
     wait: Duration.zero,
     verify: (bloc) {
@@ -501,7 +501,7 @@ void main() {
       bloc
         ..add(const ArenaStarted())
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 7000);
+      ArenaBlocMock.tickFor(bloc, 9400);
     },
     wait: Duration.zero,
     verify: (bloc) {
@@ -529,7 +529,7 @@ void main() {
         ..add(const ArenaStarted())
         ..add(const ArenaLevelSelected(levelId: ArenaLevelId.banditVeteran))
         ..add(const ArenaFightRequested());
-      ArenaBlocMock.tickFor(bloc, 15000);
+      ArenaBlocMock.tickFor(bloc, 19000);
     },
     wait: Duration.zero,
     verify: (bloc) {
diff --git a/test/layers/presentation/features/arena/game/render/arena_frames_test.dart b/test/layers/presentation/features/arena/game/render/arena_frames_test.dart
index eccaca4..6ee42af 100644
--- a/test/layers/presentation/features/arena/game/render/arena_frames_test.dart
+++ b/test/layers/presentation/features/arena/game/render/arena_frames_test.dart
@@ -10,18 +10,17 @@ import 'package:rpg/layers/presentation/features/arena/game/render/arena_render_
 import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';
 
 void main() {
-  test('testWhenAFighterSwingsThenTheSlashFrameFollowsTheChopSequence', () {
+  test('testWhenAPersonAttacksThenItWalksStrikesWithTheChopSequenceAndWalksBack', () {
     // given
-    final start = FighterRenderDataMock.heroSwinging(0);
-    final impact = FighterRenderDataMock.heroSwinging(0.5);
+    final progresses = [0.1, 0.35, 0.5, 0.9];
 
     // when
-    final startName = ArenaFrames.frameName(start, 0);
-    final impactName = ArenaFrames.frameName(impact, 0);
+    final names = [
+      for (final progress in progresses) ArenaFrames.frameName(FighterRenderDataMock.heroSwinging(progress), 0),
+    ];
 
     // then
-    expect(startName, 'hero-slash-0');
-    expect(impactName, 'hero-slash-4');
+    expect(names, ['hero-walk-1', 'hero-slash-0', 'hero-slash-4', 'hero-walk-1']);
   });
 
   test('testWhenAFighterIsIdleHurtOrDownThenTheIdleFramesAreUsed', () {
@@ -105,16 +104,22 @@ void main() {
     expect(lifts[3], closeTo(ArenaRenderConstants.leapHeight, 1e-9));
   });
 
-  test('testWhenAPersonSwingsThenItStaysOnItsSpot', () {
+  test('testWhenAPersonAttacksThenItWalksUpToItsTargetStopsShortAndWalksBackWithoutJumping', () {
     // given
-    final swinging = FighterRenderDataMock.heroSwinging(0.3);
+    final progresses = [0.0, 0.5, 0.999];
 
     // when
-    final spot = ArenaFrames.groundSpot(swinging);
-    final lift = ArenaFrames.lift(swinging);
+    final spots = [
+      for (final progress in progresses) ArenaFrames.groundSpot(FighterRenderDataMock.heroSwinging(progress)),
+    ];
+    final lift = ArenaFrames.lift(FighterRenderDataMock.heroSwinging(0.2));
 
     // then
-    expect((spot, lift), (const PositionEntity(x: 190, y: 170), 0.0));
+    expect(spots.map((spot) => spot.y), everyElement(170));
+    expect(spots[0].x, 190);
+    expect(spots[1].x, 300 - ArenaRenderConstants.approachGap);
+    expect(spots[2].x, closeTo(190, 0.01));
+    expect(lift, 0);
   });
 
   test('testWhenTheHeroHoldsASwordThenItsFramesAreTheSwordOnes', () {
diff --git a/test/layers/presentation/features/arena/models/fight_replay_data_test.dart b/test/layers/presentation/features/arena/models/fight_replay_data_test.dart
index de56a87..ce671ca 100644
--- a/test/layers/presentation/features/arena/models/fight_replay_data_test.dart
+++ b/test/layers/presentation/features/arena/models/fight_replay_data_test.dart
@@ -11,7 +11,7 @@ void main() {
 
     // then
     expect((replay.turnIndex, replay.swingingTurn, replay.isFinished), (-1, null, false));
-    expect(replay.durationMs, 400 + 9 * 600);
+    expect(replay.durationMs, 400 + 9 * 800);
     expect(replay.healthOf(FightSide.hero, 0), 30);
     expect(replay.healthOf(FightSide.enemy, 0), 20);
   });
@@ -21,8 +21,8 @@ void main() {
     final replay = FightReplayDataMock.victoryOverBanditStart();
 
     // when
-    final halfway = replay.advanced(699);
-    final landed = replay.advanced(700);
+    final halfway = replay.advanced(799);
+    final landed = replay.advanced(800);
 
     // then
     expect((halfway.turnIndex, halfway.swingingTurn), (-1, 0));
@@ -39,7 +39,7 @@ void main() {
     final ended = replay.advanced(100000);
 
     // then
-    expect((ended.elapsedMs, ended.turnIndex, ended.swingingTurn, ended.isFinished), (5800, 8, null, true));
+    expect((ended.elapsedMs, ended.turnIndex, ended.swingingTurn, ended.isFinished), (7600, 8, null, true));
     expect(ended.healthOf(FightSide.hero, 0), 22);
     expect(ended.healthOf(FightSide.enemy, 0), 0);
   });
@@ -60,7 +60,7 @@ void main() {
     final replay = FightReplayDataMock.allActionsStart();
 
     // when
-    final afterHeal = replay.advanced(400 + 4 * 600 + 300);
+    final afterHeal = replay.advanced(400 + 4 * 800 + 400);
 
     // then
     expect(afterHeal.turnIndex, 4);
```

Run: `flutter test test/layers/presentation/features/arena`
Expected: FAIL (los tiempos son de turnos de 600 ms y las personas no se mueven).

- [ ] **Step 2: Código (verde)**

```diff
diff --git a/CLAUDE.md b/CLAUDE.md
index b781466..617a948 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -46,7 +46,7 @@ Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DO
   - `features/forest/models/` — view models (`PlayerRenderData`, sealed `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `ResourceItemData`, `ToolItemData`, `PlacementData`, `HeroPanelData`, `GearRowData`, `GearItemData`, `SkillItemData`) and sealed `ForestEffect` (with `GearPurchasedEffect`, `SkillLearnedEffect`) (played once per emitted state).
   - `features/forest/game/` — Flame (`package:flame` / `flame_bloc` may only be imported by `features/forest/game/`, `features/arena/game/`, `forest_page.dart` and `arena_page.dart`; rule in `architecture_test.dart`): `ForestGame` (`update` caps `dt` at 100 ms once and uses that value for `ForestTicked` and for every component, so animations never run ahead of the simulation) + `ForestWorld` + `ForestSceneComponent` + `ForestStateListener` (reconciles components with `ForestData.world` by id; plays effects), `components/` (ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player, `FloatingTextComponent` shared with the arena, same API as F1's plan), `atlas/` (`LpcAtlas` for `forest.json`, `AlphaMask`, `LpcAssets` + loader, `SpriteNames`), `render/` (`RenderConstants`, depth, position conversion, easing, tree motion, player frames, `CameraFraming` working with `Offset`/`Size`, not Flame vectors), `particles/` (chips, dust, the gear-purchase sparkles, the same sparkles in blue when a skill is learned (`ParticleKind.magicSparkle`), blood drops: `ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`, and the champion confetti, `ParticleBursts.confetti`, gold and blue sparkles that fall).
   - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` (one section per `QuestLine`) + `QuestRow`, `PlacementBar` (touch), `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`, `HudPanel`, `HudButton` (takes an optional SVG `icon`); `HudOverlay` has four buttons, *Misiones*, *Construir*, *Héroe* and *Arena* (Arena closes any open menu, the hero panel included), on the `ResourceBar` line from `HudOverlay.buttonsBelowWidth` (920 px) and right-aligned under it below that, with the open menu always under the buttons; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_ForestViewState` is `RouteAware` on the `RouteObserver` that `ForestPage` receives through its constructor from `ContainerAppBloc`, which reads it from `NavigationService`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops; `_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
-  - `features/arena/` — the arena screen, same shape as `forest/`: `ArenaBloc` (events `ArenaStarted`, `ArenaLevelSelected`, `ArenaFightRequested`, `ArenaReplayTicked`, `ArenaReplaySkipped`, `ArenaClosed`; `ArenaData` with the level list, the selection, `FightReplayData`, `FighterRenderData`s, `ArenaResultData` and sealed `ArenaEffect`s; a double strike or a second wind adds a `SkillUsedEffect` after its own effect, and the scene floats the skill name (`Internationalize.arenaSkillUsed`, also used for the dodge) above the hero); the fight is already resolved and paid by `StartFightUseCase`, the bloc only replays the `FightLogEntity` (one turn every 600 ms, each turn's effect when its blow lands) and refreshes the list with `GetArenaUseCase` when the replay ends; a first championship adds a `ChampionEffect` (confetti over the hero) after `FightEndedEffect` and titles the result *¡Campeón de la arena!*; `game/` (`ArenaGame` with the same capped `dt`, `ArenaSceneComponent`, `ArenaStateListener`, `FighterComponent`, `HealthBarComponent`, `ArenaGroundComponent`, atlas `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames` over `arena.json`); `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`); `arena_page.dart` (`ArenaPage` + `_ArenaView`, `GameWidget(autofocus: false)`).
+  - `features/arena/` — the arena screen, same shape as `forest/`: `ArenaBloc` (events `ArenaStarted`, `ArenaLevelSelected`, `ArenaFightRequested`, `ArenaReplayTicked`, `ArenaReplaySkipped`, `ArenaClosed`; `ArenaData` with the level list, the selection, `FightReplayData`, `FighterRenderData`s, `ArenaResultData` and sealed `ArenaEffect`s; a double strike or a second wind adds a `SkillUsedEffect` after its own effect, and the scene floats the skill name (`Internationalize.arenaSkillUsed`, also used for the dodge) above the hero); the fight is already resolved and paid by `StartFightUseCase`, the bloc only replays the `FightLogEntity` (one turn every 800 ms, each turn's effect when its blow lands) and refreshes the list with `GetArenaUseCase` when the replay ends; a first championship adds a `ChampionEffect` (confetti over the hero) after `FightEndedEffect` and titles the result *¡Campeón de la arena!*; `game/` (`ArenaGame` with the same capped `dt`, `ArenaSceneComponent`, `ArenaStateListener`, `FighterComponent`, `HealthBarComponent`, `ArenaGroundComponent`, atlas `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames` over `arena.json`); `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`); `arena_page.dart` (`ArenaPage` + `_ArenaView`, `GameWidget(autofocus: false)`).
   - `widgets/` — `CustomButton`, `CustomPopUp` (used by `NavifyImpl`). `theme/` — `colors/custom_colors.dart`, `styles/custom_text_styles.dart`, `images/custom_icons.dart`, `custom_theme.dart`.
 
 Documented exceptions to the plugin (keep them; do not "fix" them):
@@ -70,7 +70,7 @@ Key cross-cutting conventions:
 - **Positions are feet / trunk bases**, in world units = native art pixels; the domain and Flame are both Y-down (no conversion). The same point drives collision, sprite anchoring and draw order (component `priority` = base `y`).
 - **New resource, tool or building:** a `Resource`/`ToolKind`/`BlueprintId` is the enum value (appended at the end) + its cases in `Internationalize` and `es.json`, `CustomIcons` (+ SVG in `lib/core/assets/images/icons/`), `SpriteNames` (+ atlas frame via `build_assets.py`) and, for buildings, `RenderConstants.buildingFrontOffset`; `lpc_atlas_test.dart`, `internationalize_test.dart` and `custom_icons_test.dart` fail if any piece is missing. `LpcAssetsMock` builds a frame for every `BlueprintId`, and new buildings reuse `build_cottage()` in `build_assets.py` (recoloured roof via `ROOF_RAMP`, taller with `roof_stretch`).
 - **The map is level data:** tree positions, wood, kinds and ground decoration come from the data layer; the view never picks art or places decor itself (`SpriteNames` maps kind → atlas frame).
-- **Rendering constants** (`features/forest/game/render/render_constants.dart`, art-specific so not in `core`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px); sprites drawn with `FilterQuality.none`. Arena: `arena/game/render/arena_render_constants.dart` (400 ms lead-in, 600 ms per turn, impact at half the turn; 480×270 stage framed with a cover zoom between 1 and 3; hero facing right, enemies facing left; people have idle, walk and slash frames and hold their weapon: the hero the axe or the LPC arming sword of its equipped weapon (`FighterRenderData.weapon`, `ArenaSpriteNames.heroWith`: bronze short sword, iron, steel), the veteran bandit (`EnemyKind.banditVeteran`, blue shirt) an iron sword; barbarians wear their own LPC layers (leather armour, beard, helmet) and the barbarian chief has his own frames (viking helmet, black beard) drawn ×1.25; wolves and bears (`ArenaRenderConstants.leapSequence`, an exhaustive `switch` on `EnemyKind`) bite or swipe with their own `attack-*` frames while `ArenaFrames.groundSpot` / `lift` make them leap at their target (`FighterRenderData.targetIndex`) during the first 40 % of the turn, stopping 30 px short, and back after 60 %, and they lie on their own `down` frame instead of tipping over; the hero's target, the first enemy still standing, has a ring under its feet (`TargetRingComponent`, `FighterRenderData.isTargeted`), and fallen fighters are drawn at half alpha).
+- **Rendering constants** (`features/forest/game/render/render_constants.dart`, art-specific so not in `core`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px); sprites drawn with `FilterQuality.none`. Arena: `arena/game/render/arena_render_constants.dart` (400 ms lead-in, 800 ms per turn, impact at half the turn; people walk up to their target during the first 35 % of the turn (walk frames, `ArenaFrames.approachReach`), strike in place with the slash frames and walk back after 65 %, stopping `approachGap` (30 px) short; 480×270 stage framed with a cover zoom between 1 and 3; hero facing right, enemies facing left; people have idle, walk and slash frames and hold their weapon: the hero the axe or the LPC arming sword of its equipped weapon (`FighterRenderData.weapon`, `ArenaSpriteNames.heroWith`: bronze short sword, iron, steel), the veteran bandit (`EnemyKind.banditVeteran`, blue shirt) an iron sword; barbarians wear their own LPC layers (leather armour, beard, helmet) and the barbarian chief has his own frames (viking helmet, black beard) drawn ×1.25; wolves and bears (`ArenaRenderConstants.leapSequence`, an exhaustive `switch` on `EnemyKind`) bite or swipe with their own `attack-*` frames while `ArenaFrames.groundSpot` / `lift` make them leap at their target (`FighterRenderData.targetIndex`) during the first 40 % of the turn, stopping 30 px short, and back after 60 %, and they lie on their own `down` frame instead of tipping over; the hero's target, the first enemy still standing, has a ring under its feet (`TargetRingComponent`, `FighterRenderData.isTargeted`), and fallen fighters are drawn at half alpha).
 - **New enemy kind:** the `EnemyKind` value (appended at the end) + its cases in `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale` and `leapSequence`, `Internationalize.arenaEnemy` and `es.json`, and its frames in `arena.png` (`build_assets.py`, credited in `CREDITS.md`); `arena_sprite_names_test.dart` and `internationalize_test.dart` fail if any piece is missing.
 - `GameWidget(autofocus: false)` is deliberate: with autofocus Flame swallows every key and Esc never reaches the page's `CallbackShortcuts`.
 - Tree taps/clicks are pixel-accurate (texture alpha), so shadows and gaps between leaves fall through to movement. On the web, right click or Esc cancels placement; touch screens get the placement bar.
diff --git a/lib/layers/presentation/features/arena/game/render/arena_frames.dart b/lib/layers/presentation/features/arena/game/render/arena_frames.dart
index 95a0020..3fe7b38 100644
--- a/lib/layers/presentation/features/arena/game/render/arena_frames.dart
+++ b/lib/layers/presentation/features/arena/game/render/arena_frames.dart
@@ -20,7 +20,14 @@ abstract final class ArenaFrames {
         name,
         sequenceColumn(leap, fighter.swingProgress),
       ),
-      FighterPose.attack => ArenaSpriteNames.slash(name, PlayerFrames.workColumn(WorkTool.axe, fighter.swingProgress)),
+      FighterPose.attack when isWalking(fighter.swingProgress) => ArenaSpriteNames.walk(
+        name,
+        PlayerFrames.walkColumn(animationSeconds),
+      ),
+      FighterPose.attack => ArenaSpriteNames.slash(
+        name,
+        PlayerFrames.workColumn(WorkTool.axe, strikeProgress(fighter.swingProgress)),
+      ),
       FighterPose.idle || FighterPose.hurt => ArenaSpriteNames.idle(name, PlayerFrames.idleColumn(animationSeconds)),
       FighterPose.down when leap != null => ArenaSpriteNames.down(name),
       FighterPose.down => ArenaSpriteNames.idle(name, 0),
@@ -50,9 +57,22 @@ abstract final class ArenaFrames {
 
   static bool isLeaping(FighterRenderData fighter) => fighter.pose == FighterPose.attack && isBeast(fighter.enemyKind);
 
-  static double leapReach(double progress) {
-    const out = ArenaRenderConstants.leapOutShare;
-    const back = ArenaRenderConstants.leapBackShare;
+  static bool isWalking(double progress) =>
+      progress < ArenaRenderConstants.approachOutShare || progress > ArenaRenderConstants.approachBackShare;
+
+  static double strikeProgress(double progress) {
+    const out = ArenaRenderConstants.approachOutShare;
+    const back = ArenaRenderConstants.approachBackShare;
+    return ((progress - out) / (back - out)).clamp(0, 1).toDouble();
+  }
+
+  static double leapReach(double progress) =>
+      _reach(progress, ArenaRenderConstants.leapOutShare, ArenaRenderConstants.leapBackShare);
+
+  static double approachReach(double progress) =>
+      _reach(progress, ArenaRenderConstants.approachOutShare, ArenaRenderConstants.approachBackShare);
+
+  static double _reach(double progress, double out, double back) {
     if (progress <= 0) return 0;
     if (progress < out) return Easing.sineOut(progress / out);
     if (progress <= back) return 1;
@@ -69,13 +89,16 @@ abstract final class ArenaFrames {
 
   static PositionEntity groundSpot(FighterRenderData fighter) {
     final home = spot(fighter.side, fighter.index);
-    if (!isLeaping(fighter)) return home;
+    if (fighter.pose != FighterPose.attack) return home;
+    final leaping = isBeast(fighter.enemyKind);
+    final gap = leaping ? ArenaRenderConstants.leapGap : ArenaRenderConstants.approachGap;
+    final reach = leaping ? leapReach(fighter.swingProgress) : approachReach(fighter.swingProgress);
     final target = spot(opposite(fighter.side), fighter.targetIndex);
     final dx = target.x - home.x;
     final dy = target.y - home.y;
     final distance = math.sqrt(dx * dx + dy * dy);
-    if (distance <= ArenaRenderConstants.leapGap) return home;
-    final travel = (distance - ArenaRenderConstants.leapGap) / distance * leapReach(fighter.swingProgress);
+    if (distance <= gap) return home;
+    final travel = (distance - gap) / distance * reach;
     return PositionEntity(x: home.x + dx * travel, y: home.y + dy * travel);
   }
 
diff --git a/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart b/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart
index 29eb036..e76f2b1 100644
--- a/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart
+++ b/lib/layers/presentation/features/arena/game/render/arena_render_constants.dart
@@ -3,7 +3,7 @@ import '../../../../../domain/entities/geometry/position_entity.dart';
 
 abstract final class ArenaRenderConstants {
   static const double leadInMs = 400;
-  static const double turnMs = 600;
+  static const double turnMs = 800;
   static const double impactShare = 0.5;
 
   static const double stageWidth = 480;
@@ -36,6 +36,9 @@ abstract final class ArenaRenderConstants {
     EnemyKind.bear => bearSwipeSequence,
   };
 
+  static const double approachOutShare = 0.35;
+  static const double approachBackShare = 0.65;
+  static const double approachGap = 30;
   static const double leapOutShare = 0.4;
   static const double leapBackShare = 0.6;
   static const double leapGap = 30;
```

Run: `flutter test` → **642** en verde.

- [ ] **Step 3: Verificación y commit**

```bash
flutter analyze
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-C8]: Walk up to the target, strike and walk back"
```

---

### Task TC8.3: HUD alineado a la izquierda

**Files:**
  - Modify: `CLAUDE.md`
  - Modify: `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`
  - Modify: `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`

- [ ] **Step 1: Tests (rojo)**

```diff
diff --git a/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart b/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
index a6863ba..53cbc36 100644
--- a/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
+++ b/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
@@ -280,6 +280,8 @@ void main() {
       expect(rect.right, lessThanOrEqualTo(640));
       expect(rect.bottom, lessThanOrEqualTo(360));
     }
+    final firstButton = tester.getRect(find.widgetWithText(HudButton, Internationalize.forestQuests));
+    expect(firstButton.left, resourceBar.left);
   });
 
   testWidgets('testWhenTheScreenIsWideThenTheFourButtonsStayOnTheResourceBarLine', (tester) async {
@@ -320,7 +322,7 @@ void main() {
     final heroButton = tester.getRect(find.widgetWithText(HudButton, Internationalize.forestHero));
     expect(tester.takeException(), isNull);
     expect(panel.top, greaterThanOrEqualTo(heroButton.bottom));
-    expect(panel.left, greaterThanOrEqualTo(0));
+    expect(panel.left, tester.getRect(find.byType(ResourceBar)).left);
     expect(panel.right, lessThanOrEqualTo(640));
     expect(panel.bottom, lessThanOrEqualTo(360));
   });
```

Run: `flutter test test/layers/presentation/features/forest/widgets/hud_overlay_test.dart` → FAIL (botones a la derecha).

- [ ] **Step 2: Código (verde)**

```diff
diff --git a/CLAUDE.md b/CLAUDE.md
index 617a948..b19bfad 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -45,7 +45,7 @@ Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DO
   - `features/forest/bloc/` — `ForestBloc` (single `on<ForestEvent>` with `await switch`; events `ForestStarted`, `ForestTicked`, `ForestMapClicked`, `ForestPointerMoved`, `ForestBuildRequested`, `ForestPlacementCancelled`, `ForestGearPurchaseRequested`, `ForestArenaRequested` (opens the arena with `NavigationService.push(const ArenaPage())` and cancels placement), `ForestSkillLearnRequested`; states `ForestInitial` / `ForestInProgress` / `ForestSuccess` / `ForestFailure` carrying `ForestData`). Handlers are synchronous so ticks keep frame order. Messages are snackbars through `NavigationService`.
   - `features/forest/models/` — view models (`PlayerRenderData`, sealed `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `ResourceItemData`, `ToolItemData`, `PlacementData`, `HeroPanelData`, `GearRowData`, `GearItemData`, `SkillItemData`) and sealed `ForestEffect` (with `GearPurchasedEffect`, `SkillLearnedEffect`) (played once per emitted state).
   - `features/forest/game/` — Flame (`package:flame` / `flame_bloc` may only be imported by `features/forest/game/`, `features/arena/game/`, `forest_page.dart` and `arena_page.dart`; rule in `architecture_test.dart`): `ForestGame` (`update` caps `dt` at 100 ms once and uses that value for `ForestTicked` and for every component, so animations never run ahead of the simulation) + `ForestWorld` + `ForestSceneComponent` + `ForestStateListener` (reconciles components with `ForestData.world` by id; plays effects), `components/` (ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player, `FloatingTextComponent` shared with the arena, same API as F1's plan), `atlas/` (`LpcAtlas` for `forest.json`, `AlphaMask`, `LpcAssets` + loader, `SpriteNames`), `render/` (`RenderConstants`, depth, position conversion, easing, tree motion, player frames, `CameraFraming` working with `Offset`/`Size`, not Flame vectors), `particles/` (chips, dust, the gear-purchase sparkles, the same sparkles in blue when a skill is learned (`ParticleKind.magicSparkle`), blood drops: `ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`, and the champion confetti, `ParticleBursts.confetti`, gold and blue sparkles that fall).
-  - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` (one section per `QuestLine`) + `QuestRow`, `PlacementBar` (touch), `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`, `HudPanel`, `HudButton` (takes an optional SVG `icon`); `HudOverlay` has four buttons, *Misiones*, *Construir*, *Héroe* and *Arena* (Arena closes any open menu, the hero panel included), on the `ResourceBar` line from `HudOverlay.buttonsBelowWidth` (920 px) and right-aligned under it below that, with the open menu always under the buttons; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_ForestViewState` is `RouteAware` on the `RouteObserver` that `ForestPage` receives through its constructor from `ContainerAppBloc`, which reads it from `NavigationService`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops; `_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
+  - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` (one section per `QuestLine`) + `QuestRow`, `PlacementBar` (touch), `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`, `HudPanel`, `HudButton` (takes an optional SVG `icon`); `HudOverlay` has four buttons, *Misiones*, *Construir*, *Héroe* and *Arena* (Arena closes any open menu, the hero panel included), on the `ResourceBar` line from `HudOverlay.buttonsBelowWidth` (920 px) and left-aligned under it below that (same left edge as the bar), with the open menu always under the buttons; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_ForestViewState` is `RouteAware` on the `RouteObserver` that `ForestPage` receives through its constructor from `ContainerAppBloc`, which reads it from `NavigationService`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops; `_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
   - `features/arena/` — the arena screen, same shape as `forest/`: `ArenaBloc` (events `ArenaStarted`, `ArenaLevelSelected`, `ArenaFightRequested`, `ArenaReplayTicked`, `ArenaReplaySkipped`, `ArenaClosed`; `ArenaData` with the level list, the selection, `FightReplayData`, `FighterRenderData`s, `ArenaResultData` and sealed `ArenaEffect`s; a double strike or a second wind adds a `SkillUsedEffect` after its own effect, and the scene floats the skill name (`Internationalize.arenaSkillUsed`, also used for the dodge) above the hero); the fight is already resolved and paid by `StartFightUseCase`, the bloc only replays the `FightLogEntity` (one turn every 800 ms, each turn's effect when its blow lands) and refreshes the list with `GetArenaUseCase` when the replay ends; a first championship adds a `ChampionEffect` (confetti over the hero) after `FightEndedEffect` and titles the result *¡Campeón de la arena!*; `game/` (`ArenaGame` with the same capped `dt`, `ArenaSceneComponent`, `ArenaStateListener`, `FighterComponent`, `HealthBarComponent`, `ArenaGroundComponent`, atlas `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames` over `arena.json`); `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`); `arena_page.dart` (`ArenaPage` + `_ArenaView`, `GameWidget(autofocus: false)`).
   - `widgets/` — `CustomButton`, `CustomPopUp` (used by `NavifyImpl`). `theme/` — `colors/custom_colors.dart`, `styles/custom_text_styles.dart`, `images/custom_icons.dart`, `custom_theme.dart`.
 
diff --git a/lib/layers/presentation/features/forest/widgets/hud_overlay.dart b/lib/layers/presentation/features/forest/widgets/hud_overlay.dart
index 88467e3..88f1f29 100644
--- a/lib/layers/presentation/features/forest/widgets/hud_overlay.dart
+++ b/lib/layers/presentation/features/forest/widgets/hud_overlay.dart
@@ -73,8 +73,8 @@ class _HudOverlayState extends State<HudOverlay> {
                 Align(alignment: Alignment.centerLeft, child: resourceBar),
                 Flexible(
                   child: Align(
-                    alignment: Alignment.topRight,
-                    child: _actions(maxWidth: maxWidth, isHeightBounded: true),
+                    alignment: Alignment.topLeft,
+                    child: _actions(maxWidth: maxWidth, isHeightBounded: true, alignLeft: true),
                   ),
                 ),
               ],
@@ -95,27 +95,27 @@ class _HudOverlayState extends State<HudOverlay> {
     );
   }
 
-  Widget _actions({required double maxWidth, bool isHeightBounded = false}) {
+  Widget _actions({required double maxWidth, bool isHeightBounded = false, bool alignLeft = false}) {
     final openMenu = _openMenu;
     final menu = openMenu == null ? null : _menu(menu: openMenu);
     return ConstrainedBox(
       constraints: BoxConstraints(maxWidth: maxWidth < 0 ? 0 : maxWidth),
       child: Column(
         mainAxisSize: MainAxisSize.min,
-        crossAxisAlignment: CrossAxisAlignment.end,
+        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
         spacing: 8,
         children: [
-          _buttons(),
+          _buttons(alignLeft: alignLeft),
           if (menu != null) isHeightBounded ? Flexible(child: menu) : menu,
         ],
       ),
     );
   }
 
-  Widget _buttons() {
+  Widget _buttons({required bool alignLeft}) {
     return FittedBox(
       fit: BoxFit.scaleDown,
-      alignment: Alignment.centerRight,
+      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
       child: _buttonRow(),
     );
   }
```

Run: `flutter test` → **642** en verde.

- [ ] **Step 3: Verificación y commit**

```bash
flutter analyze
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-C8]: Align the narrow HUD buttons with the resource bar"
```

---

### Task TC8.4: Mensajes de misiones agrupados

**Files:**
  - Modify: `CLAUDE.md`
  - Modify: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
  - Modify: `test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart`

- [ ] **Step 1: Test (rojo)**

```diff
diff --git a/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart b/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
index 0935eb7..6d40649 100644
--- a/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
+++ b/test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart
@@ -243,6 +243,41 @@ void main() {
     },
   );
 
+  blocTest<ForestBloc, ForestState>(
+    'testWhenSeveralHeroQuestsCloseTheLineInTheSameTickThenOnlyTheLineMessageIsShownOnce',
+    build: () {
+      // given
+      return ForestBlocMock.make(
+        GearScenarioMock.withAllWorkshops(hero: HeroEntityMock.championWithEveryQuestDone),
+        navigationService: navigationService,
+      );
+    },
+    act: (bloc) async {
+      // when
+      bloc
+        ..add(const ForestStarted())
+        ..add(const ForestTicked(deltaMs: ForestBlocMock.frameMs));
+      await ForestBlocMock.processEvents();
+    },
+    wait: Duration.zero,
+    verify: (bloc) {
+      // then
+      final messages = ForestBlocMock.shownMessages(navigationService);
+      final lineDone = Internationalize.forestMessageQuestLineCompleted(line: QuestLine.hero);
+      expect(messages.where((message) => message == lineDone), hasLength(1));
+      expect(
+        messages.where(
+          (message) =>
+              message ==
+              Internationalize.forestMessageQuestCompleted(
+                title: Internationalize.forestQuestTitle(id: QuestId.becomeChampion),
+              ),
+        ),
+        isEmpty,
+      );
+    },
+  );
+
   blocTest<ForestBloc, ForestState>(
     'testWhenAHeroQuestIsCompletedWhileOthersAreStillPendingThenShowsTheQuestMessage',
     build: () {
```

Run: `flutter test test/layers/presentation/features/forest/bloc/forest_bloc_hero_test.dart` → FAIL (el mensaje de línea sale varias veces).

- [ ] **Step 2: Código (verde)**

```diff
diff --git a/CLAUDE.md b/CLAUDE.md
index b19bfad..35cfee0 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -42,7 +42,7 @@ Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DO
 - `lib/layers/data/` — `datasources/level` (`LevelLocalDatasourceImpl`: seeded procedural forest that also decides each tree's kind and the ground decoration; all-nullable DBOs in `local/dbo/`), `datasources/session` (in-memory, `@LazySingleton`: one game per app), `repositories/level` (`LevelRepositoryImpl` + injected `*MapperDBO`s), `repositories/session`. Errors go through `AppExceptionHandler`.
 - `lib/layers/presentation/`
   - `app/` — `ContainerApp` (`MaterialApp` with easy_localization and the navigator key of `NavigationService`) and `ContainerAppBloc`, which replaces the start screen with `ForestPage` through `NavigationService`.
-  - `features/forest/bloc/` — `ForestBloc` (single `on<ForestEvent>` with `await switch`; events `ForestStarted`, `ForestTicked`, `ForestMapClicked`, `ForestPointerMoved`, `ForestBuildRequested`, `ForestPlacementCancelled`, `ForestGearPurchaseRequested`, `ForestArenaRequested` (opens the arena with `NavigationService.push(const ArenaPage())` and cancels placement), `ForestSkillLearnRequested`; states `ForestInitial` / `ForestInProgress` / `ForestSuccess` / `ForestFailure` carrying `ForestData`). Handlers are synchronous so ticks keep frame order. Messages are snackbars through `NavigationService`.
+  - `features/forest/bloc/` — `ForestBloc` (single `on<ForestEvent>` with `await switch`; events `ForestStarted`, `ForestTicked`, `ForestMapClicked`, `ForestPointerMoved`, `ForestBuildRequested`, `ForestPlacementCancelled`, `ForestGearPurchaseRequested`, `ForestArenaRequested` (opens the arena with `NavigationService.push(const ArenaPage())` and cancels placement), `ForestSkillLearnRequested`; states `ForestInitial` / `ForestInProgress` / `ForestSuccess` / `ForestFailure` carrying `ForestData`). Handlers are synchronous so ticks keep frame order. Messages are snackbars through `NavigationService`; the quests completed in one tick are announced together (`_announceQuests`: one message per line they close, otherwise one per quest).
   - `features/forest/models/` — view models (`PlayerRenderData`, sealed `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `ResourceItemData`, `ToolItemData`, `PlacementData`, `HeroPanelData`, `GearRowData`, `GearItemData`, `SkillItemData`) and sealed `ForestEffect` (with `GearPurchasedEffect`, `SkillLearnedEffect`) (played once per emitted state).
   - `features/forest/game/` — Flame (`package:flame` / `flame_bloc` may only be imported by `features/forest/game/`, `features/arena/game/`, `forest_page.dart` and `arena_page.dart`; rule in `architecture_test.dart`): `ForestGame` (`update` caps `dt` at 100 ms once and uses that value for `ForestTicked` and for every component, so animations never run ahead of the simulation) + `ForestWorld` + `ForestSceneComponent` + `ForestStateListener` (reconciles components with `ForestData.world` by id; plays effects), `components/` (ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player, `FloatingTextComponent` shared with the arena, same API as F1's plan), `atlas/` (`LpcAtlas` for `forest.json`, `AlphaMask`, `LpcAssets` + loader, `SpriteNames`), `render/` (`RenderConstants`, depth, position conversion, easing, tree motion, player frames, `CameraFraming` working with `Offset`/`Size`, not Flame vectors), `particles/` (chips, dust, the gear-purchase sparkles, the same sparkles in blue when a skill is learned (`ParticleKind.magicSparkle`), blood drops: `ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`, and the champion confetti, `ParticleBursts.confetti`, gold and blue sparkles that fall).
   - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` (one section per `QuestLine`) + `QuestRow`, `PlacementBar` (touch), `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`, `HudPanel`, `HudButton` (takes an optional SVG `icon`); `HudOverlay` has four buttons, *Misiones*, *Construir*, *Héroe* and *Arena* (Arena closes any open menu, the hero panel included), on the `ResourceBar` line from `HudOverlay.buttonsBelowWidth` (920 px) and left-aligned under it below that (same left edge as the bar), with the open menu always under the buttons; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_ForestViewState` is `RouteAware` on the `RouteObserver` that `ForestPage` receives through its constructor from `ContainerAppBloc`, which reads it from `NavigationService`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops; `_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
diff --git a/lib/layers/presentation/features/forest/bloc/forest_bloc.dart b/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
index 91a217e..0843eca 100644
--- a/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
+++ b/lib/layers/presentation/features/forest/bloc/forest_bloc.dart
@@ -15,6 +15,8 @@ import '../../../../../core/config/constants/enum/gear_option_state.dart';
 import '../../../../../core/config/constants/enum/gear_slot.dart';
 import '../../../../../core/config/constants/enum/learn_skill_result.dart';
 import '../../../../../core/config/constants/enum/player_activity.dart';
+import '../../../../../core/config/constants/enum/quest_id.dart';
+import '../../../../../core/config/constants/enum/quest_line.dart';
 import '../../../../../core/config/constants/enum/resource.dart';
 import '../../../../../core/config/constants/enum/skill_id.dart';
 import '../../../../../core/config/constants/enum/skill_option_state.dart';
@@ -152,9 +154,14 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     }
     final effects = <ForestEffect>[];
     final fromX = _getPlayerStatusUseCase().position.x;
-    for (final gameEvent in _advanceGameUseCase(deltaMs: event.deltaMs)) {
+    final gameEvents = _advanceGameUseCase(deltaMs: event.deltaMs);
+    for (final gameEvent in gameEvents) {
       _react(gameEvent, fromX: fromX, effects: effects);
     }
+    _announceQuests([
+      for (final gameEvent in gameEvents)
+        if (gameEvent is QuestCompletedEventEntity) gameEvent.questId,
+    ]);
     emit(ForestSuccess(data: _buildData(effects: effects)));
   }
 
@@ -307,15 +314,25 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
           Internationalize.forestMessageBuildingCompleted(name: Internationalize.forestBlueprint(id: blueprint)),
         );
         effects.add(BuildingCompletedEffect(buildingId: buildingId));
-      case QuestCompletedEventEntity(:final questId):
-        final quests = _getQuestsUseCase();
-        final line = quests.firstWhere((quest) => quest.id == questId).line;
-        final lineDone = quests.where((quest) => quest.line == line).every((quest) => quest.isCompleted);
-        _showMessage(
-          lineDone
-              ? Internationalize.forestMessageQuestLineCompleted(line: line)
-              : Internationalize.forestMessageQuestCompleted(title: Internationalize.forestQuestTitle(id: questId)),
-        );
+      case QuestCompletedEventEntity():
+        break;
+    }
+  }
+
+  void _announceQuests(List<QuestId> completed) {
+    if (completed.isEmpty) return;
+    final quests = _getQuestsUseCase();
+    for (final line in QuestLine.values) {
+      final ofLine = quests.where((quest) => quest.line == line);
+      final done = completed.where((id) => ofLine.any((quest) => quest.id == id)).toList();
+      if (done.isEmpty) continue;
+      if (ofLine.every((quest) => quest.isCompleted)) {
+        _showMessage(Internationalize.forestMessageQuestLineCompleted(line: line));
+        continue;
+      }
+      for (final id in done) {
+        _showMessage(Internationalize.forestMessageQuestCompleted(title: Internationalize.forestQuestTitle(id: id)));
+      }
     }
   }
 
```

Run: `flutter test` → **643** en verde.

- [ ] **Step 3: Verificación y commit**

```bash
flutter analyze
git add lib test
git add CLAUDE.md
git commit -m "[PROJECT-C8]: Announce the quests completed in one tick together"
```

---

### Task TC8.5: Pendientes

**Files:**
  - Modify: `docs/boost/plans/2026-10-06-hero-arena/ARENA-FIXES.md`
  - Modify: `lib/layers/presentation/features/arena/bloc/arena_bloc.dart`
  - Modify: `lib/layers/presentation/features/arena/game/arena_scene_component.dart`
  - Modify: `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`
  - Modify: `test/layers/presentation/features/arena/game/arena_scene_component_test.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_bloc_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_data_mock.dart`
  - Modify: `test/mocks/presentation/features/arena/arena_effect_mock.dart`

- [ ] **Step 1: Tests (rojo)**

```diff
diff --git a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
index 956f99d..bd2331d 100644
--- a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
+++ b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
@@ -558,6 +558,39 @@ void main() {
     },
   );
 
+  blocTest<ArenaBloc, ArenaState>(
+    'testWhenTheListCannotBeRefreshedAfterAFightThenTheErrorIsShownAndTheResultStays',
+    build: () {
+      // given
+      return ArenaBlocMock.make(
+        world,
+        navigationService: navigationService,
+        error: AppExceptionMock.noGameInProgress,
+        callsBeforeError: 3,
+      );
+    },
+    act: (bloc) {
+      // when
+      bloc
+        ..add(const ArenaStarted())
+        ..add(const ArenaFightRequested())
+        ..add(const ArenaReplaySkipped());
+    },
+    wait: Duration.zero,
+    verify: (bloc) {
+      // then
+      expect(bloc.state, isA<ArenaSuccess>());
+      expect(bloc.state.data.result, ArenaResultDataMock.victoryTenGold);
+      verify(
+        navigationService.showErrorPopUp(
+          title: AppExceptionMock.noGameInProgress.title,
+          message: AppExceptionMock.noGameInProgress.message,
+          buttonTitle: anyNamed('buttonTitle'),
+        ),
+      ).called(1);
+    },
+  );
+
   blocTest<ArenaBloc, ArenaState>(
     'testWhenClosedThenGoesBackToTheForest',
     build: () {
diff --git a/test/layers/presentation/features/arena/game/arena_scene_component_test.dart b/test/layers/presentation/features/arena/game/arena_scene_component_test.dart
index 8830ff0..fdc5212 100644
--- a/test/layers/presentation/features/arena/game/arena_scene_component_test.dart
+++ b/test/layers/presentation/features/arena/game/arena_scene_component_test.dart
@@ -126,4 +126,17 @@ void main() {
     // then
     expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
   });
+
+  testWithFlameGame('testWhenABlowDoesNoDamageThenNothingFloatsOrSplashes', (game) async {
+    // given
+    final scene = await _mountedScene(game);
+
+    // when
+    scene.show(ArenaDataMock.banditHitForNothing);
+    await game.ready();
+
+    // then
+    expect(scene.children.whereType<FloatingTextComponent>(), isEmpty);
+    expect(scene.children.whereType<ParticleBurstComponent>(), isEmpty);
+  });
 }
diff --git a/test/mocks/presentation/features/arena/arena_bloc_mock.dart b/test/mocks/presentation/features/arena/arena_bloc_mock.dart
index ad974df..76e8446 100644
--- a/test/mocks/presentation/features/arena/arena_bloc_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_bloc_mock.dart
@@ -13,11 +13,17 @@ import '../../../domain/repositories/repository_mocks.mocks.dart';
 abstract final class ArenaBlocMock {
   static const double frameMs = 16;
 
-  static ArenaBloc make(World world, {required MockNavigationService navigationService, Exception? error}) {
+  static ArenaBloc make(
+    World world, {
+    required MockNavigationService navigationService,
+    Exception? error,
+    int callsBeforeError = 0,
+  }) {
     final sessionRepository = MockGameSessionRepository();
     final session = GameSessionEntityMock.playing(world);
+    var calls = 0;
     when(sessionRepository.current()).thenAnswer((_) {
-      if (error != null) throw error;
+      if (error != null && calls++ >= callsBeforeError) throw error;
       return session;
     });
     return ArenaBloc(
diff --git a/test/mocks/presentation/features/arena/arena_data_mock.dart b/test/mocks/presentation/features/arena/arena_data_mock.dart
index be7f368..557587e 100644
--- a/test/mocks/presentation/features/arena/arena_data_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_data_mock.dart
@@ -24,6 +24,8 @@ abstract final class ArenaDataMock {
     effects: const [ArenaEffectMock.banditHitForFour],
   );
 
+  static ArenaData get banditHitForNothing => replaying.copyWith(effects: const [ArenaEffectMock.banditHitForNothing]);
+
   static ArenaData get heroDodged => replaying.copyWith(effects: const [ArenaEffectMock.heroDodged]);
 
   static ArenaData get heroGotASecondWind => replaying.copyWith(
diff --git a/test/mocks/presentation/features/arena/arena_effect_mock.dart b/test/mocks/presentation/features/arena/arena_effect_mock.dart
index d3ec224..ab2f9a2 100644
--- a/test/mocks/presentation/features/arena/arena_effect_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_effect_mock.dart
@@ -5,6 +5,8 @@ import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart'
 abstract final class ArenaEffectMock {
   static const HitEffect banditHitForFour = HitEffect(side: FightSide.enemy, index: 0, damage: 4);
 
+  static const HitEffect banditHitForNothing = HitEffect(side: FightSide.enemy, index: 0, damage: 0);
+
   static const HitEffect heroHitForTwo = HitEffect(side: FightSide.hero, index: 0, damage: 2);
 
   static const HitEffect banditHitForThree = HitEffect(side: FightSide.enemy, index: 0, damage: 3);
```

Run: `flutter test test/layers/presentation/features/arena` → FAIL (el error no se captura y el "−0" flota).

- [ ] **Step 2: Código y documentación (verde)**

```diff
diff --git a/docs/boost/plans/2026-10-06-hero-arena/ARENA-FIXES.md b/docs/boost/plans/2026-10-06-hero-arena/ARENA-FIXES.md
index 014a2e6..8dab3bf 100644
--- a/docs/boost/plans/2026-10-06-hero-arena/ARENA-FIXES.md
+++ b/docs/boost/plans/2026-10-06-hero-arena/ARENA-FIXES.md
@@ -2,10 +2,12 @@
 
 > Lista de ajustes de la arena que se aplicarán **cuando el plan *Héroe y arena* esté completo** (después de C7), en una fase propia de pulido. No es un plan detallado: cada punto se convierte en tarea cuando se planifique esa fase.
 >
-> Abierta el 2026-10-07, tras probar C2 y C3 juntas.
+> Abierta el 2026-10-07, tras probar C2 y C3 juntas. **Hecha en C8 (2026-10-09)**, salvo lo que se indica en cada punto: plan en [`C8-arena-polish.md`](C8-arena-polish.md).
 
 ## 1. Arte de los luchadores
 
+> **Hecho en C8 (TC8.1).** El veterano es `EnemyKind.banditVeteran`: camisa azul y espada de hierro. El héroe lleva en la arena el arma equipada: hacha, o la espada *arming* de LPC en bronce (corta), hierro o acero.
+
 ### 1.1 Bandido novato y bandido veterano se ven iguales
 
 Los dos son `EnemyKind.bandit` y usan los mismos frames `bandit-*` del atlas de la arena (camisa granate, pantalón gris oscuro, pelo negro y hacha).
@@ -54,6 +56,8 @@ Hoy cada pieza de equipo cuesta madera **y** oro (`Gear.all`):
 
 ## 3. Los luchadores se acercan para golpear
 
+> **Hecho en C8 (TC8.2)**, con turnos de 800 ms: avanzar hasta el 35 %, golpe a mitad y volver desde el 65 %, a 30 px del objetivo. Al volver, el luchador anda de espaldas (sigue mirando al enemigo).
+
 Hoy cada luchador se queda en su sitio (héroe en x = 190, enemigos en x = 300/340) y golpea al aire: el golpe "llega" aunque estén a más de 100 px.
 
 **Qué hacer:** que en cada turno el atacante **avance hasta el objetivo**, golpee y **vuelva** a su sitio:
@@ -106,6 +110,8 @@ Además:
 
 ## 5. HUD del bosque en móvil: botones alineados a la izquierda
 
+> **Hecho en C8 (TC8.3).**
+
 Por debajo de `HudOverlay.buttonsBelowWidth` (920 px), los botones (*Misiones*, *Construir*, *Héroe*, *Arena*) bajan a la línea de debajo de la `ResourceBar`, pero **alineados a la derecha**. En el móvil queda raro: la barra empieza a la izquierda y los botones a la derecha.
 
 **Qué hacer:** mantenerlos en la segunda línea, pero **alineados a la izquierda**, debajo de la barra de recursos y con su mismo margen.
@@ -116,6 +122,8 @@ Por debajo de `HudOverlay.buttonsBelowWidth` (920 px), los botones (*Misiones*,
 
 ## 6. Mensajes de misiones repetidos
 
+> **Hecho en C8 (TC8.4).**
+
 Las misiones se comprueban en cada `ForestTicked`, y el bosque está en pausa mientras la arena está encima. Al volver, varias misiones del héroe que se miden con la arena (*Gana un nivel de la arena*, *Gana la mitad de los niveles de la arena*, *Gana al Jefe bárbaro*) pueden completarse en el mismo tick, y salen varios mensajes seguidos. Si son las últimas de su línea, "¡Has completado las misiones de Héroe!" sale una vez por cada misión.
 
 **Qué hacer:** en `ForestBloc`, agrupar los `QuestCompletedEventEntity` del mismo tick:
@@ -126,6 +134,13 @@ Añadir un test del BLoC con dos misiones de la misma línea completadas a la ve
 
 ## 7. Pendientes que ya estaban apuntados
 
+> **Resuelto en C8 (TC8.5):**
+> - Las decisiones provisionales de C2 se dan por buenas (decisión del usuario, 2026-10-09).
+> - El fallo al refrescar la lista tras una pelea se captura: sale el error y el resultado se queda.
+> - Un golpe sin daño ya no enseña "−0" ni salpica.
+> - Frame propio de "recibir el golpe": **descartado** (habría que bajar la animación `hurt` de todas las capas; el parpadeo basta).
+> - El panel de derrota a 844 × 390 se revisa en la prueba manual de C8.
+
 Del cierre de C2 y C3 (sección 5 del README):
 - **Decisiones provisionales de C2**, a revisar con este pulido: la pausa con `RouteObserver`, el panel de victoria sin botón y el umbral ámbar del Poder (×1,25). La de "todos con hacha" la resuelven 1.2 y 1.3.
 - `ArenaBloc._emitReplay` llama a `GetArenaUseCase` sin `try/catch`; hay que capturarlo si F2 trae errores de almacenamiento.
diff --git a/lib/layers/presentation/features/arena/bloc/arena_bloc.dart b/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
index 3d82b86..b521092 100644
--- a/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
+++ b/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
@@ -169,9 +169,18 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
     ];
     var data = state.data.copyWith(replay: () => next, fighters: _replayFighters(next), effects: effects);
     if (next.isFinished) {
-      final arena = _getArenaUseCase();
-      _arena = arena;
-      data = _withArena(data, arena).copyWith(result: () => _result(next));
+      data = data.copyWith(result: () => _result(next));
+      try {
+        final arena = _getArenaUseCase();
+        _arena = arena;
+        data = _withArena(data, arena);
+      } on AppException catch (exception) {
+        _navigationService.showErrorPopUp(
+          title: exception.title,
+          message: exception.message,
+          buttonTitle: Internationalize.commonAccept,
+        );
+      }
     }
     emit(ArenaSuccess(data: data));
   }
diff --git a/lib/layers/presentation/features/arena/game/arena_scene_component.dart b/lib/layers/presentation/features/arena/game/arena_scene_component.dart
index f8c824a..8dc2fb2 100644
--- a/lib/layers/presentation/features/arena/game/arena_scene_component.dart
+++ b/lib/layers/presentation/features/arena/game/arena_scene_component.dart
@@ -91,9 +91,8 @@ class ArenaSceneComponent extends Component {
 
   void _onHit(FightSide side, int index, int damage) {
     final fighter = _fighters[FighterRenderData.keyOf(side, index)];
-    if (fighter == null) return;
+    if (fighter == null || damage <= 0) return;
     _float(side, index, Internationalize.arenaDamage(amount: damage), CustomColors.hudWarning);
-    if (damage <= 0) return;
     fighter.hit();
     final impact = fighter.impactPoint;
     add(
```

Run: `flutter test` → **645** en verde.

- [ ] **Step 3: Verificación y commit**

```bash
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart '*.mocks.dart'
flutter analyze
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
git add lib test docs
git commit -m "[PROJECT-C8]: Survive a failed list refresh and hide empty blows"
```

## Prueba manual

Chrome y emulador Android, en horizontal, con un héroe de prueba sólo en local (como en C6):

1. **Armas:** el héroe pelea con el hacha; tras comprar la espada corta, con la espada de bronce; con la de acero, la de acero.
2. **Veterano:** el *Bandido veterano* lleva camisa azul y espada; el novato, camisa granate y hacha.
3. **Acercarse:** en cada turno el atacante anda hasta su objetivo, golpea y vuelve; los animales siguen saltando. *Saltar* deja a todos en su sitio.
4. **HUD en móvil:** los botones bajo la barra de recursos, alineados a la izquierda; los menús se abren debajo, también a la izquierda.
5. **Misiones:** ganar varias del héroe a la vez (volver de la arena tras ganar al jefe) da un solo mensaje por línea completada.
6. **844 × 390:** el panel de derrota no tapa al enemigo de arriba en los niveles de tres enemigos; si lo tapa, se apunta como desviación.

## Al cerrar C8

- Marca los checkboxes y actualiza `PROGRESS.md` (C8 ✅) y la tabla del README.
- Sin PR por ahora (decisión del usuario): los commits quedan en `feature/PROJECT-X-arena`.
