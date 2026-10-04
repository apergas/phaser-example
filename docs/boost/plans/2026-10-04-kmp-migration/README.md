# Migración a Kotlin Multiplatform — Plan maestro

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement each phase plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Execute the phase documents **in order**; each one leaves the project working and green.

**Goal:** Sacar el núcleo del juego (dominio, datos, casos de uso y ViewModels) de TypeScript a un módulo Kotlin Multiplatform compartido, y tener tres frontales que lo consumen: web (Phaser, el actual), Android (Jetpack Compose) e iOS (SwiftUI + SpriteKit).

**Architecture:** Un módulo Gradle `shared` (KMP) con las capas `domain` / `data` / `presentation` siguiendo las convenciones de equipo de Android (que ya es Kotlin) y, donde la plataforma lo pide, las de iOS. Cada app solo implementa sus vistas: la web conserva Phaser + HUD HTML y consume `shared` como paquete npm generado por Kotlin/JS; Android pinta con Compose `Canvas`; iOS con SpriteKit dentro de SwiftUI.

**Tech Stack:** Kotlin Multiplatform (targets `androidTarget`, `iosArm64`, `iosSimulatorArm64`, `js(IR)` browser), kotlinx.coroutines (StateFlow/SharedFlow), kotlinx.serialization (atlas JSON), `org.jetbrains.androidx.lifecycle:lifecycle-viewmodel` (ViewModel KMP), SKIE (Swift interop), Jetpack Compose + Hilt (Android), SwiftUI + SpriteKit (iOS), Vite + Phaser 4 (web), kotlin.test.

## Global Constraints

- Dependency rule (Android `00-overview.md`): `Presentation ──▶ Domain ◀── Data`. `domain` imports nothing from `data` or `presentation`; `presentation` imports nothing from `data`. Pure Kotlin in `commonMain`: no Android, no iOS, no JS APIs.
- Naming (Android `10-structure-naming.md`): entity `<Name>`, DTO `<Name>Dto`, repository interface `<Name>Repository` + impl `<Name>RepositoryImpl`, use case interface `<Feature>UseCase` + impl `<Feature>UseCaseImpl`, local datasource `<Name>LocalDataSource` + `<Name>LocalDataSourceImpl`, mappers file `<Feature>Mappers.kt` **next to** the `RepositoryImpl`, MVI `<Feature>Contract.kt` with `<Feature>State` / `<Feature>Intent` / `<Feature>Effect`, `<Feature>ViewModel`, `<Feature>Screen` (Compose), `<Feature>View` + `<Feature>ViewModel` + `<Feature>Builder` (SwiftUI).
- Interface and implementation **side by side**, no `impl/` folders. Folders in `domain/` and `data/` are plural (`entities`, `repositories`, `usecases`, `datasources`).
- One use case interface per feature with all its operations (Android `20-domain.md`, iOS anti-pattern #5). Here: `GameUseCase` / `GameUseCaseImpl`.
- Entities are immutable `data class`es (Android `20-domain.md`). The stateful game simulation is the `World` **aggregate**, which lives in `domain/world/`, not in `entities/`.
- DTOs never leave `data/`; all DTO fields nullable, defaults applied in the mapper (Android `30-data.md`). Mappers are `internal` extension functions `toDomain()`.
- Errors are controlled `AppError` types; repositories wrap datasource calls and rethrow `errorHandler.handle(error)` (Android `50-error-handling.md`).
- Tests (iOS + Android): mirror the source tree; every test has `// given`, `// when`, `// then`; names `testWhen<Action>Then<Result>` without underscores; mock data as `val <Entity>.Companion.mock` (the Kotlin equivalent of `static let mock`), never `var`; hand-written mocks with an `error` property and `<method>Called` flags; never assert against mock properties, use literals; never mock the component under test.
- Code, identifiers and comments in English. Player-facing text in Spanish lives only in `ForestLabels`.
- Android: `compileSdk` / `targetSdk` 36 (the only version the team plugin pins). Every other version: newest stable on the day Phase 1 runs, recorded once in `gradle/libs.versions.toml` and never changed afterwards without a dedicated commit.
- Commits: format required by the team hook — `[PROJECT-123]: Imperative description` (or `[PROJECT-X]: ...`), no AI attribution of any kind. Branches `feature/PROJECT-123-description`.
- The web game must keep working and deploying to GitHub Pages at the end of every phase.

---

## 1. Dónde estamos y dónde queremos llegar

### Hoy (TypeScript, `rpg/`)

```
rpg/src/
  domain/        entities, world (aggregate + systems), quests, repositories, usecases (+ models)
  data/          datasources, dtos, mappers, repositories
  presentation/  screens/forest (ForestScene + ForestViewModel, hud/, player/, world/), screens/preload, common/
```

64 tests (Vitest) cubren dominio, datos, casos de uso, ViewModels y reglas de arquitectura.

### Destino

```
phaser-example/
  settings.gradle.kts           build.gradle.kts            gradle/libs.versions.toml
  shared/                       ← Kotlin Multiplatform: TODA la lógica
    src/commonMain/kotlin/com/apergas/rpg/
      domain/                   entities, world, quests, rules, errors, repositories, usecases
      data/                     datasources (+ dto), repositories (+ Mappers), errors
      presentation/forest/      ForestContract, ForestViewModel, ForestLabels
      util/                     SeededRandom
      di/                       GameContainer
    src/commonTest/kotlin/...   tests (espejo de commonMain), se ejecutan en JVM, JS e iOS
    src/jsMain/kotlin/.../web/  ForestWebController (+ tipos exportados a TypeScript)
  androidApp/                   Compose + Hilt: solo vistas
  iosApp/                       SwiftUI + SpriteKit: solo vistas (Xcode)
  webApp/                       (hoy rpg/) Vite + Phaser: solo vistas, consume shared como paquete npm
  asset-packs/lpc/              build_assets.py genera los assets de las tres apps
```

Lo que **cada plataforma escribe** se reduce a pintar: mundo (sprites, animaciones, cámara), HUD y entrada. Todo lo demás —reglas, generación del nivel, misiones, qué significa un clic, qué mensaje mostrar, qué efecto reproducir— está en `shared` una sola vez.

---

## 2. Decisiones de arquitectura

### D1. Convenciones: las de Android para `shared`, las de cada plataforma en su app

`shared` es Kotlin, así que sigue la skill de Android (estructura, nombres, MVI). Las apps siguen la suya: `androidApp` la de Android (Compose, Hilt, `Screen`), `iosApp` la de iOS (`View` + `ViewModel` + `Builder` + `Container`, `@Observable`). La web conserva su estructura actual de vistas.

| Concepto | `shared` (Kotlin) | Android app | iOS app | Web |
|---|---|---|---|---|
| Entidad | `Tree` (data class) | usa la de shared | usa la de shared (vía SKIE) | tipo exportado |
| Repositorio | `LevelRepository` + `LevelRepositoryImpl` | — | — | — |
| Caso de uso | `GameUseCase` + `GameUseCaseImpl` | — | — | — |
| Contenedor DI | `GameContainer` (factorías, estilo iOS `Container`) | Hilt `@Provides` que delega en `GameContainer` | `ForestBuilder` llama a `GameContainer` | `main.ts` llama al controller |
| ViewModel | `ForestViewModel` (MVI: `uiState` / `uiEffect` / `onIntent`) | lo usa directamente | `ForestViewModel` Swift `@Observable` que envuelve al compartido | `ForestWebController` (jsMain) |
| Vista | — | `ForestScreen` (Compose) | `ForestView` (SwiftUI) + `ForestScene` (SpriteKit) | `ForestScene` (Phaser) + `Hud` (DOM) |

### D2. Entidades inmutables; los ViewModels usan entidades (como en vuestras apps)

En TypeScript los ViewModels recibían *read models* porque las entidades eran objetos mutables. En Kotlin las entidades pasan a ser `data class` inmutables (regla de Android): `Tree.hit()` devuelve un `Tree` nuevo, `Inventory.addWood()` devuelve un `Inventory` nuevo. Al ser instantáneas inmutables, **los casos de uso devuelven entidades y los ViewModels las usan directamente**, igual que en iOS/Android. Los antiguos `PlayerState`, `WorldSnapshot`, `QuestProgress`, `BuildOption` pasan a ser entidades de dominio (`domain/entities/game/`). Desaparecen las "keys" duplicadas y sus mappers: `BlueprintId`, `ToolKind`, `QuestId` son `enum class` de dominio que todos usan.

El único objeto mutable es el agregado `World` (y `QuestLog`), que nunca sale del dominio: el repositorio de sesión lo guarda y los casos de uso lo operan.

### D3. Un caso de uso por feature

La convención de equipo es una interfaz por feature con todas sus operaciones. Los seis casos de uso actuales (`StartGame`, `MovePlayerTo`, `ChopTree`, `ConstructBuilding`, `AdvanceWorld`, `GetGameState`) se funden en `GameUseCase`:

```kotlin
interface GameUseCase {
    fun startGame()
    fun movePlayerTo(x: Double, y: Double)
    fun chopTree(treeId: String): ChopResult
    fun canPlaceBuilding(blueprint: BlueprintId, x: Double, y: Double): Boolean
    fun constructBuilding(blueprint: BlueprintId, x: Double, y: Double): ConstructionResult
    fun advance(deltaMs: Double): List<GameEvent>
    fun playerStatus(): PlayerStatus
    fun worldSnapshot(): WorldSnapshot
    fun buildOptions(): List<BuildOption>
    fun quests(): List<QuestProgress>
}
```

Son funciones síncronas (no `suspend`): la simulación avanza por fotogramas en el hilo de UI y no hay E/S. Cuando haya guardado de partida en disco, `saveGame`/`loadGame` serán `suspend` y vivirán en otra feature (`SaveGameUseCase`).

### D4. MVI compartido con bucle de juego síncrono

`ForestViewModel` sigue el contrato MVI de Android (`ForestContract.kt` con `ForestState`, `ForestIntent`, `ForestEffect`; `uiState: StateFlow`, `uiEffect: SharedFlow`, `onIntent()`), con dos desviaciones justificadas y documentadas en el código:

1. `ForestIntent.Tick(deltaMs)` se procesa **síncronamente** en el hilo que pinta (no `viewModelScope.launch(Dispatchers.IO)`): la simulación debe avanzar en orden de fotograma y es CPU-ligera.
2. Los efectos se emiten con `tryEmit` sobre un `MutableSharedFlow(extraBufferCapacity = 64)` en vez de `emit()` (que es `suspend`), por la misma razón.

`ForestViewModel` extiende el `ViewModel` multiplataforma de JetBrains (`org.jetbrains.androidx.lifecycle:lifecycle-viewmodel`), que en Android es el `androidx.lifecycle.ViewModel` real. No lleva `@HiltViewModel` (anotación solo-Android): Android lo crea con una factoría que pide el `GameUseCase` a Hilt (ver `07-android.md`).

### D5. DI sin librería: `GameContainer`

Hilt no existe en `commonMain`, y Koin añadiría una dependencia que ninguna convención del equipo usa. Se adopta el patrón `Container` de iOS (factorías estáticas que montan DataSource → Repository → UseCase) en `shared/di/GameContainer.kt`. Android lo envuelve en un módulo Hilt en `app/di/` (composition root, como manda su convención); iOS lo llama desde el `Builder`; la web desde el controller. Una sola definición del grafo para las tres.

### D6. Web: paquete npm generado por Kotlin/JS + fachada `@JsExport`

Kotlin/JS con `binaries.library()` y `generateTypeScriptDefinitions()` produce un paquete con `.d.ts`. Los `StateFlow`, `List` y `enum` de Kotlin no son cómodos desde TypeScript, así que `jsMain` expone una fachada `ForestWebController` con tipos planos (`Array`, `String`, `Double`) y efectos que se recogen por fotograma (`takeEffects()`). La web elimina su `domain/`, `data/` y sus ViewModels TypeScript; `ForestScene` y `Hud` pasan a hablar con el controller.

### D7. iOS: SKIE

Sin ayuda, Swift ve `StateFlow` como un objeto opaco y las `sealed interface` como clases sueltas. SKIE (`co.touchlab.skie`) convierte `Flow` en `AsyncSequence` y genera `onEnum(of:)` para hacer `switch` exhaustivo sobre sealed. El ViewModel Swift `@Observable` se suscribe a `uiState` con `for await` y la vista SwiftUI lo observa como cualquier otro ViewModel del equipo.

### D8. Assets: un único pipeline

`asset-packs/lpc/build_assets.py` sigue siendo la única fuente. Genera los mismos PNG para las tres apps y el atlas `forest.json` (formato JSON-hash de Phaser, con `pivot`). Android e iOS lo leen con un parser propio pequeño (`AtlasParser`), así no hay un segundo formato que mantener. El script copia la salida a `webApp/public/assets/lpc/`, `androidApp/src/main/assets/lpc/` e `iosApp/iosApp/Resources/lpc/`.

### D9. Coordenadas

El dominio usa el sistema de la web (origen arriba-izquierda, Y hacia abajo, unidades = píxeles nativos LPC). Android `Canvas` usa el mismo sistema. SpriteKit tiene la Y hacia arriba: la conversión vive **solo** en `iosApp` (`ScenePoint.swift`).

### D10. Todo el diseño del mapa es dato del nivel

Lo que un diseñador decide del mapa vive **una sola vez** en `shared/data` (hoy el generador procedimental, mañana un fichero de Tiled): tamaño, inicio, cada árbol con su posición, su madera y su **tipo** (`TreeKind`: roble, pino…), los objetos (hacha) y la **decoración del suelo** (`Decoration`: hierba alta, hojas, setas, rocas; sin colisión). El dominio lo modela (`Tree.kind`, `World.decorations`) y el caso de uso lo entrega en `WorldSnapshot`. Las apps solo traducen tipo → sprite con un único helper compartido (`SpriteNames`, en `shared/presentation`): ninguna app elige al azar qué árbol pintar ni dónde poner decoración. Cambiar el bosque = cambiar el datasource; las tres apps lo reciben igual.

En la web actual, el tipo de árbol se elige en la vista con `seededRandom(7)` y la decoración al azar en `GroundView`. Al moverlo al nivel, el generador reproduce exactamente los mismos tipos de árbol (test con valores dorados); la **decoración sí cambia de sitio una vez**, porque se deja de calcular con el tamaño de los sprites y pasa a calcularse con reglas del nivel.

---

## 3. Fases

Cada fase es un plan ejecutable por separado y deja todo funcionando. Orden obligatorio: cada una consume lo que produjo la anterior.

| # | Documento | Entrega | Comprobación de cierre |
|---|---|---|---|
| 1 | [`01-shared-module-setup.md`](01-shared-module-setup.md) | Proyecto Gradle KMP con `shared` compilando y testeando para Android, iOS y JS | `./gradlew :shared:allTests` verde en local |
| 2 | [`02-domain.md`](02-domain.md) | Dominio completo en Kotlin (entidades, `World` y sistemas, misiones, reglas, errores, contratos de repositorio) | tests de dominio portados verdes en JVM/JS/iOS |
| 3 | [`03-data.md`](03-data.md) | Datasources, DTOs, mappers y repositorios; el bosque generado es idéntico al de TypeScript (test con valores dorados) | `:shared:allTests` |
| 4 | [`04-usecases-and-di.md`](04-usecases-and-di.md) | `GameUseCase` + `GameUseCaseImpl` + `GameContainer` | `:shared:allTests` |
| 5 | [`05-shared-presentation.md`](05-shared-presentation.md) | `ForestContract`, `ForestViewModel`, `ForestLabels` compartidos | `:shared:allTests` |
| 6 | [`06-web.md`](06-web.md) | La web usa `shared` vía Kotlin/JS; se borra la lógica TypeScript; el despliegue a Pages genera el paquete Kotlin antes de compilar | partida completa e2e en navegador; GitHub Pages desplegado |
| 7 | [`07-android.md`](07-android.md) | App Android con Compose (mundo en `Canvas`, HUD, misiones, construir, partículas) | instalar en emulador y completar las 3 misiones |
| 8 | [`08-ios.md`](08-ios.md) | App iOS con SwiftUI + SpriteKit (partículas con `SKEmitterNode`) | ejecutar en simulador y completar las 3 misiones |
| 9 | [`09-cleanup.md`](09-cleanup.md) | `rpg/` renombrado a `webApp/`, documentación, `CLAUDE.md`, reglas de arquitectura de Gradle | despliegue a Pages verde, docs al día |

Las fases 7 y 8 son independientes entre sí y pueden ir en paralelo tras la 6.

---

## 4. Mapa de ficheros TypeScript → Kotlin

| TypeScript actual (`rpg/src/`) | Kotlin (`shared/src/commonMain/kotlin/com/apergas/rpg/`) | Fase |
|---|---|---|
| `domain/value-objects/Position.ts` | `domain/entities/geometry/Position.kt` | 2 |
| `domain/entities/Obstacle.ts` | `domain/entities/geometry/Obstacle.kt` | 2 |
| `domain/entities/Inventory.ts` | `domain/entities/player/Inventory.kt` + `ToolKind.kt` | 2 |
| `domain/entities/Player.ts` | `domain/entities/player/Player.kt`, `Activity.kt`, `Intent.kt` | 2 |
| `domain/entities/Tree.ts` | `domain/entities/tree/Tree.kt` + `TreeKind.kt` (nuevo: tipo de árbol) | 2 |
| — (decoración elegida al azar en `GroundView.ts`) | `domain/entities/decoration/Decoration.kt` + `DecorationKind.kt` | 2 |
| `domain/entities/GroundItem.ts` | `domain/entities/item/GroundItem.kt` | 2 |
| `domain/entities/Blueprint.ts`, `Building.ts` | `domain/entities/building/Blueprint.kt`, `BlueprintId.kt`, `Building.kt` | 2 |
| `domain/events.ts` | `domain/entities/game/GameEvent.kt` | 2 |
| `domain/rules.ts` | `domain/rules/Rules.kt` | 2 |
| `domain/world/*.ts` | `domain/world/World.kt`, `WorldState.kt`, `Work.kt`, `Navigation.kt`, `Woodcutting.kt`, `Construction.kt`, `Pickup.kt` | 2 |
| `domain/quests/QuestLog.ts` | `domain/quests/Quest.kt`, `QuestId.kt`, `QuestLog.kt` | 2 |
| `domain/repositories/*.ts` | `domain/repositories/level/LevelRepository.kt`, `domain/repositories/session/GameSessionRepository.kt`, `domain/entities/game/GameSession.kt` | 2 |
| `domain/usecases/*.ts` (6 clases) | `domain/usecases/game/GameUseCase.kt` + `GameUseCaseImpl.kt` | 4 |
| `domain/usecases/models/*.ts` | `domain/entities/game/PlayerStatus.kt`, `WorldSnapshot.kt`, `BuildOption.kt`, `QuestProgress.kt`, `ChopResult.kt`, `ConstructionResult.kt` | 2 |
| `data/dtos/LevelDto.ts` | `data/datasources/local/level/dto/LevelDto.kt` | 3 |
| `data/datasources/*.ts` | `data/datasources/local/level/LevelLocalDataSource.kt` + `LevelLocalDataSourceImpl.kt`; `data/datasources/local/session/GameSessionLocalDataSource.kt` + `...Impl.kt` | 3 |
| `data/mappers/LevelMapper.ts` | `data/repositories/level/LevelMappers.kt` | 3 |
| `data/repositories/*.ts` | `data/repositories/level/LevelRepositoryImpl.kt`, `data/repositories/session/GameSessionRepositoryImpl.kt` | 3 |
| `shared/seededRandom.ts` | `util/SeededRandom.kt` | 3 |
| `presentation/screens/forest/*ViewModel.ts` (3) | `presentation/forest/ForestContract.kt`, `ForestViewModel.kt` | 5 |
| `presentation/common/labels.ts` | `presentation/forest/ForestLabels.kt` | 5 |
| listas `ForestAtlas.TREES` / `DECOR` de `assets.ts` | `presentation/forest/SpriteNames.kt` (tipo → nombre de sprite, para las tres apps) | 5 |
| `main.ts` (montaje) | `di/GameContainer.kt` + `jsMain/.../web/ForestWebController.kt` | 4, 6 |

Lo que **se queda en TypeScript** (web): `presentation/screens/forest/ForestScene.ts`, `hud/Hud.ts` + `hud.css`, `player/PlayerView.ts`, `world/*View.ts`, `screens/preload/PreloadScene.ts`, `common/assets.ts`, `common/depth.ts`, `main.ts`.

---

## 5. Riesgos y cómo se mitigan

| Riesgo | Mitigación |
|---|---|
| El nivel generado en Kotlin difiere del de TypeScript (y la web cambia de aspecto) | Test con valores dorados extraídos del TS actual (fase 3): secuencia de `SeededRandom(42)`, árboles 1–3 y 70 del bosque bit a bit, y tipo de cada uno (`SeededRandom(7)`, mismo orden que la vista web) |
| Comportamiento del juego cambia al portar | Se portan primero los 64 tests existentes (fases 2–5) como especificación; la fase 6 repite el e2e del navegador y compara con la partida de referencia (16 de madera tras 5 árboles, casa construida, 3/3 misiones) |
| `lifecycle-viewmodel` de JetBrains sin target JS en la versión elegida | Fase 1, Task 2 lo verifica compilando `jsMain`; si falla, `ForestViewModel` pasa a ser clase propia con `CoroutineScope` interno y Android la envuelve en un `ViewModel` (alternativa descrita en `05-shared-presentation.md`) |
| Interop JS incómoda (`List`, `Long`, `enum`) | Solo `ForestWebController` está exportado, con tipos planos; nada de `Long` en el modelo (tiempos en `Double`) |
| Interop Swift incómoda (`StateFlow`, sealed) | SKIE desde la fase 1 |
| Tiempo del despliegue | Caché de Gradle (`gradle/actions/setup-gradle`); el despliegue solo compila y testea los targets JVM y JS, nunca iOS |

---

## 6. Despliegue de la web en GitHub Pages (y nada más)

Alcance acordado: **al subir a `main`, la web se publica en GitHub Pages; Android e iOS se prueban en local con emulador/simulador.** No hay CI adicional ni runners de macOS.

**Igual que ahora:** el mismo workflow `deploy.yml`, en el runner Linux que pone GitHub (no hace falta máquina propia), compila la web con Vite y publica `dist/` con `upload-pages-artifact` + `deploy-pages`, en la misma URL y con `base: './'`. El núcleo Kotlin va compilado a JavaScript dentro del bundle.

**Único cambio necesario** (fase 6, Task 3): antes de `npm ci`, el mismo job instala Java 21 y ejecuta Gradle para generar el paquete `rpg-shared` (`:shared:jsBrowserProductionLibraryDistribution`), del que depende la web. Sin ese paso `npm ci` falla.

**Extras baratos incluidos en ese mismo job** (sin workflows ni máquinas nuevas):
- Tests de `shared` en JVM y JS antes de publicar (minutos de Linux; evitan publicar una web rota).
- Filtro de rutas: solo se publica si cambian `shared/`, la web, assets, Gradle o el workflow; un commit solo de Android/iOS no republica.
- `kotlin-js-store/yarn.lock` versionado, para que GitHub resuelva las mismas dependencias que en local.

**Fuera de GitHub, en local:** `./gradlew :shared:allTests` (incluye iOS), tests y ejecución de `androidApp` en emulador, tests y ejecución de `iosApp` en simulador.

| Antes | Después |
|---|---|
| `deploy.yml`: `npm ci` → typecheck → test → build → publicar | `deploy.yml`: Java + Gradle (tests JVM/JS + paquete `rpg-shared`) → `npm ci` → typecheck → test → build → publicar |
| Publica en cualquier push a `main` | Publica solo si cambia algo que afecta a la web |
| `rpg/dist` | `webApp/dist` tras la fase 9 |

## 7. Cómo comprobar en cada fase que no se ha roto nada

- `./gradlew :shared:allTests` — tests compartidos en JVM (Android), JS y simulador iOS.
- `cd rpg && npm run typecheck && npm test && npm run build` — la web, mientras conserve su código TypeScript (hasta la fase 6) y después solo sus vistas.
- Fase 6 en adelante: recorrido e2e en navegador (Playwright) que recoge el hacha, tala hasta ≥15 de madera, construye la casa y termina con 3/3 misiones y sin errores de consola.

---

## 8. Desviaciones durante la ejecución

Lo que cambió respecto a lo escrito al ejecutar cada fase. Las fases siguientes deben leer esto antes de copiar sus fragmentos.

### Fase 1 (2026-10-04)

- **Versiones fijadas** en `gradle/libs.versions.toml`: Kotlin 2.4.20, AGP 9.4.1, Gradle 9.8.0, kotlinx.coroutines 1.11.0, kotlinx.serialization 1.11.0, JetBrains lifecycle-viewmodel 2.11.0, SKIE 0.10.15 (la primera con soporte de Kotlin 2.4.20), KSP 2.3.12, Hilt 2.60.1, Compose BOM 2026.09.00, activity-compose 1.13.0.
- **AGP 9 no admite `com.android.library` junto al plugin KMP.** `shared` usa `com.android.kotlin.multiplatform.library` (alias `androidKotlinMultiplatformLibrary`) y se configura dentro de `kotlin { android { namespace; compileSdk; minSdk; withHostTestBuilder {} } }`; ya no hay bloque `android {}` de nivel superior. La tarea de tests JVM es `:shared:testAndroidHostTest` (no `testDebugUnitTest`).
- **AGP 9 trae Kotlin integrado**: el alias `kotlinAndroid` se elimina del catálogo y `androidApp` (fase 7) no aplica `org.jetbrains.kotlin.android`. El alias `androidLibrary` tampoco existe.
- Kotlin/JS: `moduleName` está obsoleto; se usa `outputModuleName.set("rpg-shared")`.
- `lifecycle-viewmodel` resuelve para JS: `ForestViewModel` puede extender `ViewModel` tal como dice la fase 5 (no hace falta la alternativa).
- `kotlin-js-store/yarn.lock` se versiona ya en la fase 1 (lo genera la primera compilación JS).
- La Task 3 (push + `gh run watch`) no aplica en una rama `feature/*`: el despliegue solo corre en `main`. Se sustituye por `npm run typecheck && npm test && npm run build` en `rpg/` (64 tests verdes, sin cambios en `rpg/`).

### Fase 2 (2026-10-04)

- Sin desviaciones: el código del plan compila y pasa tal cual (39 tests en JVM, JS e iOS).

### Fase 3 (2026-10-04)

- `LevelLocalDataSourceImplTests`: el recuento por tipo se compara con `mapOf<String?, Int>(...)`, porque `TreeDto.kind` es `String?` y Kotlin 2.4 no infiere el tipo con `mapOf("broad" to 3, ...)`. Los valores esperados no cambian.
- `LevelLocalDataSourceImpl.scatterDecorations`: los `!!` repetidos sobre la misma propiedad generaban avisos de "aserción innecesaria"; se leen una vez en variables locales (`spawnX`, `spawnY`, `treeX`, `treeY`). Mismo comportamiento.
- Valores dorados del bosque (posiciones, madera, tipos de árbol y recuentos) idénticos al TypeScript en los tres targets.

### Fase 4 (2026-10-04)

- Sin desviaciones: el código del plan compila sin avisos y pasa tal cual (64 tests en JVM, JS e iOS).

### Fase 5 (2026-10-04)

- El bloque de `ForestContract.kt` no tenía cabecera de fichero en el plan; el fichero se llama `ForestContract.kt` como pide la convención.
- `ForestViewModel` extiende el `ViewModel` de JetBrains en los tres targets (no hizo falta la alternativa sin superclase).
- La etiqueta `close` (\"Cerrar\") de `labels.ts` no se porta: la web no la usa.
- 74 tests en JVM, JS e iOS, sin avisos del compilador.
