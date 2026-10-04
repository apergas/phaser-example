# Fase 3 — Capa de datos

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar la generación del nivel y la sesión en memoria a `shared/.../data/` siguiendo la convención de datos de Android (datasource interfaz + impl, DTO todo-nullable, mappers `internal` junto al repositorio, `ErrorHandler`), garantizando que el bosque generado es **idéntico** al de TypeScript.

**Architecture:** `LevelLocalDataSourceImpl` (generador procedimental con semilla) devuelve `LevelDto`; `LevelMappers.kt` (`LevelDto.toDomain()`) valida y construye el `World`; `LevelRepositoryImpl` envuelve la llamada y traduce errores con `ErrorHandler`. La sesión vive en `GameSessionLocalDataSourceImpl` (memoria) detrás de `GameSessionRepositoryImpl`.

**Tech Stack:** Kotlin common, kotlinx.serialization (anotaciones en DTOs, preparadas para leer niveles JSON/Tiled), kotlin.test.

## Global Constraints

Las de [`README.md`](README.md#global-constraints). En esta fase: DTOs con todos los campos nullable y `@Serializable`; mappers `internal`, extensión `toDomain()`, en `<Feature>Mappers.kt` junto a su `RepositoryImpl` (no hay carpeta `mappers/`); los repositorios inyectan datasources y `ErrorHandler`, nunca otra cosa; cada llamada al datasource va en `try/catch` y relanza `errorHandler.handle(error)`.

## File Structure

```
shared/src/commonMain/kotlin/com/apergas/rpg/
  util/SeededRandom.kt
  data/
    errors/DataErrorHandlerImpl.kt
    datasources/local/
      level/      LevelLocalDataSource.kt, LevelLocalDataSourceImpl.kt, dto/LevelDto.kt
      session/    GameSessionLocalDataSource.kt, GameSessionLocalDataSourceImpl.kt
    repositories/
      level/      LevelRepositoryImpl.kt, LevelMappers.kt
      session/    GameSessionRepositoryImpl.kt

shared/src/commonTest/kotlin/com/apergas/rpg/
  util/SeededRandomTests.kt
  data/
    datasources/local/level/LevelDtoMock.kt, LevelLocalDataSourceMock.kt, LevelLocalDataSourceImplTests.kt
    datasources/local/session/GameSessionLocalDataSourceMock.kt
    repositories/level/LevelRepositoryImplTests.kt
    repositories/session/GameSessionRepositoryImplTests.kt
```

**Valores dorados** (extraídos del TypeScript actual el 2026-10-04 con `seededRandom(42)` y `ProceduralForestLevelDataSource`):

| Dato | Valor |
|---|---|
| `SeededRandom(42)`, 5 primeros | `0.2523451747838408`, `0.08812504541128874`, `0.5772811982315034`, `0.22255426598712802`, `0.37566019711084664` |
| Nº de árboles | `70` |
| `tree-1` | `x = 433.47085868008435`, `y = 155.17504904419184`, `wood = 6` |
| `tree-2` | `x = 389.38031366094947`, `y = 465.71301287971437`, `wood = 5` |
| `tree-3` | `x = 721.9763031136245`, `y = 187.9368040524423`, `wood = 6` |
| `tree-70` | `x = 1487.0892029069364`, `y = 676.5116280969232`, `wood = 6` |
| Madera total | `388` |
| Hacha | `id = "axe"`, `kind = "axe"`, `(856, 608)` |
| Inicio | `(800, 600)` |

---

### Task 1: `SeededRandom` idéntico al de TypeScript

**Files:**
- Create: `shared/src/commonMain/kotlin/com/apergas/rpg/util/SeededRandom.kt`
- Test: `shared/src/commonTest/kotlin/com/apergas/rpg/util/SeededRandomTests.kt`

**Interfaces:**
- Produces: `class SeededRandom(seed: Long) { fun next(): Double }` — valores en `[0, 1)`; misma secuencia que `rpg/src/shared/seededRandom.ts`. La usan el generador de niveles (esta fase) y las vistas de Android/iOS para elegir variantes de árbol y decoración (fases 7 y 8).

- [ ] **Step 1: Test con valores dorados**

```kotlin
package com.apergas.rpg.util

import kotlin.test.Test
import kotlin.test.assertEquals

class SeededRandomTests {
    @Test
    fun testWhenSeededWith42ThenProducesTheSameSequenceAsTheWebVersion() {
        // given
        val random = SeededRandom(42)

        // when
        val values = List(5) { random.next() }

        // then
        assertEquals(
            listOf(0.2523451747838408, 0.08812504541128874, 0.5772811982315034, 0.22255426598712802, 0.37566019711084664),
            values,
        )
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.util.*"`
Expected: FAIL — `Unresolved reference: SeededRandom`.

- [ ] **Step 3: Implementar**

```kotlin
package com.apergas.rpg.util

/**
 * Deterministic pseudo-random generator (LCG): same seed, same sequence, on every platform and
 * identical to the web version, so levels and decor look the same everywhere.
 */
class SeededRandom(seed: Long) {
    private var state = seed and MASK

    /** Next value in [0, 1). */
    fun next(): Double {
        state = (state * MULTIPLIER + INCREMENT) and MASK
        return state.toDouble() / MODULUS
    }

    private companion object {
        const val MULTIPLIER = 1_664_525L
        const val INCREMENT = 1_013_904_223L
        const val MASK = 0xFFFF_FFFFL
        const val MODULUS = 4_294_967_296.0
    }
}
```

- [ ] **Step 4: Ejecutar en los tres targets**

Run: `./gradlew :shared:allTests`
Expected: PASS también en `jsBrowserTest` (Kotlin/JS emula `Long` con exactitud).

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add seeded random generator matching the web implementation"
```

---

### Task 2: `LevelDto` y datasource local del nivel (generador procedimental)

**Files:**
- Create: `data/datasources/local/level/dto/LevelDto.kt`, `LevelLocalDataSource.kt`, `LevelLocalDataSourceImpl.kt`
- Test: `data/datasources/local/level/LevelLocalDataSourceImplTests.kt`

**Interfaces:**
- Consumes: `SeededRandom` (Task 1).
- Produces:
  - `@Serializable data class LevelDto(width: Double?, height: Double?, playerStart: PointDto?, trees: List<TreeDto>?, items: List<ItemDto>?)`, `PointDto(x: Double?, y: Double?)`, `TreeDto(id: String?, x: Double?, y: Double?, wood: Int?)`, `ItemDto(id: String?, kind: String?, x: Double?, y: Double?)`, todos con `companion object`
  - `interface LevelLocalDataSource { fun fetch(): LevelDto }`
  - `class LevelLocalDataSourceImpl : LevelLocalDataSource`

- [ ] **Step 1: Tests con valores dorados**

```kotlin
package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto
import kotlin.math.hypot
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LevelLocalDataSourceImplTests {
    private val sut = LevelLocalDataSourceImpl()

    @Test
    fun testWhenFetchingTwiceThenReturnsTheSameForest() {
        // given
        val first = sut.fetch()

        // when
        val second = sut.fetch()

        // then
        assertEquals(first, second)
    }

    @Test
    fun testWhenFetchingThenForestMatchesTheWebVersionExactly() {
        // given
        val expectedFirstTrees = listOf(
            TreeDto(id = "tree-1", x = 433.47085868008435, y = 155.17504904419184, wood = 6),
            TreeDto(id = "tree-2", x = 389.38031366094947, y = 465.71301287971437, wood = 5),
            TreeDto(id = "tree-3", x = 721.9763031136245, y = 187.9368040524423, wood = 6),
        )

        // when
        val level = sut.fetch()
        val trees = level.trees.orEmpty()

        // then
        assertEquals(1600.0, level.width)
        assertEquals(1200.0, level.height)
        assertEquals(PointDto(800.0, 600.0), level.playerStart)
        assertEquals(70, trees.size)
        assertEquals(expectedFirstTrees, trees.take(3))
        assertEquals(TreeDto(id = "tree-70", x = 1487.0892029069364, y = 676.5116280969232, wood = 6), trees.last())
        assertEquals(388, trees.sumOf { it.wood ?: 0 })
        assertEquals(listOf(ItemDto(id = "axe", kind = "axe", x = 856.0, y = 608.0)), level.items)
    }

    @Test
    fun testWhenFetchingThenTreesKeepClearOfTheSpawnPoint() {
        // given
        val level = sut.fetch()

        // when
        val closest = level.trees.orEmpty().minOf { hypot((it.x ?: 0.0) - 800.0, (it.y ?: 0.0) - 600.0) }

        // then
        assertTrue(closest >= 200.0)
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.data.datasources.*"`
Expected: FAIL — `Unresolved reference: LevelLocalDataSourceImpl`.

- [ ] **Step 3: Implementar**

`dto/LevelDto.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.level.dto

import kotlinx.serialization.Serializable

/** A level as it comes from its source (generator, Tiled map, JSON file): untrusted, every field optional. */
@Serializable
data class LevelDto(
    val width: Double? = null,
    val height: Double? = null,
    val playerStart: PointDto? = null,
    val trees: List<TreeDto>? = null,
    val items: List<ItemDto>? = null,
) {
    companion object
}

@Serializable
data class PointDto(val x: Double? = null, val y: Double? = null) {
    companion object
}

@Serializable
data class TreeDto(val id: String? = null, val x: Double? = null, val y: Double? = null, val wood: Int? = null) {
    companion object
}

@Serializable
data class ItemDto(val id: String? = null, val kind: String? = null, val x: Double? = null, val y: Double? = null) {
    companion object
}
```

`LevelLocalDataSource.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.LevelDto

interface LevelLocalDataSource {
    fun fetch(): LevelDto
}
```

`LevelLocalDataSourceImpl.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto
import com.apergas.rpg.util.SeededRandom
import kotlin.math.floor
import kotlin.math.hypot

private const val WIDTH = 1600.0
private const val HEIGHT = 1200.0
private const val TREE_COUNT = 70
private const val MIN_TREE_SPACING = 120.0
/** Canopies are tall and drawn above the trunk, so trees near the spawn would hide the player and the axe. */
private const val SPAWN_CLEARANCE = 200.0
private const val BORDER_MARGIN = 60.0
private const val MIN_WOOD = 5
private const val MAX_WOOD = 6
private const val SEED = 42L
private val PLAYER_START = PointDto(WIDTH / 2, HEIGHT / 2)
/** Close to the spawn point, so it is the first thing the player finds. */
private val AXE = ItemDto(id = "axe", kind = "axe", x = WIDTH / 2 + 56, y = HEIGHT / 2 + 8)

/** A forest generated from a fixed seed: the same layout on every run and on every platform. */
class LevelLocalDataSourceImpl : LevelLocalDataSource {
    override fun fetch(): LevelDto = LevelDto(
        width = WIDTH,
        height = HEIGHT,
        playerStart = PLAYER_START,
        trees = scatterTrees(),
        items = listOf(AXE),
    )

    /** Random but reproducible spots, trees kept apart from each other and away from the spawn. */
    private fun scatterTrees(): List<TreeDto> {
        val random = SeededRandom(SEED)
        val trees = mutableListOf<TreeDto>()
        val start = PLAYER_START

        var attempt = 0
        while (attempt < TREE_COUNT * 50 && trees.size < TREE_COUNT) {
            attempt++
            val x = BORDER_MARGIN + random.next() * (WIDTH - BORDER_MARGIN * 2)
            val y = BORDER_MARGIN + random.next() * (HEIGHT - BORDER_MARGIN * 2)
            val clearOfSpawn = hypot(x - start.x!!, y - start.y!!) >= SPAWN_CLEARANCE
            val apart = trees.all { hypot(x - it.x!!, y - it.y!!) >= MIN_TREE_SPACING }
            if (clearOfSpawn && apart) {
                val wood = MIN_WOOD + floor(random.next() * (MAX_WOOD - MIN_WOOD + 1)).toInt()
                trees += TreeDto(id = "tree-${trees.size + 1}", x = x, y = y, wood = wood)
            }
        }
        return trees
    }
}
```

(Los `!!` operan sobre DTOs que este mismo fichero acaba de construir con valores; no hay dato externo.)

- [ ] **Step 4: Ejecutar en los tres targets**

Run: `./gradlew :shared:allTests`
Expected: PASS. Si `testWhenFetchingThenForestMatchesTheWebVersionExactly` falla en algún target, **no** relajar el test: buscar la diferencia en el orden de llamadas a `random.next()` comparando con `rpg/src/data/datasources/ProceduralForestLevelDataSource.ts`.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add procedural forest level datasource identical to the web version"
```

---

### Task 3: `ErrorHandler` de datos, mappers y `LevelRepositoryImpl`

**Files:**
- Create: `data/errors/DataErrorHandlerImpl.kt`, `data/repositories/level/LevelMappers.kt`, `data/repositories/level/LevelRepositoryImpl.kt`
- Test: `data/datasources/local/level/LevelDtoMock.kt`, `LevelLocalDataSourceMock.kt`, `data/repositories/level/LevelRepositoryImplTests.kt`

**Interfaces:**
- Consumes: `LevelDto`, `LevelLocalDataSource` (Task 2); `World`, `Player`, `Tree`, `GroundItem`, `Rules`, `AppError`, `ErrorHandler`, `LevelRepository` (fase 2).
- Produces: `class DataErrorHandlerImpl : ErrorHandler`; `internal fun LevelDto.toDomain(): World`; `class LevelRepositoryImpl(localDataSource: LevelLocalDataSource, errorHandler: ErrorHandler) : LevelRepository`.

- [ ] **Step 1: Mocks**

`LevelDtoMock.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto

val LevelDto.Companion.mock: LevelDto
    get() = LevelDto(
        width = 400.0,
        height = 300.0,
        playerStart = PointDto(200.0, 150.0),
        trees = listOf(TreeDto(id = "tree-a", x = 50.0, y = 60.0, wood = 5)),
        items = listOf(ItemDto(id = "axe", kind = "axe", x = 220.0, y = 150.0)),
    )

val LevelDto.Companion.mockWithUnknownItem: LevelDto
    get() = mock.copy(items = listOf(ItemDto(id = "mystery", kind = "laser", x = 0.0, y = 0.0)))

val LevelDto.Companion.mockWithoutSize: LevelDto
    get() = mock.copy(width = null)
```

`LevelLocalDataSourceMock.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.LevelDto

class LevelLocalDataSourceMock : LevelLocalDataSource {
    var error: Throwable? = null
    var levelDto: LevelDto = LevelDto.mock
    var fetchCalled = false

    override fun fetch(): LevelDto {
        fetchCalled = true
        error?.let { throw it }
        return levelDto
    }
}
```

- [ ] **Step 2: Tests del repositorio**

```kotlin
package com.apergas.rpg.data.repositories.level

import com.apergas.rpg.data.datasources.local.level.LevelLocalDataSourceMock
import com.apergas.rpg.data.datasources.local.level.mockWithUnknownItem
import com.apergas.rpg.data.datasources.local.level.mockWithoutSize
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.errors.DataErrorHandlerImpl
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.errors.AppError
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class LevelRepositoryImplTests {
    private lateinit var localDataSource: LevelLocalDataSourceMock
    private lateinit var sut: LevelRepositoryImpl

    @BeforeTest
    fun setUp() {
        localDataSource = LevelLocalDataSourceMock()
        sut = LevelRepositoryImpl(localDataSource, DataErrorHandlerImpl())
    }

    @Test
    fun testWhenLoadWithSuccessThenBuildsTheWorldWithDomainRules() {
        // given
        // localDataSource.levelDto is LevelDto.mock by default

        // when
        val world = sut.load()

        // then
        assertTrue(localDataSource.fetchCalled)
        assertEquals(400.0, world.width)
        assertEquals(Position(200.0, 150.0), world.player.position)
        assertEquals(110.0, world.player.speed)
        assertEquals("tree-a", world.trees.single().id)
        assertEquals(5, world.trees.single().woodYield)
        assertEquals(12.0, world.trees.single().trunkRadius)
        assertEquals(5, world.trees.single().hitsToFell)
        assertEquals(ToolKind.Axe, world.items.single().kind)
    }

    @Test
    fun testWhenLoadTwiceThenEachWorldIsIndependent() {
        // given
        val first = sut.load()

        // when
        first.movePlayerTo(Position(10.0, 10.0))
        first.advance(1000.0)
        val second = sut.load()

        // then
        assertEquals(Position(200.0, 150.0), second.player.position)
    }

    @Test
    fun testWhenLevelHasUnknownItemKindThenThrowsLevelError() {
        // given
        localDataSource.levelDto = LevelDto.mockWithUnknownItem

        // when
        val error = assertFailsWith<AppError.LevelError.UnknownItemKind> { sut.load() }

        // then
        assertEquals("mystery", error.itemId)
        assertEquals("laser", error.kind)
    }

    @Test
    fun testWhenLevelHasNoSizeThenThrowsInvalidLevel() {
        // given
        localDataSource.levelDto = LevelDto.mockWithoutSize

        // when / then
        assertFailsWith<AppError.LevelError.InvalidLevel> { sut.load() }
    }

    @Test
    fun testWhenDataSourceFailsThenErrorIsRoutedThroughTheHandler() {
        // given
        localDataSource.error = IllegalStateException("disk unavailable")

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.load() }
        assertTrue(localDataSource.fetchCalled)
    }
}
```

- [ ] **Step 3: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.data.repositories.level.*"`
Expected: FAIL — `Unresolved reference: LevelRepositoryImpl`.

- [ ] **Step 4: Implementar**

`DataErrorHandlerImpl.kt`:
```kotlin
package com.apergas.rpg.data.errors

import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.errors.ErrorHandler

/** Controlled errors pass through; anything else becomes a general error. */
class DataErrorHandlerImpl : ErrorHandler {
    override fun handle(error: Throwable): AppError = error as? AppError ?: AppError.GeneralError(error)
}
```

`LevelMappers.kt`:
```kotlin
package com.apergas.rpg.data.repositories.level

import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.item.GroundItem
import com.apergas.rpg.domain.entities.player.Player
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.tree.Tree
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.rules.Rules
import com.apergas.rpg.domain.world.World

internal fun LevelDto.toDomain(): World = World(
    width = width ?: throw AppError.LevelError.InvalidLevel("missing width"),
    height = height ?: throw AppError.LevelError.InvalidLevel("missing height"),
    player = Player(
        position = playerStart?.toDomain() ?: throw AppError.LevelError.InvalidLevel("missing player start"),
        speed = Rules.PLAYER_SPEED,
        radius = Rules.PLAYER_RADIUS,
    ),
    trees = trees.orEmpty().mapIndexed { index, tree -> tree.toDomain(index) },
    items = items.orEmpty().map { it.toDomain() },
)

internal fun PointDto.toDomain(): Position = Position(x ?: 0.0, y ?: 0.0)

internal fun TreeDto.toDomain(index: Int): Tree = Tree(
    id = id ?: "tree-${index + 1}",
    position = Position(x ?: 0.0, y ?: 0.0),
    trunkRadius = Rules.TREE_TRUNK_RADIUS,
    woodYield = wood ?: 0,
    hitsToFell = Rules.HITS_TO_FELL_TREE,
)

internal fun ItemDto.toDomain(): GroundItem {
    val itemId = id.orEmpty()
    val tool = ToolKind.entries.firstOrNull { it.name.equals(kind, ignoreCase = true) }
        ?: throw AppError.LevelError.UnknownItemKind(itemId, kind.orEmpty())
    return GroundItem(id = itemId, kind = tool, position = Position(x ?: 0.0, y ?: 0.0))
}
```

`LevelRepositoryImpl.kt`:
```kotlin
package com.apergas.rpg.data.repositories.level

import com.apergas.rpg.data.datasources.local.level.LevelLocalDataSource
import com.apergas.rpg.domain.errors.ErrorHandler
import com.apergas.rpg.domain.repositories.level.LevelRepository
import com.apergas.rpg.domain.world.World

class LevelRepositoryImpl(
    private val localDataSource: LevelLocalDataSource,
    private val errorHandler: ErrorHandler,
) : LevelRepository {
    override fun load(): World = try {
        localDataSource.fetch().toDomain()
    } catch (error: Throwable) {
        throw errorHandler.handle(error)
    }
}
```

- [ ] **Step 5: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add level repository, mappers and data error handler"
```

---

### Task 4: Sesión de juego en memoria

**Files:**
- Create: `data/datasources/local/session/GameSessionLocalDataSource.kt`, `GameSessionLocalDataSourceImpl.kt`, `data/repositories/session/GameSessionRepositoryImpl.kt`
- Test: `data/datasources/local/session/GameSessionLocalDataSourceMock.kt`, `data/repositories/session/GameSessionRepositoryImplTests.kt`

**Interfaces:**
- Consumes: `GameSession`, `GameSessionRepository`, `ErrorHandler`, `AppError` (fase 2).
- Produces: `interface GameSessionLocalDataSource { fun get(): GameSession?; fun set(session: GameSession) }`, `class GameSessionLocalDataSourceImpl`, `class GameSessionRepositoryImpl(localDataSource, errorHandler) : GameSessionRepository`.

- [ ] **Step 1: Mock y tests**

`GameSessionLocalDataSourceMock.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.session

import com.apergas.rpg.domain.entities.game.GameSession

class GameSessionLocalDataSourceMock : GameSessionLocalDataSource {
    var error: Throwable? = null
    var session: GameSession? = null
    var getCalled = false
    var setCalled = false

    override fun get(): GameSession? {
        getCalled = true
        error?.let { throw it }
        return session
    }

    override fun set(session: GameSession) {
        setCalled = true
        error?.let { throw it }
        this.session = session
    }
}
```

`GameSessionRepositoryImplTests.kt`:
```kotlin
package com.apergas.rpg.data.repositories.session

import com.apergas.rpg.data.datasources.local.session.GameSessionLocalDataSourceMock
import com.apergas.rpg.data.errors.DataErrorHandlerImpl
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertSame
import kotlin.test.assertTrue

class GameSessionRepositoryImplTests {
    private lateinit var localDataSource: GameSessionLocalDataSourceMock
    private lateinit var sut: GameSessionRepositoryImpl

    @BeforeTest
    fun setUp() {
        localDataSource = GameSessionLocalDataSourceMock()
        sut = GameSessionRepositoryImpl(localDataSource, DataErrorHandlerImpl())
    }

    @Test
    fun testWhenSavingThenCurrentReturnsTheSameSession() {
        // given
        val session = GameSession(World.mock(), QuestLog())

        // when
        sut.save(session)
        val current = sut.current()

        // then
        assertTrue(localDataSource.setCalled)
        assertTrue(localDataSource.getCalled)
        assertSame(session, current)
    }

    @Test
    fun testWhenNoGameWasStartedThenCurrentThrowsGeneralError() {
        // given
        localDataSource.session = null

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.current() }
    }

    @Test
    fun testWhenDataSourceFailsThenErrorIsRoutedThroughTheHandler() {
        // given
        localDataSource.error = IllegalStateException("storage unavailable")

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.save(GameSession(World.mock(), QuestLog())) }
    }
}
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `./gradlew :shared:testDebugUnitTest --tests "com.apergas.rpg.data.repositories.session.*"`
Expected: FAIL — `Unresolved reference: GameSessionRepositoryImpl`.

- [ ] **Step 3: Implementar**

`GameSessionLocalDataSource.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.session

import com.apergas.rpg.domain.entities.game.GameSession

interface GameSessionLocalDataSource {
    fun get(): GameSession?
    fun set(session: GameSession)
}
```

`GameSessionLocalDataSourceImpl.kt`:
```kotlin
package com.apergas.rpg.data.datasources.local.session

import com.apergas.rpg.domain.entities.game.GameSession

/** Keeps the session in memory for the lifetime of the app. A save-game datasource would persist it. */
class GameSessionLocalDataSourceImpl : GameSessionLocalDataSource {
    private var session: GameSession? = null

    override fun get(): GameSession? = session

    override fun set(session: GameSession) {
        this.session = session
    }
}
```

`GameSessionRepositoryImpl.kt`:
```kotlin
package com.apergas.rpg.data.repositories.session

import com.apergas.rpg.data.datasources.local.session.GameSessionLocalDataSource
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.errors.ErrorHandler
import com.apergas.rpg.domain.repositories.session.GameSessionRepository

class GameSessionRepositoryImpl(
    private val localDataSource: GameSessionLocalDataSource,
    private val errorHandler: ErrorHandler,
) : GameSessionRepository {
    override fun current(): GameSession = try {
        localDataSource.get() ?: throw AppError.GeneralError(IllegalStateException("No game in progress: call startGame() first"))
    } catch (error: Throwable) {
        throw errorHandler.handle(error)
    }

    override fun save(session: GameSession) = try {
        localDataSource.set(session)
    } catch (error: Throwable) {
        throw errorHandler.handle(error)
    }
}
```

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `./gradlew :shared:allTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add shared/src
git commit -m "[PROJECT-X]: Add in-memory game session datasource and repository"
```

---

## Self-review de la fase

- [ ] Ningún tipo de `data/` aparece en `domain/` (`grep -rn "\.data\." shared/src/commonMain/kotlin/com/apergas/rpg/domain` vacío).
- [ ] Los mappers son `internal` y viven en `LevelMappers.kt` junto a `LevelRepositoryImpl`.
- [ ] El test dorado del bosque pasa en JVM, JS e iOS.
