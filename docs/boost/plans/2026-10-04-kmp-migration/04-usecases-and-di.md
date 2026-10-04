# Fase 4 — Caso de uso `GameUseCase` y contenedor `GameContainer`

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reunir los seis casos de uso actuales de TypeScript en un único `GameUseCase` (interfaz + `GameUseCaseImpl`, convención de equipo: un caso de uso por feature) y montar el grafo de dependencias compartido en `GameContainer`.

**Architecture:** `GameUseCaseImpl` recibe `LevelRepository` y `GameSessionRepository`; pide la sesión en cada llamada (iniciar o cargar partida = guardar otra sesión). Devuelve entidades de dominio inmutables. `GameContainer` (patrón `Container` de iOS) construye DataSource → Repository → UseCase; la sesión es única para toda la app.

**Tech Stack:** Kotlin common, kotlin.test.

## Global Constraints

Las de [`README.md`](README.md#global-constraints). En esta fase: una sola interfaz `GameUseCase` con todas las operaciones; el caso de uso depende de interfaces de repositorio, nunca de implementaciones; mocks de repositorio escritos a mano con `error` y flags `<method>Called`.

## File Structure

```
shared/src/commonMain/kotlin/com/apergas/rpg/
  domain/usecases/game/  GameUseCase.kt, GameUseCaseImpl.kt
  di/                    GameContainer.kt
shared/src/commonTest/kotlin/com/apergas/rpg/
  domain/repositories/level/LevelRepositoryMock.kt
  domain/repositories/session/GameSessionRepositoryMock.kt
  domain/usecases/game/GameUseCaseImplTests.kt
  di/GameContainerTests.kt
```

---

### Task 1: `GameUseCase` + `GameUseCaseImpl`

**Files:**
- Create: `domain/usecases/game/GameUseCase.kt`, `GameUseCaseImpl.kt`
- Test: `domain/repositories/level/LevelRepositoryMock.kt`, `domain/repositories/session/GameSessionRepositoryMock.kt`, `domain/usecases/game/GameUseCaseImplTests.kt`

**Interfaces:**
- Consumes: `LevelRepository`, `GameSessionRepository`, `GameSession`, `World`, `QuestLog`, `Blueprints`, entidades de `entities/game/` (fase 2).
- Produces:
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

- [ ] **Step 1: Mocks de repositorio**

`LevelRepositoryMock.kt`:
```kotlin
package com.apergas.rpg.domain.repositories.level

import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock

class LevelRepositoryMock : LevelRepository {
    var error: Throwable? = null
    /** A fresh world on every load, like a real level source. */
    var makeWorld: () -> World = { World.mock() }
    var loadCalled = false

    override fun load(): World {
        loadCalled = true
        error?.let { throw it }
        return makeWorld()
    }
}
```

`GameSessionRepositoryMock.kt`:
```kotlin
package com.apergas.rpg.domain.repositories.session

import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.errors.AppError

class GameSessionRepositoryMock : GameSessionRepository {
    var error: Throwable? = null
    var session: GameSession? = null
    var currentCalled = false
    var saveCalled = false

    override fun current(): GameSession {
        currentCalled = true
        error?.let { throw it }
        return session ?: throw AppError.GeneralError()
    }

    override fun save(session: GameSession) {
        saveCalled = true
        error?.let { throw it }
        this.session = session
    }
}
```

- [ ] **Step 2: Tests**

```kotlin
package com.apergas.rpg.domain.usecases.game

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.game.BuildOption
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.entities.game.PlayerActivity
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.item.mock
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.quests.QuestId
import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.repositories.level.LevelRepositoryMock
import com.apergas.rpg.domain.repositories.session.GameSessionRepositoryMock
import com.apergas.rpg.domain.rules.Rules
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertTrue

class GameUseCaseImplTests {
    private lateinit var levelRepository: LevelRepositoryMock
    private lateinit var sessionRepository: GameSessionRepositoryMock
    private lateinit var sut: GameUseCaseImpl

    @BeforeTest
    fun setUp() {
        levelRepository = LevelRepositoryMock()
        sessionRepository = GameSessionRepositoryMock()
        sut = GameUseCaseImpl(levelRepository, sessionRepository)
    }

    private fun playIn(world: World) {
        sessionRepository.session = GameSession(world, QuestLog())
    }

    private fun advanceFor(totalMs: Double): List<GameEvent> {
        val events = mutableListOf<GameEvent>()
        var elapsed = 0.0
        while (elapsed < totalMs) {
            events += sut.advance(16.0)
            elapsed += 16.0
        }
        return events
    }

    @Test
    fun testWhenStartGameThenSavesLevelWorldWithFreshQuests() {
        // given
        levelRepository.makeWorld = { World.mock(trees = listOf(Tree.mock)) }

        // when
        sut.startGame()

        // then
        assertTrue(levelRepository.loadCalled)
        assertTrue(sessionRepository.saveCalled)
        assertEquals(listOf("tree-1"), sut.worldSnapshot().trees.map { it.id })
        assertTrue(sut.quests().none { it.isCompleted })
    }

    @Test
    fun testWhenStartGameWithLevelErrorThenErrorPropagates() {
        // given
        levelRepository.error = AppError.LevelError.InvalidLevel("missing width")

        // when / then
        assertFailsWith<AppError.LevelError.InvalidLevel> { sut.startGame() }
        assertEquals(false, sessionRepository.saveCalled)
    }

    @Test
    fun testWhenNoGameInProgressThenQueriesFailWithGeneralError() {
        // given
        sessionRepository.session = null

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.playerStatus() }
    }

    @Test
    fun testWhenMovePlayerAndAdvanceThenPlayerReachesThePoint() {
        // given
        playIn(World.mock(player = Player.mock.copy(position = Position(50.0, 50.0))))

        // when
        sut.movePlayerTo(50.0, 150.0)
        sut.advance(1000.0)

        // then
        assertEquals(Position(50.0, 150.0), sut.playerStatus().position)
    }

    @Test
    fun testWhenPlayingTheWholeLoopThenHouseIsBuiltAndQuestsAreCompleted() {
        // given
        playIn(
            World.mock(
                items = listOf(GroundItem.mock.copy(position = Position(120.0, 100.0))),
                trees = listOf(
                    Tree.mock,
                    Tree.mock.copy(id = "tree-2", position = Position(200.0, 200.0)),
                    Tree.mock.copy(id = "tree-3", position = Position(100.0, 200.0)),
                ),
            ),
        )
        val chopTime = 2000 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE

        // when
        val withoutAxe = sut.chopTree("tree-1")
        sut.movePlayerTo(125.0, 100.0)
        advanceFor(500.0)
        val chopResults = listOf("tree-1", "tree-2", "tree-3").map { treeId ->
            sut.chopTree(treeId).also { advanceFor(chopTime) }
        }
        val woodAfterChopping = sut.playerStatus().wood
        val construction = sut.constructBuilding(BlueprintId.House, 400.0, 400.0)
        val events = advanceFor(6000 + Rules.HAMMER_INTERVAL_MS * 8)

        // then
        assertEquals(ChopResult.NoAxe, withoutAxe)
        assertEquals(listOf(ChopResult.Ok, ChopResult.Ok, ChopResult.Ok), chopResults)
        assertEquals(18, woodAfterChopping)
        assertIs<ConstructionResult.Started>(construction)
        assertContains(events, GameEvent.BuildingCompleted("building-1", BlueprintId.House))
        assertContains(events, GameEvent.QuestCompleted(QuestId.BuildHouse))
        assertEquals(3, sut.playerStatus().wood)
        assertTrue(sut.quests().all { it.isCompleted })
    }

    @Test
    fun testWhenPickingUpTheAxeThenQuestIsCompletedAndNextOneIsCurrent() {
        // given
        playIn(World.mock(items = listOf(GroundItem.mock.copy(position = Position(110.0, 100.0)))))

        // when
        sut.movePlayerTo(110.0, 100.0)
        val events = sut.advance(200.0)

        // then
        assertContains(events, GameEvent.QuestCompleted(QuestId.PickUpAxe))
        assertEquals(
            QuestProgress(QuestId.GatherWood, progress = 0, target = 15, isCompleted = false, isCurrent = true),
            sut.quests()[1],
        )
    }

    @Test
    fun testWhenChoppingHalfASwingThenStatusReportsChoppingProgressAndTarget() {
        // given
        val player = Player.mock.copy(inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        playIn(World.mock(player = player, trees = listOf(Tree.mock.copy(position = Position(120.0, 100.0)))))
        sut.chopTree("tree-1")

        // when
        sut.advance(Rules.CHOP_INTERVAL_MS / 2)
        val status = sut.playerStatus()

        // then
        assertEquals(PlayerActivity.Chopping, status.activity)
        assertEquals(0.5, status.swingProgress)
        assertEquals(Position(120.0, 100.0), status.target)
        assertTrue(status.hasAxe)
    }

    @Test
    fun testWhenWoodIsNotEnoughThenHouseIsNotAffordable() {
        // given
        playIn(World.mock(player = Player.mock.copy(inventory = Player.mock.inventory.addWood(10))))

        // when
        val options = sut.buildOptions()

        // then
        assertEquals(listOf(BuildOption(BlueprintId.House, woodCost = 15, isAffordable = false)), options)
    }

    @Test
    fun testWhenCheckingABlockedSiteThenCannotPlace() {
        // given
        playIn(World.mock(trees = listOf(Tree.mock.copy(position = Position(400.0, 400.0)))))

        // when
        val onTree = sut.canPlaceBuilding(BlueprintId.House, 410.0, 400.0)
        val onGrass = sut.canPlaceBuilding(BlueprintId.House, 600.0, 600.0)

        // then
        assertEquals(false, onTree)
        assertEquals(true, onGrass)
    }
}
```

- [ ] **Step 3: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.domain.usecases.*"`
Expected: FAIL — `Unresolved reference: GameUseCaseImpl`.

- [ ] **Step 4: Implementar**

`GameUseCase.kt`:
```kotlin
package com.apergas.rpg.domain.usecases.game

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.game.BuildOption
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.PlayerStatus
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.game.WorldSnapshot

/**
 * Every operation of the game. Synchronous on purpose: the simulation advances frame by frame on
 * the thread that draws, and there is no I/O.
 */
interface GameUseCase {
    fun startGame()
    fun movePlayerTo(x: Double, y: Double)
    fun chopTree(treeId: String): ChopResult
    fun canPlaceBuilding(blueprint: BlueprintId, x: Double, y: Double): Boolean
    fun constructBuilding(blueprint: BlueprintId, x: Double, y: Double): ConstructionResult
    /** Advances the simulation and returns what happened, including completed quests. */
    fun advance(deltaMs: Double): List<GameEvent>
    fun playerStatus(): PlayerStatus
    fun worldSnapshot(): WorldSnapshot
    fun buildOptions(): List<BuildOption>
    fun quests(): List<QuestProgress>
}
```

`GameUseCaseImpl.kt`:
```kotlin
package com.apergas.rpg.domain.usecases.game

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.building.Blueprints
import com.apergas.rpg.domain.entities.game.BuildOption
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.entities.game.PlayerActivity
import com.apergas.rpg.domain.entities.game.PlayerStatus
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.game.WorldSnapshot
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.repositories.level.LevelRepository
import com.apergas.rpg.domain.repositories.session.GameSessionRepository
import com.apergas.rpg.domain.world.World

class GameUseCaseImpl(
    private val levelRepository: LevelRepository,
    private val sessionRepository: GameSessionRepository,
) : GameUseCase {
    private val world: World get() = sessionRepository.current().world

    override fun startGame() {
        sessionRepository.save(GameSession(levelRepository.load(), QuestLog()))
    }

    override fun movePlayerTo(x: Double, y: Double) = world.movePlayerTo(Position(x, y))

    override fun chopTree(treeId: String): ChopResult = world.orderChop(treeId)

    override fun canPlaceBuilding(blueprint: BlueprintId, x: Double, y: Double): Boolean =
        world.canPlace(Blueprints.of(blueprint), Position(x, y))

    override fun constructBuilding(blueprint: BlueprintId, x: Double, y: Double): ConstructionResult =
        world.orderConstruction(Blueprints.of(blueprint), Position(x, y))

    override fun advance(deltaMs: Double): List<GameEvent> {
        val (world, quests) = sessionRepository.current()
        return world.advance(deltaMs) + quests.update(world)
    }

    override fun playerStatus(): PlayerStatus {
        val world = world
        val player = world.player
        return PlayerStatus(
            position = player.position,
            activity = player.activity.toPlayerActivity(),
            target = world.playerTarget,
            swingProgress = world.workProgress,
            wood = player.inventory.wood,
            hasAxe = player.inventory.hasTool(ToolKind.Axe),
        )
    }

    override fun worldSnapshot(): WorldSnapshot {
        val world = world
        return WorldSnapshot(world.width, world.height, world.trees, world.items, world.decorations, world.buildings)
    }

    override fun buildOptions(): List<BuildOption> {
        val wood = world.player.inventory.wood
        return Blueprints.all.map { BuildOption(it.id, it.woodCost, isAffordable = wood >= it.woodCost) }
    }

    override fun quests(): List<QuestProgress> {
        val (world, quests) = sessionRepository.current()
        return quests.status(world)
    }
}

/** How each kind of work is shown to adapters; the `when` fails to compile when a new intent is added. */
private fun Activity.toPlayerActivity(): PlayerActivity = when (this) {
    Activity.Idle -> PlayerActivity.Idle
    is Activity.Walking -> PlayerActivity.Walking
    is Activity.Working -> when (intent) {
        is Intent.Chop -> PlayerActivity.Chopping
        is Intent.Construct -> PlayerActivity.Constructing
    }
}
```

- [ ] **Step 5: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add GameUseCase covering every game operation"
```

---

### Task 2: `GameContainer`

**Files:**
- Create: `shared/src/commonMain/kotlin/com/apergas/rpg/di/GameContainer.kt`
- Test: `shared/src/commonTest/kotlin/com/apergas/rpg/di/GameContainerTests.kt`

**Interfaces:**
- Consumes: todas las implementaciones de `data/` (fase 3) y `GameUseCaseImpl` (Task 1).
- Produces: `object GameContainer { fun makeGameUseCase(): GameUseCase }` — todas las instancias comparten la misma sesión. La fase 5 añade `makeForestViewModel()`.

- [ ] **Step 1: Test de integración**

```kotlin
package com.apergas.rpg.di

import com.apergas.rpg.domain.entities.tree.TreeKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GameContainerTests {
    @Test
    fun testWhenStartingAGameThenTheProceduralForestIsLoaded() {
        // given
        val gameUseCase = GameContainer.makeGameUseCase()

        // when
        gameUseCase.startGame()
        val snapshot = gameUseCase.worldSnapshot()

        // then
        assertEquals(70, snapshot.trees.size)
        assertEquals(388, snapshot.trees.sumOf { it.woodYield })
        assertEquals(TreeKind.Broad, snapshot.trees.first().kind)
        assertTrue(snapshot.decorations.size >= 40)
    }

    @Test
    fun testWhenTwoUseCasesAreMadeThenTheyShareTheSameGame() {
        // given
        val first = GameContainer.makeGameUseCase()
        val second = GameContainer.makeGameUseCase()
        first.startGame()

        // when
        first.movePlayerTo(800.0, 500.0)
        first.advance(2000.0)

        // then
        assertEquals(500.0, second.playerStatus().position.y)
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.di.*"`
Expected: FAIL — `Unresolved reference: GameContainer`.

- [ ] **Step 3: Implementar**

```kotlin
package com.apergas.rpg.di

import com.apergas.rpg.data.datasources.local.level.LevelLocalDataSourceImpl
import com.apergas.rpg.data.datasources.local.session.GameSessionLocalDataSourceImpl
import com.apergas.rpg.data.errors.DataErrorHandlerImpl
import com.apergas.rpg.data.repositories.level.LevelRepositoryImpl
import com.apergas.rpg.data.repositories.session.GameSessionRepositoryImpl
import com.apergas.rpg.domain.repositories.session.GameSessionRepository
import com.apergas.rpg.domain.usecases.game.GameUseCase
import com.apergas.rpg.domain.usecases.game.GameUseCaseImpl

/**
 * Builds the dependency graph from the bottom up (DataSource -> Repository -> UseCase), like the
 * iOS `Container`. The only place in `shared` that knows concrete implementations. The session
 * repository is a single instance: every use case works on the same game.
 */
object GameContainer {
    private val errorHandler = DataErrorHandlerImpl()
    private val sessionRepository: GameSessionRepository by lazy {
        GameSessionRepositoryImpl(GameSessionLocalDataSourceImpl(), errorHandler)
    }

    fun makeGameUseCase(): GameUseCase = GameUseCaseImpl(
        levelRepository = LevelRepositoryImpl(LevelLocalDataSourceImpl(), errorHandler),
        sessionRepository = sessionRepository,
    )
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add GameContainer wiring the shared dependency graph"
```

---

## Self-review de la fase

- [ ] Cada caso de uso TypeScript tiene su función en `GameUseCase`: `StartGame` → `startGame`, `MovePlayerTo` → `movePlayerTo`, `ChopTree` → `chopTree`, `ConstructBuilding` → `canPlaceBuilding` + `constructBuilding`, `AdvanceWorld` → `advance`, `GetGameState` → `playerStatus` / `worldSnapshot` / `buildOptions` / `quests`.
- [ ] `GameUseCaseImpl` solo importa interfaces de repositorio; las implementaciones aparecen únicamente en `GameContainer`.
