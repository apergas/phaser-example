---
name: cerrar-tarea
description: Use when a task of the gameplay roadmaps (docs/boost/plans/2026-10-04-game-design or docs/boost/plans/2026-10-06-hero-arena) is implemented, to verify it, update the plan, open the PR and update the GitHub tracker. Triggers on "cerrar tarea", "he terminado", "abre el PR", "finish task".
---

# Cerrar tarea

Protocolo de cierre común para los dos desarrolladores. No des una tarea por terminada sin pruebas: aplica `boost:verification-before-completion`.

## 1. Verificar

Ejecuta la batería completa. Es una sola app, así que siempre se ejecuta entera.

```bash
dart format --line-length 120 <ficheros escritos en la tarea>      # nunca di.config.dart ni *.mocks.dart
dart run build_runner build --delete-conflicting-outputs && git diff --exit-code -- lib/core/config/di/di.config.dart test
flutter analyze                                                     # debe terminar en "No issues found!"
flutter test                                                        # todo en verde
flutter test --platform chrome test/core/utils test/layers/data test/core/config/di/di_test.dart
```

- Si `build_runner` cambia ficheros generados, haz commit de ellos tal cual y vuelve a ejecutar la batería.
- Si algo falla, **para**. Usa `boost:systematic-debugging` y no abras el PR.

## 2. Prueba manual

**Desde el 2026-10-17 no se prueba a mano en cada fase** (ni web ni Android): se hace una prueba manual por bloque, al terminar C12 (la arena) y al terminar las F (la aldea), con los apartados *Prueba manual* / *Cómo probarlo* de todas sus fases. En una fase, sáltate este paso y pon en el PR «Prueba manual: en el cierre del bloque». En la prueba de bloque:

Lee el apartado *Cómo probarlo* de la tarea, o de la fase si es la última tarea, y:
- Web: pruébalo tú con `flutter run -d chrome` y las herramientas de Chrome si están disponibles. El juego se pinta en un canvas: valida con capturas, no con el DOM.
- Android (`flutter run -d emulator-5554`, AVD `Medium_Phone_API_36.0`) e iOS (`flutter run -d "iPhone 17"`): pide al usuario que lo pruebe en el emulador o simulador y espera su confirmación.
- Si algo no se ha podido probar en alguna plataforma, dilo y déjalo como pendiente en el PR. No lo des por bueno.

## 3. Actualizar el plan

- Marca los checkboxes de la tarea en `docs/boost/plans/2026-10-04-game-design/F<n>-*.md` o `docs/boost/plans/2026-10-06-hero-arena/C<n>-*.md`.
- Si la tarea resolvió un cruce entre los dos planes (sección 6 del README de la aldea, sección 3.2 del de la arena), dilo en el PR.
- Si algo se hizo distinto de lo planeado (firmas, nombres, arte, números), añade una línea en la sección 5 *Desviaciones registradas* del README. Indica fase y tarea, qué cambió y por qué.
- Actualiza la fila de la fase en `docs/boost/plans/PROGRESS.md` con la tarea terminada (estado, dónde está, notas y fecha de última actualización) y su apartado *Siguiente paso*. Si es la última tarea de la fase, cambia además su icono a ✅, aquí y en la tabla de fases del README.
- Si la tarea cambia una excepción documentada (E1–E11) o la estructura descrita en `CLAUDE.md`, actualízalo y añádelo con un `git add CLAUDE.md` aparte.

Todo esto (plan, README y `PROGRESS.md`) va en **la misma rama de la tarea**, en un commit propio (por ejemplo `[PROJECT-C6]: Update the roadmap progress after TC6.1`): no hay rama ni PR aparte para la documentación. Mensaje `[PROJECT-<fase>]: <imperative description>` (`[PROJECT-C6]`, `[PROJECT-F1]`; `[PROJECT-C4-C5]` si abarca dos fases), sin repetir el código en la descripción, en un comando `git commit` independiente. **Sin ninguna atribución a IA**: el hook lo rechaza. Comprueba con `git log -1` que el commit existe.

## 4. PR y tracker

No esperes a que el usuario apruebe el PR: tras abrirlo, únelo tú en local a `develop` con `--no-ff` y haz *push* (paso 5).

```bash
git fetch origin && git merge origin/develop
git push -u origin HEAD
gh pr create --repo apergas/phaser-example --base develop --title "[PROJECT-<fase>]: <title>" --body "<resumen>

Cómo probarlo:
<pasos de la tarea>

Closes #<n>"
gh issue comment <n> --repo apergas/phaser-example --body "PR abierto: <url>. Verificado: <comandos en verde y plataformas probadas>. Pendiente: <si algo quedó sin verificar>"
```

- **Conflicto al unir ramas en `lib/core/assets/images/lpc/forest.{png,json}` o `arena.{png,json}`:** toma la versión de `develop`, ejecuta `cd asset-packs/lpc && python3 build_assets.py` y añade el resultado.
- **Conflicto en `di.config.dart` o en un `*.mocks.dart`:** toma cualquiera de las dos versiones, ejecuta `dart run build_runner build --delete-conflicting-outputs` y añade el resultado.
- **Destino:** toda PR va a `develop`; ya no hay ramas de integración (desde el 2026-10-18). El paso de `develop` a `main` lo hace solo el usuario.
- **Documentación** (planes, README, `PROGRESS.md`): viaja con el código, en la rama de la tarea y en su mismo PR. Llega a `develop` con ella.
- Tras resolver un conflicto, vuelve a ejecutar la batería del paso 1.
- Si existe el Project, mueve la tarjeta a *Review*.

## 5. Informar

Resume al usuario:
- qué se ha hecho;
- qué se ha verificado, y cómo (comandos y plataformas);
- qué queda pendiente;
- cuál es la siguiente tarea desbloqueada (tabla de fases).

## 5. Después de unir el PR

- Une la rama: `git switch develop && git pull --ff-only && git merge --no-ff <rama> -m "[PROJECT-<fase>]: Merge <rama>" && git push`. Cierra la issue y mueve la tarjeta a *Done*.
- Borra la rama de la tarea en local (`git branch -d <rama>`, tras `git fetch --prune`). Si queda la remota, `git push origin --delete <rama>`. Nunca borres `main` ni `develop`.
- Borra también los worktrees de esa tarea (`git worktree remove`).
