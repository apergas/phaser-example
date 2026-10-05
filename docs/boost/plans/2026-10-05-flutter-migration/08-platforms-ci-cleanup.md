# Fase 8 — Plataformas, CI y limpieza — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar los tres runners de Flutter (Android, iOS, web) configurados como las apps actuales, sustituir el despliegue de GitHub Pages por uno de Flutter, borrar todo el código KMP / Compose / SwiftUI / Phaser y reescribir `README.md` y `CLAUDE.md` para el proyecto Flutter.

**Architecture:** No cambia `lib/`. Se tocan solo los runners generados por `flutter create` (`android/`, `ios/`, `web/`), el workflow `.github/workflows/deploy.yml`, `asset-packs/lpc/build_assets.py`, ficheros de la raíz (`.gitignore`, `.vscode/settings.json`, `README.md`, `CLAUDE.md`) y se eliminan con `git rm` las carpetas y ficheros del stack anterior.

**Tech Stack:** Flutter 3.47.x / Dart 3.13.x, GitHub Actions (`subosito/flutter-action`, `actions/upload-pages-artifact`, `actions/deploy-pages`), PlistBuddy (iOS), Gradle Kotlin DSL del runner Android de Flutter.

## Global Constraints

- Todas las restricciones de [`README.md`](README.md) § Global Constraints aplican a esta fase.
- App name `RPG` es el único texto por plataforma: `android:label` en `AndroidManifest.xml`, `CFBundleDisplayName` en `ios/Runner/Info.plist`, `<title>` en `web/index.html` y `name`/`short_name` en `web/manifest.json`.
- Ids: Android `namespace` y `applicationId` `com.apergas.rpg`; iOS `PRODUCT_BUNDLE_IDENTIFIER` `com.apergas.rpg` (tests `com.apergas.rpg.RunnerTests`).
- Android `compileSdk` y `targetSdk` **36** (regla de equipo), escritos como literales, no `flutter.compileSdkVersion`.
- Orientación como hoy: Android `android:screenOrientation="userLandscape"`; iOS solo `UIInterfaceOrientationLandscapeLeft` y `UIInterfaceOrientationLandscapeRight` (iPhone y iPad) y `UIRequiresFullScreen = YES`; despliegue mínimo iOS 17.0.
- Las apps antiguas no tienen iconos propios (Android solo tiene `res/values`, iOS no tiene `.xcassets` de icono): se mantienen los iconos por defecto de Flutter. El único recurso gráfico propio es `webApp/public/favicon.svg`, que pasa a `web/favicon.svg`.
- Web: `base href` solo por el flag `--base-href /phaser-example/` en CI; `web/index.html` conserva el `$FLUTTER_BASE_HREF` de la plantilla para que `flutter run -d chrome` funcione en `/`.
- CI genera el código con `build_runner` siempre (`--delete-conflicting-outputs`): funciona igual si la fase 1 decidió versionar `di.config.dart` / `*.mocks.dart` o ignorarlos.
- Memoria del usuario: tras el merge a `main` se comprueba el despliegue real en Pages; **no** se simula CI con Docker ni `act`.
- Commits `[PROJECT-X]: Imperative description`, sin ninguna atribución a IA. `CLAUDE.md` se añade en un `git add` propio, separado del resto.

---

### Task 1: Runner Android (nombre, ids, SDK 36, orientación)

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: runner `android/` creado en la fase 1 con `flutter create --org com.apergas --project-name rpg --platforms android,ios,web .`
- Produces: APK `com.apergas.rpg`, etiqueta `RPG`, apaisado.

- [ ] **Step 1: Comprobar el estado actual del runner**

Run:
```bash
grep -nE 'namespace|applicationId|compileSdk|targetSdk' android/app/build.gradle.kts
grep -nE 'android:label|screenOrientation' android/app/src/main/AndroidManifest.xml
```
Expected: `namespace = "com.apergas.rpg"`, `applicationId = "com.apergas.rpg"`, `compileSdk = flutter.compileSdkVersion`, `targetSdk = flutter.targetSdkVersion`, `android:label="rpg"` y ninguna línea `screenOrientation`.

- [ ] **Step 2: Fijar ids y SDK 36**

Run:
```bash
sed -i '' -E \
  -e 's/^( *)namespace = ".*"/\1namespace = "com.apergas.rpg"/' \
  -e 's/^( *)applicationId = ".*"/\1applicationId = "com.apergas.rpg"/' \
  -e 's/^( *)compileSdk = .*/\1compileSdk = 36/' \
  -e 's/^( *)targetSdk = .*/\1targetSdk = 36/' \
  android/app/build.gradle.kts
grep -nE 'namespace|applicationId|compileSdk|targetSdk' android/app/build.gradle.kts
```
Expected (sangría según la plantilla):
```
    namespace = "com.apergas.rpg"
    compileSdk = 36
        applicationId = "com.apergas.rpg"
        targetSdk = 36
```

- [ ] **Step 3: Nombre y orientación en el manifiesto**

Run:
```bash
sed -i '' -E \
  -e 's/android:label="[^"]*"/android:label="RPG"/' \
  -e 's/(<activity)$/\1\n            android:screenOrientation="userLandscape"/' \
  android/app/src/main/AndroidManifest.xml
grep -nE 'android:label|screenOrientation' android/app/src/main/AndroidManifest.xml
```
Expected:
```
        android:label="RPG"
            android:screenOrientation="userLandscape"
```
Si `<activity` no está sola en su línea (la plantilla puede cambiar), añadir a mano `android:screenOrientation="userLandscape"` como atributo del elemento `<activity android:name=".MainActivity" ...>` y repetir el `grep`.

- [ ] **Step 4: Compilar e instalar en el emulador**

Run:
```bash
flutter build apk --debug
flutter run -d emulator-5554 --debug
```
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. En el emulador (AVD `Medium_Phone_API_36.0`) el icono se llama **RPG**, la app abre en apaisado y no gira a vertical al rotar el dispositivo. Salir con `q`.

- [ ] **Step 5: Commit**

```bash
git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml
git commit -m "[PROJECT-X]: Configure the Android runner name, ids, SDK 36 and landscape"
```

---

### Task 2: Runner iOS (nombre, bundle id, iOS 17, apaisado)

**Files:**
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/Podfile` (si existe)

**Interfaces:**
- Consumes: runner `ios/` de la fase 1.
- Produces: app `com.apergas.rpg`, nombre `RPG`, solo apaisado, pantalla completa, iOS ≥ 17.0.

- [ ] **Step 1: Nombre, orientaciones y pantalla completa**

Run:
```bash
PLIST=ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName RPG" "$PLIST"
for key in UISupportedInterfaceOrientations "UISupportedInterfaceOrientations~ipad"; do
  /usr/libexec/PlistBuddy -c "Delete :$key" "$PLIST" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Add :$key array" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :$key:0 string UIInterfaceOrientationLandscapeLeft" "$PLIST"
  /usr/libexec/PlistBuddy -c "Add :$key:1 string UIInterfaceOrientationLandscapeRight" "$PLIST"
done
/usr/libexec/PlistBuddy -c "Delete :UIRequiresFullScreen" "$PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :UIRequiresFullScreen bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" -c "Print :UISupportedInterfaceOrientations" -c "Print :UIRequiresFullScreen" "$PLIST"
```
Expected:
```
RPG
Array {
    UIInterfaceOrientationLandscapeLeft
    UIInterfaceOrientationLandscapeRight
}
true
```

- [ ] **Step 2: Bundle id y despliegue mínimo**

Run:
```bash
PBX=ios/Runner.xcodeproj/project.pbxproj
sed -i '' -E \
  -e 's/PRODUCT_BUNDLE_IDENTIFIER = [A-Za-z0-9.]*\.RunnerTests;/PRODUCT_BUNDLE_IDENTIFIER = com.apergas.rpg.RunnerTests;/' \
  -e '/RunnerTests;/!s/PRODUCT_BUNDLE_IDENTIFIER = [A-Za-z0-9.]*;/PRODUCT_BUNDLE_IDENTIFIER = com.apergas.rpg;/' \
  -e 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/IPHONEOS_DEPLOYMENT_TARGET = 17.0;/' \
  "$PBX"
grep -E 'PRODUCT_BUNDLE_IDENTIFIER|IPHONEOS_DEPLOYMENT_TARGET' "$PBX" | sort | uniq -c
[ -f ios/Podfile ] && sed -i '' -E "s/^#? *platform :ios, '[0-9.]+'/platform :ios, '17.0'/" ios/Podfile && grep -n "platform :ios" ios/Podfile
```
Expected: solo `PRODUCT_BUNDLE_IDENTIFIER = com.apergas.rpg;` (×3) y `PRODUCT_BUNDLE_IDENTIFIER = com.apergas.rpg.RunnerTests;` (×3), todas las líneas `IPHONEOS_DEPLOYMENT_TARGET = 17.0;`, y `platform :ios, '17.0'` si hay `Podfile`.

- [ ] **Step 3: Compilar y abrir en el simulador**

Run:
```bash
flutter build ios --simulator --debug
flutter run -d "iPhone 17" --debug
```
Expected: `✓ Built build/ios/iphonesimulator/Runner.app`. En el simulador el icono se llama **RPG** y la app solo se muestra en apaisado. Salir con `q`.

- [ ] **Step 4: Commit**

```bash
git add ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
[ -f ios/Podfile ] && git add ios/Podfile
[ -f ios/Podfile.lock ] && git add ios/Podfile.lock
git commit -m "[PROJECT-X]: Configure the iOS runner name, bundle id, iOS 17 and landscape"
```

---

### Task 3: Runner web (título, manifiesto, favicon)

**Files:**
- Modify: `web/index.html` (contenido completo abajo)
- Modify: `web/manifest.json` (contenido completo abajo)
- Create: `web/favicon.svg` (copia de `webApp/public/favicon.svg`)
- Delete: `web/favicon.png`

**Interfaces:**
- Consumes: runner `web/` de la fase 1.
- Produces: `build/web` servible bajo `/phaser-example/`.

- [ ] **Step 1: Copiar el favicon actual**

Run:
```bash
cp webApp/public/favicon.svg web/favicon.svg
git rm -q web/favicon.png
```
Expected: sin salida.

- [ ] **Step 2: Escribir `web/index.html`**

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="RPG">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/svg+xml" href="favicon.svg">
  <link rel="manifest" href="manifest.json">
  <title>RPG</title>
  <style>
    html, body { margin: 0; height: 100%; overflow: hidden; background: #0e150e; }
  </style>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

- [ ] **Step 3: Escribir `web/manifest.json`**

```json
{
  "name": "RPG",
  "short_name": "RPG",
  "start_url": ".",
  "display": "standalone",
  "orientation": "landscape",
  "background_color": "#0e150e",
  "theme_color": "#0e150e",
  "prefer_related_applications": false,
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

- [ ] **Step 4: Build de producción con la ruta de Pages y prueba local**

Run:
```bash
flutter build web --release --base-href /phaser-example/
grep -o '<base href="[^"]*">' build/web/index.html
grep -o '<title>[^<]*</title>' build/web/index.html
ls build/web/assets/lib/core/assets/images/lpc/forest.json
```
Expected:
```
<base href="/phaser-example/">
<title>RPG</title>
build/web/assets/lib/core/assets/images/lpc/forest.json
```

Luego, para probarlo bajo la misma sub-ruta que Pages:
```bash
rm -rf /tmp/pages && mkdir -p /tmp/pages && cp -R build/web /tmp/pages/phaser-example
python3 -m http.server 8080 --directory /tmp/pages
```
Abrir http://localhost:8080/phaser-example/: pestaña "RPG" con el favicon del juego, el bosque carga, se recoge el hacha y se tala un árbol. Parar el servidor con Ctrl+C.

- [ ] **Step 5: Commit**

```bash
git add web/index.html web/manifest.json web/favicon.svg
git commit -m "[PROJECT-X]: Configure the web runner title, manifest and favicon"
```

---

### Task 4: Despliegue a GitHub Pages con Flutter

**Files:**
- Modify: `.github/workflows/deploy.yml` (contenido completo abajo)

**Interfaces:**
- Consumes: `flutter analyze`, `flutter test`, tests dorados en Chrome (`test/core/utils`, `test/layers/data`) de las fases 1 y 3.
- Produces: artefacto `build/web` publicado en https://apergas.github.io/phaser-example/.

- [ ] **Step 1: Escribir `.github/workflows/deploy.yml`**

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - 'lib/**'
      - 'test/**'
      - 'web/**'
      - 'pubspec.yaml'
      - 'pubspec.lock'
      - 'analysis_options.yaml'
      - 'build.yaml'
      - 'asset-packs/**'
      - '.github/workflows/deploy.yml'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
      # The forest must be identical on the web (JS numbers): golden values also run in Chrome.
      - run: flutter test --platform chrome test/core/utils test/layers/data
      - run: flutter build web --release --base-href /phaser-example/

      - uses: actions/configure-pages@v6
      - uses: actions/upload-pages-artifact@v5
        with:
          path: build/web

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v5
```

Si `build.yaml` no existe en la raíz (la fase 1 decide si hace falta), quitar esa línea de `paths`. Si al ejecutar `subosito/flutter-action@v2` ya hay una versión mayor publicada, usar la mayor estable vigente ese día.

- [ ] **Step 2: Validar la sintaxis localmente (sin simular CI)**

Run:
```bash
python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/deploy.yml')); print('ok')"
```
Expected: `ok`. (No se usa `act` ni Docker: el despliegue real se comprueba en la Task 8.)

- [ ] **Step 3: Ejecutar en local los mismos pasos**

Run:
```bash
flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test && flutter test --platform chrome test/core/utils test/layers/data
```
Expected: `No issues found!` y `All tests passed!` en ambas ejecuciones de tests.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/deploy.yml
git commit -m "[PROJECT-X]: Build and deploy the Flutter web app to GitHub Pages"
```

---

### Task 5: Borrar el stack anterior y limpiar la raíz

**Files:**
- Delete: `shared/`, `androidApp/`, `iosApp/`, `webApp/`, `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/`, `gradlew`, `gradlew.bat`, `kotlin-js-store/`
- Modify: `asset-packs/lpc/build_assets.py:6,25`
- Modify: `.gitignore` (contenido completo abajo)
- Modify: `.vscode/settings.json` (contenido completo abajo)

**Interfaces:**
- Consumes: el arte vive en `lib/core/assets/images/lpc/` desde la fase 1.
- Produces: repo solo con Flutter, `asset-packs/` y `docs/`.

- [ ] **Step 1: Comprobar que no queda nada de Flutter apuntando al código viejo**

Run:
```bash
grep -rnE 'shared/|webApp|androidApp|iosApp' lib test web android/app/src pubspec.yaml || echo "clean"
```
Expected: `clean`.

- [ ] **Step 2: `git rm` del código anterior**

Run:
```bash
git rm -r -q shared androidApp iosApp webApp kotlin-js-store gradle
git rm -q settings.gradle.kts build.gradle.kts gradle.properties gradlew gradlew.bat
git status --short | grep -vE '^D ' || echo "only deletions"
```
Expected: `only deletions`. (Si `shared/assets/lpc/` seguía existiendo como copia del arte durante la migración, se borra aquí con `shared/`.)

- [ ] **Step 3: Borrar cachés locales sin seguimiento del stack anterior**

Run:
```bash
rm -rf .gradle .kotlin local.properties
ls -a | grep -E '^(\.gradle|\.kotlin|local\.properties)$' || echo "removed"
```
Expected: `removed`. (`android/local.properties` lo gestiona Flutter y no se toca.)

- [ ] **Step 4: `build_assets.py` escribe solo en la carpeta de Flutter**

Sustituir la línea 6 del docstring:
```python
Outputs (into shared/assets/lpc/, the one copy the web, Android and iOS apps all read):
```
por:
```python
Outputs (into lib/core/assets/images/lpc/, the one copy the Flutter app reads on every platform):
```
y la línea 25:
```python
OUT = ROOT.parent.parent / "shared" / "assets" / "lpc"
```
por:
```python
OUT = ROOT.parent.parent / "lib" / "core" / "assets" / "images" / "lpc"
```
Si la fase 1 ya cambió `OUT` y añadió escrituras adicionales a `shared/assets/lpc`, eliminar esas escrituras para que solo quede `OUT`.

Run:
```bash
grep -nE 'shared|OUT =' asset-packs/lpc/build_assets.py
cd asset-packs/lpc && python3 build_assets.py && cd ../.. && git status --short lib/core/assets/images/lpc
```
Expected: solo `OUT = ROOT.parent.parent / "lib" / "core" / "assets" / "images" / "lpc"` (ninguna línea con `shared`) y `git status` sin cambios en el arte (la salida es idéntica a la versionada).

- [ ] **Step 5: Escribir `.gitignore`**

```gitignore
.DS_Store
__MACOSX
__pycache__

# Overrides the global gitignore: this repo shares its Claude Code guidance
!CLAUDE.md

# Local knowledge graph generated by the graphify hooks; rebuilt on every commit
graphify-out/

# Flutter / Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
build/
coverage/

# IDE
*.iml
.idea/
xcuserdata/
```

Si la fase 1 decidió **no** versionar el código generado, añadir al final las líneas que la fase 1 puso en su `.gitignore` (por ejemplo `*.mocks.dart` y `lib/core/config/di/di.config.dart`); si lo versiona, no añadir nada.

- [ ] **Step 6: Escribir `.vscode/settings.json`**

```json
{
  "dart.lineLength": 120,
  "[dart]": {
    "editor.rulers": [120],
    "editor.formatOnSave": true
  }
}
```

- [ ] **Step 7: Verificar que todo sigue verde**

Run:
```bash
flutter pub get && flutter analyze && flutter test
```
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git add -A shared androidApp iosApp webApp kotlin-js-store gradle settings.gradle.kts build.gradle.kts gradle.properties gradlew gradlew.bat
git add asset-packs/lpc/build_assets.py .gitignore .vscode/settings.json
git commit -m "[PROJECT-X]: Remove the Kotlin Multiplatform, Compose, SwiftUI and Phaser projects"
```

---

### Task 6: Reescribir `README.md`

**Files:**
- Modify: `README.md` (contenido completo abajo)
- Modify: `docs/boost/plans/2026-10-04-kmp-migration/README.md:1` (nota de histórico)

- [ ] **Step 1: Escribir `README.md`**

````markdown
# phaser-example

Top-down (3/4 view) gather-and-build game prototype written in **Flutter** for Android, iOS and the web. The
world is drawn with **Flame**; the HUD is plain Flutter widgets. The code follows the team's Flutter Clean
Architecture conventions (`flutter-arch-conventions`): `core/` plus `domain` / `data` / `presentation` layers,
get_it + injectable, BLoC and easy_localization.

```
lib/
  main.dart
  core/          assets (LPC art, i18n), config (enums, render constants, DI), error-handling, services, utils
  layers/
    domain/      entities, world (simulation aggregate), quests, rules, repositories, use-cases
    data/        datasources (procedural level, in-memory session), mappers, repositories
    presentation/ app (ContainerApp), features/forest (BLoC, Flame game, HUD widgets), theme
test/            mirrors lib/, plus mocks/ and architecture_test.dart
android/ ios/ web/  Flutter runners
asset-packs/lpc/ LPC art sources and build_assets.py
```

Layer rules are checked by `test/architecture_test.dart`.

Gather-and-build loop: pick up the axe next to the spawn point, tap or click a tree to chop it (5 hits,
5–6 wood each), then use **Construir** to place a house (15 wood) and watch it being built. **Misiones** lists the
current goals and their progress.

## Run locally

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # DI config and mockito mocks
flutter analyze
flutter test                                                # all tests on the VM
flutter test --platform chrome test/core/utils test/layers/data   # forest golden values on the web
flutter run -d chrome                                       # web
flutter run -d emulator-5554                                # Android emulator
flutter run -d "iPhone 17"                                  # iOS simulator
```

Needs the Flutter SDK (stable), Chrome for the web, the Android SDK and Xcode for the mobile targets.

Every push to `main` that touches the app runs analysis and tests, builds the web app with
`--base-href /phaser-example/` and publishes `build/web` to GitHub Pages: https://apergas.github.io/phaser-example/
(`.github/workflows/deploy.yml`).

## Art

- `asset-packs/lpc/` — Liberated Pixel Cup sources and `build_assets.py`, which generates the textures in
  `lib/core/assets/images/lpc/`, the single copy the app reads on every platform (requires Pillow):
  `cd asset-packs/lpc && python3 build_assets.py`.

LPC art is licensed CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0 and requires attribution:
see [`lib/core/assets/images/lpc/CREDITS.md`](lib/core/assets/images/lpc/CREDITS.md).

## History

The project was first a Phaser + TypeScript game, then a Kotlin Multiplatform core with Compose, SwiftUI and Phaser
front ends, and is now a single Flutter app. The migration plans are in `docs/boost/plans/`
(`2026-10-04-kmp-migration/` is historical; `2026-10-05-flutter-migration/` describes the current code).
````

- [ ] **Step 2: Marcar el plan KMP como histórico**

Insertar como primera línea de `docs/boost/plans/2026-10-04-kmp-migration/README.md`, seguida de una línea en blanco:
```markdown
> **Histórico.** Este plan describe la migración a Kotlin Multiplatform, sustituida por la app Flutter (ver `../2026-10-05-flutter-migration/`). Ningún fichero que menciona sigue en el repo.
```

Run:
```bash
head -2 docs/boost/plans/2026-10-04-kmp-migration/README.md
```
Expected: la nota y una línea en blanco.

- [ ] **Step 3: Commit**

```bash
git add README.md docs/boost/plans/2026-10-04-kmp-migration/README.md
git commit -m "[PROJECT-X]: Document the Flutter project in the README"
```

---

### Task 7: Reescribir `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (contenido completo abajo)

- [ ] **Step 1: Escribir `CLAUDE.md`**

````markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Layout

- Single **Flutter** app at the repo root (Android, iOS, web), Dart package `rpg`. All game logic and all views live in `lib/`.
- `lib/core/` — `assets/` (`images/lpc/`: the only copy of the art, with `CREDITS.md`; `i18n/translations/es.json` + `i18n/internationalize.dart`), `config/` (`constants/enum/` with every enum, `constants/render_constants.dart`, `di/` with `locator.dart`, `di.dart`, generated `di.config.dart`, `di_environment.dart`), `error-handling/` (`CustomException`, `AppException` cases, `AppExceptionHandler`), `services/navigation/` (`NavigationService`: snackbars), `utils/seeded_random.dart`.
- `lib/layers/domain/`, `lib/layers/data/`, `lib/layers/presentation/` — see Architecture.
- `test/` mirrors `lib/`; `test/mocks/` holds centralised mock data; `test/architecture_test.dart` enforces the layer rules.
- `android/`, `ios/`, `web/` — Flutter runners (app name `RPG`, ids `com.apergas.rpg`, landscape only).
- `asset-packs/lpc/` — raw LPC art and `build_assets.py`, which generates `lib/core/assets/images/lpc/`.
- `.github/workflows/deploy.yml` — on pushes to `main` that touch the app: `build_runner`, `flutter analyze`, `flutter test`, golden tests in Chrome, `flutter build web --base-href /phaser-example/` and publish `build/web` to GitHub Pages (https://apergas.github.io/phaser-example/). Android and iOS are tested locally only.
- `docs/boost/plans/2026-10-05-flutter-migration/` — the migration plan; its README section 7 records every deviation found while executing it. `2026-10-04-kmp-migration/` is historical.

## Commands

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs          # regenerate di.config.dart and *.mocks.dart after DI/mock changes
flutter analyze                                                   # lints (flutter_lints + prefer_relative_imports); must be clean
flutter test                                                      # all tests on the Dart VM
flutter test test/layers/domain/world                             # filtered
flutter test --platform chrome test/core/utils test/layers/data   # forest golden values on the web
dart format --line-length 120 lib test
flutter run -d chrome | flutter run -d emulator-5554 | flutter run -d "iPhone 17"
flutter build web --release --base-href /phaser-example/
```

Regenerate art after editing the asset script: `cd asset-packs/lpc && python3 build_assets.py` (needs Pillow).

## Architecture

Team conventions from the `flutter-arch-conventions` plugin: `PRESENTATION -> DOMAIN <- DATA`, `CORE` used by all. `test/architecture_test.dart` checks that domain imports nothing from data/presentation nor Flutter/Flame/`dart:ui`/`dart:io`, data never imports presentation, presentation never imports data, core imports nothing from `layers/` (except the NavigationService widgets), and entities have only `final` fields.

- `lib/layers/domain/`
  - `entities/<feature>/` — immutable `*Entity` classes: `final` fields, `const` constructor, `copyWith`, computed getters, hand-written `==`/`hashCode`. Geometry, tree, item, decoration, building (`BlueprintEntity`, `BuildingEntity`), player (`InventoryEntity`, `PlayerEntity`, sealed `ActivityEntity`, sealed `IntentEntity`), game (sealed `GameEventEntity`, sealed `ConstructionResultEntity`, `PlayerStatusEntity`, `WorldSnapshotEntity`, `QuestProgressEntity`, `BuildOptionEntity`, `GameSessionEntity`).
  - `world/` — `World`, the mutable aggregate and only entry point that changes the game. It owns a `WorldState` and delegates to systems: `Navigation`, `Woodcutting`, `Construction`, `pickUpItems`. Work mechanics are an `IntentEntity` subtype + a `Work` + one case in `workFor()` (exhaustive `switch`). `advance(deltaMs)` returns `GameEventEntity`s. `world/extensions/` holds the entity operations (`hit`, `hammer`, `addWood`, `spendWood`, `walkTo`, `distanceTo`...).
  - `quests/` (`Quest`, `Quests`, `QuestLog` with sticky completion), `rules/` (`Rules` tuning, `Blueprints` catalogue), `repositories/` (interfaces).
  - `use-cases/game/` — one `@Injectable()` class per action with a synchronous `call()`: start game, move player, chop tree, can place / construct building, advance, player status, world snapshot, build options, quests. Each reads the session from `GameSessionRepository`.
- `lib/layers/data/` — `datasources/level` (`LevelLocalDatasourceImpl`: seeded procedural forest that also decides each tree's kind and the ground decoration; all-nullable DBOs in `local/dbo/`), `datasources/session` (in-memory, `@LazySingleton`: one game per app), `repositories/level` (`LevelRepositoryImpl` + injected `*MapperDBO`s), `repositories/session`. Errors go through `AppExceptionHandler`.
- `lib/layers/presentation/`
  - `app/container_app.dart` — `ContainerApp` (`MaterialApp` with easy_localization and the navigator key of `NavigationService`).
  - `features/forest/bloc/` — `ForestBloc` (single `on<ForestEvent>` with `await switch`; events `ForestStarted`, `ForestTicked`, `ForestMapClicked`, `ForestPointerMoved`, `ForestBuildRequested`, `ForestPlacementCancelled`; states `ForestInitial` / `ForestInProgress` / `ForestSuccess` / `ForestFailure` carrying `ForestData`). Handlers are synchronous so ticks keep frame order. Messages are snackbars through `NavigationService`.
  - `features/forest/models/` — view models (`PlayerRenderData`, sealed `PlayerPose`, `HudData`, `QuestItemData`, `BuildItemData`, `PlacementData`) and sealed `ForestEffect` (played once per emitted state).
  - `features/forest/game/` — Flame: `ForestGame` (`update` adds `ForestTicked`; reconciles components with `ForestData.world` by id; plays effects), `components/` (ground, decoration, trees with pixel-accurate taps, items, buildings by stage, animated player, placement ghost, particles), `atlas/` (`LpcAtlas` for `forest.json`, `SpriteNames`).
  - `features/forest/widgets/` — HUD (wood, axe, build menu, quest panel, touch placement bar), rebuilt only when `HudData` changes. `forest_page.dart` — `ForestPage` (creates the BLoC from `locator`, adds `ForestStarted`) + `_ForestView` (`_bodyByState` switch; `GameWidget` under the HUD).
  - `theme/` — `CustomColors`, `CustomTextStyles`.

Documented exceptions to the plugin (keep them; do not "fix" them):

- E1 — `domain/world/`, `domain/quests/`, `domain/rules/` exist besides entities/repositories/use-cases: the simulation is a mutable aggregate.
- E2 — entity operations live in `domain/world/extensions/`; entities keep only computed getters.
- E3 — use cases have a synchronous `call()`: the game advances per frame with no I/O.
- E4 — entities use the enums in `core/config/constants/enum/` (`TreeKind`, `ToolKind`, ...).
- E5 — `GameSessionLocalDatasource` stores the `GameSessionEntity` in memory (no DBO).
- E6 — repositories read only the local datasource (no remote, no cache-first).
- E7 — core has only `di`, `error-handling`, `services/navigation`, `utils`, `assets` (no network/storage/connection yet).
- E8 — sealed hierarchies are declared in a single file.
- E9 — `features/forest/` adds `models/` and `game/` (Flame) next to `bloc/`, `widgets/` and the page.

Key cross-cutting conventions:

- **Positions are feet / trunk bases**, in world units = native art pixels; the domain and Flame are both Y-down (no conversion). The same point drives collision, sprite anchoring and draw order (component `priority` = base `y`).
- **The map is level data:** tree positions, wood, kinds and ground decoration come from the data layer; the view never picks art or places decor itself (`SpriteNames` maps kind → atlas frame).
- **Rendering constants** (`render_constants.dart`): camera zoom 2; LPC 64 px character frames, rows `up, left, down, right`, walk columns 1–8 at 10 fps, idle 2 columns at 2 fps; work sheets 128 px with sequences chop `[0,0,5,5,4,4,3,1]` and hammer `[0,0,5,5,4,4,1]`, frame chosen from `swingProgress` so the impact frame matches the hit; house drawn 24 px below its footprint centre; sprites drawn with `FilterQuality.none`.
- Tree taps/clicks are pixel-accurate (texture alpha), so shadows and gaps between leaves fall through to movement. On the web, right click or Esc cancels placement; touch screens get the placement bar.

## Constraints

- Versions only in `pubspec.yaml` (caret constraints, `sdk: ^3.13.0`); bump a dependency in its own commit. Android `compileSdk`/`targetSdk` 36 is a team rule.
- Plugin rules: folders kebab-case, files snake_case with type suffix, classes with type suffix (`TreeEntity`, `ChopTreeUseCase`, `LevelLocalDatasourceImpl`, `LevelDBO`, `LevelMapperDBO`, `ForestBloc`, `ForestPage`); `locator`, never `GetIt.instance`; no `@Injectable()` on BLoCs; no `Equatable`; nullable `copyWith` fields with `ValueGetter`; no comments in `lib/`; `dart format --line-length 120`; regenerate DI after any change outside `presentation/`.
- Tests: mirror `lib/`; names `testWhen<Action>Then<Result>`; `// given`, `// when`, `// then`; mocks with mockito `@GenerateMocks`, BLoCs with `blocTest`; mock data as `static` fields in `test/mocks/**/<name>_mock.dart` (e.g. `TreeEntityMock.mock`), never declared inline in a test.
- Code, identifiers and comments in English; player-facing text in Spanish only in `es.json`, read through `Internationalize` (the app name `RPG` is the only per-platform text: `AndroidManifest.xml`, `Info.plist`, `web/index.html`, `web/manifest.json`).
- LPC art is CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0: any new LPC asset must be credited in `lib/core/assets/images/lpc/CREDITS.md`.
- Git flow: `main` (published) / `develop` (default) / `feature/PROJECT-X-<description>` branches. A git hook enforces commit messages as `[PROJECT-123]: Imperative description` (or `[PROJECT-X]: ...` without a ticket), branches as `(feature|bugfix|hotfix)/PROJECT-123-description`, and rejects any AI attribution (no `Co-Authored-By` for an AI, no Claude/Anthropic mentions).
````

Ajustar antes de escribir: si alguna fase anterior registró en el README del plan (§7) un nombre o ruta distinto del contrato (por ejemplo la ubicación final de `NavigationService` o de `internationalize.dart`), usar el nombre real en este fichero.

- [ ] **Step 2: Comprobar que las rutas citadas existen**

Run:
```bash
for p in lib/core/assets/images/lpc/CREDITS.md lib/core/assets/i18n/translations/es.json lib/core/config/constants/render_constants.dart lib/core/config/di/di.dart lib/core/utils/seeded_random.dart lib/layers/domain/world lib/layers/presentation/features/forest/game test/architecture_test.dart; do [ -e "$p" ] && echo "ok $p" || echo "MISSING $p"; done
```
Expected: todas las líneas `ok ...`. Si alguna es `MISSING`, corregir la ruta en `CLAUDE.md` con la real.

- [ ] **Step 3: Commit (CLAUDE.md en su propio `git add`)**

```bash
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the Flutter architecture for Claude Code"
```

---

### Task 8: Verificación final, desviaciones y despliegue

**Files:**
- Modify: `docs/boost/plans/2026-10-05-flutter-migration/README.md` (§7 Desviaciones encontradas al ejecutar)

- [ ] **Step 1: Buscar restos del stack anterior**

Run:
```bash
rg -n -i "kotlin|gradle|phaser|SKIE|ForestViewModel|shared/assets|webApp|androidApp|iosApp|npm" \
  --glob '!docs/**' --glob '!android/**' --glob '!ios/**' --glob '!build/**' --glob '!.dart_tool/**' \
  --glob '!graphify-out/**' --glob '!asset-packs/lpc/sources/**'
```
Expected: solo coincidencias legítimas: el nombre del repo `phaser-example` (README, CLAUDE.md, workflow `--base-href /phaser-example/`) y la sección *History* del README. Cualquier otra coincidencia se elimina o corrige. (`android/` se excluye porque el runner de Flutter usa Gradle Kotlin DSL y `MainActivity.kt` legítimamente.)

- [ ] **Step 2: Árbol de la raíz esperado**

Run:
```bash
git ls-files | cut -d/ -f1 | sort -u
```
Expected exactamente:
```
.github
.gitignore
.metadata
.vscode
CLAUDE.md
README.md
analysis_options.yaml
android
asset-packs
docs
ios
lib
pubspec.lock
pubspec.yaml
test
web
```
(más `build.yaml` si la fase 1 lo creó).

- [ ] **Step 3: Análisis y tests completos**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
dart format --line-length 120 --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome test/core/utils test/layers/data
```
Expected: `0 changed`, `No issues found!`, `All tests passed!` (×2).

- [ ] **Step 4: Partida completa en las tres plataformas**

Run por turnos:
```bash
flutter run -d chrome --release
flutter run -d emulator-5554 --release
flutter run -d "iPhone 17" --release
```
En cada una: bienvenida en snackbar, recoger el hacha, talar hasta 15 de madera, *Construir* → *Casa* → colocar (web: clic; clic derecho o Esc cancela; táctil: barra *Construir aquí* / *Cancelar*), ver la casa construirse por fases y llegar a "¡Has completado todas las misiones!". Apaisado en móvil, nombre **RPG** en el icono y en la pestaña.

- [ ] **Step 5: Registrar desviaciones**

En `docs/boost/plans/2026-10-05-flutter-migration/README.md` §7, sustituir la línea "(Se rellena durante la ejecución: ...)" por una tabla con todas las desviaciones encontradas en las fases 1–8:

```markdown
| Fase | Desviación | Motivo | Commit |
|---|---|---|---|
| 8 | (una fila por desviación real; si no hubo ninguna en una fase, una fila "Ninguna") | | |
```

Rellenar cada fila con datos reales (`git log --oneline develop..HEAD` para los hashes). Si no hubo desviaciones en todo el plan, dejar una única fila `| — | Ninguna | — | — |`.

- [ ] **Step 6: Commit**

```bash
git add docs/boost/plans/2026-10-05-flutter-migration/README.md
git commit -m "[PROJECT-X]: Record the Flutter migration deviations in the plan"
```

- [ ] **Step 7: Integración y comprobación del despliegue real**

Usar boost:finishing-a-development-branch para abrir la PR `feature/PROJECT-X-flutter-migration` → `develop` (descripción en español, sin atribución a IA). Después del merge de `develop` a `main` (lo hace el equipo):

Run:
```bash
gh run list --workflow deploy.yml --branch main --limit 1
gh run watch "$(gh run list --workflow deploy.yml --branch main --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
curl -s https://apergas.github.io/phaser-example/ | grep -o '<title>[^<]*</title>'
curl -s -o /dev/null -w '%{http_code}\n' https://apergas.github.io/phaser-example/flutter_bootstrap.js
```
Expected: el run termina en `completed success`, `<title>RPG</title>` y `200`. Abrir https://apergas.github.io/phaser-example/ en el navegador y repetir la partida del Step 4. Si el run falla, leer el log con `gh run view --log-failed` y corregir en una rama `bugfix/PROJECT-X-...`; no simular CI con Docker ni `act`.
