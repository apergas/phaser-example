# Fase 7 — HUD y pantalla del bosque — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Montar la pantalla jugable: `ForestPage` crea el `ForestBloc`, `_ForestView` pone el `GameWidget` de Flame (fase 6) debajo de un HUD Flutter con el mismo aspecto que el HUD web actual (madera, hacha, *Misiones*, *Construir*, barra de colocación táctil), y `ContainerApp` arranca en esa pantalla. Al terminar, las tres misiones se completan en web, Android e iOS.

**Architecture:** Patrón Page / View / State del plugin. `ForestPage` solo crea el `BlocProvider` con `locator.get<T>()` (el BLoC no se registra en DI, ver fase 4, Task 4) y lanza `ForestStarted`. `_ForestViewState` tiene un getter `bloc`, crea el `ForestGame` una sola vez y pinta `_bodyByState` con un `BlocBuilder` que solo se reconstruye al cambiar el **tipo** de estado (los ticks emiten `ForestSuccess` 60 veces por segundo). El HUD se lee con `BlocSelector<ForestBloc, ForestState, HudData?>` (se reconstruye solo cuando `HudData` cambia, gracias a su `==` escrito a mano). Abrir y cerrar los paneles del HUD es estado visual efímero (`setState` permitido por `pages.md`). Los mensajes no son widgets: el BLoC (fase 5) los muestra como snackbar con `NavigationService.showSnackbar`, y el `Scaffold` de la vista es su anfitrión.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_bloc, flame (`GameWidget`), flutter_svg (nuevo, iconos del HUD), easy_localization (`Internationalize`), get_it (`locator`), flutter_test, mockito, bloc_test.

## Global Constraints

Todas las de [`README.md`](README.md) § Global Constraints, en particular: sin comentarios en `lib/`; `dart format --line-length 120`; `flutter analyze` sin incidencias al cerrar cada tarea; textos visibles solo en `es.json` vía `Internationalize`; tests con `testWhen<Action>Then<Result>` y `// given` / `// when` / `// then`; datos de prueba en `test/mocks/**`, nunca declarados dentro del cuerpo de un test; commits `[PROJECT-X]: ...` sin ninguna atribución a una IA.

Específicas de esta fase:

- Page/View/State en un único fichero `forest_page.dart`; todos los métodos de UI privados con tipo de retorno `Widget` explícito y dentro del `State`; `_bodyByState` con `switch` expresión y caso por defecto `_`.
- Un widget por fichero en `features/forest/widgets/`. Clase de widget solo si tiene estado propio, envuelve un único modelo o se reutiliza (`HudPanel` y `HudButton` se usan en varios widgets y en la vista); si no, método privado.
- Ningún widget llama a un servicio de `core/services/`: todo pasa por eventos del BLoC. La única llamada a `locator` en presentación es la de `BlocProvider.create`.
- Iconos como SVG en `lib/core/assets/images/icons/`, registrados en `CustomIcons` (`theme/images/custom_icons.dart`) y pintados con `SvgPicture.asset` (el HUD web actual tiene iconos de madera y hacha dibujados con CSS; aquí pasan a SVG).
- Estilos de texto solo desde `CustomTextStyles` (`theme/styles/custom_text_styles.dart`, nombres `system<tamaño>w<peso>` sin color, fase 1) con el color aplicado con `copyWith(color: CustomColors.xxx)`; colores solo desde `CustomColors` (`theme/colors/custom_colors.dart`, fase 1, que ya trae `hudBackground`, `hudBorder`, `hudText`, `hudMuted`, `hudAccent`, `questDone` y `black` = fondo del bosque). `flutter_svg` ya es dependencia desde la fase 1.
- Paleta y medidas copiadas de `webApp/src/presentation/screens/forest/hud/hud.css`: fondo `rgba(28,22,16,.82)`, borde `#8a6a3f` de 2 px y radio 8, texto `#f3e7cf`, apagado `#b9a888`, acento `#e8c05a`, hecho `#7cc36b`, aviso `#e38b6b`; paneles a 12 px de los bordes; etiquetas ocultas por debajo de 480 px de ancho.
- Entrada: en web el clic derecho y `Esc` cancelan la colocación (el clic derecho lo genera `ForestGame`, fase 6; `Esc` lo atiende esta vista); en Android/iOS (también la web abierta en un móvil) aparece la barra de colocación como `bottomNavigationBar`, así los snackbars salen encima de ella, igual que en la app Compose.

---

## Contratos que consume esta fase

| Qué | Dónde | Fase |
|---|---|---|
| `locator`, `configureDependencies({required String environment})`, `DiEnvironment.dev` | `lib/core/config/di/{locator,di,di_environment}.dart` | 1 |
| `NavigationService` (`navigatorKey`, `showSnackbar`, `showErrorPopUp`) | `lib/core/services/navigation/source/navigation_service.dart` | 1 |
| `CustomColors.hudBackground, hudBorder, hudText, hudMuted, hudAccent, questDone, black` (+ `white`, `gray6` de `NavifyImpl`) | `lib/layers/presentation/theme/colors/custom_colors.dart` | 1 |
| `CustomTextStyles.system13w500, system13w700, system15w600, system18w600` | `lib/layers/presentation/theme/styles/custom_text_styles.dart` | 1 |
| `Internationalize` (fase 5 ya trae `forestWood`, `forestAxe`, `forestBuild`, `forestQuests`, `forestQuestDone`, `forestPlacementConfirm`, `forestPlacementCancel`, `forestAccessibilityGameWorld`, con `static const String _forest = 'forest'`) | `lib/core/assets/i18n/internationalize.dart` | 1, 5 |
| `ContainerApp` + `ContainerAppView` + `ContainerAppBloc()` (`ContainerAppStarted` → `ContainerAppInProgress`, `ContainerAppSuccess`; hoy `Success` pinta una pantalla vacía) | `lib/layers/presentation/app/container_app.dart`, `app/bloc/container_app_{bloc,event,state}.dart`, `test/layers/presentation/app/bloc/container_app_bloc_test.dart` | 1 |
| `CustomException.title` / `.message`, `InvalidLevelException({required String data})` | `lib/core/error-handling/exceptions/` | 1, 3 |
| `MockNavigationService` (`test/mocks/core/services/navigation_service_mocks.dart` + `.mocks.dart`) | — | 5 |
| `ForestPage` mínima (solo `GameWidget`, desactiva el menú contextual en web) y `ContainerAppView._emptyBody()` devolviendo `const ForestPage()` | `features/forest/forest_page.dart`, `app/container_app.dart` | 6 |
| `LevelRepository` + `MockLevelRepository` | `lib/layers/domain/repositories/level/level_repository.dart`, `test/mocks/domain/repositories/repository_mocks.dart` (+ `.mocks.dart`) | 2, 4 |
| Los 10 casos de uso (`StartGameUseCase` … `GetQuestsUseCase`) | `lib/layers/domain/use-cases/game/` | 4 |
| `ForestBloc({required ... startGameUseCase, movePlayerUseCase, chopTreeUseCase, canPlaceBuildingUseCase, constructBuildingUseCase, advanceGameUseCase, getPlayerStatusUseCase, getWorldSnapshotUseCase, getBuildOptionsUseCase, getQuestsUseCase, navigationService})` | `features/forest/bloc/forest_bloc.dart` | 5 |
| Eventos (todos `const`, fase 5): `ForestStarted()`, `ForestMapClicked({required PositionEntity position, String? treeId, bool isSecondary = false})`, `ForestBuildRequested({required BlueprintId blueprint})`, `ForestPlacementCancelled()` | `features/forest/bloc/forest_event.dart` | 5 |
| Estados `ForestInitial`, `ForestInProgress`, `ForestSuccess`, `ForestFailure(exception)`; `state.data.hud` (`HudData?`), `state.data.placement` (`PlacementData?`) | `features/forest/bloc/forest_state.dart` | 5 |
| `HudData({required int wood, required bool hasAxe, required String questBadge, required List<QuestItemData> quests, required List<BuildItemData> buildItems, required bool isBuildLocked})`, `QuestItemData({required String title, required String progressText, required QuestItemStatus status})`, `BuildItemData({required BlueprintId blueprint, required String name, required String costText, String? missingText, required bool isEnabled})`, `PlacementData.position`; todos con `==`/`hashCode` | `features/forest/models/` | 5 |
| `ForestGame({required ForestBloc bloc, LpcAssetsLoader? assetsLoader, math.Random? random})` (aquí solo se pasa `bloc`): envía `ForestTicked` por fotograma, `ForestMapClicked` (con `treeId` por píxel y `isSecondary` en clic derecho) y, en táctil durante la colocación, `ForestPointerMoved` | `features/forest/game/forest_game.dart` | 6 |

Si al ejecutar esta fase algún nombre de las fases 1, 5 o 6 difiere de esta tabla, se usa el nombre real y la diferencia se anota en el README § 7.

## Mapa de ficheros

```
lib/core/assets/images/icons/wood.svg                                   (nuevo)
lib/core/assets/images/icons/axe.svg                                    (nuevo)
lib/core/assets/i18n/translations/es.json                               (se amplía)
lib/core/assets/i18n/internationalize.dart                              (se amplía)
lib/core/config/constants/enum/forest/hud_menu.dart                     (nuevo)
lib/layers/presentation/theme/colors/custom_colors.dart                 (se amplía)
lib/layers/presentation/theme/styles/custom_text_styles.dart            (se amplía)
lib/layers/presentation/theme/images/custom_icons.dart                  (nuevo)
lib/layers/presentation/features/forest/widgets/hud_panel.dart
lib/layers/presentation/features/forest/widgets/hud_button.dart
lib/layers/presentation/features/forest/widgets/resource_bar.dart
lib/layers/presentation/features/forest/widgets/quest_row.dart
lib/layers/presentation/features/forest/widgets/quest_panel.dart
lib/layers/presentation/features/forest/widgets/build_option_tile.dart
lib/layers/presentation/features/forest/widgets/build_menu.dart
lib/layers/presentation/features/forest/widgets/placement_bar.dart
lib/layers/presentation/features/forest/widgets/hud_overlay.dart
lib/layers/presentation/features/forest/forest_page.dart                (se reescribe: la fase 6 dejó una versión mínima)
lib/layers/presentation/app/container_app.dart                          (Success -> carga; navega el BLoC)
lib/layers/presentation/app/bloc/container_app_bloc.dart               (recibe NavigationService)
pubspec.yaml                                                            (carpeta de iconos)
test/helpers/hud_test_app.dart
test/mocks/presentation/features/forest/models/quest_item_data_mock.dart
test/mocks/presentation/features/forest/models/build_item_data_mock.dart
test/mocks/presentation/features/forest/models/hud_data_mock.dart
test/layers/presentation/features/forest/widgets/*_test.dart            (uno por widget)
test/layers/presentation/features/forest/forest_page_test.dart
```

---

### Task 1: Tema del HUD, textos y piezas base (`HudPanel`, `HudButton`)

**Files:**
- Modify: `pubspec.yaml` (carpeta `lib/core/assets/images/icons/`)
- Modify: `lib/layers/presentation/theme/colors/custom_colors.dart`
- Modify: `lib/layers/presentation/theme/styles/custom_text_styles.dart`
- Modify: `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`
- Create: `lib/layers/presentation/features/forest/widgets/hud_panel.dart`, `hud_button.dart`
- Create: `test/helpers/hud_test_app.dart`
- Test: `test/layers/presentation/features/forest/widgets/hud_panel_test.dart`, `hud_button_test.dart`

**Interfaces:**
- Consumes: `CustomColors`, `CustomTextStyles` (fase 1), `Internationalize` con los getters `forest*` (fase 5).
- Produces:
  - Nuevos `CustomColors.hudAccentSoft, hudOptionBackground, hudWarning, hudShadow` (`Color`).
  - Nuevos `CustomTextStyles.system12w500, system12w600` (`TextStyle`).
  - `Internationalize.forestRetry` (`String`, nuevo; el resto de getters del HUD vienen de la fase 5).
  - `HudPanel({Key? key, required Widget child, EdgeInsetsGeometry padding = EdgeInsets.zero, bool isHighlighted = false})`; `HudPanel.decorationKey` (`Key` del `DecoratedBox`).
  - `HudButton({Key? key, required String label, String? badge, VoidCallback? onPressed, bool isActive = false})`; desactivado cuando `onPressed == null` (opacidad 0,5).
  - `extension HudTestApp on WidgetTester { Future<void> pumpHud(Widget child) }` (test).

- [ ] **Step 1: Declarar la carpeta de iconos en `pubspec.yaml`**

En la sección `flutter: assets:` (que ya lista `lib/core/assets/images/lpc/` y las traducciones desde la fase 1) añadir la línea:

```yaml
    - lib/core/assets/images/icons/
```

Y crear la carpeta vacía con un `.gitkeep` provisional (la Task 2 pone los SVG y lo borra):

```bash
mkdir -p lib/core/assets/images/icons && touch lib/core/assets/images/icons/.gitkeep
```

- [ ] **Step 2: Texto de *Reintentar* en `es.json` e `Internationalize`**

La fase 5 ya dejó en el bloque `"forest"` de `es.json` todos los textos del HUD (`forest.hud.*`, `forest.placement.*`, `forest.accessibility.gameWorld`) y sus getters (`forestWood`, `forestAxe`, `forestBuild`, `forestQuests`, `forestQuestDone`, `forestPlacementConfirm`, `forestPlacementCancel`, `forestAccessibilityGameWorld`). Esta fase solo añade el texto nuevo de la pantalla de error.

Comprobar lo que hay:

Run: `grep -n "forestWood\|forestPlacementConfirm\|forestAccessibilityGameWorld\|forestRetry\|_forest =" lib/core/assets/i18n/internationalize.dart`
Expected: aparecen `_forest =`, `forestWood`, `forestPlacementConfirm` y `forestAccessibilityGameWorld`; **no** aparece `forestRetry`.

En `lib/core/assets/i18n/translations/es.json`, dentro del objeto `"forest"` existente, añadir como última clave:

```json
    "retry": "Reintentar"
```

(con la coma que corresponda en la clave anterior).

En la clase `Internationalize`, tras `forestAccessibilityGameWorld`:

```dart
  static String get forestRetry => '$_forest.retry'.tr();
```

En los widget tests easy_localization no se inicializa: `.tr()` devuelve la clave tal cual (`forest.hud.wood`). Por eso los tests buscan siempre `find.text(Internationalize.forestWood)` y nunca el literal en español.

- [ ] **Step 3: Colores y estilos que faltan**

Añadir a la clase `CustomColors` existente (sin tocar ninguna constante de la fase 1):

```dart
  static const Color hudAccentSoft = Color(0x1FE8C05A);
  static const Color hudOptionBackground = Color(0x0AFFFFFF);
  static const Color hudWarning = Color(0xFFE38B6B);
  static const Color hudShadow = Color(0x66000000);
```

Añadir a la clase `CustomTextStyles` existente, junto a `system12w700` y con su mismo estilo:

```dart
  static const TextStyle system12w500 = TextStyle(fontSize: 12, fontWeight: .w500);
  static const TextStyle system12w600 = TextStyle(fontSize: 12, fontWeight: .w600);
```

- [ ] **Step 4: Ayudante de tests del HUD**

`test/helpers/hud_test_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

extension HudTestApp on WidgetTester {
  Future<void> pumpHud(Widget child) {
    return pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: CustomColors.black,
          body: child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Escribir los tests que fallan**

`test/layers/presentation/features/forest/widgets/hud_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_panel.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) {
    return tester.widget<DecoratedBox>(find.byKey(HudPanel.decorationKey)).decoration as BoxDecoration;
  }

  testWidgets('testWhenRenderedThenItHasTheHudBackgroundAndBorder', (tester) async {
    // given
    const panel = HudPanel(child: Text('content'));

    // when
    await tester.pumpHud(const Center(child: panel));

    // then
    final decoration = decorationOf(tester);
    expect(decoration.color, CustomColors.hudBackground);
    expect((decoration.border! as Border).top.color, CustomColors.hudBorder);
    expect((decoration.border! as Border).top.width, 2);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('testWhenHighlightedThenTheBorderUsesTheAccent', (tester) async {
    // given
    const panel = HudPanel(isHighlighted: true, child: Text('content'));

    // when
    await tester.pumpHud(const Center(child: panel));

    // then
    expect((decorationOf(tester).border! as Border).top.color, CustomColors.hudAccent);
  });
}
```

`test/layers/presentation/features/forest/widgets/hud_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';

import '../../../../../helpers/hud_test_app.dart';

void main() {
  testWidgets('testWhenBadgeIsGivenThenItIsShownNextToTheLabel', (tester) async {
    // given
    final button = HudButton(label: 'Misiones', badge: '1/3', onPressed: () {});

    // when
    await tester.pumpHud(Center(child: button));

    // then
    expect(find.text('Misiones'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('testWhenTappedThenOnPressedIsCalled', (tester) async {
    // given
    var taps = 0;
    await tester.pumpHud(Center(child: HudButton(label: 'Construir', onPressed: () => taps++)));

    // when
    await tester.tap(find.text('Construir'));

    // then
    expect(taps, 1);
  });

  testWidgets('testWhenOnPressedIsNullThenItIsDimmed', (tester) async {
    // given
    const button = HudButton(label: 'Construir');

    // when
    await tester.pumpHud(const Center(child: button));
    await tester.tap(find.text('Construir'));

    // then
    final opacity = tester.widget<Opacity>(find.ancestor(of: find.text('Construir'), matching: find.byType(Opacity)));
    expect(opacity.opacity, 0.5);
  });
}
```

- [ ] **Step 6: Ejecutar y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/widgets/hud_panel_test.dart test/layers/presentation/features/forest/widgets/hud_button_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/layers/presentation/features/forest/widgets/hud_panel.dart': No such file or directory`.

- [ ] **Step 7: Implementar `HudPanel`**

`lib/layers/presentation/features/forest/widgets/hud_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../theme/colors/custom_colors.dart';

class HudPanel extends StatelessWidget {
  static const Key decorationKey = Key('hudPanelDecoration');

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isHighlighted;

  const HudPanel({super.key, required this.child, this.padding = EdgeInsets.zero, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: decorationKey,
      decoration: BoxDecoration(
        color: CustomColors.hudBackground,
        border: Border.all(color: isHighlighted ? CustomColors.hudAccent : CustomColors.hudBorder, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: CustomColors.hudShadow, offset: Offset(0, 2))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
```

- [ ] **Step 8: Implementar `HudButton`**

`lib/layers/presentation/features/forest/widgets/hud_button.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_panel.dart';

class HudButton extends StatelessWidget {
  final String label;
  final String? badge;
  final VoidCallback? onPressed;
  final bool isActive;

  const HudButton({super.key, required this.label, this.badge, this.onPressed, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final badgeText = badge;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: HudPanel(
        isHighlighted: isActive,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            hoverColor: CustomColors.hudAccentSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(label, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
                  if (badgeText != null) _badge(text: badgeText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge({required String text}) {
    return DecoratedBox(
      decoration: BoxDecoration(color: CustomColors.hudAccent, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(text, style: CustomTextStyles.system12w600.copyWith(color: CustomColors.black)),
      ),
    );
  }
}
```

- [ ] **Step 9: Ejecutar y ver que pasan**

Run: `flutter test test/layers/presentation/features/forest/widgets/hud_panel_test.dart test/layers/presentation/features/forest/widgets/hud_button_test.dart`
Expected: `All tests passed!`

- [ ] **Step 10: Formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 11: Commit**

```bash
git add pubspec.yaml lib/core/assets/images/icons/.gitkeep lib/core/assets/i18n lib/layers/presentation/theme lib/layers/presentation/features/forest/widgets/hud_panel.dart lib/layers/presentation/features/forest/widgets/hud_button.dart test/helpers/hud_test_app.dart test/layers/presentation/features/forest/widgets/hud_panel_test.dart test/layers/presentation/features/forest/widgets/hud_button_test.dart
git commit -m "[PROJECT-X]: Add the HUD theme, texts, panel and button"
```

---

### Task 2: Barra de recursos (madera y hacha)

**Files:**
- Create: `lib/core/assets/images/icons/wood.svg`, `axe.svg` (y borrar `.gitkeep`)
- Create: `lib/layers/presentation/theme/images/custom_icons.dart`
- Create: `lib/layers/presentation/features/forest/widgets/resource_bar.dart`
- Test: `test/layers/presentation/features/forest/widgets/resource_bar_test.dart`

**Interfaces:**
- Consumes: `HudPanel` (Task 1), `CustomTextStyles`, `Internationalize.forestWood/forestAxe` (fase 5).
- Produces: `CustomIcons.wood`, `CustomIcons.axe` (`String` rutas de asset); `ResourceBar({Key? key, required int wood, required bool hasAxe, bool showLabels = true})`; `ResourceBar.axeKey` (`Key` del `Opacity` del hacha).

- [ ] **Step 1: Iconos SVG**

`lib/core/assets/images/icons/wood.svg` (tronco visto de lado, como `.hud__icon--wood`):

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="14" viewBox="0 0 22 14">
  <defs>
    <linearGradient id="bark" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#7A4D24"/>
      <stop offset="1" stop-color="#5A3518"/>
    </linearGradient>
  </defs>
  <path d="M4 0H15A7 7 0 0 1 15 14H4A4 4 0 0 1 0 10V4A4 4 0 0 1 4 0Z" fill="url(#bark)"/>
  <circle cx="17" cy="7" r="4.4" fill="#B3803F"/>
  <circle cx="17" cy="7" r="3.2" fill="#E3B878"/>
</svg>
```

`lib/core/assets/images/icons/axe.svg` (hoja sobre un mango, como `.hud__icon--axe`):

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22">
  <path d="M3 20L16 7" stroke="#8A5A2B" stroke-width="2.6" stroke-linecap="round"/>
  <path d="M12 3.5L15.5 0.5Q21.5 3 21.5 9.5L18.5 12.5Z" fill="#C9CED6"/>
</svg>
```

```bash
rm lib/core/assets/images/icons/.gitkeep
```

- [ ] **Step 2: `CustomIcons`**

`lib/layers/presentation/theme/images/custom_icons.dart`:

```dart
abstract final class CustomIcons {
  static const String _path = 'lib/core/assets/images/icons';

  static const String wood = '$_path/wood.svg';
  static const String axe = '$_path/axe.svg';
}
```

- [ ] **Step 3: Escribir el test que falla**

`test/layers/presentation/features/forest/widgets/resource_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/resource_bar.dart';

import '../../../../../helpers/hud_test_app.dart';

void main() {
  double axeOpacity(WidgetTester tester) => tester.widget<Opacity>(find.byKey(ResourceBar.axeKey)).opacity;

  testWidgets('testWhenRenderedThenItShowsTheWoodAmount', (tester) async {
    // given
    const bar = ResourceBar(wood: 23, hasAxe: true);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(find.text('23'), findsOneWidget);
    expect(find.text(Internationalize.forestWood), findsOneWidget);
    expect(find.text(Internationalize.forestAxe), findsOneWidget);
  });

  testWidgets('testWhenThePlayerHasNoAxeThenTheAxeIsDimmed', (tester) async {
    // given
    const bar = ResourceBar(wood: 0, hasAxe: false);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(axeOpacity(tester), 0.35);
  });

  testWidgets('testWhenThePlayerHasTheAxeThenTheAxeIsOpaque', (tester) async {
    // given
    const bar = ResourceBar(wood: 0, hasAxe: true);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(axeOpacity(tester), 1);
  });

  testWidgets('testWhenLabelsAreHiddenThenOnlyTheValueAndIconsAreShown', (tester) async {
    // given
    const bar = ResourceBar(wood: 7, hasAxe: true, showLabels: false);

    // when
    await tester.pumpHud(const Center(child: bar));

    // then
    expect(find.text('7'), findsOneWidget);
    expect(find.text(Internationalize.forestWood), findsNothing);
    expect(find.text(Internationalize.forestAxe), findsNothing);
  });
}
```

- [ ] **Step 4: Ejecutar y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/widgets/resource_bar_test.dart`
Expected: FAIL — `No such file or directory` para `resource_bar.dart`.

- [ ] **Step 5: Implementar `ResourceBar`**

`lib/layers/presentation/features/forest/widgets/resource_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/images/custom_icons.dart';
import '../../../theme/styles/custom_text_styles.dart';
import 'hud_panel.dart';

class ResourceBar extends StatelessWidget {
  static const Key axeKey = Key('resourceBarAxe');

  final int wood;
  final bool hasAxe;
  final bool showLabels;

  const ResourceBar({super.key, required this.wood, required this.hasAxe, this.showLabels = true});

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [_woodResource(), _axeResource()],
      ),
    );
  }

  Widget _woodResource() {
    return Semantics(
      label: Internationalize.forestWood,
      value: '$wood',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          SvgPicture.asset(CustomIcons.wood, width: 22, height: 14, excludeFromSemantics: true),
          if (showLabels) Text(Internationalize.forestWood, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text('$wood', style: CustomTextStyles.system18w600.copyWith(color: CustomColors.hudAccent)),
          ),
        ],
      ),
    );
  }

  Widget _axeResource() {
    return Opacity(
      key: axeKey,
      opacity: hasAxe ? 1 : 0.35,
      child: Semantics(
        label: Internationalize.forestAxe,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset(CustomIcons.axe, width: 22, height: 22, excludeFromSemantics: true),
            if (showLabels) Text(Internationalize.forestAxe, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Ejecutar y ver que pasa**

Run: `flutter test test/layers/presentation/features/forest/widgets/resource_bar_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/core/assets/images/icons lib/layers/presentation/theme/images/custom_icons.dart lib/layers/presentation/features/forest/widgets/resource_bar.dart test/layers/presentation/features/forest/widgets/resource_bar_test.dart
git commit -m "[PROJECT-X]: Add the HUD resource bar with wood and axe icons"
```

---

### Task 3: Panel de misiones (`QuestRow`, `QuestPanel`)

**Files:**
- Create: `lib/layers/presentation/features/forest/widgets/quest_row.dart`, `quest_panel.dart`
- Create: `test/mocks/presentation/features/forest/models/quest_item_data_mock.dart`
- Test: `test/layers/presentation/features/forest/widgets/quest_row_test.dart`, `quest_panel_test.dart`

**Interfaces:**
- Consumes: `QuestItemData`, `QuestItemStatus` (fase 5 / README § 3.1), `HudPanel`, `CustomTextStyles`, `Internationalize.forestQuests`.
- Produces: `QuestRow({Key? key, required QuestItemData quest})`, `QuestRow.decorationKey`, `QuestRow.checkKey`; `QuestPanel({Key? key, required List<QuestItemData> quests})`; `QuestItemDataMock.done / current / pending / all`.

- [ ] **Step 1: Datos de prueba**

Si la fase 5 ya creó `quest_item_data_mock.dart`, se añaden estos campos a su clase en vez de crear el fichero.

`test/mocks/presentation/features/forest/models/quest_item_data_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

abstract final class QuestItemDataMock {
  static final QuestItemData done = QuestItemData(
    title: 'Recoge el hacha',
    progressText: 'Hecha',
    status: QuestItemStatus.done,
  );

  static final QuestItemData current = QuestItemData(
    title: 'Consigue al menos 15 de madera',
    progressText: '6/15',
    status: QuestItemStatus.current,
  );

  static final QuestItemData pending = QuestItemData(
    title: 'Construye una casa',
    progressText: '',
    status: QuestItemStatus.pending,
  );

  static final List<QuestItemData> all = [done, current, pending];
}
```

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/presentation/features/forest/widgets/quest_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_row.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../mocks/presentation/features/forest/models/quest_item_data_mock.dart';

void main() {
  TextStyle titleStyleOf(WidgetTester tester, String title) => tester.widget<Text>(find.text(title)).style!;

  BoxDecoration rowDecorationOf(WidgetTester tester) {
    return tester.widget<DecoratedBox>(find.byKey(QuestRow.decorationKey)).decoration as BoxDecoration;
  }

  testWidgets('testWhenQuestIsDoneThenTitleIsStruckThroughAndCheckIsFilled', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.done);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 320, child: row)));

    // then
    final style = titleStyleOf(tester, QuestItemDataMock.done.title);
    expect(style.decoration, TextDecoration.lineThrough);
    expect(style.color, CustomColors.hudMuted);
    final check = tester.widget<Container>(find.byKey(QuestRow.checkKey)).decoration as BoxDecoration;
    expect((check.border! as Border).top.color, CustomColors.questDone);
    expect(find.text('Hecha'), findsOneWidget);
  });

  testWidgets('testWhenQuestIsCurrentThenRowIsHighlighted', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.current);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 320, child: row)));

    // then
    final decoration = rowDecorationOf(tester);
    expect(decoration.color, CustomColors.hudAccentSoft);
    expect((decoration.border! as Border).top.color, CustomColors.hudAccent);
    expect(find.text('6/15'), findsOneWidget);
  });

  testWidgets('testWhenQuestIsPendingThenTitleIsMutedAndRowIsNotHighlighted', (tester) async {
    // given
    final row = QuestRow(quest: QuestItemDataMock.pending);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 320, child: row)));

    // then
    final style = titleStyleOf(tester, QuestItemDataMock.pending.title);
    expect(style.color, CustomColors.hudMuted);
    expect(style.decoration, isNot(TextDecoration.lineThrough));
    expect(rowDecorationOf(tester).color, isNull);
  });
}
```

`test/layers/presentation/features/forest/widgets/quest_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_panel.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_row.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../mocks/presentation/features/forest/models/quest_item_data_mock.dart';

void main() {
  testWidgets('testWhenRenderedThenItShowsTheTitleAndOneRowPerQuest', (tester) async {
    // given
    final panel = QuestPanel(quests: QuestItemDataMock.all);

    // when
    await tester.pumpHud(Center(child: panel));

    // then
    expect(find.text(Internationalize.forestQuests.toUpperCase()), findsOneWidget);
    expect(find.byType(QuestRow), findsNWidgets(3));
  });
}
```

- [ ] **Step 3: Ejecutar y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/widgets/quest_row_test.dart test/layers/presentation/features/forest/widgets/quest_panel_test.dart`
Expected: FAIL — `No such file or directory` para `quest_row.dart`.

- [ ] **Step 4: Implementar `QuestRow`**

`lib/layers/presentation/features/forest/widgets/quest_row.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/quest_item_data.dart';

class QuestRow extends StatelessWidget {
  static const Key decorationKey = Key('questRowDecoration');
  static const Key checkKey = Key('questRowCheck');

  final QuestItemData quest;

  const QuestRow({super.key, required this.quest});

  bool get _isCurrent => quest.status == QuestItemStatus.current;

  bool get _isDone => quest.status == QuestItemStatus.done;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: decorationKey,
      decoration: BoxDecoration(
        color: _isCurrent ? CustomColors.hudAccentSoft : null,
        border: Border.all(color: _isCurrent ? CustomColors.hudAccent : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          spacing: 10,
          children: [
            _check(),
            Expanded(child: Text(quest.title, style: _titleStyle())),
            Text(
              quest.progressText,
              softWrap: false,
              style: CustomTextStyles.system13w500.copyWith(color: _isDone ? CustomColors.questDone : CustomColors.hudAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _check() {
    final color = switch (quest.status) {
      QuestItemStatus.done => CustomColors.questDone,
      QuestItemStatus.current => CustomColors.hudAccent,
      QuestItemStatus.pending => CustomColors.hudMuted,
    };
    return Container(
      key: checkKey,
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: _isDone ? const ColoredBox(color: CustomColors.questDone) : null,
    );
  }

  TextStyle _titleStyle() {
    return switch (quest.status) {
      QuestItemStatus.done => CustomTextStyles.system15w600.copyWith(
        color: CustomColors.hudMuted,
        decoration: TextDecoration.lineThrough,
      ),
      QuestItemStatus.current => CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
      QuestItemStatus.pending => CustomTextStyles.system15w600.copyWith(color: CustomColors.hudMuted),
    };
  }
}
```

- [ ] **Step 5: Implementar `QuestPanel`**

`lib/layers/presentation/features/forest/widgets/quest_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/quest_item_data.dart';
import 'hud_panel.dart';
import 'quest_row.dart';

class QuestPanel extends StatelessWidget {
  final List<QuestItemData> quests;

  const QuestPanel({super.key, required this.quests});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(),
            for (final quest in quests) QuestRow(quest: quest),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(Internationalize.forestQuests.toUpperCase(), style: CustomTextStyles.system13w700.copyWith(color: CustomColors.hudMuted, letterSpacing: 0.78)),
    );
  }
}
```

- [ ] **Step 6: Ejecutar y ver que pasan**

Run: `flutter test test/layers/presentation/features/forest/widgets/quest_row_test.dart test/layers/presentation/features/forest/widgets/quest_panel_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/layers/presentation/features/forest/widgets/quest_row.dart lib/layers/presentation/features/forest/widgets/quest_panel.dart test/mocks/presentation/features/forest/models/quest_item_data_mock.dart test/layers/presentation/features/forest/widgets/quest_row_test.dart test/layers/presentation/features/forest/widgets/quest_panel_test.dart
git commit -m "[PROJECT-X]: Add the HUD quest panel"
```

---

### Task 4: Menú de construcción (`BuildOptionTile`, `BuildMenu`)

**Files:**
- Create: `lib/layers/presentation/features/forest/widgets/build_option_tile.dart`, `build_menu.dart`
- Create: `test/mocks/presentation/features/forest/models/build_item_data_mock.dart`
- Test: `test/layers/presentation/features/forest/widgets/build_option_tile_test.dart`, `build_menu_test.dart`

**Interfaces:**
- Consumes: `BuildItemData`, `BlueprintId` (fase 5 / README § 3.1), `HudPanel`, `CustomTextStyles`.
- Produces: `BuildOptionTile({Key? key, required BuildItemData item, VoidCallback? onPressed})`; `BuildMenu({Key? key, required List<BuildItemData> items, required ValueChanged<BlueprintId> onSelected})`; `BuildItemDataMock.affordable / unaffordable`.

- [ ] **Step 1: Datos de prueba**

Si la fase 5 ya creó `build_item_data_mock.dart`, se añaden estos campos a su clase.

`test/mocks/presentation/features/forest/models/build_item_data_mock.dart`:

```dart
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/build_item_data.dart';

abstract final class BuildItemDataMock {
  static final BuildItemData affordable = BuildItemData(
    blueprint: BlueprintId.house,
    name: 'Casa',
    costText: '15 de madera',
    missingText: null,
    isEnabled: true,
  );

  static final BuildItemData unaffordable = BuildItemData(
    blueprint: BlueprintId.house,
    name: 'Casa',
    costText: '15 de madera',
    missingText: 'Faltan 9',
    isEnabled: false,
  );
}
```

- [ ] **Step 2: Escribir los tests que fallan**

`test/layers/presentation/features/forest/widgets/build_option_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/build_option_tile.dart';
import 'package:rpg/layers/presentation/theme/colors/custom_colors.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../mocks/presentation/features/forest/models/build_item_data_mock.dart';

void main() {
  testWidgets('testWhenItemIsAffordableThenTappingCallsOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpHud(
      Center(
        child: SizedBox(
          width: 300,
          child: BuildOptionTile(item: BuildItemDataMock.affordable, onPressed: () => taps++),
        ),
      ),
    );

    // when
    await tester.tap(find.text('Casa'));

    // then
    expect(taps, 1);
    expect(find.text('15 de madera'), findsOneWidget);
    expect(find.text('Faltan 9'), findsNothing);
  });

  testWidgets('testWhenItemIsNotAffordableThenItShowsTheMissingTextMuted', (tester) async {
    // given
    final tile = BuildOptionTile(item: BuildItemDataMock.unaffordable);

    // when
    await tester.pumpHud(Center(child: SizedBox(width: 300, child: tile)));

    // then
    expect(find.text('Faltan 9'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Casa')).style!.color, CustomColors.hudMuted);
    expect(tester.widget<Text>(find.text('15 de madera')).style!.color, CustomColors.hudMuted);
  });
}
```

`test/layers/presentation/features/forest/widgets/build_menu_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/build_menu.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../mocks/presentation/features/forest/models/build_item_data_mock.dart';

void main() {
  testWidgets('testWhenAnEnabledItemIsTappedThenOnSelectedReceivesItsBlueprint', (tester) async {
    // given
    final selected = <BlueprintId>[];
    await tester.pumpHud(Center(child: BuildMenu(items: [BuildItemDataMock.affordable], onSelected: selected.add)));

    // when
    await tester.tap(find.text('Casa'));

    // then
    expect(selected, [BlueprintId.house]);
  });

  testWidgets('testWhenADisabledItemIsTappedThenOnSelectedIsNotCalled', (tester) async {
    // given
    final selected = <BlueprintId>[];
    await tester.pumpHud(Center(child: BuildMenu(items: [BuildItemDataMock.unaffordable], onSelected: selected.add)));

    // when
    await tester.tap(find.text('Casa'));

    // then
    expect(selected, isEmpty);
  });
}
```

- [ ] **Step 3: Ejecutar y ver que fallan**

Run: `flutter test test/layers/presentation/features/forest/widgets/build_option_tile_test.dart test/layers/presentation/features/forest/widgets/build_menu_test.dart`
Expected: FAIL — `No such file or directory` para `build_option_tile.dart`.

- [ ] **Step 4: Implementar `BuildOptionTile`**

`lib/layers/presentation/features/forest/widgets/build_option_tile.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../theme/colors/custom_colors.dart';
import '../../../theme/styles/custom_text_styles.dart';
import '../models/build_item_data.dart';

class BuildOptionTile extends StatelessWidget {
  final BuildItemData item;
  final VoidCallback? onPressed;

  const BuildOptionTile({super.key, required this.item, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final missingText = item.missingText;
    return Material(
      color: CustomColors.hudOptionBackground,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        hoverColor: CustomColors.hudAccentSoft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: CustomTextStyles.system15w600.copyWith(color: item.isEnabled ? CustomColors.hudText : CustomColors.hudMuted),
                    ),
                  ),
                  Text(
                    item.costText,
                    style: CustomTextStyles.system13w500.copyWith(
                      color: item.isEnabled ? CustomColors.hudAccent : CustomColors.hudMuted,
                    ),
                  ),
                ],
              ),
              if (missingText != null) Text(missingText, style: CustomTextStyles.system12w500.copyWith(color: CustomColors.hudWarning)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implementar `BuildMenu`**

`lib/layers/presentation/features/forest/widgets/build_menu.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../models/build_item_data.dart';
import 'build_option_tile.dart';
import 'hud_panel.dart';

class BuildMenu extends StatelessWidget {
  final List<BuildItemData> items;
  final ValueChanged<BlueprintId> onSelected;

  const BuildMenu({super.key, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: HudPanel(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            for (final item in items)
              BuildOptionTile(item: item, onPressed: item.isEnabled ? () => onSelected(item.blueprint) : null),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Ejecutar y ver que pasan**

Run: `flutter test test/layers/presentation/features/forest/widgets/build_option_tile_test.dart test/layers/presentation/features/forest/widgets/build_menu_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/layers/presentation/features/forest/widgets/build_option_tile.dart lib/layers/presentation/features/forest/widgets/build_menu.dart test/mocks/presentation/features/forest/models/build_item_data_mock.dart test/layers/presentation/features/forest/widgets/build_option_tile_test.dart test/layers/presentation/features/forest/widgets/build_menu_test.dart
git commit -m "[PROJECT-X]: Add the HUD build menu"
```

---

### Task 5: Barra de colocación táctil

**Files:**
- Create: `lib/layers/presentation/features/forest/widgets/placement_bar.dart`
- Test: `test/layers/presentation/features/forest/widgets/placement_bar_test.dart`

**Interfaces:**
- Consumes: `HudButton` (Task 1), `Internationalize.forestPlacementConfirm/forestPlacementCancel` (fase 5).
- Produces: `PlacementBar({Key? key, required VoidCallback onConfirm, required VoidCallback onCancel})`.

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/features/forest/widgets/placement_bar_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/placement_bar.dart';

import '../../../../../helpers/hud_test_app.dart';

void main() {
  testWidgets('testWhenConfirmIsTappedThenOnConfirmIsCalled', (tester) async {
    // given
    var confirms = 0;
    var cancels = 0;
    await tester.pumpHud(PlacementBar(onConfirm: () => confirms++, onCancel: () => cancels++));

    // when
    await tester.tap(find.text(Internationalize.forestPlacementConfirm));

    // then
    expect(confirms, 1);
    expect(cancels, 0);
  });

  testWidgets('testWhenCancelIsTappedThenOnCancelIsCalled', (tester) async {
    // given
    var confirms = 0;
    var cancels = 0;
    await tester.pumpHud(PlacementBar(onConfirm: () => confirms++, onCancel: () => cancels++));

    // when
    await tester.tap(find.text(Internationalize.forestPlacementCancel));

    // then
    expect(cancels, 1);
    expect(confirms, 0);
  });
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/widgets/placement_bar_test.dart`
Expected: FAIL — `No such file or directory` para `placement_bar.dart`.

- [ ] **Step 3: Implementar `PlacementBar`**

`lib/layers/presentation/features/forest/widgets/placement_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import 'hud_button.dart';

class PlacementBar extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PlacementBar({super.key, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            HudButton(label: Internationalize.forestPlacementConfirm, isActive: true, onPressed: onConfirm),
            HudButton(label: Internationalize.forestPlacementCancel, onPressed: onCancel),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/layers/presentation/features/forest/widgets/placement_bar_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/features/forest/widgets/placement_bar.dart test/layers/presentation/features/forest/widgets/placement_bar_test.dart
git commit -m "[PROJECT-X]: Add the touch placement bar"
```

---

### Task 6: `HudOverlay` (composición y paneles)

**Files:**
- Create: `lib/core/config/constants/enum/forest/hud_menu.dart`
- Create: `lib/layers/presentation/features/forest/widgets/hud_overlay.dart`
- Create: `test/mocks/presentation/features/forest/models/hud_data_mock.dart`
- Test: `test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`

**Interfaces:**
- Consumes: `HudData` (fase 5), `ResourceBar`, `HudButton`, `QuestPanel`, `BuildMenu` (Tasks 1–4), `QuestItemDataMock`, `BuildItemDataMock`.
- Produces: `enum HudMenu { quests, build }`; `HudOverlay({Key? key, required HudData hud, required ValueChanged<BlueprintId> onBuildSelected})`; `HudOverlay.narrowWidth` (`double`, 480); `HudDataMock.start / gathering / placing`.

Comportamiento (igual que `Hud.ts`): los botones *Misiones* (con insignia `n/3`) y *Construir* abren su panel; abrir uno cierra el otro; pulsar el mismo lo cierra; elegir una opción de construir cierra el menú y avisa; *Construir* está desactivado mientras se coloca (`isBuildLocked`) y, si el menú estaba abierto, se cierra. Por debajo de 480 px de ancho se ocultan las etiquetas de recursos (`@media (max-width: 480px)`). Las zonas vacías del HUD dejan pasar los toques al juego (solo hay hijos `Positioned`).

- [ ] **Step 1: Enum del menú**

`lib/core/config/constants/enum/forest/hud_menu.dart`:

```dart
enum HudMenu { quests, build }
```

- [ ] **Step 2: Datos de prueba**

Si la fase 5 ya creó `hud_data_mock.dart`, se añaden estos campos a su clase (renombrándolos si chocan).

`test/mocks/presentation/features/forest/models/hud_data_mock.dart`:

```dart
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';

import 'build_item_data_mock.dart';
import 'quest_item_data_mock.dart';

abstract final class HudDataMock {
  static final HudData start = HudData(
    wood: 0,
    hasAxe: false,
    questBadge: '0/3',
    quests: [QuestItemDataMock.current, QuestItemDataMock.pending],
    buildItems: [BuildItemDataMock.unaffordable],
    isBuildLocked: false,
  );

  static final HudData gathering = HudData(
    wood: 23,
    hasAxe: true,
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: false,
  );

  static final HudData placing = HudData(
    wood: 23,
    hasAxe: true,
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: true,
  );
}
```

- [ ] **Step 3: Escribir los tests que fallan**

`test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/build_menu.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_button.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/hud_overlay.dart';
import 'package:rpg/layers/presentation/features/forest/widgets/quest_panel.dart';

import '../../../../../helpers/hud_test_app.dart';
import '../../../../../mocks/presentation/features/forest/models/hud_data_mock.dart';

void main() {
  Future<List<BlueprintId>> pumpOverlay(WidgetTester tester, HudData hud) async {
    final selected = <BlueprintId>[];
    await tester.pumpHud(HudOverlay(hud: hud, onBuildSelected: selected.add));
    return selected;
  }

  HudButton buildButton(WidgetTester tester) {
    return tester.widget<HudButton>(
      find.ancestor(of: find.text(Internationalize.forestBuild), matching: find.byType(HudButton)),
    );
  }

  testWidgets('testWhenRenderedThenItShowsResourcesAndTheQuestBadge', (tester) async {
    // given
    final hud = HudDataMock.gathering;

    // when
    await pumpOverlay(tester, hud);

    // then
    expect(find.text('23'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byType(QuestPanel), findsNothing);
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenQuestsButtonIsTappedThenTheQuestPanelOpens', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);

    // when
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // then
    expect(find.byType(QuestPanel), findsOneWidget);
  });

  testWidgets('testWhenQuestsButtonIsTappedTwiceThenTheQuestPanelCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // then
    expect(find.byType(QuestPanel), findsNothing);
  });

  testWidgets('testWhenBuildIsTappedWhileQuestsAreOpenThenOnlyTheBuildMenuIsShown', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestQuests));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(find.byType(BuildMenu), findsOneWidget);
    expect(find.byType(QuestPanel), findsNothing);
  });

  testWidgets('testWhenABuildOptionIsSelectedThenTheMenuClosesAndTheBlueprintIsReported', (tester) async {
    // given
    final selected = await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // when
    await tester.tap(find.text('Casa'));
    await tester.pump();

    // then
    expect(selected, [BlueprintId.house]);
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenBuildIsLockedThenTheBuildButtonIsDisabled', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.placing);

    // when
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // then
    expect(buildButton(tester).onPressed, isNull);
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenBuildBecomesLockedWhileTheMenuIsOpenThenTheMenuCloses', (tester) async {
    // given
    await pumpOverlay(tester, HudDataMock.gathering);
    await tester.tap(find.text(Internationalize.forestBuild));
    await tester.pump();

    // when
    await pumpOverlay(tester, HudDataMock.placing);

    // then
    expect(find.byType(BuildMenu), findsNothing);
  });

  testWidgets('testWhenTheScreenIsNarrowThenResourceLabelsAreHidden', (tester) async {
    // given
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // when
    await pumpOverlay(tester, HudDataMock.start);

    // then
    expect(find.text(Internationalize.forestWood), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Ejecutar y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`
Expected: FAIL — `No such file or directory` para `hud_overlay.dart`.

- [ ] **Step 5: Implementar `HudOverlay`**

`lib/layers/presentation/features/forest/widgets/hud_overlay.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../../core/assets/i18n/internationalize.dart';
import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/forest/hud_menu.dart';
import '../models/hud_data.dart';
import 'build_menu.dart';
import 'hud_button.dart';
import 'quest_panel.dart';
import 'resource_bar.dart';

class HudOverlay extends StatefulWidget {
  static const double narrowWidth = 480;

  final HudData hud;
  final ValueChanged<BlueprintId> onBuildSelected;

  const HudOverlay({super.key, required this.hud, required this.onBuildSelected});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  HudMenu? _openMenu;

  @override
  void didUpdateWidget(HudOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hud.isBuildLocked && _openMenu == HudMenu.build) {
      _openMenu = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLabels = MediaQuery.sizeOf(context).width >= HudOverlay.narrowWidth;
    return Stack(
      children: [
        Positioned(
          top: 12,
          left: 12,
          child: ResourceBar(wood: widget.hud.wood, hasAxe: widget.hud.hasAxe, showLabels: showLabels),
        ),
        Positioned(top: 12, right: 12, child: _actions()),
      ],
    );
  }

  Widget _actions() {
    final openMenu = _openMenu;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        _buttons(),
        if (openMenu != null) _menu(menu: openMenu),
      ],
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        HudButton(
          label: Internationalize.forestQuests,
          badge: widget.hud.questBadge,
          isActive: _openMenu == HudMenu.quests,
          onPressed: () => _toggle(HudMenu.quests),
        ),
        HudButton(
          label: Internationalize.forestBuild,
          isActive: _openMenu == HudMenu.build,
          onPressed: widget.hud.isBuildLocked ? null : () => _toggle(HudMenu.build),
        ),
      ],
    );
  }

  Widget _menu({required HudMenu menu}) {
    return switch (menu) {
      HudMenu.quests => QuestPanel(quests: widget.hud.quests),
      HudMenu.build => BuildMenu(items: widget.hud.buildItems, onSelected: _onBuildSelected),
    };
  }

  void _toggle(HudMenu menu) {
    setState(() => _openMenu = _openMenu == menu ? null : menu);
  }

  void _onBuildSelected(BlueprintId blueprint) {
    setState(() => _openMenu = null);
    widget.onBuildSelected(blueprint);
  }
}
```

- [ ] **Step 6: Ejecutar y ver que pasa**

Run: `flutter test test/layers/presentation/features/forest/widgets/hud_overlay_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/core/config/constants/enum/forest/hud_menu.dart lib/layers/presentation/features/forest/widgets/hud_overlay.dart test/mocks/presentation/features/forest/models/hud_data_mock.dart test/layers/presentation/features/forest/widgets/hud_overlay_test.dart
git commit -m "[PROJECT-X]: Compose the HUD overlay with its quest and build panels"
```

---

### Task 7: `ForestPage` y arranque desde `ContainerApp`

**Files:**
- Modify (reescritura completa): `lib/layers/presentation/features/forest/forest_page.dart` (versión mínima de la fase 6, Task 11)
- Modify: `lib/layers/presentation/app/bloc/container_app_bloc.dart` (recibe `NavigationService` y navega a `ForestPage`)
- Modify: `lib/layers/presentation/app/container_app.dart` (crea el BLoC con `NavigationService`; `Success` pinta la carga mientras se reemplaza la ruta)
- Test: `test/layers/presentation/features/forest/forest_page_test.dart`
- Test: `test/layers/presentation/app/bloc/container_app_bloc_test.dart`

**Interfaces:**
- Consumes: los 10 casos de uso y `NavigationService` vía `locator` (fases 1 y 4), `ForestBloc` y sus eventos/estados (fase 5), `ForestGame({required ForestBloc bloc})` (fase 6), `HudOverlay`, `PlacementBar`, `HudPanel`, `HudButton` (Tasks 1–6), `MockLevelRepository` (fase 4), `MockNavigationService` (fase 5), `InvalidLevelException` (fases 1 y 3).
- Produces: `ForestPage({Key? key})` (`const`), pantalla inicial de la app; `ContainerAppBloc({required NavigationService navigationService})`.

Vista:

- `Scaffold(backgroundColor: CustomColors.black)`: anfitrión de los snackbars que lanza el BLoC con `NavigationService.showSnackbar` (el `ScaffoldMessenger` de `MaterialApp` los pinta en el `Scaffold` visible).
- `body`: `BlocBuilder` con `buildWhen` por tipo de estado → `_bodyByState`: `ForestInProgress` y `ForestInitial` (caso `_`) → indicador de carga; `ForestSuccess` → juego + HUD; `ForestFailure` → panel con título, mensaje y *Reintentar* (`ForestStarted`).
- Juego: `Semantics(label: Internationalize.forestAccessibilityGameWorld)` sobre `GameWidget(game: _game)`; `_game` se crea una vez (`late final`) con el `bloc`.
- `Esc` → `ForestPlacementCancelled` con `CallbackShortcuts` + `Focus(autofocus: true)` por encima del `GameWidget` (las teclas que Flame no consume suben a sus ancestros).
- En web se desactiva el menú contextual del navegador mientras la pantalla está viva (el clic derecho es "cancelar").
- `bottomNavigationBar` solo en plataformas táctiles (`defaultTargetPlatform` Android/iOS, también la web en un móvil): `BlocSelector` sobre `placement`; con colocación activa muestra `PlacementBar` (confirmar = `ForestMapClicked` en la posición del fantasma; cancelar = `ForestPlacementCancelled`).

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/features/forest/forest_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';
import 'package:rpg/layers/domain/repositories/level/level_repository.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';

import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const invalidLevel = InvalidLevelException(data: 'missing width');

  late MockLevelRepository levelRepository;
  late MockNavigationService navigationService;

  setUp(() async {
    await configureDependencies(environment: DiEnvironment.dev);
    levelRepository = MockLevelRepository();
    navigationService = MockNavigationService();
    locator.allowReassignment = true;
    locator.registerFactory<LevelRepository>(() => levelRepository);
    locator.registerSingleton<NavigationService>(navigationService);
  });

  tearDown(() async {
    await locator.reset();
  });

  testWidgets('testWhenTheLevelCannotBeLoadedThenTheErrorAndRetryAreShown', (tester) async {
    // given
    when(levelRepository.load()).thenThrow(invalidLevel);

    // when
    await tester.pumpWidget(const MaterialApp(home: ForestPage()));
    await tester.pump();

    // then
    expect(find.text(invalidLevel.title), findsOneWidget);
    expect(find.text(invalidLevel.message), findsOneWidget);
    expect(find.text(Internationalize.forestRetry), findsOneWidget);
  });

  testWidgets('testWhenRetryIsTappedThenTheGameIsStartedAgain', (tester) async {
    // given
    when(levelRepository.load()).thenThrow(invalidLevel);
    await tester.pumpWidget(const MaterialApp(home: ForestPage()));
    await tester.pump();

    // when
    await tester.tap(find.text(Internationalize.forestRetry));
    await tester.pump();

    // then
    verify(levelRepository.load()).called(2);
  });
}
```

`InvalidLevelException` es `const` (fase 1 / README § 3.4). Si la fase 1 dejó las excepciones en otro fichero que `app_exceptions.dart`, se ajusta solo ese import.

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/layers/presentation/features/forest/forest_page_test.dart`
Expected: FAIL — la página mínima de la fase 6 no tiene pantalla de error: `Expected: exactly one matching candidate` / `Found 0 widgets with text "forest.retry"` (o el título de la excepción).

- [ ] **Step 3: Reescribir `ForestPage`**

Se sustituye todo el contenido de `lib/layers/presentation/features/forest/forest_page.dart` (se conservan el nombre, la creación del BLoC y la desactivación del menú contextual de la fase 6):

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/assets/i18n/internationalize.dart';
import '../../../../core/config/di/locator.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../../domain/use-cases/game/advance_game_use_case.dart';
import '../../../domain/use-cases/game/can_place_building_use_case.dart';
import '../../../domain/use-cases/game/chop_tree_use_case.dart';
import '../../../domain/use-cases/game/construct_building_use_case.dart';
import '../../../domain/use-cases/game/get_build_options_use_case.dart';
import '../../../domain/use-cases/game/get_player_status_use_case.dart';
import '../../../domain/use-cases/game/get_quests_use_case.dart';
import '../../../domain/use-cases/game/get_world_snapshot_use_case.dart';
import '../../../domain/use-cases/game/move_player_use_case.dart';
import '../../../domain/use-cases/game/start_game_use_case.dart';
import '../../theme/colors/custom_colors.dart';
import '../../theme/styles/custom_text_styles.dart';
import 'bloc/forest_bloc.dart';
import 'game/forest_game.dart';
import 'models/hud_data.dart';
import 'models/placement_data.dart';
import 'widgets/hud_button.dart';
import 'widgets/hud_overlay.dart';
import 'widgets/hud_panel.dart';
import 'widgets/placement_bar.dart';

class ForestPage extends StatelessWidget {
  const ForestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForestBloc(
        startGameUseCase: locator.get<StartGameUseCase>(),
        movePlayerUseCase: locator.get<MovePlayerUseCase>(),
        chopTreeUseCase: locator.get<ChopTreeUseCase>(),
        canPlaceBuildingUseCase: locator.get<CanPlaceBuildingUseCase>(),
        constructBuildingUseCase: locator.get<ConstructBuildingUseCase>(),
        advanceGameUseCase: locator.get<AdvanceGameUseCase>(),
        getPlayerStatusUseCase: locator.get<GetPlayerStatusUseCase>(),
        getWorldSnapshotUseCase: locator.get<GetWorldSnapshotUseCase>(),
        getBuildOptionsUseCase: locator.get<GetBuildOptionsUseCase>(),
        getQuestsUseCase: locator.get<GetQuestsUseCase>(),
        navigationService: locator.get<NavigationService>(),
      )..add(const ForestStarted()),
      child: const _ForestView(),
    );
  }
}

class _ForestView extends StatefulWidget {
  const _ForestView();

  @override
  State<_ForestView> createState() => _ForestViewState();
}

class _ForestViewState extends State<_ForestView> {
  ForestBloc get bloc => context.read<ForestBloc>();

  late final ForestGame _game = ForestGame(bloc: bloc);

  bool get _isTouchPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      BrowserContextMenu.disableContextMenu();
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      BrowserContextMenu.enableContextMenu();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.black,
      body: BlocBuilder<ForestBloc, ForestState>(
        buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
        builder: (context, state) => _bodyByState(state),
      ),
      bottomNavigationBar: _isTouchPlatform ? _placementBar() : null,
    );
  }

  Widget _bodyByState(ForestState state) {
    return switch (state) {
      ForestInProgress() => _loadingBody(),
      ForestSuccess() => _gameBody(),
      ForestFailure() => _errorBody(state),
      _ => _loadingBody(),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator(color: CustomColors.hudAccent));
  }

  Widget _gameBody() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => bloc.add(const ForestPlacementCancelled()),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              container: true,
              label: Internationalize.forestAccessibilityGameWorld,
              child: GameWidget(game: _game),
            ),
            SafeArea(child: _hud()),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    return BlocSelector<ForestBloc, ForestState, HudData?>(
      selector: (state) => state.data.hud,
      builder: (context, hud) => _hudOverlay(hud: hud),
    );
  }

  Widget _hudOverlay({required HudData? hud}) {
    if (hud == null) return const SizedBox.shrink();
    return HudOverlay(
      hud: hud,
      onBuildSelected: (blueprint) => bloc.add(ForestBuildRequested(blueprint: blueprint)),
    );
  }

  Widget _placementBar() {
    return BlocSelector<ForestBloc, ForestState, PlacementData?>(
      selector: (state) => state.data.placement,
      builder: (context, placement) => _placementActions(placement: placement),
    );
  }

  Widget _placementActions({required PlacementData? placement}) {
    if (placement == null) return const SizedBox.shrink();
    return PlacementBar(
      onConfirm: () => bloc.add(ForestMapClicked(position: placement.position, treeId: null)),
      onCancel: () => bloc.add(const ForestPlacementCancelled()),
    );
  }

  Widget _errorBody(ForestFailure state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HudPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(state.exception.title, textAlign: TextAlign.center, style: CustomTextStyles.system18w600.copyWith(color: CustomColors.hudAccent, fontFeatures: const [FontFeature.tabularFigures()])),
              Text(state.exception.message, textAlign: TextAlign.center, style: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText)),
              HudButton(label: Internationalize.forestRetry, onPressed: () => bloc.add(const ForestStarted())),
            ],
          ),
        ),
      ),
    );
  }
}
```

Notas:

- `forest_event.dart` y `forest_state.dart` son `part of 'forest_bloc.dart'` (fase 5), así que el import de `forest_bloc.dart` trae eventos y estados.
- El `buildWhen` por tipo hace que `_gameBody` (y con él el `GameWidget`) se construya una sola vez por partida; los cambios por fotograma llegan al juego por `flame_bloc` y al HUD por los `BlocSelector`.

- [ ] **Step 4: Ejecutar el test de la página**

Run: `flutter test test/layers/presentation/features/forest/forest_page_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Test que falla: el contenedor navega al bosque**

Según `references/presentation/presentation.md`, `ContainerAppView` nunca pinta la primera pantalla: el `ContainerAppBloc` navega con `NavigationService.pushReplacement` al resolver el arranque. Se sustituye `test/layers/presentation/app/bloc/container_app_bloc_test.dart` por:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/layers/presentation/app/bloc/container_app_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/forest_page.dart';

import '../../../../mocks/core/services/navigation_service_mocks.mocks.dart';

void main() {
  late MockNavigationService navigationService;

  setUp(() {
    navigationService = MockNavigationService();
  });

  test('testWhenCreatedThenTheStateIsInitial', () {
    // given
    final bloc = ContainerAppBloc(navigationService: navigationService);

    // when
    final state = bloc.state;

    // then
    expect(state, isA<ContainerAppInitial>());
  });

  blocTest<ContainerAppBloc, ContainerAppState>(
    'testWhenStartedThenEmitsInProgressAndSuccess',
    // given
    build: () => ContainerAppBloc(navigationService: navigationService),
    // when
    act: (bloc) => bloc.add(ContainerAppStarted()),
    // then
    expect: () => [isA<ContainerAppInProgress>(), isA<ContainerAppSuccess>()],
  );

  blocTest<ContainerAppBloc, ContainerAppState>(
    'testWhenStartedThenItReplacesTheRouteWithTheForestPage',
    // given
    build: () => ContainerAppBloc(navigationService: navigationService),
    // when
    act: (bloc) => bloc.add(ContainerAppStarted()),
    // then
    verify: (_) => verify(navigationService.pushReplacement(argThat(isA<ForestPage>()))).called(1),
  );
}
```

Run: `flutter test test/layers/presentation/app/bloc/container_app_bloc_test.dart`
Expected: FAIL — `No named parameter with the name 'navigationService'`.

- [ ] **Step 6: El contenedor recibe `NavigationService` y navega**

`lib/layers/presentation/app/bloc/container_app_bloc.dart` queda:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error-handling/exceptions/custom_exception.dart';
import '../../../../core/services/navigation/source/navigation_service.dart';
import '../../features/forest/forest_page.dart';

part 'container_app_event.dart';
part 'container_app_state.dart';

class ContainerAppBloc extends Bloc<ContainerAppEvent, ContainerAppState> {
  final NavigationService _navigationService;

  ContainerAppBloc({required this._navigationService}) : super(const ContainerAppInitial()) {
    on<ContainerAppEvent>((event, emit) async {
      await switch (event) {
        ContainerAppStarted() => _onStarted(event, emit),
      };
    });
  }

  Future<void> _onStarted(ContainerAppStarted event, Emitter<ContainerAppState> emit) async {
    emit(ContainerAppInProgress(data: state.data));

    _navigationService.pushReplacement(const ForestPage());
    emit(ContainerAppSuccess(data: state.data));
  }
}
```

En `lib/layers/presentation/app/container_app.dart` cambian solo dos cosas (regla "ContainerApp Consistency" del plugin: nada más):

1. El `create` del `BlocProvider`:

```dart
      create: (context) => ContainerAppBloc(navigationService: locator.get<NavigationService>())
        ..add(ContainerAppStarted()),
```

2. En `ContainerAppView._bodyByState`, el caso `Success` deja de pintar `ForestPage` directamente (la fase 6 lo dejó en `_emptyBody()`) y reutiliza la carga mientras la navegación reemplaza la ruta; se borran el método `_emptyBody` y el import `import '../features/forest/forest_page.dart';` que añadió la fase 6 (si no, `flutter analyze` avisa de import sin usar):

```dart
      ContainerAppSuccess() => _loadingBody(),
```

`pushReplacement` usa el `navigatorKey` de `NavigationService`, que ya es el del `MaterialApp`. Como el BLoC procesa el evento después del primer fotograma, el `Navigator` ya existe cuando se llama.

Run: `flutter test test/layers/presentation/app/bloc/container_app_bloc_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Suite completa, formato y análisis**

Run: `dart format --line-length 120 lib test && flutter analyze && flutter test`
Expected: `No issues found!` y `All tests passed!` (incluido `test/architecture_test.dart`: la página importa dominio, core y su propia feature, nunca `layers/data`).

- [ ] **Step 8: Commit**

```bash
git add lib/layers/presentation/features/forest/forest_page.dart lib/layers/presentation/app test/layers/presentation/features/forest/forest_page_test.dart test/layers/presentation/app/bloc/container_app_bloc_test.dart
git commit -m "[PROJECT-X]: Open the forest game with its HUD when the app starts"
```

---

### Task 8: Verificación de cierre en las tres plataformas

**Files:** ninguno (solo verificación; cualquier fallo se corrige en la tarea que corresponda con su propio test y commit, y se anota en el README § 7).

**Interfaces:**
- Consumes: la app completa de las fases 1–7.
- Produces: confirmación de que la fase cierra.

- [ ] **Step 1: Suite completa**

Run: `flutter analyze && flutter test && flutter test --platform chrome test/core/utils test/layers/data`
Expected: `No issues found!` y `All tests passed!` en las dos ejecuciones de tests.

- [ ] **Step 2: Web (ratón y teclado)**

Run: `flutter run -d chrome`

Comprobar, en este orden:

1. Aparece el snackbar de bienvenida ("Hay un hacha en el suelo, cerca de ti…"); el HUD muestra madera `0`, hacha apagada, *Misiones* `0/3`.
2. Clic en un árbol sin hacha → snackbar "Necesitas un hacha para talar."
3. Pasar por encima del hacha → snackbar "¡Hacha recogida!…", hacha opaca, *Misiones* `1/3`.
4. Clic en árboles hasta tener ≥ 15 de madera → "+5/+6 de madera" por árbol; *Misiones* `2/3`; el panel de misiones tacha las hechas y resalta la actual.
5. *Construir* → el menú muestra "Casa · 15 de madera"; elegirla → fantasma verde/rojo siguiendo el ratón, *Construir* desactivado.
6. Clic derecho → se cancela; volver a elegir Casa y pulsar `Esc` → se cancela.
7. Elegir Casa y clic en un sitio libre → "Manos a la obra…", el personaje martillea, al terminar "¡Casa construida!" y "¡Has completado todas las misiones!"; *Misiones* `3/3`.
8. Con la ventana a < 480 px de ancho, las etiquetas "Madera"/"Hacha" desaparecen y quedan los iconos.

- [ ] **Step 3: Android (táctil)**

Arrancar el emulador `Medium_Phone_API_36.0` y ejecutar: `flutter run -d emulator-5554`

Repetir los puntos 1–7 con toques. En el 5–7: con la colocación activa aparece abajo la barra *Construir aquí* / *Cancelar*; tocar el mapa mueve el fantasma; *Cancelar* la cierra; *Construir aquí* coloca la casa; los snackbars salen por encima de la barra. TalkBack anuncia el mundo como "Mundo de juego: bosque con árboles, el personaje y los edificios".

- [ ] **Step 4: iOS (táctil)**

Run: `open -a Simulator && flutter run -d "iPhone 17"`

Repetir el Step 3 en el simulador (VoiceOver en lugar de TalkBack). Comprobar que el HUD respeta la isla dinámica y la barra de inicio (`SafeArea`).

- [ ] **Step 5: Registrar el cierre**

Si todo se comporta como arriba, la fase está cerrada. Si hubo que corregir algo, cada corrección ya tiene su commit y su línea en el README § 7; no hay commit adicional en esta tarea.
