# Fase 7 — App Android (Jetpack Compose)

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Una app Android que juega exactamente la misma partida que la web usando `shared`: mundo pintado en un `Canvas` de Compose con los assets LPC, HUD en Material 3, misiones y construcción adaptadas a pantalla táctil.

**Architecture:** Módulo `:androidApp` con la estructura de la skill de Android: `app/` (composition root Hilt), `presentation/navigation/` (ruta tipada global), `presentation/forest/` (`ForestScreen` + componentes). El `ForestViewModel` es el compartido; Hilt aporta el `GameUseCase` (vía `GameContainer`) y una factoría crea el ViewModel. El renderizado del mundo vive en `presentation/forest/world/`.

**Tech Stack:** Android (compileSdk/targetSdk 36), Jetpack Compose (BOM), Material 3, Navigation Compose (rutas `@Serializable`), Hilt + KSP, lifecycle-runtime-compose, kotlinx.serialization (atlas).

## Global Constraints

Las de [`README.md`](README.md#global-constraints) y las de la skill de Android aplicables a una app: `@HiltAndroidApp` en `app/App.kt`; todo el cableado Hilt en `app/di/`; rutas tipadas en un único `AppDestination`; la pantalla habla con el ViewModel solo por `onIntent()`; el `Scaffold` va en un `ForestScaffold` privado que recibe `content`; la pantalla posee el `SnackbarHostState`; composables de contenido privados que reciben datos y lambdas; `modifier: Modifier = Modifier` primer parámetro; accesibilidad: gráficos con `contentDescription` localizado o `null` si son decorativos, botones con `Role.Button`.

**Desviación justificada:** el `ForestViewModel` no lleva `@HiltViewModel` (es de `commonMain`); se crea con `viewModel(factory = ...)` a partir del `GameUseCase` que inyecta Hilt.

**Adaptación táctil (solo presentación, mismos intents):** no hay "puntero flotante": en modo colocación, un toque mueve el fantasma (`PointerMoved`) y la barra inferior ofrece **Construir aquí** (envía `MapClicked` en la posición del fantasma) y **Cancelar** (`PlacementCancelled`). Fuera del modo colocación, un toque equivale al clic de la web.

## File Structure

```
settings.gradle.kts                    include(":androidApp")
gradle/libs.versions.toml              + navigation-compose, lifecycle-runtime-compose, core-ktx
androidApp/
  build.gradle.kts
  src/main/AndroidManifest.xml
  src/main/assets/lpc/                 copiado por build_assets.py
  src/main/res/values/strings.xml      nombre de la app y descripciones de accesibilidad
  src/main/kotlin/com/apergas/rpg/android/
    app/App.kt                         @HiltAndroidApp
    app/MainActivity.kt                @AndroidEntryPoint, setContent { RpgTheme { NavGraph() } }
    app/di/GameModule.kt               @Provides GameUseCase (delegando en GameContainer)
    presentation/theme/RpgTheme.kt
    presentation/navigation/AppDestination.kt, NavGraph.kt
    presentation/forest/ForestScreen.kt          pantalla + ForestScaffold + bucle de juego
    presentation/forest/components/HudOverlay.kt recursos, botones, paneles, barra de colocación
    presentation/forest/world/LpcAssets.kt       carga de bitmaps y atlas
    presentation/forest/world/AtlasParser.kt     forest.json (JSON-hash de Phaser) → frames con pivote
    presentation/forest/world/WorldSceneState.kt árboles/objetos/edificios vivos + animaciones de efectos
    presentation/forest/world/WorldCanvas.kt     dibujo ordenado por Y, cámara, fantasma, partículas
    presentation/forest/world/Particles.kt       astillas y polvo (mismos valores que la web)
  src/test/kotlin/.../world/AtlasParserTests.kt, ParticlesTests.kt
  src/androidTest/kotlin/.../forest/ForestScreenTests.kt
asset-packs/lpc/build_assets.py        + copia a androidApp/src/main/assets/lpc/
```

---

### Task 1: Módulo `:androidApp`, Hilt y navegación

**Files:**
- Modify: `settings.gradle.kts`, `gradle/libs.versions.toml`
- Create: `androidApp/build.gradle.kts`, `androidApp/src/main/AndroidManifest.xml`, `res/values/strings.xml`, `app/App.kt`, `app/MainActivity.kt`, `app/di/GameModule.kt`, `presentation/theme/RpgTheme.kt`, `presentation/navigation/AppDestination.kt`, `presentation/navigation/NavGraph.kt`, `presentation/forest/ForestScreen.kt` (provisional: solo texto)

**Interfaces:**
- Consumes: `GameContainer.makeGameUseCase()`, `ForestViewModel` (shared).
- Produces: app instalable que abre `AppDestination.Forest`; `GameUseCase` inyectable con Hilt.

- [ ] **Step 1: Catálogo** (commit propio). Añadir en `[versions]` `navigationCompose`, `lifecycleRuntimeCompose`, `coreKtx` con la última estable del día, y en `[libraries]`:

```toml
navigation-compose = { module = "androidx.navigation:navigation-compose", version.ref = "navigationCompose" }
lifecycle-runtime-compose = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "lifecycleRuntimeCompose" }
core-ktx = { module = "androidx.core:core-ktx", version.ref = "coreKtx" }
compose-ui-test-junit4 = { module = "androidx.compose.ui:ui-test-junit4" }
compose-ui-test-manifest = { module = "androidx.compose.ui:ui-test-manifest" }
```
```bash
git add gradle/libs.versions.toml
git commit -m "[PROJECT-X]: Add Android navigation and lifecycle libraries to the version catalog"
```

- [ ] **Step 2: `settings.gradle.kts`** → `include(":shared", ":androidApp")`.

- [ ] **Step 3: `androidApp/build.gradle.kts`**

```kotlin
plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.kotlinAndroid)
    alias(libs.plugins.composeCompiler)
    alias(libs.plugins.kotlinSerialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.apergas.rpg.android"
    compileSdk = libs.versions.androidCompileSdk.get().toInt()
    defaultConfig {
        applicationId = "com.apergas.rpg"
        minSdk = libs.versions.androidMinSdk.get().toInt()
        targetSdk = libs.versions.androidTargetSdk.get().toInt()
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    buildFeatures { compose = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin { jvmToolchain(17) }

dependencies {
    implementation(project(":shared"))
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.activity.compose)
    implementation(libs.navigation.compose)
    implementation(libs.lifecycle.runtime.compose)
    implementation(libs.core.ktx)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    testImplementation(kotlin("test"))
    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.compose.ui.test.junit4)
    debugImplementation(libs.compose.ui.test.manifest)
}
```

- [ ] **Step 4: Manifest, strings y entrada de la app**

`AndroidManifest.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:name=".app.App"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.NoActionBar">
        <activity
            android:name=".app.MainActivity"
            android:exported="true"
            android:screenOrientation="userLandscape">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

`res/values/strings.xml`:
```xml
<resources>
    <string name="app_name">RPG</string>
    <string name="cd_game_world">Mundo de juego: bosque con árboles, el personaje y los edificios</string>
    <string name="cd_wood">Madera</string>
    <string name="cd_axe">Hacha</string>
    <string name="build_here">Construir aquí</string>
    <string name="cancel">Cancelar</string>
</resources>
```

`app/App.kt`:
```kotlin
package com.apergas.rpg.android.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class App : Application()
```

`app/di/GameModule.kt`:
```kotlin
package com.apergas.rpg.android.app.di

import com.apergas.rpg.di.GameContainer
import com.apergas.rpg.domain.usecases.game.GameUseCase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object GameModule {
    @Provides
    @Singleton
    fun provideGameUseCase(): GameUseCase = GameContainer.makeGameUseCase()
}
```

`app/MainActivity.kt`:
```kotlin
package com.apergas.rpg.android.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.apergas.rpg.android.presentation.navigation.NavGraph
import com.apergas.rpg.android.presentation.theme.RpgTheme
import com.apergas.rpg.domain.usecases.game.GameUseCase
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var gameUseCase: GameUseCase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { RpgTheme { NavGraph(gameUseCase = gameUseCase) } }
    }
}
```

`presentation/theme/RpgTheme.kt`:
```kotlin
package com.apergas.rpg.android.presentation.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** Same palette as the web HUD (hud.css). */
private val HudColors = darkColorScheme(
    primary = Color(0xFFE8C05A),
    onPrimary = Color(0xFF1C1610),
    surface = Color(0xD11C1610),
    onSurface = Color(0xFFF3E7CF),
    onSurfaceVariant = Color(0xFFB9A888),
    outline = Color(0xFF8A6A3F),
)

@Composable
fun RpgTheme(content: @Composable () -> Unit) = MaterialTheme(colorScheme = HudColors, content = content)
```

`presentation/navigation/AppDestination.kt`:
```kotlin
package com.apergas.rpg.android.presentation.navigation

import kotlinx.serialization.Serializable

sealed interface AppDestination {
    @Serializable data object Forest : AppDestination
}
```

`presentation/navigation/NavGraph.kt`:
```kotlin
package com.apergas.rpg.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.apergas.rpg.android.presentation.forest.ForestScreen
import com.apergas.rpg.domain.usecases.game.GameUseCase
import com.apergas.rpg.presentation.forest.ForestViewModel

@Composable
fun NavGraph(gameUseCase: GameUseCase) {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = AppDestination.Forest) {
        composable<AppDestination.Forest> {
            val viewModel: ForestViewModel = viewModel(factory = viewModelFactory { initializer { ForestViewModel(gameUseCase) } })
            ForestScreen(viewModel = viewModel)
        }
    }
}
```

`presentation/forest/ForestScreen.kt` (provisional, se sustituye en la Task 3):
```kotlin
package com.apergas.rpg.android.presentation.forest

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.apergas.rpg.presentation.forest.ForestViewModel

@Composable
fun ForestScreen(viewModel: ForestViewModel, modifier: Modifier = Modifier) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    Text(text = "${state.hud.questBadge} · ${state.hud.wood}", modifier = modifier)
}
```

- [ ] **Step 5: Compilar e instalar**

Run: `./gradlew :androidApp:assembleDebug && ./gradlew :androidApp:installDebug` (con un emulador arrancado: `emulator -list-avds`, `emulator @<avd> &`)
Expected: la app abre y muestra `0/3 · 0`.

- [ ] **Step 6: Commit**

```bash
git add settings.gradle.kts androidApp
git commit -m "[PROJECT-X]: Add Android app module with Hilt and typed navigation"
```

---

### Task 2: Assets LPC y parser del atlas

**Files:**
- Modify: `asset-packs/lpc/build_assets.py`
- Create: `presentation/forest/world/AtlasParser.kt`, `presentation/forest/world/LpcAssets.kt`
- Test: `androidApp/src/test/kotlin/com/apergas/rpg/android/presentation/forest/world/AtlasParserTests.kt`

**Interfaces:**
- Produces: `data class AtlasFrame(name: String, x: Int, y: Int, width: Int, height: Int, pivotX: Float, pivotY: Float)`; `object AtlasParser { fun parse(json: String): Map<String, AtlasFrame> }`; `class LpcAssets(context: Context)` con `forest: ImageBitmap`, `forestPixels: android.graphics.Bitmap` (para hit-test), `frames: Map<String, AtlasFrame>`, `ground`, `heroWalk`, `heroIdle`, `heroWalkAxe`, `heroIdleAxe`, `heroChop`, `heroHammer` (`ImageBitmap`).

- [ ] **Step 1: El script copia también a Android.** Al final de `build_assets.py`, en `if __name__ == "__main__":`, tras generar:

```python
    android_out = ROOT.parent.parent / "androidApp" / "src" / "main" / "assets" / "lpc"
    shutil.copytree(OUT, android_out, dirs_exist_ok=True)
```
(con `import shutil` arriba). Run: `cd asset-packs/lpc && python3 build_assets.py && ls ../../androidApp/src/main/assets/lpc`
Expected: los mismos PNG y `forest.json` que en la web.

- [ ] **Step 2: Test del parser**

```kotlin
package com.apergas.rpg.android.presentation.forest.world

import kotlin.test.Test
import kotlin.test.assertEquals

class AtlasParserTests {
    @Test
    fun testWhenParsingAPhaserJsonHashAtlasThenReturnsFramesWithPivots() {
        // given
        val json = """
            {"frames": {"tree-oak": {"frame": {"x": 10, "y": 20, "w": 125, "h": 151},
              "rotated": false, "trimmed": false, "pivot": {"x": 0.568, "y": 1.0}}},
             "meta": {"image": "forest.png"}}
        """.trimIndent()

        // when
        val frames = AtlasParser.parse(json)

        // then
        assertEquals(AtlasFrame("tree-oak", 10, 20, 125, 151, 0.568f, 1.0f), frames.getValue("tree-oak"))
    }
}
```

- [ ] **Step 3: Ejecutar y ver que falla**

Run: `./gradlew :androidApp:testDebugUnitTest`
Expected: FAIL — `Unresolved reference: AtlasParser`.

- [ ] **Step 4: Implementar**

`AtlasParser.kt`:
```kotlin
package com.apergas.rpg.android.presentation.forest.world

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

data class AtlasFrame(
    val name: String,
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
    val pivotX: Float,
    val pivotY: Float,
)

/** Reads the Phaser JSON-hash atlas generated by build_assets.py, pivots included. */
object AtlasParser {
    @Serializable private data class Rect(val x: Int, val y: Int, val w: Int, val h: Int)
    @Serializable private data class Pivot(val x: Float = 0.5f, val y: Float = 0.5f)
    @Serializable private data class Frame(val frame: Rect, val pivot: Pivot = Pivot())
    @Serializable private data class Atlas(val frames: Map<String, Frame>)

    private val json = Json { ignoreUnknownKeys = true }

    fun parse(text: String): Map<String, AtlasFrame> =
        json.decodeFromString<Atlas>(text).frames.mapValues { (name, entry) ->
            AtlasFrame(name, entry.frame.x, entry.frame.y, entry.frame.w, entry.frame.h, entry.pivot.x, entry.pivot.y)
        }
}
```

`LpcAssets.kt`:
```kotlin
package com.apergas.rpg.android.presentation.forest.world

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap

/** Every LPC texture the forest screen draws, loaded once from assets/lpc. */
class LpcAssets(context: Context) {
    private fun bitmap(name: String): Bitmap =
        context.assets.open("lpc/$name").use { BitmapFactory.decodeStream(it) }

    val forestPixels: Bitmap = bitmap("forest.png")
    val forest: ImageBitmap = forestPixels.asImageBitmap()
    val frames: Map<String, AtlasFrame> =
        AtlasParser.parse(context.assets.open("lpc/forest.json").bufferedReader().use { it.readText() })
    val ground: ImageBitmap = bitmap("ground.png").asImageBitmap()
    val heroWalk: ImageBitmap = bitmap("hero-walk.png").asImageBitmap()
    val heroIdle: ImageBitmap = bitmap("hero-idle.png").asImageBitmap()
    val heroWalkAxe: ImageBitmap = bitmap("hero-walk-axe.png").asImageBitmap()
    val heroIdleAxe: ImageBitmap = bitmap("hero-idle-axe.png").asImageBitmap()
    val heroChop: ImageBitmap = bitmap("hero-chop.png").asImageBitmap()
    val heroHammer: ImageBitmap = bitmap("hero-hammer.png").asImageBitmap()

    /** Pixel-accurate hit test on an atlas frame, in frame-local coordinates. */
    fun isOpaque(frame: AtlasFrame, localX: Int, localY: Int): Boolean {
        if (localX !in 0 until frame.width || localY !in 0 until frame.height) return false
        return (forestPixels.getPixel(frame.x + localX, frame.y + localY) ushr 24) >= SOLID_ALPHA
    }

    private companion object {
        /** Same threshold as the web: the painted tree shadow is fainter. */
        const val SOLID_ALPHA = 200
    }
}
```

- [ ] **Step 5: Ejecutar y ver que pasa**

Run: `./gradlew :androidApp:testDebugUnitTest`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add asset-packs/lpc/build_assets.py androidApp
git commit -m "[PROJECT-X]: Load LPC assets and atlas in the Android app"
```

---

### Task 3: Mundo en `Canvas`, bucle de juego, HUD y efectos

**Files:**
- Create: `presentation/forest/world/WorldSceneState.kt`, `presentation/forest/world/WorldCanvas.kt`, `presentation/forest/components/HudOverlay.kt`
- Modify: `presentation/forest/ForestScreen.kt` (versión final)
- Test: `androidApp/src/androidTest/kotlin/com/apergas/rpg/android/presentation/forest/ForestScreenTests.kt`

**Interfaces:**
- Consumes: `LpcAssets`, `AtlasFrame` (Task 2); `ForestViewModel`, `ForestState`, `ForestEffect`, `ForestIntent`, `WorldSnapshot`, `SpriteNames` (shared).
- Produces: `ForestScreen(viewModel, modifier)` final.

Constantes de render (idénticas a la web, `rpg/src/presentation/common/assets.ts`): zoom de cámara `2`; hoja de personaje 64 px, origen Y `62/64`; filas de dirección `up, left, down, right`; andar: columnas 1–8 a 10 fps; quieto: 2 columnas a 2 fps; trabajo: celdas 128 px, 6 columnas, origen Y `94/128`, secuencias hacha `[0,0,5,5,4,4,3,1]` y martillo `[0,0,5,5,4,4,1]`; árboles y decoración: el sprite lo da `SpriteNames` a partir del tipo que trae el nivel; casa: pivote abajo-centro, dibujada `24` px por debajo del centro de su huella; edificio en obra con alfa `0.35 + 0.65·progreso`.

- [ ] **Step 1: `WorldSceneState.kt`** — estado vivo del mundo dibujado y animaciones de efectos

```kotlin
package com.apergas.rpg.android.presentation.forest.world

import androidx.compose.runtime.mutableStateMapOf
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.SpriteNames

data class SceneTree(val id: String, val base: Position, val frame: String, val hitAtNanos: Long? = null, val fromX: Double = 0.0, val felledAtNanos: Long? = null)
data class SceneBuilding(val id: String, val center: Position, val progress: Double, val completedAtNanos: Long? = null)
data class SceneDecoration(val id: String, val position: Position, val frame: String)

/**
 * What is drawn in the world beyond the player: built from the initial snapshot and kept up to date
 * by the view model's effects, exactly like the web scene.
 */
class WorldSceneState(snapshot: WorldSnapshot) {
    val width = snapshot.width
    val height = snapshot.height
    val trees = mutableStateMapOf<String, SceneTree>()
    val items = mutableStateMapOf<String, Position>()
    val buildings = mutableStateMapOf<String, SceneBuilding>()
    val stumps = mutableStateMapOf<String, Position>()
    val decorations = mutableStateMapOf<String, SceneDecoration>()

    init {
        // What to draw and where comes from the level (shared): no art decisions are made here.
        snapshot.trees.forEach { tree -> trees[tree.id] = SceneTree(tree.id, tree.position, SpriteNames.tree(tree.kind)) }
        snapshot.decorations.forEach { decoration ->
            decorations[decoration.id] = SceneDecoration(decoration.id, decoration.position, SpriteNames.decoration(decoration.kind))
        }
        snapshot.items.forEach { items[it.id] = it.position }
        snapshot.buildings.forEach { buildings[it.id] = it.toScene() }
    }

    fun play(effect: ForestEffect, nowNanos: Long) {
        when (effect) {
            is ForestEffect.ItemPickedUp -> items.remove(effect.itemId)
            is ForestEffect.TreeHit -> trees.computeIfPresent(effect.treeId) { _, tree -> tree.copy(hitAtNanos = nowNanos, fromX = effect.fromX) }
            is ForestEffect.TreeFelled -> trees[effect.treeId]?.let { tree ->
                trees[tree.id] = tree.copy(felledAtNanos = nowNanos, fromX = effect.fromX)
                stumps[tree.id] = tree.base
            }
            is ForestEffect.BuildingPlaced -> {
                buildings[effect.building.id] = effect.building.toScene()
                val radius = effect.building.blueprint.footprintRadius + 24
                stumps.filterValues { base -> base.distanceTo(effect.building.position) < radius }.keys.forEach(stumps::remove)
                decorations.filterValues { it.position.distanceTo(effect.building.position) < radius }.keys.forEach(decorations::remove)
            }
            is ForestEffect.BuildingHammered -> buildings.computeIfPresent(effect.buildingId) { _, b -> b.copy(progress = effect.progress) }
            is ForestEffect.BuildingCompleted -> buildings.computeIfPresent(effect.buildingId) { _, b -> b.copy(progress = 1.0, completedAtNanos = nowNanos) }
            is ForestEffect.ShowMessage -> Unit
        }
    }

    /** Removes trees whose fall animation has finished. */
    fun prune(nowNanos: Long) {
        trees.values.filter { it.felledAtNanos != null && nowNanos - it.felledAtNanos > FALL_NANOS }.forEach { trees.remove(it.id) }
    }

    /** The tree drawn on top at this world point, pixel-accurate, or null. */
    fun treeAt(point: Position, assets: LpcAssets): String? =
        trees.values.filter { it.felledAtNanos == null }.sortedByDescending { it.base.y }.firstOrNull { tree ->
            val frame = assets.frames.getValue(tree.frame)
            val left = tree.base.x - frame.width * frame.pivotX
            val top = tree.base.y - frame.height * frame.pivotY
            assets.isOpaque(frame, (point.x - left).toInt(), (point.y - top).toInt())
        }?.id

    private fun Building.toScene() = SceneBuilding(id, position, progress)

    companion object {
        const val FALL_NANOS = 700_000_000L
    }
}
```

- [ ] **Step 2: `WorldCanvas.kt`** — dibujo ordenado por Y con cámara

```kotlin
package com.apergas.rpg.android.presentation.forest.world

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.Facing
import com.apergas.rpg.presentation.forest.Placement
import com.apergas.rpg.presentation.forest.PlayerPose
import com.apergas.rpg.presentation.forest.PlayerRenderState
import com.apergas.rpg.presentation.forest.WorkTool
import kotlin.math.exp
import kotlin.math.min
import kotlin.math.sin

const val CAMERA_ZOOM = 2f
private const val HOUSE_FRONT_OFFSET = 24.0
private val FACING_ROWS = listOf(Facing.Up, Facing.Left, Facing.Down, Facing.Right)
private val CHOP_SEQUENCE = listOf(0, 0, 5, 5, 4, 4, 3, 1)
private val HAMMER_SEQUENCE = listOf(0, 0, 5, 5, 4, 4, 1)

/** Top-left world point shown on screen: the camera follows the player and stays inside the world. */
fun cameraOrigin(player: Position, scene: WorldSceneState, viewport: Size): Offset {
    val viewWidth = viewport.width / CAMERA_ZOOM
    val viewHeight = viewport.height / CAMERA_ZOOM
    fun axis(center: Double, world: Double, view: Float): Float =
        if (view >= world) ((world - view) / 2).toFloat()
        else (center - view / 2).coerceIn(0.0, world - view).toFloat()
    return Offset(axis(player.x, scene.width, viewWidth), axis(player.y, scene.height, viewHeight))
}

@Composable
fun WorldCanvas(
    scene: WorldSceneState,
    player: PlayerRenderState,
    placement: Placement?,
    assets: LpcAssets,
    frameNanos: Long,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        val origin = cameraOrigin(player.position, scene, size)
        withTransform({
            scale(CAMERA_ZOOM, CAMERA_ZOOM, pivot = Offset.Zero)
            translate(-origin.x, -origin.y)
        }) {
            drawGround(scene, assets)
            val drawables = buildList<Pair<Double, DrawScope.() -> Unit>> {
                scene.decorations.values.forEach { decoration -> add(decoration.position.y to { drawFrame(assets, decoration.frame, decoration.position) }) }
                scene.stumps.values.forEach { base -> add(base.y - 1 to { drawFrame(assets, "stump", base) }) }
                scene.items.values.forEach { position -> add(position.y to { drawFrame(assets, "axe-pickup", Position(position.x, position.y - 8)) }) }
                scene.trees.values.forEach { tree -> add(tree.base.y to { drawTree(assets, tree, frameNanos) }) }
                scene.buildings.values.forEach { building ->
                    add(building.center.y + HOUSE_FRONT_OFFSET to { drawHouse(assets, building.center, 0.35f + 0.65f * building.progress.toFloat()) })
                }
                add(player.position.y to { drawPlayer(assets, player, frameNanos) })
            }
            drawables.sortedBy { it.first }.forEach { (_, draw) -> draw() }
            placement?.let { ghost ->
                val tint = if (ghost.isValid) Color(0xFFB8FFB8) else Color(0xFFFF8080)
                drawHouse(assets, ghost.position, 0.6f, ColorFilter.tint(tint, androidx.compose.ui.graphics.BlendMode.Modulate))
            }
        }
    }
}

private fun DrawScope.drawGround(scene: WorldSceneState, assets: LpcAssets) {
    val tile = 32
    var y = 0
    while (y < scene.height) {
        var x = 0
        while (x < scene.width) {
            drawImage(assets.ground, srcOffset = IntOffset.Zero, srcSize = IntSize(tile, tile), dstOffset = IntOffset(x, y), dstSize = IntSize(tile, tile), filterQuality = FilterQuality.None)
            x += tile
        }
        y += tile
    }
}

private fun DrawScope.drawFrame(assets: LpcAssets, name: String, anchor: Position, alpha: Float = 1f, colorFilter: ColorFilter? = null) {
    val frame = assets.frames.getValue(name)
    val left = (anchor.x - frame.width * frame.pivotX).toInt()
    val top = (anchor.y - frame.height * frame.pivotY).toInt()
    drawImage(
        assets.forest,
        srcOffset = IntOffset(frame.x, frame.y),
        srcSize = IntSize(frame.width, frame.height),
        dstOffset = IntOffset(left, top),
        dstSize = IntSize(frame.width, frame.height),
        alpha = alpha,
        colorFilter = colorFilter,
        filterQuality = FilterQuality.None,
    )
}

/** Shake for 140 ms after a hit; fall away from the player and fade out over 700 ms. */
private fun DrawScope.drawTree(assets: LpcAssets, tree: SceneTree, now: Long) {
    val awayFromPlayer = if (tree.fromX < tree.base.x) 1f else -1f
    val pivot = Offset(tree.base.x.toFloat(), tree.base.y.toFloat())
    val felledAt = tree.felledAtNanos
    if (felledAt != null) {
        val t = min(1f, (now - felledAt) / WorldSceneState.FALL_NANOS.toFloat())
        rotate(85f * awayFromPlayer * t * t, pivot) { drawFrame(assets, tree.frame, tree.base, alpha = 1f - t) }
        return
    }
    val hitAt = tree.hitAtNanos
    val shake = if (hitAt == null) 0f else {
        val t = (now - hitAt) / 1_000_000f
        if (t > 140f) 0f else 3f * awayFromPlayer * sin(t / 140f * Math.PI.toFloat()) * exp(-t / 200f)
    }
    rotate(shake, pivot) { drawFrame(assets, tree.frame, tree.base) }
}

private fun DrawScope.drawHouse(assets: LpcAssets, center: Position, alpha: Float, colorFilter: ColorFilter? = null) =
    drawFrame(assets, "house", Position(center.x, center.y + HOUSE_FRONT_OFFSET), alpha, colorFilter)

private fun DrawScope.drawPlayer(assets: LpcAssets, player: PlayerRenderState, now: Long) {
    val row = FACING_ROWS.indexOf(player.facing)
    val (sheet, cell, column, originY) = when (val pose = player.pose) {
        is PlayerPose.Work -> {
            val sequence = if (pose.tool == WorkTool.Axe) CHOP_SEQUENCE else HAMMER_SEQUENCE
            val step = min(sequence.size - 1, (pose.swingProgress * sequence.size).toInt())
            SheetFrame(if (pose.tool == WorkTool.Axe) assets.heroChop else assets.heroHammer, 128, sequence[step], 94f / 128)
        }
        is PlayerPose.Walk -> SheetFrame(if (pose.withAxe) assets.heroWalkAxe else assets.heroWalk, 64, 1 + ((now / 100_000_000L) % 8).toInt(), 62f / 64)
        is PlayerPose.Idle -> SheetFrame(if (pose.withAxe) assets.heroIdleAxe else assets.heroIdle, 64, ((now / 500_000_000L) % 2).toInt(), 62f / 64)
    }
    drawOval(Color(0x4D000000), topLeft = Offset(player.position.x.toFloat() - 11, player.position.y.toFloat() - 4.5f), size = Size(22f, 7f))
    drawImage(
        sheet,
        srcOffset = IntOffset(column * cell, row * cell),
        srcSize = IntSize(cell, cell),
        dstOffset = IntOffset((player.position.x - cell / 2).toInt(), (player.position.y - cell * originY).toInt()),
        dstSize = IntSize(cell, cell),
        filterQuality = FilterQuality.None,
    )
}

private data class SheetFrame(val sheet: ImageBitmap, val cell: Int, val column: Int, val originY: Float)
```

- [ ] **Step 3: `HudOverlay.kt`** — mismo contenido que el HUD web, en Compose

```kotlin
package com.apergas.rpg.android.presentation.forest.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.apergas.rpg.android.R
import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.presentation.forest.ForestLabels
import com.apergas.rpg.presentation.forest.HudState
import com.apergas.rpg.presentation.forest.QuestItemStatus

private enum class Panel { Quests, Build }

@Composable
fun HudOverlay(
    hud: HudState,
    isPlacing: Boolean,
    onBuild: (BlueprintId) -> Unit,
    onConfirmPlacement: () -> Unit,
    onCancelPlacement: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var openPanel by remember { mutableStateOf<Panel?>(null) }
    Box(modifier = modifier.fillMaxSize().padding(12.dp)) {
        Card(modifier = Modifier.align(Alignment.TopStart)) {
            Row(modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("${ForestLabels.WOOD} ${hud.wood}", color = MaterialTheme.colorScheme.primary)
                Text(ForestLabels.AXE, color = if (hud.hasAxe) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Column(modifier = Modifier.align(Alignment.TopEnd), horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = { openPanel = if (openPanel == Panel.Quests) null else Panel.Quests }) {
                    Text("${ForestLabels.QUESTS} ${hud.questBadge}")
                }
                OutlinedButton(enabled = !hud.isBuildLocked, onClick = { openPanel = if (openPanel == Panel.Build) null else Panel.Build }) {
                    Text(ForestLabels.BUILD)
                }
            }
            when (openPanel) {
                Panel.Quests -> Card(modifier = Modifier.widthIn(max = 320.dp)) {
                    Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        hud.quests.forEach { quest ->
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Text(
                                    quest.title,
                                    textDecoration = if (quest.status == QuestItemStatus.Done) TextDecoration.LineThrough else null,
                                    color = if (quest.status == QuestItemStatus.Pending) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
                                )
                                Text(quest.progressText, color = MaterialTheme.colorScheme.primary)
                            }
                        }
                    }
                }
                Panel.Build -> Card(modifier = Modifier.widthIn(max = 320.dp)) {
                    Column(modifier = Modifier.padding(8.dp)) {
                        hud.buildItems.forEach { item ->
                            OutlinedButton(enabled = item.isEnabled, onClick = { openPanel = null; onBuild(item.blueprint) }) {
                                Text("${item.name} · ${item.costText}" + (item.missingText?.let { " · $it" } ?: ""))
                            }
                        }
                    }
                }
                null -> Unit
            }
        }
        if (isPlacing) {
            Row(modifier = Modifier.align(Alignment.BottomCenter), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = onConfirmPlacement) { Text(stringResource(R.string.build_here)) }
                OutlinedButton(onClick = onCancelPlacement) { Text(stringResource(R.string.cancel)) }
            }
        }
    }
}
```

- [ ] **Step 4: `ForestScreen.kt` final** — bucle de juego, efectos, entrada y `ForestScaffold`

```kotlin
package com.apergas.rpg.android.presentation.forest

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.toSize
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.apergas.rpg.android.R
import com.apergas.rpg.android.presentation.forest.components.HudOverlay
import com.apergas.rpg.android.presentation.forest.world.CAMERA_ZOOM
import com.apergas.rpg.android.presentation.forest.world.LpcAssets
import com.apergas.rpg.android.presentation.forest.world.WorldCanvas
import com.apergas.rpg.android.presentation.forest.world.WorldSceneState
import com.apergas.rpg.android.presentation.forest.world.cameraOrigin
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.presentation.forest.ForestEffect
import com.apergas.rpg.presentation.forest.ForestIntent
import com.apergas.rpg.presentation.forest.ForestViewModel
import kotlinx.coroutines.isActive

@Composable
fun ForestScreen(viewModel: ForestViewModel, modifier: Modifier = Modifier) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val assets = remember { LpcAssets(context) }
    val scene = remember { WorldSceneState(viewModel.worldSnapshot()) }
    val snackbarHostState = remember { SnackbarHostState() }
    var frameNanos by remember { mutableLongStateOf(0L) }

    LaunchedEffect(viewModel) {
        viewModel.uiEffect.collect { effect ->
            if (effect is ForestEffect.ShowMessage) snackbarHostState.showSnackbar(effect.text)
            else scene.play(effect, frameNanos)
        }
    }
    LaunchedEffect(viewModel) {
        var last = androidx.compose.runtime.withFrameNanos { it }
        while (isActive) {
            androidx.compose.runtime.withFrameNanos { now ->
                viewModel.onIntent(ForestIntent.Tick((now - last) / 1_000_000.0))
                last = now
                frameNanos = now
                scene.prune(now)
            }
        }
    }

    ForestScaffold(snackbarHostState = snackbarHostState, modifier = modifier) { padding ->
        Box(modifier = Modifier.fillMaxSize()) {
            val description = stringResource(R.string.cd_game_world)
            WorldCanvas(
                scene = scene,
                player = state.player,
                placement = state.placement,
                assets = assets,
                frameNanos = frameNanos,
                modifier = Modifier
                    .fillMaxSize()
                    .semantics { contentDescription = description }
                    .pointerInput(Unit) {
                        detectTapGestures { tap ->
                            val origin = cameraOrigin(state.player.position, scene, this.size.toSize())
                            val world = Position((origin.x + tap.x / CAMERA_ZOOM).toDouble(), (origin.y + tap.y / CAMERA_ZOOM).toDouble())
                            if (state.placement != null) viewModel.onIntent(ForestIntent.PointerMoved(world))
                            else viewModel.onIntent(ForestIntent.MapClicked(world, scene.treeAt(world, assets)))
                        }
                    },
            )
            HudOverlay(
                hud = state.hud,
                isPlacing = state.placement != null,
                onBuild = { viewModel.onIntent(ForestIntent.BuildRequested(it)) },
                onConfirmPlacement = { state.placement?.let { viewModel.onIntent(ForestIntent.MapClicked(it.position, treeId = null)) } },
                onCancelPlacement = { viewModel.onIntent(ForestIntent.PlacementCancelled) },
                modifier = Modifier.padding(padding),
            )
        }
    }
}

@Composable
private fun ForestScaffold(
    snackbarHostState: SnackbarHostState,
    modifier: Modifier = Modifier,
    content: @Composable (PaddingValues) -> Unit,
) {
    Scaffold(modifier = modifier, snackbarHost = { SnackbarHost(snackbarHostState) }, content = content)
}
```

- [ ] **Step 5: Test instrumentado del HUD**

```kotlin
package com.apergas.rpg.android.presentation.forest

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.apergas.rpg.android.presentation.theme.RpgTheme
import com.apergas.rpg.di.GameContainer
import com.apergas.rpg.presentation.forest.ForestViewModel
import org.junit.Rule
import org.junit.Test

class ForestScreenTests {
    @get:Rule val composeRule = createComposeRule()

    @Test
    fun testWhenOpeningQuestsThenTheFirstQuestIsListed() {
        // given
        composeRule.setContent { RpgTheme { ForestScreen(viewModel = ForestViewModel(GameContainer.makeGameUseCase())) } }

        // when
        composeRule.onNodeWithText("Misiones 0/3").performClick()

        // then
        composeRule.onNodeWithText("Recoge el hacha").assertIsDisplayed()
    }
}
```

Run: `./gradlew :androidApp:connectedDebugAndroidTest` (emulador arrancado)
Expected: PASS.

- [ ] **Step 6: Partida manual en emulador**

Run: `./gradlew :androidApp:installDebug`, abrir la app y comprobar: bosque idéntico al de la web (mismos árboles en las mismas posiciones); recoger el hacha → snackbar "¡Hacha recogida!…"; tocar un árbol → se coloca a su lado, da hachazos con sacudida del árbol (las astillas llegan en la Task 4), el árbol cae y deja tocón; 3 árboles → ≥15 madera; **Construir** → Casa → tocar sitio (fantasma verde/rojo) → **Construir aquí**; casa construida; **Misiones 3/3**.

- [ ] **Step 7: Commit**

```bash
git add androidApp asset-packs
git commit -m "[PROJECT-X]: Add Compose forest screen with world rendering, HUD and touch placement"
```

### Task 4: Partículas (astillas y polvo)

**Files:**
- Create: `presentation/forest/world/Particles.kt`
- Modify: `presentation/forest/world/WorldSceneState.kt`, `presentation/forest/world/WorldCanvas.kt`
- Test: `androidApp/src/test/kotlin/com/apergas/rpg/android/presentation/forest/world/ParticlesTests.kt`

**Interfaces:**
- Consumes: `WorldSceneState.play`/`prune`, `WorldCanvas` (Task 3); `ForestEffect.TreeHit`, `ForestEffect.BuildingHammered` (shared).
- Produces: `Particle`, `ParticleKind`, `ParticleBursts.woodChips(trunkBase, playerOnLeft, nowNanos, random)`, `ParticleBursts.dust(buildingCenter, nowNanos, random)`; `WorldSceneState.particles`.

Compose no trae sistema de partículas, así que se escribe uno mínimo. Cada partícula tiene trayectoria cerrada (posición = origen + v·t + ½·g·t²): no se actualiza fotograma a fotograma, se calcula en el instante del dibujo con el `frameNanos` que ya existe. Valores copiados de la web (`TreeView.hit`, `BuildingView.hammered`, `PreloadScene.generateParticleTextures`), con los ángulos en grados y la Y hacia abajo como en Phaser:

| Efecto | Origen | Cantidad | Velocidad | Ángulo | Gravedad | Vida | Alfa | Escala | Aspecto |
|---|---|---|---|---|---|---|---|---|---|
| Astillas (`TreeHit`) | base del tronco − 10 en Y | 8 | 30–80 | 200–290 si el jugador está a la izquierda, 250–340 si a la derecha | 220 | 500 ms | 1 → 0 | 1 | rectángulo 3×2 `#8A5A2B` con brillo 2×1 `#C89A5E`, giro fijo al azar 0–360 |
| Polvo (`BuildingHammered`) | frente de la casa (centro + 24) − 4 en Y | 6 | 10–35 | 180–360 | 0 | 450 ms | 0.7 → 0 | 0.8 → 0.2 | círculo de radio 3 `#D8CDB0` |

- [ ] **Step 1: Test**

`ParticlesTests.kt`:
```kotlin
package com.apergas.rpg.android.presentation.forest.world

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.math.atan2
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ParticlesTests {
    private val trunkBase = Position(200.0, 300.0)

    @Test
    fun testWhenTreeIsHitFromTheLeftThenEightChipsFlyUpTowardsThePlayer() {
        // given
        val random = Random(1)

        // when
        val chips = ParticleBursts.woodChips(trunkBase, playerOnLeft = true, nowNanos = 0, random = random)

        // then
        assertEquals(8, chips.size)
        chips.forEach { chip ->
            assertEquals(Position(200.0, 290.0), chip.origin)
            assertTrue(chip.angleDegrees() in 200.0..290.0)
        }
    }

    @Test
    fun testWhenTimePassesThenAChipFallsWithGravityAndFadesOut() {
        // given
        val chip = ParticleBursts.woodChips(trunkBase, playerOnLeft = false, nowNanos = 0, random = Random(1)).first()

        // when
        val position = chip.position(nowNanos = 250_000_000)

        // then
        assertEquals(chip.origin.x + chip.velocityX * 0.25, position.x, 1e-9)
        assertEquals(chip.origin.y + chip.velocityY * 0.25 + 0.5 * 220 * 0.25 * 0.25, position.y, 1e-9)
        assertEquals(0.5, chip.alpha(nowNanos = 250_000_000), 1e-9)
        assertFalse(chip.isAlive(nowNanos = 500_000_000))
    }

    @Test
    fun testWhenBuildingIsHammeredThenSixDustPuffsRiseFromItsFront() {
        // given
        val center = Position(400.0, 400.0)

        // when
        val dust = ParticleBursts.dust(center, nowNanos = 0, random = Random(1))

        // then
        assertEquals(6, dust.size)
        dust.forEach { puff ->
            assertEquals(Position(400.0, 420.0), puff.origin)
            assertTrue(puff.velocityY <= 0.0)
            assertEquals(0.2, puff.scale(nowNanos = 450_000_000), 1e-9)
        }
    }

    private fun Particle.angleDegrees(): Double = (Math.toDegrees(atan2(velocityY, velocityX)) + 360) % 360
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :androidApp:testDebugUnitTest --tests "*ParticlesTests"`
Expected: FAIL (`Unresolved reference: ParticleBursts`).

- [ ] **Step 3: `Particles.kt`**

```kotlin
package com.apergas.rpg.android.presentation.forest.world

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

enum class ParticleKind { WoodChip, Dust }

/** One particle with a closed-form trajectory: its state at any instant is computed, never stepped. */
data class Particle(
    val kind: ParticleKind,
    val origin: Position,
    val velocityX: Double,
    val velocityY: Double,
    val gravity: Double,
    val rotationDegrees: Double,
    val bornAtNanos: Long,
    val lifespanNanos: Long,
    val alphaStart: Double,
    val alphaEnd: Double,
    val scaleStart: Double,
    val scaleEnd: Double,
    /** Draw order: just in front of whatever emitted it. */
    val sortY: Double,
) {
    fun isAlive(nowNanos: Long): Boolean = nowNanos - bornAtNanos < lifespanNanos

    fun position(nowNanos: Long): Position {
        val seconds = (nowNanos - bornAtNanos) / 1e9
        return Position(
            origin.x + velocityX * seconds,
            origin.y + velocityY * seconds + 0.5 * gravity * seconds * seconds,
        )
    }

    fun alpha(nowNanos: Long): Double = alphaStart + (alphaEnd - alphaStart) * progress(nowNanos)

    fun scale(nowNanos: Long): Double = scaleStart + (scaleEnd - scaleStart) * progress(nowNanos)

    private fun progress(nowNanos: Long): Double = ((nowNanos - bornAtNanos).toDouble() / lifespanNanos).coerceIn(0.0, 1.0)
}

private const val CHIPS_PER_HIT = 8
private const val IMPACT_HEIGHT = 10.0
private const val DUST_PER_HAMMER = 6
/** The dust rises from the house's front wall, which is drawn 24 px below its footprint centre. */
private const val HOUSE_FRONT_OFFSET = 24.0
private const val DUST_LIFT = 4.0

/** The web's bursts (TreeView.hit, BuildingView.hammered) with the same Phaser emitter values: degrees, Y down. */
object ParticleBursts {
    fun woodChips(trunkBase: Position, playerOnLeft: Boolean, nowNanos: Long, random: Random): List<Particle> {
        val angles = if (playerOnLeft) 200.0..290.0 else 250.0..340.0
        return List(CHIPS_PER_HIT) {
            val speed = random.between(30.0..80.0)
            val angle = Math.toRadians(random.between(angles))
            Particle(
                kind = ParticleKind.WoodChip,
                origin = Position(trunkBase.x, trunkBase.y - IMPACT_HEIGHT),
                velocityX = speed * cos(angle),
                velocityY = speed * sin(angle),
                gravity = 220.0,
                rotationDegrees = random.between(0.0..360.0),
                bornAtNanos = nowNanos,
                lifespanNanos = 500_000_000,
                alphaStart = 1.0,
                alphaEnd = 0.0,
                scaleStart = 1.0,
                scaleEnd = 1.0,
                sortY = trunkBase.y + 0.5,
            )
        }
    }

    fun dust(buildingCenter: Position, nowNanos: Long, random: Random): List<Particle> {
        val front = buildingCenter.y + HOUSE_FRONT_OFFSET
        return List(DUST_PER_HAMMER) {
            val speed = random.between(10.0..35.0)
            val angle = Math.toRadians(random.between(180.0..360.0))
            Particle(
                kind = ParticleKind.Dust,
                origin = Position(buildingCenter.x, front - DUST_LIFT),
                velocityX = speed * cos(angle),
                velocityY = speed * sin(angle),
                gravity = 0.0,
                rotationDegrees = 0.0,
                bornAtNanos = nowNanos,
                lifespanNanos = 450_000_000,
                alphaStart = 0.7,
                alphaEnd = 0.0,
                scaleStart = 0.8,
                scaleEnd = 0.2,
                sortY = front + 1,
            )
        }
    }

    private fun Random.between(range: ClosedFloatingPointRange<Double>): Double =
        range.start + nextDouble() * (range.endInclusive - range.start)
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :androidApp:testDebugUnitTest --tests "*ParticlesTests"`
Expected: PASS.

- [ ] **Step 5: Emitir desde `WorldSceneState.kt`** — añadir el import `kotlin.random.Random`, la lista de partículas y sustituir las ramas `TreeHit` y `BuildingHammered` y la función `prune`:

```kotlin
    val particles = mutableStateListOf<Particle>()
    private val random = Random.Default
```
(import `androidx.compose.runtime.mutableStateListOf`)

```kotlin
            is ForestEffect.TreeHit -> trees[effect.treeId]?.let { tree ->
                trees[tree.id] = tree.copy(hitAtNanos = nowNanos, fromX = effect.fromX)
                particles += ParticleBursts.woodChips(tree.base, playerOnLeft = effect.fromX < tree.base.x, nowNanos, random)
            }
```
```kotlin
            is ForestEffect.BuildingHammered -> buildings[effect.buildingId]?.let { building ->
                buildings[building.id] = building.copy(progress = effect.progress)
                particles += ParticleBursts.dust(building.center, nowNanos, random)
            }
```
```kotlin
    /** Removes trees whose fall animation has finished and particles that have faded out. */
    fun prune(nowNanos: Long) {
        trees.values.filter { it.felledAtNanos != null && nowNanos - it.felledAtNanos > FALL_NANOS }.forEach { trees.remove(it.id) }
        particles.removeAll { !it.isAlive(nowNanos) }
    }
```

- [ ] **Step 6: Dibujar en `WorldCanvas.kt`** — en `buildList` de `WorldCanvas`, tras la línea del jugador:

```kotlin
                scene.particles.forEach { particle -> add(particle.sortY to { drawParticle(particle, frameNanos) }) }
```

y al final del fichero (mismo aspecto que las texturas que genera `PreloadScene` en la web):

```kotlin
private val CHIP_DARK = Color(0xFF8A5A2B)
private val CHIP_LIGHT = Color(0xFFC89A5E)
private val DUST_COLOR = Color(0xFFD8CDB0)

private fun DrawScope.drawParticle(particle: Particle, now: Long) {
    val at = particle.position(now)
    val center = Offset(at.x.toFloat(), at.y.toFloat())
    val alpha = particle.alpha(now).toFloat()
    when (particle.kind) {
        ParticleKind.WoodChip -> rotate(particle.rotationDegrees.toFloat(), center) {
            val topLeft = Offset(center.x - 1.5f, center.y - 1f)
            drawRect(CHIP_DARK, topLeft, Size(3f, 2f), alpha)
            drawRect(CHIP_LIGHT, topLeft, Size(2f, 1f), alpha)
        }
        ParticleKind.Dust -> drawCircle(DUST_COLOR, radius = 3f * particle.scale(now).toFloat(), center = center, alpha = alpha)
    }
}
```

- [ ] **Step 7: Comprobar en emulador**

Run: `./gradlew :androidApp:installDebug` y talar un árbol y construir la casa: en cada hachazo saltan 8 astillas hacia el jugador y caen; en cada martillazo sube un poco de polvo del frente de la casa. Comparar a ojo con la web abierta al lado.

- [ ] **Step 8: Commit**

```bash
git add androidApp
git commit -m "[PROJECT-X]: Add wood chip and dust particles to the Android forest"
```

---

## Self-review de la fase

- [ ] Se prueba en local: `./gradlew :androidApp:testDebugUnitTest :androidApp:connectedDebugAndroidTest` con un emulador arrancado, la partida manual del Step 6 de la Task 3 y las partículas (Task 4, Step 7). No hay CI para Android (alcance acordado).
- [ ] `androidApp` no importa nada de `com.apergas.rpg.data` (`grep -rn "com.apergas.rpg.data" androidApp/src` vacío).
- [ ] Toda la lógica de juego y textos de juego vienen de `shared`; las únicas cadenas propias son de accesibilidad y de la barra táctil.
- [ ] Mismo bosque que la web (comparar visualmente la zona de inicio con una captura de la web).
- [ ] Mismos tipos de árbol y misma decoración que la web: vienen del nivel compartido; `grep -rn "SeededRandom\|TREE_FRAMES" androidApp/src` vacío.
- [ ] Astillas y polvo con los mismos valores que los emisores de Phaser (tabla de la Task 4).
