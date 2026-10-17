# C9 · Maná — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (arena, después de X) |
| **Rama** | `feature/PROJECT-C9-mana`, desde `feature/PROJECT-X-arena` @ `82cdffb` (ya creada, con este plan) |
| **Issue / milestone** | `phase:C9` · milestone `C9 Mana` · #56 |
| **Depende de** | [X · Alineación con iOS](X-ios-alignment.md) |
| **Va antes de** | C10 (y C12, que sube los costes de maná de las habilidades) |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-arena/C9-mana.md` (el porqué de cada cifra), merge `f8f7792` (`[PROJECT-C9]: Merge the mana`), icono `$IOS/Farming/Assets.xcassets/Icons/mana.imageset/mana.svg` |

**Goal:** Un recurso nuevo, el **maná**, que solo se gana venciendo en la mitad difícil de la arena (de *Tres bandidos* en adelante, junto con el oro) y que, junto con el oro, paga las habilidades de la torre de magia.

**Architecture:**
- **Recurso (TC9.2):** `Resource.mana` al final del enum (`wood, gold, mana`) con sus casos en `Internationalize.forestResource` / `forestAmount`, `es.json` (`Maná`, `{amount} de maná`) y `CustomIcons` (`mana.svg`, el rombo azul de iOS, byte a byte). La `ResourceBar` lo pinta sola (`ForestBloc` recorre `Resource.values`). No lleva frame en `SpriteNames`: el maná nunca está en el suelo.
- **Umbral del HUD (TC9.1 + TC9.2):** el maná ensancha la barra. `hud_overlay_test.dart` carga **Roboto** del SDK (la fuente real de Android y de la web; la de los tests, *FlutterTest*, pinta cada letra como un cuadrado y da anchos que no existen) y mide `ResourceBar` + la fila de botones con todos los recursos a 9999. Con la misma holgura de 24 px que tenía 920 en iOS, `HudOverlay.buttonsBelowWidth` pasa de **920 a 1030**. `narrowWidth` (480) no cambia.
- **Dominio (TC9.3):** solo cambian dos catálogos: `ArenaLevels` (niveles 6–10 dan oro y maná: 20/25/30/35/50) y `Skills` (oro y maná: 60 + 20, 90 + 30, 130 + 45). `World.earn` / `spend`, `InventoryRules.missing` / `spend`, `ArenaRules.rewardFor` y `LearnSkillUseCase` ya trabajan recurso a recurso: con oro y sin maná, `notEnoughResources` y no se gasta nada. `balance_test.dart` comprueba el presupuesto por recurso (oro y maná). El combate no cambia: las mismas tiradas, las mismas tasas de victoria.
- **Recompensa entera (TC9.4):** `es.json` `arena.reward` pasa a `+{amounts}` e `Internationalize.arenaReward(amounts:)` recibe el mapa: descarta las cantidades ≤ 0 y une con `", "` cada `forestAmount` en el orden de `Resource.values` (`+10 de oro`, `+75 de oro, 20 de maná`). `ArenaBloc` se lo pasa entero en la fila de cada nivel y en el resultado; nadie lee ya solo `[Resource.gold]`.
- **Docs (TC9.5):** `docs/GAME_DESIGN.md` 3.8 (columna de maná y precios) y `CLAUDE.md`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, easy_localization, `flutter_svg`; tests con `flutter_test`, `bloc_test`, `mockito`. Sin dependencias nuevas.

**Precondición** (`feature/PROJECT-X-arena` @ `82cdffb`, X unida, 658 tests). Este plan usa exactamente estas firmas; comprueba que no han cambiado:
- `enum Resource { wood, gold }` (`lib/core/config/constants/enum/resource.dart:1`);
- `Internationalize.forestResource({required Resource resource})` y `forestAmount({required Resource resource, required int amount})` (`switch` en las líneas 43–46 y 54–57), `Internationalize.arenaReward({required int amount})` (línea 163) con `es.json` `arena.reward` = `"+{amount} de oro"` (línea 147);
- `CustomIcons.resource(Resource)` (`switch` en `custom_icons.dart:14-17`);
- `ArenaLevels.all` con `reward: {Resource.gold: N}` (75, 90, 100, 120 y 150 en las líneas 73, 83, 101, 115 y 133); `Skills.doubleStrike` / `dodge` / `secondWind` con `cost: {Resource.gold: 60 | 90 | 130}`; `Rules.repeatRewardDivisor = 3`;
- `ArenaBloc._result` (línea 221) y `_levelItem` (línea 252) con `Internationalize.arenaReward(amount: …[Resource.gold] ?? 0)`;
- `HudOverlay.buttonsBelowWidth = 920` (línea 19), `narrowWidth = 480`, `_margin = 12`; en la rama ancha, la barra va a la izquierda y la fila de botones a la derecha, las dos a 12 px del borde;
- `void loadSpanishTranslations()` (síncrona) en `test/helpers/spanish_translations.dart`; `HudDataMock.withEveryResourceAndTool` (cada `Resource.values` a 9999); `ResourceItemDataMock.wood` / `gold` / `of`;
- `FundsMock.doubleStrikePrice = {gold: 60}`, `tenGoldShortOfDoubleStrike = {gold: 50}`; `SkillItemDataMock.unaffordable(SkillId, {required int missingGold})`; `ArenaResultDataMock.championHundredFiftyGold` y `victoryFiftyGold`.

**Cómo probar la fase entera:**
- `flutter test` en verde: **665 tests** (658 antes; TC9.1 +1, TC9.2 +0 (cambian 3), TC9.3 +5 (cambian 3, y 5 ficheros de mocks), TC9.4 +1 (cambian 5, y 3 ficheros de mocks), TC9.5 +0).
- `flutter analyze` → `No issues found!`; `dart run build_runner build --delete-conflicting-outputs` + `git diff --exit-code` limpio (C9 no toca DI ni mocks generados); `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart` → `+40`.
- La sección *Prueba manual* en Chrome y Android.

**Cómo se ha comprobado este plan (2026-10-17):** en un worktree desechable sobre `feature/PROJECT-C9-mana` (`82cdffb`), con un commit por tarea; los parches de este documento son esos commits, separados en tests y código:
- tras cada tarea, `flutter analyze` → `No issues found!` y `flutter test` en verde: **659**, **659**, **664**, **665** y **665**;
- los tests nuevos o cambiados fallaban antes de tocar `lib/`: en TC9.2, `Member not found: 'mana'`, y con el recurso ya puesto solo el test del umbral (`1025.55859375` > `920`); en TC9.3, 13 tests; en TC9.4, `No named parameter with the name 'amounts'`. TC9.1 es un test de medida que ya pasa con 920 (ver *Decisiones* 3);
- **equilibrado** (impreso con un `print` temporal en `balance_test.dart`, sin commitear), idéntico al de iOS: oro sin cambios (0 ≤ 0, 0 ≤ 19, 30 ≤ 48, 70 ≤ 90, 130 ≤ 139, 200 ≤ 209, 300 ≤ 305, 390 ≤ 410, 500 ≤ 519, 620 ≤ 660); maná 0 en los niveles 1–6 y **20 ≤ 38, 50 ≤ 69, 50 ≤ 105, 50 ≤ 143**; victorias del héroe esperado 0,86 / 0,77 / 0,84 / 0,79 / 0,84 / 0,78 / 0,78 / 0,81 / 0,80 (niveles 2–10), las mismas que antes de C9;
- **anchos del HUD** a 3000 px de ancho, con labels (los botones miden lo mismo con dos y con tres recursos):

  | Fuente | Barra, 2 recursos, 9999 | Barra, 3 recursos, 9999 | Fila de botones | 12 + barra + 8 + botones + 12, con 3 recursos |
  |---|---|---|---|---|
  | Roboto del SDK (Android, web) | 372,1 | 499,0 | 470,5 | **1001,6** (+ 24 = 1025,6 → **1030**) |
  | *FlutterTest* (la de los tests sin cargar fuente) | 525,5 | 705,5 | 688,5 | 1426,0 |
  | SF Pro de macOS cargada como Roboto (aproximada) | 395,3 | 530,5 | 489,8 | 1052,4 |

  Con dos recursos y Roboto hacían falta 874,6 + 24 = 898,6 ≤ 920: el umbral de hoy tiene la holgura de 24 px y algo más;
- `build_runner` sin cambios; tests de Chrome `+40`;
- después se volvió a aplicar todo **sacando los parches del texto de este plan** (los diez bloques `diff`, en orden) en otro worktree limpio sobre `82cdffb`, con los comandos de cada paso: mismos rojos, mismas cuentas (659, 659, 664, 665, 665) y el árbol final idéntico al del primer intento (`git diff` vacío);
- **no** se ha probado a mano en ningún dispositivo ni en el simulador iOS (se hace en la *Prueba manual*).

## Decisiones del plan

Las de la ficha se mantienen (tablas de recompensas y costes, un tercio de cada recurso al repetir, fichas de habilidad y equipo sin cambios, icono sin créditos, `narrowWidth` igual). Lo que la ficha no fijaba o cambia:

1. **Umbral `buttonsBelowWidth = 1030`, no 1060.** Se mide en Flutter como pide la ficha: Roboto da 1001,6 px de barra + botones con tres recursos y 24 px de holgura dan 1025,6, que se redondea a la decena. Con SF Pro (la fuente de iOS; medida aproximada, porque la `SFNS.ttf` de macOS es variable y Flutter engorda la negrita) harían falta unos 1052 + 24: ningún iPad en horizontal cae entre 1030 y 1076 (1024 queda por debajo, con los botones debajo; 1080 y más, por encima), así que no hay solape real. En horizontal, todos los móviles (incluidos los iPhone Pro Max, 932–956) llevan los botones bajo la barra.
2. **Roboto en los tests del HUD (desviación de la ficha).** La ficha pedía medir con `tester.getSize`, pero con la fuente de los tests la barra de tres recursos mide 705 px y no cabe en 640 (los cinco tests de 640 px de `hud_overlay_test.dart` fallan con `RenderFlex overflowed by 90 pixels`). Nuevo `test/helpers/roboto_font.dart` (`loadRobotoFont()`): carga `Roboto-{Regular,Medium,Bold}.ttf` de `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/` (el artefacto `material_fonts` siempre está, también en el CI) con un `FontLoader('Roboto')`; `hud_overlay_test.dart` lo llama en `setUpAll`. Sin ficheros de fuente nuevos en el repositorio.
3. **TC9.1 es un test de medida que pasa con 920:** fija la regla (12 + barra + 8 + botones + 12 + 24 ≤ umbral) antes de añadir el recurso. El rojo llega en TC9.2, al añadir `Resource.mana`: 1025,6 > 920.
4. **Orden de las tareas:** el recurso (TC9.2) va antes que los números del dominio (TC9.3) porque `Resource.mana` no compila sin sus casos en los `switch` de `Internationalize` y `CustomIcons`; y lo primero que rompe es el HUD.
5. **Equilibrado por recurso, solo los de la arena:** `balance_test.dart` recorre `[Resource.gold, Resource.mana]`, no `Resource.values`: la madera no la paga la arena (la torre de magia cuesta 30 de madera). Test nuevo `testWhenEveryLevelIsWonOnceThenTheManaPaysForEverySkill` que fija `(160, 95)`.
6. **Mocks:** `FundsMock.doubleStrikePrice` pasa a 60 de oro + 20 de maná y `tenGoldShortOfDoubleStrike` a 50 + 20 (sigue siendo "faltan 10 de oro"); nuevos `doubleStrikeGoldWithoutMana`, `banditTrioReward`, `banditTrioRepeatReward` (TC9.3) y `barbarianChiefReward`, `barbarianChiefRepeatReward` (50 + 16), `thirtyGold`, `tenGoldAndZeroMana`, `sixManaBeforeTwentyFiveGold` (TC9.4). `ArenaResultDataMock.championHundredFiftyGold` y `victoryFiftyGold` cambian de nombre (`championWithTheChiefReward`, `victoryWithTheChiefRepeatReward`) porque ya llevan maná. `SkillItemDataMock.unaffordable` gana `missingMana`.
7. **"Faltan 20 de maná"** se prueba en el dominio (`GetSkillOptionsUseCase`: `missing == {mana: 20}`, test nuevo); el texto sale del `_amounts` de siempre de `ForestBloc`, que ya recorre los recursos en el orden del enum.
8. **`arenaReward`** recorre `Resource.values` con `if (amounts[resource] case final amount? when amount > 0)`: el orden lo pone el enum, no el mapa (test con `{mana: 6, gold: 25}` → `+25 de oro, 6 de maná`).
9. **Sin cambios en `LevelTile` ni `ResultPanel`:** la recompensa de la fila ya va en un `Wrap` junto al poder y el detalle del resultado ya parte línea.
10. **`CLAUDE.md`** en su propia tarea (TC9.5), junto con `GAME_DESIGN.md`, en un `git add CLAUDE.md` aparte.

## Reparto

| Tarea | Qué | Depende de |
|---|---|---|
| TC9.1 | Medir el umbral del HUD con la fuente real | — |
| TC9.2 | El maná como recurso (enum, textos, icono, umbral 1030) | TC9.1 |
| TC9.3 | Maná en la arena y en las habilidades, equilibrado por recurso | TC9.2 |
| TC9.4 | La recompensa entera en la arena | TC9.3 (mismo `funds_mock.dart`) |
| TC9.5 | `GAME_DESIGN.md` 3.8 y `CLAUDE.md` | TC9.4 |

En serie, en `feature/PROJECT-C9-mana`, en el orden de la tabla: cada tarea toca ficheros de la anterior. Commits `[PROJECT-C9]: …`, sin atribución a IA; `CLAUDE.md` se añade en un comando aparte del `git commit`. Al terminar cada tarea, su nota en la fila de C9 de `docs/boost/plans/PROGRESS.md`, en la misma rama.

**Cómo aplicar los parches:** guarda cada bloque `diff` en un fichero fuera del repo y ejecuta `git apply --check <fichero> && git apply <fichero>` desde la raíz. Si `--check` falla, para y aplica el mismo cambio a mano. Nunca `dart format` sobre carpetas enteras: los parches ya están formateados con `--line-length 120`.

---

### Task TC9.1: Medir el umbral del HUD con la fuente real

**Files:**
- Create: `test/helpers/roboto_font.dart`
- Modify: `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart:21-26` (import y `setUpAll`) y antes de la línea 330 (test nuevo)

**Interfaces:**
- Consumes: `HudOverlay.buttonsBelowWidth` (920), `HudDataMock.withEveryResourceAndTool`, `Internationalize.forestQuests`.
- Produces: `Future<void> loadRobotoFont()` en `test/helpers/roboto_font.dart`; el test `testWhenEveryResourceShowsFourDigitsThenTheBreakpointLeavesRoomForTheButtonsBesideTheBar`, que TC9.2 pone en rojo.

- [ ] **Step 1: El ayudante y el test de medida**

```diff
diff --git a/test/helpers/roboto_font.dart b/test/helpers/roboto_font.dart
new file mode 100644
index 0000000..bc46594
--- /dev/null
+++ b/test/helpers/roboto_font.dart
@@ -0,0 +1,14 @@
+import 'dart:io';
+
+import 'package:flutter/services.dart';
+
+Future<void> loadRobotoFont() async {
+  final root = Platform.environment['FLUTTER_ROOT'];
+  if (root == null) throw StateError('FLUTTER_ROOT is not set: run the tests with flutter test');
+  final loader = FontLoader('Roboto');
+  for (final weight in const ['Regular', 'Medium', 'Bold']) {
+    final file = File('$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf');
+    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
+  }
+  await loader.load();
+}
diff --git a/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart b/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
index 5221768..87ee96c 100644
--- a/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
+++ b/test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
@@ -19,11 +19,15 @@ import 'package:farming/layers/presentation/features/forest/widgets/resource_bar
 import 'package:farming/layers/presentation/features/forest/widgets/skill_tile.dart';
 
 import '../../../../../helpers/hud_test_app.dart';
+import '../../../../../helpers/roboto_font.dart';
 import '../../../../../helpers/spanish_translations.dart';
 import '../../../../../mocks/presentation/features/forest/hud_data_mock.dart';
 
 void main() {
-  setUpAll(loadSpanishTranslations);
+  setUpAll(() async {
+    loadSpanishTranslations();
+    await loadRobotoFont();
+  });
 
   Future<List<BlueprintId>> pumpOverlay(
     WidgetTester tester,
@@ -327,6 +331,32 @@ void main() {
     expect(panel.bottom, lessThanOrEqualTo(360));
   });
 
+  testWidgets('testWhenEveryResourceShowsFourDigitsThenTheBreakpointLeavesRoomForTheButtonsBesideTheBar', (
+    tester,
+  ) async {
+    // given
+    const margin = 12.0;
+    const gap = 8.0;
+    const slack = 24.0;
+    tester.view.physicalSize = const Size(HudOverlay.buttonsBelowWidth, 720);
+    tester.view.devicePixelRatio = 1;
+    addTearDown(tester.view.reset);
+
+    // when
+    await pumpOverlay(tester, HudDataMock.withEveryResourceAndTool);
+
+    // then
+    final bar = tester.getSize(find.byType(ResourceBar)).width;
+    final buttons = tester
+        .getSize(
+          find
+              .ancestor(of: find.widgetWithText(HudButton, Internationalize.forestQuests), matching: find.byType(Row))
+              .first,
+        )
+        .width;
+    expect(margin + bar + gap + buttons + margin + slack, lessThanOrEqualTo(HudOverlay.buttonsBelowWidth));
+  });
+
   testWidgets('testWhenTheScreenIsJustBelowTheBreakpointThenTheButtonsGoUnderTheResourceBar', (tester) async {
     // given
     tester.view.physicalSize = const Size(HudOverlay.buttonsBelowWidth - 1, 720);
```

La fila de botones es el primer `Row` por encima de *Misiones* (el `_buttonRow` de `HudOverlay`); en la rama ancha nada la escala (`FittedBox` con sitio de sobra), así que `getSize` da su ancho natural.

- [ ] **Step 2: Comprobar la medida**

Run: `flutter test test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`
Expected: `+24: All tests passed!`. Con dos recursos, 12 + 372,1 + 8 + 470,5 + 12 + 24 = 898,6 ≤ 920: el test pasa ya (fija la regla; se pone en rojo en TC9.2). Si quieres ver las cifras, un `print` temporal de `bar` y `buttons` da `372.095703125` y `470.52978515625`; quítalo antes de seguir.

- [ ] **Step 3: Comprobar todo**

```bash
dart format --line-length 120 test/helpers/roboto_font.dart test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
flutter analyze
flutter test
```

Expected: `Formatted 2 files (0 changed)`; `No issues found!`; `+659: All tests passed!`.

- [ ] **Step 4: Commit**

```bash
git add test/helpers/roboto_font.dart test/layers/presentation/features/forest/widgets/hud_overlay_test.dart docs/boost/plans/PROGRESS.md
git commit -m "[PROJECT-C9]: Measure the HUD breakpoint with the real font"
```

---

### Task TC9.2: El maná como recurso

**Files:**
- Modify: `lib/core/config/constants/enum/resource.dart:1`
- Modify: `lib/core/assets/i18n/translations/es.json:33,40` (`forest.resource.mana`, `forest.amount.mana`)
- Modify: `lib/core/assets/i18n/internationalize.dart:45,56`
- Create: `lib/core/assets/images/icons/mana.svg` (copia exacta del de iOS)
- Modify: `lib/layers/presentation/theme/images/custom_icons.dart:8,16`
- Modify: `lib/layers/presentation/features/forest/widgets/hud_overlay.dart:19`
- Modify: `test/mocks/presentation/features/forest/resource_item_data_mock.dart` (`mana`)
- Test: `test/core/assets/i18n/internationalize_test.dart`, `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart:158`; `custom_icons_test.dart` y `testWhenNamingEveryResourceAndToolThenNoneFallsBackToItsKey` ya recorren `Resource.values`

**Interfaces:**
- Consumes: `loadRobotoFont()` y el test de medida (TC9.1).
- Produces: `enum Resource { wood, gold, mana }`; `Internationalize.forestResource(resource: Resource.mana)` → `Maná`, `forestAmount(resource: Resource.mana, amount: n)` → `n de maná`; `CustomIcons.mana` (`lib/core/assets/images/icons/mana.svg`); `ResourceItemDataMock.mana(int)`; `HudOverlay.buttonsBelowWidth == 1030`.

- [ ] **Step 1: Write the failing tests**

```diff
diff --git a/test/core/assets/i18n/internationalize_test.dart b/test/core/assets/i18n/internationalize_test.dart
index 80e6a01..9261c34 100644
--- a/test/core/assets/i18n/internationalize_test.dart
+++ b/test/core/assets/i18n/internationalize_test.dart
@@ -24,6 +24,7 @@ void main() {
 
     // when
     final cost = Internationalize.forestAmount(resource: Resource.wood, amount: amount);
+    final mana = Internationalize.forestAmount(resource: Resource.mana, amount: 20);
     final missing = Internationalize.forestMissing(
       amounts: Internationalize.forestAmount(resource: Resource.wood, amount: 5),
     );
@@ -31,6 +32,7 @@ void main() {
 
     // then
     expect(cost, '15 de madera');
+    expect(mana, '20 de maná');
     expect(missing, 'Faltan 5 de madera');
     expect(gained, '+6 de madera');
   });
@@ -101,6 +103,7 @@ void main() {
     final texts = [
       Internationalize.forestResource(resource: Resource.wood),
       Internationalize.forestResource(resource: Resource.gold),
+      Internationalize.forestResource(resource: Resource.mana),
       Internationalize.forestTool(tool: ToolKind.axe),
       Internationalize.forestBuild,
       Internationalize.forestQuests,
@@ -127,6 +130,7 @@ void main() {
     expect(texts, [
       'Madera',
       'Oro',
+      'Maná',
       'Hacha',
       'Construir',
       'Misiones',
diff --git a/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart b/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
index 0ee98a9..a23c23a 100644
--- a/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
+++ b/test/layers/presentation/features/forest/bloc/forest_bloc_test.dart
@@ -155,7 +155,11 @@ void main() {
         expect((pose as WorkPose).tool, WorkTool.axe);
         expect(effects.whereType<TreeHitEffect>().length, 5);
         expect(effects, contains(ForestEffectMock.treeFelled));
-        expect(bloc.state.data.hud!.resources, [ResourceItemDataMock.wood(6), ResourceItemDataMock.gold(0)]);
+        expect(bloc.state.data.hud!.resources, [
+          ResourceItemDataMock.wood(6),
+          ResourceItemDataMock.gold(0),
+          ResourceItemDataMock.mana(0),
+        ]);
       },
     );
   });
diff --git a/test/mocks/presentation/features/forest/resource_item_data_mock.dart b/test/mocks/presentation/features/forest/resource_item_data_mock.dart
index 8306698..02940bf 100644
--- a/test/mocks/presentation/features/forest/resource_item_data_mock.dart
+++ b/test/mocks/presentation/features/forest/resource_item_data_mock.dart
@@ -15,6 +15,12 @@ abstract final class ResourceItemDataMock {
     amount: amount,
   );
 
+  static ResourceItemData mana(int amount) => ResourceItemData(
+    resource: Resource.mana,
+    name: Internationalize.forestResource(resource: Resource.mana),
+    amount: amount,
+  );
+
   static ResourceItemData of(Resource resource, int amount) => ResourceItemData(
     resource: resource,
     name: Internationalize.forestResource(resource: resource),
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`
Expected: FAIL de compilación: `Error: Member not found: 'mana'.`

- [ ] **Step 3: El recurso, sus textos y su icono**

```diff
diff --git a/lib/core/assets/i18n/internationalize.dart b/lib/core/assets/i18n/internationalize.dart
index d8d571e..c801503 100644
--- a/lib/core/assets/i18n/internationalize.dart
+++ b/lib/core/assets/i18n/internationalize.dart
@@ -43,6 +43,7 @@ class Internationalize {
   static String forestResource({required Resource resource}) => switch (resource) {
     Resource.wood => '$_forest.resource.wood'.tr(),
     Resource.gold => '$_forest.resource.gold'.tr(),
+    Resource.mana => '$_forest.resource.mana'.tr(),
   };
   static String forestTool({required ToolKind tool}) => switch (tool) {
     ToolKind.axe => '$_forest.tool.axe'.tr(),
@@ -54,6 +55,7 @@ class Internationalize {
   static String forestAmount({required Resource resource, required int amount}) => switch (resource) {
     Resource.wood => '$_forest.amount.wood'.tr(namedArgs: {'amount': '$amount'}),
     Resource.gold => '$_forest.amount.gold'.tr(namedArgs: {'amount': '$amount'}),
+    Resource.mana => '$_forest.amount.mana'.tr(namedArgs: {'amount': '$amount'}),
   };
   static String forestMissing({required String amounts}) => '$_forest.hud.missing'.tr(namedArgs: {'amounts': amounts});
   static String forestBlueprint({required BlueprintId id}) => switch (id) {
diff --git a/lib/core/assets/i18n/translations/es.json b/lib/core/assets/i18n/translations/es.json
index 42ed929..ac43dc0 100644
--- a/lib/core/assets/i18n/translations/es.json
+++ b/lib/core/assets/i18n/translations/es.json
@@ -30,14 +30,16 @@
     },
     "resource": {
       "wood": "Madera",
-      "gold": "Oro"
+      "gold": "Oro",
+      "mana": "Maná"
     },
     "tool": {
       "axe": "Hacha"
     },
     "amount": {
       "wood": "{amount} de madera",
-      "gold": "{amount} de oro"
+      "gold": "{amount} de oro",
+      "mana": "{amount} de maná"
     },
     "blueprint": {
       "house": "Casa",
diff --git a/lib/core/assets/images/icons/mana.svg b/lib/core/assets/images/icons/mana.svg
new file mode 100644
index 0000000..556e8c7
--- /dev/null
+++ b/lib/core/assets/images/icons/mana.svg
@@ -0,0 +1,5 @@
+<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
+  <path d="M11 1L18 9L11 21L4 9Z" fill="#2F5FB3"/>
+  <path d="M11 1L18 9L11 12L4 9Z" fill="#5C8EE6"/>
+  <path d="M11 3.5L15 9L11 10.5L7 9Z" fill="#A9C8FF"/>
+</svg>
diff --git a/lib/core/config/constants/enum/resource.dart b/lib/core/config/constants/enum/resource.dart
index f84df04..b77b13a 100644
--- a/lib/core/config/constants/enum/resource.dart
+++ b/lib/core/config/constants/enum/resource.dart
@@ -1 +1 @@
-enum Resource { wood, gold }
+enum Resource { wood, gold, mana }
diff --git a/lib/layers/presentation/theme/images/custom_icons.dart b/lib/layers/presentation/theme/images/custom_icons.dart
index ff1be7e..dd45a20 100644
--- a/lib/layers/presentation/theme/images/custom_icons.dart
+++ b/lib/layers/presentation/theme/images/custom_icons.dart
@@ -6,6 +6,7 @@ abstract final class CustomIcons {
 
   static const String wood = '$_path/wood.svg';
   static const String gold = '$_path/gold.svg';
+  static const String mana = '$_path/mana.svg';
   static const String axe = '$_path/axe.svg';
   static const String hero = '$_path/hero.svg';
   static const String arena = '$_path/arena.svg';
@@ -14,6 +15,7 @@ abstract final class CustomIcons {
   static String resource(Resource resource) => switch (resource) {
     Resource.wood => wood,
     Resource.gold => gold,
+    Resource.mana => mana,
   };
 
   static String tool(ToolKind tool) => switch (tool) {
```

`mana.svg` es el de `$IOS/Farming/Assets.xcassets/Icons/mana.imageset/mana.svg` sin tocar (`cmp` sin salida); diseño propio, sin entrada en `CREDITS.md`. La barra lo pinta a 22 × 14 (como el oro), así que el rombo queda a 14 × 14.

- [ ] **Step 4: Ver el umbral en rojo**

```bash
dart format --line-length 120 lib/core/config/constants/enum/resource.dart lib/core/assets/i18n/internationalize.dart lib/layers/presentation/theme/images/custom_icons.dart test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/mocks/presentation/features/forest/resource_item_data_mock.dart
flutter test
```

Expected: `Formatted 6 files (0 changed)`; `+658 -1: Some tests failed.`: solo `testWhenEveryResourceShowsFourDigitsThenTheBreakpointLeavesRoomForTheButtonsBesideTheBar`, con `Expected: a value less than or equal to <920.0>` / `Actual: <1025.55859375>`. Los tests de 640 px pasan gracias a Roboto (TC9.1).

- [ ] **Step 5: Subir el umbral**

```diff
diff --git a/lib/layers/presentation/features/forest/widgets/hud_overlay.dart b/lib/layers/presentation/features/forest/widgets/hud_overlay.dart
index 88f1f29..3cb6ea0 100644
--- a/lib/layers/presentation/features/forest/widgets/hud_overlay.dart
+++ b/lib/layers/presentation/features/forest/widgets/hud_overlay.dart
@@ -16,7 +16,7 @@ import 'resource_bar.dart';
 
 class HudOverlay extends StatefulWidget {
   static const double narrowWidth = 480;
-  static const double buttonsBelowWidth = 920;
+  static const double buttonsBelowWidth = 1030;
   static const double _margin = 12;
 
   final HudData hud;
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
flutter analyze
flutter test
```

Expected: `No issues found!`; `+659: All tests passed!`.

- [ ] **Step 7: Commit**

```bash
git add lib/core test/core lib/layers/presentation/theme/images/custom_icons.dart lib/layers/presentation/features/forest/widgets/hud_overlay.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/mocks/presentation/features/forest/resource_item_data_mock.dart docs/boost/plans/PROGRESS.md
git commit -m "[PROJECT-C9]: Add mana as a resource"
```

---

### Task TC9.3: Maná en la arena y en las habilidades

**Files:**
- Modify: `lib/layers/domain/rules/arena_levels.dart:73,83,101,115,133`
- Modify: `lib/layers/domain/rules/skills.dart:9-13`
- Modify (mocks): `test/mocks/domain/world/funds_mock.dart`, `test/mocks/domain/entities/hero/skill_entity_mock.dart`, `test/mocks/domain/entities/hero/skill_option_entity_mock.dart`, `test/mocks/domain/entities/hero/hero_entity_mock.dart` (`banditTrioCleared`), `test/mocks/presentation/features/forest/skill_item_data_mock.dart`
- Test: `test/layers/domain/combat/balance_test.dart`, `test/layers/domain/rules/arena_levels_test.dart`, `test/layers/domain/rules/skills_test.dart`, `test/layers/domain/world/extensions/arena_rules_test.dart`, `test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart`, `test/layers/domain/use-cases/hero/get_skill_options_use_case_test.dart`

**Interfaces:**
- Consumes: `Resource.mana` (TC9.2); `ArenaRules.rewardFor(ArenaLevelEntity)`, `Rules.repeatRewardDivisor` (3), `LearnSkillResult.notEnoughResources`, `SkillScenarioMock.withTower({funds, hero})`.
- Produces:
  - `ArenaLevels.all[5..9].reward == {gold: 75 | 90 | 100 | 120 | 150, mana: 20 | 25 | 30 | 35 | 50}`; los niveles 1–5 sin cambios;
  - `Skills.doubleStrike.cost == {gold: 60, mana: 20}`, `dodge == {gold: 90, mana: 30}`, `secondWind == {gold: 130, mana: 45}`;
  - mocks `FundsMock.doubleStrikePrice` (60 + 20), `tenGoldShortOfDoubleStrike` (50 + 20), `doubleStrikeGoldWithoutMana` (60), `banditTrioReward` (75 + 20), `banditTrioRepeatReward` (25 + 6); `HeroEntityMock.banditTrioCleared`; `SkillOptionEntityMock.doubleStrikeTwentyManaShort`; `SkillItemDataMock.unaffordable(SkillId, {required int missingGold, required int missingMana})`.

- [ ] **Step 1: Write the failing tests**

```diff
diff --git a/test/layers/domain/combat/balance_test.dart b/test/layers/domain/combat/balance_test.dart
index acbe434..7afdc38 100644
--- a/test/layers/domain/combat/balance_test.dart
+++ b/test/layers/domain/combat/balance_test.dart
@@ -22,19 +22,21 @@ double _winRate(ArenaLevelEntity level, HeroEntity hero) {
   return wins / BalanceScenarioMock.seeds;
 }
 
-int _gold(Map<Resource, int> cost) => cost[Resource.gold] ?? 0;
+const _arenaResources = [Resource.gold, Resource.mana];
 
-int _goldSpentOn(HeroEntity hero) {
+int _amount(Map<Resource, int> amounts, Resource resource) => amounts[resource] ?? 0;
+
+int _spentOn(HeroEntity hero, Resource resource) {
   var total = 0;
   for (final slot in GearSlot.values) {
     for (var tier = 1; tier <= hero.tierOf(slot); tier++) {
-      total += _gold(Gear.of(slot, tier).cost);
+      total += _amount(Gear.of(slot, tier).cost, resource);
     }
   }
   for (final skill in hero.skills) {
-    total += _gold(Skills.byId(skill).cost);
+    total += _amount(Skills.byId(skill).cost, resource);
   }
-  if (hero.skills.isNotEmpty) total += _gold(Blueprints.of(Skills.building).cost);
+  if (hero.skills.isNotEmpty) total += _amount(Blueprints.of(Skills.building).cost, resource);
   return total;
 }
 
@@ -91,18 +93,25 @@ void main() {
     }
   });
 
-  test('testWhenEveryEarlierLevelIsWonOnceAndTheLastOneRepeatedThenTheExpectedGearIsAffordable', () {
+  test('testWhenEveryEarlierLevelIsWonOnceAndTheLastOneRepeatedThenTheExpectedGearIsAffordableInEveryResource', () {
     // given
-    var firstRewards = 0;
     final budgets = <(String, int, int)>[];
 
     // when
-    for (final (index, level) in levels.indexed) {
-      final repeats = index == 0
-          ? 0
-          : BalanceScenarioMock.maxRepeats * (_gold(levels[index - 1].reward) ~/ Rules.repeatRewardDivisor);
-      budgets.add((level.id.name, _goldSpentOn(_expectedHero(level)), firstRewards + repeats));
-      firstRewards += _gold(level.reward);
+    for (final resource in _arenaResources) {
+      var firstRewards = 0;
+      for (final (index, level) in levels.indexed) {
+        final repeats = index == 0
+            ? 0
+            : BalanceScenarioMock.maxRepeats *
+                  (_amount(levels[index - 1].reward, resource) ~/ Rules.repeatRewardDivisor);
+        budgets.add((
+          '${resource.name} ${level.id.name}',
+          _spentOn(_expectedHero(level), resource),
+          firstRewards + repeats,
+        ));
+        firstRewards += _amount(level.reward, resource);
+      }
     }
 
     // then
@@ -110,4 +119,16 @@ void main() {
       expect(spent, lessThanOrEqualTo(earned), reason: '$name: gear and skills cost $spent, the arena paid $earned');
     }
   });
+
+  test('testWhenEveryLevelIsWonOnceThenTheManaPaysForEverySkill', () {
+    // given
+    const skills = Skills.all;
+
+    // when
+    final earned = levels.fold(0, (total, level) => total + _amount(level.reward, Resource.mana));
+    final cost = skills.fold(0, (total, skill) => total + _amount(skill.cost, Resource.mana));
+
+    // then
+    expect((earned, cost), (160, 95));
+  });
 }
diff --git a/test/layers/domain/rules/arena_levels_test.dart b/test/layers/domain/rules/arena_levels_test.dart
index 5710355..95d18e8 100644
--- a/test/layers/domain/rules/arena_levels_test.dart
+++ b/test/layers/domain/rules/arena_levels_test.dart
@@ -43,6 +43,17 @@ void main() {
     }
   });
 
+  test('testWhenListingLevelsThenOnlyTheSecondHalfAlsoPaysMana', () {
+    // given
+    final levels = ArenaLevels.all;
+
+    // when
+    final mana = levels.map((level) => level.reward[Resource.mana] ?? 0);
+
+    // then
+    expect(mana, [0, 0, 0, 0, 0, 20, 25, 30, 35, 50]);
+  });
+
   test('testWhenListingLevelsThenTheRookieBanditOpensTheArena', () {
     // given
     final levels = ArenaLevels.all;
diff --git a/test/layers/domain/rules/skills_test.dart b/test/layers/domain/rules/skills_test.dart
index 5552765..261ae80 100644
--- a/test/layers/domain/rules/skills_test.dart
+++ b/test/layers/domain/rules/skills_test.dart
@@ -19,17 +19,17 @@ void main() {
     expect(unique, SkillId.values.toSet());
   });
 
-  test('testWhenAskingForEachSkillThenItCostsOnlyGoldFromCheapestToDearest', () {
+  test('testWhenAskingForEachSkillThenItCostsGoldAndManaFromCheapestToDearest', () {
     // given
     final ids = [SkillId.doubleStrike, SkillId.dodge, SkillId.secondWind];
 
     // when
     final skills = ids.map(Skills.byId).toList();
-    final prices = Skills.all.map((skill) => skill.cost[Resource.gold]).toList();
+    final prices = Skills.all.map((skill) => (skill.cost[Resource.gold], skill.cost[Resource.mana])).toList();
 
     // then
     expect(skills, [SkillEntityMock.doubleStrike, SkillEntityMock.dodge, SkillEntityMock.secondWind]);
-    expect(prices, [60, 90, 130]);
+    expect(prices, [(60, 20), (90, 30), (130, 45)]);
   });
 
   test('testWhenAskingWhereSkillsAreLearnedThenItIsTheMageTower', () {
diff --git a/test/layers/domain/use-cases/hero/get_skill_options_use_case_test.dart b/test/layers/domain/use-cases/hero/get_skill_options_use_case_test.dart
index 04cb8e3..ccb457f 100644
--- a/test/layers/domain/use-cases/hero/get_skill_options_use_case_test.dart
+++ b/test/layers/domain/use-cases/hero/get_skill_options_use_case_test.dart
@@ -69,6 +69,17 @@ void main() {
     expect(options.first, SkillOptionEntityMock.doubleStrikeTenGoldShort);
   });
 
+  test('testWhenOnlyManaIsShortThenTheSkillSaysOnlyTheManaIsMissing', () {
+    // given
+    playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikeGoldWithoutMana));
+
+    // when
+    final options = sut();
+
+    // then
+    expect(options.first, SkillOptionEntityMock.doubleStrikeTwentyManaShort);
+  });
+
   test('testWhenTheHeroKnowsASkillThenItIsListedAsKnownWithNothingMissing', () {
     // given
     playing(SkillScenarioMock.withTower(hero: HeroEntityMock.withDoubleStrike));
diff --git a/test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart b/test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart
index 1cd7719..04bba67 100644
--- a/test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart
+++ b/test/layers/domain/use-cases/hero/learn_skill_use_case_test.dart
@@ -80,6 +80,20 @@ void main() {
     expect(world.funds.amount(Resource.gold), 50);
   });
 
+  test('testWhenThereIsEnoughGoldButNoManaThenNothingIsPaidOrLearned', () {
+    // given
+    final world = playing(SkillScenarioMock.withTower(funds: FundsMock.doubleStrikeGoldWithoutMana));
+
+    // when
+    final result = sut(id: SkillId.doubleStrike);
+
+    // then
+    expect(result, LearnSkillResult.notEnoughResources);
+    expect(world.hero, HeroEntityMock.mock);
+    expect(world.funds.amount(Resource.gold), 60);
+    expect(world.funds.amount(Resource.mana), 0);
+  });
+
   test('testWhenSeveralChecksFailThenTheyAreReportedInOrder', () {
     // given
     playing(SkillScenarioMock.withoutTower(hero: HeroEntityMock.withDoubleStrike));
@@ -107,5 +121,6 @@ void main() {
     expect(world.hero, HeroEntityMock.withDoubleStrike);
     expect((powerBefore, world.hero.power), (31, 34));
     expect(world.funds.amount(Resource.gold), 0);
+    expect(world.funds.amount(Resource.mana), 0);
   });
 }
diff --git a/test/layers/domain/world/extensions/arena_rules_test.dart b/test/layers/domain/world/extensions/arena_rules_test.dart
index 4a4380d..e4cbb99 100644
--- a/test/layers/domain/world/extensions/arena_rules_test.dart
+++ b/test/layers/domain/world/extensions/arena_rules_test.dart
@@ -110,6 +110,19 @@ void main() {
       // then
       expect(reward, FundsMock.threeGold);
     });
+
+    test('testWhenTheThreeBanditsAreWonThenTheFirstRewardIsGoldAndManaAndARepeatPaysAThirdOfEach', () {
+      // given
+      final level = ArenaLevels.byId(ArenaLevelId.banditTrio);
+
+      // when
+      final first = HeroEntityMock.mock.rewardFor(level);
+      final repeat = HeroEntityMock.banditTrioCleared.rewardFor(level);
+
+      // then
+      expect(first, FundsMock.banditTrioReward);
+      expect(repeat, FundsMock.banditTrioRepeatReward);
+    });
   });
 
   group('afterFight', () {
diff --git a/test/mocks/domain/entities/hero/hero_entity_mock.dart b/test/mocks/domain/entities/hero/hero_entity_mock.dart
index b2eb2d1..62ee0e7 100644
--- a/test/mocks/domain/entities/hero/hero_entity_mock.dart
+++ b/test/mocks/domain/entities/hero/hero_entity_mock.dart
@@ -57,6 +57,8 @@ abstract final class HeroEntityMock {
     fightsFought: 2,
   );
 
+  static const HeroEntity banditTrioCleared = HeroEntity(clearedLevels: {ArenaLevelId.banditTrio});
+
   static const HeroEntity packHunter = HeroEntity(
     weaponTier: 3,
     armorTier: 3,
diff --git a/test/mocks/domain/entities/hero/skill_entity_mock.dart b/test/mocks/domain/entities/hero/skill_entity_mock.dart
index fca1ebc..de5a945 100644
--- a/test/mocks/domain/entities/hero/skill_entity_mock.dart
+++ b/test/mocks/domain/entities/hero/skill_entity_mock.dart
@@ -3,9 +3,15 @@ import 'package:farming/core/config/constants/enum/skill_id.dart';
 import 'package:farming/layers/domain/entities/hero/skill_entity.dart';
 
 abstract final class SkillEntityMock {
-  static const SkillEntity doubleStrike = SkillEntity(id: SkillId.doubleStrike, cost: {Resource.gold: 60});
+  static const SkillEntity doubleStrike = SkillEntity(
+    id: SkillId.doubleStrike,
+    cost: {Resource.gold: 60, Resource.mana: 20},
+  );
 
-  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90});
+  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90, Resource.mana: 30});
 
-  static const SkillEntity secondWind = SkillEntity(id: SkillId.secondWind, cost: {Resource.gold: 130});
+  static const SkillEntity secondWind = SkillEntity(
+    id: SkillId.secondWind,
+    cost: {Resource.gold: 130, Resource.mana: 45},
+  );
 }
diff --git a/test/mocks/domain/entities/hero/skill_option_entity_mock.dart b/test/mocks/domain/entities/hero/skill_option_entity_mock.dart
index 953dd9f..3717863 100644
--- a/test/mocks/domain/entities/hero/skill_option_entity_mock.dart
+++ b/test/mocks/domain/entities/hero/skill_option_entity_mock.dart
@@ -19,6 +19,9 @@ abstract final class SkillOptionEntityMock {
   static SkillOptionEntity get doubleStrikeTenGoldShort =>
       make(SkillId.doubleStrike, SkillOptionState.unaffordable, missing: {Resource.gold: 10});
 
+  static SkillOptionEntity get doubleStrikeTwentyManaShort =>
+      make(SkillId.doubleStrike, SkillOptionState.unaffordable, missing: {Resource.mana: 20});
+
   static List<SkillOptionEntity> get newHeroWithoutTower => [
     make(SkillId.doubleStrike, SkillOptionState.needsBuilding),
     make(SkillId.dodge, SkillOptionState.needsBuilding),
@@ -27,8 +30,8 @@ abstract final class SkillOptionEntityMock {
 
   static List<SkillOptionEntity> get readyToLearnDoubleStrike => [
     doubleStrikeAvailable,
-    make(SkillId.dodge, SkillOptionState.unaffordable, missing: {Resource.gold: 30}),
-    make(SkillId.secondWind, SkillOptionState.unaffordable, missing: {Resource.gold: 70}),
+    make(SkillId.dodge, SkillOptionState.unaffordable, missing: {Resource.gold: 30, Resource.mana: 10}),
+    make(SkillId.secondWind, SkillOptionState.unaffordable, missing: {Resource.gold: 70, Resource.mana: 25}),
   ];
 
   static List<SkillOptionEntity> get afterLearningDoubleStrike => [
diff --git a/test/mocks/domain/world/funds_mock.dart b/test/mocks/domain/world/funds_mock.dart
index f0be82e..b15116a 100644
--- a/test/mocks/domain/world/funds_mock.dart
+++ b/test/mocks/domain/world/funds_mock.dart
@@ -19,7 +19,13 @@ abstract final class FundsMock {
 
   static const Map<Resource, int> fiveGoldShortOfShortSword = {Resource.gold: 25};
 
-  static const Map<Resource, int> doubleStrikePrice = {Resource.gold: 60};
+  static const Map<Resource, int> doubleStrikePrice = {Resource.gold: 60, Resource.mana: 20};
 
-  static const Map<Resource, int> tenGoldShortOfDoubleStrike = {Resource.gold: 50};
+  static const Map<Resource, int> tenGoldShortOfDoubleStrike = {Resource.gold: 50, Resource.mana: 20};
+
+  static const Map<Resource, int> doubleStrikeGoldWithoutMana = {Resource.gold: 60};
+
+  static const Map<Resource, int> banditTrioReward = {Resource.gold: 75, Resource.mana: 20};
+
+  static const Map<Resource, int> banditTrioRepeatReward = {Resource.gold: 25, Resource.mana: 6};
 }
diff --git a/test/mocks/presentation/features/forest/skill_item_data_mock.dart b/test/mocks/presentation/features/forest/skill_item_data_mock.dart
index 6349144..7aa53f9 100644
--- a/test/mocks/presentation/features/forest/skill_item_data_mock.dart
+++ b/test/mocks/presentation/features/forest/skill_item_data_mock.dart
@@ -13,10 +13,10 @@ abstract final class SkillItemDataMock {
     canLearn: false,
   );
 
-  static SkillItemData unaffordable(SkillId id, {required int missingGold}) => _make(
+  static SkillItemData unaffordable(SkillId id, {required int missingGold, required int missingMana}) => _make(
     id,
     reasonText: Internationalize.forestMissing(
-      amounts: Internationalize.forestAmount(resource: Resource.gold, amount: missingGold),
+      amounts: _amounts(gold: missingGold, mana: missingMana),
     ),
     canLearn: false,
   );
@@ -39,29 +39,34 @@ abstract final class SkillItemDataMock {
 
   static List<SkillItemData> get readyToLearnDoubleStrike => [
     doubleStrikeAvailable,
-    unaffordable(SkillId.dodge, missingGold: 30),
-    unaffordable(SkillId.secondWind, missingGold: 70),
+    unaffordable(SkillId.dodge, missingGold: 30, missingMana: 10),
+    unaffordable(SkillId.secondWind, missingGold: 70, missingMana: 25),
   ];
 
   static List<SkillItemData> get afterLearningDoubleStrike => [
     doubleStrikeKnown,
-    unaffordable(SkillId.dodge, missingGold: 90),
-    unaffordable(SkillId.secondWind, missingGold: 130),
+    unaffordable(SkillId.dodge, missingGold: 90, missingMana: 30),
+    unaffordable(SkillId.secondWind, missingGold: 130, missingMana: 45),
   ];
 
   static SkillItemData _make(SkillId id, {required String? reasonText, required bool canLearn}) => SkillItemData(
     id: id,
     name: Internationalize.forestSkillName(id: id),
     description: Internationalize.forestSkillDescription(id: id),
-    costText: Internationalize.forestAmount(resource: Resource.gold, amount: _price(id)),
+    costText: _amounts(gold: _price(id).gold, mana: _price(id).mana),
     reasonText: reasonText,
     isKnown: false,
     canLearn: canLearn,
   );
 
-  static int _price(SkillId id) => switch (id) {
-    SkillId.doubleStrike => 60,
-    SkillId.secondWind => 130,
-    SkillId.dodge => 90,
+  static ({int gold, int mana}) _price(SkillId id) => switch (id) {
+    SkillId.doubleStrike => (gold: 60, mana: 20),
+    SkillId.secondWind => (gold: 130, mana: 45),
+    SkillId.dodge => (gold: 90, mana: 30),
   };
+
+  static String _amounts({required int gold, required int mana}) => [
+    Internationalize.forestAmount(resource: Resource.gold, amount: gold),
+    Internationalize.forestAmount(resource: Resource.mana, amount: mana),
+  ].join(', ');
 }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/layers/domain test/layers/presentation/features/forest/bloc`
Expected: `-13: Some tests failed.`: los cinco nuevos (`testWhenEveryLevelIsWonOnceThenTheManaPaysForEverySkill`, `testWhenTheThreeBanditsAreWonThenTheFirstRewardIsGoldAndManaAndARepeatPaysAThirdOfEach`, `testWhenThereIsEnoughGoldButNoManaThenNothingIsPaidOrLearned`, `testWhenOnlyManaIsShortThenTheSkillSaysOnlyTheManaIsMissing`, `testWhenListingLevelsThenOnlyTheSecondHalfAlsoPaysMana`), `testWhenAskingForEachSkillThenItCostsGoldAndManaFromCheapestToDearest`, `testWhenEverythingIsInPlaceThenPaysLearnsTheSkillAndRaisesPower`, `testWhenTheTowerIsBuiltAndTheDoubleStrikeIsPaidForThenOnlyItIsAvailable`, tres de `forest_bloc_skill_test.dart` y dos de `forest_bloc_hero_test.dart` (los mocks ya cuentan con el maná y el catálogo todavía no). El test de equilibrado por recurso pasa ya: sin maná en el catálogo no hay nada que pagar.

- [ ] **Step 3: Los catálogos**

```diff
diff --git a/lib/layers/domain/rules/arena_levels.dart b/lib/layers/domain/rules/arena_levels.dart
index 93ce2c9..2bde734 100644
--- a/lib/layers/domain/rules/arena_levels.dart
+++ b/lib/layers/domain/rules/arena_levels.dart
@@ -70,7 +70,7 @@ abstract final class ArenaLevels {
           stats: CombatStatsEntity(attackMin: 7, attackMax: 9, defense: 1, health: 26),
         ),
       ],
-      reward: {Resource.gold: 75},
+      reward: {Resource.gold: 75, Resource.mana: 20},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarian,
@@ -80,7 +80,7 @@ abstract final class ArenaLevels {
           stats: CombatStatsEntity(attackMin: 10, attackMax: 14, defense: 4, health: 58),
         ),
       ],
-      reward: {Resource.gold: 90},
+      reward: {Resource.gold: 90, Resource.mana: 25},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.wolfPack,
@@ -98,7 +98,7 @@ abstract final class ArenaLevels {
           stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 1, health: 22),
         ),
       ],
-      reward: {Resource.gold: 100},
+      reward: {Resource.gold: 100, Resource.mana: 30},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarianPair,
@@ -112,7 +112,7 @@ abstract final class ArenaLevels {
           stats: CombatStatsEntity(attackMin: 8, attackMax: 12, defense: 4, health: 52),
         ),
       ],
-      reward: {Resource.gold: 120},
+      reward: {Resource.gold: 120, Resource.mana: 35},
     ),
     ArenaLevelEntity(
       id: ArenaLevelId.barbarianChief,
@@ -130,7 +130,7 @@ abstract final class ArenaLevels {
           stats: CombatStatsEntity(attackMin: 7, attackMax: 11, defense: 2, health: 31),
         ),
       ],
-      reward: {Resource.gold: 150},
+      reward: {Resource.gold: 150, Resource.mana: 50},
     ),
   ];
 
diff --git a/lib/layers/domain/rules/skills.dart b/lib/layers/domain/rules/skills.dart
index 9b0ea25..29d3393 100644
--- a/lib/layers/domain/rules/skills.dart
+++ b/lib/layers/domain/rules/skills.dart
@@ -6,11 +6,17 @@ import '../entities/hero/skill_entity.dart';
 abstract final class Skills {
   static const BlueprintId building = BlueprintId.mageTower;
 
-  static const SkillEntity doubleStrike = SkillEntity(id: SkillId.doubleStrike, cost: {Resource.gold: 60});
+  static const SkillEntity doubleStrike = SkillEntity(
+    id: SkillId.doubleStrike,
+    cost: {Resource.gold: 60, Resource.mana: 20},
+  );
 
-  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90});
+  static const SkillEntity dodge = SkillEntity(id: SkillId.dodge, cost: {Resource.gold: 90, Resource.mana: 30});
 
-  static const SkillEntity secondWind = SkillEntity(id: SkillId.secondWind, cost: {Resource.gold: 130});
+  static const SkillEntity secondWind = SkillEntity(
+    id: SkillId.secondWind,
+    cost: {Resource.gold: 130, Resource.mana: 45},
+  );
 
   static const List<SkillEntity> all = [doubleStrike, dodge, secondWind];
 
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter analyze
flutter test
```

Expected: `No issues found!`; `+664: All tests passed!`. Las tasas de victoria de `balance_test.dart` no cambian (el combate es el mismo); el presupuesto de maná es 20 ≤ 38, 50 ≤ 69, 50 ≤ 105 y 50 ≤ 143, como en iOS. Si el equilibrado falla, no sigas: compara las tablas con la ficha.

- [ ] **Step 5: Commit**

```bash
git add lib/layers/domain/rules test/layers/domain test/mocks/domain test/mocks/presentation/features/forest/skill_item_data_mock.dart docs/boost/plans/PROGRESS.md
git commit -m "[PROJECT-C9]: Pay mana in the arena and charge it for skills"
```

---

### Task TC9.4: La recompensa entera en la arena

**Files:**
- Modify: `lib/core/assets/i18n/translations/es.json:149` (`arena.reward`; 147 antes de TC9.2)
- Modify: `lib/core/assets/i18n/internationalize.dart:165` (`arenaReward`; 163 antes de TC9.2)
- Modify: `lib/layers/presentation/features/arena/bloc/arena_bloc.dart:16,221,252`
- Modify (mocks): `test/mocks/domain/world/funds_mock.dart`, `test/mocks/presentation/features/arena/arena_result_data_mock.dart`, `test/mocks/presentation/features/arena/arena_level_item_data_mock.dart`
- Test: `test/core/assets/i18n/internationalize_test.dart`, `test/layers/presentation/features/arena/bloc/arena_bloc_test.dart`, `test/layers/presentation/features/arena/arena_page_test.dart`, `test/layers/presentation/features/arena/widgets/result_panel_test.dart`

**Interfaces:**
- Consumes: `Resource.mana` y `forestAmount` (TC9.2); recompensas de los niveles 6–10 y `FundsMock.banditTrioReward` (TC9.3).
- Produces: `static String Internationalize.arenaReward({required Map<Resource, int> amounts})` con `es.json` `"reward": "+{amounts}"`; mocks `FundsMock.barbarianChiefReward` (150 + 50), `barbarianChiefRepeatReward` (50 + 16), `thirtyGold`, `tenGoldAndZeroMana`, `sixManaBeforeTwentyFiveGold`; `ArenaResultDataMock.championWithTheChiefReward` y `victoryWithTheChiefRepeatReward` (sustituyen a `championHundredFiftyGold` y `victoryFiftyGold`).

- [ ] **Step 1: Write the failing tests**

```diff
diff --git a/test/core/assets/i18n/internationalize_test.dart b/test/core/assets/i18n/internationalize_test.dart
index 9261c34..e20b8d1 100644
--- a/test/core/assets/i18n/internationalize_test.dart
+++ b/test/core/assets/i18n/internationalize_test.dart
@@ -14,6 +14,7 @@ import 'package:farming/core/config/constants/enum/skill_id.dart';
 import 'package:farming/core/config/constants/enum/tool_kind.dart';
 
 import '../../../helpers/spanish_translations.dart';
+import '../../../mocks/domain/world/funds_mock.dart';
 
 void main() {
   setUpAll(loadSpanishTranslations);
@@ -274,10 +275,10 @@ void main() {
 
   test('testWhenFormattingArenaNumbersThenUsesTheSpanishTexts', () {
     // given
-    const amount = 10;
+    const amounts = FundsMock.tenGold;
 
     // when
-    final reward = Internationalize.arenaReward(amount: amount);
+    final reward = Internationalize.arenaReward(amounts: amounts);
     final power = Internationalize.arenaPower(power: 19);
     final heroPower = Internationalize.arenaHeroPower(power: 31);
     final damage = Internationalize.arenaDamage(amount: 4);
@@ -293,6 +294,21 @@ void main() {
     expect(group, '3 × Bandido');
   });
 
+  test('testWhenFormattingAnArenaRewardThenListsEveryPositiveAmountInResourceOrder', () {
+    // given
+    const goldAndMana = FundsMock.banditTrioReward;
+
+    // when
+    final both = Internationalize.arenaReward(amounts: goldAndMana);
+    final withoutZeros = Internationalize.arenaReward(amounts: FundsMock.tenGoldAndZeroMana);
+    final reordered = Internationalize.arenaReward(amounts: FundsMock.sixManaBeforeTwentyFiveGold);
+
+    // then
+    expect(both, '+75 de oro, 20 de maná');
+    expect(withoutZeros, '+10 de oro');
+    expect(reordered, '+25 de oro, 6 de maná');
+  });
+
   test('testWhenNamingArenaLevelsEnemiesAndAdviceThenUsesTheSpanishTexts', () {
     // given
     // when
diff --git a/test/layers/presentation/features/arena/arena_page_test.dart b/test/layers/presentation/features/arena/arena_page_test.dart
index aca0c86..0c1027d 100644
--- a/test/layers/presentation/features/arena/arena_page_test.dart
+++ b/test/layers/presentation/features/arena/arena_page_test.dart
@@ -20,6 +20,7 @@ import '../../../../helpers/pump_until.dart';
 import '../../../../helpers/spanish_translations.dart';
 import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
 import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
+import '../../../../mocks/domain/world/funds_mock.dart';
 import '../../../../mocks/presentation/features/arena/arena_level_item_data_mock.dart';
 import '../../../../mocks/presentation/features/forest/forest_scenario_mock.dart';
 import '../../../../mocks/presentation/features/forest/game/asset_bundle_fake.dart';
@@ -80,7 +81,7 @@ void main() {
 
     // then
     expect(find.text(Internationalize.arenaVictory), findsOneWidget);
-    expect(find.text(Internationalize.arenaReward(amount: 10)), findsOneWidget);
+    expect(find.text(Internationalize.arenaReward(amounts: FundsMock.tenGold)), findsOneWidget);
     expect(find.text(Internationalize.arenaCleared), findsOneWidget);
   });
 
diff --git a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
index cc4a722..f7b01cc 100644
--- a/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
+++ b/test/layers/presentation/features/arena/bloc/arena_bloc_test.dart
@@ -363,7 +363,7 @@ void main() {
     verify: (bloc) {
       // then
       expect(effects, [ArenaEffectMock.won, ArenaEffectMock.champion]);
-      expect(bloc.state.data.result, ArenaResultDataMock.championHundredFiftyGold);
+      expect(bloc.state.data.result, ArenaResultDataMock.championWithTheChiefReward);
     },
   );
 
@@ -387,7 +387,7 @@ void main() {
     verify: (bloc) {
       // then
       expect(effects, [ArenaEffectMock.won]);
-      expect(bloc.state.data.result, ArenaResultDataMock.victoryFiftyGold);
+      expect(bloc.state.data.result, ArenaResultDataMock.victoryWithTheChiefRepeatReward);
     },
   );
 
diff --git a/test/layers/presentation/features/arena/widgets/result_panel_test.dart b/test/layers/presentation/features/arena/widgets/result_panel_test.dart
index c75472a..9a93bfe 100644
--- a/test/layers/presentation/features/arena/widgets/result_panel_test.dart
+++ b/test/layers/presentation/features/arena/widgets/result_panel_test.dart
@@ -5,6 +5,7 @@ import 'package:farming/layers/presentation/features/arena/widgets/result_panel.
 
 import '../../../../../helpers/hud_test_app.dart';
 import '../../../../../helpers/spanish_translations.dart';
+import '../../../../../mocks/domain/world/funds_mock.dart';
 import '../../../../../mocks/presentation/features/arena/arena_result_data_mock.dart';
 
 void main() {
@@ -23,7 +24,7 @@ void main() {
 
     // then
     expect(find.text(Internationalize.arenaVictory), findsOneWidget);
-    expect(find.text(Internationalize.arenaReward(amount: 10)), findsOneWidget);
+    expect(find.text(Internationalize.arenaReward(amounts: FundsMock.tenGold)), findsOneWidget);
     expect(find.text(Internationalize.arenaRetry), findsNothing);
   });
 
diff --git a/test/mocks/domain/world/funds_mock.dart b/test/mocks/domain/world/funds_mock.dart
index b15116a..9e1b2f7 100644
--- a/test/mocks/domain/world/funds_mock.dart
+++ b/test/mocks/domain/world/funds_mock.dart
@@ -28,4 +28,14 @@ abstract final class FundsMock {
   static const Map<Resource, int> banditTrioReward = {Resource.gold: 75, Resource.mana: 20};
 
   static const Map<Resource, int> banditTrioRepeatReward = {Resource.gold: 25, Resource.mana: 6};
+
+  static const Map<Resource, int> barbarianChiefReward = {Resource.gold: 150, Resource.mana: 50};
+
+  static const Map<Resource, int> barbarianChiefRepeatReward = {Resource.gold: 50, Resource.mana: 16};
+
+  static const Map<Resource, int> thirtyGold = {Resource.gold: 30};
+
+  static const Map<Resource, int> tenGoldAndZeroMana = {Resource.gold: 10, Resource.mana: 0};
+
+  static const Map<Resource, int> sixManaBeforeTwentyFiveGold = {Resource.mana: 6, Resource.gold: 25};
 }
diff --git a/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart b/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
index 03be346..b567438 100644
--- a/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_level_item_data_mock.dart
@@ -5,6 +5,8 @@ import 'package:farming/core/config/constants/enum/arena_level_id.dart';
 import 'package:farming/core/config/constants/enum/enemy_kind.dart';
 import 'package:farming/layers/presentation/features/arena/models/arena_level_item_data.dart';
 
+import '../../../domain/world/funds_mock.dart';
+
 abstract final class ArenaLevelItemDataMock {
   static ArenaLevelItemData get rookieOpen => ArenaLevelItemData(
     id: ArenaLevelId.banditRookie,
@@ -12,7 +14,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
     powerText: Internationalize.arenaPower(power: 19),
     tone: PowerTone.easy,
-    rewardText: Internationalize.arenaReward(amount: 10),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.tenGold),
     status: ArenaLevelItemStatus.open,
   );
 
@@ -22,7 +24,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
     powerText: Internationalize.arenaPower(power: 19),
     tone: PowerTone.easy,
-    rewardText: Internationalize.arenaReward(amount: 3),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.threeGold),
     status: ArenaLevelItemStatus.cleared,
   );
 
@@ -32,7 +34,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
     powerText: Internationalize.arenaPower(power: 41),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 30),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.thirtyGold),
     status: ArenaLevelItemStatus.locked,
   );
 
@@ -42,7 +44,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
     powerText: Internationalize.arenaPower(power: 41),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 30),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.thirtyGold),
     status: ArenaLevelItemStatus.open,
   );
 
@@ -52,7 +54,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit)),
     powerText: Internationalize.arenaPower(power: 123),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 75),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.banditTrioReward),
     status: ArenaLevelItemStatus.locked,
   );
 
@@ -62,7 +64,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
     powerText: Internationalize.arenaPower(power: 29),
     tone: PowerTone.easy,
-    rewardText: Internationalize.arenaReward(amount: 20),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.twentyGold),
     status: ArenaLevelItemStatus.locked,
   );
 
@@ -72,7 +74,7 @@ abstract final class ArenaLevelItemDataMock {
     enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
     powerText: Internationalize.arenaPower(power: 29),
     tone: PowerTone.easy,
-    rewardText: Internationalize.arenaReward(amount: 20),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.twentyGold),
     status: ArenaLevelItemStatus.open,
   );
 
@@ -85,7 +87,7 @@ abstract final class ArenaLevelItemDataMock {
     ].join(', '),
     powerText: Internationalize.arenaPower(power: 210),
     tone: PowerTone.hard,
-    rewardText: Internationalize.arenaReward(amount: 150),
+    rewardText: Internationalize.arenaReward(amounts: FundsMock.barbarianChiefReward),
     status: ArenaLevelItemStatus.locked,
   );
 }
diff --git a/test/mocks/presentation/features/arena/arena_result_data_mock.dart b/test/mocks/presentation/features/arena/arena_result_data_mock.dart
index 44ab036..a4fd29d 100644
--- a/test/mocks/presentation/features/arena/arena_result_data_mock.dart
+++ b/test/mocks/presentation/features/arena/arena_result_data_mock.dart
@@ -2,23 +2,25 @@ import 'package:farming/core/assets/i18n/internationalize.dart';
 import 'package:farming/core/config/constants/enum/fight_advice.dart';
 import 'package:farming/layers/presentation/features/arena/models/arena_result_data.dart';
 
+import '../../../domain/world/funds_mock.dart';
+
 abstract final class ArenaResultDataMock {
   static ArenaResultData get victoryTenGold => ArenaResultData(
     isVictory: true,
     title: Internationalize.arenaVictory,
-    detail: Internationalize.arenaReward(amount: 10),
+    detail: Internationalize.arenaReward(amounts: FundsMock.tenGold),
   );
 
-  static ArenaResultData get championHundredFiftyGold => ArenaResultData(
+  static ArenaResultData get championWithTheChiefReward => ArenaResultData(
     isVictory: true,
     title: Internationalize.arenaChampion,
-    detail: Internationalize.arenaReward(amount: 150),
+    detail: Internationalize.arenaReward(amounts: FundsMock.barbarianChiefReward),
   );
 
-  static ArenaResultData get victoryFiftyGold => ArenaResultData(
+  static ArenaResultData get victoryWithTheChiefRepeatReward => ArenaResultData(
     isVictory: true,
     title: Internationalize.arenaVictory,
-    detail: Internationalize.arenaReward(amount: 50),
+    detail: Internationalize.arenaReward(amounts: FundsMock.barbarianChiefRepeatReward),
   );
 
   static ArenaResultData get defeatNeedAttack => ArenaResultData(
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/arena`
Expected: FAIL de compilación: `Error: No named parameter with the name 'amounts'.`

- [ ] **Step 3: El texto y el BLoC**

```diff
diff --git a/lib/core/assets/i18n/internationalize.dart b/lib/core/assets/i18n/internationalize.dart
index c801503..14ef21a 100644
--- a/lib/core/assets/i18n/internationalize.dart
+++ b/lib/core/assets/i18n/internationalize.dart
@@ -162,7 +162,14 @@ class Internationalize {
   static String get arenaTitle => '$_arena.title'.tr();
   static String arenaHeroPower({required int power}) => '$_arena.heroPower'.tr(namedArgs: {'power': '$power'});
   static String arenaPower({required int power}) => '$_arena.power'.tr(namedArgs: {'power': '$power'});
-  static String arenaReward({required int amount}) => '$_arena.reward'.tr(namedArgs: {'amount': '$amount'});
+  static String arenaReward({required Map<Resource, int> amounts}) => '$_arena.reward'.tr(
+    namedArgs: {
+      'amounts': [
+        for (final resource in Resource.values)
+          if (amounts[resource] case final amount? when amount > 0) forestAmount(resource: resource, amount: amount),
+      ].join(', '),
+    },
+  );
   static String get arenaCleared => '$_arena.cleared'.tr();
   static String get arenaLocked => '$_arena.locked'.tr();
   static String get arenaFight => '$_arena.fight'.tr();
diff --git a/lib/core/assets/i18n/translations/es.json b/lib/core/assets/i18n/translations/es.json
index ac43dc0..95b936e 100644
--- a/lib/core/assets/i18n/translations/es.json
+++ b/lib/core/assets/i18n/translations/es.json
@@ -146,7 +146,7 @@
     "title": "Arena",
     "heroPower": "Tu Poder: {power}",
     "power": "Poder {power}",
-    "reward": "+{amount} de oro",
+    "reward": "+{amounts}",
     "cleared": "Ganado",
     "locked": "Cerrado",
     "fight": "Empezar pelea",
diff --git a/lib/layers/presentation/features/arena/bloc/arena_bloc.dart b/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
index 368b470..2fd4c64 100644
--- a/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
+++ b/lib/layers/presentation/features/arena/bloc/arena_bloc.dart
@@ -13,7 +13,6 @@ import '../../../../../core/config/constants/enum/fight_advice.dart';
 import '../../../../../core/config/constants/enum/fight_side.dart';
 import '../../../../../core/config/constants/enum/gear_id.dart';
 import '../../../../../core/config/constants/enum/gear_slot.dart';
-import '../../../../../core/config/constants/enum/resource.dart';
 import '../../../../../core/config/constants/enum/skill_id.dart';
 import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
 import '../../../../../core/error-handling/exceptions/custom_exception.dart';
@@ -218,7 +217,7 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
       return ArenaResultData(
         isVictory: true,
         title: _isFirstChampionship ? Internationalize.arenaChampion : Internationalize.arenaVictory,
-        detail: Internationalize.arenaReward(amount: log.reward[Resource.gold] ?? 0),
+        detail: Internationalize.arenaReward(amounts: log.reward),
       );
     }
     final advice = _advice;
@@ -249,7 +248,7 @@ class ArenaBloc extends Bloc<ArenaEvent, ArenaState> {
       enemiesText: _enemiesText(level),
       powerText: Internationalize.arenaPower(power: level.power),
       tone: _tone(levelPower: level.power, heroPower: heroPower),
-      rewardText: Internationalize.arenaReward(amount: status.nextReward[Resource.gold] ?? 0),
+      rewardText: Internationalize.arenaReward(amounts: status.nextReward),
       status: switch (status) {
         ArenaLevelStatusEntity(isCleared: true) => ArenaLevelItemStatus.cleared,
         ArenaLevelStatusEntity(isUnlocked: true) => ArenaLevelItemStatus.open,
```

`arena_bloc.dart` ya no usa `Resource`: su import se va con el cambio (si no, `flutter analyze` da `unused_import`).

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter analyze
flutter test
```

Expected: `No issues found!`; `+665: All tests passed!`. `arena_bloc_test.dart` comprueba ya `+75 de oro, 20 de maná` en la fila de *Tres bandidos*, `+150 de oro, 50 de maná` en la del jefe y en la primera victoria sobre él, y `+50 de oro, 16 de maná` al repetirla.

- [ ] **Step 5: Commit**

```bash
git add lib/core/assets/i18n lib/layers/presentation/features/arena/bloc/arena_bloc.dart test/core/assets/i18n test/layers/presentation/features/arena test/mocks/domain/world/funds_mock.dart test/mocks/presentation/features/arena docs/boost/plans/PROGRESS.md
git commit -m "[PROJECT-C9]: Show the whole arena reward"
```

---

### Task TC9.5: `GAME_DESIGN.md` 3.8 y `CLAUDE.md`

**Files:**
- Modify: `docs/GAME_DESIGN.md` (sección 3.8: bucle, edificios, precio de las habilidades, tabla de niveles con la columna de maná, presupuesto y repeticiones)
- Modify: `CLAUDE.md:10,40,48,49,69,71`

**Interfaces:**
- Consumes: las cifras de TC9.2–TC9.4.
- Produces: solo documentación.

- [ ] **Step 1: `GAME_DESIGN.md` 3.8**

(Bloque con cuatro comillas: el parche contiene el diagrama del bucle, que va entre tres.)

````diff
diff --git a/docs/GAME_DESIGN.md b/docs/GAME_DESIGN.md
index 0ed554c..f4ca612 100644
--- a/docs/GAME_DESIGN.md
+++ b/docs/GAME_DESIGN.md
@@ -175,10 +175,11 @@ La aldea por sí sola acaba siendo "talar y construir". Se propone un segundo mo
 ```
 Aldea: madera / piedra ──▶ Herrería, Armería, Torre de magia ──▶ equipo y habilidades ──▶ más Poder
   ▲                                                                                        │
-  └──────────────── oro (y más adelante trofeos) ◀──────────── Arena: ganar niveles ◀──────┘
+  └──────────── oro y maná (y más adelante trofeos) ◀──────── Arena: ganar niveles ◀──────┘
 ```
 
-- El **oro** sólo se gana en la arena; el equipo y las habilidades sólo se compran en la aldea.
+- El **oro** sólo se gana en la arena; desde *Tres bandidos* la arena da también **maná**, que junto con el oro paga
+  las habilidades. El equipo y las habilidades sólo se compran en la aldea.
 - Ningún modo bloquea al otro: la aldea se juega igual sin pisar la arena, y la arena se puede repetir para conseguir
   oro aunque no se avance.
 
@@ -195,7 +196,8 @@ Valores de partida: Ataque 3–5, Defensa 1, Vida 30 (Poder 31). Con todo el equ
 12–16, Defensa 8, Vida 75 (Poder 144). Las cifras son las del equilibrado de la fase C7, protegidas por
 `test/layers/domain/combat/balance_test.dart`.
 
-**Edificios de mejora** (se construyen con recursos de la aldea; lo que venden se paga **sólo con oro** de la arena):
+**Edificios de mejora** (se construyen con recursos de la aldea; el equipo se paga **sólo con oro** de la arena y las
+habilidades con **oro y maná**):
 
 | Edificio | Qué vende | Niveles |
 |---|---|---|
@@ -216,29 +218,32 @@ Si existe la piedra, la piden los edificios, no el equipo.
 | Armadura de cuero | Defensa 3 · Vida 40 | 40 de oro |
 | Cota de malla | Defensa 5 · Vida 55 | 70 de oro |
 | Armadura de placas | Defensa 8 · Vida 75 | 120 de oro |
-| *Golpe doble* / *Esquiva* / *Segundo aliento* | — | 60 / 90 / 130 de oro (con la Torre de magia: 30 de madera y 40 de oro) |
+| *Golpe doble* / *Esquiva* / *Segundo aliento* | — | 60 de oro y 20 de maná / 90 y 30 / 130 y 45 (con la Torre de magia: 30 de madera y 40 de oro) |
 
 **Niveles de la arena** (equilibrados en la fase C7; cada enemigo: Ataque / Defensa / Vida):
 
-| Nivel | Enemigos | Poder | Recompensa (primera vez) | Héroe esperado | Gana con él | Con un escalón menos |
-|---|---|---|---|---|---|---|
-| 1 | Bandido novato (2–4 / 0 / 20) | 19 | 10 de oro | Inicial | casi siempre | — |
-| 2 | Lobo (4–6 / 1 / 20) | 29 | 20 de oro | Inicial | 60–95 % | — |
-| 3 | Bandido veterano (4–6 / 2 / 36) | 41 | 30 de oro | Espada corta | 60–95 % | < 50 % |
-| 4 | Dos lobos (6–8 / 1 / 18) | 68 | 40 de oro | + Armadura de cuero | 60–95 % | < 50 % |
-| 5 | Oso (8–12 / 3 / 40) | 62 | 55 de oro | + Espada de hierro | 60–95 % | < 50 % |
-| 6 | Tres bandidos (7–9 / 1 / 26) | 123 | 75 de oro | + Cota de malla | 60–95 % | < 50 % |
-| 7 | Bárbaro (10–14 / 4 / 58) | 81 | 90 de oro | + *Golpe doble* | 60–95 % | < 50 % |
-| 8 | Manada de tres lobos (8–12 / 1 / 22) | 135 | 100 de oro | + *Esquiva* | 60–95 % | < 50 % |
-| 9 | Dos bárbaros (8–12 / 4 / 52) | 144 | 120 de oro | + Espada de acero | 60–95 % | < 50 % |
-| 10 | Jefe bárbaro (16–20 / 5 / 72) y dos guardias (7–11 / 2 / 31) | 210 | 150 de oro | + Armadura de placas | 60–95 % | < 50 % |
+| Nivel | Enemigos | Poder | Oro (primera vez) | Maná (primera vez) | Héroe esperado | Gana con él | Con un escalón menos |
+|---|---|---|---|---|---|---|---|
+| 1 | Bandido novato (2–4 / 0 / 20) | 19 | 10 | — | Inicial | casi siempre | — |
+| 2 | Lobo (4–6 / 1 / 20) | 29 | 20 | — | Inicial | 60–95 % | — |
+| 3 | Bandido veterano (4–6 / 2 / 36) | 41 | 30 | — | Espada corta | 60–95 % | < 50 % |
+| 4 | Dos lobos (6–8 / 1 / 18) | 68 | 40 | — | + Armadura de cuero | 60–95 % | < 50 % |
+| 5 | Oso (8–12 / 3 / 40) | 62 | 55 | — | + Espada de hierro | 60–95 % | < 50 % |
+| 6 | Tres bandidos (7–9 / 1 / 26) | 123 | 75 | 20 | + Cota de malla | 60–95 % | < 50 % |
+| 7 | Bárbaro (10–14 / 4 / 58) | 81 | 90 | 25 | + *Golpe doble* | 60–95 % | < 50 % |
+| 8 | Manada de tres lobos (8–12 / 1 / 22) | 135 | 100 | 30 | + *Esquiva* | 60–95 % | < 50 % |
+| 9 | Dos bárbaros (8–12 / 4 / 52) | 144 | 120 | 35 | + Espada de acero | 60–95 % | < 50 % |
+| 10 | Jefe bárbaro (16–20 / 5 / 72) y dos guardias (7–11 / 2 / 31) | 210 | 150 | 50 | + Armadura de placas | 60–95 % | < 50 % |
 
 - "Gana con él" y "con un escalón menos" son el porcentaje de victorias en 100 peleas (semillas 0–99). El Poder del
   nivel no sube siempre: el oso pega fuerte pero es uno solo, y los grupos cuentan a todos sus miembros.
-- Con el oro de la primera victoria de cada nivel anterior, más repetir como mucho tres veces el último, se paga el
-  héroe esperado del nivel siguiente. *Segundo aliento* queda como mejora opcional para el final.
+- Con el oro y el maná de la primera victoria de cada nivel anterior, más repetir como mucho tres veces el último, se
+  paga el héroe esperado del nivel siguiente. Maná: 38 ≥ 20 en el bárbaro, 69 ≥ 50 en la manada, 105 ≥ 50 y 143 ≥ 50.
+  Con todo ganado una vez hay 160 de maná y las tres habilidades cuestan 95. *Segundo aliento* queda como mejora
+  opcional para el final.
 
-- Un nivel se desbloquea al ganar el anterior. Repetir un nivel ganado da un tercio del oro.
+- Un nivel se desbloquea al ganar el anterior. Repetir un nivel ganado da un tercio de cada recurso (*Tres bandidos*:
+  25 de oro y 6 de maná).
 - Perder no quita nada: se vuelve a la aldea con un consejo ("Te falta Defensa", "Prueba con la Cota de malla").
 
 **La pelea.**
````

- [ ] **Step 2: `CLAUDE.md`**

```diff
diff --git a/CLAUDE.md b/CLAUDE.md
index 13462ee..be91b6d 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -7,7 +7,7 @@ This file provides guidance to Claude Code (claude.ai/code) when working with co
 - Single **Flutter** app at the repo root (Android, iOS, web), Dart package `farming`. All game logic and all views live in `lib/`.
 - `lib/core/` — `assets/` (`images/lpc/`: the only copy of the art, with `CREDITS.md`, and also the arena atlas `arena.{png,json}`; `images/icons/`: HUD SVG icons, including `arena.svg`; `i18n/translations/es.json` + `i18n/internationalize.dart`), `config/` (`constants/enum/` with every enum, screen-only ones in `enum/forest/` and `enum/arena/`; `di/` with `locator.dart`, `di.dart`, generated `di.config.dart`, `di_environment.dart`; `env/` with `EnvironmentConstants` and the dev/prod `--dart-define-from-file` JSON files), `error-handling/` (`CustomException`, `AppException` cases, `AppExceptionHandler`), `services/logging/` (`Logger`, `CustomLoggerImpl`, `BlocLogger`), `services/navigation/` (`NavigationService` + `NavifyImpl`: navigation, snackbars, error pop-ups and the `routeObserver` that `ContainerApp` registers and pages listen to with `RouteAware`), `utils/` (`seeded_random.dart`, `kebab_case.dart`).
 - `lib/layers/domain/`, `lib/layers/data/`, `lib/layers/presentation/` — see Architecture.
-- `test/` mirrors `lib/`; `test/mocks/` holds centralised mock data; `test/helpers/` has `loadSpanishTranslations` (`spanish_translations.dart`), `pumpUntil` (`pump_until.dart`) and `hud_test_app.dart`; `test/architecture_test.dart` enforces the layer rules.
+- `test/` mirrors `lib/`; `test/mocks/` holds centralised mock data; `test/helpers/` has `loadSpanishTranslations` (`spanish_translations.dart`), `pumpUntil` (`pump_until.dart`), `loadRobotoFont` (`roboto_font.dart`: the SDK's Roboto, so HUD widths are real) and `hud_test_app.dart`; `test/architecture_test.dart` enforces the layer rules.
 - `android/`, `ios/`, `web/` — Flutter runners (app name `Farming`, ids `com.apergas.farming`, landscape only on mobile: Android `userLandscape`, iOS landscape left/right + full screen).
 - `asset-packs/lpc/` — raw LPC art, `build_assets.py`, which generates `lib/core/assets/images/lpc/`, and `build_app_icon.py`, which draws the app icon (the oak of `forest.png` on `#0E150E`, also the launch colour) for Android (legacy icon plus the adaptive icon foreground), iOS and the web.
 - `.github/workflows/deploy.yml` — Flutter pinned to 3.47.6 (`flutter-version` in `subosito/flutter-action`, bump it in its own commit); on pushes to `main` that touch the app: `build_runner` + `git diff --exit-code`, `flutter analyze`, `flutter test`, golden tests in Chrome, `flutter build web --base-href /phaser-example/` (production env file) and publish `build/web` to GitHub Pages (https://apergas.github.io/phaser-example/). Android and iOS are tested locally only.
@@ -37,7 +37,7 @@ Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DO
   - `entities/<feature>/` — immutable `*Entity` classes: `final` fields, `const` constructor, `copyWith`, computed getters, hand-written `==`/`hashCode`. Geometry, tree, item, decoration, building (`BlueprintEntity`, `BuildingEntity`), player (`InventoryEntity`, `PlayerEntity`, sealed `ActivityEntity`, sealed `IntentEntity`), game (sealed `GameEventEntity`, sealed `ConstructionResultEntity`, `PlayerStatusEntity`, `WorldSnapshotEntity`, `QuestProgressEntity`, `BuildOptionEntity`, `GameSessionEntity`), hero (`CombatStatsEntity` with an attack range, `attackMin`–`attackMax`, `HeroEntity`, `HeroStatusEntity` with `isChampion`, `SkillEntity`, `SkillOptionEntity` with a `SkillOptionState`, `missing` and `canLearn`), gear (`GearEntity`, `GearOptionEntity` with a `GearOptionState`, `missing` and `canBuy`), combat (`EnemyEntity`, `ArenaLevelEntity`, `FightTurnEntity`, `FightLogEntity`, `ArenaEntity`, `ArenaLevelStatusEntity`, sealed `FightResultEntity`: `FightPlayedEntity` with an optional `FightAdvice` and `isFirstChampionship`, `FightLockedEntity`).
   - `combat/` — `Combat`, pure functions: `resolve(…, seed)` plays a whole fight with `SeededRandom(seed)` (`StartFightUseCase` passes `hero.fightsFought`) and returns a `FightLogEntity` (the call order of `next()` is part of the contract: one per hit, plus one per enemy attack when the hero can dodge); each blow picks a value in the attacker's `attackMin`–`attackMax` with its `next()` and deals `max(1, value − defense)`, capped at the health left; `adviceFor` reads a lost fight.
   - `world/` — `World`, the mutable aggregate and only entry point that changes the game. It owns a `WorldState` and delegates to systems: `Navigation`, `Woodcutting`, `Construction`, `pickUpItems`. `World` also owns the hero (`hero`, `updateHero`) and the funds (`funds`, `earn`, `spend`: the way hero/arena costs and rewards are paid and collected; village systems still use the inventory directly until F6 moves everything to the stock). Work mechanics are an `IntentEntity` subtype + a `Work` + one case in `workFor()` (exhaustive `switch`). `advance(deltaMs)` returns `GameEventEntity`s. `world/extensions/` holds the entity operations (`hit`, `hammer`, `add`, `spend`, `missing`, `addTool`, `hasTool`, `walkTo`, `distanceTo`, `BuildingListRules.hasComplete` (whether there is a finished building of a blueprint)...; `HeroRules`: `stats`, `power`, `equipped`, `nextGear`, `withGear`; `ArenaRules`: `isUnlocked`, `hasCleared`, `isChampion` (the hero has beaten `ArenaLevels.championship`, the barbarian chief), `rewardFor`, `afterFight`).
-  - `quests/` (`Quest` with its `QuestLine`, `Quests` (village line, then the hero line), `QuestLog` with sticky completion and one current quest per line), `rules/` (`Rules` tuning, `Blueprints` catalogue (house, forge, armory, mage tower), `Gear` catalogue (gold only; `workshopFor`: weapons at the forge, armor at the armory), `Skills` catalogue (gold only, cheapest first; `Skills.building`: learned at the mage tower), `ArenaLevels`: the list order is the play order (a new level can go anywhere in the list, its `ArenaLevelId` always at the end of the enum; `ArenaRules.isUnlocked` also opens any level already cleared, so a game keeps its levels when new ones are inserted), and the combat constants of `Rules`), `repositories/{level,session}` (interfaces).
+  - `quests/` (`Quest` with its `QuestLine`, `Quests` (village line, then the hero line), `QuestLog` with sticky completion and one current quest per line), `rules/` (`Rules` tuning, `Blueprints` catalogue (house, forge, armory, mage tower), `Gear` catalogue (gold only; `workshopFor`: weapons at the forge, armor at the armory), `Skills` catalogue (gold and mana, cheapest first; `Skills.building`: learned at the mage tower), `ArenaLevels`: levels 6–10 pay gold and mana, 1–5 only gold; the list order is the play order (a new level can go anywhere in the list, its `ArenaLevelId` always at the end of the enum; `ArenaRules.isUnlocked` also opens any level already cleared, so a game keeps its levels when new ones are inserted), and the combat constants of `Rules`), `repositories/{level,session}` (interfaces).
   - `use-cases/game/` — one `@Injectable()` class per action with a synchronous `call()`: start game, move player, chop tree, can place / construct building, resume construction (`ResumeConstructionUseCase` → `World.orderResumeConstruction`: tapping an unfinished building sends the player back to hammer it, keeping its progress and without paying again; tapping the building already being hammered returns `ok` without touching the world, so the swing is not restarted), advance, player status, world snapshot, build options, quests; `hero/`: `GetHeroStatusUseCase`, `BuyGearUseCase` (checks a finished workshop, the next tier and the funds, in that order; pays with `World.spend` and equips with `World.updateHero`), `GetGearOptionsUseCase` (per slot, from the equipped tier up), `LearnSkillUseCase` (checks a finished mage tower, that the skill is not known yet and the funds, in that order; pays with `World.spend` and adds the skill with `World.updateHero`), `GetSkillOptionsUseCase` (one option per skill, in `Skills.all` order); `arena/`: `GetArenaUseCase`, `StartFightUseCase` (resolves, pays with `World.earn` and records the fight with `World.updateHero` in one synchronous call; sets `FightPlayedEntity.isFirstChampionship` when the hero beats the chief for the first time). Each reads the session from `GameSessionRepository`.
 - `lib/layers/data/` — `datasources/level` (`LevelLocalDatasourceImpl`: seeded procedural forest that also decides each tree's kind and the ground decoration; all-nullable DBOs in `local/dbo/`), `datasources/session` (in-memory, `@LazySingleton`: one game per app), `repositories/level` (`LevelRepositoryImpl` + injected `*MapperDBO`s), `repositories/session`. Errors go through `AppExceptionHandler`.
 - `lib/layers/presentation/`
@@ -45,8 +45,8 @@ Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DO
   - `features/forest/bloc/` — `ForestBloc` (single `on<ForestEvent>` with `await switch`; events `ForestStarted`, `ForestTicked`, `ForestMapClicked` (with the tapped `treeId` or `buildingId`, both pixel-accurate), `ForestPointerMoved`, `ForestBuildRequested`, `ForestPlacementCancelled`, `ForestGearPurchaseRequested`, `ForestArenaRequested` (opens the arena with `NavigationService.push(const ArenaPage())` and cancels placement), `ForestSkillLearnRequested`; states `ForestInitial` / `ForestInProgress` / `ForestSuccess` / `ForestFailure` carrying `ForestData`). Handlers are synchronous so ticks keep frame order. Messages are snackbars through `NavigationService`; the quests completed in one tick are announced together (`_announceQuests`: one message per line they close, otherwise one per quest).
   - `features/forest/models/` — view models (`PlayerRenderData`, sealed `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `ResourceItemData`, `ToolItemData`, `PlacementData`, `HeroPanelData`, `GearRowData`, `GearItemData`, `SkillItemData`) and sealed `ForestEffect` (with `GearPurchasedEffect`, `SkillLearnedEffect`) (played once per emitted state).
   - `features/forest/game/` — Flame (`package:flame` / `flame_bloc` may only be imported by `features/forest/game/`, `features/arena/game/`, `forest_page.dart` and `arena_page.dart`; rule in `architecture_test.dart`): `ForestGame` (`update` caps `dt` at 100 ms once and uses that value for `ForestTicked` and for every component, so animations never run ahead of the simulation) + `ForestWorld` + `ForestSceneComponent` + `ForestStateListener` (reconciles components with `ForestData.world` by id; plays effects), `components/` (ground, atlas sprites, shadows, trees with pixel-accurate taps, items, buildings by stage, placement ghost, animated player, `FloatingTextComponent` shared with the arena, same API as F1's plan), `atlas/` (`LpcAtlas` for `forest.json`, `AlphaMask`, `LpcAssets` + loader, `SpriteNames`), `render/` (`RenderConstants`, depth, position conversion, easing, tree motion, player frames, `CameraFraming` working with `Offset`/`Size`, not Flame vectors), `particles/` (chips, dust, the gear-purchase sparkles, the same sparkles in blue when a skill is learned (`ParticleKind.magicSparkle`), blood drops: `ParticleKind.bloodDrop`, `ParticleBursts.bloodDrops`, and the champion confetti, `ParticleBursts.confetti`, gold and blue sparkles that fall).
-  - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` (one section per `QuestLine`) + `QuestRow`, `PlacementBar` (touch), `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`, `HudPanel`, `HudButton` (takes an optional SVG `icon`); `HudOverlay` has four buttons, *Misiones*, *Construir*, *Héroe* and *Arena* (Arena closes any open menu, the hero panel included), on the `ResourceBar` line from `HudOverlay.buttonsBelowWidth` (920 px) and left-aligned under it below that (same left edge as the bar), with the open menu always under the buttons; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_ForestViewState` is `RouteAware` on the `RouteObserver` that `ForestPage` receives through its constructor from `ContainerAppBloc`, which reads it from `NavigationService`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops; `_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
-  - `features/arena/` — the arena screen, same shape as `forest/`: `ArenaBloc` (events `ArenaStarted`, `ArenaLevelSelected`, `ArenaFightRequested`, `ArenaReplayTicked`, `ArenaReplaySkipped`, `ArenaClosed`; `ArenaData` with the level list, the selection, `FightReplayData`, `FighterRenderData`s, `ArenaResultData` and sealed `ArenaEffect`s; a double strike or a second wind adds a `SkillUsedEffect` after its own effect, and the scene floats the skill name (`Internationalize.arenaSkillUsed`, also used for the dodge) above the hero); the fight is already resolved and paid by `StartFightUseCase`, the bloc only replays the `FightLogEntity` (one turn every 800 ms, each turn's effect when its blow lands) and refreshes the list with `GetArenaUseCase` when the replay ends; a first championship adds a `ChampionEffect` (confetti over the hero) after `FightEndedEffect` and titles the result *¡Campeón de la arena!*; `game/` (`ArenaGame` with the same capped `dt`, `ArenaSceneComponent`, `ArenaStateListener`, `FighterComponent`, `HealthBarComponent`, `ArenaGroundComponent`, atlas `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames` over `arena.json`); `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`); `arena_page.dart` (`ArenaPage` + `_ArenaView`, `GameWidget(autofocus: false)`).
+  - `features/forest/widgets/` — HUD, one class per file: `HudOverlay`, `ResourceBar` (every `Resource` and `ToolKind`), `BuildMenu` + `BuildOptionTile`, `QuestPanel` (one section per `QuestLine`) + `QuestRow`, `PlacementBar` (touch), `HeroPanel` (a *Campeón de la arena* badge next to the title once the chief is beaten; tabs *Equipo* and *Habilidades*, which `HudOverlay` always passes; with one section there are no tabs; `sections` must not be empty, and the open tab falls back to the first one if it is no longer offered) + `GearRow` + `GearOptionTile` + `SkillTile`, `HudPanel`, `HudButton` (takes an optional SVG `icon`); `HudOverlay` has four buttons, *Misiones*, *Construir*, *Héroe* and *Arena* (Arena closes any open menu, the hero panel included), on the `ResourceBar` line from `HudOverlay.buttonsBelowWidth` (1030 px: the bar with every resource at 9999 and the buttons, measured with Roboto in `hud_overlay_test.dart`, plus 24 px) and left-aligned under it below that (same left edge as the bar), with the open menu always under the buttons; rebuilt only when `HudData` changes. The page lives at `features/forest/forest_page.dart`: `ForestPage` (creates the BLoC in `BlocProvider.create` from `locator`, adds `ForestStarted`, toggles `BrowserContextMenu` on web in its lifecycle) + `_ForestView` (`_ForestViewState` is `RouteAware` on the `RouteObserver` that `ForestPage` receives through its constructor from `ContainerAppBloc`, which reads it from `NavigationService`: the game engine pauses while another route (the arena, a dialog) is on top and resumes when it pops; `_bodyByState` switch; `GameWidget(autofocus: false)` under the HUD; error view with *Reintentar*, also used by the `GameWidget` `errorBuilder` when the art fails to load: `ForestGame.onLoad` loads the LPC assets through `LpcAssetsLoader` (bundle from `DefaultAssetBundle`), so the failure reaches the widget, and *Reintentar* builds a new `ForestGame` and restarts).
+  - `features/arena/` — the arena screen, same shape as `forest/`: `ArenaBloc` (events `ArenaStarted`, `ArenaLevelSelected`, `ArenaFightRequested`, `ArenaReplayTicked`, `ArenaReplaySkipped`, `ArenaClosed`; `ArenaData` with the level list, the selection, `FightReplayData`, `FighterRenderData`s, `ArenaResultData` and sealed `ArenaEffect`s; a double strike or a second wind adds a `SkillUsedEffect` after its own effect, and the scene floats the skill name (`Internationalize.arenaSkillUsed`, also used for the dodge) above the hero); the fight is already resolved and paid by `StartFightUseCase`, the bloc only replays the `FightLogEntity` (one turn every 800 ms, each turn's effect when its blow lands) and refreshes the list with `GetArenaUseCase` when the replay ends; rewards are written whole with `Internationalize.arenaReward(amounts:)` (every positive amount in `Resource` order: `+75 de oro, 20 de maná`); a first championship adds a `ChampionEffect` (confetti over the hero) after `FightEndedEffect` and titles the result *¡Campeón de la arena!*; `game/` (`ArenaGame` with the same capped `dt`, `ArenaSceneComponent`, `ArenaStateListener`, `FighterComponent`, `HealthBarComponent`, `ArenaGroundComponent`, atlas `ArenaAssets` / `ArenaAssetsLoader` / `ArenaSpriteNames` over `arena.json`); `widgets/` (`ArenaHud`, `LevelList`, `LevelTile`, `FightButton`, `ResultPanel`); `arena_page.dart` (`ArenaPage` + `_ArenaView`, `GameWidget(autofocus: false)`).
   - `widgets/` — `CustomButton`, `CustomPopUp` (used by `NavifyImpl`). `theme/` — `colors/custom_colors.dart`, `styles/custom_text_styles.dart`, `images/custom_icons.dart`, `custom_theme.dart`.
 
 Documented exceptions to the plugin (keep them; do not "fix" them):
@@ -66,9 +66,9 @@ Documented exceptions to the plugin (keep them; do not "fix" them):
 Key cross-cutting conventions:
 
 - **Arena fights are deterministic:** same hero and seed, same log; golden tests in `test/layers/domain/combat/combat_test.dart`.
-- **Arena balance:** `test/layers/domain/combat/balance_test.dart` plays every arena level with 100 seeds for the expected hero of `BalanceScenarioMock` (60–95 % of wins, the first level may always be won; under 50 % one step behind; the gold of earlier first wins plus three repeats pays the expected gear). Any change to `Gear`, `Skills`, `ArenaLevels` or building costs must keep it green; the final table lives in `docs/GAME_DESIGN.md` 3.8.
+- **Arena balance:** `test/layers/domain/combat/balance_test.dart` plays every arena level with 100 seeds for the expected hero of `BalanceScenarioMock` (60–95 % of wins, the first level may always be won; under 50 % one step behind; for each arena resource, gold and mana, the earlier first wins plus three repeats of the last pay the expected gear and skills). Any change to `Gear`, `Skills`, `ArenaLevels` or building costs must keep it green; the final table lives in `docs/GAME_DESIGN.md` 3.8.
 - **Positions are feet / trunk bases**, in world units = native art pixels; the domain and Flame are both Y-down (no conversion). The same point drives collision, sprite anchoring and draw order (component `priority` = base `y`).
-- **New resource, tool or building:** a `Resource`/`ToolKind`/`BlueprintId` is the enum value (appended at the end) + its cases in `Internationalize` and `es.json`, `CustomIcons` (+ SVG in `lib/core/assets/images/icons/`), `SpriteNames` (+ atlas frame via `build_assets.py`) and, for buildings, `RenderConstants.buildingFrontOffset`; `lpc_atlas_test.dart`, `internationalize_test.dart` and `custom_icons_test.dart` fail if any piece is missing. `LpcAssetsMock` builds a frame for every `BlueprintId`, and new buildings reuse `build_cottage()` in `build_assets.py` (recoloured roof via `ROOF_RAMP`, taller with `roof_stretch`).
+- **New resource, tool or building:** a `Resource`/`ToolKind`/`BlueprintId` is the enum value (appended at the end) + its cases in `Internationalize` and `es.json`, `CustomIcons` (+ SVG in `lib/core/assets/images/icons/`), `SpriteNames` (+ atlas frame via `build_assets.py`) and, for buildings, `RenderConstants.buildingFrontOffset`; `lpc_atlas_test.dart`, `internationalize_test.dart` and `custom_icons_test.dart` fail if any piece is missing. A resource that never lies on the ground (gold, mana) needs no `SpriteNames` frame; every new resource widens the `ResourceBar`, and the breakpoint test of `hud_overlay_test.dart` fails until `HudOverlay.buttonsBelowWidth` is measured again. `LpcAssetsMock` builds a frame for every `BlueprintId`, and new buildings reuse `build_cottage()` in `build_assets.py` (recoloured roof via `ROOF_RAMP`, taller with `roof_stretch`).
 - **The map is level data:** tree positions, wood, kinds and ground decoration come from the data layer; the view never picks art or places decor itself (`SpriteNames` maps kind → atlas frame).
 - **Rendering constants** (`features/forest/game/render/render_constants.dart`, art-specific so not in `core`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; buildings drawn `RenderConstants.buildingFrontOffset` below their footprint centre (house: 24 px); sprites drawn with `FilterQuality.none`. Arena: `arena/game/render/arena_render_constants.dart` (400 ms lead-in, 800 ms per turn, impact at half the turn; people walk up to their target during the first 35 % of the turn (walk frames, `ArenaFrames.approachReach`), strike in place with the slash frames and walk back after 65 %, stopping `approachGap` (30 px) short; 480×270 stage framed with a cover zoom between 1 and 3; hero facing right, enemies facing left; people have idle, walk and slash frames and hold their weapon: the hero the axe or the LPC arming sword of its equipped weapon (`FighterRenderData.weapon`, `ArenaSpriteNames.heroWith`: bronze short sword, iron, steel), the veteran bandit (`EnemyKind.banditVeteran`, blue shirt) an iron sword; barbarians wear their own LPC layers (leather armour, beard, helmet) and the barbarian chief has his own frames (viking helmet, black beard) drawn ×1.25; wolves and bears (`ArenaRenderConstants.leapSequence`, an exhaustive `switch` on `EnemyKind`) bite or swipe with their own `attack-*` frames while `ArenaFrames.groundSpot` / `lift` make them leap at their target (`FighterRenderData.targetIndex`) during the first 40 % of the turn, stopping 30 px short, and back after 60 %, and they lie on their own `down` frame instead of tipping over; the hero's target, the first enemy still standing, has a ring under its feet (`TargetRingComponent`, `FighterRenderData.isTargeted`), and fallen fighters are drawn at half alpha).
 - **New enemy kind:** the `EnemyKind` value (appended at the end) + its cases in `ArenaSpriteNames.enemy`, `ArenaRenderConstants.fighterScale` and `leapSequence`, `Internationalize.arenaEnemy` and `es.json`, and its frames in `arena.png` (`build_assets.py`, credited in `CREDITS.md`); `arena_sprite_names_test.dart` and `internationalize_test.dart` fail if any piece is missing.
```

- [ ] **Step 3: Batería de cierre**

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- lib test
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

Expected: `git diff` sin salida; `No issues found!`; `+665: All tests passed!`; `+40: All tests passed!`.

- [ ] **Step 4: Commit**

```bash
git add docs/GAME_DESIGN.md docs/boost/plans/PROGRESS.md
git add CLAUDE.md
git commit -m "[PROJECT-C9]: Document the mana"
```

(`CLAUDE.md` se añade en un comando aparte del `git commit`.)

---

## Prueba manual

Para llegar a los niveles 6–10 sin jugar una hora, el mismo truco que en C6: un héroe de prueba **solo en local** (por ejemplo, `HeroEntity(weaponTier: 2, armorTier: 2, clearedLevels: {…hasta bear})` y oro en `StartGameUseCase`), que nunca se commitea.

1. **Chrome** (`flutter run -d chrome`), ventana de más de 1030 px: la barra dice *Madera 0 · Oro 0 · Maná 0* con el rombo azul, después el hacha; los cuatro botones a la derecha, en la misma línea. Estrechando la ventana por debajo de 1030 px, los botones bajan bajo la barra, alineados a su izquierda, sin solaparse.
2. **Arena:** la fila de *Tres bandidos* dice *+75 de oro, 20 de maná*; los niveles 1–5 solo oro. Ganarlo: el resultado dice *+75 de oro, 20 de maná* y, de vuelta en el bosque, la barra suma las dos cosas. La fila pasa a *+25 de oro, 6 de maná* y repetirlo da eso.
3. **Torre de magia con oro y sin maná:** en *Héroe* ▸ *Habilidades*, *Golpe doble* cuesta *60 de oro, 20 de maná* y dice *Faltan 20 de maná*; no se puede aprender y el oro sigue ahí. Con 20 de maná, se aprende y la barra baja 60 de oro y 20 de maná.
4. **Android** (`flutter run -d emulator-5554`, horizontal, p. ej. 915 × 412): los botones bajo la barra, sin solaparse; la barra con etiquetas cabe entera.
5. **iOS** (`flutter run -d "iPhone 17"`), opcional: lo mismo que en Android.

## Al cerrar C9

- Batería de cierre (TC9.5, Step 3).
- `PROGRESS.md`: C9 pasa a ✅ con 665 tests; `README.md` de la arena, el icono de C9 (✅).
- PR `[PROJECT-C9]: Add mana` hacia `feature/PROJECT-X-arena`. No cierra #56 sola (PR a una rama de integración): se cierra y se mueve la tarjeta a mano.
- Después, C10 sale de `feature/PROJECT-X-arena`.
