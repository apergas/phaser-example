---
name: cerrar-tarea
description: Use when a task of the gameplay roadmap (docs/boost/plans/2026-10-04-game-design) is implemented, to verify it on every platform, update the plan, open the PR and update the GitHub tracker. Triggers on "cerrar tarea", "he terminado", "abre el PR", "finish task".
---

# Cerrar tarea

Protocolo de cierre común para los dos desarrolladores. No des una tarea por terminada sin pruebas: aplica `boost:verification-before-completion`.

## 1. Verificar

Ejecuta la batería que corresponde a lo que ha tocado la tarea. Si la tarea toca `shared`, ejecútala entera, porque las tres apps dependen de `shared`.

```bash
./gradlew :shared:allTests
./gradlew :shared:jsBrowserProductionLibraryDistribution
(cd webApp && npm ci && npm run typecheck && npm test && npm run build)
./gradlew :androidApp:testDebugUnitTest :androidApp:assembleDebug
xcodebuild test -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

- `connectedDebugAndroidTest` sólo se ejecuta si hay un emulador arrancado. Si no lo hay, dilo.
- En una máquina sin Xcode, dilo y deja la verificación de iOS como pendiente en el PR. No la des por buena.
- Si algo falla, **para**. Usa `boost:systematic-debugging` y no abras el PR.

## 2. Prueba manual

Lee el apartado *Cómo probarlo* de la tarea, o de la fase si es la última tarea, y:
- Web: si puedes, pruébalo con `npm run dev`. En desarrollo existe `window.__rpg`, útil para automatizar con Chrome.
- Android e iOS: pide al usuario que lo pruebe en el emulador o simulador y espera su confirmación.

## 3. Actualizar el plan

- Marca los checkboxes de la tarea en `docs/boost/plans/2026-10-04-game-design/F<n>-*.md`.
- Si algo se hizo distinto de lo planeado (firmas, nombres, arte, números), añade una línea en la sección 5 *Desviaciones registradas* del README. Indica fase y tarea, qué cambió y por qué.
- Si es la última tarea de la fase, cambia su icono en la tabla de fases del README a ✅.

Haz el commit junto al código: `[PROJECT-X]: <imperative description>`. **Sin ninguna atribución a IA**: el hook lo rechaza.

## 4. PR y tracker

Confirma con el usuario antes de hacer *push* y abrir el PR.

```bash
git fetch origin && git rebase origin/develop
git push -u origin HEAD
gh pr create --repo apergas/phaser-example --base develop --title "[PROJECT-X]: <title>" --body "<resumen>

Cómo probarlo:
<pasos de la tarea>

Closes #<n>"
gh issue comment <n> --repo apergas/phaser-example --body "PR abierto: <url>. Verificado: <comandos en verde>. Pendiente: <si algo quedó sin verificar>"
```

- **Conflicto de rebase en `shared/assets/lpc/forest.{png,json}`:** toma la versión de `develop`, ejecuta `cd asset-packs/lpc && python3 build_assets.py` y añade el resultado.
- Si existe el Project, mueve la tarjeta a *Review*.

## 5. Informar

Resume al usuario:
- qué se ha hecho;
- qué se ha verificado, y cómo;
- qué queda pendiente;
- cuál es la siguiente tarea desbloqueada (tabla de fases).
