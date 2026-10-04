# Fase 1 — Proyecto Gradle y módulo `shared` (KMP)

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear en la raíz del repo un proyecto Gradle con un módulo Kotlin Multiplatform `shared` que compila y ejecuta tests en Android (JVM), JS (navegador) e iOS (simulador), sin tocar todavía la web ni su despliegue.

**Architecture:** Monorepo: Gradle en la raíz (`settings.gradle.kts`), `shared/` como único módulo de momento; `rpg/` (web) sigue igual. Versiones centralizadas en `gradle/libs.versions.toml`.

**Tech Stack:** Gradle (wrapper), Kotlin Multiplatform plugin, Android Gradle Plugin (library), kotlinx.coroutines, kotlinx.serialization, JetBrains lifecycle-viewmodel, SKIE, kotlin.test.

## Global Constraints

Las de [`README.md`](README.md#global-constraints), en especial: `compileSdk`/`targetSdk` 36; resto de versiones = última estable el día de esta fase, fijadas una vez en `libs.versions.toml`; package raíz `com.apergas.rpg`; commits `[PROJECT-X]: ...` sin atribución IA.

## File Structure

| Fichero | Responsabilidad |
|---|---|
| `settings.gradle.kts` | Repositorios y módulos (`:shared`) |
| `build.gradle.kts` | Plugins declarados `apply false` |
| `gradle.properties` | Flags de Kotlin/Android (`kotlin.code.style`, AndroidX, memoria) |
| `gradle/libs.versions.toml` | Única fuente de versiones |
| `gradle/wrapper/*`, `gradlew` | Gradle wrapper |
| `shared/build.gradle.kts` | Targets (android, iOS, JS), source sets, dependencias, SKIE, salida npm |
| `shared/src/commonMain/kotlin/com/apergas/rpg/util/Platform.kt` | Fichero mínimo para validar la cadena (se borra en la fase 2) |
| `shared/src/commonTest/kotlin/com/apergas/rpg/util/PlatformTests.kt` | Test que valida que commonTest corre en los tres targets |
| `.gitignore` | `build/`, `.gradle/`, `local.properties`, `.kotlin/` |

---

### Task 1: Gradle wrapper, catálogo de versiones y proyecto raíz

**Files:**
- Create: `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/libs.versions.toml`, `gradle/wrapper/` (vía comando)
- Modify: `.gitignore`

**Interfaces:**
- Produces: alias de plugins `kotlinMultiplatform`, `androidLibrary`, `androidApplication`, `kotlinSerialization`, `composeCompiler`, `skie`, `hilt`, `ksp`; alias de librerías `kotlinx-coroutines-core`, `kotlinx-coroutines-test`, `kotlinx-serialization-json`, `lifecycle-viewmodel` (usados por las fases siguientes).

- [ ] **Step 1: Comprobar requisitos locales**

Run: `java -version && xcodebuild -version`
Expected: JDK 17 o superior y Xcode instalado (necesario para compilar los targets iOS). Si falta el JDK: `brew install --cask temurin@21`.

- [ ] **Step 2: Averiguar las versiones estables de hoy y anotarlas**

Consultar y anotar (son las únicas versiones que se fijan en todo el proyecto):
- Kotlin: https://kotlinlang.org/docs/releases.html (última estable `2.x`).
- Android Gradle Plugin: https://developer.android.com/build/releases/gradle-plugin (última estable compatible con esa Kotlin).
- Gradle: la que pida esa AGP (tabla de compatibilidad de la misma página).
- kotlinx.coroutines, kotlinx.serialization: releases de GitHub de `Kotlin/kotlinx.coroutines` y `Kotlin/kotlinx.serialization`.
- `org.jetbrains.androidx.lifecycle:lifecycle-viewmodel`: https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-viewmodel.html (comprobar que lista los targets `js`/`wasmJs`).
- SKIE: https://skie.touchlab.co/ (versión compatible con la Kotlin elegida).
- Hilt, KSP, Compose BOM, Activity Compose: se usan en la fase 7, se fijan ya para no tocar el catálogo después.

- [ ] **Step 3: Crear el wrapper de Gradle**

Run (con Gradle instalado temporalmente vía `brew install gradle`, o desde otro proyecto):
```bash
cd /Users/axelperezgaspar/phaser-example
gradle wrapper --gradle-version <versión de Gradle del Step 2>
```
Expected: aparecen `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, `gradle/wrapper/gradle-wrapper.properties`.

- [ ] **Step 4: Escribir `gradle/libs.versions.toml`** sustituyendo cada versión por la anotada en el Step 2:

```toml
[versions]
kotlin = "<kotlin>"
agp = "<agp>"
coroutines = "<kotlinx.coroutines>"
serialization = "<kotlinx.serialization>"
lifecycle = "<jetbrains lifecycle-viewmodel>"
skie = "<skie>"
ksp = "<ksp para esa kotlin>"
hilt = "<hilt>"
composeBom = "<compose bom>"
activityCompose = "<androidx.activity:activity-compose>"
androidCompileSdk = "36"
androidTargetSdk = "36"
androidMinSdk = "26"

[libraries]
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }
kotlinx-serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "serialization" }
lifecycle-viewmodel = { module = "org.jetbrains.androidx.lifecycle:lifecycle-viewmodel", version.ref = "lifecycle" }
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "composeBom" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-foundation = { module = "androidx.compose.foundation:foundation" }
compose-material3 = { module = "androidx.compose.material3:material3" }
activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activityCompose" }
hilt-android = { module = "com.google.dagger:hilt-android", version.ref = "hilt" }
hilt-compiler = { module = "com.google.dagger:hilt-compiler", version.ref = "hilt" }

[plugins]
kotlinMultiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
kotlinAndroid = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlinSerialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
composeCompiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
androidLibrary = { id = "com.android.library", version.ref = "agp" }
androidApplication = { id = "com.android.application", version.ref = "agp" }
skie = { id = "co.touchlab.skie", version.ref = "skie" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

`androidMinSdk = 26`: Android 8, cubre >95 % de dispositivos y no requiere desugaring. Es la única versión que este plan elige; si el equipo tiene un mínimo distinto, usar el del equipo.

- [ ] **Step 5: Escribir `settings.gradle.kts`**

```kotlin
rootProject.name = "phaser-example"

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

include(":shared")
```

- [ ] **Step 6: Escribir `build.gradle.kts` (raíz)**

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.kotlinAndroid) apply false
    alias(libs.plugins.kotlinSerialization) apply false
    alias(libs.plugins.composeCompiler) apply false
    alias(libs.plugins.androidLibrary) apply false
    alias(libs.plugins.androidApplication) apply false
    alias(libs.plugins.skie) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.hilt) apply false
}
```

- [ ] **Step 7: Escribir `gradle.properties`**

```properties
org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8
org.gradle.caching=true
kotlin.code.style=official
android.useAndroidX=true
android.nonTransitiveRClass=true
```

- [ ] **Step 8: Añadir a `.gitignore` (raíz)**

```
.gradle/
build/
.kotlin/
local.properties
*.iml
.idea/
xcuserdata/
```

- [ ] **Step 9: Comprobar que Gradle arranca**

Run: `./gradlew help`
Expected: `BUILD SUCCESSFUL` (aún sin módulos con código, falla solo si `:shared` no existe: crear la carpeta vacía `shared/` antes si hace falta).

- [ ] **Step 10: Commit**

```bash
git add settings.gradle.kts build.gradle.kts gradle.properties gradle/ gradlew gradlew.bat .gitignore
git commit -m "[PROJECT-X]: Add Gradle root project and version catalog for Kotlin Multiplatform"
```

---

### Task 2: Módulo `shared` con targets Android, iOS y JS, y su primer test en los tres

**Files:**
- Create: `shared/build.gradle.kts`, `shared/src/commonMain/kotlin/com/apergas/rpg/util/Platform.kt`, `shared/src/commonTest/kotlin/com/apergas/rpg/util/PlatformTests.kt`

**Interfaces:**
- Consumes: alias del catálogo (Task 1).
- Produces: tareas Gradle `:shared:allTests`, `:shared:jvmTest`-equivalente `:shared:testDebugUnitTest`, `:shared:jsBrowserTest`, `:shared:iosSimulatorArm64Test`, `:shared:jsBrowserProductionLibraryDistribution` (paquete npm en `shared/build/dist/js/productionLibrary/`), framework iOS `Shared`.

- [ ] **Step 1: Escribir el test (falla porque no hay código)**

`shared/src/commonTest/kotlin/com/apergas/rpg/util/PlatformTests.kt`:
```kotlin
package com.apergas.rpg.util

import kotlin.test.Test
import kotlin.test.assertTrue

class PlatformTests {
    @Test
    fun testWhenSharedCodeRunsThenItIsTheSameOnEveryTarget() {
        // given
        val greeting = sharedGreeting()

        // when
        val isShared = greeting.startsWith("shared:")

        // then
        assertTrue(isShared)
    }
}
```

- [ ] **Step 2: Escribir `shared/build.gradle.kts`**

```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.kotlinSerialization)
    alias(libs.plugins.androidLibrary)
    alias(libs.plugins.skie)
}

kotlin {
    androidTarget {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }

    listOf(iosArm64(), iosSimulatorArm64()).forEach { target ->
        target.binaries.framework {
            baseName = "Shared"
            isStatic = true
        }
    }

    js(IR) {
        moduleName = "rpg-shared"
        browser {
            testTask { useKarma { useChromeHeadless() } }
        }
        binaries.library()
        generateTypeScriptDefinitions()
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.json)
            api(libs.lifecycle.viewmodel)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.kotlinx.coroutines.test)
        }
    }
}

android {
    namespace = "com.apergas.rpg.shared"
    compileSdk = libs.versions.androidCompileSdk.get().toInt()
    defaultConfig { minSdk = libs.versions.androidMinSdk.get().toInt() }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
```

Y añadir `include(":shared")` ya está en `settings.gradle.kts`.

- [ ] **Step 3: Ejecutar los tests y ver que fallan por compilación**

Run: `./gradlew :shared:testDebugUnitTest`
Expected: FAIL — `Unresolved reference: sharedGreeting`.

- [ ] **Step 4: Implementación mínima**

`shared/src/commonMain/kotlin/com/apergas/rpg/util/Platform.kt`:
```kotlin
package com.apergas.rpg.util

fun sharedGreeting(): String = "shared:rpg"
```

- [ ] **Step 5: Ejecutar en los tres targets**

Run: `./gradlew :shared:allTests`
Expected: `BUILD SUCCESSFUL`; el informe `shared/build/reports/tests/allTests/index.html` muestra el test en `testDebugUnitTest` (JVM), `jsBrowserTest` e `iosSimulatorArm64Test`.

Si `jsBrowserTest` no encuentra Chrome: `export CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`.

Si la resolución de `lifecycle-viewmodel` falla **solo para JS** (variante `js` inexistente en la versión elegida): mover esa dependencia de `commonMain` a `androidMain` + `iosMain` y anotarlo en el README del plan; la fase 5 usa entonces la alternativa descrita allí (`ForestViewModel` sin superclase).

- [ ] **Step 6: Comprobar los artefactos de salida**

Run: `./gradlew :shared:jsBrowserProductionLibraryDistribution :shared:linkDebugFrameworkIosSimulatorArm64 && ls shared/build/dist/js/productionLibrary && ls shared/build/bin/iosSimulatorArm64/debugFramework`
Expected: `package.json`, `rpg-shared.js`, `rpg-shared.d.ts` en el primero; `Shared.framework` en el segundo.

- [ ] **Step 7: Commit**

```bash
git add shared/
git commit -m "[PROJECT-X]: Add Kotlin Multiplatform shared module with Android, iOS and JS targets"
```

---

### Task 3: Comprobar que el despliegue web no se ve afectado

En esta fase no se crea CI nueva: los tests de `shared` se ejecutan en local (`./gradlew :shared:allTests`). El despliegue de la web (`deploy.yml`) no cambia hasta la fase 6.

- [ ] **Step 1: Push y verificación**

Run: `git push && gh run watch --exit-status`
Expected: `Deploy to GitHub Pages` en verde (sigue construyendo solo `rpg/`); la web publicada no cambia.

---

## Self-review de la fase

- [ ] `./gradlew :shared:allTests` verde en local.
- [ ] Ningún fichero de `rpg/` modificado.
- [ ] `libs.versions.toml` es el único sitio con números de versión.
