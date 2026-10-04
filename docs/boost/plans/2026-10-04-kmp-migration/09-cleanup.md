# Fase 9 — Cierre: estructura final, reglas de arquitectura y documentación

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar el monorepo con su forma definitiva (`shared/`, `androidApp/`, `iosApp/`, `webApp/`), con las reglas de dependencias del código Kotlin comprobadas por un test y la documentación al día.

**Architecture:** `rpg/` pasa a `webApp/`. Las reglas de capas de `shared` las comprueba un test JVM (`androidUnitTest`) que lee los `import` de `commonMain`, equivalente al `architecture.test.ts` que tenía la web.

**Tech Stack:** Gradle, Kotlin JVM test (java.io.File), GitHub Actions, Markdown.

## Global Constraints

Las de [`README.md`](README.md#global-constraints). La web sigue desplegando en la misma URL de GitHub Pages.

---

### Task 1: Test de arquitectura de `shared`

**Files:**
- Create: `shared/src/androidUnitTest/kotlin/com/apergas/rpg/ArchitectureTests.kt`

**Interfaces:**
- Consumes: estructura de paquetes de fases 2–5.

- [ ] **Step 1: Escribir el test**

```kotlin
package com.apergas.rpg

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals

class ArchitectureTests {
    private val root = File("src/commonMain/kotlin/com/apergas/rpg")

    private fun importsUnder(folder: String): List<Pair<String, String>> =
        File(root, folder).walkTopDown().filter { it.extension == "kt" }.flatMap { file ->
            file.readLines().filter { it.startsWith("import ") }.map { file.relativeTo(root).path to it.removePrefix("import ").trim() }
        }.toList()

    private fun violations(folder: String, forbidden: Regex): List<String> =
        importsUnder(folder).filter { (_, import) -> forbidden.containsMatchIn(import) }.map { (file, import) -> "$file -> $import" }

    @Test
    fun testWhenCheckingDomainThenItImportsNothingFromDataPresentationOrPlatforms() {
        // given
        val forbidden = Regex("""^com\.apergas\.rpg\.(data|presentation|di)\.|^android\.|^platform\.|^kotlin\.js\.""")

        // when
        val found = violations("domain", forbidden)

        // then
        assertEquals(emptyList(), found)
    }

    @Test
    fun testWhenCheckingDataThenItNeverImportsPresentation() {
        // given
        val forbidden = Regex("""^com\.apergas\.rpg\.(presentation|di)\.""")

        // when
        val found = violations("data", forbidden)

        // then
        assertEquals(emptyList(), found)
    }

    @Test
    fun testWhenCheckingPresentationThenItNeverImportsData() {
        // given
        val forbidden = Regex("""^com\.apergas\.rpg\.data\.""")

        // when
        val found = violations("presentation", forbidden)

        // then
        assertEquals(emptyList(), found)
    }

    @Test
    fun testWhenCheckingEntitiesThenTheyAreImmutable() {
        // given
        val entityFiles = File(root, "domain/entities").walkTopDown().filter { it.extension == "kt" }

        // when
        val mutable = entityFiles.filter { file -> file.readLines().any { it.trimStart().startsWith("var ") || it.contains(" var ") } }
            .map { it.relativeTo(root).path }.toList()

        // then
        assertEquals(emptyList(), mutable)
    }
}
```

- [ ] **Step 2: Ejecutar**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.ArchitectureTests"`
Expected: PASS. Comprobar que detecta violaciones: añadir temporalmente `import com.apergas.rpg.data.errors.DataErrorHandlerImpl` en `domain/rules/Rules.kt`, ver FAIL con `domain/rules/Rules.kt -> com.apergas.rpg.data.errors.DataErrorHandlerImpl`, y quitarlo.

- [ ] **Step 3: Commit**

```bash
git add shared/src/androidUnitTest
git commit -m "[PROJECT-X]: Enforce shared module layer rules with an architecture test"
```

---

### Task 2: `rpg/` → `webApp/`

**Files:**
- Move: `rpg/` → `webApp/`
- Modify: `.github/workflows/deploy.yml`, `asset-packs/lpc/build_assets.py`, `webApp/package.json` (ruta del paquete compartido no cambia: `file:../shared/...`), `.vscode/settings.json`

- [ ] **Step 1: Mover**

```bash
git mv rpg webApp
```

- [ ] **Step 2: Actualizar rutas**

- `.github/workflows/deploy.yml`: en `on.push.paths`, `'rpg/**'` → `'webApp/**'`; los cuatro `working-directory: rpg` → `webApp`; `cache-dependency-path: rpg/package-lock.json` → `webApp/package-lock.json`; `path: rpg/dist` → `webApp/dist`.
- `asset-packs/lpc/build_assets.py`: `OUT = ROOT.parent.parent / "rpg" / ...` → `"webApp"`.
- `.vscode/settings.json` (raíz): `"typescript.tsdk": "webApp/node_modules/typescript/lib"`.

Run: `grep -rn "rpg/" .github asset-packs/lpc/build_assets.py .vscode webApp/package.json`
Expected: ninguna ruta a `rpg/` (las referencias al paquete npm `rpg-shared` son correctas).

- [ ] **Step 3: Verificar todo**

Run:
```bash
./gradlew :shared:allTests :androidApp:assembleDebug
cd webApp && npm ci && npm run typecheck && npm test && npm run build
```
Expected: todo verde.

- [ ] **Step 4: Commit y despliegue**

```bash
git add -A
git commit -m "[PROJECT-X]: Rename the web app folder to webApp"
git push && gh run watch --exit-status
```
Expected: despliegue correcto; la URL de GitHub Pages sigue sirviendo el juego.

---

### Task 3: Documentación

**Files:**
- Modify: `README.md`, `CLAUDE.md` (añadir en un comando aparte del commit, ver nota del hook en la memoria del proyecto)

- [ ] **Step 1: `README.md`** — sustituir la sección de estructura por:

```
shared/       Kotlin Multiplatform: domain, data, presentation (ForestViewModel), di (GameContainer)
androidApp/   Jetpack Compose + Hilt: only views
iosApp/       SwiftUI + SpriteKit: only views (Xcode project)
webApp/       Vite + Phaser 4: only views; consumes shared as the npm package rpg-shared
asset-packs/  LPC art sources and build_assets.py (feeds the three apps)
```
y la sección de comandos por:
```sh
./gradlew :shared:allTests                          # shared tests on JVM, JS and iOS simulator
./gradlew :shared:jsBrowserProductionLibraryDistribution   # npm package for webApp
./gradlew :androidApp:installDebug                  # Android app on a running emulator
open iosApp/iosApp.xcodeproj                        # iOS app (Run builds the framework via Gradle)
cd webApp && npm install && npm run dev             # web app (build the npm package first)
```

- [ ] **Step 2: `CLAUDE.md`** — reescribir las secciones *Layout*, *Commands* y *Architecture* con: la estructura anterior; que las reglas viven en `shared` (Kotlin, convención de Android) y las apps solo pintan; `GameUseCase` único; `ForestViewModel` MVI compartido (intents síncronos, efectos con `tryEmit`); `GameContainer` como contenedor; SKIE en iOS; `ForestWebController` como única API exportada a la web; las reglas de arquitectura comprobadas por `ArchitectureTests.kt` (Kotlin) y `webApp/tests/architecture.test.ts` (web); y el pipeline de assets que copia a las tres apps.

- [ ] **Step 3: Commit**

```bash
git add README.md
git add CLAUDE.md
git commit -m "[PROJECT-X]: Document the Kotlin Multiplatform architecture"
git push
```

---

## Self-review de la fase y de la migración completa

- [ ] En local: `./gradlew :shared:allTests` verde; tests de `androidApp` (emulador) e `iosApp` (simulador) verdes; `webApp` typecheck/test/build verdes. En GitHub: despliegue a Pages verde.
- [ ] Las tres apps juegan la partida de referencia: mismo bosque, hacha, 3 árboles → ≥15 madera, casa, 3/3 misiones.
- [ ] Ni rastro de reglas de juego fuera de `shared`: `grep -rln "CHOP_INTERVAL\|woodCost\|HITS_TO_FELL" webApp/src androidApp/src iosApp` vacío.
