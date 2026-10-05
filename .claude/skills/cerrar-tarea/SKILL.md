---
name: cerrar-tarea
description: Use when a task of the gameplay roadmap (docs/boost/plans/2026-10-04-game-design) is implemented, to verify it, update the plan, open the PR and update the GitHub tracker. Triggers on "cerrar tarea", "he terminado", "abre el PR", "finish task".
---

# Cerrar tarea

Protocolo de cierre común para los dos desarrolladores. No des una tarea por terminada sin pruebas: aplica `boost:verification-before-completion`.

## 1. Verificar

Ejecuta la batería completa. Es una sola app, así que siempre se ejecuta entera.

```bash
dart format --line-length 120 <ficheros escritos en la tarea>      # nunca di.config.dart ni *.mocks.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test
flutter analyze                                                     # debe terminar en "No issues found!"
flutter test
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

- Si `build_runner` cambia ficheros generados, haz commit de ellos tal cual y vuelve a ejecutar la batería.
- Si algo falla, **para**. Usa `boost:systematic-debugging` y no abras el PR.

## 2. Prueba manual

Lee el apartado *Cómo probarlo* de la tarea, o de la fase si es la última tarea, y:
- Web: pruébalo tú con `flutter run -d chrome` y las herramientas de Chrome si están disponibles. El juego se pinta en un canvas: valida con capturas, no con el DOM.
- Android (`flutter run -d emulator-5554`, AVD `Medium_Phone_API_36.0`) e iOS (`flutter run -d "iPhone 17"`): pide al usuario que lo pruebe en el emulador o simulador y espera su confirmación.
- Si algo no se ha podido probar en alguna plataforma, dilo y déjalo como pendiente en el PR. No lo des por bueno.

## 3. Actualizar el plan

- Marca los checkboxes de la tarea en `docs/boost/plans/2026-10-04-game-design/F<n>-*.md`.
- Si algo se hizo distinto de lo planeado (firmas, nombres, arte, números), añade una línea en la sección 5 *Desviaciones registradas* del README. Indica fase y tarea, qué cambió y por qué.
- Si es la última tarea de la fase, cambia su icono en la tabla de fases del README a ✅.
- Si la tarea cambia una excepción documentada (E1–E11) o la estructura descrita en `CLAUDE.md`, actualízalo y añádelo con un `git add CLAUDE.md` aparte.

Haz el commit junto al código: `[PROJECT-X]: <imperative description>`, en un comando `git commit` independiente. **Sin ninguna atribución a IA**: el hook lo rechaza. Comprueba con `git log -1` que el commit existe.

## 4. PR y tracker

Confirma con el usuario antes de hacer *push* y abrir el PR.

```bash
git fetch origin && git rebase origin/develop
git push -u origin HEAD
gh pr create --repo apergas/phaser-example --base develop --title "[PROJECT-X]: <title>" --body "<resumen>

Cómo probarlo:
<pasos de la tarea>

Closes #<n>"
gh issue comment <n> --repo apergas/phaser-example --body "PR abierto: <url>. Verificado: <comandos en verde y plataformas probadas>. Pendiente: <si algo quedó sin verificar>"
```

- **Conflicto de rebase en `lib/core/assets/images/lpc/forest.{png,json}`:** toma la versión de `develop`, ejecuta `cd asset-packs/lpc && python3 build_assets.py` y añade el resultado.
- **Conflicto en `di.config.dart` o en un `*.mocks.dart`:** toma cualquiera de las dos versiones, ejecuta `dart run build_runner build --delete-conflicting-outputs` y añade el resultado.
- Tras resolver un conflicto, vuelve a ejecutar la batería del paso 1.
- Si existe el Project, mueve la tarjeta a *Review*.

## 5. Informar

Resume al usuario:
- qué se ha hecho;
- qué se ha verificado, y cómo (comandos y plataformas);
- qué queda pendiente;
- cuál es la siguiente tarea desbloqueada (tabla de fases).
