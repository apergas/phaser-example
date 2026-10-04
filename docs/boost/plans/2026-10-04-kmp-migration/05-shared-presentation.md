# Fase 5 — Presentación compartida (MVI)

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar la lógica de presentación (`ForestViewModel`, `HudViewModel` y `PlayerViewModel` de TypeScript) a un único `ForestViewModel` Kotlin con contrato MVI, consumido por las tres apps.

**Architecture:** `ForestContract.kt` define `ForestState` (estado que se pinta cada fotograma), `ForestIntent` (entrada) y `ForestEffect` (efectos de un solo uso: animaciones y mensajes). `ForestViewModel` extiende el `ViewModel` multiplataforma de JetBrains, recibe `GameUseCase` y procesa los intents **síncronamente** (bucle de juego). Los textos en español viven en `ForestLabels`.

**Tech Stack:** Kotlin common, kotlinx.coroutines (`StateFlow`, `SharedFlow`), `org.jetbrains.androidx.lifecycle:lifecycle-viewmodel`, kotlinx-coroutines-test.

## Global Constraints

Las de [`README.md`](README.md#global-constraints). En esta fase (convención de presentación de Android): un `ForestContract.kt` con `State` (data class, solo `val`, colecciones inmutables), `Intent` (sealed interface) y `Effect` (sealed interface); estado expuesto como `uiState: StateFlow` con `_uiState` privado; efectos como `uiEffect: SharedFlow` con `_uiEffect` privado; la vista habla con el ViewModel solo por `onIntent()`; sin lógica de negocio en el ViewModel (delegada en `GameUseCase`).

**Desviaciones justificadas** (comentadas en el código):
1. Los intents se procesan síncronamente, sin `viewModelScope.launch(Dispatchers.IO)`: el `Tick` debe avanzar la simulación en el orden de los fotogramas y no hay E/S.
2. Los efectos usan `tryEmit` sobre `MutableSharedFlow(extraBufferCapacity = 64)` en vez de `emit()` (que es `suspend`).
3. La partida se inicia en el constructor (`startGame()`), no con un intent de carga en `onStart`: es síncrona y barata. El mensaje de bienvenida se emite en el primer `Tick`, cuando la vista ya está suscrita a los efectos.

## File Structure

```
shared/src/commonMain/kotlin/com/apergas/rpg/
  presentation/forest/  ForestContract.kt, ForestViewModel.kt, ForestLabels.kt, SpriteNames.kt
  di/GameContainer.kt   (+ makeForestViewModel)
shared/src/commonTest/kotlin/com/apergas/rpg/
  presentation/forest/  ForestViewModelFixture.kt, ForestViewModelTests.kt, SpriteNamesTests.kt
```

---

### Task 1: Contrato y textos

**Files:**
- Create: `presentation/forest/ForestContract.kt`, `presentation/forest/ForestLabels.kt`

**Interfaces:**
- Consumes: `Position`, `BlueprintId`, `Building`, `QuestId` (fase 2).
- Produces (los usan el ViewModel y las tres apps):

```kotlin
data class ForestState(val player: PlayerRenderState, val hud: HudState, val placement: Placement?)
data class PlayerRenderState(val position: Position, val facing: Facing, val pose: PlayerPose)
enum class Facing { Up, Left, Down, Right }
sealed interface PlayerPose {
    data class Idle(val withAxe: Boolean) : PlayerPose
    data class Walk(val withAxe: Boolean) : PlayerPose
    data class Work(val tool: WorkTool, val swingProgress: Double) : PlayerPose
}
enum class WorkTool { Axe, Hammer }
data class HudState(wood: Int, hasAxe: Boolean, questBadge: String, quests: List<QuestItem>, buildItems: List<BuildItem>, isBuildLocked: Boolean)
data class QuestItem(title: String, progressText: String, status: QuestItemStatus)
enum class QuestItemStatus { Done, Current, Pending }
data class BuildItem(blueprint: BlueprintId, name: String, costText: String, missingText: String?, isEnabled: Boolean)
data class Placement(blueprint: BlueprintId, position: Position, isValid: Boolean)
sealed interface ForestIntent { Tick(deltaMs), MapClicked(position, treeId: String?, isSecondary = false), PointerMoved(position), BuildRequested(blueprint), PlacementCancelled }
sealed interface ForestEffect { ItemPickedUp(itemId), TreeHit(treeId, fromX), TreeFelled(treeId, fromX), BuildingPlaced(building), BuildingHammered(buildingId, progress), BuildingCompleted(buildingId), ShowMessage(text) }
object ForestLabels { ... }
```

- [ ] **Step 1: Escribir `ForestContract.kt`**

```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.geometry.Position

/** What the gameplay screen draws every frame. */
data class ForestState(
    val player: PlayerRenderState,
    val hud: HudState,
    /** A building being positioned with the pointer before it is ordered, if any. */
    val placement: Placement?,
)

data class PlayerRenderState(val position: Position, val facing: Facing, val pose: PlayerPose)

enum class Facing { Up, Left, Down, Right }

sealed interface PlayerPose {
    data class Idle(val withAxe: Boolean) : PlayerPose
    data class Walk(val withAxe: Boolean) : PlayerPose
    data class Work(val tool: WorkTool, val swingProgress: Double) : PlayerPose
}

enum class WorkTool { Axe, Hammer }

/** Display-ready HUD content: texts already formatted. */
data class HudState(
    val wood: Int,
    val hasAxe: Boolean,
    val questBadge: String,
    val quests: List<QuestItem>,
    val buildItems: List<BuildItem>,
    /** The build menu is locked while a building is being placed. */
    val isBuildLocked: Boolean,
)

data class QuestItem(val title: String, val progressText: String, val status: QuestItemStatus)

enum class QuestItemStatus { Done, Current, Pending }

data class BuildItem(
    val blueprint: BlueprintId,
    val name: String,
    val costText: String,
    val missingText: String?,
    val isEnabled: Boolean,
)

data class Placement(val blueprint: BlueprintId, val position: Position, val isValid: Boolean)

sealed interface ForestIntent {
    data class Tick(val deltaMs: Double) : ForestIntent
    /** [treeId] is the tree drawn under the pointer, if any: hit-testing sprites is the view's job. */
    data class MapClicked(val position: Position, val treeId: String?, val isSecondary: Boolean = false) : ForestIntent
    data class PointerMoved(val position: Position) : ForestIntent
    data class BuildRequested(val blueprint: BlueprintId) : ForestIntent
    data object PlacementCancelled : ForestIntent
}

/** One-off reactions the view plays once: animations, particles and messages. */
sealed interface ForestEffect {
    data class ItemPickedUp(val itemId: String) : ForestEffect
    data class TreeHit(val treeId: String, val fromX: Double) : ForestEffect
    data class TreeFelled(val treeId: String, val fromX: Double) : ForestEffect
    data class BuildingPlaced(val building: Building) : ForestEffect
    data class BuildingHammered(val buildingId: String, val progress: Double) : ForestEffect
    data class BuildingCompleted(val buildingId: String) : ForestEffect
    data class ShowMessage(val text: String) : ForestEffect
}
```

- [ ] **Step 2: Escribir `ForestLabels.kt`** (mismos textos que `rpg/src/presentation/common/labels.ts`)

```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.quests.QuestId

/** Every player-facing text of the gameplay screen, in one place. */
object ForestLabels {
    const val WOOD = "Madera"
    const val AXE = "Hacha"
    const val BUILD = "Construir"
    const val QUESTS = "Misiones"
    const val QUEST_DONE = "Hecha"

    fun cost(wood: Int) = "$wood de madera"
    fun missing(wood: Int) = "Faltan $wood"

    fun blueprint(id: BlueprintId) = when (id) {
        BlueprintId.House -> "Casa"
    }

    fun questTitle(id: QuestId) = when (id) {
        QuestId.PickUpAxe -> "Recoge el hacha"
        QuestId.GatherWood -> "Consigue al menos 15 de madera"
        QuestId.BuildHouse -> "Construye una casa"
    }

    object Messages {
        const val WELCOME = "Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima."
        const val NEED_AXE = "Necesitas un hacha para talar."
        const val BLOCKED_PATH = "Hay algo en medio. Acércate por otro lado."
        const val PICKED_UP_AXE = "¡Hacha recogida! Haz clic en un árbol para talarlo."
        const val BLOCKED_SITE = "Ahí no cabe. Busca un sitio despejado."
        const val NOT_ENOUGH_WOOD = "No tienes madera suficiente."
        const val BUILDING_STARTED = "Manos a la obra…"
        const val ALL_QUESTS_COMPLETED = "¡Has completado todas las misiones!"

        fun woodGained(wood: Int) = "+$wood de madera"
        fun placing(name: String) = "Elige dónde construir: $name. Clic derecho o Esc para cancelar."
        fun buildingCompleted(name: String) = "¡$name construida!"
        fun questCompleted(title: String) = "Misión completada: $title"
    }

    /** Bar shown on touch screens while placing a building (the web uses right click / Esc instead). */
    object Placement {
        const val CONFIRM = "Construir aquí"
        const val CANCEL = "Cancelar"
    }

    /** Screen-reader descriptions (TalkBack / VoiceOver). */
    object Accessibility {
        const val GAME_WORLD = "Mundo de juego: bosque con árboles, el personaje y los edificios"
    }
}
```

- [ ] **Step 3: `SpriteNames.kt` y su test** — único sitio donde un tipo del nivel se convierte en nombre de sprite del atlas (`forest.json`); lo usan la web (vía `jsMain`), Android e iOS.

`SpriteNamesTests.kt`:
```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.tree.TreeKind
import kotlin.test.Test
import kotlin.test.assertEquals

class SpriteNamesTests {
    @Test
    fun testWhenNamingSpritesThenFollowsTheAtlasFrameNames() {
        // given
        val tree = TreeKind.Broad
        val decoration = DecorationKind.TallGrass

        // when
        val treeName = SpriteNames.tree(tree)
        val decorationName = SpriteNames.decoration(decoration)

        // then
        assertEquals("tree-broad", treeName)
        assertEquals("decor-tall-grass", decorationName)
    }
}
```

`SpriteNames.kt`:
```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.tree.TreeKind

/** Atlas frame names (forest.json) for what the level places. Shared so every app draws the same art. */
object SpriteNames {
    fun tree(kind: TreeKind): String = "tree-${kebab(kind.name)}"
    fun decoration(kind: DecorationKind): String = "decor-${kebab(kind.name)}"

    private fun kebab(name: String): String = name.replace(Regex("(?<!^)([A-Z])"), "-$1").lowercase()
}
```

- [ ] **Step 4: Compilar y ejecutar**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add shared forest screen contract and labels"
```

---

### Task 2: `ForestViewModel`

**Files:**
- Create: `presentation/forest/ForestViewModel.kt`
- Modify: `di/GameContainer.kt` (añadir `makeForestViewModel()`)
- Test: `presentation/forest/ForestViewModelFixture.kt`, `ForestViewModelTests.kt`

**Interfaces:**
- Consumes: `GameUseCase` (fase 4), contrato y labels (Task 1).
- Produces:
```kotlin
class ForestViewModel(gameUseCase: GameUseCase) : ViewModel() {
    val uiState: StateFlow<ForestState>
    val uiEffect: SharedFlow<ForestEffect>
    fun onIntent(intent: ForestIntent)
    /** The world as it is now, to build the scene from scratch. */
    fun worldSnapshot(): WorldSnapshot
}
// GameContainer:
fun makeForestViewModel(): ForestViewModel
```

- [ ] **Step 1: Fixture de test**

`ForestViewModelFixture.kt`:
```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.repositories.level.LevelRepositoryMock
import com.apergas.rpg.domain.repositories.session.GameSessionRepositoryMock
import com.apergas.rpg.domain.usecases.game.GameUseCaseImpl
import com.apergas.rpg.domain.world.World
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch

/** A view model on the real use case, whose level is [world] (kept so tests can adjust it). */
fun forestViewModelFor(world: World): ForestViewModel {
    val levelRepository = LevelRepositoryMock().apply { makeWorld = { world } }
    return ForestViewModel(GameUseCaseImpl(levelRepository, GameSessionRepositoryMock()))
}

/**
 * Collects every effect while the test runs: pass `backgroundScope` and an `UnconfinedTestDispatcher`
 * so the collector is subscribed before the first intent and receives effects synchronously.
 */
fun ForestViewModel.collectEffects(scope: CoroutineScope, dispatcher: CoroutineDispatcher): List<ForestEffect> {
    val effects = mutableListOf<ForestEffect>()
    scope.launch(dispatcher) { uiEffect.toList(effects) }
    return effects
}

fun ForestViewModel.tickFor(totalMs: Double) {
    var elapsed = 0.0
    while (elapsed < totalMs) {
        onIntent(ForestIntent.Tick(16.0))
        elapsed += 16.0
    }
}
```

- [ ] **Step 2: Tests** (equivalentes a `rpg/tests/presentation/screens/forest/ForestViewModel.test.ts`)

```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.item.mock
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.rules.Rules
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class ForestViewModelTests {
    @Test
    fun testWhenFirstTickThenGreetsAndShowsTheQuestList() = runTest {
        // given
        val sut = forestViewModelFor(World.mock())
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))

        // when
        sut.onIntent(ForestIntent.Tick(16.0))

        // then
        val hud = sut.uiState.value.hud
        assertContains(effects, ForestEffect.ShowMessage("Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima."))
        assertEquals("0/3", hud.questBadge)
        assertEquals(QuestItem("Recoge el hacha", "", QuestItemStatus.Current), hud.quests[0])
        assertEquals(QuestItem("Consigue al menos 15 de madera", "0/15", QuestItemStatus.Pending), hud.quests[1])
    }

    @Test
    fun testWhenClickingEmptyGroundThenWalksThereFacingIt() = runTest {
        // given
        val sut = forestViewModelFor(World.mock())

        // when
        sut.onIntent(ForestIntent.MapClicked(Position(150.0, 100.0), treeId = null))
        sut.tickFor(1000.0)

        // then
        assertEquals(Position(150.0, 100.0), sut.uiState.value.player.position)
        assertEquals(Facing.Right, sut.uiState.value.player.facing)
    }

    @Test
    fun testWhenClickingATreeWithoutAxeThenExplainsWhy() = runTest {
        // given
        val sut = forestViewModelFor(World.mock(trees = listOf(Tree.mock.copy(position = Position(300.0, 100.0)))))
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))

        // when
        sut.onIntent(ForestIntent.MapClicked(Position(300.0, 80.0), treeId = "tree-1"))

        // then
        assertContains(effects, ForestEffect.ShowMessage("Necesitas un hacha para talar."))
    }

    @Test
    fun testWhenPickingUpTheAxeThenPlaysEffectAnnouncesAndHoldsIt() = runTest {
        // given
        val sut = forestViewModelFor(World.mock(items = listOf(GroundItem.mock.copy(position = Position(110.0, 100.0)))))
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))

        // when
        sut.onIntent(ForestIntent.MapClicked(Position(110.0, 100.0), treeId = null))
        sut.tickFor(300.0)

        // then
        assertContains(effects, ForestEffect.ItemPickedUp("axe-1"))
        assertContains(effects, ForestEffect.ShowMessage("¡Hacha recogida! Haz clic en un árbol para talarlo."))
        assertTrue(sut.uiState.value.hud.hasAxe)
        assertEquals(PlayerPose.Idle(withAxe = true), sut.uiState.value.player.pose)
    }

    @Test
    fun testWhenChoppingThenFacesTheTreeSwingsAndReportsHitsAndTheFall() = runTest {
        // given
        val world = World.mock(trees = listOf(Tree.mock))
        world.updatePlayer { it.withInventory(it.inventory.addTool(ToolKind.Axe)) }
        val sut = forestViewModelFor(world)
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))

        // when
        sut.onIntent(ForestIntent.MapClicked(Position(200.0, 80.0), treeId = "tree-1"))
        sut.tickFor(1500.0)
        val facing = sut.uiState.value.player.facing
        val pose = sut.uiState.value.player.pose
        sut.tickFor(Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE)

        // then
        assertEquals(Facing.Right, facing)
        assertIs<PlayerPose.Work>(pose)
        assertEquals(WorkTool.Axe, pose.tool)
        assertEquals(5, effects.count { it is ForestEffect.TreeHit })
        assertContains(effects, ForestEffect.TreeFelled("tree-1", fromX = 180.0))
        assertEquals(6, sut.uiState.value.hud.wood)
    }

    @Test
    fun testWhenWoodIsNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace() = runTest {
        // given
        val world = World.mock()
        world.updatePlayer { it.withInventory(it.inventory.addWood(10)) }
        val sut = forestViewModelFor(world)
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))
        sut.onIntent(ForestIntent.Tick(16.0))

        // when
        sut.onIntent(ForestIntent.BuildRequested(BlueprintId.House))

        // then
        assertEquals(
            listOf(BuildItem(BlueprintId.House, "Casa", "15 de madera", "Faltan 5", isEnabled = false)),
            sut.uiState.value.hud.buildItems,
        )
        assertNull(sut.uiState.value.placement)
        assertContains(effects, ForestEffect.ShowMessage("No tienes madera suficiente."))
    }

    @Test
    fun testWhenPlacingThenPreviewsValidityIgnoresBlockedSitesAndPlacesOnAFreeOne() = runTest {
        // given
        val world = World.mock(trees = listOf(Tree.mock.copy(position = Position(400.0, 400.0))))
        world.updatePlayer { it.withInventory(it.inventory.addWood(15)) }
        val sut = forestViewModelFor(world)
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))
        sut.onIntent(ForestIntent.BuildRequested(BlueprintId.House))

        // when
        sut.onIntent(ForestIntent.PointerMoved(Position(410.0, 400.0)))
        val preview = sut.uiState.value.placement
        val isLockedWhilePlacing = sut.uiState.value.hud.isBuildLocked
        sut.onIntent(ForestIntent.MapClicked(Position(410.0, 400.0), treeId = null))
        val stillPlacing = sut.uiState.value.placement
        sut.onIntent(ForestIntent.MapClicked(Position(250.0, 250.0), treeId = null))

        // then
        assertEquals(Placement(BlueprintId.House, Position(410.0, 400.0), isValid = false), preview)
        assertTrue(isLockedWhilePlacing)
        assertNotNull(stillPlacing)
        assertContains(effects, ForestEffect.ShowMessage("Ahí no cabe. Busca un sitio despejado."))
        val placed = effects.filterIsInstance<ForestEffect.BuildingPlaced>().single()
        assertEquals("building-1", placed.building.id)
        assertEquals(Position(250.0, 250.0), placed.building.position)
        assertNull(sut.uiState.value.placement)
    }

    @Test
    fun testWhenSecondaryClickWhilePlacingThenCancelsWithoutBuilding() = runTest {
        // given
        val world = World.mock()
        world.updatePlayer { it.withInventory(it.inventory.addWood(15)) }
        val sut = forestViewModelFor(world)
        sut.onIntent(ForestIntent.BuildRequested(BlueprintId.House))

        // when
        sut.onIntent(ForestIntent.MapClicked(Position(500.0, 500.0), treeId = null, isSecondary = true))

        // then
        assertNull(sut.uiState.value.placement)
        assertTrue(world.buildings.isEmpty())
        assertEquals(false, sut.uiState.value.hud.isBuildLocked)
    }

    @Test
    fun testWhenTheLastQuestIsCompletedThenShowsTheFinalMessage() = runTest {
        // given
        val world = World.mock()
        world.updatePlayer { it.withInventory(it.inventory.addTool(ToolKind.Axe).addWood(15)) }
        val sut = forestViewModelFor(world)
        val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))
        sut.onIntent(ForestIntent.Tick(16.0))
        val badgeBefore = sut.uiState.value.hud.questBadge

        // when
        sut.onIntent(ForestIntent.BuildRequested(BlueprintId.House))
        sut.onIntent(ForestIntent.MapClicked(Position(300.0, 100.0), treeId = null))
        sut.tickFor(6000 + Rules.HAMMER_INTERVAL_MS * 8)

        // then
        assertEquals("2/3", badgeBefore)
        assertContains(effects, ForestEffect.BuildingCompleted("building-1"))
        assertEquals("3/3", sut.uiState.value.hud.questBadge)
        assertEquals(ForestEffect.ShowMessage("¡Has completado todas las misiones!"), effects.filterIsInstance<ForestEffect.ShowMessage>().last())
    }
}
```

- [ ] **Step 3: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.presentation.*"`
Expected: FAIL — `Unresolved reference: ForestViewModel`.

- [ ] **Step 4: Implementar `ForestViewModel.kt`**

```kotlin
package com.apergas.rpg.presentation.forest

import androidx.lifecycle.ViewModel
import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionRejection
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.PlayerActivity
import com.apergas.rpg.domain.entities.game.PlayerStatus
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.usecases.game.GameUseCase
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.math.abs

/**
 * Presentation logic of the gameplay screen, shared by every platform: what a click means, the
 * placement mode, which message each event shows and which effect the view plays.
 *
 * Intents are handled synchronously (no `viewModelScope.launch`) because `Tick` must advance the
 * simulation in frame order on the drawing thread, and effects use `tryEmit` for the same reason.
 */
class ForestViewModel(private val gameUseCase: GameUseCase) : ViewModel() {
    private var lastPosition: Position
    private var facing = Facing.Down
    private var placement: Placement? = null
    private var hasGreeted = false

    private val _uiState: MutableStateFlow<ForestState>
    val uiState: StateFlow<ForestState>

    private val _uiEffect = MutableSharedFlow<ForestEffect>(extraBufferCapacity = 64)
    val uiEffect: SharedFlow<ForestEffect> = _uiEffect.asSharedFlow()

    init {
        gameUseCase.startGame()
        lastPosition = gameUseCase.playerStatus().position
        _uiState = MutableStateFlow(buildState())
        uiState = _uiState.asStateFlow()
    }

    fun worldSnapshot(): WorldSnapshot = gameUseCase.worldSnapshot()

    fun onIntent(intent: ForestIntent) {
        when (intent) {
            is ForestIntent.Tick -> tick(intent.deltaMs)
            is ForestIntent.MapClicked -> mapClicked(intent)
            is ForestIntent.PointerMoved -> pointerMoved(intent.position)
            is ForestIntent.BuildRequested -> buildRequested(intent.blueprint)
            ForestIntent.PlacementCancelled -> placement = null
        }
        _uiState.value = buildState()
    }

    private fun tick(deltaMs: Double) {
        if (!hasGreeted) {
            hasGreeted = true
            show(ForestLabels.Messages.WELCOME)
        }
        val fromX = gameUseCase.playerStatus().position.x
        gameUseCase.advance(deltaMs).forEach { react(it, fromX) }
    }

    private fun mapClicked(intent: ForestIntent.MapClicked) {
        val current = placement
        if (current != null) {
            if (intent.isSecondary) placement = null else place(current.blueprint, intent.position)
            return
        }
        if (intent.isSecondary) return
        if (intent.treeId != null) {
            if (gameUseCase.chopTree(intent.treeId) == ChopResult.NoAxe) show(ForestLabels.Messages.NEED_AXE)
        } else {
            gameUseCase.movePlayerTo(intent.position.x, intent.position.y)
        }
    }

    private fun pointerMoved(position: Position) {
        val current = placement ?: return
        placement = current.copy(position = position, isValid = gameUseCase.canPlaceBuilding(current.blueprint, position.x, position.y))
    }

    private fun buildRequested(blueprint: BlueprintId) {
        val option = gameUseCase.buildOptions().firstOrNull { it.blueprint == blueprint }
        if (option == null || !option.isAffordable) return show(ForestLabels.Messages.NOT_ENOUGH_WOOD)
        placement = Placement(blueprint, lastPosition, isValid = false)
        pointerMoved(lastPosition)
        show(ForestLabels.Messages.placing(ForestLabels.blueprint(blueprint)))
    }

    private fun place(blueprint: BlueprintId, position: Position) {
        when (val result = gameUseCase.constructBuilding(blueprint, position.x, position.y)) {
            is ConstructionResult.Started -> {
                placement = null
                show(ForestLabels.Messages.BUILDING_STARTED)
                _uiEffect.tryEmit(ForestEffect.BuildingPlaced(result.building))
            }
            is ConstructionResult.Rejected -> when (result.reason) {
                ConstructionRejection.Blocked -> show(ForestLabels.Messages.BLOCKED_SITE)
                ConstructionRejection.NotEnoughWood -> {
                    placement = null
                    show(ForestLabels.Messages.NOT_ENOUGH_WOOD)
                }
            }
        }
    }

    private fun react(event: GameEvent, fromX: Double) {
        when (event) {
            is GameEvent.ItemPickedUp -> {
                show(ForestLabels.Messages.PICKED_UP_AXE)
                _uiEffect.tryEmit(ForestEffect.ItemPickedUp(event.itemId))
            }
            GameEvent.PlayerBlocked -> show(ForestLabels.Messages.BLOCKED_PATH)
            is GameEvent.TreeHit -> _uiEffect.tryEmit(ForestEffect.TreeHit(event.treeId, fromX))
            is GameEvent.TreeFelled -> {
                show(ForestLabels.Messages.woodGained(event.wood))
                _uiEffect.tryEmit(ForestEffect.TreeFelled(event.treeId, fromX))
            }
            is GameEvent.BuildingHammered -> _uiEffect.tryEmit(ForestEffect.BuildingHammered(event.buildingId, event.progress))
            is GameEvent.BuildingCompleted -> {
                show(ForestLabels.Messages.buildingCompleted(ForestLabels.blueprint(event.blueprint)))
                _uiEffect.tryEmit(ForestEffect.BuildingCompleted(event.buildingId))
            }
            is GameEvent.QuestCompleted -> {
                val allDone = gameUseCase.quests().all { it.isCompleted }
                show(
                    if (allDone) ForestLabels.Messages.ALL_QUESTS_COMPLETED
                    else ForestLabels.Messages.questCompleted(ForestLabels.questTitle(event.questId)),
                )
            }
        }
    }

    private fun show(text: String) {
        _uiEffect.tryEmit(ForestEffect.ShowMessage(text))
    }

    private fun buildState(): ForestState {
        val status = gameUseCase.playerStatus()
        return ForestState(
            player = playerRenderState(status),
            hud = hudState(status, gameUseCase.quests()),
            placement = placement,
        )
    }

    /** Facing follows the movement; while working it faces the target instead. */
    private fun playerRenderState(status: PlayerStatus): PlayerRenderState {
        val dx = status.position.x - lastPosition.x
        val dy = status.position.y - lastPosition.y
        val isMoving = dx != 0.0 || dy != 0.0
        lastPosition = status.position

        val isWorking = status.activity == PlayerActivity.Chopping || status.activity == PlayerActivity.Constructing
        val target = status.target
        if (isWorking && target != null) facing = facingFor(target.x - status.position.x, target.y - status.position.y)
        else if (isMoving) facing = facingFor(dx, dy)

        val pose = when {
            isWorking -> PlayerPose.Work(
                tool = if (status.activity == PlayerActivity.Chopping) WorkTool.Axe else WorkTool.Hammer,
                swingProgress = status.swingProgress,
            )
            isMoving -> PlayerPose.Walk(withAxe = status.hasAxe)
            else -> PlayerPose.Idle(withAxe = status.hasAxe)
        }
        return PlayerRenderState(status.position, facing, pose)
    }

    private fun hudState(status: PlayerStatus, quests: List<QuestProgress>): HudState = HudState(
        wood = status.wood,
        hasAxe = status.hasAxe,
        questBadge = "${quests.count { it.isCompleted }}/${quests.size}",
        quests = quests.map { quest ->
            QuestItem(
                title = ForestLabels.questTitle(quest.id),
                progressText = when {
                    quest.isCompleted -> ForestLabels.QUEST_DONE
                    quest.target > 1 -> "${quest.progress}/${quest.target}"
                    else -> ""
                },
                status = when {
                    quest.isCompleted -> QuestItemStatus.Done
                    quest.isCurrent -> QuestItemStatus.Current
                    else -> QuestItemStatus.Pending
                },
            )
        },
        buildItems = gameUseCase.buildOptions().map { option ->
            BuildItem(
                blueprint = option.blueprint,
                name = ForestLabels.blueprint(option.blueprint),
                costText = ForestLabels.cost(option.woodCost),
                missingText = if (option.isAffordable) null else ForestLabels.missing(option.woodCost - status.wood),
                isEnabled = option.isAffordable,
            )
        },
        isBuildLocked = placement != null,
    )
}

private fun facingFor(dx: Double, dy: Double): Facing = when {
    abs(dx) > abs(dy) -> if (dx < 0) Facing.Left else Facing.Right
    else -> if (dy < 0) Facing.Up else Facing.Down
}
```

- [ ] **Step 5: Añadir la factoría a `GameContainer`**

```kotlin
    fun makeForestViewModel(): ForestViewModel = ForestViewModel(makeGameUseCase())
```
(con `import com.apergas.rpg.presentation.forest.ForestViewModel`)

- [ ] **Step 6: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS en los tres targets.

**Si en la fase 1 `lifecycle-viewmodel` no estaba disponible para JS:** quitar `: ViewModel()` y el import de `androidx.lifecycle.ViewModel` de `ForestViewModel`. Android (fase 7) lo envolverá en `ForestAndroidViewModel(val forest: ForestViewModel) : androidx.lifecycle.ViewModel()`. Los tests no cambian.

- [ ] **Step 7: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add shared ForestViewModel with MVI contract"
```

---

## Self-review de la fase

- [ ] Los 10 tests de `ForestViewModel.test.ts` tienen su equivalente (el de `serial` de mensajes desaparece: los mensajes son efectos y cada uno llega aunque el texto se repita).
- [ ] `ForestViewModel` solo importa `domain` (casos de uso y entidades), nunca `data`.
- [ ] Ningún texto en español fuera de `ForestLabels`, tampoco en las apps (botones táctiles y accesibilidad incluidos). Única excepción: el nombre de la app, que lo lee el sistema antes de arrancar el código (`app_name` en Android, `Info.plist` en iOS, `<title>` en la web).
- [ ] Si llegan más idiomas: `ForestLabels` pasa a ser una interfaz con una implementación por idioma (`SpanishLabels`, `EnglishLabels`…) y cada app indica el idioma del dispositivo al crear el `ForestViewModel`; el resto del código no cambia.
