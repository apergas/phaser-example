# F5 · Piedra y pico — Implementation Plan

> **Implementado el 2026-10-17 sin tests (regla del usuario); lo que falta de test está en *Para T1*.** Una sola rama `feature/PROJECT-F5-stone`, un commit por tarea (TF5.1–TF5.5). Desvíos respecto a iOS y a la ficha: `ForestMapClicked.rockId` en vez de un enum `MapTarget` (decisión 9); `RockDBO` con `x`/`y` sueltos (decisión 6); el pico es el único objeto del suelo (`items[0]`), porque el hacha ya no está en el mapa (decisión 7); umbrales del HUD medidos con Roboto: 1260 y 770 en vez de 1300 y 800 pt (decisión 14). Rocas, pico, decoración quitada y frames, idénticos a iOS.

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

| | |
|---|---|
| **Flujo** | Único (aldea, bloque 2) |
| **Rama** | `feature/PROJECT-F5-stone`, desde `feature/PROJECT-X-town` (develop con la arena C0–C13, "empezar con el hacha", F1, F3 y F4) |
| **Depende de** | F4 (orden de iOS; técnicamente solo F0) |
| **Issue / milestone** | `phase:F5` · milestone `F5 Stone` |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios` (solo lectura). Plan `$IOS/docs/plans/2026-10-12-village/F5-stone.md`, merge `b26be1c` (`[PROJECT-F5]: Merge stone and the pickaxe`), commits `1a69419` (dominio), `073dd32` (frames), `06f881c` (nivel), `1b7dcde` (escena) |

**Goal:** Un segundo recurso que se recoge en el mapa: rocas que se pican con un pico encontrado lejos del inicio. La piedra paga los edificios del héroe y, después, la cantera y el taller.

**Architecture:** Dominio: `RockEntity` en `WorldState.rocks` (obstáculo), el sistema interno `Mining` calcado de `Woodcutting` (`MineIntentEntity`, `PlayerActivity.mining`, `MineResult`, `World.orderMine`, `MineRockUseCase`), los eventos `RockHitEventEntity` / `RockBrokenEventEntity` y `WorldSnapshotEntity.rocks`; la Herrería, la Armería y la Torre de magia piden 10 de piedra. Datos: `RockDBO` y `LevelDBO.rocks`, 12 rocas con su propia semilla después de los árboles, el pico en el suelo y la decoración que caería encima quitada. Presentación: `Resource.stone` y `ToolKind.pickaxe` en el HUD (umbrales medidos de nuevo), `ForestMapClicked.rockId`, `RockComponent` + `RockMotion`, esquirlas `ParticleKind.stoneChip`, "+8" flotante y la pose de picar con la hoja del martillo.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, Flame, `flutter_bloc`, `easy_localization`, `injectable`; Pillow para `build_assets.py`. Sin dependencias nuevas.

## Global Constraints

- **Sin tests en esta fase (decisión del usuario):** no se escribe, cambia ni ejecuta ningún test y no se toca `test/`. Los tests que dejen de compilar, cambien de resultado o falten están en *Para T1*. La única excepción es medir el umbral del HUD con un test de widget de usar y tirar en el *scratchpad* (no se guarda).
- **Sin comprobación manual por tarea:** la *Prueba manual* se hace una vez, con el bloque 2 de la aldea.
- Verificación de cada tarea: `flutter analyze lib` → `No issues found!` y `dart format --line-length 120` sobre los ficheros de `lib/` escritos. Si cambia la inyección (TF5.3, TF5.4): `dart run build_runner build --delete-conflicting-outputs` y commit de `di.config.dart` tal cual. Si cambia `build_assets.py` (TF5.2): regenerar y comprobar que solo aparecen los frames nuevos.
- Textos solo en `es.json`, leídos por `Internationalize`; cada texto que dice cómo interactuar tiene su variante `…Touch`.
- Sin comentarios en `lib/`; imports relativos; `switch` exhaustivos en el orden de declaración; enums nuevos al final; títulos de commit `[PROJECT-F5]: <frase en inglés en imperativo>`; el commit, en un comando aparte del `git add`.

## Decisiones

Las de la ficha (comprobadas en iOS) más las que salen de Flutter:

1. **Dominio** como en iOS: `RockEntity(id, position, radius, stoneYield, hitsToBreak, hitsTaken = 0)` en `domain/entities/rock/` con `footprint`, `hitsRemaining`, `isBroken` y los `assert` de iOS; `RockRules.hit()` en `domain/world/extensions/rock_rules.dart`; `Mining` (`domain/world/mining.dart`, pieza interna) con `check` (`unknownRock` antes que `noPickaxe`), los mismos sitios que la tala (izquierda o derecha, `y + 1`) y un golpe cada `Rules.mineIntervalMs = 750`. El último golpe quita la roca de `WorldState.rocks`, suma `Resource.stone` al inventario (F6 la pasa a la carga) y emite `RockHitEventEntity(rockId)` y `RockBrokenEventEntity(rockId, stone)` en ese orden. No queda resto en el suelo. Volver a tocar la roca que se pica reinicia el golpe (lo hace `Navigation.goWorkOn`, igual que con los árboles).
2. **Obstáculos:** `WorldState.obstacles()` = troncos, rocas y edificios, en ese orden. Así una roca bloquea el paso, `canPlace` y el rebrote de un tocón a menos de 34 (12 + 22); el generador deja las rocas a ≥ 60 de todo tronco, así que ningún tocón del nivel queda bloqueado para siempre.
3. **`StatsRecording`:** `RockHitEventEntity() || RockBrokenEventEntity() => stats` al final del `switch`. Las misiones de piedra son de F8.
4. **Costes:** Herrería y Armería `{wood: 25, stone: 10}`, Torre de magia `{wood: 30, gold: 40, stone: 10}`. `Gear` y `Skills` no cambian, así que el oro y el maná de la arena siguen igual y `balance_test.dart` no se toca. La nota de la tabla *Si la arena ya está* del README (15 de piedra en `steelSword` / `plateArmor`) queda descartada por la ficha. Las 12 rocas dan 96 de piedra, más que los 75 que piden F5 y F8 juntas; las rocas **no vuelven**.
5. **Nivel:** las rocas salen con `SeededRandom(2026)` **después** de los árboles: hasta `12 × 50 = 600` intentos de dos tiradas dentro del margen de 60; vale si está a ≥ 200 del inicio, ≥ 80 del pico, ≥ 200 de otra roca, ≥ 60 de todo tronco y fuera de la caja de copa de cualquier árbol (`_isUnderTree`, la misma que usa la decoración). Salen 12 en 202 intentos, idénticas a iOS: `rock-1` (303.66, 1110.24), `rock-2` (1333.10, 464.67), `rock-3` (385.68, 823.07). La roca más cercana a un tronco está a 67,2.
6. **`RockDBO({id, x, y})`**, no `position`: los DBO de Flutter (`TreeDBO`, `ItemDBO`, `DecorationDBO`) guardan `x`/`y` sueltos. `RockMapperDBO` pone las cifras de `Rules` y, sin id, `rock-<n>`; sin posición, (0, 0).
7. **Pico en el suelo:** `ItemDBO(id: 'pickaxe', kind: 'pickaxe', x: spawnX + 212, y: spawnY + 212)` = (1012, 812), a 299,8 del inicio y a 80,3 del tronco más cercano, fuera de toda copa: el sitio está despejado. **Diferencia con iOS/ficha:** en Flutter ya no hay hacha en el suelo (se empieza con ella), así que el pico es `items[0]` y el único objeto.
8. **Decoración:** se genera igual y después se quitan las que caen a menos de 48 de una roca o de 32 del pico. Sin el hacha en el suelo la decoración de Flutter sale igual que la de iOS (la comprobación del hacha no quitaba ninguna), así que se quitan las mismas 13 de 107 (ids 6, 12, 17, 30, 34, 37, 40, 42, 49, 68, 81, 85 y 105) y quedan 94, sin moverse ni cambiar de id. Árboles, tipos y madera (388 en los DBO, 411 en el dominio) no cambian.
9. **Toque:** `ForestMapClicked` gana `rockId` junto a `treeId` y `buildingId` (**diferencia con iOS**, que usa `MapTarget`: en Flutter el evento ya lleva un id por tipo, y un enum + id obligaría a reescribir el toque de árboles y edificios). `ForestSceneComponent.rockAt` elige al píxel la roca de mayor prioridad y la descarta si la tapa un árbol de prioridad mayor (como `buildingAt`). `ForestBloc._orderAt`: edificio sin terminar → roca → árbol → andar.
10. **Escena:** `RockComponent` (prioridad `y`, toque al píxel con `AlphaMask`) con `RockMotion`: tiembla 1,5 px durante 120 ms al golpear (alejándose del jugador) y al romperse encoge al 60 % y se desvanece en 350 ms (`Easing.quadIn`), y deja de poder tocarse. Esquirlas `ParticleKind.stoneChip` (`ParticleBursts.stoneChips`, la variante de `woodChips` con origen 14 por encima de la base; gris `0xFF4B4F58` / `0xFF9AA0AA`). "+8" flotante dorado y *snackbar* "+8 de piedra".
11. **Pose:** `WorkTool.pickaxe` usa la hoja y la secuencia del martillo (`PlayerSheet.hammer`, `hammerSequence`). `ForestBloc._workTool` saca la herramienta con un `switch` exhaustivo sobre `PlayerActivity` (si no, picar pintaría al jugador quieto).
12. **Arte** (sin autores nuevos): `rock-large` (caja `(864, 736, 928, 800)` de `terrain_atlas.png`, recortada a 61 × 45, pivote `(0.5, 0.8)`) y `pickaxe-pickup` (`axe-pickup` recoloreado en gris y reflejado, 24 × 27). El código es el de iOS; `forest.png` sale del mismo tamaño que en iOS (96 820 bytes) y ningún frame anterior cambia.
13. **Textos:** `forest.resource.stone` "Piedra", `forest.amount.stone` "{amount} de piedra", `forest.tool.pickaxe` "Pico", `forest.message.needPickaxe` "Necesitas un pico para picar.", `forest.message.pickedUpPickaxe` "¡Pico recogido! Haz clic en una roca para picarla.", `forest.message.pickedUpPickaxeTouch` "¡Pico recogido! Toca una roca para picarla.", `forest.message.stoneGained` "+{amount} de piedra", `forest.floating.stoneGained` "+{amount}". Iconos `stone.svg` (22 × 14) y `pickaxe.svg` (22 × 22), copiados de iOS.
14. **HUD:** medido con Roboto (test de usar y tirar en el *scratchpad* con `test/helpers/roboto_font.dart`; los mocks de `test/` no compilan desde C12), los cuatro recursos a 9999, las dos herramientas y la insignia `15/15`: barra con nombres 717,3 px, botones 484,8 px; en una línea hacen falta 12 + 717,3 + 8 + 484,8 + 12 = 1234,1, más la holgura de 24 → **`buttonsBelowWidth = 1260`** (antes 1030). La barra con nombres más márgenes mide 741,3, más 24 → **`narrowWidth = 770`** (antes 480): por debajo, la barra va sin nombres (433,2 px, cabe en cualquier móvil apaisado). En iOS, con SF Pro y la insignia 16/16, 1300 y 800 pt.
15. **Guardado:** en F2 (rocas con `id`, `position` y `hitsTaken`; el pico va con los objetos del suelo).

## Reparto

| Tarea | Qué |
|---|---|
| TF5.1 | Piedra y pico en el HUD (enums, textos, iconos, umbrales) |
| TF5.2 | Frames `rock-large` y `pickaxe-pickup` |
| TF5.3 | Picar rocas (dominio, caso de uso, bloc y escena) |
| TF5.4 | Rocas y pico en el nivel, piedra en los costes |
| TF5.5 | Cierre: T1, `PROGRESS.md`, README, `CLAUDE.md` |

---

### Task TF5.1: Piedra y pico en el HUD

**Files:**
- Create: `lib/core/assets/images/icons/stone.svg`, `lib/core/assets/images/icons/pickaxe.svg`
- Modify: `lib/core/config/constants/enum/resource.dart`, `lib/core/config/constants/enum/tool_kind.dart`, `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`, `lib/layers/presentation/theme/images/custom_icons.dart`, `lib/layers/presentation/features/forest/game/atlas/sprite_names.dart`, `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`

**Interfaces:**
- Produces: `enum Resource { wood, gold, mana, stone }`, `enum ToolKind { axe, pickaxe }`; `CustomIcons.stone` / `CustomIcons.pickaxe`; `SpriteNames.item(ToolKind.pickaxe) == 'pickaxe-pickup'` (el frame llega en TF5.2; ningún pico está en el suelo hasta TF5.4); `Internationalize.forestMessagePickedUpPickaxe` / `forestMessagePickedUpPickaxeTouch`; `HudOverlay.narrowWidth == 770`, `HudOverlay.buttonsBelowWidth == 1260`.

- [ ] **Step 1: enums** — `enum Resource { wood, gold, mana, stone }` y `enum ToolKind { axe, pickaxe }`.
- [ ] **Step 2: iconos** — copiar `$IOS/Farming/Assets.xcassets/Icons/stone.imageset/stone.svg` y `pickaxe.imageset/pickaxe.svg` a `lib/core/assets/images/icons/` (la carpeta ya está en `pubspec.yaml`):

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="14" viewBox="0 0 22 14">
  <path d="M1 13.5L2.5 6.5L7.5 3L12.5 4.5L15 13.5Z" fill="#5A5E68"/>
  <path d="M2.5 6.5L7.5 3L12.5 4.5L10.5 8L4.5 8.5Z" fill="#A0A6B0"/>
  <path d="M12.5 13.5L14 8.5L17.5 6L21.5 8.5L21.5 13.5Z" fill="#464A53"/>
  <path d="M14 8.5L17.5 6L21.5 8.5L17.5 10Z" fill="#878D97"/>
</svg>
```
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
  <path d="M3 20L15 7" stroke="#8A5A2B" stroke-width="2.6" stroke-linecap="round"/>
  <path d="M7.5 2Q17 0.5 21.5 11.5L19.5 12.5Q16 5 7.5 4.5Z" fill="#C9CED6"/>
</svg>
```
- [ ] **Step 3: textos** — en `es.json`, `forest.resource.stone`, `forest.amount.stone`, `forest.tool.pickaxe`, `forest.message.pickedUpPickaxe` y `forest.message.pickedUpPickaxeTouch` (decisión 13); en `Internationalize`:

```diff
@@ -45,7 +45,9 @@ class Internationalize {
     Resource.gold => '$_forest.resource.gold'.tr(),
     Resource.mana => '$_forest.resource.mana'.tr(),
+    Resource.stone => '$_forest.resource.stone'.tr(),
   };
   static String forestTool({required ToolKind tool}) => switch (tool) {
     ToolKind.axe => '$_forest.tool.axe'.tr(),
+    ToolKind.pickaxe => '$_forest.tool.pickaxe'.tr(),
   };
   static String get forestBuild => '$_forest.hud.build'.tr();
@@ -59,4 +61,5 @@ class Internationalize {
     Resource.gold => '$_forest.amount.gold'.tr(namedArgs: {'amount': '$amount'}),
     Resource.mana => '$_forest.amount.mana'.tr(namedArgs: {'amount': '$amount'}),
+    Resource.stone => '$_forest.amount.stone'.tr(namedArgs: {'amount': '$amount'}),
   };
   static String forestMissing({required String amounts}) => '$_forest.hud.missing'.tr(namedArgs: {'amounts': amounts});
@@ -93,4 +96,6 @@ class Internationalize {
   static String get forestMessagePickedUpAxe => '$_forest.message.pickedUpAxe'.tr();
   static String get forestMessagePickedUpAxeTouch => '$_forest.message.pickedUpAxeTouch'.tr();
+  static String get forestMessagePickedUpPickaxe => '$_forest.message.pickedUpPickaxe'.tr();
+  static String get forestMessagePickedUpPickaxeTouch => '$_forest.message.pickedUpPickaxeTouch'.tr();
   static String get forestMessageBlockedSite => '$_forest.message.blockedSite'.tr();
   static String get forestMessageNotEnoughResources => '$_forest.message.notEnoughResources'.tr();
```
- [ ] **Step 4: `CustomIcons`, `SpriteNames` y el aviso de recogida**

```diff
@@ -8,5 +8,7 @@ abstract final class CustomIcons {
   static const String gold = '$_path/gold.svg';
   static const String mana = '$_path/mana.svg';
+  static const String stone = '$_path/stone.svg';
   static const String axe = '$_path/axe.svg';
+  static const String pickaxe = '$_path/pickaxe.svg';
   static const String hero = '$_path/hero.svg';
   static const String arena = '$_path/arena.svg';
@@ -17,8 +19,10 @@ abstract final class CustomIcons {
     Resource.gold => gold,
     Resource.mana => mana,
+    Resource.stone => stone,
   };
 
   static String tool(ToolKind tool) => switch (tool) {
     ToolKind.axe => axe,
+    ToolKind.pickaxe => pickaxe,
   };
 }
```
```diff
@@ -22,4 +22,5 @@ abstract final class SpriteNames {
   static String item(ToolKind kind) => switch (kind) {
     ToolKind.axe => 'axe-pickup',
+    ToolKind.pickaxe => 'pickaxe-pickup',
   };
 }
```
```diff
@@ -323,4 +323,8 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
           ToolKind.axe =>
             _isTouchInput ? Internationalize.forestMessagePickedUpAxeTouch : Internationalize.forestMessagePickedUpAxe,
+          ToolKind.pickaxe =>
+            _isTouchInput
+                ? Internationalize.forestMessagePickedUpPickaxeTouch
+                : Internationalize.forestMessagePickedUpPickaxe,
         });
         effects.add(ItemPickedUpEffect(itemId: itemId));
```
- [ ] **Step 5: umbrales del HUD** (decisión 14). Medir con un test de widget de usar y tirar en el *scratchpad* (`flutter test <ruta absoluta>` desde la raíz del repo) que pinta `HudOverlay` a 3000 × 720 con `ResourceItemData(…, amount: 9999)` de cada `Resource`, `ToolItemData(…, isOwned: true)` de cada `ToolKind` e insignia `15/15`, y lee el ancho de `ResourceBar`, el de la fila de botones (el `Row` antecesor del botón *Misiones*) y el de `ResourceBar(showLabels: false)`. Con los resultados:

```diff
@@ -16,6 +16,6 @@ import 'resource_bar.dart';
 
 class HudOverlay extends StatefulWidget {
-  static const double narrowWidth = 480;
-  static const double buttonsBelowWidth = 1030;
+  static const double narrowWidth = 770;
+  static const double buttonsBelowWidth = 1260;
   static const double _margin = 12;
 
```
- [ ] **Step 6: Verificar**

```sh
dart format --line-length 120 lib/core/config/constants/enum/resource.dart lib/core/config/constants/enum/tool_kind.dart lib/core/assets/i18n/internationalize.dart lib/layers/presentation/theme/images/custom_icons.dart lib/layers/presentation/features/forest/game/atlas/sprite_names.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart lib/layers/presentation/features/forest/widgets/hud_overlay.dart
flutter analyze lib
```
Esperado: `No issues found!`.

- [ ] **Step 7: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F5]: Add stone and the pickaxe to the HUD`.

### Task TF5.2: Frames `rock-large` y `pickaxe-pickup`

**Files:**
- Modify: `asset-packs/lpc/build_assets.py`, `lib/core/assets/images/lpc/forest.{png,json}` (generados), `lib/core/assets/images/lpc/CREDITS.md`

**Interfaces:**
- Produces: frames `rock-large` (61 × 45, pivote (0.5, 0.8)) y `pickaxe-pickup` (24 × 27, pivote (0.5, 0.5)) en `forest.json`.

- [ ] **Step 1: `build_assets.py`** (el código de iOS, tarea 2 de su plan):

```diff
@@ -10,5 +10,5 @@ Outputs (into lib/core/assets/images/lpc/, the one copy the Flutter app reads on
                                    back and front layers (same layout as the LPC generator)
   forest.png + forest.json         JSON-hash atlas (TexturePacker format): trees and sapling (pivot = trunk base), decor, stump,
-                                   axe pickup, the house, the forge, the armory and the mage tower
+                                   large rock, axe and pickaxe pickups, the house, the forge, the armory and the mage tower
                                    (pivot = bottom centre)
   ground.png                       grass tile(s) for the tilemap (32x32 each, in a row)
@@ -168,4 +168,10 @@ STUMP_BOX = (391, 395, 441, 436)  # terrain_atlas.png
 SAPLING_BOX = (416, 800, 448, 832)  # terrain_atlas.png, a young woody plant among the farm crops
 AXE_PICKUP = (1, 5)  # (row, column) of a 128px axe frame (back + front layers) showing the whole axe
+ROCK_BOX = (864, 736, 928, 800)  # terrain_atlas.png, a large grey boulder with two pebbles
+ROCK_PIVOT_Y = 0.8  # the centre of the rock's base, where its round footprint sits
+# There is no LPC pickaxe in sources/tools: the pickaxe on the ground is the axe pickup mirrored, with the wooden
+# handle and the blade recoloured grey. Each axe colour maps to the grey at the same index.
+AXE_COLOURS = [(174, 118, 75), (105, 71, 51), (77, 74, 93), (114, 107, 126), (134, 126, 127), (196, 181, 159)]
+PICKAXE_COLOURS = [(150, 150, 156), (96, 96, 102), (64, 66, 74), (92, 96, 106), (120, 124, 132), (170, 174, 182)]
 
 # House assembled from LPC cottage pieces: a 3x3 timber-frame wall, a thatched hip roof on top
@@ -306,4 +312,9 @@ def build_forest() -> None:
     frames["axe-pickup"] = trim(axe, "axe-pickup")
     pivots["axe-pickup"] = {"x": 0.5, "y": 0.5}
+    pickaxe = recolour(frames["axe-pickup"].copy(), AXE_COLOURS, PICKAXE_COLOURS)
+    frames["pickaxe-pickup"] = pickaxe.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
+    pivots["pickaxe-pickup"] = {"x": 0.5, "y": 0.5}
+    frames["rock-large"] = trim(terrain.crop(ROCK_BOX), "rock-large")
+    pivots["rock-large"] = {"x": 0.5, "y": ROCK_PIVOT_Y}
     frames["house"] = build_house()
     pivots["house"] = {"x": 0.5, "y": 1}
```
- [ ] **Step 2: regenerar** — copiar antes `forest.{png,json}` al *scratchpad*, `cd asset-packs/lpc && python3 build_assets.py` y comparar frame a frame (recorte de cada frame del atlas viejo y del nuevo con Pillow): solo se añaden `rock-large` y `pickaxe-pickup`; ningún otro frame cambia de píxeles ni de pivote (el empaquetado puede moverlos). Mirar los dos frames nuevos ampliados ×4 con *Read*: roca gris con dos guijarros; pico gris reflejado.
- [ ] **Step 3: `CREDITS.md`** — sin autores nuevos, dos frases:

```diff
@@ -21,5 +21,6 @@ Clothes and hair recoloured.
 | Axe and hammer (tools) | bluecarrot16, JaidynReiman, Pierre Vigier (pvigier), Tuomo Untinen (reemax) | OGA-BY 3.0, CC-BY 4.0, CC-BY-SA 3.0+, GPL 2.0+ |
 
-The axe pickup sprite in `forest.png` is cropped from the axe tool sheet.
+The axe pickup sprite in `forest.png` is cropped from the axe tool sheet. The pickaxe pickup sprite
+(`pickaxe-pickup`) is that same axe, mirrored and recoloured grey (there is no LPC pickaxe among the sources).
 
 Sources: <https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles>,
@@ -56,4 +57,5 @@ The mage tower roof is recoloured violet and stretched 40 % taller.
 
 The stump (`stump` frame) comes from the LPC Tile Atlas above.
+The large rock (`rock-large` frame) is a grey boulder of the LPC Tile Atlas above.
 The sapling (`sapling` frame) is a young plant from the farming crops of the LPC Tile Atlas above (Daniel Eddeland).
 
```
- [ ] **Step 4: Commit** — `git add asset-packs lib/core/assets/images/lpc` y, aparte, el commit `[PROJECT-F5]: Add the rock and pickaxe frames`.

### Task TF5.3: Picar rocas

**Files:**
- Create: `lib/core/config/constants/enum/mine_result.dart`, `lib/layers/domain/entities/rock/rock_entity.dart`, `lib/layers/domain/world/extensions/rock_rules.dart`, `lib/layers/domain/world/mining.dart`, `lib/layers/domain/use-cases/game/mine_rock_use_case.dart`, `lib/layers/presentation/features/forest/game/render/rock_motion.dart`, `lib/layers/presentation/features/forest/game/components/rock_component.dart`
- Modify: core: `enum/player_activity.dart`, `enum/forest/work_tool.dart`, `enum/forest/particle_kind.dart`, `es.json`, `internationalize.dart`; dominio: `intent_entity.dart`, `game_event_entity.dart`, `world_snapshot_entity.dart`, `get_world_snapshot_use_case.dart`, `rules.dart`, `work.dart`, `world.dart`, `world_state.dart`, `stats_recording.dart`, `extensions/activity_rules.dart`; presentación: `forest_bloc.dart`, `forest_event.dart`, `forest_page.dart`, `models/forest_effect.dart`, `game/forest_world.dart`, `game/forest_scene_component.dart`, `game/atlas/sprite_names.dart`, `game/particles/particle_bursts.dart`, `game/particles/particle_burst_component.dart`, `game/render/player_frames.dart`; generado: `lib/core/config/di/di.config.dart`

**Interfaces:**
- Consumes: `Resource.stone`, `ToolKind.pickaxe` (TF5.1); frame `rock-large` (TF5.2).
- Produces:
  - `enum MineResult { ok, noPickaxe, unknownRock }`; `PlayerActivity.mining`; `WorkTool.pickaxe`; `ParticleKind.stoneChip`.
  - `RockEntity`, `RockRules.hit()`, `MineIntentEntity({required String rockId})`, `RockHitEventEntity({required String rockId})`, `RockBrokenEventEntity({required String rockId, required int stone})`.
  - `World({…, List<RockEntity> rocks = const [], …})`, `World.rocks`, `World.orderMine(String rockId) → MineResult`; `WorldState(…, required List<RockEntity> rocks)` y `WorldState.rocks`; `WorldSnapshotEntity.rocks` (obligatorio).
  - `Rules.mineIntervalMs = 750`, `rockRadius = 22`, `rockStoneYield = 8`, `rockHitsToBreak = 8`.
  - `MineRockUseCase.call({required String rockId}) → MineResult` (`@Injectable()`); `ForestBloc(…, required MineRockUseCase mineRockUseCase, …)`.
  - `ForestMapClicked({…, String? rockId, …})`; `RockHitEffect({rockId, fromX})`, `RockBrokenEffect({rockId, stone})`; `ForestSceneComponent.rockAt(Vector2)` y `.rocks`; `RockComponent`, `RockMotion`; `ParticleBursts.stoneChips({rockBase, playerOnLeft, random})`, `ParticleBursts.stoneImpactHeight = 14`; `SpriteNames.rock = 'rock-large'`.
  - Textos `Internationalize.forestMessageNeedPickaxe`, `forestMessageStoneGained({required int amount})`, `forestFloatingStoneGained({required int amount})`.
- Hasta TF5.4 el nivel no tiene rocas (`World(rocks: const [])`): la tarea compila y no cambia el juego.

- [ ] **Step 1: enums** — `enum MineResult { ok, noPickaxe, unknownRock }` (nuevo, `mine_result.dart`), `PlayerActivity { idle, walking, chopping, constructing, mining }`, `WorkTool { axe, hammer, pickaxe }`, `ParticleKind { woodChip, dust, sparkle, bloodDrop, magicSparkle, stoneChip }`.
- [ ] **Step 2: `rock_entity.dart`** (nuevo)

```dart
import '../geometry/obstacle_entity.dart';
import '../geometry/position_entity.dart';

class RockEntity {
  final String id;
  final PositionEntity position;
  final double radius;
  final int stoneYield;
  final int hitsToBreak;
  final int hitsTaken;

  const RockEntity({
    required this.id,
    required this.position,
    required this.radius,
    required this.stoneYield,
    required this.hitsToBreak,
    this.hitsTaken = 0,
  }) : assert(radius > 0),
       assert(stoneYield >= 0),
       assert(hitsToBreak > 0),
       assert(hitsTaken >= 0 && hitsTaken <= hitsToBreak);

  ObstacleEntity get footprint => ObstacleEntity(position: position, radius: radius);

  int get hitsRemaining => hitsToBreak - hitsTaken;

  bool get isBroken => hitsRemaining == 0;

  RockEntity copyWith({
    String? id,
    PositionEntity? position,
    double? radius,
    int? stoneYield,
    int? hitsToBreak,
    int? hitsTaken,
  }) {
    return RockEntity(
      id: id ?? this.id,
      position: position ?? this.position,
      radius: radius ?? this.radius,
      stoneYield: stoneYield ?? this.stoneYield,
      hitsToBreak: hitsToBreak ?? this.hitsToBreak,
      hitsTaken: hitsTaken ?? this.hitsTaken,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RockEntity &&
      other.id == id &&
      other.position == position &&
      other.radius == radius &&
      other.stoneYield == stoneYield &&
      other.hitsToBreak == hitsToBreak &&
      other.hitsTaken == hitsTaken;

  @override
  int get hashCode => Object.hash(id, position, radius, stoneYield, hitsToBreak, hitsTaken);
}
```
- [ ] **Step 3: `rock_rules.dart`** (nuevo)

```dart
import '../../entities/rock/rock_entity.dart';

extension RockRules on RockEntity {
  RockEntity hit() => isBroken ? this : copyWith(hitsTaken: hitsTaken + 1);
}
```
- [ ] **Step 4: intención y eventos** — al final de `intent_entity.dart` y de `game_event_entity.dart` (E8: misma jerarquía en el mismo fichero):

```diff
@@ -26,2 +26,14 @@ final class ConstructIntentEntity extends IntentEntity {
   int get hashCode => Object.hash(ConstructIntentEntity, buildingId);
 }
+
+final class MineIntentEntity extends IntentEntity {
+  final String rockId;
+
+  const MineIntentEntity({required this.rockId});
+
+  @override
+  bool operator ==(Object other) => other is MineIntentEntity && other.rockId == rockId;
+
+  @override
+  int get hashCode => Object.hash(MineIntentEntity, rockId);
+}
```
```diff
@@ -121,2 +121,27 @@ final class TreeRegrownEventEntity extends GameEventEntity {
   int get hashCode => Object.hash(TreeRegrownEventEntity, tree);
 }
+
+final class RockHitEventEntity extends GameEventEntity {
+  final String rockId;
+
+  const RockHitEventEntity({required this.rockId});
+
+  @override
+  bool operator ==(Object other) => other is RockHitEventEntity && other.rockId == rockId;
+
+  @override
+  int get hashCode => Object.hash(RockHitEventEntity, rockId);
+}
+
+final class RockBrokenEventEntity extends GameEventEntity {
+  final String rockId;
+  final int stone;
+
+  const RockBrokenEventEntity({required this.rockId, required this.stone});
+
+  @override
+  bool operator ==(Object other) => other is RockBrokenEventEntity && other.rockId == rockId && other.stone == stone;
+
+  @override
+  int get hashCode => Object.hash(RockBrokenEventEntity, rockId, stone);
+}
```
- [ ] **Step 5: `mining.dart`** (nuevo, calcado de `woodcutting.dart`)

```dart
import '../../../core/config/constants/enum/mine_result.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/rock_rules.dart';
import 'work.dart';
import 'world_state.dart';

final class Mining implements Work<MineIntentEntity> {
  const Mining();

  static MineResult check(WorldState state, String rockId) {
    if (!state.rocks.containsKey(rockId)) return MineResult.unknownRock;
    if (!state.player.inventory.hasTool(ToolKind.pickaxe)) return MineResult.noPickaxe;
    return MineResult.ok;
  }

  @override
  double get intervalMs => Rules.mineIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, MineIntentEntity intent) => state.rocks[intent.rockId]?.footprint;

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) {
    final position = target.position;
    return [
      PositionEntity(x: position.x + side * distance, y: position.y + 1),
      PositionEntity(x: position.x - side * distance, y: position.y + 1),
    ];
  }

  @override
  bool impact(WorldState state, MineIntentEntity intent, List<GameEventEntity> events) {
    final rock = state.rocks[intent.rockId]?.hit();
    if (rock == null) return true;
    events.add(RockHitEventEntity(rockId: rock.id));
    if (!rock.isBroken) {
      state.rocks[rock.id] = rock;
      return false;
    }
    state.rocks.remove(rock.id);
    state.player = state.player.withInventory(state.player.inventory.add(Resource.stone, rock.stoneYield));
    events.add(RockBrokenEventEntity(rockId: rock.id, stone: rock.stoneYield));
    return true;
  }
}
```
- [ ] **Step 6: `Rules`, `WorldState`, `Work`, `ActivityRules`, `StatsRecording`**

```diff
@@ -5,4 +5,5 @@ abstract final class Rules {
   static const double chopIntervalMs = 750;
   static const double hammerIntervalMs = 650;
+  static const double mineIntervalMs = 750;
   static const double workGap = 2;
   static const double reachTolerance = 6;
@@ -13,4 +14,7 @@ abstract final class Rules {
   static const double sproutAfterMs = 60000;
   static const double regrowAfterMs = 180000;
+  static const double rockRadius = 22;
+  static const int rockStoneYield = 8;
+  static const int rockHitsToBreak = 8;
   static const Map<TreeKind, TreeStatsEntity> treeKindStats = {
     TreeKind.slim: TreeStatsEntity(woodYield: 4, hitsToFell: 3),
```
```diff
@@ -9,4 +9,5 @@ import '../entities/hero/hero_entity.dart';
 import '../entities/item/ground_item_entity.dart';
 import '../entities/player/player_entity.dart';
+import '../entities/rock/rock_entity.dart';
 import '../entities/tree/stump_entity.dart';
 import '../entities/tree/tree_entity.dart';
@@ -21,8 +22,10 @@ class WorldState {
     required List<GroundItemEntity> items,
     required List<DecorationEntity> decorations,
+    required List<RockEntity> rocks,
     this.hero = const HeroEntity(),
   }) : assert(width > 0 && height > 0),
        trees = {for (final tree in trees) tree.id: tree},
        items = {for (final item in items) item.id: item},
+       rocks = {for (final rock in rocks) rock.id: rock},
        decorations = List.unmodifiable(decorations);
 
@@ -34,4 +37,5 @@ class WorldState {
   final Map<String, TreeEntity> trees;
   final Map<String, GroundItemEntity> items;
+  final Map<String, RockEntity> rocks;
   final Map<String, BuildingEntity> buildings = {};
   final Map<String, StumpEntity> stumps = {};
@@ -41,4 +45,5 @@ class WorldState {
   List<ObstacleEntity> obstacles() => [
     for (final tree in trees.values) tree.footprint,
+    for (final rock in rocks.values) rock.footprint,
     for (final building in buildings.values) building.footprint,
   ];
```
```diff
@@ -4,4 +4,5 @@ import '../entities/geometry/position_entity.dart';
 import '../entities/player/intent_entity.dart';
 import 'construction.dart';
+import 'mining.dart';
 import 'woodcutting.dart';
 import 'world_state.dart';
@@ -36,3 +37,4 @@ BoundWork<IntentEntity> workFor(IntentEntity intent) => switch (intent) {
   ChopIntentEntity() => BoundWork<ChopIntentEntity>(const Woodcutting(), intent),
   ConstructIntentEntity() => BoundWork<ConstructIntentEntity>(const Construction(), intent),
+  MineIntentEntity() => BoundWork<MineIntentEntity>(const Mining(), intent),
 };
```
```diff
@@ -10,4 +10,5 @@ extension ActivityRules on ActivityEntity {
       ChopIntentEntity() => PlayerActivity.chopping,
       ConstructIntentEntity() => PlayerActivity.constructing,
+      MineIntentEntity() => PlayerActivity.mining,
     },
   };
```
```diff
@@ -20,4 +20,5 @@ abstract final class StatsRecording {
       QuestCompletedEventEntity() || TreeSproutedEventEntity() => stats,
       TreeRegrownEventEntity() => stats.regrowingTree(),
+      RockHitEventEntity() || RockBrokenEventEntity() => stats,
     };
   }
```
- [ ] **Step 7: `World`**

```diff
@@ -2,4 +2,5 @@ import 'package:meta/meta.dart';
 
 import '../../../core/config/constants/enum/chop_result.dart';
+import '../../../core/config/constants/enum/mine_result.dart';
 import '../../../core/config/constants/enum/resource.dart';
 import '../../../core/config/constants/enum/resume_construction_result.dart';
@@ -18,7 +19,9 @@ import '../entities/player/intent_entity.dart';
 import '../entities/player/inventory_entity.dart';
 import '../entities/player/player_entity.dart';
+import '../entities/rock/rock_entity.dart';
 import '../entities/tree/stump_entity.dart';
 import '../entities/tree/tree_entity.dart';
 import 'construction.dart';
+import 'mining.dart';
 import 'extensions/inventory_rules.dart';
 import 'extensions/player_rules.dart';
@@ -39,4 +42,5 @@ class World {
     List<GroundItemEntity> items = const [],
     List<DecorationEntity> decorations = const [],
+    List<RockEntity> rocks = const [],
     HeroEntity hero = const HeroEntity(),
   }) : this._(
@@ -48,4 +52,5 @@ class World {
            items: items,
            decorations: decorations,
+           rocks: rocks,
            hero: hero,
          ),
@@ -73,4 +78,6 @@ class World {
   List<StumpEntity> get stumps => _state.stumps.values.toList();
 
+  List<RockEntity> get rocks => _state.rocks.values.toList();
+
   StatsEntity get stats => _state.stats;
 
@@ -99,4 +106,10 @@ class World {
   }
 
+  MineResult orderMine(String rockId) {
+    final result = Mining.check(_state, rockId);
+    if (result == MineResult.ok) _navigation.goWorkOn(MineIntentEntity(rockId: rockId));
+    return result;
+  }
+
   ConstructionResultEntity orderConstruction(BlueprintEntity blueprint, PositionEntity position) {
     final result = Construction.place(_state, blueprint, position);
```
- [ ] **Step 8: caso de uso y foto del mundo** — `mine_rock_use_case.dart` (nuevo):

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/mine_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class MineRockUseCase {
  final GameSessionRepository _sessionRepository;

  const MineRockUseCase({required this._sessionRepository});

  MineResult call({required String rockId}) => _sessionRepository.current().world.orderMine(rockId);
}
```
```diff
@@ -4,4 +4,5 @@ import '../building/building_entity.dart';
 import '../decoration/decoration_entity.dart';
 import '../item/ground_item_entity.dart';
+import '../rock/rock_entity.dart';
 import '../tree/stump_entity.dart';
 import '../tree/tree_entity.dart';
@@ -15,4 +16,5 @@ class WorldSnapshotEntity {
   final List<BuildingEntity> buildings;
   final List<StumpEntity> stumps;
+  final List<RockEntity> rocks;
 
   const WorldSnapshotEntity({
@@ -24,4 +26,5 @@ class WorldSnapshotEntity {
     required this.buildings,
     required this.stumps,
+    required this.rocks,
   });
 
@@ -35,5 +38,6 @@ class WorldSnapshotEntity {
       const ListEquality<DecorationEntity>().equals(other.decorations, decorations) &&
       const ListEquality<BuildingEntity>().equals(other.buildings, buildings) &&
-      const ListEquality<StumpEntity>().equals(other.stumps, stumps);
+      const ListEquality<StumpEntity>().equals(other.stumps, stumps) &&
+      const ListEquality<RockEntity>().equals(other.rocks, rocks);
 
   @override
@@ -46,4 +50,5 @@ class WorldSnapshotEntity {
     const ListEquality<BuildingEntity>().hash(buildings),
     const ListEquality<StumpEntity>().hash(stumps),
+    const ListEquality<RockEntity>().hash(rocks),
   );
 }
```
```diff
@@ -20,4 +20,5 @@ final class GetWorldSnapshotUseCase {
       buildings: world.buildings,
       stumps: world.stumps,
+      rocks: world.rocks,
     );
   }
```
- [ ] **Step 9: textos** — `forest.message.needPickaxe`, `forest.message.stoneGained` y `forest.floating.stoneGained` en `es.json` (decisión 13), y:

```diff
@@ -93,4 +93,5 @@ class Internationalize {
   static String get forestMessageWelcome => '$_forest.message.welcome'.tr();
   static String get forestMessageNeedAxe => '$_forest.message.needAxe'.tr();
+  static String get forestMessageNeedPickaxe => '$_forest.message.needPickaxe'.tr();
   static String get forestMessageBlockedPath => '$_forest.message.blockedPath'.tr();
   static String get forestMessagePickedUpAxe => '$_forest.message.pickedUpAxe'.tr();
@@ -105,4 +106,6 @@ class Internationalize {
   static String forestMessageWoodGained({required int wood}) =>
       '$_forest.message.woodGained'.tr(namedArgs: {'wood': '$wood'});
+  static String forestMessageStoneGained({required int amount}) =>
+      '$_forest.message.stoneGained'.tr(namedArgs: {'amount': '$amount'});
   static String forestMessagePlacing({required String name}) =>
       '$_forest.message.placing'.tr(namedArgs: {'name': name});
@@ -119,4 +122,6 @@ class Internationalize {
   static String forestFloatingWoodGained({required int wood}) =>
       '$_forest.floating.woodGained'.tr(namedArgs: {'wood': '$wood'});
+  static String forestFloatingStoneGained({required int amount}) =>
+      '$_forest.floating.stoneGained'.tr(namedArgs: {'amount': '$amount'});
   static String get forestHero => '$_forest.hero.title'.tr();
   static String get forestHeroPower => '$_forest.hero.power'.tr();
```
- [ ] **Step 10: efectos, evento y bloc** — `RockHitEffect` / `RockBrokenEffect` al final de `forest_effect.dart`; `rockId` en `ForestMapClicked`; el bloc pide el caso de uso, ordena picar, reacciona a los eventos y saca la herramienta con un `switch` exhaustivo:

```diff
@@ -138,2 +138,30 @@ final class TreeRegrownEffect extends ForestEffect {
   int get hashCode => Object.hash(TreeRegrownEffect, treeId);
 }
+
+final class RockHitEffect extends ForestEffect {
+  final String rockId;
+  final double fromX;
+
+  const RockHitEffect({required this.rockId, required this.fromX});
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) || other is RockHitEffect && other.rockId == rockId && other.fromX == fromX;
+
+  @override
+  int get hashCode => Object.hash(RockHitEffect, rockId, fromX);
+}
+
+final class RockBrokenEffect extends ForestEffect {
+  final String rockId;
+  final int stone;
+
+  const RockBrokenEffect({required this.rockId, required this.stone});
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) || other is RockBrokenEffect && other.rockId == rockId && other.stone == stone;
+
+  @override
+  int get hashCode => Object.hash(RockBrokenEffect, rockId, stone);
+}
```
```diff
@@ -19,7 +19,14 @@ final class ForestMapClicked extends ForestEvent {
   final String? treeId;
   final String? buildingId;
+  final String? rockId;
   final bool isSecondary;
 
-  const ForestMapClicked({required this.position, this.treeId, this.buildingId, this.isSecondary = false});
+  const ForestMapClicked({
+    required this.position,
+    this.treeId,
+    this.buildingId,
+    this.rockId,
+    this.isSecondary = false,
+  });
 }
 
```
```diff
@@ -15,4 +15,5 @@ import '../../../../../core/config/constants/enum/gear_option_state.dart';
 import '../../../../../core/config/constants/enum/gear_slot.dart';
 import '../../../../../core/config/constants/enum/learn_skill_result.dart';
+import '../../../../../core/config/constants/enum/mine_result.dart';
 import '../../../../../core/config/constants/enum/player_activity.dart';
 import '../../../../../core/config/constants/enum/quest_id.dart';
@@ -47,4 +48,5 @@ import '../../../../domain/use-cases/game/get_player_status_use_case.dart';
 import '../../../../domain/use-cases/game/get_quests_use_case.dart';
 import '../../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
+import '../../../../domain/use-cases/game/mine_rock_use_case.dart';
 import '../../../../domain/use-cases/game/move_player_use_case.dart';
 import '../../../../domain/use-cases/game/start_game_use_case.dart';
@@ -78,4 +80,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
   final MovePlayerUseCase _movePlayerUseCase;
   final ChopTreeUseCase _chopTreeUseCase;
+  final MineRockUseCase _mineRockUseCase;
   final CanPlaceBuildingUseCase _canPlaceBuildingUseCase;
   final ConstructBuildingUseCase _constructBuildingUseCase;
@@ -103,4 +106,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     required this._movePlayerUseCase,
     required this._chopTreeUseCase,
+    required this._mineRockUseCase,
     required this._canPlaceBuildingUseCase,
     required this._constructBuildingUseCase,
@@ -184,5 +188,5 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
       }
     } else if (!event.isSecondary) {
-      _orderAt(event.position, treeId: event.treeId, buildingId: event.buildingId);
+      _orderAt(event.position, treeId: event.treeId, buildingId: event.buildingId, rockId: event.rockId);
     }
     emit(ForestSuccess(data: _buildData(effects: effects)));
@@ -214,8 +218,19 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
   }
 
-  void _orderAt(PositionEntity position, {required String? treeId, required String? buildingId}) {
+  void _orderAt(
+    PositionEntity position, {
+    required String? treeId,
+    required String? buildingId,
+    required String? rockId,
+  }) {
     if (buildingId != null && _resumeConstructionUseCase(buildingId: buildingId) == ResumeConstructionResult.ok) {
       return;
     }
+    if (rockId != null) {
+      if (_mineRockUseCase(rockId: rockId) == MineResult.noPickaxe) {
+        _showMessage(Internationalize.forestMessageNeedPickaxe);
+      }
+      return;
+    }
     if (treeId == null) {
       _movePlayerUseCase(x: position.x, y: position.y);
@@ -349,4 +364,9 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
       case TreeRegrownEventEntity(:final tree):
         effects.add(TreeRegrownEffect(treeId: tree.id));
+      case RockHitEventEntity(:final rockId):
+        effects.add(RockHitEffect(rockId: rockId, fromX: fromX));
+      case RockBrokenEventEntity(:final rockId, :final stone):
+        _showMessage(Internationalize.forestMessageStoneGained(amount: stone));
+        effects.add(RockBrokenEffect(rockId: rockId, stone: stone));
     }
   }
@@ -396,8 +416,8 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     final dy = status.position.y - lastPosition.y;
     final isMoving = dx != 0 || dy != 0;
-    final isWorking = status.activity == PlayerActivity.chopping || status.activity == PlayerActivity.constructing;
+    final tool = _workTool(status.activity);
     final target = status.target;
     var facing = _facing;
-    if (isWorking && target != null) {
+    if (tool != null && target != null) {
       facing = _facingFor(target.x - status.position.x, target.y - status.position.y);
     } else if (isMoving) {
@@ -405,15 +425,19 @@ class ForestBloc extends Bloc<ForestEvent, ForestState> {
     }
 
-    final PlayerPose pose = switch ((isWorking, isMoving)) {
-      (true, _) => WorkPose(
-        tool: status.activity == PlayerActivity.chopping ? WorkTool.axe : WorkTool.hammer,
-        swingProgress: status.swingProgress,
-      ),
-      (false, true) => WalkPose(withAxe: status.inventory.hasTool(ToolKind.axe)),
-      (false, false) => IdlePose(withAxe: status.inventory.hasTool(ToolKind.axe)),
+    final PlayerPose pose = switch ((tool, isMoving)) {
+      (final WorkTool tool, _) => WorkPose(tool: tool, swingProgress: status.swingProgress),
+      (null, true) => WalkPose(withAxe: status.inventory.hasTool(ToolKind.axe)),
+      (null, false) => IdlePose(withAxe: status.inventory.hasTool(ToolKind.axe)),
     };
     return PlayerRenderData(position: status.position, facing: facing, pose: pose);
   }
 
+  WorkTool? _workTool(PlayerActivity activity) => switch (activity) {
+    PlayerActivity.idle || PlayerActivity.walking => null,
+    PlayerActivity.chopping => WorkTool.axe,
+    PlayerActivity.constructing => WorkTool.hammer,
+    PlayerActivity.mining => WorkTool.pickaxe,
+  };
+
   Facing _facingFor(double dx, double dy) {
     if (dx.abs() > dy.abs()) return dx < 0 ? Facing.left : Facing.right;
```
```diff
@@ -12,4 +12,5 @@ import '../../../domain/use-cases/game/advance_game_use_case.dart';
 import '../../../domain/use-cases/game/can_place_building_use_case.dart';
 import '../../../domain/use-cases/game/chop_tree_use_case.dart';
+import '../../../domain/use-cases/game/mine_rock_use_case.dart';
 import '../../../domain/use-cases/game/resume_construction_use_case.dart';
 import '../../../domain/use-cases/game/construct_building_use_case.dart';
@@ -49,4 +50,5 @@ class ForestPage extends StatelessWidget {
         movePlayerUseCase: locator.get<MovePlayerUseCase>(),
         chopTreeUseCase: locator.get<ChopTreeUseCase>(),
+        mineRockUseCase: locator.get<MineRockUseCase>(),
         canPlaceBuildingUseCase: locator.get<CanPlaceBuildingUseCase>(),
         constructBuildingUseCase: locator.get<ConstructBuildingUseCase>(),
```
```diff
@@ -56,4 +56,5 @@ class ForestWorld extends World
         treeId: scene.treeAt(point),
         buildingId: scene.buildingAt(point),
+        rockId: scene.rockAt(point),
         isSecondary: isSecondary,
       ),
```
- [ ] **Step 11: pose** — la hoja y la secuencia del martillo:

```diff
@@ -27,5 +27,8 @@ abstract final class PlayerFrames {
 
   static int workColumn(WorkTool tool, double swingProgress) {
-    final sequence = tool == WorkTool.axe ? RenderConstants.chopSequence : RenderConstants.hammerSequence;
+    final sequence = switch (tool) {
+      WorkTool.axe => RenderConstants.chopSequence,
+      WorkTool.hammer || WorkTool.pickaxe => RenderConstants.hammerSequence,
+    };
     final step = math.min(sequence.length - 1, (swingProgress * sequence.length).floor());
     return sequence[math.max(0, step)];
@@ -36,5 +39,8 @@ abstract final class PlayerFrames {
       IdlePose(:final withAxe) => withAxe ? PlayerSheet.idleAxe : PlayerSheet.idle,
       WalkPose(:final withAxe) => withAxe ? PlayerSheet.walkAxe : PlayerSheet.walk,
-      WorkPose(:final tool) => tool == WorkTool.axe ? PlayerSheet.chop : PlayerSheet.hammer,
+      WorkPose(:final tool) => switch (tool) {
+        WorkTool.axe => PlayerSheet.chop,
+        WorkTool.hammer || WorkTool.pickaxe => PlayerSheet.hammer,
+      },
     };
   }
```
- [ ] **Step 12: `rock_motion.dart`** (nuevo, como `TreeMotion`)

```dart
import 'easing.dart';

abstract final class RockMotion {
  static const double shakeOffset = 1.5;
  static const double shakeHalfMs = 60;
  static const double shakeMs = shakeHalfMs * 2;
  static const double breakMs = 350;
  static const double breakEndScale = 0.6;

  static double direction({required double fromX, required double baseX}) => fromX < baseX ? 1 : -1;

  static double shakeX({required double elapsedMs, required double direction}) {
    if (elapsedMs < 0 || elapsedMs >= shakeMs) return 0;
    final leg = elapsedMs < shakeHalfMs ? elapsedMs / shakeHalfMs : (shakeMs - elapsedMs) / shakeHalfMs;
    return shakeOffset * direction * Easing.sineOut(leg);
  }

  static double breakScale(double elapsedMs) => 1 - (1 - breakEndScale) * _breakProgress(elapsedMs);

  static double breakOpacity(double elapsedMs) => 1 - _breakProgress(elapsedMs);

  static bool hasBroken(double elapsedMs) => elapsedMs >= breakMs;

  static double _breakProgress(double elapsedMs) => Easing.quadIn((elapsedMs / breakMs).clamp(0, 1).toDouble());
}
```
- [ ] **Step 13: `rock_component.dart`** (nuevo, como `TreeComponent`) y `SpriteNames.rock`

```dart
import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../../domain/entities/rock/rock_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import '../render/rock_motion.dart';
import 'atlas_sprite_component.dart';

class RockComponent extends AtlasSpriteComponent {
  final String rockId;
  final PositionEntity base;
  final LpcAssets _assets;
  double _direction = 1;
  double? _hitElapsedMs;
  double? _breakElapsedMs;

  RockComponent({required LpcAssets assets, required RockEntity rock})
    : rockId = rock.id,
      base = rock.position,
      _assets = assets,
      super.fromFrame(
        frame: assets.frame(SpriteNames.rock),
        sprite: assets.sprite(SpriteNames.rock),
        position: rock.position.toVector2(),
        priority: RenderDepth.bySortY(rock.position.y),
      );

  bool get isBreaking => _breakElapsedMs != null;

  @override
  bool containsPoint(Vector2 point) {
    if (isBreaking || !boundsContain(point)) return false;
    final area = bounds;
    return _assets.isOpaque(frame, (point.x - area.left).floor(), (point.y - area.top).floor());
  }

  void hit(double fromX) {
    _direction = RockMotion.direction(fromX: fromX, baseX: base.x);
    _hitElapsedMs = 0;
  }

  void shatter() {
    _hitElapsedMs = null;
    position.setValues(base.x, base.y);
    _breakElapsedMs = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsedMs = dt * 1000;
    final breakElapsed = _breakElapsedMs;
    if (breakElapsed != null) {
      final total = breakElapsed + elapsedMs;
      _breakElapsedMs = total;
      scale.setAll(RockMotion.breakScale(total));
      opacity = RockMotion.breakOpacity(total);
      if (RockMotion.hasBroken(total)) removeFromParent();
      return;
    }
    final hitElapsed = _hitElapsedMs;
    if (hitElapsed == null) return;
    final total = hitElapsed + elapsedMs;
    position.setValues(base.x + RockMotion.shakeX(elapsedMs: total, direction: _direction), base.y);
    _hitElapsedMs = total >= RockMotion.shakeMs ? null : total;
  }
}
```
```diff
@@ -8,4 +8,5 @@ abstract final class SpriteNames {
   static const String stump = 'stump';
   static const String sapling = 'sapling';
+  static const String rock = 'rock-large';
 
   static String tree(TreeKind kind) => 'tree-${kind.name.toKebabCase()}';
```
- [ ] **Step 14: esquirlas de piedra** — `woodChips` y `stoneChips` comparten `_chips`:

```diff
@@ -8,4 +8,5 @@ abstract final class ParticleBursts {
   static const int chipsPerHit = 8;
   static const double impactHeight = 10;
+  static const double stoneImpactHeight = 14;
   static const int dustPerHammer = 6;
   static const double dustLift = 4;
@@ -73,4 +74,31 @@ abstract final class ParticleBursts {
     required bool playerOnLeft,
     required math.Random random,
+  }) {
+    return _chips(
+      ParticleKind.woodChip,
+      origin: PositionEntity(x: trunkBase.x, y: trunkBase.y - impactHeight),
+      playerOnLeft: playerOnLeft,
+      random: random,
+    );
+  }
+
+  static List<Particle> stoneChips({
+    required PositionEntity rockBase,
+    required bool playerOnLeft,
+    required math.Random random,
+  }) {
+    return _chips(
+      ParticleKind.stoneChip,
+      origin: PositionEntity(x: rockBase.x, y: rockBase.y - stoneImpactHeight),
+      playerOnLeft: playerOnLeft,
+      random: random,
+    );
+  }
+
+  static List<Particle> _chips(
+    ParticleKind kind, {
+    required PositionEntity origin,
+    required bool playerOnLeft,
+    required math.Random random,
   }) {
     final minAngle = playerOnLeft ? chipAngleLeftMin : chipAngleRightMin;
@@ -80,6 +108,6 @@ abstract final class ParticleBursts {
       final angle = _between(random, minAngle, maxAngle) * math.pi / 180;
       return Particle(
-        kind: ParticleKind.woodChip,
-        origin: PositionEntity(x: trunkBase.x, y: trunkBase.y - impactHeight),
+        kind: kind,
+        origin: origin,
         velocityX: speed * math.cos(angle),
         velocityY: speed * math.sin(angle),
```
```diff
@@ -21,4 +21,6 @@ class ParticleBurstComponent extends Component {
   static const Color bloodColor = Color(0xFF9E1B1B);
   static const Rect bloodDrop = Rect.fromLTWH(-1, -1, 2, 2);
+  static const Color stoneDark = Color(0xFF4B4F58);
+  static const Color stoneLight = Color(0xFF9AA0AA);
 
   final List<Particle> _particles;
@@ -46,5 +48,5 @@ class ParticleBurstComponent extends Component {
       switch (particle.kind) {
         case ParticleKind.woodChip:
-          _renderChip(canvas, at, particle.rotationDegrees, alpha);
+          _renderChip(canvas, at, particle.rotationDegrees, alpha, dark: chipDark, light: chipLight);
         case ParticleKind.dust:
           _paint.color = dustColor.withValues(alpha: alpha);
@@ -62,4 +64,6 @@ class ParticleBurstComponent extends Component {
             magicSparkleColor.withValues(alpha: alpha),
           );
+        case ParticleKind.stoneChip:
+          _renderChip(canvas, at, particle.rotationDegrees, alpha, dark: stoneDark, light: stoneLight);
       }
     }
@@ -71,11 +75,18 @@ class ParticleBurstComponent extends Component {
   }
 
-  void _renderChip(Canvas canvas, PositionEntity at, double rotationDegrees, double alpha) {
+  void _renderChip(
+    Canvas canvas,
+    PositionEntity at,
+    double rotationDegrees,
+    double alpha, {
+    required Color dark,
+    required Color light,
+  }) {
     canvas.save();
     canvas.translate(at.x, at.y);
     canvas.rotate(rotationDegrees * math.pi / 180);
-    _paint.color = chipDark.withValues(alpha: alpha);
+    _paint.color = dark.withValues(alpha: alpha);
     canvas.drawRect(chipBody, _paint);
-    _paint.color = chipLight.withValues(alpha: alpha);
+    _paint.color = light.withValues(alpha: alpha);
     canvas.drawRect(chipHighlight, _paint);
     canvas.restore();
```
- [ ] **Step 15: escena** — rocas reconciliadas por id, `rockAt`, golpe y rotura:

```diff
@@ -22,4 +22,5 @@ import 'components/ground_item_component.dart';
 import 'components/placement_ghost_component.dart';
 import 'components/player_component.dart';
+import 'components/rock_component.dart';
 import 'components/stump_component.dart';
 import 'components/tree_component.dart';
@@ -35,4 +36,5 @@ class ForestSceneComponent extends Component {
   final Map<String, BuildingComponent> _buildings = {};
   final Map<String, StumpComponent> _stumps = {};
+  final Map<String, RockComponent> _rocks = {};
   final Set<String> _sprouting = {};
   final Set<String> _regrowing = {};
@@ -52,4 +54,6 @@ class ForestSceneComponent extends Component {
   Map<String, StumpComponent> get stumps => Map.unmodifiable(_stumps);
 
+  Map<String, RockComponent> get rocks => Map.unmodifiable(_rocks);
+
   List<AtlasSpriteComponent> get clutter => List.unmodifiable(_clutter);
 
@@ -80,4 +84,16 @@ class ForestSceneComponent extends Component {
   }
 
+  String? rockAt(Vector2 point) {
+    RockComponent? best;
+    for (final rock in _rocks.values) {
+      if (!rock.containsPoint(point)) continue;
+      if (best == null || rock.priority > best.priority) best = rock;
+    }
+    if (best == null) return null;
+    final front = best;
+    final isHidden = _trees.values.any((tree) => tree.priority > front.priority && tree.containsPoint(point));
+    return isHidden ? null : front.rockId;
+  }
+
   String? buildingAt(Vector2 point) {
     BuildingComponent? best;
@@ -122,4 +138,8 @@ class ForestSceneComponent extends Component {
       case TreeRegrownEffect(:final treeId):
         _regrowing.add(treeId);
+      case RockHitEffect(:final rockId, :final fromX):
+        _onRockHit(rockId, fromX);
+      case RockBrokenEffect(:final rockId, :final stone):
+        _onRockBroken(rockId, stone);
     }
   }
@@ -153,4 +173,28 @@ class ForestSceneComponent extends Component {
   }
 
+  void _onRockHit(String rockId, double fromX) {
+    final rock = _rocks[rockId];
+    if (rock == null) return;
+    rock.hit(fromX);
+    add(
+      ParticleBurstComponent(
+        particles: ParticleBursts.stoneChips(rockBase: rock.base, playerOnLeft: fromX < rock.base.x, random: _random),
+        sortY: ParticleBursts.chipsSortY(rock.base),
+      ),
+    );
+  }
+
+  void _onRockBroken(String rockId, int stone) {
+    final rock = _rocks.remove(rockId);
+    if (rock == null) return;
+    rock.shatter();
+    add(
+      FloatingTextComponent(
+        text: Internationalize.forestFloatingStoneGained(amount: stone),
+        at: rock.base,
+      ),
+    );
+  }
+
   void _onBuildingPlaced(BuildingEntity building) {
     _clearClutterUnder(_building(building));
@@ -223,4 +267,12 @@ class ForestSceneComponent extends Component {
     _regrowing.clear();
 
+    final rockIds = {for (final rock in world.rocks) rock.id};
+    for (final id in _rocks.keys.where((id) => !rockIds.contains(id)).toList()) {
+      _rocks.remove(id)!.removeFromParent();
+    }
+    for (final rock in world.rocks) {
+      _rocks.putIfAbsent(rock.id, () => _added(RockComponent(assets: _assets, rock: rock)));
+    }
+
     final itemIds = {for (final item in world.items) item.id};
     for (final id in _items.keys.where((id) => !itemIds.contains(id)).toList()) {
```
- [ ] **Step 16: Verificar**

```sh
dart run build_runner build --delete-conflicting-outputs   # registra MineRockUseCase en di.config.dart
dart format --line-length 120 <los .dart de lib/ escritos en esta tarea, sin di.config.dart>
flutter analyze lib
```
Esperado: `No issues found!`; `di.config.dart` solo gana `MineRockUseCase`.

- [ ] **Step 17: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F5]: Mine rocks with the pickaxe`.

### Task TF5.4: Rocas y pico en el nivel, piedra en los costes

**Files:**
- Create: `lib/layers/data/datasources/level/local/dbo/rock_dbo.dart`, `lib/layers/data/repositories/level/mappers/rock_mapper_dbo.dart`
- Modify: `lib/layers/data/datasources/level/local/dbo/level_dbo.dart`, `lib/layers/data/datasources/level/local/level_local_datasource_impl.dart`, `lib/layers/data/repositories/level/mappers/level_mapper_dbo.dart`, `lib/layers/domain/rules/blueprints.dart`; generado: `di.config.dart`

**Interfaces:**
- Consumes: `RockEntity`, `World(rocks:)`, `Rules.rock*` (TF5.3).
- Produces: `RockDBO({String? id, double? x, double? y})`, `LevelDBO.rocks`, `RockMapperDBO.toEntity(RockDBO, {required int index})` (`@Injectable()`, inyectado en `LevelMapperDBO`); el nivel con 12 rocas, el pico en `items[0]` y 94 decoraciones; los costes nuevos de `Blueprints`.

- [ ] **Step 1: `rock_dbo.dart`** (nuevo) y `LevelDBO.rocks`

```dart
class RockDBO {
  final String? id;
  final double? x;
  final double? y;

  const RockDBO({this.id, this.x, this.y});

  @override
  bool operator ==(Object other) => other is RockDBO && other.id == id && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(id, x, y);

  @override
  String toString() => 'RockDBO(id: $id, x: $x, y: $y)';
}
```
```diff
@@ -4,4 +4,5 @@ import 'decoration_dbo.dart';
 import 'item_dbo.dart';
 import 'point_dbo.dart';
+import 'rock_dbo.dart';
 import 'tree_dbo.dart';
 
@@ -13,6 +14,15 @@ class LevelDBO {
   final List<ItemDBO>? items;
   final List<DecorationDBO>? decorations;
+  final List<RockDBO>? rocks;
 
-  const LevelDBO({this.width, this.height, this.playerStart, this.trees, this.items, this.decorations});
+  const LevelDBO({
+    this.width,
+    this.height,
+    this.playerStart,
+    this.trees,
+    this.items,
+    this.decorations,
+    this.rocks,
+  });
 
   @override
@@ -24,5 +34,6 @@ class LevelDBO {
       const ListEquality<TreeDBO>().equals(other.trees, trees) &&
       const ListEquality<ItemDBO>().equals(other.items, items) &&
-      const ListEquality<DecorationDBO>().equals(other.decorations, decorations);
+      const ListEquality<DecorationDBO>().equals(other.decorations, decorations) &&
+      const ListEquality<RockDBO>().equals(other.rocks, rocks);
 
   @override
@@ -34,4 +45,5 @@ class LevelDBO {
     const ListEquality<ItemDBO>().hash(items),
     const ListEquality<DecorationDBO>().hash(decorations),
+    const ListEquality<RockDBO>().hash(rocks),
   );
 
@@ -39,4 +51,4 @@ class LevelDBO {
   String toString() =>
       'LevelDBO(width: $width, height: $height, playerStart: $playerStart, trees: $trees, items: $items, '
-      'decorations: $decorations)';
+      'decorations: $decorations, rocks: $rocks)';
 }
```
- [ ] **Step 2: datasource** (decisiones 5, 7 y 8)

```diff
@@ -6,6 +6,8 @@ import '../../../../../core/utils/seeded_random.dart';
 import '../source/level_local_datasource.dart';
 import 'dbo/decoration_dbo.dart';
+import 'dbo/item_dbo.dart';
 import 'dbo/level_dbo.dart';
 import 'dbo/point_dbo.dart';
+import 'dbo/rock_dbo.dart';
 import 'dbo/tree_dbo.dart';
 
@@ -38,4 +40,10 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
     'big',
   ];
+  static const int _rockSeed = 2026;
+  static const int _rockCount = 12;
+  static const double _minRockSpacing = 200;
+  static const double _rockTreeClearance = 60;
+  static const double _rockItemClearance = 80;
+  static const double _rockDecorationClearance = 48;
   static const int _decorationSeed = 1337;
   static const int _decorationAttempts = 107;
@@ -60,4 +68,5 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
   static const double _spawnY = _height / 2;
   static const PointDBO _playerStart = PointDBO(x: _spawnX, y: _spawnY);
+  static const ItemDBO _pickaxe = ItemDBO(id: 'pickaxe', kind: 'pickaxe', x: _spawnX + 212, y: _spawnY + 212);
 
   const LevelLocalDatasourceImpl();
@@ -66,4 +75,5 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
   LevelDBO fetch() {
     final trees = _scatterTrees();
+    final rocks = _scatterRocks(trees);
     return LevelDBO(
       width: _width,
@@ -71,6 +81,7 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
       playerStart: _playerStart,
       trees: trees,
-      items: const [],
-      decorations: _scatterDecorations(trees),
+      items: const [_pickaxe],
+      decorations: _scatterDecorations(trees).where((decoration) => _isClear(decoration, rocks)).toList(),
+      rocks: rocks,
     );
   }
@@ -97,4 +108,37 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
   }
 
+  List<RockDBO> _scatterRocks(List<TreeDBO> trees) {
+    final random = SeededRandom(_rockSeed);
+    final rocks = <RockDBO>[];
+
+    var attempt = 0;
+    while (attempt < _rockCount * 50 && rocks.length < _rockCount) {
+      attempt++;
+      final x = _borderMargin + random.next() * (_width - _borderMargin * 2);
+      final y = _borderMargin + random.next() * (_height - _borderMargin * 2);
+      final clearOfSpawn = _distance(x, y, _spawnX, _spawnY) >= _spawnClearance;
+      final clearOfPickaxe = _distance(x, y, _pickaxe.x!, _pickaxe.y!) >= _rockItemClearance;
+      final clearOfTrees =
+          !_isUnderTree(x, y, trees) && trees.every((tree) => _distance(x, y, tree.x!, tree.y!) >= _rockTreeClearance);
+      final apart = rocks.every((rock) => _distance(x, y, rock.x!, rock.y!) >= _minRockSpacing);
+      if (clearOfSpawn && clearOfPickaxe && clearOfTrees && apart) {
+        rocks.add(RockDBO(id: 'rock-${rocks.length + 1}', x: x, y: y));
+      }
+    }
+    return rocks;
+  }
+
+  bool _isClear(DecorationDBO decoration, List<RockDBO> rocks) {
+    final x = decoration.x!;
+    final y = decoration.y!;
+    final onRock = rocks.any((rock) => _distance(x, y, rock.x!, rock.y!) < _rockDecorationClearance);
+    final onPickaxe = _distance(x, y, _pickaxe.x!, _pickaxe.y!) < _decorationSpacing;
+    return !onRock && !onPickaxe;
+  }
+
+  bool _isUnderTree(double x, double y, List<TreeDBO> trees) => trees.any(
+    (tree) => (x - tree.x!).abs() < _treeHalfWidth && y > tree.y! - _treeHeight && y < tree.y! + _treeRoots,
+  );
+
   List<DecorationDBO> _scatterDecorations(List<TreeDBO> trees) {
     final random = SeededRandom(_decorationSeed);
@@ -102,7 +146,5 @@ class LevelLocalDatasourceImpl implements LevelLocalDatasource {
 
     bool isFree(double x, double y) {
-      final underTree = trees.any(
-        (tree) => (x - tree.x!).abs() < _treeHalfWidth && y > tree.y! - _treeHeight && y < tree.y! + _treeRoots,
-      );
+      final underTree = _isUnderTree(x, y, trees);
       final onSpawn = (x - _spawnX).abs() < _spawnHalfWidth && y > _spawnY - _spawnAbove && y < _spawnY + _spawnBelow;
       final crowded = decorations.any(
```
- [ ] **Step 3: `rock_mapper_dbo.dart`** (nuevo) y `LevelMapperDBO`

```dart
import 'package:injectable/injectable.dart';

import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/entities/rock/rock_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/level/local/dbo/rock_dbo.dart';

@Injectable()
class RockMapperDBO {
  RockEntity toEntity(RockDBO dbo, {required int index}) {
    return RockEntity(
      id: dbo.id ?? 'rock-${index + 1}',
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      radius: Rules.rockRadius,
      stoneYield: Rules.rockStoneYield,
      hitsToBreak: Rules.rockHitsToBreak,
    );
  }
}
```
```diff
@@ -11,4 +11,5 @@ import 'decoration_mapper_dbo.dart';
 import 'ground_item_mapper_dbo.dart';
 import 'position_mapper_dbo.dart';
+import 'rock_mapper_dbo.dart';
 import 'tree_mapper_dbo.dart';
 
@@ -19,4 +20,5 @@ class LevelMapperDBO {
   final DecorationMapperDBO _decorationMapperDBO;
   final GroundItemMapperDBO _groundItemMapperDBO;
+  final RockMapperDBO _rockMapperDBO;
 
   const LevelMapperDBO({
@@ -25,4 +27,5 @@ class LevelMapperDBO {
     required this._decorationMapperDBO,
     required this._groundItemMapperDBO,
+    required this._rockMapperDBO,
   });
 
@@ -34,4 +37,5 @@ class LevelMapperDBO {
     final items = dbo.items ?? const [];
     final decorations = dbo.decorations ?? const [];
+    final rocks = dbo.rocks ?? const [];
     return World(
       width: width,
@@ -49,4 +53,5 @@ class LevelMapperDBO {
           _decorationMapperDBO.toEntity(decorations[index], index: index),
       ],
+      rocks: [for (var index = 0; index < rocks.length; index++) _rockMapperDBO.toEntity(rocks[index], index: index)],
     );
   }
```
- [ ] **Step 4: costes** (decisión 4)

```diff
@@ -13,5 +13,5 @@ abstract final class Blueprints {
   static const BlueprintEntity forge = BlueprintEntity(
     id: BlueprintId.forge,
-    cost: {Resource.wood: 25},
+    cost: {Resource.wood: 25, Resource.stone: 10},
     hitsToBuild: 10,
     footprintRadius: 40,
@@ -20,5 +20,5 @@ abstract final class Blueprints {
   static const BlueprintEntity armory = BlueprintEntity(
     id: BlueprintId.armory,
-    cost: {Resource.wood: 25},
+    cost: {Resource.wood: 25, Resource.stone: 10},
     hitsToBuild: 10,
     footprintRadius: 40,
@@ -27,5 +27,5 @@ abstract final class Blueprints {
   static const BlueprintEntity mageTower = BlueprintEntity(
     id: BlueprintId.mageTower,
-    cost: {Resource.wood: 30, Resource.gold: 40},
+    cost: {Resource.wood: 30, Resource.gold: 40, Resource.stone: 10},
     hitsToBuild: 12,
     footprintRadius: 40,
```
- [ ] **Step 5: Verificar**

```sh
dart run build_runner build --delete-conflicting-outputs   # inyecta RockMapperDBO en LevelMapperDBO
dart format --line-length 120 lib/layers/data lib/layers/domain/rules/blueprints.dart
flutter analyze lib
```
Esperado: `No issues found!`. Comprobar las cifras con un script de usar y tirar en el *scratchpad* (`dart --packages=.dart_tool/package_config.json <script>` que llama a `LevelLocalDatasourceImpl().fetch()`): 12 rocas con las tres primeras de la decisión 5, `items` = el pico en (1012, 812), 94 decoraciones, 70 árboles.

- [ ] **Step 6: Commit** — `git add lib` y, aparte, el commit `[PROJECT-F5]: Scatter rocks and the pickaxe in the level`.

### Task TF5.5: Cierre de la fase

**Files:** `docs/boost/plans/PROGRESS.md`, `docs/boost/plans/2026-10-04-game-design/README.md`, `docs/boost/plans/2026-10-17-extras/T1-tests.md`, este plan, `CLAUDE.md`.

- [ ] **Step 1:** añadir a *Para T1* de `T1-tests.md` el bullet `- **F5** …` con la lista de la sección *Para T1* de este plan.
- [ ] **Step 2:** `PROGRESS.md`: fila F5 → `✅`, `feature/PROJECT-F5-stone`, nota "Bloque 2. Sin tests (T1)."; `README.md`: icono de F5 → ✅; cabecera de este plan con lo implementado y los desvíos.
- [ ] **Step 3:** `CLAUDE.md`: rocas (`RockEntity`, `RockRules`, `Mining`, `World.orderMine`, `MineRockUseCase`, obstáculos), el nivel (semilla 2026, pico, decoración quitada), los costes con piedra, `ForestMapClicked.rockId`, `RockComponent` / `RockMotion`, esquirlas de piedra, la pose del pico y los umbrales del HUD (1260 / 770). Sin repetir lo que ya diga.
- [ ] **Step 4: Commit** — `git add docs`; `git add CLAUDE.md` (comando aparte); el commit `[PROJECT-F5]: Close the stone phase` (comando aparte).

## Prueba manual

Se hace una vez, con el bloque 2 de la aldea, en Chrome y Android:

1. El bosque se ve igual (árboles y decoración en su sitio, con 13 huecos) con 12 rocas grises, ninguna escondida detrás de una copa; a unos 300 abajo a la derecha del inicio hay un pico gris en el suelo, reflejado respecto al hacha.
2. La barra muestra *Piedra* y el *Pico* (apagado hasta recogerlo). Por debajo de 770 px de ancho la barra va sin nombres; por debajo de 1260 los botones van debajo de la barra.
3. Tocar una roca sin pico dice "Necesitas un pico para picar.". Recoger el pico dice "¡Pico recogido! Haz clic en una roca para picarla." (con ratón) o "… Toca una roca para picarla." (táctil).
4. Con el pico, el jugador se pone a un lado y pica con el gesto del martillo; la roca tiembla y suelta esquirlas grises a cada golpe; al octavo se encoge, se desvanece, sube un "+8" dorado y sale "+8 de piedra". Después se puede pasar por su sitio. Volver a tocar la roca mientras se pica reinicia el golpe.
5. La Herrería, la Armería y la Torre de magia piden 10 de piedra ("Faltan …, 10 de piedra"); la casa no. El equipo y las habilidades cuestan lo mismo que antes.

## Para T1

Tests que dejan de compilar, cambian de resultado o son nuevos por F5 (no se ha tocado `test/`; los de iOS valen como referencia). Datos en `test/mocks/**` (p. ej. `RockEntityMock` en `test/mocks/domain/entities/rock/rock_entity_mock.dart`: `intact`, `almostBroken`; `RockDBOMock`), nunca en línea:

- **Compilación:** `ForestBloc` pide `mineRockUseCase` (todos los `ForestBloc(...)` de los tests del bosque); `WorldSnapshotEntity` pide `rocks` (`world_snapshot_entity_mock.dart`, `forest_data_mock.dart`); `WorldState` pide `rocks` si algún test lo construye; `LevelMapperDBO` pide `rockMapperDBO`; `di_test.dart` resuelve `MineRockUseCase` y `RockMapperDBO`. `architecture_test.dart`: `world/mining.dart` en `_worldInternals`.
- **Dominio:** `rock_entity_test.dart` (`footprint`, `hitsRemaining`, `isBroken`, `copyWith`, `==`, `assert`), `rock_rules_test.dart` (`hit` no pasa de `hitsToBreak`); `world_mining_test.dart`: `unknownRock` y `noPickaxe` no mueven al jugador (y `unknownRock` gana sin pico), un `RockHitEventEntity` cada 750 ms y en el octavo `RockBrokenEventEntity(stone: 8)` detrás, +8 de piedra, la roca sale de `obstacles` y de `World.rocks`, volver a tocarla reinicia el golpe; `world_regrowth_test.dart`: un tocón a 33 de una roca no rebrota y a 35 sí; `canPlace` encima de una roca → bloqueado; `stats_recording_test.dart`: los eventos de roca no cambian nada; `blueprints_test.dart` y los que cuentan costes (`get_build_options_use_case_test.dart`, el "Faltan …" del bloc): Herrería y Armería `{wood: 25, stone: 10}`, Torre `{wood: 30, gold: 40, stone: 10}`; los flujos que construyen la Herrería, la Armería o la Torre (`hero_flow` / `skill_flow`, `buy_gear_use_case_test.dart`, `learn_skill_use_case_test.dart`, escenarios de `ForestScenarioMock` / `GameScenarioMock`) necesitan 10 de piedra en el inventario; `balance_test.dart` sin cambios. `mine_rock_use_case_test.dart`; `get_world_snapshot_use_case_test.dart` con `rocks`.
- **Datos:** `level_local_datasource_impl_test.dart`: 12 rocas con el golden de las tres primeras (decisión 5); 70 árboles idénticos y 388 de madera en los DBO; 94 decoraciones sin los ids 6, 12, 17, 30, 34, 37, 40, 42, 49, 68, 81, 85 y 105 y las demás en su sitio; `items` = solo el pico en (1012, 812); invariantes de las rocas (≥ 60 de todo tronco, ≥ 200 del inicio y entre ellas, ≥ 80 del pico, fuera de las copas). Los goldens de decoración (VM y Chrome: `test/core/utils`, `test/layers/data`, `di_test.dart`) se actualizan. `level_repository_impl_test.dart` / `rock_mapper_dbo_test.dart`: sin id → `rock-<n>`, sin posición → (0, 0), cifras de `Rules`; `==` de `LevelDBO` con `rocks`.
- **Presentación:** `forest_bloc_test.dart`: "Necesitas un pico para picar.", aviso de pico recogido con ratón y táctil, `RockHitEffect` (con `fromX`) y `RockBrokenEffect` + "+8 de piedra", la pose `WorkPose(tool: WorkTool.pickaxe)`, el orden edificio → roca → árbol en `ForestMapClicked`, `HudData` con cuatro recursos y dos herramientas (`hud_data_mock.dart`); `forest_world_test.dart` / `forest_scene_component_test.dart`: `rockAt` al píxel (gana la de mayor prioridad; nada si la tapa un árbol delante), rocas reconciliadas por id, la rotura quita la roca del mapa y añade el "+8"; `rock_component_test.dart` (61 × 45, toque al píxel, sin toque al romperse, encoger y quitar a los 350 ms); `rock_motion_test.dart` (1,5 px a 60 ms, 0 a 120 ms, escala 0,6 y opacidad 0 a 350 ms); `particle_bursts_test.dart` (`stoneChips`: 8, origen 14 por encima, `ParticleKind.stoneChip`); `particle_burst_component_test.dart` si pinta cada tipo; `player_frames_test.dart` (`pickaxe` → hoja y secuencia del martillo); `LpcAssetsMock` con `rock-large` y `pickaxe-pickup`; `lpc_atlas_test.dart`, `custom_icons_test.dart`, `internationalize_test.dart` (las ocho claves nuevas); `hud_overlay_test.dart`: umbral 1260 con la insignia de 15/15 y los tests de 1259 / 1260, y `narrowWidth` 770 (con nombres cabe a 770; a 640 × 360 va sin nombres); `resource_bar_test.dart` si cuenta iconos.

## Para F2

- Guardar `WorldState.rocks` (`id`, `position`, `hitsTaken`; las rotas no vuelven) y el pico con los objetos del suelo; al cargar, una roca guardada sustituye a la del nivel con el mismo id.
