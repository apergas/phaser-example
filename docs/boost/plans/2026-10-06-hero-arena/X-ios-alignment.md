# X · Alineación con la versión iOS — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) (and the ones of the village plan it points to) first; they apply to every task.

| | |
|---|---|
| **Flujo** | C (arena); trabajo sin fase propia: commits `[PROJECT-X]: …` |
| **Rama** | `feature/PROJECT-X-ios-alignment`, desde `feature/PROJECT-X-arena` (ya creada, con el arreglo de reanudar obras de #54 unido) |
| **Issue** | #55 (`stream:C`, sin etiqueta de fase ni milestone: no es una fase de la hoja de ruta) |
| **Depende de** | C8 y el arreglo de reanudar obras (`a16317c`, #54) |
| **Va antes de** | C9: todo lo que viene después usa el nombre y el paquete nuevos |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios`. Migración M0–M7, decisiones D17–D18 de `$IOS/docs/plans/2026-10-12-swiftui-migration/README.md`, notas de `$IOS/.boost/sdd/cross-phase-notes.md`, `$IOS/scripts/build_app_icon.py`, `GameUseCase.resumeConstruction` y `Localizable.xcstrings` |

**Goal:** Que la app Flutter sea la misma que la de iOS antes de portar las fases nuevas: mismo nombre (*Farming*), mismos ids (`com.apergas.farming`), paquete Dart `farming`, el icono del roble, el arranque verde oscuro, los textos táctiles y la guarda que no reinicia la obra que se está martilleando.

**Architecture:**
- **Renombrado (TX.1):** cambio mecánico. `pubspec.yaml` pasa a `name: farming`; `sed` cambia `package:rpg/` por `package:farming/` en `lib/` y `test/` (salvo los generados, que se regeneran con `build_runner`); los runners de Android, iOS y web cambian el nombre visible y los ids. `lib/` usa imports relativos, así que apenas cambia.
- **Guarda de la obra (TX.2):** `ResumeConstructionUseCase` devuelve `ok` sin tocar el mundo si el jugador ya está trabajando (`WorkingActivityEntity`) con `ConstructIntentEntity(buildingId: buildingId)`. Es lo que hace `GameUseCase.resumeConstruction` en iOS. Volver a tocar un árbol sí reinicia el golpe (paridad con iOS).
- **Textos táctiles (TX.3):** dos claves nuevas (`pickedUpAxeTouch`, `placingTouch`) con los textos de iOS. `ForestBloc` recibe `isTouchInput` en el constructor y elige; `ForestPage` se lo pasa con la misma regla que ya decide la `PlacementBar` (`_isTouchPlatform`, que sale de `_ForestViewState` a nivel de fichero). La web sigue con los textos de ratón.
- **Icono y arranque (TX.4):** `asset-packs/lpc/build_app_icon.py` (versión ampliada del de iOS) pinta el `tree-oak` del atlas sobre `#0E150E` y escribe los iconos de Android, iOS y web, más un `web/favicon.png` que sustituye al `favicon.svg` de plantilla. Fondo de arranque `#0E150E` en Android (`@color/launch_background`) y en el `LaunchScreen` de iOS; `web/manifest.json` ya lo tenía.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13, `flutter_bloc`, easy_localization; tests con `flutter_test`, `bloc_test`, `mockito`. Iconos con Python 3 + Pillow (como `build_assets.py`).

**Precondición** (`feature/PROJECT-X-arena` @ `988f6d2`, #54 unido). Este plan usa exactamente estas firmas; comprueba que no han cambiado:
- `ResumeConstructionUseCase.call({required String buildingId})` delega en `World.orderResumeConstruction(String)`;
- `WorkingActivityEntity(intent, elapsedMs)`, `ConstructIntentEntity(buildingId)` con `==` por `buildingId`;
- `WorldMock.withSeventeenWood()`, `WorldMock.advanceFor(double)` (pasos de 16 ms), `GameSessionEntityMock.playing(World)`, `Blueprints.house` (`hitsToBuild: 8`), `Rules.hammerIntervalMs = 650`;
- `ForestBloc` con los parámetros nombrados privados `required this._…UseCase` y `required this._navigationService` (el último), `_openPlacement(BlueprintId)` que acaba mostrando `forestMessagePlacing` y `_react` con el caso `ItemPickedUpEventEntity`; `ForestBlocMock.make(world, {required navigationService, loadError, failingLoads})`;
- `_ForestViewState._isTouchPlatform` en `forest_page.dart`;
- `Internationalize.forestMessagePickedUpAxe` (getter) y `forestMessagePlacing({required String name})`.

**Cómo probar la fase entera:**
- `flutter test` en verde: **658 tests** (655 antes; TX.1 +0, TX.2 +1, TX.3 +2, TX.4 +0).
- `flutter analyze` → `No issues found!`; `dart run build_runner build --delete-conflicting-outputs` + `git diff --exit-code` limpio; `grep -rniI 'rpg' lib test android ios web pubspec.yaml` sin resultados.
- La sección *Prueba manual* en Chrome, Android e iOS.

**Cómo se ha comprobado este plan (2026-10-17):** en un worktree desechable sobre `feature/PROJECT-X-ios-alignment` (`774dcd4`), con un commit por tarea:
- tras cada tarea, `flutter analyze` → `No issues found!` y `flutter test` en verde: **655**, **656**, **658** y **658**. En TX.2 y TX.3 los tests nuevos fallaban antes de tocar `lib/`;
- `flutter build apk --debug`: `package: name='com.apergas.farming'`, `application-label:'Farming'`; `flutter build web` con `<title>Farming</title>`;
- se miraron `Icon-App-1024x1024@1x.png` (el roble ×5 sobre verde oscuro, igual que en iOS) e `Icon-maskable-192.png`;
- `flutter build ios --simulator` **no** se pudo comprobar: el sandbox de la sesión no deja a Xcode escribir en `DerivedData` (falla igual en el repositorio principal). Se comprueba en la prueba manual.

## Decisiones del plan

Decididas con el usuario el 2026-10-17:

1. **Nombre visible e ids:** `Farming`, `com.apergas.farming`, paquete Dart `farming`. En Android y en el simulador iOS se instala como una app **nueva**; la antigua `com.apergas.rpg` se desinstala a mano. No hay partidas guardadas que migrar (F2 todavía no existe).

Del plan:

2. **Descripción** (`pubspec.yaml`, `web/index.html`, `web/manifest.json`): *"Top-down forest game: chop trees, build a village and train a hero for the arena."*
3. **Sin `flutter_launcher_icons`:** un script de Pillow, como el arte, sin dependencia nueva. Los iconos se reducen con `LANCZOS` desde un máster de 1024 px dibujado con vecino más cercano (el mismo que el de iOS).
4. **Icono *maskable* de la web** con el roble al 60 % (no al 80 %), para que quede dentro de la zona segura circular.
5. **`web/favicon.svg`** era el de la plantilla (un rayo morado): se borra y `index.html` apunta a `favicon.png` (32 px).
6. **La guarda compara la intención entera** (`activity.intent == ConstructIntentEntity(buildingId: buildingId)`), sin *pattern* anidado: se lee mejor y `dart format` no lo parte.
7. **`isTouchInput` es obligatorio** en `ForestBloc` (como el resto de parámetros); `ForestBlocMock.make` lo deja en `false` por defecto para que los tests de siempre sigan con los textos de ratón.
8. **`_isTouchPlatform` pasa a ser un *getter* de nivel de fichero** en `forest_page.dart`: lo usan `ForestPage.build` (para el BLoC) y `_ForestViewState` (para la `PlacementBar`).
9. **Lo que no se trae de iOS** (específico de Swift o de SpriteKit): D9 `ScenePoint`, D16/D20 (aislamiento de actores), D19 (símbolos del String Catalog; aquí sigue `Internationalize`), `RenderDepth.overlay`, `SpriteView(isPaused:)`, el `Navigator`/`Router` y el `fullScreenCover`. D17 (sin web) **no** aplica: Flutter mantiene web, Esc y clic derecho.

## Reparto

| Tarea | Qué | Depende de |
|---|---|---|
| TX.1 | Renombrado: nombre, ids y paquete | — |
| TX.2 | No reiniciar la obra que se está martilleando | TX.1 |
| TX.3 | Textos táctiles | TX.1 |
| TX.4 | Icono y pantalla de arranque | TX.1 |

TX.2, TX.3 y TX.4 no tocan los mismos ficheros: con TX.1 hecha se pueden repartir entre agentes en paralelo (cada uno en su worktree) y unir después. En serie, el orden es el de la tabla.

---

### Task TX.1: Renombrado: nombre, ids y paquete

**Files:**
- Modify: `pubspec.yaml:1-2`
- Modify: `lib/core/assets/i18n/translations/es.json:3`
- Modify: `android/app/build.gradle.kts:8,19`, `android/app/src/main/AndroidManifest.xml:3`
- Move: `android/app/src/main/kotlin/com/apergas/rpg/MainActivity.kt` → `android/app/src/main/kotlin/com/apergas/farming/MainActivity.kt` (y su `package`)
- Modify: `ios/Runner/Info.plist:10,18`, `ios/Runner.xcodeproj/project.pbxproj` (6 `PRODUCT_BUNDLE_IDENTIFIER`)
- Modify: `web/index.html:8,11,15`, `web/manifest.json:2-4`
- Modify: los ~215 ficheros de `lib/` y `test/` con `package:rpg/` (casi todos en `test/`; incluye las cadenas de `test/architecture_test.dart`)
- Regenerate: `lib/core/config/di/di.config.dart` y los 5 `*.mocks.dart` (nunca a mano)
- Modify: `CLAUDE.md:7,11,85`

**Interfaces:**
- Produces: paquete `package:farming/…` para todos los tests de las tareas siguientes.

- [ ] **Step 1: Cambiar nombre y descripción del paquete**

```bash
sed -i '' -e 's/^name: rpg$/name: farming/' \
  -e 's/^description: .*/description: "Top-down forest game: chop trees, build a village and train a hero for the arena."/' pubspec.yaml
```

- [ ] **Step 2: Cambiar los imports y las cadenas `package:rpg/` (sin los generados)**

```bash
grep -rlI 'package:rpg/' lib test | grep -v '\.mocks\.dart$' | grep -v 'di\.config\.dart$' \
  | xargs sed -i '' 's#package:rpg/#package:farming/#g'
```

- [ ] **Step 3: Nombre visible e ids de las plataformas**

```bash
sed -i '' 's/"title": "RPG"/"title": "Farming"/' lib/core/assets/i18n/translations/es.json
sed -i '' 's/com\.apergas\.rpg/com.apergas.farming/g' android/app/build.gradle.kts ios/Runner.xcodeproj/project.pbxproj
sed -i '' 's/android:label="RPG"/android:label="Farming"/' android/app/src/main/AndroidManifest.xml
git mv android/app/src/main/kotlin/com/apergas/rpg android/app/src/main/kotlin/com/apergas/farming
sed -i '' 's/^package com\.apergas\.rpg$/package com.apergas.farming/' android/app/src/main/kotlin/com/apergas/farming/MainActivity.kt
sed -i '' -e 's#<string>RPG</string>#<string>Farming</string>#' -e 's#<string>rpg</string>#<string>farming</string>#' ios/Runner/Info.plist
sed -i '' -e 's/content="Top-down forest RPG: chop trees, gather wood and build a house."/content="Top-down forest game: chop trees, build a village and train a hero for the arena."/' \
  -e 's/content="RPG"/content="Farming"/' -e 's#<title>RPG</title>#<title>Farming</title>#' web/index.html
sed -i '' -e 's/"name": "RPG"/"name": "Farming"/' -e 's/"short_name": "RPG"/"short_name": "Farming"/' \
  -e 's/"description": "Top-down forest RPG: chop trees, gather wood and build a house."/"description": "Top-down forest game: chop trees, build a village and train a hero for the arena."/' web/manifest.json
```

En `Info.plist`, `RPG` es `CFBundleDisplayName` (línea 10) y `rpg` es `CFBundleName` (línea 18).

- [ ] **Step 4: Regenerar y formatear**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
git diff --name-only -- '*.dart' | grep -v '\.mocks\.dart$' | grep -v di.config.dart | xargs dart format --line-length 120
```

Expected: `build_runner` reescribe `di.config.dart` (los imports se reordenan: `farming` va antes que `flutter`) y los `*.mocks.dart`; `dart format` sólo cambia `test/architecture_test.dart` (una línea pasa de 120).

- [ ] **Step 5: Comprobar**

```bash
grep -rniI 'rpg' lib test android ios web pubspec.yaml
flutter analyze
flutter test
```

Expected: `grep` sin resultados; `No issues found!`; `+655: All tests passed!`.

- [ ] **Step 6: Actualizar `CLAUDE.md`**

- Línea 7: `Dart package \`rpg\`` → `Dart package \`farming\``.
- Línea 11: `(app name \`RPG\`, ids \`com.apergas.rpg\`, …` → `(app name \`Farming\`, ids \`com.apergas.farming\`, …`.
- Línea 85: `(the app name \`RPG\` is the only per-platform text: …` → `(the app name \`Farming\` is the only per-platform text: …`.

- [ ] **Step 7: Commit**

```bash
git add -A -- . ':!CLAUDE.md'
git add CLAUDE.md
git commit -m "[PROJECT-X]: Rename the app to Farming"
```

(`CLAUDE.md` se añade en un comando aparte del `git commit`.)

---

### Task TX.2: No reiniciar la obra que se está martilleando

**Files:**
- Modify: `lib/layers/domain/use-cases/game/resume_construction_use_case.dart`
- Test: `test/layers/domain/use-cases/game/resume_construction_use_case_test.dart`
- Modify: `CLAUDE.md:41`

**Interfaces:**
- Consumes: `package:farming/` (TX.1).
- Produces: nada nuevo; `ResumeConstructionUseCase.call({required String buildingId})` mantiene la firma.

- [ ] **Step 1: Write the failing test**

Añadir los imports y el test a `resume_construction_use_case_test.dart` (el fichero queda así):

```dart
import 'package:farming/core/config/constants/enum/resume_construction_result.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/domain/use-cases/game/resume_construction_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ResumeConstructionUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ResumeConstructionUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenResumingAnUnknownBuildingThenReturnsUnknownBuilding', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final result = sut(buildingId: 'building-99');

    // then
    expect(result, ResumeConstructionResult.unknownBuilding);
  });

  test('testWhenResumingTheBuildingBeingHammeredThenKeepsTheSwing', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(Blueprints.house, const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000 + Rules.hammerIntervalMs * 2 + 320);
    final swing = world.player.activity;
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));

    // when
    final result = sut(buildingId: 'building-1');

    // then
    expect(swing, isA<WorkingActivityEntity>().having((activity) => activity.elapsedMs, 'elapsedMs', greaterThan(0)));
    expect(result, ResumeConstructionResult.ok);
    expect(world.player.activity, swing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/layers/domain/use-cases/game/resume_construction_use_case_test.dart`
Expected: FAIL en `testWhenResumingTheBuildingBeingHammeredThenKeepsTheSwing`: el `WorkingActivityEntity` de después tiene `elapsedMs` 0 (el golpe se ha reiniciado).

- [ ] **Step 3: Write minimal implementation**

`resume_construction_use_case.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/resume_construction_result.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class ResumeConstructionUseCase {
  final GameSessionRepository _sessionRepository;

  const ResumeConstructionUseCase({required this._sessionRepository});

  ResumeConstructionResult call({required String buildingId}) {
    final world = _sessionRepository.current().world;
    final activity = world.player.activity;
    if (activity is WorkingActivityEntity && activity.intent == ConstructIntentEntity(buildingId: buildingId)) {
      return ResumeConstructionResult.ok;
    }
    return world.orderResumeConstruction(buildingId);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/layers/domain/use-cases/game/resume_construction_use_case_test.dart test/layers/domain/world/world_construction_test.dart`
Expected: PASS. Después `flutter analyze` → `No issues found!` y `flutter test` → `+656`.

- [ ] **Step 5: Actualizar `CLAUDE.md`**

En la línea 41, tras `… keeping its progress and without paying again` añadir `; tapping the building already being hammered returns \`ok\` without touching the world, so the swing is not restarted`.

- [ ] **Step 6: Commit**

```bash
git add lib/layers/domain/use-cases/game/resume_construction_use_case.dart test/layers/domain/use-cases/game/resume_construction_use_case_test.dart
git add CLAUDE.md
git commit -m "[PROJECT-X]: Keep the swing when tapping the building being hammered"
```

---

### Task TX.3: Textos táctiles

**Files:**
- Modify: `lib/core/assets/i18n/translations/es.json` (claves `forest.message.pickedUpAxeTouch` y `forest.message.placingTouch`)
- Modify: `lib/core/assets/i18n/internationalize.dart`
- Modify: `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`
- Modify: `lib/layers/presentation/features/forest/forest_page.dart`
- Modify: `test/mocks/presentation/features/forest/forest_bloc_mock.dart`
- Test: `test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`, `test/core/assets/i18n/internationalize_test.dart`
- Modify: `CLAUDE.md:76`

**Interfaces:**
- Consumes: `package:farming/` (TX.1).
- Produces:
  - `Internationalize.forestMessagePickedUpAxeTouch` (getter `String`), `Internationalize.forestMessagePlacingTouch({required String name})`;
  - `ForestBloc({…, required NavigationService navigationService, required bool isTouchInput})`;
  - `ForestBlocMock.make(world, {required navigationService, loadError, failingLoads, bool isTouchInput = false})`.
  F5 usará lo mismo para el pico (*"¡Pico recogido! Toca una roca para picarla."* / *"… Haz clic en una roca …"*).

- [ ] **Step 1: Write the failing tests**

En `internationalize_test.dart`, `testWhenFormattingMessagesWithNamesThenInsertsThem`:

```dart
    final placing = Internationalize.forestMessagePlacing(name: name);
    final placingTouch = Internationalize.forestMessagePlacingTouch(name: name);
```

```dart
    expect(placing, 'Elige dónde construir: Casa. Clic derecho o Esc para cancelar.');
    expect(
      placingTouch,
      'Elige dónde construir: Casa. Arrastra el dedo para moverlo y toca Construir aquí o Cancelar.',
    );
```

y en `testWhenReadingEveryForestTextThenNoneFallsBackToItsKey`, justo después de `Internationalize.forestMessagePickedUpAxe,` en `texts` y de su texto en la lista esperada:

```dart
      Internationalize.forestMessagePickedUpAxeTouch,
```

```dart
      '¡Hacha recogida! Toca un árbol para talarlo.',
```

En `forest_bloc_mock.dart`, el parámetro y su paso al constructor:

```dart
    Set<int>? failingLoads,
    bool isTouchInput = false,
  }) {
```

```dart
      navigationService: navigationService,
      isTouchInput: isTouchInput,
    );
```

En `forest_bloc_test.dart`, antes de `group('testWhenCancellingThePlacementThenClosesItWithoutBuilding', …)`:

```dart
  blocTest<ForestBloc, ForestState>(
    'testWhenPickingUpTheAxeOnATouchScreenThenTellsToTapATree',
    build: () {
      // given
      return ForestBlocMock.make(
        ForestScenarioMock.axeNextToPlayer(),
        navigationService: navigationService,
        isTouchInput: true,
      );
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestMapClicked(position: ForestScenarioMock.axeSpot));
      ForestBlocMock.tickFor(bloc, 300);
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final messages = ForestBlocMock.shownMessages(navigationService);
      expect(messages, contains(Internationalize.forestMessagePickedUpAxeTouch));
      expect(messages, isNot(contains(Internationalize.forestMessagePickedUpAxe)));
    },
  );

  blocTest<ForestBloc, ForestState>(
    'testWhenPlacingOnATouchScreenThenTellsToDragAndTap',
    build: () {
      // given
      return ForestBlocMock.make(
        ForestScenarioMock.fifteenWood(),
        navigationService: navigationService,
        isTouchInput: true,
      );
    },
    act: (bloc) {
      // when
      bloc
        ..add(const ForestStarted())
        ..add(const ForestBuildRequested(blueprint: BlueprintId.house));
    },
    wait: Duration.zero,
    verify: (bloc) {
      // then
      final name = Internationalize.forestBlueprint(id: BlueprintId.house);
      final messages = ForestBlocMock.shownMessages(navigationService);
      expect(messages, contains(Internationalize.forestMessagePlacingTouch(name: name)));
      expect(messages, isNot(contains(Internationalize.forestMessagePlacing(name: name))));
    },
  );
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart`
Expected: FAIL de compilación: `Member not found: 'Internationalize.forestMessagePlacingTouch'` (y `No named parameter with the name 'isTouchInput'`).

- [ ] **Step 3: Textos**

`es.json`, en `forest.message`, cada clave nueva justo después de la suya:

```json
      "pickedUpAxe": "¡Hacha recogida! Haz clic en un árbol para talarlo.",
      "pickedUpAxeTouch": "¡Hacha recogida! Toca un árbol para talarlo.",
```

```json
      "placing": "Elige dónde construir: {name}. Clic derecho o Esc para cancelar.",
      "placingTouch": "Elige dónde construir: {name}. Arrastra el dedo para moverlo y toca Construir aquí o Cancelar.",
```

`internationalize.dart`, cada uno tras el suyo:

```dart
  static String get forestMessagePickedUpAxe => '$_forest.message.pickedUpAxe'.tr();
  static String get forestMessagePickedUpAxeTouch => '$_forest.message.pickedUpAxeTouch'.tr();
```

```dart
  static String forestMessagePlacing({required String name}) =>
      '$_forest.message.placing'.tr(namedArgs: {'name': name});
  static String forestMessagePlacingTouch({required String name}) =>
      '$_forest.message.placingTouch'.tr(namedArgs: {'name': name});
```

- [ ] **Step 4: `ForestBloc` elige el texto**

Campo y parámetro (al final, tras `_navigationService`):

```dart
  final NavigationService _navigationService;
  final bool _isTouchInput;
```

```dart
    required this._navigationService,
    required this._isTouchInput,
  }) : super(const ForestInitial()) {
```

Al final de `_openPlacement(BlueprintId blueprint)`, en lugar de `_showMessage(Internationalize.forestMessagePlacing(name: Internationalize.forestBlueprint(id: blueprint)));`:

```dart
    final name = Internationalize.forestBlueprint(id: blueprint);
    _showMessage(
      _isTouchInput
          ? Internationalize.forestMessagePlacingTouch(name: name)
          : Internationalize.forestMessagePlacing(name: name),
    );
```

En `_react`, caso `ItemPickedUpEventEntity`:

```dart
        _showMessage(switch (kind) {
          ToolKind.axe =>
            _isTouchInput ? Internationalize.forestMessagePickedUpAxeTouch : Internationalize.forestMessagePickedUpAxe,
        });
```

- [ ] **Step 5: `ForestPage` pasa la plataforma**

En `forest_page.dart`, quitar `_isTouchPlatform` de `_ForestViewState` y ponerlo a nivel de fichero, justo antes de `class _ForestView`:

```dart
bool get _isTouchPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS => true,
  _ => false,
};
```

y en `ForestPage.build`, tras `navigationService:`:

```dart
        navigationService: locator.get<NavigationService>(),
        isTouchInput: _isTouchPlatform,
      )..add(const ForestStarted()),
```

`_ForestViewState` sigue usando `_isTouchPlatform` para la `PlacementBar` sin más cambios.

- [ ] **Step 6: Run tests to verify they pass**

```bash
dart format --line-length 120 lib/core/assets/i18n/internationalize.dart lib/layers/presentation/features/forest/bloc/forest_bloc.dart lib/layers/presentation/features/forest/forest_page.dart test/core/assets/i18n/internationalize_test.dart test/layers/presentation/features/forest/bloc/forest_bloc_test.dart test/mocks/presentation/features/forest/forest_bloc_mock.dart
flutter analyze
flutter test
```

Expected: `No issues found!`; `+658: All tests passed!`.

- [ ] **Step 7: Actualizar `CLAUDE.md`**

En la línea 76, tras `touch screens get the placement bar` añadir `and the touch texts (\`ForestBloc\` gets \`isTouchInput\` from \`ForestPage\`; \`Internationalize\` has a \`…Touch\` variant of every text that says how to interact)`.

- [ ] **Step 8: Commit**

```bash
git add lib/core/assets/i18n lib/layers/presentation/features/forest test/core/assets/i18n test/layers/presentation/features/forest/bloc test/mocks/presentation/features/forest
git add CLAUDE.md
git commit -m "[PROJECT-X]: Tell touch players to tap instead of click"
```

---

### Task TX.4: Icono y pantalla de arranque

**Files:**
- Create: `asset-packs/lpc/build_app_icon.py`
- Regenerate: `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`, los 19 PNG de `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `web/icons/Icon-{192,512}.png`, `web/icons/Icon-maskable-{192,512}.png`
- Create: `web/favicon.png`, `android/app/src/main/res/values/colors.xml`
- Delete: `web/favicon.svg`
- Modify: `android/app/src/main/res/drawable/launch_background.xml:4`, `android/app/src/main/res/drawable-v21/launch_background.xml:4`, `ios/Runner/Base.lproj/LaunchScreen.storyboard:22`, `web/index.html:13`
- Modify: `lib/core/assets/images/lpc/CREDITS.md` (al final), `CLAUDE.md:12`

**Interfaces:**
- Consumes: el frame `tree-oak` de `lib/core/assets/images/lpc/forest.{png,json}` (ya existe).
- Produces: nada que use el código; sólo recursos de plataforma.

No hay test automático (son recursos de plataforma); se comprueba mirando las imágenes y compilando.

- [ ] **Step 1: El script**

`asset-packs/lpc/build_app_icon.py`:

```python
"""Draws the app icon from the oak of the forest atlas and writes it for Android, iOS and the web.

  python3 build_app_icon.py      (run build_assets.py first: it reads lib/core/assets/images/lpc/forest.*)

The oak (`tree-oak`) is scaled with nearest neighbour to a 1024 px master on the launch colour #0E150E,
then every platform size is resized from that master.
"""

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).parent
REPO = ROOT.parent.parent
ART = REPO / "lib" / "core" / "assets" / "images" / "lpc"
MASTER_SIZE = 1024
BACKGROUND = (0x0E, 0x15, 0x0E)
FRAME = "tree-oak"
COVERAGE = 0.8
MASKABLE_COVERAGE = 0.6
ANDROID_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
IOS_ICONSET = REPO / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
WEB = REPO / "web"


def oak_icon(coverage):
    frames = json.loads((ART / "forest.json").read_text())["frames"]
    rect = frames[FRAME]["frame"]
    sheet = Image.open(ART / "forest.png").convert("RGBA")
    sprite = sheet.crop((rect["x"], rect["y"], rect["x"] + rect["w"], rect["y"] + rect["h"]))
    scale = int(MASTER_SIZE * coverage) // max(rect["w"], rect["h"])
    sprite = sprite.resize((rect["w"] * scale, rect["h"] * scale), Image.NEAREST)
    icon = Image.new("RGB", (MASTER_SIZE, MASTER_SIZE), BACKGROUND)
    icon.paste(sprite, ((MASTER_SIZE - sprite.width) // 2, (MASTER_SIZE - sprite.height) // 2), sprite)
    return icon


def save(icon, size, path):
    icon.resize((size, size), Image.LANCZOS).save(path)


def main():
    icon = oak_icon(COVERAGE)
    maskable = oak_icon(MASKABLE_COVERAGE)
    for density, size in ANDROID_SIZES.items():
        save(icon, size, REPO / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png")
    for image in json.loads((IOS_ICONSET / "Contents.json").read_text())["images"]:
        points = float(image["size"].split("x")[0])
        save(icon, round(points * int(image["scale"][0])), IOS_ICONSET / image["filename"])
    for size in (192, 512):
        save(icon, size, WEB / "icons" / f"Icon-{size}.png")
        save(maskable, size, WEB / "icons" / f"Icon-maskable-{size}.png")
    save(icon, 32, WEB / "favicon.png")
    print(f"{FRAME} -> {MASTER_SIZE} px master, Android, iOS and web icons written")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Generar y mirar**

```bash
cd asset-packs/lpc && python3 build_app_icon.py && cd ../..
```

Expected: `tree-oak -> 1024 px master, Android, iOS and web icons written`; cambian 5 PNG de Android, 19 de iOS y 4 de la web, y aparece `web/favicon.png`. Abrir `Icon-App-1024x1024@1x.png` (el roble grande, centrado, sobre verde casi negro, igual que el `AppIcon-1024.png` de iOS) e `Icon-maskable-192.png` (el roble más pequeño, con margen).

- [ ] **Step 3: Fondo de arranque y favicon**

```bash
printf '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="launch_background">#0E150E</color>\n</resources>\n' > android/app/src/main/res/values/colors.xml
sed -i '' 's#<item android:drawable="@android:color/white" />#<item android:drawable="@color/launch_background" />#' android/app/src/main/res/drawable/launch_background.xml
sed -i '' 's#<item android:drawable="?android:colorBackground" />#<item android:drawable="@color/launch_background" />#' android/app/src/main/res/drawable-v21/launch_background.xml
sed -i '' 's#<color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>#<color key="backgroundColor" red="0.054901960784313725" green="0.082352941176470587" blue="0.054901960784313725" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>#' ios/Runner/Base.lproj/LaunchScreen.storyboard
sed -i '' 's#<link rel="icon" type="image/svg+xml" href="favicon.svg">#<link rel="icon" type="image/png" href="favicon.png">#' web/index.html
git rm web/favicon.svg
```

(`0x0E / 255 = 0.0549…`, `0x15 / 255 = 0.0823…`.) `web/manifest.json` ya tiene `#0e150e` en `background_color` y `theme_color`.

- [ ] **Step 4: Créditos**

Al final de `lib/core/assets/images/lpc/CREDITS.md`:

```markdown

## App icon (Android `mipmap-*/ic_launcher.png`, iOS `AppIcon.appiconset`, web `icons/` and `favicon.png`)

The `tree-oak` frame of `forest.png` (see *Trees* above, CC-BY-SA 3.0), scaled with nearest neighbour and
centred on the launch colour `#0E150E` by `asset-packs/lpc/build_app_icon.py`.
```

- [ ] **Step 5: Compilar**

```bash
flutter build apk --debug
"$(ls -d ~/Library/Android/sdk/build-tools/* | tail -1)/aapt" dump badging build/app/outputs/flutter-apk/app-debug.apk | grep -E "^package|application-label:"
flutter build web --release --base-href /phaser-example/ --dart-define-from-file=lib/core/config/env/production_environment.json
flutter build ios --simulator --debug
flutter test
```

Expected: `package: name='com.apergas.farming'`, `application-label:'Farming'`; web y simulador iOS compilan; `+658`.

- [ ] **Step 6: Actualizar `CLAUDE.md`**

Línea 12: `raw LPC art and \`build_assets.py\`, which generates \`lib/core/assets/images/lpc/\`` → `raw LPC art, \`build_assets.py\`, which generates \`lib/core/assets/images/lpc/\`, and \`build_app_icon.py\`, which draws the app icon (the oak of \`forest.png\` on \`#0E150E\`, also the launch colour) for Android, iOS and the web`. En *Commands*, junto a la línea de `build_assets.py`: `and \`python3 build_app_icon.py\` after it if the oak changes`.

- [ ] **Step 7: Commit**

```bash
git add asset-packs/lpc/build_app_icon.py android/app/src/main/res ios/Runner/Assets.xcassets ios/Runner/Base.lproj/LaunchScreen.storyboard web lib/core/assets/images/lpc/CREDITS.md
git add CLAUDE.md
git commit -m "[PROJECT-X]: Use the oak as the app icon and a dark green launch screen"
```

---

## Prueba manual

Desinstalar antes la app antigua (`com.apergas.rpg`) del emulador y del simulador.

1. **Chrome** (`flutter run -d chrome`): la pestaña se llama *Farming* y lleva el roble como favicon. Recoger el hacha → *"… Haz clic en un árbol para talarlo."*; *Construir* ▸ *Casa* → *"… Clic derecho o Esc para cancelar."*
2. **Android** (`flutter run -d emulator-5554`): en el lanzador, *Farming* con el roble; el arranque es verde oscuro, no blanco. Recoger el hacha → *"… Toca un árbol para talarlo."*; *Construir* ▸ *Casa* → *"… Arrastra el dedo para moverlo y toca Construir aquí o Cancelar."*
3. **iOS** (`flutter run -d "iPhone 17"`): lo mismo que en Android (nombre, icono, arranque y textos).
4. **La obra:** empezar una casa y, mientras se martillea, tocarla tres veces seguidas: el martilleo no se para y la casa termina como siempre. Irse, volver a tocarla: el jugador vuelve y sigue (lo de #54).

## Al cerrar X

- Batería de cierre: `build_runner` + `git diff --exit-code`, `flutter analyze`, `flutter test`, `flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart`.
- `PROGRESS.md`: X pasa a ✅ con el número de tests; `README.md` de la arena, el icono de X.
- PR `[PROJECT-X]: Align the app with the iOS version` hacia `feature/PROJECT-X-arena`. No cierra #55 sola: se cierra y se mueve la tarjeta a mano.
- Después, C9 sale de `feature/PROJECT-X-arena` con el paquete `farming`.
