# X · Alineación con la versión iOS — ficha

> **Plan detallado: pendiente.** Al empezar, `boost:writing-plans` sobre esta ficha. Es trabajo sin fase propia: commits `[PROJECT-X]: …`, rama `feature/PROJECT-X-ios-alignment`.

| | |
|---|---|
| **Rama** | `feature/PROJECT-X-ios-alignment`, desde `feature/PROJECT-X-arena` (con el arreglo de `bugfix/PROJECT-X-resume-construction` ya unido) |
| **Issue** | #55 (`stream:C`, sin etiqueta de fase ni milestone: no es una fase de la hoja de ruta) |
| **Depende de** | C8 y el arreglo de reanudar obras (`a16317c`) |
| **Va antes de** | C9 (todo lo que viene después usa el nombre y el paquete nuevos) |
| **Referencia iOS** | `$IOS` = `/Users/axelperezgaspar/farming-ios`. Migración M0–M7 (`develop` @ `f181ddd`), decisiones D17–D18 de `$IOS/docs/plans/2026-10-12-swiftui-migration/README.md` y notas de `$IOS/.boost/sdd/cross-phase-notes.md` |

## Objetivo

Que la app Flutter sea la misma que la de iOS antes de portar las fases nuevas: mismo nombre, mismos identificadores, mismo icono y los pequeños cambios de comportamiento que la migración a iOS introdujo a propósito. Desde aquí el desarrollo sigue en Flutter; el repositorio iOS queda como referencia.

## Decisiones ya tomadas

**Nombre e identificadores** (decidido por el usuario el 2026-10-17: nombre visible **e** ids):
- Nombre visible `Farming` en todas las plataformas: `app.title` de `es.json`, `android:label` de `AndroidManifest.xml`, `CFBundleDisplayName` de `ios/Runner/Info.plist`, `<title>` y `apple-mobile-web-app-title` de `web/index.html`, `name` y `short_name` de `web/manifest.json`. `CFBundleName` pasa de `rpg` a `farming`.
- Descripción (`pubspec.yaml`, `web/index.html`, `web/manifest.json`): sin la palabra *RPG* (por ejemplo *"Top-down forest game: chop trees, build a village and train a hero for the arena."*).
- Ids `com.apergas.farming`:
  - Android: `namespace` y `applicationId` de `android/app/build.gradle.kts`, y `MainActivity.kt` movido a `kotlin/com/apergas/farming/` con su `package`.
  - iOS: `PRODUCT_BUNDLE_IDENTIFIER` de `Runner` (`com.apergas.farming`) y de `RunnerTests` (`com.apergas.farming.RunnerTests`) en `project.pbxproj`.
  - Consecuencia: en Android y en el simulador iOS se instala como una app **nueva**; la antigua `com.apergas.rpg` se desinstala a mano. No hay partidas guardadas que migrar (F2 todavía no existe).
- Paquete Dart `farming` (`name:` de `pubspec.yaml`). Los ~220 ficheros con `package:rpg/` (casi todos en `test/`, más los `*.mocks.dart` generados) pasan a `package:farming/`; los generados se regeneran con `build_runner`, nunca se editan a mano. `lib/` usa imports relativos (`prefer_relative_imports`), así que apenas cambia.
- La web sigue publicándose en `https://apergas.github.io/phaser-example/` (el `--base-href` depende del nombre del repositorio, no de la app).
- La palabra *RPG* no vuelve a aparecer en código, textos ni ajustes (regla de iOS). `CLAUDE.md` se actualiza: *Layout* (paquete `farming`, app `Farming`, ids `com.apergas.farming`) y *Constraints* (el nombre de la app es el único texto por plataforma).

**Icono y pantalla de arranque** (iOS M7):
- El icono de iOS sale del roble del atlas (`$IOS/scripts/build_app_icon.py`, que escribe `AppIcon-1024.png`). Se copia el script a `asset-packs/lpc/build_app_icon.py` (o se reutiliza la imagen de 1024 px) y se generan los iconos de las tres plataformas: `android/app/src/main/res/mipmap-*/ic_launcher.png`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/` y `web/icons/` + `web/favicon.png`. Si se usa `flutter_launcher_icons`, va como `dev_dependency` en su propio commit.
- Color de arranque `#0E150E` (el de iOS): `launch_background.xml` de Android (y su `values-night`), el `LaunchScreen` de iOS, y `background_color`/`theme_color` de `web/manifest.json`.
- El roble ya está acreditado en `CREDITS.md`; se añade una línea que dice que el icono sale de él (como en iOS).

**No reiniciar el golpe al volver a tocar la obra en curso** (nota de M3/M4 de iOS, ya hecho allí en `GameUseCase.resumeConstruction`):
- Hoy `ResumeConstructionUseCase` llama siempre a `World.orderResumeConstruction`, que vuelve a dar la orden y reinicia el temporizador del martillo: tocar varias veces seguidas (< 650 ms) la obra que se está construyendo la para.
- `ResumeConstructionUseCase` devuelve `ResumeConstructionResult.ok` **sin** llamar al mundo si `player.activity` ya es un trabajo de construcción sobre ese mismo edificio. Con otro edificio o con el jugador parado, como hasta ahora.
- Volver a tocar el árbol que se está talando **sí** reinicia el golpe (paridad con Dart, se mantiene en iOS).

**Textos táctiles** (iOS M5): Flutter sigue teniendo web con ratón, así que los textos que dicen cómo se interactúa tienen dos variantes y se elige según `_isTouchPlatform` (la misma regla que ya decide si sale la `PlacementBar`):

| Clave | Ratón (la de hoy) | Táctil (la de iOS) |
|---|---|---|
| `forest.message.pickedUpAxe` / `pickedUpAxeTouch` | ¡Hacha recogida! Haz clic en un árbol para talarlo. | ¡Hacha recogida! Toca un árbol para talarlo. |
| `forest.message.placing` / `placingTouch` | Elige dónde construir: {name}. Clic derecho o Esc para cancelar. | Elige dónde construir: {name}. Arrastra el dedo para moverlo y toca Construir aquí o Cancelar. |

- El BLoC no conoce la plataforma: `ForestBloc` recibe en su constructor si la entrada es táctil (`ForestPage` se lo pasa), y `Internationalize` ofrece los dos textos. Lo mismo valdrá para el pico de F5 (*"¡Pico recogido! Toca una roca para picarla."* / *"… Haz clic en una roca …"*).

**Lo que no se trae de iOS** (específico de Swift o de SpriteKit): D9 `ScenePoint` (Flame y el dominio ya son Y hacia abajo), D16/D20 (aislamiento de actores), D19 (símbolos del String Catalog; aquí sigue `Internationalize`), `RenderDepth.overlay` y sus empates de `Float` (F1 de iOS), `SpriteView(isPaused:)`, el `Navigator`/`Router` y el `fullScreenCover`. D17 (sin web) **no** aplica: Flutter mantiene web, Esc y clic derecho.

## Ficheros previstos

- `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/apergas/farming/MainActivity.kt` (movido), `android/app/src/main/res/**` (iconos y fondo de arranque), `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Assets.xcassets/**`, `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `web/index.html`, `web/manifest.json`, `web/icons/**`, `web/favicon.png`.
- `test/**` (`package:rpg/` → `package:farming/`) y `*.mocks.dart` regenerados.
- `lib/core/assets/i18n/translations/es.json`, `lib/core/assets/i18n/internationalize.dart`.
- `lib/layers/domain/use-cases/game/resume_construction_use_case.dart`.
- `lib/layers/presentation/features/forest/bloc/forest_bloc.dart`, `forest_page.dart`.
- `asset-packs/lpc/build_app_icon.py` (nuevo) y `lib/core/assets/images/lpc/CREDITS.md`.
- `CLAUDE.md`, y `.github/workflows/deploy.yml` si nombra el paquete.

## Cómo probarlo

- `flutter analyze` sin avisos, `flutter test` en verde, `build_runner` + `git diff --exit-code` limpio y `grep -rniI 'rpg' lib test android ios web pubspec.yaml` sin resultados (salvo `build/`).
- En Chrome, Android e iOS la app se llama *Farming* y lleva el icono del roble; el arranque es verde oscuro.
- En Android/iOS, recoger el hacha y empezar a colocar un edificio enseñan los textos táctiles; en Chrome, los de ratón.
- Tocar tres veces seguidas la obra que se está martilleando no la para.
- Tests:
  - `resume_construction_use_case_test.dart`: el mismo edificio que se martillea → `ok` y el temporizador sigue (el edificio termina en el mismo tick que sin el segundo toque); otro edificio y jugador parado, como antes.
  - `forest_bloc_test.dart`: con entrada táctil, los mensajes `pickedUpAxeTouch` / `placingTouch`; sin ella, los de siempre.
  - `internationalize_test.dart`: las dos claves nuevas.
