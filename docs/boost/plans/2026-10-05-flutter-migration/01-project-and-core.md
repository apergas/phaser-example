# Fase 1 — Proyecto Flutter y `core/` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tener un proyecto Flutter (`rpg`) en la raíz del repo, junto al código actual sin tocarlo, con `pubspec.yaml`, `analysis_options.yaml`, el `core/` completo (DI, errores, navegación, logging, i18n, `SeededRandom`, constantes de render), el arte LPC empaquetado, un test de reglas de arquitectura y una app que arranca en web mostrando una pantalla vacía.

**Architecture:** `flutter create --empty` genera `lib/`, `android/`, `ios/`, `web/` y `pubspec.yaml` en la raíz; nada de `shared/`, `androidApp/`, `iosApp/`, `webApp/` ni de los ficheros Gradle cambia. El `core/` sigue el ejemplo del plugin `flutter-arch-conventions` (`~/.claude/plugins/cache/arch-skills/flutter-arch-conventions/0.0.8/skills/install-rules/resources/examples/flutter-example`) recortado a lo que el juego necesita (excepción E7 del README). El arte se **copia** (no se mueve) a `lib/core/assets/images/lpc/`, porque las apps actuales lo siguen leyendo de `shared/assets/lpc/` hasta la fase 8.

**Tech Stack:** Flutter 3.47.x, Dart 3.13.x, get_it, injectable, easy_localization, flutter_bloc, bloc, flame, flame_bloc, collection, meta, flutter_svg, hybrid_logger; dev: build_runner, injectable_generator, mockito, bloc_test, flame_test, flutter_lints.

## Global Constraints

Ver [README §Global Constraints](README.md#global-constraints). Además, en esta fase:

- **No se toca nada existente** salvo `.gitignore` (se añaden las entradas de Flutter) y `asset-packs/lpc/build_assets.py` (escribe en la carpeta nueva y además replica en la vieja). `git status` al final de cada tarea no puede mostrar `M`/`D` en `shared/`, `androidApp/`, `iosApp/`, `webApp/`, `gradle/`, `*.gradle.kts`, `README.md` ni `CLAUDE.md`.
- Doble copia del arte **temporal**: `shared/assets/lpc/` (apps viejas) y `lib/core/assets/images/lpc/` (Flutter). `build_assets.py` escribe en la nueva y la copia a la vieja mientras exista `shared/`. La fase 8 borra la vieja y la réplica.
- Solo español: `supportedLocales: [Locale('es')]`, `fallbackLocale` y `startLocale` `es` (el plugin propone `es` + `en`; el README fija solo español).
- Sin bloqueo de orientación (`gen-main` propone vertical): las apps actuales no la bloquean y el juego debe comportarse igual.
- `BlocLogger` registra solo `onError`, no `onEvent`: el `ForestBloc` recibirá un `ForestTicked` por fotograma (60/s) y el log de eventos inundaría la consola.
- Los ficheros generados (`di.config.dart`, y en fases siguientes `*.mocks.dart`) **se versionan**: `flutter test` debe funcionar sin ejecutar `build_runner`. El CI de la fase 8 ejecuta igualmente `dart run build_runner build --delete-conflicting-outputs` antes de los tests.
- **No se crea `build.yaml`**: la configuración por defecto de `injectable_generator` (genera `di.config.dart` junto a `di.dart`) y de `mockito` basta.
- Ningún comentario en `lib/` (regla 11 del plugin). Los tests usan `// given`, `// when`, `// then`.

---

### Task 1: Crear el proyecto Flutter en la raíz

**Files:**
- Create (generado): `pubspec.yaml`, `pubspec.lock`, `.metadata`, `lib/main.dart`, `android/**`, `ios/**`, `web/**`
- Create: `analysis_options.yaml` (sobrescribe el generado)
- Modify: `.gitignore` (añadir bloque Flutter)
- Delete (si se genera): `test/widget_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces: paquete Dart `rpg` (imports relativos, `prefer_relative_imports`); dependencias resueltas para todas las fases.

- [ ] **Step 1: Guardar los ficheros que `flutter create` podría pisar**

```bash
cd /Users/axelperezgaspar/phaser-example
git status --porcelain   # debe estar limpio salvo docs/boost/plans/2026-10-05-flutter-migration/
```

`README.md` y `.gitignore` están versionados: si `flutter create` los modifica se restauran con `git checkout` en el paso 3.

- [ ] **Step 2: Generar el proyecto**

```bash
flutter create --org com.apergas --project-name rpg --platforms android,ios,web --empty .
```

Expected: `All done!` y aparecen `android/`, `ios/`, `web/`, `lib/main.dart`, `pubspec.yaml`, `.metadata`, `analysis_options.yaml`.

- [ ] **Step 3: Restaurar lo existente y limpiar lo generado que sobra**

```bash
git checkout -- README.md .gitignore
rm -f test/widget_test.dart
git status --porcelain | grep -E '^( M|D |MM)' || echo "nothing existing modified"
```

Expected: `nothing existing modified`.

- [ ] **Step 4: Añadir las entradas de Flutter al `.gitignore`**

Añadir al final de `.gitignore`:

```gitignore

# Flutter / Dart
.dart_tool/
.flutter-plugins-dependencies
.pub-cache/
.pub/
/coverage/
app.*.symbols
app.*.map.json
/android/app/debug
/android/app/profile
/android/app/release
```

(`build/`, `*.iml`, `.idea/` y `xcuserdata/` ya están ignorados por las reglas actuales.)

- [ ] **Step 5: Fijar el SDK y añadir las dependencias**

En `pubspec.yaml`, dejar `environment` así:

```yaml
environment:
  sdk: ^3.13.0
```

Después:

```bash
flutter pub add flame flame_bloc flutter_bloc bloc get_it injectable easy_localization collection meta flutter_svg hybrid_logger
flutter pub add --dev build_runner injectable_generator mockito bloc_test flame_test
```

Expected: cada paquete queda en `pubspec.yaml` con su versión estable más reciente y caret (`^x.y.z`). Esas versiones no se cambian en el resto de la migración sin un commit propio. `flutter_lints` ya viene de `flutter create`.

- [ ] **Step 6: Escribir `analysis_options.yaml` exactamente como el plugin**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/di.config.dart"
  errors:
    todo: ignore
    fixme: ignore

linter:
  rules:
    - prefer_relative_imports

formatter:
  trailing_commas: preserve
  page_width: 120
```

- [ ] **Step 7: Comprobar**

```bash
flutter pub get
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock .metadata analysis_options.yaml .gitignore lib/main.dart android ios web
git commit -m "[PROJECT-X]: Create the Flutter project next to the current apps"
```

---

### Task 2: Test de reglas de arquitectura

**Files:**
- Create: `test/architecture_test.dart`

**Interfaces:**
- Consumes: nada (lee `lib/` desde disco; si una carpeta aún no existe cuenta como vacía).
- Produces: las reglas que todas las fases deben mantener en verde: dominio sin datos/presentación/Flutter/Flame/DI/servicios; datos sin presentación/Flutter/Flame/BLoC; presentación sin datos; `core/` sin `layers/` salvo `core/services/navigation/` → `layers/presentation/{widgets,theme}/`; entidades sin campos mutables.

- [ ] **Step 1: Escribir el test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const List<String> _domainForbidden = [
  'lib/layers/data/',
  'lib/layers/presentation/',
  'lib/core/config/di/',
  'lib/core/services/',
  'package:flutter/',
  'package:flame',
  'package:flutter_bloc/',
  'package:bloc/',
  'dart:ui',
  'dart:io',
  'dart:html',
];

const List<String> _dataForbidden = [
  'lib/layers/presentation/',
  'package:flutter/',
  'package:flame',
  'package:flutter_bloc/',
  'package:bloc/',
  'dart:ui',
];

const List<String> _presentationForbidden = ['lib/layers/data/'];

const List<String> _coreForbidden = ['lib/layers/'];

const Map<String, List<String>> _coreAllowed = {
  'lib/core/services/navigation/': ['lib/layers/presentation/widgets/', 'lib/layers/presentation/theme/'],
};

final RegExp _importPattern = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

final RegExp _mutableFieldPattern = RegExp(
  r'^  (?!final\b|static\b|const\b|factory\b|return\b|@|//)(?:late\s+)?(?:var\b|[A-Za-z_]\w*(?:<[^;{}()]*>)?\??\s+_?[a-z]\w*\s*(?:=.*)?;)',
  multiLine: true,
);

List<String> importsOf(String source) => _importPattern.allMatches(source).map((match) => match.group(1)!).toList();

String resolveImport({required String importingFile, required String import}) {
  if (import.startsWith('package:rpg/')) return 'lib/${import.substring('package:rpg/'.length)}';
  if (import.startsWith('package:') || import.startsWith('dart:')) return import;
  return Uri.file(importingFile).resolve(import).path;
}

List<String> mutableFieldsIn(String source) =>
    _mutableFieldPattern.allMatches(source).map((match) => match.group(0)!.trim()).toList();

List<File> dartFilesUnder(String folder) {
  final directory = Directory(folder);
  if (!directory.existsSync()) return [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart') && !file.path.endsWith('.config.dart'))
      .toList();
}

List<String> violations({
  required String folder,
  required List<String> forbidden,
  Map<String, List<String>> allowed = const {},
}) {
  final found = <String>[];
  for (final file in dartFilesUnder(folder)) {
    final path = file.path;
    final allowedTargets = allowed.entries
        .where((entry) => path.startsWith(entry.key))
        .expand((entry) => entry.value)
        .toList();
    for (final import in importsOf(file.readAsStringSync())) {
      final target = resolveImport(importingFile: path, import: import);
      final isForbidden = forbidden.any(target.startsWith);
      final isAllowed = allowedTargets.any(target.startsWith);
      if (isForbidden && !isAllowed) found.add('$path -> $target');
    }
  }
  return found;
}

void main() {
  group('rules', () {
    test('testWhenCheckingDomainThenItImportsNothingFromDataPresentationOrPlatforms', () {
      // given
      const folder = 'lib/layers/domain';

      // when
      final found = violations(folder: folder, forbidden: _domainForbidden);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingDataThenItNeverImportsPresentationOrFlutter', () {
      // given
      const folder = 'lib/layers/data';

      // when
      final found = violations(folder: folder, forbidden: _dataForbidden);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingPresentationThenItNeverImportsData', () {
      // given
      const folder = 'lib/layers/presentation';

      // when
      final found = violations(folder: folder, forbidden: _presentationForbidden);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingCoreThenItOnlyImportsLayersThroughTheDocumentedExceptions', () {
      // given
      const folder = 'lib/core';

      // when
      final found = violations(folder: folder, forbidden: _coreForbidden, allowed: _coreAllowed);

      // then
      expect(found, isEmpty);
    });

    test('testWhenCheckingEntitiesThenTheyHaveNoMutableFields', () {
      // given
      final files = dartFilesUnder('lib/layers/domain/entities');

      // when
      final found = [
        for (final file in files)
          for (final field in mutableFieldsIn(file.readAsStringSync())) '${file.path}: $field',
      ];

      // then
      expect(found, isEmpty);
    });
  });

  group('checkers', () {
    test('testWhenResolvingARelativeImportThenItIsRelativeToTheImportingFile', () {
      // given
      const importingFile = 'lib/layers/domain/world/world.dart';

      // when
      final target = resolveImport(importingFile: importingFile, import: '../../data/x/y.dart');

      // then
      expect(target, 'lib/layers/data/x/y.dart');
    });

    test('testWhenResolvingAPackageImportOfTheAppThenItPointsIntoLib', () {
      // given
      const import = 'package:rpg/layers/data/x.dart';

      // when
      final target = resolveImport(importingFile: 'lib/main.dart', import: import);

      // then
      expect(target, 'lib/layers/data/x.dart');
    });

    test('testWhenReadingImportsThenImportsAndExportsAreFound', () {
      // given
      const source = "import 'package:flutter/material.dart';\nexport '../a.dart';\npart 'b.dart';\n";

      // when
      final imports = importsOf(source);

      // then
      expect(imports, ['package:flutter/material.dart', '../a.dart']);
    });

    test('testWhenAnEntityHasVarOrNonFinalFieldsThenTheyAreReported', () {
      // given
      const source = '''
class SampleEntity {
  final double x;
  double y;
  var z = 0;
  static const int limit = 3;
  int get total => 1;
  const SampleEntity({required this.x, required this.y});
  @override
  int get hashCode => Object.hash(x, y);
}
''';

      // when
      final fields = mutableFieldsIn(source);

      // then
      expect(fields, ['double y;', 'var z = 0;']);
    });
  });
}
```

- [ ] **Step 2: Ejecutarlo**

Run: `flutter test test/architecture_test.dart`
Expected: `All tests passed!` (las reglas pasan sobre carpetas vacías o inexistentes; los cuatro tests de `checkers` prueban que los comprobadores detectan lo que deben).

- [ ] **Step 3: Comprobar análisis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add test/architecture_test.dart
git commit -m "[PROJECT-X]: Add the architecture rules test"
```

---

### Task 3: Empaquetar el arte LPC

**Files:**
- Create: `lib/core/assets/images/lpc/{CREDITS.md,forest.json,forest.png,ground.png,hero-chop.png,hero-hammer.png,hero-idle-axe.png,hero-idle.png,hero-walk-axe.png,hero-walk.png}` (copia de `shared/assets/lpc/`)
- Modify: `asset-packs/lpc/build_assets.py:1-25` y `:269-273`
- Modify: `pubspec.yaml` (sección `flutter:`)
- Test: `test/core/assets/lpc_assets_test.dart`

**Interfaces:**
- Consumes: `shared/assets/lpc/` (actual).
- Produces: assets Flutter bajo `lib/core/assets/images/lpc/` (rutas de bundle `lib/core/assets/images/lpc/<fichero>`); la fase 6 configura Flame con `images.prefix = 'lib/core/assets/images/'`.

- [ ] **Step 1: Escribir el test que falla**

`test/core/assets/lpc_assets_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _folder = 'lib/core/assets/images/lpc';

const List<String> _files = [
  'forest.png',
  'forest.json',
  'ground.png',
  'hero-walk.png',
  'hero-idle.png',
  'hero-walk-axe.png',
  'hero-idle-axe.png',
  'hero-chop.png',
  'hero-hammer.png',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('testWhenLoadingTheLpcArtThenEveryFileIsBundled', () async {
    // given
    final paths = [for (final name in _files) '$_folder/$name'];

    // when
    final sizes = [for (final path in paths) (await rootBundle.load(path)).lengthInBytes];

    // then
    expect(sizes.every((size) => size > 0), isTrue);
  });

  test('testWhenReadingTheForestAtlasThenTheHouseKeepsItsBottomCentrePivot', () async {
    // given
    final json = await rootBundle.loadString('$_folder/forest.json');

    // when
    final frames = (jsonDecode(json) as Map<String, dynamic>)['frames'] as Map<String, dynamic>;
    final house = frames['house'] as Map<String, dynamic>;

    // then
    expect(house['pivot'], {'x': 0.5, 'y': 1});
  });
}
```

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/core/assets/lpc_assets_test.dart`
Expected: FAIL con `Unable to load asset: "lib/core/assets/images/lpc/forest.png"`.

- [ ] **Step 3: Copiar el arte y declararlo**

```bash
mkdir -p lib/core/assets/images
cp -R shared/assets/lpc lib/core/assets/images/lpc
```

En `pubspec.yaml`, la sección `flutter:` queda:

```yaml
flutter:
  uses-material-design: true

  assets:
    - lib/core/assets/images/lpc/
```

- [ ] **Step 4: Ejecutar el test**

Run: `flutter test test/core/assets/lpc_assets_test.dart`
Expected: PASS.

- [ ] **Step 5: Apuntar `build_assets.py` a la carpeta nueva y replicar en la vieja**

En `asset-packs/lpc/build_assets.py`, sustituir la cabecera del docstring y las constantes de salida:

```python
"""
Builds the game's LPC textures from the raw sources in ./sources.

  python3 build_assets.py

Outputs (into lib/core/assets/images/lpc/, the copy the Flutter app bundles; mirrored into
shared/assets/lpc/ while the Kotlin Multiplatform apps still exist):
```

(el resto del docstring no cambia)

```python
from pathlib import Path
import json
import shutil

from PIL import Image

ROOT = Path(__file__).parent
SOURCES = ROOT / "sources"
OUT = ROOT.parent.parent / "lib" / "core" / "assets" / "images" / "lpc"
LEGACY_OUT = ROOT.parent.parent / "shared" / "assets" / "lpc"
```

Y el bloque final:

```python
if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    build_character()
    build_forest()
    print(f"Assets written to {OUT}")
    if LEGACY_OUT.parent.exists():
        shutil.copytree(OUT, LEGACY_OUT, dirs_exist_ok=True)
        print(f"Assets mirrored to {LEGACY_OUT}")
```

- [ ] **Step 6: Comprobar el script**

```bash
cd asset-packs/lpc && python3 build_assets.py && cd ../..
diff -r lib/core/assets/images/lpc shared/assets/lpc && echo "same art"
```

Expected: `Assets written to …/lib/core/assets/images/lpc`, `Assets mirrored to …/shared/assets/lpc`, `same art`. Si `git status` muestra PNG de `shared/assets/lpc/` modificados (otra versión de Pillow), restaurarlos con `git checkout -- shared/assets/lpc lib/core/assets/images/lpc` y volver a copiar con el paso 3: el arte no debe cambiar en esta migración.

- [ ] **Step 7: Commit**

```bash
git add lib/core/assets/images/lpc pubspec.yaml asset-packs/lpc/build_assets.py test/core/assets/lpc_assets_test.dart
git commit -m "[PROJECT-X]: Bundle the LPC art in the Flutter project"
```

---

### Task 4: `SeededRandom` y constantes de render

**Files:**
- Create: `lib/core/utils/seeded_random.dart`
- Create: `lib/core/config/constants/render_constants.dart`
- Test: `test/core/utils/seeded_random_test.dart`

**Interfaces:**
- Consumes: nada.
- Produces:
  - `class SeededRandom { SeededRandom(int seed); double next(); }` (fase 3, generador del nivel). No se registra en DI: cada uso crea el suyo con su semilla.
  - `abstract final class RenderConstants` con los valores de abajo (fases 6 y 7).

- [ ] **Step 1: Escribir el test que falla (valores dorados de Kotlin)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/utils/seeded_random.dart';

void main() {
  test('testWhenSeededWith42ThenProducesTheSameSequenceAsTheKotlinVersion', () {
    // given
    final random = SeededRandom(42);

    // when
    final values = [for (var i = 0; i < 5; i++) random.next()];

    // then
    expect(values, [0.2523451747838408, 0.08812504541128874, 0.5772811982315034, 0.22255426598712802, 0.37566019711084664]);
  });
}
```

Nota: en `test/` el import `package:rpg/...` es correcto (los tests no están bajo `lib/`, `prefer_relative_imports` solo afecta a `lib/`).

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/core/utils/seeded_random_test.dart`
Expected: FAIL (`Target of URI doesn't exist: 'package:rpg/core/utils/seeded_random.dart'`).

- [ ] **Step 3: Implementar**

`lib/core/utils/seeded_random.dart`:

```dart
class SeededRandom {
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;
  static const int _mask = 0xFFFFFFFF;
  static const double _modulus = 4294967296;

  int _state;

  SeededRandom(int seed) : _state = seed & _mask;

  double next() {
    _state = (_state * _multiplier + _increment) & _mask;
    return _state / _modulus;
  }
}
```

`lib/core/config/constants/render_constants.dart`:

```dart
abstract final class RenderConstants {
  static const double cameraZoom = 2;
  static const double tileSize = 32;

  static const double characterFrameSize = 64;
  static const double characterAnchorY = 62 / 64;
  static const int rowUp = 0;
  static const int rowLeft = 1;
  static const int rowDown = 2;
  static const int rowRight = 3;

  static const int walkColumns = 9;
  static const int walkFirstStep = 1;
  static const int walkLastStep = 8;
  static const double walkFps = 10;

  static const int idleColumns = 2;
  static const double idleFps = 2;

  static const double workFrameSize = 128;
  static const int workColumns = 6;
  static const double workAnchorY = (32 + 62) / 128;
  static const List<int> chopSequence = [0, 0, 5, 5, 4, 4, 3, 1];
  static const List<int> hammerSequence = [0, 0, 5, 5, 4, 4, 1];

  static const double houseFrontOffset = 24;
}
```

(Valores de `webApp/src/presentation/common/assets.ts`: `CAMERA_ZOOM`, `TILE_SIZE`, `CHARACTER_FRAME_SIZE`, `CHARACTER_ORIGIN_Y`, `FACING_DIRECTIONS` en orden `up, left, down, right`, `WalkSheet`, `IdleSheet`, `WorkSheet`, `HOUSE_FRONT_OFFSET`.)

- [ ] **Step 4: Ejecutar el test en la VM y en Chrome**

```bash
flutter test test/core/utils/seeded_random_test.dart
flutter test --platform chrome test/core/utils/seeded_random_test.dart
```

Expected: PASS en ambos (el producto máximo, ~7,1e15, cabe en 2^53: mismo resultado en JS).

- [ ] **Step 5: Analizar y commit**

```bash
flutter analyze
git add lib/core/utils/seeded_random.dart lib/core/config/constants/render_constants.dart test/core/utils/seeded_random_test.dart
git commit -m "[PROJECT-X]: Port the seeded random generator and render constants"
```

Expected de `flutter analyze`: `No issues found!`

---

### Task 5: Tema y widgets compartidos (requisito de `NavifyImpl`)

`references/core/navigation_service.md` exige que `CustomColors`, `CustomButton` y `CustomPopUp` existan antes de `NavigationService`. Los colores son la paleta del HUD actual (`webApp/src/presentation/screens/forest/hud/hud.css`) más los nombres que usan los widgets del plugin. No hay fuente propia: el HUD actual usa la del sistema (`system-ui`), así que los estilos no fijan `fontFamily`.

**Files:**
- Create: `lib/layers/presentation/theme/colors/custom_colors.dart`
- Create: `lib/layers/presentation/theme/styles/custom_text_styles.dart`
- Create: `lib/layers/presentation/theme/custom_theme.dart`
- Create: `lib/layers/presentation/widgets/custom-button/custom_button.dart`
- Create: `lib/layers/presentation/widgets/custom-button/custom_button_color.dart`
- Create: `lib/layers/presentation/widgets/custom-button/custom_button_size.dart`
- Create: `lib/layers/presentation/widgets/custom-popup/custom_pop_up.dart`
- Test: `test/layers/presentation/widgets/custom-button/custom_button_test.dart`

**Interfaces:**
- Consumes: `flutter_svg`.
- Produces:
  - `CustomColors` con `hudBackground`, `hudBorder`, `hudText`, `hudMuted`, `hudAccent`, `questDone`, `black`, `white`, `gray1Background`, `gray2Background`, `gray4`, `gray6`, `success`, `error`, `warning` (la fase 7 dibuja el HUD con los `hud*`).
  - `CustomTextStyles.system12w700`, `system13w500`, `system13w700`, `system14w400`, `system14w700`, `system15w600`, `system16w400`, `system18w600`, `system24w400`.
  - `CustomTheme.data` (`ThemeData`).
  - `CustomButton({required String label, required Function()? onPressed, CustomButtonColor color, BorderSide? border, CustomButtonSize size, bool isLoading, bool isDisabled, IconData? leadingIcon, EdgeInsetsGeometry? padding, double? elevation, String? leadingIconSvg, double leadingIconSvgPadding})`.
  - `CustomPopUp(...)` y `enum ActionsDirection { vertical, horizontal }` (en `custom_pop_up.dart`, como en el plugin).

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/widgets/custom-button/custom_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/widgets/custom-button/custom_button.dart';

void main() {
  testWidgets('testWhenTappingAnEnabledButtonThenItCallsOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomButton(label: 'Construir aquí', onPressed: () => taps++)),
      ),
    );

    // when
    await tester.tap(find.text('Construir aquí'));

    // then
    expect(taps, 1);
  });

  testWidgets('testWhenTappingADisabledButtonThenItDoesNotCallOnPressed', (tester) async {
    // given
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CustomButton(label: 'Construir aquí', isDisabled: true, onPressed: () => taps++)),
      ),
    );

    // when
    await tester.tap(find.text('Construir aquí'));

    // then
    expect(taps, 0);
  });
}
```

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/layers/presentation/widgets/custom-button/custom_button_test.dart`
Expected: FAIL (URI no existe).

- [ ] **Step 3: Implementar colores y estilos**

`lib/layers/presentation/theme/colors/custom_colors.dart`:

```dart
import 'dart:ui';

class CustomColors {
  static const Color hudBackground = Color(0xD11C1610);
  static const Color hudBorder = Color(0xFF8A6A3F);
  static const Color hudText = Color(0xFFF3E7CF);
  static const Color hudMuted = Color(0xFFB9A888);
  static const Color hudAccent = Color(0xFFE8C05A);
  static const Color questDone = Color(0xFF7CC36B);

  static const Color black = Color(0xFF1C1610);
  static const Color white = Color(0xFFFDFDFD);
  static const Color gray1Background = Color(0xFFF5F8F7);
  static const Color gray2Background = Color(0xFFE7ECEA);
  static const Color gray4 = Color(0xFFCFD1D0);
  static const Color gray6 = Color(0xFF464B49);

  static const Color success = Color(0xFF7CC36B);
  static const Color error = Color(0xFFFD5B60);
  static const Color warning = Color(0xFFE8C05A);
}
```

`lib/layers/presentation/theme/styles/custom_text_styles.dart`:

```dart
import 'package:flutter/material.dart';

class CustomTextStyles {
  static const TextStyle system12w700 = TextStyle(fontSize: 12, fontWeight: .w700);
  static const TextStyle system13w500 = TextStyle(fontSize: 13, fontWeight: .w500);
  static const TextStyle system13w700 = TextStyle(fontSize: 13, fontWeight: .w700);
  static const TextStyle system14w400 = TextStyle(fontSize: 14, fontWeight: .w400);
  static const TextStyle system14w700 = TextStyle(fontSize: 14, fontWeight: .w700);
  static const TextStyle system15w600 = TextStyle(fontSize: 15, fontWeight: .w600, height: 1.2);
  static const TextStyle system16w400 = TextStyle(fontSize: 16, fontWeight: .w400);
  static const TextStyle system18w600 = TextStyle(fontSize: 18, fontWeight: .w600);
  static const TextStyle system24w400 = TextStyle(fontSize: 24, fontWeight: .w400);
}
```

`lib/layers/presentation/theme/custom_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'colors/custom_colors.dart';
import 'styles/custom_text_styles.dart';

class CustomTheme {
  CustomTheme._();

  static final data = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: CustomColors.hudAccent, brightness: .dark),
    scaffoldBackgroundColor: CustomColors.black,
    textTheme: _textTheme(),
    snackBarTheme: _snackBarTheme(),
    dialogTheme: _dialogTheme(),
    progressIndicatorTheme: _progressIndicatorTheme(),
  );

  static TextTheme _textTheme() {
    return TextTheme(
      headlineSmall: CustomTextStyles.system24w400,
      titleMedium: CustomTextStyles.system18w600,
      labelLarge: CustomTextStyles.system14w700,
      bodyLarge: CustomTextStyles.system16w400,
      bodyMedium: CustomTextStyles.system14w400,
    );
  }

  static SnackBarThemeData _snackBarTheme() {
    return SnackBarThemeData(
      contentTextStyle: CustomTextStyles.system15w600.copyWith(color: CustomColors.hudText),
      behavior: SnackBarBehavior.floating,
    );
  }

  static DialogThemeData _dialogTheme() {
    return DialogThemeData(
      backgroundColor: CustomColors.hudBackground,
      shape: RoundedRectangleBorder(borderRadius: .circular(8)),
    );
  }

  static ProgressIndicatorThemeData _progressIndicatorTheme() {
    return const ProgressIndicatorThemeData(color: CustomColors.hudAccent);
  }
}
```

- [ ] **Step 4: Implementar los widgets (copia del ejemplo del plugin adaptada a los estilos de arriba)**

`lib/layers/presentation/widgets/custom-button/custom_button_color.dart`:

```dart
import 'dart:ui';

import '../../theme/colors/custom_colors.dart';

enum CustomButtonColor {
  dark,
  white,
  light,
  lightTwo,
  success,
  failure,
  warning;

  Color get background {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.black;
      case CustomButtonColor.white:
        return CustomColors.white;
      case CustomButtonColor.light:
        return CustomColors.gray1Background;
      case CustomButtonColor.lightTwo:
        return CustomColors.gray2Background;
      case CustomButtonColor.success:
        return CustomColors.success;
      case CustomButtonColor.failure:
        return CustomColors.error;
      case CustomButtonColor.warning:
        return CustomColors.warning;
    }
  }

  Color get foreground {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.white;
      case CustomButtonColor.white:
        return CustomColors.black;
      case CustomButtonColor.light:
        return CustomColors.black;
      case CustomButtonColor.lightTwo:
        return CustomColors.black;
      case CustomButtonColor.success:
        return CustomColors.white;
      case CustomButtonColor.failure:
        return CustomColors.white;
      case CustomButtonColor.warning:
        return CustomColors.white;
    }
  }

  Color get backgroundDisable {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.gray4;
      case CustomButtonColor.white:
        return CustomColors.white;
      case CustomButtonColor.light:
        return CustomColors.gray1Background;
      case CustomButtonColor.lightTwo:
        return CustomColors.gray2Background;
      case CustomButtonColor.success:
        return CustomColors.success;
      case CustomButtonColor.failure:
        return CustomColors.error;
      case CustomButtonColor.warning:
        return CustomColors.warning;
    }
  }

  Color get foregroundDisable {
    switch (this) {
      case CustomButtonColor.dark:
        return CustomColors.black.withValues(alpha: 0.38);
      case CustomButtonColor.white:
        return CustomColors.black.withValues(alpha: 0.20);
      case CustomButtonColor.light:
        return CustomColors.gray4;
      case CustomButtonColor.lightTwo:
        return CustomColors.gray2Background;
      case CustomButtonColor.success:
        return CustomColors.success;
      case CustomButtonColor.failure:
        return CustomColors.error;
      case CustomButtonColor.warning:
        return CustomColors.warning;
    }
  }
}
```

`lib/layers/presentation/widgets/custom-button/custom_button_size.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/styles/custom_text_styles.dart';

enum CustomButtonSize {
  small,
  standard;

  double get size {
    switch (this) {
      case CustomButtonSize.small:
        return 40;
      case CustomButtonSize.standard:
        return 48;
    }
  }

  TextStyle get textStyle {
    switch (this) {
      case CustomButtonSize.small:
        return CustomTextStyles.system12w700;
      case CustomButtonSize.standard:
        return CustomTextStyles.system14w700;
    }
  }

  double get spacing {
    switch (this) {
      case CustomButtonSize.small:
        return 4;
      case CustomButtonSize.standard:
        return 8;
    }
  }

  double get iconSize {
    switch (this) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.standard:
        return 18;
    }
  }
}
```

`lib/layers/presentation/widgets/custom-button/custom_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/colors/custom_colors.dart';
import 'custom_button_color.dart';
import 'custom_button_size.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final Function()? onPressed;
  final CustomButtonColor color;
  final BorderSide? border;
  final CustomButtonSize size;
  final IconData? leadingIcon;
  final String? leadingIconSvg;
  final double leadingIconSvgPadding;
  final double? elevation;
  final bool isLoading;
  final bool isDisabled;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = CustomButtonColor.dark,
    this.border,
    this.size = CustomButtonSize.standard,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.padding,
    this.elevation,
    this.leadingIconSvg,
    this.leadingIconSvgPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.size,
      child: ElevatedButton(
        style: ButtonStyle(
          elevation: WidgetStatePropertyAll(isDisabled ? 0 : elevation ?? 0),
          backgroundColor: isDisabled
              ? WidgetStatePropertyAll(color.backgroundDisable)
              : WidgetStatePropertyAll(color.background),
          foregroundColor: WidgetStatePropertyAll(color.foreground),
          padding: WidgetStatePropertyAll(padding),
          side: WidgetStatePropertyAll(isDisabled ? BorderSide(color: CustomColors.gray4) : border),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: .circular(16))),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (color == CustomButtonColor.dark && states.contains(WidgetState.pressed)) {
              return Colors.white.withAlpha(25);
            }
            return null;
          }),
        ),
        onPressed: isLoading || isDisabled ? null : onPressed,
        child: isLoading ? _loader() : _content(isDisabled),
      ),
    );
  }

  Widget _content(bool isDisabled) {
    return Row(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      spacing: size.spacing,
      children: [
        if (leadingIconSvg != null)
          SvgPicture.asset(
            leadingIconSvg!,
            width: 18,
            height: 18,
            colorFilter: .mode(isDisabled ? color.foregroundDisable : color.foreground, .srcIn),
          ),
        if (leadingIcon != null)
          Icon(leadingIcon!, size: size.iconSize, color: isDisabled ? color.foregroundDisable : color.foreground),
        Flexible(
          child: Text(
            label,
            textAlign: .center,
            softWrap: true,
            overflow: .visible,
            style: size.textStyle.copyWith(color: isDisabled ? color.foregroundDisable : color.foreground),
          ),
        ),
      ],
    );
  }

  Widget _loader() {
    return SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: color.foreground));
  }
}
```

`lib/layers/presentation/widgets/custom-popup/custom_pop_up.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/colors/custom_colors.dart';
import '../custom-button/custom_button.dart';

enum ActionsDirection { vertical, horizontal }

class CustomPopUp extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<CustomButton> actions;
  final ActionsDirection actionsDirection;
  final String? icon;
  final String? image;
  final Color? textColor;

  bool get hasTopWidget => icon != null || image != null;

  EdgeInsets get topPadding {
    if (icon != null) {
      return const .only(top: 8, left: 24, right: 24);
    }

    if (image != null) {
      return const .only(top: 24, left: 24, right: 24);
    }

    return const .only(top: 32, left: 24, right: 24);
  }

  const CustomPopUp({
    super.key,
    required this.title,
    required this.actions,
    this.actionsDirection = ActionsDirection.horizontal,
    this.textColor = CustomColors.hudText,
    this.icon,
    this.image,
    this.message,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      alignment: .center,
      titlePadding: topPadding,
      actionsPadding: const .only(left: 16, right: 16, bottom: 16, top: 16),
      actionsAlignment: .center,
      contentPadding: const .symmetric(horizontal: 24, vertical: 16),
      insetPadding: const .all(32),
      title: !hasTopWidget ? _plainTitle(context) : _titleWithTopWidget(context),
      content: message != null
          ? Text(message!, textAlign: .left, style: TextTheme.of(context).bodyLarge!.copyWith(color: textColor))
          : content,
      actions: [_actions()],
    );
  }

  Widget _plainTitle(BuildContext context) {
    return Text(title, textAlign: .left, style: TextTheme.of(context).headlineSmall!.copyWith(color: textColor));
  }

  Widget _titleWithTopWidget(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Padding(
            padding: const .only(bottom: 16),
            child: SvgPicture.asset(icon!, height: 32, width: 32),
          ),
        if (image != null)
          Padding(
            padding: const .only(bottom: 32),
            child: Image.asset(image!, height: 120, width: 120, fit: .cover),
          ),
        Text(title, textAlign: .center, style: TextTheme.of(context).headlineSmall!.copyWith(color: textColor)),
      ],
    );
  }

  Widget _actions() {
    return actionsDirection == .vertical
        ? Column(
            mainAxisSize: .min,
            spacing: 16,
            children: actions.map((action) => Row(children: [Expanded(child: action)])).toList(),
          )
        : Row(spacing: 16, children: actions.map((action) => Expanded(child: action)).toList());
  }
}
```

- [ ] **Step 5: Ejecutar test y análisis**

```bash
flutter test test/layers/presentation/widgets/custom-button/custom_button_test.dart
flutter analyze
```

Expected: PASS y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/layers/presentation/theme lib/layers/presentation/widgets test/layers/presentation/widgets
git commit -m "[PROJECT-X]: Add the theme and the shared button and pop-up widgets"
```

---

### Task 6: Traducciones y excepciones de la app

**Files:**
- Create: `lib/core/assets/i18n/translations/es.json`
- Create: `lib/core/assets/i18n/internationalize.dart`
- Create: `lib/core/error-handling/exceptions/custom_exception.dart`
- Create: `lib/core/error-handling/exceptions/app_exceptions.dart`
- Create: `lib/core/error-handling/handlers/app_exception_handler.dart`
- Modify: `pubspec.yaml` (asset de traducciones)
- Test: `test/core/error-handling/handlers/app_exception_handler_test.dart`

**Interfaces:**
- Consumes: `easy_localization`, `injectable`.
- Produces (README §3.4):
  - `abstract class CustomException<T extends Object?> implements Exception { final T? data; String get title; String get message; bool hasData(); }`
  - `sealed class AppException<T extends Object?> extends CustomException<T>` con `GenericException()`, `InvalidLevelException({required String data})`, `UnknownTreeKindException({required String data})`, `UnknownDecorationKindException({required String data})`, `UnknownItemKindException({required String data})`, `NoGameInProgressException()`.
  - `@Injectable() class AppExceptionHandler { AppException handle({required Object? exception, StackTrace? stackTrx}); }`
  - `Internationalize.appTitle`, `commonError`, `commonAccept`, `errorGenericTitle`, `errorGenericMessage`, `errorInvalidLevelTitle`, `errorInvalidLevelMessage({required String reason})`, `errorUnknownTreeKindTitle`, `errorUnknownTreeKindMessage({required String detail})`, `errorUnknownDecorationKindTitle`, `errorUnknownDecorationKindMessage({required String detail})`, `errorUnknownItemKindTitle`, `errorUnknownItemKindMessage({required String detail})`, `errorNoGameInProgressTitle`, `errorNoGameInProgressMessage`. La fase 5 añade la sección `forest`.

- [ ] **Step 1: Escribir el test que falla**

`test/core/error-handling/handlers/app_exception_handler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';

void main() {
  late AppExceptionHandler handler;

  setUp(() {
    handler = AppExceptionHandler();
  });

  test('testWhenHandlingAnAppExceptionThenItIsReturnedUnchanged', () {
    // given
    const exception = InvalidLevelException(data: 'missing width');

    // when
    final handled = handler.handle(exception: exception);

    // then
    expect(identical(handled, exception), isTrue);
  });

  test('testWhenHandlingAnUnknownErrorThenItBecomesAGenericException', () {
    // given
    final error = StateError('boom');

    // when
    final handled = handler.handle(exception: error, stackTrx: StackTrace.current);

    // then
    expect(handled, isA<GenericException>());
  });

  test('testWhenHandlingNullThenItBecomesAGenericException', () {
    // given
    const Object? error = null;

    // when
    final handled = handler.handle(exception: error);

    // then
    expect(handled, isA<GenericException>());
  });

  test('testWhenALevelExceptionCarriesDetailsThenTheyAreItsData', () {
    // given
    const exception = UnknownTreeKindException(data: 'tree-3: "palm"');

    // when
    final hasData = exception.hasData();

    // then
    expect(hasData, isTrue);
    expect(exception.data, 'tree-3: "palm"');
  });
}
```

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/core/error-handling/handlers/app_exception_handler_test.dart`
Expected: FAIL (URI no existe).

- [ ] **Step 3: Traducciones**

`lib/core/assets/i18n/translations/es.json`:

```json
{
  "app": {
    "title": "RPG"
  },
  "common": {
    "error": "Error",
    "accept": "Aceptar"
  },
  "error": {
    "genericTitle": "Error",
    "genericMessage": "Se ha producido un error. Inténtalo de nuevo más tarde.",
    "invalidLevelTitle": "Nivel no válido",
    "invalidLevelMessage": "El nivel no es válido: {reason}",
    "unknownTreeKindTitle": "Árbol desconocido",
    "unknownTreeKindMessage": "El nivel tiene un árbol de un tipo desconocido: {detail}",
    "unknownDecorationKindTitle": "Decoración desconocida",
    "unknownDecorationKindMessage": "El nivel tiene una decoración de un tipo desconocido: {detail}",
    "unknownItemKindTitle": "Objeto desconocido",
    "unknownItemKindMessage": "El nivel tiene un objeto de un tipo desconocido: {detail}",
    "noGameInProgressTitle": "No hay partida",
    "noGameInProgressMessage": "No hay ninguna partida en curso."
  }
}
```

`lib/core/assets/i18n/internationalize.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';

class Internationalize {
  static const String _app = 'app';
  static String get appTitle => '$_app.title'.tr();

  static const String _common = 'common';
  static String get commonError => '$_common.error'.tr();
  static String get commonAccept => '$_common.accept'.tr();

  static const String _error = 'error';
  static String get errorGenericTitle => '$_error.genericTitle'.tr();
  static String get errorGenericMessage => '$_error.genericMessage'.tr();
  static String get errorInvalidLevelTitle => '$_error.invalidLevelTitle'.tr();
  static String errorInvalidLevelMessage({required String reason}) =>
      '$_error.invalidLevelMessage'.tr(namedArgs: {'reason': reason});
  static String get errorUnknownTreeKindTitle => '$_error.unknownTreeKindTitle'.tr();
  static String errorUnknownTreeKindMessage({required String detail}) =>
      '$_error.unknownTreeKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorUnknownDecorationKindTitle => '$_error.unknownDecorationKindTitle'.tr();
  static String errorUnknownDecorationKindMessage({required String detail}) =>
      '$_error.unknownDecorationKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorUnknownItemKindTitle => '$_error.unknownItemKindTitle'.tr();
  static String errorUnknownItemKindMessage({required String detail}) =>
      '$_error.unknownItemKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorNoGameInProgressTitle => '$_error.noGameInProgressTitle'.tr();
  static String get errorNoGameInProgressMessage => '$_error.noGameInProgressMessage'.tr();
}
```

En `pubspec.yaml`, añadir la carpeta de traducciones a `assets`:

```yaml
  assets:
    - lib/core/assets/i18n/translations/
    - lib/core/assets/images/lpc/
```

- [ ] **Step 4: Excepciones y manejador**

`lib/core/error-handling/exceptions/custom_exception.dart`:

```dart
abstract class CustomException<T extends Object?> implements Exception {
  final T? data;

  String get title;
  String get message;

  const CustomException({this.data});

  bool hasData() => data != null;
}
```

`lib/core/error-handling/exceptions/app_exceptions.dart`:

```dart
import '../../assets/i18n/internationalize.dart';
import 'custom_exception.dart';

sealed class AppException<T extends Object?> extends CustomException<T> {
  const AppException({super.data});
}

final class GenericException extends AppException {
  @override
  String get title => Internationalize.errorGenericTitle;

  @override
  String get message => Internationalize.errorGenericMessage;

  const GenericException();
}

final class InvalidLevelException extends AppException<String> {
  @override
  String get title => Internationalize.errorInvalidLevelTitle;

  @override
  String get message => Internationalize.errorInvalidLevelMessage(reason: data!);

  const InvalidLevelException({required String super.data});
}

final class UnknownTreeKindException extends AppException<String> {
  @override
  String get title => Internationalize.errorUnknownTreeKindTitle;

  @override
  String get message => Internationalize.errorUnknownTreeKindMessage(detail: data!);

  const UnknownTreeKindException({required String super.data});
}

final class UnknownDecorationKindException extends AppException<String> {
  @override
  String get title => Internationalize.errorUnknownDecorationKindTitle;

  @override
  String get message => Internationalize.errorUnknownDecorationKindMessage(detail: data!);

  const UnknownDecorationKindException({required String super.data});
}

final class UnknownItemKindException extends AppException<String> {
  @override
  String get title => Internationalize.errorUnknownItemKindTitle;

  @override
  String get message => Internationalize.errorUnknownItemKindMessage(detail: data!);

  const UnknownItemKindException({required String super.data});
}

final class NoGameInProgressException extends AppException {
  @override
  String get title => Internationalize.errorNoGameInProgressTitle;

  @override
  String get message => Internationalize.errorNoGameInProgressMessage;

  const NoGameInProgressException();
}
```

`lib/core/error-handling/handlers/app_exception_handler.dart`:

```dart
import 'package:injectable/injectable.dart';

import '../exceptions/app_exceptions.dart';

@Injectable()
class AppExceptionHandler {
  AppException handle({required Object? exception, StackTrace? stackTrx}) {
    if (exception is AppException) {
      return exception;
    }

    return const GenericException();
  }
}
```

(No hay `SocketException` ni `DioException`: el juego no hace red, excepción E7.)

- [ ] **Step 5: Ejecutar test y análisis**

```bash
flutter test test/core/error-handling/handlers/app_exception_handler_test.dart
flutter analyze
```

Expected: PASS y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/assets/i18n lib/core/error-handling pubspec.yaml test/core/error-handling
git commit -m "[PROJECT-X]: Add translations and the app exceptions"
```

---

### Task 7: Servicios de logging y navegación

**Files:**
- Create: `lib/core/services/logging/source/logger.dart`
- Create: `lib/core/services/logging/hybrid-logger/custom_logger_impl.dart`
- Create: `lib/core/services/logging/bloc/bloc_logger.dart`
- Create: `lib/core/services/navigation/source/navigation_service.dart`
- Create: `lib/core/services/navigation/navify/navify_impl.dart`
- Test: `test/core/services/navigation/navify/navify_impl_test.dart`

**Interfaces:**
- Consumes: `CustomColors`, `CustomButton`, `CustomPopUp`, `ActionsDirection` (tarea 5); `hybrid_logger`, `injectable`, `flutter_bloc`.
- Produces:
  - `abstract interface class Logger { void success({required String message, String? header}); void error({required String message, String? header, StackTrace? stackTrace}); void warning(...); void info(...); void debug(...); }` — `@Singleton(as: Logger) CustomLoggerImpl`. Sin métodos HTTP (no hay red).
  - `@Singleton() class BlocLogger extends BlocObserver` (solo `onError`).
  - `abstract interface class NavigationService` exactamente como `references/core/navigation_service.md` (incluye `navigatorKey`, `push`, `pop`, `pushReplacement`, `pushAndRemoveUntil`, `popUntil`, `popUntilFirst`, `canPop`, `showSheet`, `showFullScreenSheet`, `showErrorPopUp`, `showPopUp`, `showSnackbar({required String message, double? bottomMargin})`, `showLoader`) — `@Singleton(as: NavigationService) NavifyImpl`. La fase 5 usa `showSnackbar` para los mensajes del juego.

- [ ] **Step 1: Escribir el test que falla**

`test/core/services/navigation/navify/navify_impl_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/services/navigation/navify/navify_impl.dart';

void main() {
  late NavifyImpl navify;

  setUp(() {
    navify = NavifyImpl();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(navigatorKey: navify.navigatorKey, home: const Scaffold()));
  }

  testWidgets('testWhenShowingASnackbarThenItsMessageIsVisible', (tester) async {
    // given
    await pumpApp(tester);

    // when
    navify.showSnackbar(message: '+6 de madera');
    await tester.pump();

    // then
    expect(find.text('+6 de madera'), findsOneWidget);
  });

  testWidgets('testWhenShowingASecondSnackbarThenOnlyTheLastOneIsVisible', (tester) async {
    // given
    await pumpApp(tester);
    navify.showSnackbar(message: 'Manos a la obra…');
    await tester.pump();

    // when
    navify.showSnackbar(message: '¡Casa construida!');
    await tester.pumpAndSettle();

    // then
    expect(find.text('Manos a la obra…'), findsNothing);
    expect(find.text('¡Casa construida!'), findsOneWidget);
  });

  testWidgets('testWhenPushingAPageThenItCanBePopped', (tester) async {
    // given
    await pumpApp(tester);

    // when
    navify.push(const Scaffold(body: Text('second')));
    await tester.pumpAndSettle();

    // then
    expect(find.text('second'), findsOneWidget);
    expect(navify.canPop(), isTrue);
  });
}
```

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/core/services/navigation/navify/navify_impl_test.dart`
Expected: FAIL (URI no existe).

- [ ] **Step 3: Logging**

`lib/core/services/logging/source/logger.dart`:

```dart
abstract interface class Logger {
  void success({required String message, String? header});
  void error({required String message, String? header, StackTrace? stackTrace});
  void warning({required String message, String? header});
  void info({required String message, String? header});
  void debug({required String message, String? header});
}
```

`lib/core/services/logging/hybrid-logger/custom_logger_impl.dart`:

```dart
import 'package:hybrid_logger/hybrid_logger.dart';
import 'package:injectable/injectable.dart';

import '../source/logger.dart';

@Singleton(as: Logger)
class CustomLoggerImpl implements Logger {
  final HybridLogger _hybridLogger = HybridLogger(
    settings: HybridSettings(type: LogTypeEntity.debug, maxLineWidth: 50),
  );

  @override
  void debug({required String message, String? header}) {
    _hybridLogger.debug(message, header: header);
  }

  @override
  void error({required String message, String? header, StackTrace? stackTrace}) {
    _hybridLogger.error(message, header: header, stack: stackTrace);
  }

  @override
  void info({required String message, String? header}) {
    _hybridLogger.info(message, header: header);
  }

  @override
  void success({required String message, String? header}) {
    _hybridLogger.success(message, header: header);
  }

  @override
  void warning({required String message, String? header}) {
    _hybridLogger.warning(message, header: header);
  }
}
```

(Si la versión resuelta de `hybrid_logger` cambió la firma de `HybridLogger`/`HybridSettings`, adaptar solo estas llamadas siguiendo su README y anotarlo en README §7.)

`lib/core/services/logging/bloc/bloc_logger.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../source/logger.dart';

@Singleton()
class BlocLogger extends BlocObserver {
  final Logger _logger;

  const BlocLogger({required this._logger});

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.error(message: error.toString(), stackTrace: stackTrace, header: 'Bloc Error');
    super.onError(bloc, error, stackTrace);
  }
}
```

- [ ] **Step 4: Navegación (texto exacto de `references/core/navigation_service.md`)**

`lib/core/services/navigation/source/navigation_service.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../layers/presentation/widgets/custom-button/custom_button.dart';
import '../../../../layers/presentation/widgets/custom-popup/custom_pop_up.dart';

abstract interface class NavigationService {
  GlobalKey<NavigatorState> get navigatorKey;
  Future<T?>? push<T extends Object?>(Widget page, {Object? arguments});
  void pop<T extends Object?>([T? result]);
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page, {
    Object? arguments,
    TO? result,
  });
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page, {
    RoutePredicate? predicate,
    Object? arguments,
  });
  void popUntil(RoutePredicate predicate);
  void popUntilFirst();
  bool canPop();
  void showSheet(
    Widget sheet, {
    bool isDismissible = true,
    VoidCallback? onDismiss,
  });
  void showFullScreenSheet(Widget sheet, {bool isDismissible = true});

  void showErrorPopUp({
    required String title,
    String? message,
    Widget? content,
    required String buttonTitle,
    bool willPop = false,
  });
  Future<void> showPopUp({
    required String title,
    String? message,
    Widget? content,
    required List<CustomButton> actions,
    Color? textColor,
    bool isDismissible = true,
    ActionsDirection actionsDirection = .horizontal,
    String? icon,
    String? image,
  });

  void showSnackbar({required String message, double? bottomMargin});

  void showLoader();
}
```

`lib/core/services/navigation/navify/navify_impl.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../layers/presentation/theme/colors/custom_colors.dart';
import '../../../../layers/presentation/widgets/custom-button/custom_button.dart';
import '../../../../layers/presentation/widgets/custom-popup/custom_pop_up.dart';
import '../source/navigation_service.dart';

@Singleton(as: NavigationService)
class NavifyImpl implements NavigationService {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<T?>? push<T extends Object?>(Widget page, {Object? arguments}) {
    return navigatorKey.currentState!.push<T>(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
    );
  }

  @override
  void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }

  @override
  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page, {
    Object? arguments,
    TO? result,
  }) {
    return navigatorKey.currentState!.pushReplacement<T, TO>(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
      result: result,
    );
  }

  @override
  Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page, {
    RoutePredicate? predicate,
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(arguments: arguments),
      ),
      predicate ?? (route) => false,
    );
  }

  @override
  void popUntil(RoutePredicate predicate) {
    navigatorKey.currentState!.popUntil(predicate);
  }

  @override
  void popUntilFirst() {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }

  @override
  bool canPop() {
    return navigatorKey.currentState!.canPop();
  }

  @override
  void showSheet(
    Widget sheet, {
    bool isDismissible = true,
    VoidCallback? onDismiss,
  }) {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: CustomColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: isDismissible
            ? const .only(
                topLeft: .circular(16),
                topRight: .circular(16),
              )
            : .zero,
      ),
      context: navigatorKey.currentContext!,
      builder: (context) => sheet,
    ).then((_) {
      if (onDismiss != null) {
        onDismiss();
      }
    });
  }

  @override
  void showFullScreenSheet(
    Widget sheet, {
    bool isDismissible = true,
  }) {
    final rootContext = navigatorKey.currentContext!;
    final rootMediaQuery = MediaQuery.of(rootContext);

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      useSafeArea: false,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      shape: null,
      builder: (_) {
        return Material(
          color: CustomColors.white,
          child: Padding(
            padding: .only(
              top: rootMediaQuery.padding.top,
            ),
            child: sheet,
          ),
        );
      },
    );
  }

  @override
  void showErrorPopUp({
    required String title,
    String? message,
    Widget? content,
    required String buttonTitle,
    bool willPop = false,
  }) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => CustomPopUp(
        title: title,
        message: message,
        content: content,
        actions: [
          CustomButton(
            label: buttonTitle,
            onPressed: () {
              pop();
              if (willPop) pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Future<void> showPopUp({
    required String title,
    required List<CustomButton> actions,
    String? message,
    Widget? content,
    Color? textColor,
    ActionsDirection actionsDirection = .horizontal,
    bool isDismissible = true,
    String? icon,
    String? image,
  }) {
    return showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: isDismissible,
      builder: (context) => CustomPopUp(
        title: title,
        message: message,
        content: content,
        actions: actions,
        textColor: textColor,
        actionsDirection: actionsDirection,
        icon: icon,
        image: image,
      ),
    );
  }

  @override
  void showSnackbar({required String message, double? bottomMargin}) {
    final scaffoldMessenger = ScaffoldMessenger.of(
      navigatorKey.currentContext!,
    );

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: CustomColors.gray6,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: .circular(16),
        ),
        content: Text(message),
        margin: .only(
          bottom: bottomMargin ?? 16.0,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  @override
  void showLoader() {
    final context = navigatorKey.currentContext!;
    showDialog(
      useSafeArea: false,
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 5,
          color: CustomColors.white,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Ejecutar tests y análisis**

```bash
flutter test test/core/services/navigation/navify/navify_impl_test.dart test/architecture_test.dart
flutter analyze
```

Expected: PASS (la regla de `core/` admite `core/services/navigation/` → `layers/presentation/{widgets,theme}/`) y `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/services test/core/services
git commit -m "[PROJECT-X]: Add the logging and navigation services"
```

---

### Task 8: Inyección de dependencias

**Files:**
- Create: `lib/core/config/di/locator.dart`
- Create: `lib/core/config/di/di.dart`
- Create: `lib/core/config/di/di_environment.dart`
- Create (generado): `lib/core/config/di/di.config.dart`
- Create: `lib/core/config/env/environment_constants.dart`
- Create: `lib/core/config/env/development_environment.json`
- Create: `lib/core/config/env/production_environment.json`
- Test: `test/core/config/di/di_test.dart`

**Interfaces:**
- Consumes: `NavifyImpl`, `CustomLoggerImpl`, `BlocLogger`, `AppExceptionHandler` (tareas 6–7).
- Produces:
  - `GetIt get locator` (`locator.dart`).
  - `Future<void> configureDependencies({required String environment})` (`di.dart`). La fase 4 añade aquí, tras `locator.init(...)`, el registro manual del `ForestBloc`.
  - `DiEnvironment.dev`, `DiEnvironment.prod`, `DiEnvironment.mock`.
  - `EnvironmentConstants.name`, `EnvironmentConstants.diEnvironment` (por defecto `dev`, así `flutter run` funciona sin flags; la fase 8 compila la web con `--dart-define-from-file=lib/core/config/env/production_environment.json`).

- [ ] **Step 1: Escribir el test que falla**

`test/core/config/di/di_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/di/di.dart';
import 'package:rpg/core/config/di/di_environment.dart';
import 'package:rpg/core/config/di/locator.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/core/services/logging/bloc/bloc_logger.dart';
import 'package:rpg/core/services/logging/hybrid-logger/custom_logger_impl.dart';
import 'package:rpg/core/services/logging/source/logger.dart';
import 'package:rpg/core/services/navigation/navify/navify_impl.dart';
import 'package:rpg/core/services/navigation/source/navigation_service.dart';

void main() {
  tearDown(() async {
    await locator.reset();
  });

  test('testWhenConfiguringDependenciesThenTheCoreServicesAreRegistered', () async {
    // given
    const environment = DiEnvironment.dev;

    // when
    await configureDependencies(environment: environment);

    // then
    expect(locator<NavigationService>(), isA<NavifyImpl>());
    expect(locator<Logger>(), isA<CustomLoggerImpl>());
    expect(locator<BlocLogger>(), isA<BlocLogger>());
    expect(locator<AppExceptionHandler>(), isA<AppExceptionHandler>());
  });

  test('testWhenResolvingTheNavigationServiceTwiceThenItIsTheSameInstance', () async {
    // given
    await configureDependencies(environment: DiEnvironment.dev);

    // when
    final first = locator<NavigationService>();
    final second = locator<NavigationService>();

    // then
    expect(identical(first, second), isTrue);
  });
}
```

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/core/config/di/di_test.dart`
Expected: FAIL (URI no existe).

- [ ] **Step 3: Ficheros de DI y entorno**

`lib/core/config/di/locator.dart`:

```dart
import 'package:get_it/get_it.dart';

GetIt get locator => GetIt.instance;
```

`lib/core/config/di/di.dart`:

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'di.config.dart';

@InjectableInit()
Future<void> configureDependencies({required String environment}) => GetIt.instance.init(environment: environment);
```

`lib/core/config/di/di_environment.dart`:

```dart
class DiEnvironment {
  static const String mock = 'mock';
  static const String dev = 'dev';
  static const String prod = 'prod';
}
```

`lib/core/config/env/environment_constants.dart`:

```dart
import '../di/di_environment.dart';

class EnvironmentConstants {
  static const String name = String.fromEnvironment('ENVIRONMENT_NAME', defaultValue: 'DEV');
  static const String diEnvironment = String.fromEnvironment('DI_ENVIRONMENT', defaultValue: DiEnvironment.dev);
}
```

`lib/core/config/env/development_environment.json`:

```json
{
  "ENVIRONMENT_NAME": "DEV",
  "DI_ENVIRONMENT": "dev"
}
```

`lib/core/config/env/production_environment.json`:

```json
{
  "ENVIRONMENT_NAME": "PROD",
  "DI_ENVIRONMENT": "prod"
}
```

- [ ] **Step 4: Generar `di.config.dart`**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: se crea `lib/core/config/di/di.config.dart` con `NavifyImpl`, `CustomLoggerImpl`, `BlocLogger` (singletons) y `AppExceptionHandler` (factory). No se edita a mano.

- [ ] **Step 5: Ejecutar tests y análisis**

```bash
flutter test test/core/config/di/di_test.dart test/architecture_test.dart
flutter analyze
```

Expected: PASS y `No issues found!` (`di.config.dart` está excluido del análisis y del test de arquitectura).

- [ ] **Step 6: Commit**

```bash
git add lib/core/config test/core/config
git commit -m "[PROJECT-X]: Configure dependency injection"
```

---

### Task 9: `ContainerApp`, `main.dart` y arranque en web

La app arranca con el bootstrap de `gen-main` y muestra un `ContainerApp` cuyo estado `Success` es, de momento, una pantalla vacía. La fase 7 cambia ese estado para navegar a `ForestPage`.

**Files:**
- Create: `lib/layers/presentation/app/bloc/container_app_bloc.dart`
- Create: `lib/layers/presentation/app/bloc/container_app_event.dart`
- Create: `lib/layers/presentation/app/bloc/container_app_state.dart`
- Create: `lib/layers/presentation/app/container_app.dart`
- Modify: `lib/main.dart` (sustituye al generado)
- Test: `test/layers/presentation/app/bloc/container_app_bloc_test.dart`

**Interfaces:**
- Consumes: `configureDependencies`, `locator`, `EnvironmentConstants`, `BlocLogger`, `NavigationService`, `Internationalize`, `CustomTheme`, `CustomColors`, `CustomException`.
- Produces:
  - `ContainerAppBloc()` con `ContainerAppStarted` → `ContainerAppInProgress`, `ContainerAppSuccess`. Estados `ContainerAppInitial`, `ContainerAppInProgress`, `ContainerAppSuccess`, `ContainerAppFailure({required ContainerAppData data, required CustomException exception})`, datos `ContainerAppData`.
  - `ContainerApp` (`MaterialApp` con `navigatorKey` de `NavigationService`, delegados de `easy_localization`, `CustomTheme.data`, `title: Internationalize.appTitle`) y `ContainerAppView` con `_bodyByState`.

- [ ] **Step 1: Escribir el test que falla**

`test/layers/presentation/app/bloc/container_app_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/app/bloc/container_app_bloc.dart';

void main() {
  test('testWhenCreatedThenTheStateIsInitial', () {
    // given
    final bloc = ContainerAppBloc();

    // when
    final state = bloc.state;

    // then
    expect(state, isA<ContainerAppInitial>());
  });

  blocTest<ContainerAppBloc, ContainerAppState>(
    'testWhenStartedThenEmitsInProgressAndSuccess',
    // given
    build: ContainerAppBloc.new,
    // when
    act: (bloc) => bloc.add(ContainerAppStarted()),
    // then
    expect: () => [isA<ContainerAppInProgress>(), isA<ContainerAppSuccess>()],
  );
}
```

- [ ] **Step 2: Ejecutarlo para verlo fallar**

Run: `flutter test test/layers/presentation/app/bloc/container_app_bloc_test.dart`
Expected: FAIL (URI no existe).

- [ ] **Step 3: BLoC del contenedor**

`lib/layers/presentation/app/bloc/container_app_event.dart`:

```dart
part of 'container_app_bloc.dart';

sealed class ContainerAppEvent {}

final class ContainerAppStarted extends ContainerAppEvent {}
```

`lib/layers/presentation/app/bloc/container_app_state.dart`:

```dart
part of 'container_app_bloc.dart';

final class ContainerAppData {
  const ContainerAppData();

  ContainerAppData copyWith() {
    return const ContainerAppData();
  }
}

sealed class ContainerAppState {
  final ContainerAppData data;

  const ContainerAppState({required this.data});
}

final class ContainerAppInitial extends ContainerAppState {
  const ContainerAppInitial() : super(data: const ContainerAppData());
}

final class ContainerAppInProgress extends ContainerAppState {
  const ContainerAppInProgress({required super.data});
}

final class ContainerAppSuccess extends ContainerAppState {
  const ContainerAppSuccess({required super.data});
}

final class ContainerAppFailure extends ContainerAppState {
  final CustomException exception;

  const ContainerAppFailure({required super.data, required this.exception});
}
```

`lib/layers/presentation/app/bloc/container_app_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error-handling/exceptions/custom_exception.dart';

part 'container_app_event.dart';
part 'container_app_state.dart';

class ContainerAppBloc extends Bloc<ContainerAppEvent, ContainerAppState> {
  ContainerAppBloc() : super(const ContainerAppInitial()) {
    on<ContainerAppEvent>((event, emit) async {
      await switch (event) {
        ContainerAppStarted() => _onStarted(event, emit),
      };
    });
  }

  Future<void> _onStarted(ContainerAppStarted event, Emitter<ContainerAppState> emit) async {
    emit(ContainerAppInProgress(data: state.data));

    emit(ContainerAppSuccess(data: state.data));
  }
}
```

- [ ] **Step 4: Vista del contenedor**

`lib/layers/presentation/app/container_app.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/assets/i18n/internationalize.dart';
import '../../../core/config/di/locator.dart';
import '../../../core/services/navigation/source/navigation_service.dart';
import '../theme/colors/custom_colors.dart';
import '../theme/custom_theme.dart';
import 'bloc/container_app_bloc.dart';

class ContainerApp extends StatelessWidget {
  const ContainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContainerAppBloc()..add(ContainerAppStarted()),
      child: MaterialApp(
        title: Internationalize.appTitle,
        navigatorKey: locator<NavigationService>().navigatorKey,
        theme: CustomTheme.data,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        home: const ContainerAppView(),
      ),
    );
  }
}

class ContainerAppView extends StatelessWidget {
  const ContainerAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContainerAppBloc, ContainerAppState>(
      builder: (context, state) {
        return Scaffold(backgroundColor: CustomColors.black, body: _bodyByState(state));
      },
    );
  }

  Widget _bodyByState(ContainerAppState state) {
    return switch (state) {
      ContainerAppInitial() => _loadingBody(),
      ContainerAppInProgress() => _loadingBody(),
      ContainerAppSuccess() => _emptyBody(),
      ContainerAppFailure() => _errorBody(),
    };
  }

  Widget _loadingBody() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _emptyBody() {
    return const SizedBox.expand();
  }

  Widget _errorBody() {
    return Center(child: Text(Internationalize.commonError));
  }
}
```

- [ ] **Step 5: `main.dart`**

`lib/main.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/di/di.dart';
import 'core/config/di/locator.dart';
import 'core/config/env/environment_constants.dart';
import 'core/services/logging/bloc/bloc_logger.dart';
import 'layers/presentation/app/container_app.dart';

void main() async {
  await _initialize();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('es')],
      path: 'lib/core/assets/i18n/translations',
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      child: const ContainerApp(),
    ),
  );
}

Future<void> _initialize() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await EasyLocalization.ensureInitialized();
  EasyLocalization.logger.enableBuildModes = [];

  await configureDependencies(environment: EnvironmentConstants.diEnvironment);

  Bloc.observer = locator<BlocLogger>();
}
```

(Orden de `gen-main`: binding, `SystemChrome`, `EasyLocalization`, DI, `Bloc.observer`. Sin orientación fija, sin Hive, sin `NetworkService`: no existen en este proyecto.)

- [ ] **Step 6: Ejecutar toda la batería y el análisis**

```bash
flutter test
flutter test --platform chrome test/core/utils
flutter analyze
dart format --line-length 120 --set-exit-if-changed lib test
```

Expected: `All tests passed!` (arquitectura, assets, `SeededRandom`, botón, excepciones, navegación, DI, contenedor), PASS en Chrome, `No issues found!` y `dart format` sin cambios (si cambia algo, volver a ejecutar sin `--set-exit-if-changed` y añadir el resultado al commit).

- [ ] **Step 7: Arranque real en web y compilación**

```bash
flutter run -d chrome
```

Expected: se abre Chrome con la pestaña titulada `RPG` y una pantalla oscura vacía (`CustomColors.black`), sin errores en la consola de `flutter run`. Salir con `q`.

```bash
flutter build web --release
```

Expected: `✓ Built build/web`.

- [ ] **Step 8: Comprobar que lo viejo sigue intacto**

```bash
git status --porcelain | grep -E '^( M|D |MM)' | grep -v -E ' (lib/main.dart)$' || echo "old projects untouched"
```

Expected: `old projects untouched`. Opcional, si hay tiempo: `./gradlew :shared:allTests` sigue verde (no debería verse afectado; las apps viejas siguen leyendo `shared/assets/lpc/`).

- [ ] **Step 9: Commit**

```bash
git add lib/layers/presentation/app lib/main.dart test/layers/presentation/app
git commit -m "[PROJECT-X]: Bootstrap the app with an empty container screen"
```

---

## Cierre de la fase

- `flutter analyze` → `No issues found!`
- `flutter test` → todo verde; `flutter test --platform chrome test/core/utils` → verde.
- `flutter run -d chrome` muestra la app vacía titulada `RPG`.
- `shared/`, `androidApp/`, `iosApp/`, `webApp/` y Gradle sin cambios; el despliegue actual a Pages no se ve afectado (el workflow no vigila `lib/`, `android/`, `ios/`, `web/` ni `pubspec.yaml`).
- Cualquier desviación (por ejemplo, firma distinta de `hybrid_logger` o de `flutter create`) se anota en [README §7](README.md#7-desviaciones-encontradas-al-ejecutar) con su commit.
