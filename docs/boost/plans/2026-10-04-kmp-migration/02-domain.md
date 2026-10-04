# Fase 2 — Dominio en Kotlin

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar el dominio del juego (entidades, agregado `World` con sus sistemas, misiones, reglas, errores y contratos de repositorio) a `shared/src/commonMain`, con los tests de TypeScript traducidos como especificación.

**Architecture:** Entidades = `data class` inmutables (cada operación devuelve una copia). `World` es el agregado mutable (único punto de entrada para cambiar el juego) y delega en sistemas `internal` (`Navigation`, `Woodcutting`, `Construction`, `pickUpItems`). Las mecánicas de trabajo se registran en `workFor()` con un `when` exhaustivo sobre `Intent`.

**Tech Stack:** Kotlin common (sin dependencias de plataforma), kotlin.test.

## Global Constraints

Las de [`README.md`](README.md#global-constraints). En esta fase en particular: nada de `android.*`, `platform.*` ni `kotlin.js.*` en `commonMain`; entidades inmutables; tests con `// given`, `// when`, `// then` y nombres `testWhen...Then...`; mocks como `val <Entity>.Companion.mock`.

## File Structure

```
shared/src/commonMain/kotlin/com/apergas/rpg/domain/
  entities/
    geometry/   Position.kt, Obstacle.kt
    player/     ToolKind.kt, Inventory.kt, Intent.kt, Activity.kt, Player.kt
    tree/       TreeKind.kt, Tree.kt
    decoration/ DecorationKind.kt, Decoration.kt
    item/       GroundItem.kt
    building/   BlueprintId.kt, Blueprint.kt, Building.kt
    game/       GameEvent.kt, ChopResult.kt, ConstructionResult.kt, PlayerStatus.kt,
                WorldSnapshot.kt, BuildOption.kt, QuestProgress.kt, GameSession.kt
  rules/        Rules.kt
  errors/       AppError.kt, ErrorHandler.kt
  world/        World.kt, WorldState.kt, Work.kt, Navigation.kt, Woodcutting.kt,
                Construction.kt, Pickup.kt
  quests/       QuestId.kt, Quest.kt, QuestLog.kt
  repositories/
    level/      LevelRepository.kt
    session/    GameSessionRepository.kt

shared/src/commonTest/kotlin/com/apergas/rpg/domain/
  entities/
    geometry/PositionTests.kt
    player/PlayerMock.kt, PlayerTests.kt, InventoryTests.kt
    tree/TreeMock.kt, TreeTests.kt
    item/GroundItemMock.kt
    building/BuildingTests.kt
  world/WorldMock.kt, WorldMovementTests.kt, WorldItemsTests.kt, WorldChoppingTests.kt, WorldConstructionTests.kt
  quests/QuestLogTests.kt
```

Las clases de `entities/game/` que solo sirven al caso de uso (`PlayerStatus`, `WorldSnapshot`, `BuildOption`, `QuestProgress`) se testean en la fase 4 a través de `GameUseCaseImpl`.

---

### Task 1: Geometría — `Position` y `Obstacle`

**Files:**
- Create: `shared/src/commonMain/kotlin/com/apergas/rpg/domain/entities/geometry/Position.kt`
- Create: `shared/src/commonMain/kotlin/com/apergas/rpg/domain/entities/geometry/Obstacle.kt`
- Test: `shared/src/commonTest/kotlin/com/apergas/rpg/domain/entities/geometry/PositionTests.kt`
- Delete: `shared/src/commonMain/kotlin/com/apergas/rpg/util/Platform.kt`, `shared/src/commonTest/kotlin/com/apergas/rpg/util/PlatformTests.kt` (andamiaje de la fase 1)

**Interfaces:**
- Produces: `data class Position(x: Double, y: Double)` con `distanceTo`, `moveTowards`, `pointAtDistance`, `companion object`; `data class Obstacle(position: Position, radius: Double)` con `blocks(position, radius)`.

- [ ] **Step 1: Escribir los tests**

```kotlin
package com.apergas.rpg.domain.entities.geometry

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue

class PositionTests {
    @Test
    fun testWhenMeasuringDistanceThenReturnsEuclideanDistance() {
        // given
        val origin = Position(0.0, 0.0)

        // when
        val distance = origin.distanceTo(Position(3.0, 4.0))

        // then
        assertEquals(5.0, distance)
    }

    @Test
    fun testWhenMovingTowardsTargetThenAdvancesByStep() {
        // given
        val origin = Position(0.0, 0.0)

        // when
        val moved = origin.moveTowards(Position(10.0, 0.0), 4.0)

        // then
        assertEquals(Position(4.0, 0.0), moved)
    }

    @Test
    fun testWhenStepWouldOvershootThenSnapsToTarget() {
        // given
        val target = Position(10.0, 0.0)

        // when
        val moved = Position(8.0, 0.0).moveTowards(target, 5.0)

        // then
        assertSame(target, moved)
    }

    @Test
    fun testWhenAskingPointAtDistanceThenFollowsDirection() {
        // given
        val origin = Position(0.0, 0.0)

        // when
        val point = origin.pointAtDistance(5.0, Position(30.0, 40.0))

        // then
        assertEquals(Position(3.0, 4.0), point)
    }

    @Test
    fun testWhenBothPositionsCoincideThenPointIsBelow() {
        // given
        val position = Position(1.0, 1.0)

        // when
        val point = position.pointAtDistance(5.0, Position(1.0, 1.0))

        // then
        assertEquals(Position(1.0, 6.0), point)
    }

    @Test
    fun testWhenFootprintsOverlapThenObstacleBlocks() {
        // given
        val obstacle = Obstacle(Position(30.0, 0.0), 10.0)

        // when
        val blocksNear = obstacle.blocks(Position(15.0, 0.0), 8.0)
        val blocksFar = obstacle.blocks(Position(0.0, 0.0), 8.0)

        // then
        assertTrue(blocksNear)
        assertFalse(blocksFar)
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.domain.entities.geometry.*"`
Expected: FAIL — `Unresolved reference: Position`.

- [ ] **Step 3: Implementar**

`Position.kt`:
```kotlin
package com.apergas.rpg.domain.entities.geometry

import kotlin.math.hypot

data class Position(val x: Double, val y: Double) {
    fun distanceTo(other: Position): Double = hypot(other.x - x, other.y - y)

    /** A position moved towards [target] by at most [maxStep], never overshooting it. */
    fun moveTowards(target: Position, maxStep: Double): Position {
        val distance = distanceTo(target)
        if (distance <= maxStep) return target
        val ratio = maxStep / distance
        return Position(x + (target.x - x) * ratio, y + (target.y - y) * ratio)
    }

    /**
     * The point at exactly [distance] from this position in the direction of [towards].
     * When both coincide there is no direction, so the point is placed below (south).
     */
    fun pointAtDistance(distance: Double, towards: Position): Position {
        val length = distanceTo(towards)
        if (length == 0.0) return Position(x, y + distance)
        val ratio = distance / length
        return Position(x + (towards.x - x) * ratio, y + (towards.y - y) * ratio)
    }

    companion object
}
```

`Obstacle.kt`:
```kotlin
package com.apergas.rpg.domain.entities.geometry

/** Something solid on the ground. Only its circular footprint matters. */
data class Obstacle(val position: Position, val radius: Double) {
    init {
        require(radius > 0) { "Obstacle radius must be positive" }
    }

    fun blocks(position: Position, radius: Double): Boolean = this.position.distanceTo(position) < this.radius + radius
}
```

Borrar `util/Platform.kt` y `util/PlatformTests.kt`.

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS (6 tests × 3 targets).

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add Position and Obstacle to the shared domain"
```

---

### Task 2: Jugador — `ToolKind`, `Inventory`, `Intent`, `Activity`, `Player`

**Files:**
- Create: `domain/entities/player/ToolKind.kt`, `Inventory.kt`, `Intent.kt`, `Activity.kt`, `Player.kt` (bajo `shared/src/commonMain/kotlin/com/apergas/rpg/`)
- Test: `domain/entities/player/PlayerMock.kt`, `PlayerTests.kt`, `InventoryTests.kt` (bajo `shared/src/commonTest/kotlin/com/apergas/rpg/`)

**Interfaces:**
- Consumes: `Position` (Task 1).
- Produces:
  - `enum class ToolKind { Axe }`
  - `data class Inventory(wood: Int = 0, tools: Set<ToolKind> = emptySet())` con `addWood(Int): Inventory`, `spendWood(Int): Inventory?` (null si no alcanza), `addTool(ToolKind): Inventory`, `hasTool(ToolKind): Boolean`
  - `sealed interface Intent { data class Chop(treeId: String); data class Construct(buildingId: String) }`
  - `sealed interface Activity { data object Idle; data class Walking(destination: Position, intent: Intent?); data class Working(intent: Intent, elapsedMs: Double) }`
  - `data class Player(position, speed, radius, inventory = Inventory(), activity = Activity.Idle)` con `isMoving`, `walkTo(destination, intent = null)`, `startWork(intent)`, `continueWork(elapsedMs)`, `stop()`, `nextPosition(deltaMs): Position?`, `placeAt(position)`, `withInventory(inventory)`, `companion object`
  - Test: `val Player.Companion.mock: Player` (posición `(100, 100)`, velocidad `100`, radio `8`)

- [ ] **Step 1: Escribir el mock y los tests**

`PlayerMock.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position

val Player.Companion.mock: Player
    get() = Player(position = Position(100.0, 100.0), speed = 100.0, radius = 8.0)
```

`PlayerTests.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull

class PlayerTests {
    @Test
    fun testWhenCreatedThenIsIdleWithoutNextPosition() {
        // given
        val player = Player.mock

        // when
        val next = player.nextPosition(1000.0)

        // then
        assertEquals(Activity.Idle, player.activity)
        assertNull(next)
    }

    @Test
    fun testWhenWalkingThenNextPositionAdvancesSpeedTimesSecondsWithoutMoving() {
        // given
        val player = Player.mock.copy(position = Position(0.0, 0.0)).walkTo(Position(1000.0, 0.0))

        // when
        val next = player.nextPosition(500.0)

        // then
        assertEquals(Position(50.0, 0.0), next)
        assertEquals(Position(0.0, 0.0), player.position)
    }

    @Test
    fun testWhenStoppingThenReturnsToIdle() {
        // given
        val walking = Player.mock.walkTo(Position(10.0, 0.0))

        // when
        val stopped = walking.stop()

        // then
        assertFalse(stopped.isMoving)
        assertEquals(Activity.Idle, stopped.activity)
    }

    @Test
    fun testWhenContinuingWorkThenTracksElapsedTime() {
        // given
        val working = Player.mock.startWork(Intent.Chop("tree-1"))

        // when
        val later = working.continueWork(300.0)

        // then
        assertEquals(Activity.Working(Intent.Chop("tree-1"), 300.0), later.activity)
    }

    @Test
    fun testWhenSpeedOrRadiusAreNotPositiveThenCreationFails() {
        // given
        val position = Position(0.0, 0.0)

        // when / then
        assertFailsWith<IllegalArgumentException> { Player(position, speed = 0.0, radius = 10.0) }
        assertFailsWith<IllegalArgumentException> { Player(position, speed = 100.0, radius = 0.0) }
    }
}
```

`InventoryTests.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class InventoryTests {
    @Test
    fun testWhenSpendingAffordableWoodThenReturnsInventoryWithTheRest() {
        // given
        val inventory = Inventory().addWood(6)

        // when
        val afterSpending = inventory.spendWood(4)

        // then
        assertEquals(2, afterSpending?.wood)
    }

    @Test
    fun testWhenSpendingMoreWoodThanStoredThenReturnsNull() {
        // given
        val inventory = Inventory().addWood(3)

        // when
        val afterSpending = inventory.spendWood(5)

        // then
        assertNull(afterSpending)
        assertEquals(3, inventory.wood)
    }

    @Test
    fun testWhenAddingToolThenInventoryHasIt() {
        // given
        val inventory = Inventory()

        // when
        val withAxe = inventory.addTool(ToolKind.Axe)

        // then
        assertFalse(inventory.hasTool(ToolKind.Axe))
        assertTrue(withAxe.hasTool(ToolKind.Axe))
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.domain.entities.player.*"`
Expected: FAIL — `Unresolved reference: Player`.

- [ ] **Step 3: Implementar**

`ToolKind.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

enum class ToolKind { Axe }
```

`Inventory.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

/** What the player carries: stored wood and the tools it has picked up. */
data class Inventory(val wood: Int = 0, val tools: Set<ToolKind> = emptySet()) {
    fun addWood(amount: Int): Inventory {
        require(amount >= 0) { "Cannot add a negative amount of wood" }
        return copy(wood = wood + amount)
    }

    /** The inventory after paying [amount], or null when there is not enough wood. */
    fun spendWood(amount: Int): Inventory? = if (amount > wood) null else copy(wood = wood - amount)

    fun addTool(tool: ToolKind): Inventory = copy(tools = tools + tool)

    fun hasTool(tool: ToolKind): Boolean = tool in tools
}
```

`Intent.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

/** Work the player is asked to do on a target: walk up to it, then work until it is done. */
sealed interface Intent {
    data class Chop(val treeId: String) : Intent
    data class Construct(val buildingId: String) : Intent
}
```

`Activity.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position

sealed interface Activity {
    data object Idle : Activity
    data class Walking(val destination: Position, val intent: Intent?) : Activity
    /** [elapsedMs] is the time since the last impact (axe hit, hammer blow...). */
    data class Working(val intent: Intent, val elapsedMs: Double) : Activity
}
```

`Player.kt`:
```kotlin
package com.apergas.rpg.domain.entities.player

import com.apergas.rpg.domain.entities.geometry.Position

data class Player(
    val position: Position,
    /** World units per second. */
    val speed: Double,
    /** Radius of the footprint on the ground, used for collisions. */
    val radius: Double,
    val inventory: Inventory = Inventory(),
    val activity: Activity = Activity.Idle,
) {
    init {
        require(speed > 0) { "Player speed must be positive" }
        require(radius > 0) { "Player radius must be positive" }
    }

    val isMoving: Boolean get() = activity is Activity.Walking

    fun walkTo(destination: Position, intent: Intent? = null): Player =
        copy(activity = Activity.Walking(destination, intent))

    fun startWork(intent: Intent): Player = copy(activity = Activity.Working(intent, elapsedMs = 0.0))

    /** Keeps working on the current task; [elapsedMs] is the time since the last impact. */
    fun continueWork(elapsedMs: Double): Player {
        val working = activity as? Activity.Working ?: return this
        return copy(activity = working.copy(elapsedMs = elapsedMs))
    }

    fun stop(): Player = copy(activity = Activity.Idle)

    /** Where the player would be after [deltaMs], or null when not walking. */
    fun nextPosition(deltaMs: Double): Position? {
        val walking = activity as? Activity.Walking ?: return null
        return position.moveTowards(walking.destination, speed * deltaMs / 1000)
    }

    fun placeAt(position: Position): Player = copy(position = position)

    fun withInventory(inventory: Inventory): Player = copy(inventory = inventory)

    companion object
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add immutable player, inventory and activity to the shared domain"
```

---

### Task 3: Árbol (con su tipo), decoración, objeto en el suelo y edificios

**Files:**
- Create: `domain/entities/tree/TreeKind.kt`, `Tree.kt`, `domain/entities/decoration/DecorationKind.kt`, `Decoration.kt`, `domain/entities/item/GroundItem.kt`, `domain/entities/building/BlueprintId.kt`, `Blueprint.kt`, `Building.kt`
- Test: `domain/entities/tree/TreeMock.kt`, `TreeTests.kt`, `domain/entities/item/GroundItemMock.kt`, `domain/entities/building/BuildingTests.kt`

**Interfaces:**
- Consumes: `Position`, `Obstacle`, `ToolKind`.
- Produces:
  - `enum class TreeKind { Slim, Round, Wide, Broad, Twisted, Branches, Leaning, Lumpy, Pine, Dome, Oak, Dense, Old, Big }` (este orden es el de la lista de sprites de la web y lo usa el generador: no reordenar)
  - `data class Tree(id, kind: TreeKind, position, trunkRadius, woodYield: Int, hitsToFell: Int, hitsTaken: Int = 0)` con `footprint: Obstacle`, `hitsRemaining`, `isFelled`, `hit(): Tree`
  - `enum class DecorationKind { TallGrass, Leaves, Mushrooms, Rock }`; `data class Decoration(id, kind: DecorationKind, position)` — sin colisión
  - `data class GroundItem(id, kind: ToolKind, position)`
  - `enum class BlueprintId { House }`; `data class Blueprint(id, woodCost, hitsToBuild, footprintRadius)`; `object Blueprints { val house; val all; fun of(BlueprintId) }`
  - `data class Building(id, blueprint, position, hitsDone = 0)` con `footprint`, `progress: Double`, `isComplete`, `hammer(): Building`
  - Test: `val Tree.Companion.mock` (`tree-1`, roble, en `(200, 100)`, tronco 10, madera 6, 5 golpes); `val GroundItem.Companion.mock` (`axe-1`, hacha, `(150, 100)`)

- [ ] **Step 1: Escribir mocks y tests**

`TreeMock.kt`:
```kotlin
package com.apergas.rpg.domain.entities.tree

import com.apergas.rpg.domain.entities.geometry.Position

val Tree.Companion.mock: Tree
    get() = Tree(id = "tree-1", kind = TreeKind.Oak, position = Position(200.0, 100.0), trunkRadius = 10.0, woodYield = 6, hitsToFell = 5)
```

`GroundItemMock.kt`:
```kotlin
package com.apergas.rpg.domain.entities.item

import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind

val GroundItem.Companion.mock: GroundItem
    get() = GroundItem(id = "axe-1", kind = ToolKind.Axe, position = Position(150.0, 100.0))
```

`TreeTests.kt`:
```kotlin
package com.apergas.rpg.domain.entities.tree

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class TreeTests {
    @Test
    fun testWhenHitTheRequiredTimesThenTreeIsFelledAndIgnoresMoreHits() {
        // given
        var tree = Tree.mock

        // when
        repeat(5) { tree = tree.hit() }
        val hitAgain = tree.hit()

        // then
        assertTrue(tree.isFelled)
        assertEquals(0, hitAgain.hitsRemaining)
    }

    @Test
    fun testWhenHitOnceThenOriginalTreeIsUnchanged() {
        // given
        val tree = Tree.mock

        // when
        val hitTree = tree.hit()

        // then
        assertEquals(5, tree.hitsRemaining)
        assertEquals(4, hitTree.hitsRemaining)
    }
}
```

`BuildingTests.kt`:
```kotlin
package com.apergas.rpg.domain.entities.building

import com.apergas.rpg.domain.entities.geometry.Position
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class BuildingTests {
    @Test
    fun testWhenHammeredThenProgressGrowsUntilComplete() {
        // given
        var building = Building(id = "building-1", blueprint = Blueprints.house, position = Position(0.0, 0.0))

        // when
        building = building.hammer()
        val afterOneHit = building.progress
        repeat(7) { building = building.hammer() }

        // then
        assertEquals(0.125, afterOneHit)
        assertTrue(building.isComplete)
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.domain.entities.*"`
Expected: FAIL — `Unresolved reference: Tree`.

- [ ] **Step 3: Implementar**

`TreeKind.kt`:
```kotlin
package com.apergas.rpg.domain.entities.tree

/**
 * The species/shape of a tree, decided by the level. Apps map it to their sprite; gameplay may use it
 * later (e.g. oaks yielding more wood). Order matters: the level generator indexes this list.
 */
enum class TreeKind { Slim, Round, Wide, Broad, Twisted, Branches, Leaning, Lumpy, Pine, Dome, Oak, Dense, Old, Big }
```

`DecorationKind.kt` y `Decoration.kt`:
```kotlin
package com.apergas.rpg.domain.entities.decoration

enum class DecorationKind { TallGrass, Leaves, Mushrooms, Rock }
```
```kotlin
package com.apergas.rpg.domain.entities.decoration

import com.apergas.rpg.domain.entities.geometry.Position

/** Ground decoration placed by the level. Purely visual: it never blocks movement. */
data class Decoration(val id: String, val kind: DecorationKind, val position: Position) {
    companion object
}
```

`Tree.kt`:
```kotlin
package com.apergas.rpg.domain.entities.tree

import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position

/** A choppable tree. Its trunk blocks movement until it is felled. */
data class Tree(
    val id: String,
    val kind: TreeKind,
    val position: Position,
    val trunkRadius: Double,
    /** Wood added to the inventory when the tree is felled. */
    val woodYield: Int,
    val hitsToFell: Int,
    val hitsTaken: Int = 0,
) {
    init {
        require(woodYield >= 0) { "Wood yield cannot be negative" }
        require(hitsToFell > 0) { "A tree needs at least one hit to fell" }
    }

    val footprint: Obstacle get() = Obstacle(position, trunkRadius)
    val hitsRemaining: Int get() = hitsToFell - hitsTaken
    val isFelled: Boolean get() = hitsRemaining == 0

    fun hit(): Tree = if (isFelled) this else copy(hitsTaken = hitsTaken + 1)

    companion object
}
```

`GroundItem.kt`:
```kotlin
package com.apergas.rpg.domain.entities.item

import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind

/** A tool lying on the ground, waiting to be picked up. */
data class GroundItem(val id: String, val kind: ToolKind, val position: Position) {
    companion object
}
```

`BlueprintId.kt`:
```kotlin
package com.apergas.rpg.domain.entities.building

enum class BlueprintId { House }
```

`Blueprint.kt`:
```kotlin
package com.apergas.rpg.domain.entities.building

/** What it takes to construct a kind of building. */
data class Blueprint(
    val id: BlueprintId,
    val woodCost: Int,
    /** Hammer hits needed to finish it. */
    val hitsToBuild: Int,
    /** Radius of the circular footprint that blocks movement. */
    val footprintRadius: Double,
)

object Blueprints {
    val house = Blueprint(id = BlueprintId.House, woodCost = 15, hitsToBuild = 8, footprintRadius = 40.0)
    val all: List<Blueprint> = listOf(house)

    fun of(id: BlueprintId): Blueprint = all.first { it.id == id }
}
```

`Building.kt`:
```kotlin
package com.apergas.rpg.domain.entities.building

import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position

/** A building placed in the world. It blocks movement from the moment construction starts. */
data class Building(val id: String, val blueprint: Blueprint, val position: Position, val hitsDone: Int = 0) {
    val footprint: Obstacle get() = Obstacle(position, blueprint.footprintRadius)

    /** From 0 (just started) to 1 (complete). */
    val progress: Double get() = hitsDone.toDouble() / blueprint.hitsToBuild
    val isComplete: Boolean get() = hitsDone >= blueprint.hitsToBuild

    fun hammer(): Building = if (isComplete) this else copy(hitsDone = hitsDone + 1)

    companion object
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add trees, ground items and buildings to the shared domain"
```

---

### Task 4: Reglas, eventos, resultados y errores

Sin comportamiento propio (solo tipos y constantes): se validan compilando y los usan los tests de la Task 5.

**Files:**
- Create: `domain/rules/Rules.kt`, `domain/entities/game/GameEvent.kt`, `ChopResult.kt`, `ConstructionResult.kt`, `domain/errors/AppError.kt`, `ErrorHandler.kt`, `domain/quests/QuestId.kt`

**Interfaces:**
- Produces:
  - `object Rules` con `HITS_TO_FELL_TREE = 5`, `CHOP_INTERVAL_MS = 750.0`, `HAMMER_INTERVAL_MS = 650.0`, `WORK_GAP = 2.0`, `PICK_UP_RANGE = 14.0`, `PLAYER_SPEED = 110.0`, `PLAYER_RADIUS = 8.0`, `TREE_TRUNK_RADIUS = 12.0`
  - `sealed interface GameEvent` (variantes abajo)
  - `enum class ChopResult { Ok, NoAxe, UnknownTree }`
  - `sealed interface ConstructionResult { data class Started(building: Building); data class Rejected(reason: ConstructionRejection) }`, `enum class ConstructionRejection { NotEnoughWood, Blocked }`
  - `sealed class AppError`, `interface ErrorHandler { fun handle(error: Throwable): AppError }`
  - `enum class QuestId { PickUpAxe, GatherWood, BuildHouse }`

- [ ] **Step 1: Escribir los ficheros**

`Rules.kt`:
```kotlin
package com.apergas.rpg.domain.rules

/** Tuning values for the gathering and building loop. Times in milliseconds, distances in world units. */
object Rules {
    const val HITS_TO_FELL_TREE = 5
    const val CHOP_INTERVAL_MS = 750.0
    const val HAMMER_INTERVAL_MS = 650.0
    /** Gap left between the player's footprint and the target's when walking up to work on it. */
    const val WORK_GAP = 2.0
    /** The player picks up items within this distance of its feet. */
    const val PICK_UP_RANGE = 14.0
    const val PLAYER_SPEED = 110.0
    const val PLAYER_RADIUS = 8.0
    const val TREE_TRUNK_RADIUS = 12.0
}
```

`QuestId.kt`:
```kotlin
package com.apergas.rpg.domain.quests

enum class QuestId { PickUpAxe, GatherWood, BuildHouse }
```

`GameEvent.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.quests.QuestId

/** Things that happened during a simulation step, so adapters can animate or announce them. */
sealed interface GameEvent {
    data class ItemPickedUp(val itemId: String, val kind: ToolKind) : GameEvent
    /** Something stood between the player and the target it was sent to work on. */
    data object PlayerBlocked : GameEvent
    data class TreeHit(val treeId: String, val hitsRemaining: Int) : GameEvent
    data class TreeFelled(val treeId: String, val wood: Int) : GameEvent
    data class BuildingHammered(val buildingId: String, val progress: Double) : GameEvent
    data class BuildingCompleted(val buildingId: String, val blueprint: BlueprintId) : GameEvent
    data class QuestCompleted(val questId: QuestId) : GameEvent
}
```

`ChopResult.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

enum class ChopResult { Ok, NoAxe, UnknownTree }
```

`ConstructionResult.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.Building

sealed interface ConstructionResult {
    data class Started(val building: Building) : ConstructionResult
    data class Rejected(val reason: ConstructionRejection) : ConstructionResult
}

enum class ConstructionRejection { NotEnoughWood, Blocked }
```

`AppError.kt`:
```kotlin
package com.apergas.rpg.domain.errors

/** Base of every controlled error; nothing else reaches the presentation layer. */
sealed class AppError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class GeneralError(cause: Throwable? = null) : AppError("Something went wrong", cause)

    sealed class LevelError(message: String) : AppError(message) {
        class UnknownItemKind(val itemId: String, val kind: String) :
            LevelError("Level item \"$itemId\" has an unknown kind: \"$kind\"")

        class UnknownTreeKind(val treeId: String, val kind: String) :
            LevelError("Level tree \"$treeId\" has an unknown kind: \"$kind\"")

        class UnknownDecorationKind(val decorationId: String, val kind: String) :
            LevelError("Level decoration \"$decorationId\" has an unknown kind: \"$kind\"")

        class InvalidLevel(reason: String) : LevelError("Invalid level: $reason")
    }
}
```

`ErrorHandler.kt`:
```kotlin
package com.apergas.rpg.domain.errors

fun interface ErrorHandler {
    fun handle(error: Throwable): AppError
}
```

- [ ] **Step 2: Compilar**

Run: `./gradlew :shared:compileKotlinMetadata :shared:allTests`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add rules, game events, results and errors to the shared domain"
```

---

### Task 5: Agregado `World` y sus sistemas

**Files:**
- Create: `domain/world/WorldState.kt`, `Work.kt`, `Navigation.kt`, `Woodcutting.kt`, `Construction.kt`, `Pickup.kt`, `World.kt`
- Test: `domain/world/WorldMock.kt`, `WorldMovementTests.kt`, `WorldItemsTests.kt`, `WorldChoppingTests.kt`, `WorldConstructionTests.kt`

**Interfaces:**
- Consumes: todas las entidades de Tasks 1–4.
- Produces (`World`, API pública):
  - `class World(width: Double, height: Double, player: Player, trees: List<Tree>, items: List<GroundItem> = emptyList(), decorations: List<Decoration> = emptyList())`
  - `val width; val height; val player: Player; val trees: List<Tree>; val items: List<GroundItem>; val decorations: List<Decoration>; val buildings: List<Building>; val obstacles: List<Obstacle>` (las decoraciones no entran en `obstacles`)
  - `val workProgress: Double` (0..1); `val playerTarget: Position?`
  - `fun movePlayerTo(destination: Position)`, `fun orderChop(treeId: String): ChopResult`, `fun orderConstruction(blueprint: Blueprint, position: Position): ConstructionResult`, `fun canPlace(blueprint: Blueprint, position: Position): Boolean`, `fun advance(deltaMs: Double): List<GameEvent>`
  - `internal fun updatePlayer(transform: (Player) -> Player)` — solo para preparar estados en tests (los tests de `commonTest` ven `internal`)
  - `companion object`
  - Test: `fun World.Companion.mock(player = Player.mock, trees = emptyList(), items = emptyList()): World` (1000 × 1000); `fun World.advanceFor(totalMs: Double): List<GameEvent>` (pasos de 16 ms)

- [ ] **Step 1: Escribir los helpers de test**

`WorldMock.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree

fun World.Companion.mock(
    player: Player = Player.mock,
    trees: List<Tree> = emptyList(),
    items: List<GroundItem> = emptyList(),
): World = World(width = 1000.0, height = 1000.0, player = player, trees = trees, items = items)

/** Advances in 16 ms steps, like a 60 fps game loop, collecting every event. */
fun World.advanceFor(totalMs: Double): List<GameEvent> {
    val events = mutableListOf<GameEvent>()
    var elapsed = 0.0
    while (elapsed < totalMs) {
        events += advance(16.0)
        elapsed += 16.0
    }
    return events
}
```

- [ ] **Step 2: Escribir los tests de movimiento y objetos**

`WorldMovementTests.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class WorldMovementTests {
    @Test
    fun testWhenPathIsClearThenPlayerMoves() {
        // given
        val world = World.mock()
        world.movePlayerTo(Position(200.0, 100.0))

        // when
        world.advance(500.0)

        // then
        assertEquals(Position(150.0, 100.0), world.player.position)
    }

    @Test
    fun testWhenNextStepHitsATrunkThenPlayerStops() {
        // given
        val world = World.mock(trees = listOf(Tree.mock.copy(position = Position(130.0, 100.0))))
        world.movePlayerTo(Position(200.0, 100.0))

        // when
        world.advance(150.0)

        // then
        assertEquals(Position(100.0, 100.0), world.player.position)
        assertFalse(world.player.isMoving)
    }

    @Test
    fun testWhenDestinationIsOutsideTheWorldThenItIsClampedToTheEdge() {
        // given
        val world = World(width = 200.0, height = 100.0, player = Player.mock.copy(position = Position(50.0, 50.0)), trees = emptyList())
        world.movePlayerTo(Position(-50.0, 500.0))

        // when
        world.advanceFor(2000.0)

        // then
        assertEquals(Position(8.0, 92.0), world.player.position)
    }
}
```

`WorldItemsTests.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.item.mock
import com.apergas.rpg.domain.entities.player.ToolKind
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertTrue

class WorldItemsTests {
    @Test
    fun testWhenPlayerWalksOverAToolThenPicksItUp() {
        // given
        val world = World.mock(items = listOf(GroundItem.mock))
        world.movePlayerTo(Position(160.0, 100.0))

        // when
        val events = world.advanceFor(1000.0)

        // then
        assertContains(events, GameEvent.ItemPickedUp("axe-1", ToolKind.Axe))
        assertTrue(world.player.inventory.hasTool(ToolKind.Axe))
        assertTrue(world.items.isEmpty())
    }
}
```

- [ ] **Step 3: Escribir los tests de talar**

`WorldChoppingTests.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.rules.Rules
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

class WorldChoppingTests {
    private fun worldWithAxeAndTree(): World {
        val player = Player.mock.copy(inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        return World.mock(player = player, trees = listOf(Tree.mock))
    }

    @Test
    fun testWhenChoppingWithoutAxeThenReturnsNoAxeAndStaysPut() {
        // given
        val world = World.mock(trees = listOf(Tree.mock))

        // when
        val result = world.orderChop("tree-1")

        // then
        assertEquals(ChopResult.NoAxe, result)
        assertFalse(world.player.isMoving)
    }

    @Test
    fun testWhenChoppingUnknownTreeThenReturnsUnknownTree() {
        // given
        val world = worldWithAxeAndTree()

        // when
        val result = world.orderChop("nope")

        // then
        assertEquals(ChopResult.UnknownTree, result)
    }

    @Test
    fun testWhenChoppingThenWalksToTheNearSideAndStartsWorking() {
        // given
        val world = worldWithAxeAndTree()

        // when
        val result = world.orderChop("tree-1")
        world.advanceFor(1500.0)

        // then
        assertEquals(ChopResult.Ok, result)
        assertEquals(Intent.Chop("tree-1"), (world.player.activity as Activity.Working).intent)
        assertEquals(Position(180.0, 101.0), world.player.position)
    }

    @Test
    fun testWhenNearSideIsBlockedThenChopsFromTheOtherSide() {
        // given
        val player = Player.mock.copy(position = Position(100.0, 300.0), inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        val world = World.mock(player = player, trees = listOf(Tree.mock, Tree.mock.copy(id = "neighbour", position = Position(165.0, 100.0))))
        world.orderChop("tree-1")

        // when
        world.advanceFor(4000.0)

        // then
        assertIs<Activity.Working>(world.player.activity)
        assertTrue(world.player.position.x > 200.0)
    }

    @Test
    fun testWhenChoppingLongEnoughThenTreeFallsAndWoodIsAdded() {
        // given
        val world = worldWithAxeAndTree()
        world.orderChop("tree-1")
        world.advanceFor(1500.0)

        // when
        val events = world.advanceFor(Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE + 100)

        // then
        assertEquals(5, events.count { it is GameEvent.TreeHit })
        assertContains(events, GameEvent.TreeFelled("tree-1", 6))
        assertEquals(6, world.player.inventory.wood)
        assertTrue(world.trees.isEmpty())
        assertEquals(Activity.Idle, world.player.activity)
    }

    @Test
    fun testWhenAnotherTreeStandsInTheWayThenReportsPlayerBlocked() {
        // given
        val player = Player.mock.copy(inventory = Player.mock.inventory.addTool(ToolKind.Axe))
        val world = World.mock(
            player = player,
            trees = listOf(Tree.mock.copy(position = Position(300.0, 100.0)), Tree.mock.copy(id = "in-the-way", position = Position(180.0, 100.0))),
        )
        world.orderChop("tree-1")

        // when
        val events = world.advanceFor(3000.0)

        // then
        assertContains(events, GameEvent.PlayerBlocked)
        assertEquals(Activity.Idle, world.player.activity)
    }

    @Test
    fun testWhenTreeIsFelledThenPathIsFree() {
        // given
        val world = worldWithAxeAndTree()
        world.orderChop("tree-1")
        world.advanceFor(1500 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE + 100)

        // when
        world.movePlayerTo(Position(300.0, 100.0))
        world.advanceFor(3000.0)

        // then
        assertEquals(Position(300.0, 100.0), world.player.position)
    }
}
```

- [ ] **Step 4: Escribir los tests de construir**

`WorldConstructionTests.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.building.Blueprints
import com.apergas.rpg.domain.entities.game.ConstructionRejection
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.mock
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.entities.tree.mock
import com.apergas.rpg.domain.rules.Rules
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class WorldConstructionTests {
    private val house = Blueprints.house

    private fun worldWithWood(wood: Int): World =
        World.mock(player = Player.mock.copy(inventory = Player.mock.inventory.addWood(wood)))

    @Test
    fun testWhenConstructingWithoutEnoughWoodThenIsRejected() {
        // given
        val world = World.mock()

        // when
        val result = world.orderConstruction(house, Position(400.0, 400.0))

        // then
        assertEquals(ConstructionResult.Rejected(ConstructionRejection.NotEnoughWood), result)
        assertTrue(world.buildings.isEmpty())
    }

    @Test
    fun testWhenSiteOverlapsTreePlayerOrEdgeThenIsBlockedWithoutCharging() {
        // given
        val world = World.mock(
            player = Player.mock.copy(inventory = Player.mock.inventory.addWood(15)),
            trees = listOf(Tree.mock.copy(position = Position(400.0, 400.0))),
        )
        val blocked = ConstructionResult.Rejected(ConstructionRejection.Blocked)

        // when
        val overTree = world.orderConstruction(house, Position(420.0, 400.0))
        val overPlayer = world.orderConstruction(house, Position(110.0, 100.0))
        val overEdge = world.orderConstruction(house, Position(10.0, 500.0))

        // then
        assertEquals(blocked, overTree)
        assertEquals(blocked, overPlayer)
        assertEquals(blocked, overEdge)
        assertEquals(15, world.player.inventory.wood)
    }

    @Test
    fun testWhenConstructingThenChargesWoodPlacesSiteAndWalksThere() {
        // given
        val world = worldWithWood(17)

        // when
        val result = world.orderConstruction(house, Position(300.0, 100.0))

        // then
        assertIs<ConstructionResult.Started>(result)
        assertEquals(2, world.player.inventory.wood)
        assertEquals(1, world.buildings.size)
        assertTrue(world.player.isMoving)
    }

    @Test
    fun testWhenReachingTheSiteThenBuildsFromTheFront() {
        // given
        val world = worldWithWood(17)
        world.orderConstruction(house, Position(300.0, 100.0))

        // when
        world.advanceFor(3000.0)

        // then
        assertEquals(Intent.Construct("building-1"), (world.player.activity as Activity.Working).intent)
        assertEquals(Position(300.0, 150.0), world.player.position)
    }

    @Test
    fun testWhenHammeringLongEnoughThenBuildingIsCompleted() {
        // given
        val world = worldWithWood(17)
        world.orderConstruction(house, Position(300.0, 100.0))

        // when
        val events = world.advanceFor(3000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild)

        // then
        assertEquals(8, events.count { it is GameEvent.BuildingHammered })
        assertContains(events, GameEvent.BuildingCompleted("building-1", BlueprintId.House))
        assertTrue(world.buildings.single().isComplete)
        assertEquals(Activity.Idle, world.player.activity)
    }

    @Test
    fun testWhenBuildingIsCompleteThenItBlocksMovement() {
        // given
        val world = worldWithWood(17)
        world.orderConstruction(house, Position(300.0, 100.0))
        world.advanceFor(3000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild)
        for (waypoint in listOf(Position(200.0, 200.0), Position(200.0, 100.0))) {
            world.movePlayerTo(waypoint)
            world.advanceFor(3000.0)
        }

        // when
        world.movePlayerTo(Position(500.0, 100.0))
        world.advanceFor(5000.0)

        // then
        assertTrue(world.player.position.x < 260.0)
    }
}
```

- [ ] **Step 5: Ejecutar y ver que fallan**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.domain.world.*"`
Expected: FAIL — `Unresolved reference: World`.

- [ ] **Step 6: Implementar `WorldState` y `Work`**

`WorldState.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.tree.Tree
import kotlin.math.max
import kotlin.math.min

/** The world's data, shared by the systems that implement its rules. Only `World` creates it. */
internal class WorldState(
    val width: Double,
    val height: Double,
    var player: Player,
    trees: List<Tree>,
    items: List<GroundItem>,
    /** Static and non-solid: no system changes it, it never takes part in collisions. */
    val decorations: List<Decoration>,
) {
    init {
        require(width > 0 && height > 0) { "World size must be positive" }
    }

    val trees: MutableMap<String, Tree> = trees.associateByTo(LinkedHashMap()) { it.id }
    val items: MutableMap<String, GroundItem> = items.associateByTo(LinkedHashMap()) { it.id }
    val buildings: MutableMap<String, Building> = LinkedHashMap()
    private val idCounters = mutableMapOf<String, Int>()

    /** Every footprint that blocks movement: standing trees and buildings (finished or not). */
    fun obstacles(): List<Obstacle> = trees.values.map { it.footprint } + buildings.values.map { it.footprint }

    fun isBlocked(position: Position, radius: Double): Boolean = obstacles().any { it.blocks(position, radius) }

    /** Keeps a footprint of [margin] radius inside the world. */
    fun clamp(position: Position, margin: Double): Position {
        fun clamp(value: Double, limit: Double) = min(max(value, margin), limit - margin)
        return Position(clamp(position.x, width), clamp(position.y, height))
    }

    fun isInside(position: Position, margin: Double): Boolean = clamp(position, margin) == position

    /** Sequential ids per prefix: `building-1`, `building-2`... */
    fun nextId(prefix: String): String {
        val next = (idCounters[prefix] ?: 0) + 1
        idCounters[prefix] = next
        return "$prefix-$next"
    }
}
```

`Work.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Intent

/**
 * A kind of work done on a target one impact at a time. Adding a mechanic = a new `Intent`
 * variant + a `Work` + one branch in [workFor]; the compiler flags the missing branch.
 */
internal interface Work<I : Intent> {
    val intervalMs: Double
    fun target(state: WorldState, intent: I): Obstacle?
    /** Spots to stand on, best first, [distance] from the target; [side] is -1 from the left, 1 from the right. */
    fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position>
    /** Applies one impact. Returns true when the work is finished. */
    fun impact(state: WorldState, intent: I, events: MutableList<GameEvent>): Boolean
}

/** A work bound to its intent, so callers do not deal with the generic type. */
internal class BoundWork<I : Intent>(private val work: Work<I>, private val intent: I) {
    val intervalMs: Double get() = work.intervalMs
    fun target(state: WorldState): Obstacle? = work.target(state, intent)
    fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position> =
        work.preferredSpots(target, distance, side)
    fun impact(state: WorldState, events: MutableList<GameEvent>): Boolean = work.impact(state, intent, events)
}

internal fun workFor(intent: Intent): BoundWork<*> = when (intent) {
    is Intent.Chop -> BoundWork(Woodcutting, intent)
    is Intent.Construct -> BoundWork(Construction, intent)
}
```

- [ ] **Step 7: Implementar los sistemas**

`Woodcutting.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.rules.Rules

/** Felling trees with an axe: one hit per interval, wood added when the tree falls. */
internal object Woodcutting : Work<Intent.Chop> {
    override val intervalMs: Double = Rules.CHOP_INTERVAL_MS

    fun check(state: WorldState, treeId: String): ChopResult = when {
        treeId !in state.trees -> ChopResult.UnknownTree
        !state.player.inventory.hasTool(ToolKind.Axe) -> ChopResult.NoAxe
        else -> ChopResult.Ok
    }

    override fun target(state: WorldState, intent: Intent.Chop): Obstacle? = state.trees[intent.treeId]?.footprint

    /** Beside the trunk, a pixel in front so the player is drawn over it; near side first. */
    override fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position> {
        val (x, y) = target.position
        return listOf(Position(x + side * distance, y + 1), Position(x - side * distance, y + 1))
    }

    override fun impact(state: WorldState, intent: Intent.Chop, events: MutableList<GameEvent>): Boolean {
        val tree = state.trees[intent.treeId]?.hit() ?: return true
        events += GameEvent.TreeHit(tree.id, tree.hitsRemaining)
        if (!tree.isFelled) {
            state.trees[tree.id] = tree
            return false
        }
        state.trees.remove(tree.id)
        state.player = state.player.withInventory(state.player.inventory.addWood(tree.woodYield))
        events += GameEvent.TreeFelled(tree.id, tree.woodYield)
        return true
    }
}
```

`Construction.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.Blueprint
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.game.ConstructionRejection
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.rules.Rules

/** Paying for buildings, placing their sites and hammering them until they are finished. */
internal object Construction : Work<Intent.Construct> {
    override val intervalMs: Double = Rules.HAMMER_INTERVAL_MS

    fun canPlace(state: WorldState, blueprint: Blueprint, position: Position): Boolean {
        val radius = blueprint.footprintRadius
        val player = state.player
        val overlapsPlayer = position.distanceTo(player.position) < radius + player.radius
        val overlapsItem = state.items.values.any { position.distanceTo(it.position) < radius }
        return state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem
    }

    fun place(state: WorldState, blueprint: Blueprint, position: Position): ConstructionResult {
        val paid = state.player.inventory.spendWood(blueprint.woodCost)
            ?: return ConstructionResult.Rejected(ConstructionRejection.NotEnoughWood)
        if (!canPlace(state, blueprint, position)) return ConstructionResult.Rejected(ConstructionRejection.Blocked)

        state.player = state.player.withInventory(paid)
        val building = Building(state.nextId("building"), blueprint, position)
        state.buildings[building.id] = building
        return ConstructionResult.Started(building)
    }

    override fun target(state: WorldState, intent: Intent.Construct): Obstacle? =
        state.buildings[intent.buildingId]?.takeUnless { it.isComplete }?.footprint

    /** In front of the building (south), where the player stays in view. */
    override fun preferredSpots(target: Obstacle, distance: Double, side: Int): List<Position> =
        listOf(Position(target.position.x, target.position.y + distance))

    override fun impact(state: WorldState, intent: Intent.Construct, events: MutableList<GameEvent>): Boolean {
        val building = state.buildings[intent.buildingId]?.hammer() ?: return true
        state.buildings[building.id] = building
        events += GameEvent.BuildingHammered(building.id, building.progress)
        if (!building.isComplete) return false
        events += GameEvent.BuildingCompleted(building.id, building.blueprint.id)
        return true
    }
}
```

`Pickup.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.rules.Rules

/** Picks up every item the player is standing on. */
internal fun pickUpItems(state: WorldState, events: MutableList<GameEvent>) {
    for (item in state.items.values.toList()) {
        if (item.position.distanceTo(state.player.position) > Rules.PICK_UP_RANGE) continue
        state.items.remove(item.id)
        state.player = state.player.withInventory(state.player.inventory.addTool(item.kind))
        events += GameEvent.ItemPickedUp(item.id, item.kind)
    }
}
```

`Navigation.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.rules.Rules

/** Extra distance, beyond touching footprints, from which the player can still work on a target. */
private const val REACH_TOLERANCE = 6.0

/** Walking, collisions and getting into position to work on a target. */
internal class Navigation(private val state: WorldState) {
    fun walkTo(destination: Position) {
        state.player = state.player.walkTo(state.clamp(destination, state.player.radius))
    }

    /** Walks up to the intent's target, or starts working right away if it is already within reach. */
    fun goWorkOn(intent: Intent) {
        if (isWithinReach(intent)) return startWork(intent)
        state.player = state.player.walkTo(workSpot(intent), intent)
    }

    fun step(deltaMs: Double, activity: Activity.Walking, events: MutableList<GameEvent>) {
        val player = state.player
        val next = player.nextPosition(deltaMs) ?: return
        val intent = activity.intent

        if (state.isBlocked(next, player.radius)) {
            if (intent != null && isWithinReach(intent)) return startWork(intent)
            if (intent != null) events += GameEvent.PlayerBlocked
            state.player = player.stop()
            return
        }

        state.player = player.placeAt(next)
        if (next != activity.destination) return
        if (intent != null) startWork(intent) else state.player = state.player.stop()
    }

    private fun startWork(intent: Intent) {
        state.player = if (workFor(intent).target(state) != null) state.player.startWork(intent) else state.player.stop()
    }

    private fun isWithinReach(intent: Intent): Boolean {
        val target = workFor(intent).target(state) ?: return false
        val reach = target.radius + state.player.radius + Rules.WORK_GAP + REACH_TOLERANCE
        return state.player.position.distanceTo(target.position) <= reach
    }

    /** The work's preferred spots first; the closest point on the player's side when those are blocked. */
    private fun workSpot(intent: Intent): Position {
        val player = state.player
        val work = workFor(intent)
        val target = work.target(state) ?: return player.position
        val distance = target.radius + player.radius + Rules.WORK_GAP
        val side = if (player.position.x < target.position.x) -1 else 1
        val isFree = { spot: Position -> state.isInside(spot, player.radius) && !state.isBlocked(spot, player.radius) }

        return work.preferredSpots(target, distance, side).firstOrNull(isFree)
            ?: state.clamp(target.position.pointAtDistance(distance, player.position), player.radius)
    }
}
```

`World.kt`:
```kotlin
package com.apergas.rpg.domain.world

import com.apergas.rpg.domain.entities.building.Blueprint
import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.game.ChopResult
import com.apergas.rpg.domain.entities.game.ConstructionResult
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.geometry.Obstacle
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Activity
import com.apergas.rpg.domain.entities.player.Intent
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.tree.Tree

/**
 * Aggregate root: the only entry point that changes the world. It owns the state and delegates each
 * rule to a system (navigation, woodcutting, construction, pick-up). Everything it hands out is an
 * immutable entity snapshot.
 */
class World(
    width: Double,
    height: Double,
    player: Player,
    trees: List<Tree>,
    items: List<GroundItem> = emptyList(),
    decorations: List<Decoration> = emptyList(),
) {
    private val state = WorldState(width, height, player, trees, items, decorations)
    private val navigation = Navigation(state)

    val width: Double get() = state.width
    val height: Double get() = state.height
    val player: Player get() = state.player
    val trees: List<Tree> get() = state.trees.values.toList()
    val items: List<GroundItem> get() = state.items.values.toList()
    val decorations: List<Decoration> get() = state.decorations
    val buildings: List<Building> get() = state.buildings.values.toList()
    val obstacles: List<Obstacle> get() = state.obstacles()

    /** Progress of the current impact cycle, 0..1, or 0 when not working. */
    val workProgress: Double
        get() {
            val working = player.activity as? Activity.Working ?: return 0.0
            return working.elapsedMs / workFor(working.intent).intervalMs
        }

    /** Where the player is heading or what it is working on, if anything. */
    val playerTarget: Position?
        get() = when (val activity = player.activity) {
            is Activity.Walking -> activity.destination
            is Activity.Working -> workFor(activity.intent).target(state)?.position
            Activity.Idle -> null
        }

    fun movePlayerTo(destination: Position) = navigation.walkTo(destination)

    /** Sends the player to chop a tree. Requires an axe. */
    fun orderChop(treeId: String): ChopResult {
        val result = Woodcutting.check(state, treeId)
        if (result == ChopResult.Ok) navigation.goWorkOn(Intent.Chop(treeId))
        return result
    }

    /** Pays for a building, places its site and sends the player to construct it. */
    fun orderConstruction(blueprint: Blueprint, position: Position): ConstructionResult {
        val result = Construction.place(state, blueprint, position)
        if (result is ConstructionResult.Started) navigation.goWorkOn(Intent.Construct(result.building.id))
        return result
    }

    fun canPlace(blueprint: Blueprint, position: Position): Boolean = Construction.canPlace(state, blueprint, position)

    fun advance(deltaMs: Double): List<GameEvent> {
        val events = mutableListOf<GameEvent>()
        when (val activity = player.activity) {
            is Activity.Walking -> navigation.step(deltaMs, activity, events)
            is Activity.Working -> work(deltaMs, activity, events)
            Activity.Idle -> Unit
        }
        pickUpItems(state, events)
        return events
    }

    /** Test seam: prepares a player state without going through the game rules. */
    internal fun updatePlayer(transform: (Player) -> Player) {
        state.player = transform(state.player)
    }

    /** Generic work loop: one impact per interval until the work reports it is finished. */
    private fun work(deltaMs: Double, activity: Activity.Working, events: MutableList<GameEvent>) {
        val work = workFor(activity.intent)
        if (work.target(state) == null) {
            state.player = state.player.stop()
            return
        }
        val elapsed = activity.elapsedMs + deltaMs
        if (elapsed < work.intervalMs) {
            state.player = state.player.continueWork(elapsed)
            return
        }
        state.player = state.player.continueWork(elapsed - work.intervalMs)
        if (work.impact(state, events)) state.player = state.player.stop()
    }

    companion object
}
```

- [ ] **Step 8: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS (todos los tests de dominio en los tres targets).

- [ ] **Step 9: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add the World aggregate and its gameplay systems to the shared domain"
```

---

### Task 6: Misiones — `Quest`, `QuestLog`

**Files:**
- Create: `domain/quests/Quest.kt`, `domain/quests/QuestLog.kt`, `domain/entities/game/QuestProgress.kt`
- Test: `domain/quests/QuestLogTests.kt`

**Interfaces:**
- Consumes: `World`, `QuestId`, `GameEvent.QuestCompleted`.
- Produces: `interface Quest { val id: QuestId; val target: Int; fun progress(world: World): Int }`, `object Quests { val all: List<Quest> }`, `class QuestLog(quests: List<Quest> = Quests.all)` con `update(world): List<GameEvent.QuestCompleted>` y `status(world): List<QuestProgress>`; `data class QuestProgress(id: QuestId, progress: Int, target: Int, isCompleted: Boolean, isCurrent: Boolean)`.

- [ ] **Step 1: Escribir los tests**

```kotlin
package com.apergas.rpg.domain.quests

import com.apergas.rpg.domain.entities.building.Blueprints
import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.advanceFor
import com.apergas.rpg.domain.world.mock
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class QuestLogTests {
    @Test
    fun testWhenGameStartsThenEveryQuestIsPendingAndTheFirstIsCurrent() {
        // given
        val world = World.mock()

        // when
        val status = QuestLog().status(world)

        // then
        assertEquals(
            listOf(
                QuestProgress(QuestId.PickUpAxe, progress = 0, target = 1, isCompleted = false, isCurrent = true),
                QuestProgress(QuestId.GatherWood, progress = 0, target = 15, isCompleted = false, isCurrent = false),
                QuestProgress(QuestId.BuildHouse, progress = 0, target = 1, isCompleted = false, isCurrent = false),
            ),
            status,
        )
    }

    @Test
    fun testWhenQuestIsFulfilledThenItIsReportedOnlyOnce() {
        // given
        val world = World.mock()
        val questLog = QuestLog()
        world.updatePlayer { it.withInventory(it.inventory.addTool(ToolKind.Axe)) }

        // when
        val first = questLog.update(world)
        val second = questLog.update(world)

        // then
        assertEquals(listOf(GameEvent.QuestCompleted(QuestId.PickUpAxe)), first)
        assertTrue(second.isEmpty())
    }

    @Test
    fun testWhenWoodIsSpentAfterCompletingThenWoodQuestStaysCompleted() {
        // given
        val world = World.mock()
        val questLog = QuestLog()
        world.updatePlayer { it.withInventory(it.inventory.addWood(16)) }
        questLog.update(world)

        // when
        world.updatePlayer { it.withInventory(it.inventory.spendWood(16)!!) }

        // then
        val woodQuest = questLog.status(world).first { it.id == QuestId.GatherWood }
        assertEquals(QuestProgress(QuestId.GatherWood, progress = 15, target = 15, isCompleted = true, isCurrent = false), woodQuest)
    }

    @Test
    fun testWhenProgressExceedsTargetThenItIsCapped() {
        // given
        val world = World.mock()
        world.updatePlayer { it.withInventory(it.inventory.addWood(40)) }

        // when
        val woodQuest = QuestLog().status(world).first { it.id == QuestId.GatherWood }

        // then
        assertEquals(15, woodQuest.progress)
    }

    @Test
    fun testWhenHouseIsOnlyPlacedThenBuildQuestIsNotCompleted() {
        // given
        val world = World.mock()
        val questLog = QuestLog()
        world.updatePlayer { it.withInventory(it.inventory.addWood(15)) }
        questLog.update(world)
        world.orderConstruction(Blueprints.house, Position(300.0, 100.0))

        // when
        val whilePlaced = questLog.update(world)
        world.advanceFor(10_000.0)
        val whenFinished = questLog.update(world)

        // then
        assertTrue(whilePlaced.isEmpty())
        assertEquals(listOf(GameEvent.QuestCompleted(QuestId.BuildHouse)), whenFinished)
    }
}
```

(`spendWood(16)!!` en un test es aceptable: el `given` ha añadido justo 16.)

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.domain.quests.*"`
Expected: FAIL — `Unresolved reference: QuestLog`.

- [ ] **Step 3: Implementar**

`QuestProgress.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.quests.QuestId

data class QuestProgress(
    val id: QuestId,
    val progress: Int,
    val target: Int,
    val isCompleted: Boolean,
    /** The first unfinished quest: what the player should do next. */
    val isCurrent: Boolean,
)
```

`Quest.kt`:
```kotlin
package com.apergas.rpg.domain.quests

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.world.World

/** A goal measured against the world: done once [progress] reaches [target]. */
interface Quest {
    val id: QuestId
    val target: Int
    fun progress(world: World): Int
}

object Quests {
    val all: List<Quest> = listOf(
        quest(QuestId.PickUpAxe, target = 1) { if (it.player.inventory.hasTool(ToolKind.Axe)) 1 else 0 },
        quest(QuestId.GatherWood, target = 15) { it.player.inventory.wood },
        quest(QuestId.BuildHouse, target = 1) { world ->
            world.buildings.count { it.isComplete && it.blueprint.id == BlueprintId.House }
        },
    )

    private fun quest(id: QuestId, target: Int, measure: (World) -> Int): Quest = object : Quest {
        override val id = id
        override val target = target
        override fun progress(world: World) = measure(world)
    }
}
```

`QuestLog.kt`:
```kotlin
package com.apergas.rpg.domain.quests

import com.apergas.rpg.domain.entities.game.GameEvent
import com.apergas.rpg.domain.entities.game.QuestProgress
import com.apergas.rpg.domain.world.World

/** Tracks which quests are done. Completion is permanent; quests can be completed in any order. */
class QuestLog(private val quests: List<Quest> = Quests.all) {
    private val completed = mutableSetOf<QuestId>()

    /** Marks newly fulfilled quests as completed and reports them. */
    fun update(world: World): List<GameEvent.QuestCompleted> =
        quests.filter { it.id !in completed && it.progress(world) >= it.target }
            .map { quest ->
                completed += quest.id
                GameEvent.QuestCompleted(quest.id)
            }

    fun status(world: World): List<QuestProgress> {
        val currentId = quests.firstOrNull { it.id !in completed }?.id
        return quests.map { quest ->
            val isCompleted = quest.id in completed
            QuestProgress(
                id = quest.id,
                progress = if (isCompleted) quest.target else minOf(quest.progress(world), quest.target),
                target = quest.target,
                isCompleted = isCompleted,
                isCurrent = quest.id == currentId,
            )
        }
    }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add quests to the shared domain"
```

---

### Task 7: Contratos de repositorio y entidades de lectura

**Files:**
- Create: `domain/entities/game/GameSession.kt`, `PlayerStatus.kt`, `WorldSnapshot.kt`, `BuildOption.kt`
- Create: `domain/repositories/level/LevelRepository.kt`, `domain/repositories/session/GameSessionRepository.kt`

**Interfaces:**
- Produces:
  - `data class GameSession(val world: World, val quests: QuestLog)`
  - `enum class PlayerActivity { Idle, Walking, Chopping, Constructing }`; `data class PlayerStatus(position, activity: PlayerActivity, target: Position?, swingProgress: Double, wood: Int, hasAxe: Boolean)`
  - `data class WorldSnapshot(width, height, trees: List<Tree>, items: List<GroundItem>, decorations: List<Decoration>, buildings: List<Building>)`
  - `data class BuildOption(blueprint: BlueprintId, woodCost: Int, isAffordable: Boolean)`
  - `interface LevelRepository { fun load(): World }`
  - `interface GameSessionRepository { fun current(): GameSession; fun save(session: GameSession) }`

- [ ] **Step 1: Escribir los ficheros**

`GameSession.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.world.World

/** Everything that makes up a game in progress. */
data class GameSession(val world: World, val quests: QuestLog)
```

`PlayerStatus.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.geometry.Position

enum class PlayerActivity { Idle, Walking, Chopping, Constructing }

data class PlayerStatus(
    val position: Position,
    val activity: PlayerActivity,
    /** What the player is walking to or working on, if anything. */
    val target: Position?,
    /** Progress of the current swing, 0..1, while chopping or constructing. */
    val swingProgress: Double,
    val wood: Int,
    val hasAxe: Boolean,
)
```

`WorldSnapshot.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.Building
import com.apergas.rpg.domain.entities.decoration.Decoration
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.tree.Tree

/** Everything placed in the world at a given moment, to draw it from scratch. */
data class WorldSnapshot(
    val width: Double,
    val height: Double,
    val trees: List<Tree>,
    val items: List<GroundItem>,
    val decorations: List<Decoration>,
    val buildings: List<Building>,
)
```

`BuildOption.kt`:
```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.BlueprintId

data class BuildOption(val blueprint: BlueprintId, val woodCost: Int, val isAffordable: Boolean)
```

`LevelRepository.kt`:
```kotlin
package com.apergas.rpg.domain.repositories.level

import com.apergas.rpg.domain.world.World

/** Provides the world a new game starts in. */
interface LevelRepository {
    fun load(): World
}
```

`GameSessionRepository.kt`:
```kotlin
package com.apergas.rpg.domain.repositories.session

import com.apergas.rpg.domain.entities.game.GameSession

/** Where the current game lives. Use cases fetch it on every call. */
interface GameSessionRepository {
    fun current(): GameSession
    fun save(session: GameSession)
}
```

- [ ] **Step 2: Compilar y ejecutar todo**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add repository contracts and read entities to the shared domain"
```

---

## Self-review de la fase

- [ ] Los tests de dominio de TypeScript (`rpg/tests/domain/*`) tienen todos su equivalente Kotlin: Position (5→6), Player (5), Inventory (3), Tree/Building (2→3), World movement (3), items (1), chopping (7), construction (6), QuestLog (5).
- [ ] `grep -rn "import android\|import platform\|import kotlin.js" shared/src/commonMain` no devuelve nada.
- [ ] Ninguna entidad de `entities/` tiene `var`.
