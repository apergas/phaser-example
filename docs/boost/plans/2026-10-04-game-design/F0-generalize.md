# F0 · Generalizar recursos, herramientas y edificios — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use boost:subagent-driven-development (recommended) or boost:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Read the **Global Constraints** in [README.md](README.md) first; they apply to every task.

**Goal:** Que añadir un recurso, una herramienta o un edificio sea casi sólo añadir datos. Para ello se quitan las suposiciones "madera / hacha / casa" del dominio, del HUD y del dibujo, **sin cambiar la jugabilidad**.

**Architecture:**
- `Inventory` guarda un `Map<Resource, Int>`.
- `Blueprint` tiene un `cost: Map<Resource, Int>`.
- El view model expone listas genéricas de recursos y herramientas.
- `SpriteNames` decide el frame y el desplazamiento de dibujo de cada edificio e ítem.
- Las apps dejan de escribir a mano `"house"`, `"axe-pickup"`, `wood` y `hasAxe`.
- Se aplica *expandir y contraer*:
  - T0.1 añade la API nueva y deja la vieja `@Deprecated`, así las tres apps siguen compilando;
  - T0.2–T0.4 migran cada app (en paralelo);
  - T0.5 borra lo viejo.

**Tech Stack:** Kotlin Multiplatform + kotlin.test, Phaser 4 + TypeScript, Jetpack Compose, SwiftUI + SpriteKit.

**Cómo probar la fase entera:** en las tres apps el juego se comporta como hoy:
- el HUD muestra "Madera N" y el hacha (atenuada hasta recogerla);
- la casa cuesta 15;
- la previsualización y el edificio se dibujan igual que ahora.

Sólo cambian dos textos:
- el que se muestra si faltan recursos;
- el que se muestra al terminar un edificio.

## Reparto

| Tarea | Plataforma | Depende de | Paralelizable |
|---|---|---|---|
| T0.1 `shared` | shared | — | No (bloqueante) |
| T0.2 Web | web | T0.1 | Sí, con T0.3 y T0.4 |
| T0.3 Android | android | T0.1 | Sí |
| T0.4 iOS | ios | T0.1 | Sí |
| T0.5 Quitar API obsoleta | shared + apps | T0.2, T0.3, T0.4 | No |

---

### Task T0.1: `shared`: recursos, costes, HUD genérico y nombres de sprites

**Files:**
- Create:
  - `shared/src/commonMain/kotlin/com/apergas/rpg/domain/entities/player/Resource.kt`
  - `shared/src/commonTest/kotlin/com/apergas/rpg/domain/entities/building/BlueprintsTests.kt`
- Modify:
  - Dominio, en `shared/src/commonMain/kotlin/com/apergas/rpg/domain/`:
    - `entities/player/Inventory.kt`
    - `entities/building/Blueprint.kt`
    - `entities/game/BuildOption.kt`
    - `entities/game/ConstructionResult.kt`
    - `entities/game/PlayerStatus.kt`
    - `world/Construction.kt`
    - `world/Woodcutting.kt`
    - `quests/Quest.kt`
    - `usecases/game/GameUseCaseImpl.kt`
  - Presentación:
    - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/ForestContract.kt`
    - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/ForestLabels.kt`
    - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/ForestViewModel.kt`
    - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/SpriteNames.kt`
  - Web:
    - `shared/src/jsMain/kotlin/com/apergas/rpg/web/WebModels.kt`
    - `shared/src/jsMain/kotlin/com/apergas/rpg/web/WebMappers.kt`
- Test (todo en `shared/src/commonTest/kotlin/com/apergas/rpg/` salvo el último):
  - `domain/entities/player/InventoryTests.kt`: se reescribe.
  - `domain/entities/building/BlueprintsTests.kt`: nuevo.
  - `domain/world/WorldConstructionTests.kt`
  - `domain/world/WorldChoppingTests.kt`
  - `domain/quests/QuestLogTests.kt`
  - `domain/usecases/game/GameUseCaseImplTests.kt`
  - `presentation/forest/ForestViewModelTests.kt`
  - `presentation/forest/SpriteNamesTests.kt`
  - `shared/src/jsTest/kotlin/com/apergas/rpg/web/ForestWebControllerTests.kt`

**Interfaces:**
- Consumes: nada nuevo.
- Produces (lo que usan T0.2–T0.5 y las fases siguientes):
  ```kotlin
  // domain/entities/player/Resource.kt
  enum class Resource { Wood }

  // domain/entities/player/Inventory.kt
  data class Inventory(val resources: Map<Resource, Int> = emptyMap(), val tools: Set<ToolKind> = emptySet()) {
      fun amount(resource: Resource): Int
      fun add(resource: Resource, quantity: Int): Inventory
      fun missing(cost: Map<Resource, Int>): Map<Resource, Int>   // only resources still short, > 0
      fun spend(cost: Map<Resource, Int>): Inventory?             // null when something is missing
      fun addTool(tool: ToolKind): Inventory
      fun hasTool(tool: ToolKind): Boolean
  }

  // domain/entities/building/Blueprint.kt
  data class Blueprint(val id: BlueprintId, val cost: Map<Resource, Int>, val hitsToBuild: Int, val footprintRadius: Double)

  // domain/entities/game/*
  data class BuildOption(val blueprint: BlueprintId, val cost: Map<Resource, Int>, val missing: Map<Resource, Int>) { val isAffordable: Boolean }
  enum class ConstructionRejection { NotEnoughResources, Blocked }
  data class PlayerStatus(position, activity, target, swingProgress, val inventory: Inventory)

  // presentation/forest/ForestContract.kt
  data class ResourceItem(val resource: Resource, val name: String, val amount: Int)
  data class ToolItem(val tool: ToolKind, val name: String, val isOwned: Boolean)
  data class HudState(
      val resources: List<ResourceItem>, val tools: List<ToolItem>,
      @Deprecated val wood: Int, @Deprecated val hasAxe: Boolean,         // removed in T0.5
      val questBadge: String, val quests: List<QuestItem>, val buildItems: List<BuildItem>, val isBuildLocked: Boolean,
  )

  // presentation/forest/ForestLabels.kt
  fun resource(resource: Resource): String      // "Madera"
  fun tool(tool: ToolKind): String              // "Hacha"
  fun cost(cost: Map<Resource, Int>): String    // "15 de madera"
  fun missing(missing: Map<Resource, Int>): String  // "Faltan 5 de madera"
  Messages.NOT_ENOUGH_RESOURCES, Messages.buildingCompleted(name) = "Construcción terminada: $name"

  // presentation/forest/SpriteNames.kt
  fun building(id: BlueprintId): String          // House -> "house"
  fun buildingFrontOffset(id: BlueprintId): Double  // House -> 24.0
  fun item(kind: ToolKind): String               // Axe -> "axe-pickup"

  // jsMain web/WebModels.kt (added; old fields kept until T0.5)
  WebHud.resources: Array<WebResourceItem(id: String /* "wood" */, name: String, amount: Int)>
  WebHud.tools: Array<WebToolItem(id: String /* "axe" */, name: String, isOwned: Boolean)>
  WebItem.frame: String
  WebBuilding.frame: String, WebBuilding.frontOffset: Double
  WebPlacement.frame: String, WebPlacement.frontOffset: Double
  ```

- [ ] **Step 1: Crear la rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f0-shared
```

- [ ] **Step 2: Escribir el test de `Inventory`, que debe fallar**

Sustituir el contenido de `shared/src/commonTest/kotlin/com/apergas/rpg/domain/entities/player/InventoryTests.kt` por:

```kotlin
package com.apergas.rpg.domain.entities.player

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class InventoryTests {
    @Test
    fun testWhenAddingResourcesThenAmountAccumulates() {
        // given
        val inventory = Inventory()

        // when
        val updated = inventory.add(Resource.Wood, 4).add(Resource.Wood, 2)

        // then
        assertEquals(0, inventory.amount(Resource.Wood))
        assertEquals(6, updated.amount(Resource.Wood))
    }

    @Test
    fun testWhenSpendingAnAffordableCostThenReturnsInventoryWithTheRest() {
        // given
        val inventory = Inventory().add(Resource.Wood, 6)

        // when
        val afterSpending = inventory.spend(mapOf(Resource.Wood to 4))

        // then
        assertEquals(2, afterSpending?.amount(Resource.Wood))
    }

    @Test
    fun testWhenSpendingMoreThanStoredThenReturnsNullAndReportsWhatIsMissing() {
        // given
        val inventory = Inventory().add(Resource.Wood, 3)
        val cost = mapOf(Resource.Wood to 5)

        // when
        val afterSpending = inventory.spend(cost)
        val missing = inventory.missing(cost)

        // then
        assertNull(afterSpending)
        assertEquals(mapOf(Resource.Wood to 2), missing)
        assertEquals(3, inventory.amount(Resource.Wood))
    }

    @Test
    fun testWhenNothingIsMissingThenMissingIsEmpty() {
        // given
        val inventory = Inventory().add(Resource.Wood, 15)

        // when
        val missing = inventory.missing(mapOf(Resource.Wood to 15))

        // then
        assertTrue(missing.isEmpty())
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

- [ ] **Step 3: Comprobar que falla**

Run: `./gradlew :shared:testAndroidHostTest --tests "com.apergas.rpg.domain.entities.player.InventoryTests"`
Expected: FAIL de compilación (`Unresolved reference: Resource`, `add`, `amount`).

- [ ] **Step 4: Implementar `Resource` e `Inventory`**

`shared/src/commonMain/kotlin/com/apergas/rpg/domain/entities/player/Resource.kt`:

```kotlin
package com.apergas.rpg.domain.entities.player

/** Raw materials the player gathers and spends. New resources are added here. */
enum class Resource { Wood }
```

`shared/src/commonMain/kotlin/com/apergas/rpg/domain/entities/player/Inventory.kt`:

```kotlin
package com.apergas.rpg.domain.entities.player

/** What the player carries: stored resources and the tools it has picked up. */
data class Inventory(val resources: Map<Resource, Int> = emptyMap(), val tools: Set<ToolKind> = emptySet()) {
    fun amount(resource: Resource): Int = resources[resource] ?: 0

    fun add(resource: Resource, quantity: Int): Inventory {
        require(quantity >= 0) { "Cannot add a negative amount of $resource" }
        return copy(resources = resources + (resource to amount(resource) + quantity))
    }

    /** What is still short to pay [cost]; empty when it is affordable. */
    fun missing(cost: Map<Resource, Int>): Map<Resource, Int> =
        cost.mapValues { (resource, quantity) -> quantity - amount(resource) }.filterValues { it > 0 }

    /** The inventory after paying [cost], or null when something is missing. */
    fun spend(cost: Map<Resource, Int>): Inventory? {
        if (missing(cost).isNotEmpty()) return null
        return copy(resources = resources + cost.map { (resource, quantity) -> resource to amount(resource) - quantity })
    }

    fun addTool(tool: ToolKind): Inventory = copy(tools = tools + tool)

    fun hasTool(tool: ToolKind): Boolean = tool in tools
}
```

- [ ] **Step 5: Adaptar `Blueprint`, `Construction`, `Woodcutting` y `Quests`**

`Blueprint.kt`: se sustituye `woodCost: Int` por `cost`.

```kotlin
package com.apergas.rpg.domain.entities.building

import com.apergas.rpg.domain.entities.player.Resource

/** What it takes to construct a kind of building. */
data class Blueprint(
    val id: BlueprintId,
    /** Resources paid when the site is placed. */
    val cost: Map<Resource, Int>,
    /** Hammer hits needed to finish it. */
    val hitsToBuild: Int,
    /** Radius of the circular footprint that blocks movement. */
    val footprintRadius: Double,
)

object Blueprints {
    val house = Blueprint(id = BlueprintId.House, cost = mapOf(Resource.Wood to 15), hitsToBuild = 8, footprintRadius = 40.0)
    val all: List<Blueprint> = listOf(house)

    fun of(id: BlueprintId): Blueprint = all.first { it.id == id }
}
```

`ConstructionResult.kt`: `enum class ConstructionRejection { NotEnoughResources, Blocked }`.

`Construction.place`:

```kotlin
val paid = state.player.inventory.spend(blueprint.cost)
    ?: return ConstructionResult.Rejected(ConstructionRejection.NotEnoughResources)
```

`Woodcutting.impact`: cambia la línea que suma la madera.

```kotlin
state.player = state.player.withInventory(state.player.inventory.add(Resource.Wood, tree.woodYield))
```

`Quest.kt`:

```kotlin
quest(QuestId.GatherWood, target = 15) { it.player.inventory.amount(Resource.Wood) },
```

Hay que añadir los `import com.apergas.rpg.domain.entities.player.Resource` necesarios.

- [ ] **Step 6: Adaptar los tests de dominio a la API nueva**

Patrón de sustitución en `WorldConstructionTests.kt`, `WorldChoppingTests.kt` y `QuestLogTests.kt`. Se añade `import com.apergas.rpg.domain.entities.player.Resource`.

| Antes | Después |
|---|---|
| `inventory.addWood(n)` | `inventory.add(Resource.Wood, n)` |
| `inventory.spendWood(n)!!` | `inventory.spend(mapOf(Resource.Wood to n))!!` |
| `inventory.wood` | `inventory.amount(Resource.Wood)` |
| `ConstructionRejection.NotEnoughWood` | `ConstructionRejection.NotEnoughResources` |

Además, `testWhenConstructingWithoutEnoughWoodThenIsRejected` pasa a llamarse `testWhenConstructingWithoutEnoughResourcesThenIsRejected`.

Crear `shared/src/commonTest/kotlin/com/apergas/rpg/domain/entities/building/BlueprintsTests.kt`:

```kotlin
package com.apergas.rpg.domain.entities.building

import com.apergas.rpg.domain.entities.player.Resource
import kotlin.test.Test
import kotlin.test.assertEquals

class BlueprintsTests {
    @Test
    fun testWhenLookingUpTheHouseThenCostsFifteenWood() {
        // given
        val id = BlueprintId.House

        // when
        val blueprint = Blueprints.of(id)

        // then
        assertEquals(mapOf(Resource.Wood to 15), blueprint.cost)
        assertEquals(8, blueprint.hitsToBuild)
    }
}
```

Run: `./gradlew :shared:testAndroidHostTest --tests "com.apergas.rpg.domain.*"`
Expected: FAIL sólo en `GameUseCaseImplTests` (`wood`, `hasAxe`, `woodCost`). Lo resuelve el paso siguiente.

- [ ] **Step 7: `PlayerStatus`, `BuildOption` y `GameUseCaseImpl`**

`PlayerStatus.kt`: se sustituyen `wood` y `hasAxe` por el inventario completo.

```kotlin
data class PlayerStatus(
    val position: Position,
    val activity: PlayerActivity,
    /** What the player is walking to or working on, if anything. */
    val target: Position?,
    /** Progress of the current swing, 0..1, while chopping or constructing. */
    val swingProgress: Double,
    val inventory: Inventory,
)
```

`BuildOption.kt`:

```kotlin
package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.player.Resource

data class BuildOption(val blueprint: BlueprintId, val cost: Map<Resource, Int>, val missing: Map<Resource, Int>) {
    val isAffordable: Boolean get() = missing.isEmpty()
}
```

`GameUseCaseImpl`:

```kotlin
override fun playerStatus(): PlayerStatus {
    val world = world
    val player = world.player
    return PlayerStatus(
        position = player.position,
        activity = player.activity.toPlayerActivity(),
        target = world.playerTarget,
        swingProgress = world.workProgress,
        inventory = player.inventory,
    )
}

override fun buildOptions(): List<BuildOption> {
    val inventory = world.player.inventory
    return Blueprints.all.map { BuildOption(it.id, it.cost, inventory.missing(it.cost)) }
}
```

Se elimina el import de `ToolKind` si queda sin uso.

En `GameUseCaseImplTests.kt`:

| Antes | Después |
|---|---|
| `sut.playerStatus().wood` | `sut.playerStatus().inventory.amount(Resource.Wood)` |
| `status.hasAxe` | `status.inventory.hasTool(ToolKind.Axe)` |
| `Player.mock.inventory.addWood(10)` | `Player.mock.inventory.add(Resource.Wood, 10)` |

La aserción de `testWhenWoodIsNotEnoughThenHouseIsNotAffordable` queda así:

```kotlin
assertEquals(
    listOf(BuildOption(BlueprintId.House, cost = mapOf(Resource.Wood to 15), missing = mapOf(Resource.Wood to 5))),
    options,
)
assertFalse(options.single().isAffordable)
```

Run: `./gradlew :shared:testAndroidHostTest --tests "com.apergas.rpg.domain.*"`
Expected: PASS.

- [ ] **Step 8: Test de `SpriteNames`, que debe fallar**

Añadir a `SpriteNamesTests.kt`:

```kotlin
@Test
fun testWhenNamingBuildingsAndItemsThenFollowsTheAtlasFrameNames() {
    // given
    val house = BlueprintId.House
    val axe = ToolKind.Axe

    // when
    val buildingName = SpriteNames.building(house)
    val frontOffset = SpriteNames.buildingFrontOffset(house)
    val itemName = SpriteNames.item(axe)

    // then
    assertEquals("house", buildingName)
    assertEquals(24.0, frontOffset)
    assertEquals("axe-pickup", itemName)
}
```

Run: `./gradlew :shared:testAndroidHostTest --tests "com.apergas.rpg.presentation.forest.SpriteNamesTests"`
Expected: FAIL (`Unresolved reference: building`).

- [ ] **Step 9: Implementar `SpriteNames`**

```kotlin
package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.tree.TreeKind

/** Atlas frame names (forest.json) for what the level places. Shared so every app draws the same art. */
object SpriteNames {
    fun tree(kind: TreeKind): String = "tree-${kebab(kind.name)}"
    fun decoration(kind: DecorationKind): String = "decor-${kebab(kind.name)}"

    fun building(id: BlueprintId): String = when (id) {
        BlueprintId.House -> "house"
    }

    /**
     * Building sprites pivot on the bottom of their front wall. In the 3/4 view the ground footprint
     * (centred on the domain position) lies behind that wall, so the sprite is drawn this much lower.
     */
    fun buildingFrontOffset(id: BlueprintId): Double = when (id) {
        BlueprintId.House -> 24.0
    }

    fun item(kind: ToolKind): String = when (kind) {
        ToolKind.Axe -> "axe-pickup"
    }

    private fun kebab(name: String): String = name.replace(Regex("(?<!^)([A-Z])"), "-$1").lowercase()
}
```

Run: el mismo comando del paso 8. Expected: PASS.

- [ ] **Step 10: Test del HUD genérico en el view model, que debe fallar**

En `ForestViewModelTests.kt`:
- Se cambian `addWood(n)` por `add(Resource.Wood, n)` y `addTool(ToolKind.Axe).addWood(15)` por `addTool(ToolKind.Axe).add(Resource.Wood, 15)`.
- `hud.wood` y `hud.hasAxe` siguen existiendo, como deprecados, hasta T0.5.

Sustituir `testWhenWoodIsNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace` por:

```kotlin
@Test
fun testWhenResourcesAreNotEnoughThenBuildMenuShowsWhatIsMissingAndRefusesToPlace() = runTest {
    // given
    val world = World.mock()
    world.updatePlayer { it.withInventory(it.inventory.add(Resource.Wood, 10)) }
    val sut = forestViewModelFor(world)
    val effects = sut.collectEffects(backgroundScope, UnconfinedTestDispatcher(testScheduler))
    sut.onIntent(ForestIntent.Tick(16.0))

    // when
    sut.onIntent(ForestIntent.BuildRequested(BlueprintId.House))

    // then
    assertEquals(
        listOf(BuildItem(BlueprintId.House, "Casa", "15 de madera", "Faltan 5 de madera", isEnabled = false)),
        sut.uiState.value.hud.buildItems,
    )
    assertNull(sut.uiState.value.placement)
    assertContains(effects, ForestEffect.ShowMessage("No tienes recursos suficientes."))
}

@Test
fun testWhenRenderingTheHudThenListsEveryResourceAndToolWithOwnership() {
    // given
    val world = World.mock()
    world.updatePlayer { it.withInventory(it.inventory.add(Resource.Wood, 7)) }

    // when
    val sut = forestViewModelFor(world)

    // then
    assertEquals(listOf(ResourceItem(Resource.Wood, "Madera", 7)), sut.uiState.value.hud.resources)
    assertEquals(listOf(ToolItem(ToolKind.Axe, "Hacha", isOwned = false)), sut.uiState.value.hud.tools)
}
```

Si hay algún test que espera el mensaje de edificio terminado `"¡Casa construida!"`, pasa a esperar `"Construcción terminada: Casa"`.

Run: `./gradlew :shared:testAndroidHostTest --tests "com.apergas.rpg.presentation.forest.ForestViewModelTests"`
Expected: FAIL (`Unresolved reference: ResourceItem`).

- [ ] **Step 11: Contrato, textos y view model**

`ForestContract.kt`: añadir los tipos y los campos nuevos y deprecar los viejos.

```kotlin
/** Display-ready HUD content: texts already formatted. */
data class HudState(
    val resources: List<ResourceItem>,
    val tools: List<ToolItem>,
    @Deprecated("Use resources; removed in F0 T0.5") val wood: Int,
    @Deprecated("Use tools; removed in F0 T0.5") val hasAxe: Boolean,
    val questBadge: String,
    val quests: List<QuestItem>,
    val buildItems: List<BuildItem>,
    /** The build menu is locked while a building is being placed. */
    val isBuildLocked: Boolean,
)

data class ResourceItem(val resource: Resource, val name: String, val amount: Int)

data class ToolItem(val tool: ToolKind, val name: String, val isOwned: Boolean)
```

`ForestLabels.kt`: cambiar las funciones de coste y añadir las nuevas. `WOOD` y `AXE` quedan deprecados.

```kotlin
@Deprecated("Use resource(Resource.Wood); removed in F0 T0.5") const val WOOD = "Madera"
@Deprecated("Use tool(ToolKind.Axe); removed in F0 T0.5") const val AXE = "Hacha"

fun resource(resource: Resource) = when (resource) {
    Resource.Wood -> "Madera"
}

fun tool(tool: ToolKind) = when (tool) {
    ToolKind.Axe -> "Hacha"
}

fun cost(cost: Map<Resource, Int>) = amounts(cost)
fun missing(missing: Map<Resource, Int>) = "Faltan ${amounts(missing)}"

private fun amounts(amounts: Map<Resource, Int>) =
    amounts.entries.joinToString(", ") { (resource, quantity) -> "$quantity de ${resource(resource).lowercase()}" }
```

En `ForestLabels.Messages`:
- `NOT_ENOUGH_WOOD` se renombra a `const val NOT_ENOUGH_RESOURCES = "No tienes recursos suficientes."`.
- `buildingCompleted` queda como `fun buildingCompleted(name: String) = "Construcción terminada: $name"`, para que no dé por hecho un nombre femenino.

`ForestViewModel.kt`:
- Sustituir `NOT_ENOUGH_WOOD` por `NOT_ENOUGH_RESOURCES`, en `buildRequested` y en `place`.
- En `place`, la rama `ConstructionRejection.NotEnoughWood` pasa a `ConstructionRejection.NotEnoughResources`.
- En `playerRenderState` se cambia `status.hasAxe` por `status.inventory.hasTool(ToolKind.Axe)`.
- `hudState` queda así:

```kotlin
private fun hudState(status: PlayerStatus, quests: List<QuestProgress>): HudState {
    val inventory = status.inventory
    return HudState(
        resources = Resource.entries.map { ResourceItem(it, ForestLabels.resource(it), inventory.amount(it)) },
        tools = ToolKind.entries.map { ToolItem(it, ForestLabels.tool(it), inventory.hasTool(it)) },
        wood = inventory.amount(Resource.Wood),
        hasAxe = inventory.hasTool(ToolKind.Axe),
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
                costText = ForestLabels.cost(option.cost),
                missingText = if (option.isAffordable) null else ForestLabels.missing(option.missing),
                isEnabled = option.isAffordable,
            )
        },
        isBuildLocked = placement != null,
    )
}
```

Para que el uso interno de los campos deprecados no ensucie la compilación, la función lleva `@Suppress("DEPRECATION")`.

Run: `./gradlew :shared:testAndroidHostTest`
Expected: PASS (todos, incluido `ArchitectureTests`).

- [ ] **Step 12: Modelos web**

Test en `ForestWebControllerTests.kt`. Se añade al final de `testWhenAskingForTheWorldThenTreesAndAxeAreExposed`:

```kotlin
assertEquals("axe-pickup", world.items.single().frame)
```

Se añade también:

```kotlin
@Test
fun testWhenTickingThenHudListsResourcesAndToolsAsPlainValues() {
    // given
    val sut = ForestWebController()

    // when
    sut.tick(16.0)
    val hud = sut.state().hud

    // then
    assertEquals("wood", hud.resources.single().id)
    assertEquals("Madera", hud.resources.single().name)
    assertEquals(0, hud.resources.single().amount)
    assertEquals("axe", hud.tools.single().id)
    assertEquals(false, hud.tools.single().isOwned)
}
```

En `WebModels.kt` se añaden los tipos nuevos; los campos viejos se mantienen.

```kotlin
@JsExport class WebHud(
    val resources: Array<WebResourceItem>,
    val tools: Array<WebToolItem>,
    val wood: Int,          // deprecated: removed in T0.5
    val hasAxe: Boolean,    // deprecated: removed in T0.5
    val questBadge: String,
    val quests: Array<WebQuestItem>,
    val buildItems: Array<WebBuildItem>,
    val isBuildLocked: Boolean,
)

@JsExport class WebResourceItem(val id: String, val name: String, val amount: Int)

@JsExport class WebToolItem(val id: String, val name: String, val isOwned: Boolean)

@JsExport class WebPlacement(val blueprint: String, val frame: String, val frontOffset: Double, val position: WebPoint, val isValid: Boolean)

@JsExport class WebItem(val id: String, val kind: String, val frame: String, val position: WebPoint)

@JsExport class WebBuilding(val id: String, val blueprint: String, val frame: String, val frontOffset: Double, val position: WebPoint, val progress: Double)
```

`WebMappers.kt`:

```kotlin
internal fun Building.toWeb() = WebBuilding(
    id, blueprint.id.name, SpriteNames.building(blueprint.id), SpriteNames.buildingFrontOffset(blueprint.id), position.toWeb(), progress,
)

// in WorldSnapshot.toWeb():
items = items.map { WebItem(it.id, it.kind.name.lowercase(), SpriteNames.item(it.kind), it.position.toWeb()) }.toTypedArray(),

// in ForestState.toWeb(), hud = WebHud(...):
resources = hud.resources.map { WebResourceItem(it.resource.name.lowercase(), it.name, it.amount) }.toTypedArray(),
tools = hud.tools.map { WebToolItem(it.tool.name.lowercase(), it.name, it.isOwned) }.toTypedArray(),

// placement:
placement = placement?.let {
    WebPlacement(it.blueprint.name, SpriteNames.building(it.blueprint), SpriteNames.buildingFrontOffset(it.blueprint), it.position.toWeb(), it.isValid)
},
```

Como en Kotlin/JS `@JsExport` usa los argumentos por posición, hay que revisar cualquier otra llamada a estos constructores con `grep -rn "WebPlacement(\|WebItem(\|WebBuilding(\|WebHud(" shared/src/jsMain`.

`toWeb()` lleva `@Suppress("DEPRECATION")` porque sigue rellenando `wood` y `hasAxe`.

**Compatibilidad de la web actual:**
- `webApp` sigue compilando: sólo se han **añadido** campos.
- Los constructores no se llaman desde TypeScript.

- [ ] **Step 13: Verificación completa de `shared` y de que las apps siguen compilando**

```bash
./gradlew :shared:allTests
./gradlew :shared:jsBrowserProductionLibraryDistribution
cd webApp && npm ci && npm run typecheck && npm test && npm run build && cd ..
./gradlew :androidApp:assembleDebug :androidApp:testDebugUnitTest
xcodebuild build -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: todo en verde. Sólo aparecen *warnings* de deprecación en las apps (`WOOD`, `AXE`, `hud.wood`, `hud.hasAxe`).

- [ ] **Step 14: Commit y PR**

```bash
git add shared
git commit -m "[PROJECT-X]: Generalize inventory, costs and HUD over resources and tools"
```

Después, `/cerrar-tarea`: abre el PR con `Closes #<issue T0.1>`.

**Cómo probarlo a mano:** `cd webApp && npm run dev`. El juego funciona igual que antes, salvo los textos "Faltan 5 de madera" y "Construcción terminada: Casa".

---

### Task T0.2: Web: HUD de recursos y sprites desde `shared`

**Files:**
- Modify:
  - `webApp/src/presentation/screens/forest/hud/Hud.ts`
  - `webApp/src/presentation/screens/forest/hud/hud.css`
  - `webApp/src/presentation/screens/forest/world/BuildingView.ts`
  - `webApp/src/presentation/screens/forest/world/ItemView.ts`
  - `webApp/src/presentation/screens/forest/ForestScene.ts`
  - `webApp/src/presentation/common/assets.ts`

**Interfaces:**
- Consumes (de T0.1):
  - `WebHud.resources: WebResourceItem[] {id, name, amount}`
  - `WebHud.tools: WebToolItem[] {id, name, isOwned}`
  - `WebItem.frame`
  - `WebBuilding.frame` y `WebBuilding.frontOffset`
  - `WebPlacement.frame` y `WebPlacement.frontOffset`
- Produces: un HUD que pinta **cualquier** recurso o herramienta con el icono CSS `hud__icon--<id>`, y `BuildingView` / `ItemView` que dibujan el frame que reciben. Las fases F5–F8 sólo añaden un icono CSS y un frame del atlas.

- [ ] **Step 1: Rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f0-web
./gradlew :shared:jsBrowserProductionLibraryDistribution && (cd webApp && npm ci)
```

- [ ] **Step 2: Sprites de edificios e ítems.** En `BuildingView.ts` se sustituyen `addHouseImage` / `placeHouseImage` por funciones genéricas:

```ts
/** Draws a building where `position` is the centre of its ground footprint. */
export function addBuildingImage(scene: Phaser.Scene, frame: string, frontOffset: number, position: WebPoint): Phaser.GameObjects.Image {
  return placeBuildingImage(scene.add.image(0, 0, ForestAtlas.key, frame), frontOffset, position);
}

/** Anchors a building image to a footprint centre: the front wall sits below it, y-sorted by that wall. */
export function placeBuildingImage(image: Phaser.GameObjects.Image, frontOffset: number, position: WebPoint): Phaser.GameObjects.Image {
  const frontY = position.y + frontOffset;
  return image.setPosition(position.x, frontY).setDepth(Depth.bySortY(frontY));
}
```

El constructor de `BuildingView` queda así:

```ts
constructor(scene: Phaser.Scene, building: WebBuilding) {
  this.scene = scene;
  this.image = addBuildingImage(scene, building.frame, building.frontOffset, building.position);
  this.bar = scene.add.graphics().setDepth(Depth.bySortY(this.image.y) + 1);
  this.setProgress(building.progress);
}
```

`ItemView`:
- El constructor pasa a ser `(scene: Phaser.Scene, item: WebItem)`.
- La imagen usa `item.frame` en lugar de `ForestAtlas.AXE_PICKUP`.
- `position` pasa a ser `item.position`.

`assets.ts`:
- Se borran `AXE_PICKUP`, `HOUSE` y `HOUSE_FRONT_OFFSET` (con su comentario).
- `STUMP` se queda.

- [ ] **Step 3: `ForestScene.ts`**

```ts
for (const item of world.items) this.items.set(item.id, new ItemView(this, item));
for (const building of world.buildings) this.buildings.set(building.id, new BuildingView(this, building));
// building-placed effect:
const view = new BuildingView(this, effect.building);
```

`renderGhost`: si cambia de blueprint, se vuelve a crear el fantasma.

```ts
private renderGhost(placement: WebPlacement | null | undefined): void {
  if (!placement) {
    this.ghost?.destroy();
    this.ghost = null;
    return;
  }
  if (this.ghost?.frame.name !== placement.frame) {
    this.ghost?.destroy();
    this.ghost = addBuildingImage(this, placement.frame, placement.frontOffset, placement.position).setAlpha(GHOST_ALPHA);
  }
  placeBuildingImage(this.ghost, placement.frontOffset, placement.position)
    .setTint(placement.isValid ? GHOST_VALID_TINT : GHOST_INVALID_TINT)
    .setDepth(Depth.OVERLAY);
}
```

Se actualizan los imports (`addBuildingImage`, `placeBuildingImage`).

- [ ] **Step 4: HUD genérico.** En `Hud.ts`, el bloque `hud__resources` del `innerHTML` pasa a ser un contenedor vacío:

```html
<div class="hud__panel hud__resources" data-ref="resources"></div>
```

Cambios en la clase:
- Se sustituyen los campos `wood` y `axe` por `private readonly resources: HTMLElement;`, que se inicializa con `ref(root, 'resources')`.
- En `render`, se cambian las dos líneas de `wood` / `hasAxe` por:

```ts
if (!previous || JSON.stringify([previous.resources, previous.tools]) !== JSON.stringify([state.resources, state.tools])) {
  this.renderResources(state);
}
```

Método nuevo:

```ts
private renderResources(state: WebHud): void {
  const resources = state.resources.map(
    (resource) => `
      <span class="hud__resource" title="${resource.name}">
        <span class="hud__icon hud__icon--${resource.id}" aria-hidden="true"></span>
        <span class="hud__label">${resource.name}</span>
        <strong class="hud__value">${resource.amount}</strong>
      </span>`,
  );
  const tools = state.tools.map(
    (tool) => `
      <span class="hud__resource hud__tool ${tool.isOwned ? 'hud__tool--owned' : ''}" title="${tool.name}">
        <span class="hud__icon hud__icon--${tool.id}" aria-hidden="true"></span>
        <span class="hud__label">${tool.name}</span>
      </span>`,
  );
  this.resources.innerHTML = [...resources, ...tools].join('');
}
```

`hud.css` no cambia: `hud__icon--wood` y `hud__icon--axe` ya existen. Las fases siguientes añaden `hud__icon--<id>`.

Los textos `labels.wood` / `labels.axe` dejan de usarse; `WebLabels` los pierde en T0.5.

- [ ] **Step 5: Verificar**

```bash
cd webApp && npm run typecheck && npm test && npm run build
```

Expected: PASS.

Prueba manual: `npm run dev`.
- El HUD muestra la madera y el hacha (atenuada, y nítida al recogerla).
- Talar sube la madera.
- La previsualización de la casa sale verde o roja.
- La casa construida se ve igual que antes.

- [ ] **Step 6: Commit**

```bash
git add webApp
git commit -m "[PROJECT-X]: Draw HUD resources and building sprites from shared data on the web"
```

Después, `/cerrar-tarea`.

---

### Task T0.3: Android: HUD de recursos y sprites desde `shared`

**Files:**
- Modify (en `androidApp/src/main/kotlin/com/apergas/rpg/android/presentation/forest/`):
  - `components/HudOverlay.kt`
  - `world/WorldSceneState.kt`
  - `world/WorldCanvas.kt`
  - `world/Particles.kt`
- Test: `androidApp/src/test/kotlin/com/apergas/rpg/android/presentation/forest/world/ParticlesTests.kt`

**Interfaces:**
- Consumes (de T0.1):
  - `HudState.resources: List<ResourceItem>` y `HudState.tools: List<ToolItem>`
  - `SpriteNames.building(BlueprintId)`, `SpriteNames.buildingFrontOffset(BlueprintId)` y `SpriteNames.item(ToolKind)`
- Produces:
  - `SceneBuilding(id, center, progress, frame: String, frontOffset: Double, completedAtNanos)`
  - `SceneItem(position: Position, frame: String)`
  - `ParticleBursts.dust(front: Position, nowNanos, random)`

- [ ] **Step 1: Rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f0-android
```

- [ ] **Step 2: Test del polvo, que debe fallar.** La firma pasa a recibir el punto del muro frontal. En `ParticlesTests.kt`:

```kotlin
@Test
fun testWhenBuildingIsHammeredThenSixDustPuffsRiseFromItsFront() {
    // given
    val front = Position(400.0, 424.0)

    // when
    val dust = ParticleBursts.dust(front, nowNanos = 0, random = Random(1))

    // then
    assertEquals(6, dust.size)
    dust.forEach { puff ->
        assertEquals(Position(400.0, 420.0), puff.origin)
        assertTrue(puff.velocityY <= 0.0)
        assertEquals(0.2, puff.scale(nowNanos = 450_000_000), 1e-9)
    }
}
```

Run: `./gradlew :androidApp:testDebugUnitTest --tests "*ParticlesTests"`
Expected: FAIL: `origin` vale `(400, 444)` porque todavía se suma el offset.

- [ ] **Step 3: `Particles.kt`**
- Se borra `HOUSE_FRONT_OFFSET` y su comentario.
- `fun dust(front: Position, nowNanos: Long, random: Random)` usa `origin = Position(front.x, front.y - DUST_LIFT)`.

Run: el mismo comando del paso 2. Expected: PASS.

- [ ] **Step 4: Estado de la escena.** En `WorldSceneState.kt`:

```kotlin
data class SceneBuilding(
    val id: String,
    val center: Position,
    val progress: Double,
    val frame: String,
    val frontOffset: Double,
    val completedAtNanos: Long? = null,
) {
    /** Bottom of the front wall: where the sprite is anchored, y-sorted and where dust rises. */
    val front: Position get() = Position(center.x, center.y + frontOffset)
}

data class SceneItem(val position: Position, val frame: String)
```

Cambios:
- `val items = mutableStateMapOf<String, SceneItem>()`
- `snapshot.items.forEach { items[it.id] = SceneItem(it.position, SpriteNames.item(it.kind)) }`
- `private fun Building.toScene() = SceneBuilding(id, position, progress, SpriteNames.building(blueprint.id), SpriteNames.buildingFrontOffset(blueprint.id))`
- En `BuildingHammered`: `particles += ParticleBursts.dust(building.front, nowNanos, random)`

- [ ] **Step 5: `WorldCanvas.kt`**
- Se borra `HOUSE_FRONT_OFFSET`.
- `drawHouse` se sustituye por:

```kotlin
private fun DrawScope.drawBuilding(assets: LpcAssets, frame: String, front: Position, alpha: Float, colorFilter: ColorFilter? = null) =
    drawFrame(assets, frame, front, alpha, colorFilter)
```

Usos:

```kotlin
scene.items.values.forEach { item -> add(item.position.y to { drawFrame(assets, item.frame, Position(item.position.x, item.position.y - 8)) }) }
scene.buildings.values.forEach { building ->
    add(building.front.y to { drawBuilding(assets, building.frame, building.front, 0.35f + 0.65f * building.progress.toFloat()) })
}
// ghost:
placement?.let { ghost ->
    val tint = if (ghost.isValid) Color(0xFFB8FFB8) else Color(0xFFFF8080)
    val front = Position(ghost.position.x, ghost.position.y + SpriteNames.buildingFrontOffset(ghost.blueprint))
    drawBuilding(assets, SpriteNames.building(ghost.blueprint), front, 0.6f, ColorFilter.tint(tint, androidx.compose.ui.graphics.BlendMode.Modulate))
}
```

- [ ] **Step 6: `HudOverlay.kt`.** Las dos líneas de `WOOD` y `AXE` se sustituyen por:

```kotlin
hud.resources.forEach { resource ->
    Text("${resource.name} ${resource.amount}", color = MaterialTheme.colorScheme.primary)
}
hud.tools.forEach { tool ->
    Text(tool.name, color = if (tool.isOwned) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant)
}
```

- [ ] **Step 7: Verificar**

```bash
./gradlew :androidApp:testDebugUnitTest :androidApp:assembleDebug
./gradlew :androidApp:connectedDebugAndroidTest   # emulator running
./gradlew :androidApp:installDebug
```

Expected: PASS.

Prueba manual en el AVD `Medium_Phone_API_36.0`:
- se ve "Madera 0" y el hacha atenuada;
- al recoger el hacha y talar, sube la madera;
- la previsualización y la casa se ven igual;
- el polvo sale del muro frontal.

- [ ] **Step 8: Commit**

```bash
git add androidApp
git commit -m "[PROJECT-X]: Draw HUD resources and building sprites from shared data on Android"
```

Después, `/cerrar-tarea`.

---

### Task T0.4: iOS: HUD de recursos y sprites desde `shared`

**Files:**
- Modify:
  - `iosApp/iosApp/Presentation/Screens/Forest/Components/HudView.swift`
  - `iosApp/iosApp/Presentation/Screens/Forest/World/ForestScene.swift`

**Interfaces:**
- Consumes (de T0.1), con los nombres que les da SKIE:
  - `hud.resources: [ResourceItem]`
  - `hud.tools: [ToolItem]`
  - `SpriteNames.shared.building(id:)`, `SpriteNames.shared.buildingFrontOffset(id:)` y `SpriteNames.shared.item(kind:)`
- Produces: `ForestScene.addBuilding(id:center:progress:blueprint:)` y `addItem(id:position:kind:)`.

- [ ] **Step 1: Rama**

```bash
git switch develop && git pull && git switch -c feature/PROJECT-X-f0-ios
```

- [ ] **Step 2: `HudView.swift`.** El bloque `resources` queda así:

```swift
private var resources: some View {
    HStack(spacing: 16) {
        ForEach(hud.resources, id: \.name) { resource in
            Text("\(resource.name) \(resource.amount)").foregroundStyle(.yellow)
        }
        ForEach(hud.tools, id: \.name) { tool in
            Text(tool.name).opacity(tool.isOwned ? 1 : 0.35)
        }
    }
    .padding(.horizontal, 14).padding(.vertical, 8)
    .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
    .foregroundStyle(.white)
}
```

- [ ] **Step 3: `ForestScene.swift`**
- Se borra `private let houseFrontOffset = 24.0`.
- Se añade `private var buildingFronts: [String: Position] = [:]`, la base del muro de cada edificio, que se usa para el polvo.

```swift
func addItem(id: String, position: Position, kind: ToolKind) {
    let node = SKSpriteNode(texture: atlas.textures[SpriteNames.shared.item(kind: kind)])
    node.position = points.scene(Position(x: position.x, y: position.y - 8))
    node.zPosition = position.y
    node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: 0.7), .moveBy(x: 0, y: -3, duration: 0.7)])))
    addChild(node)
    items[id] = node
}

func addBuilding(id: String, center: Position, progress: Double, blueprint: BlueprintId) {
    let frame = SpriteNames.shared.building(id: blueprint)
    let front = Position(x: center.x, y: center.y + SpriteNames.shared.buildingFrontOffset(id: blueprint))
    let node = SKSpriteNode(texture: atlas.textures[frame])
    node.anchorPoint = atlas.anchor(of: frame)
    node.position = points.scene(front)
    node.zPosition = front.y
    node.alpha = 0.35 + 0.65 * progress
    addChild(node)
    buildings[id] = node
}
```

Llamadas:
- `addItem(id: item.id, position: item.position, kind: item.kind)`
- `addBuilding(id: building.id, center: building.position, progress: building.progress, blueprint: building.blueprint.id)`, en `didMove` y en `.buildingPlaced`.

Fantasma:
- La configuración inicial de textura y ancla sale de `didMove`.
- En `renderGhost` se calcula a partir de `placement.blueprint`:

```swift
func renderGhost(_ placement: Placement?) {
    guard let placement else { ghost.isHidden = true; return }
    let frame = SpriteNames.shared.building(id: placement.blueprint)
    if ghost.texture !== atlas.textures[frame] {
        ghost.texture = atlas.textures[frame]
        ghost.size = ghost.texture?.size() ?? .zero
        ghost.anchorPoint = atlas.anchor(of: frame)
    }
    ghost.isHidden = false
    let offset = SpriteNames.shared.buildingFrontOffset(id: placement.blueprint)
    ghost.position = points.scene(Position(x: placement.position.x, y: placement.position.y + offset))
    ghost.color = placement.isValid ? UIColor(red: 0.72, green: 1, blue: 0.72, alpha: 1) : UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
    ghost.colorBlendFactor = 1
}
```

En `didMove` se conservan `alpha`, `zPosition`, `isHidden` y `addChild(ghost)`.

Si SKIE expone las firmas con otros nombres de argumento, se toman los que muestre el autocompletado de Xcode. La diferencia se apunta en la sección 5 del README.

- [ ] **Step 4: Verificar**

```bash
./gradlew :shared:allTests
xcodebuild test -project iosApp/iosApp.xcodeproj -scheme iosApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: PASS.

Prueba manual en el simulador:
- el HUD muestra la madera y el hacha (atenuada y luego nítida);
- la previsualización y la casa se ven igual que antes;
- el polvo sale del muro.

- [ ] **Step 5: Commit**

```bash
git add iosApp
git commit -m "[PROJECT-X]: Draw HUD resources and building sprites from shared data on iOS"
```

Después, `/cerrar-tarea`.

---

### Task T0.5: Quitar la API deprecada

**Files:**
- Modify:
  - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/ForestContract.kt`
  - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/ForestLabels.kt`
  - `shared/src/commonMain/kotlin/com/apergas/rpg/presentation/forest/ForestViewModel.kt`
  - `shared/src/jsMain/kotlin/com/apergas/rpg/web/WebModels.kt`
  - `shared/src/jsMain/kotlin/com/apergas/rpg/web/WebMappers.kt`
  - `shared/src/jsMain/kotlin/com/apergas/rpg/web/ForestWebController.kt`
  - `webApp/src/presentation/screens/forest/hud/Hud.ts`, sólo si aún lee `labels.wood` / `labels.axe`
- Test: `ForestViewModelTests.kt`, cambiando los asserts que usen `hud.wood` / `hud.hasAxe`.

**Interfaces:**
- Consumes: T0.2, T0.3 y T0.4 fusionadas (ninguna app usa ya lo deprecado).
- Produces: `HudState` sin `wood` / `hasAxe`, `ForestLabels` sin `WOOD` / `AXE`, `WebHud` sin `wood` / `hasAxe` y `WebLabels(build, quests)`.

- [ ] **Step 1: Rama:** `git switch develop && git pull && git switch -c feature/PROJECT-X-f0-cleanup`.
- [ ] **Step 2: Comprobar que nadie usa la API vieja**

```bash
grep -rn "hud.wood\|hud.hasAxe\|\.WOOD\b\|\.AXE\b\|labels.wood\|labels.axe" androidApp/src iosApp webApp/src shared/src
```

Expected: sólo aparecen en `shared` (el view model, los mappers y los tests).

- [ ] **Step 3: Cambiar los tests.** En `ForestViewModelTests.kt`:

| Antes | Después |
|---|---|
| `assertEquals(6, sut.uiState.value.hud.wood)` | `assertEquals(6, sut.uiState.value.hud.resources.single { it.resource == Resource.Wood }.amount)` |
| `assertTrue(sut.uiState.value.hud.hasAxe)` | `assertTrue(sut.uiState.value.hud.tools.single { it.tool == ToolKind.Axe }.isOwned)` |

Run: `./gradlew :shared:testAndroidHostTest --tests "*ForestViewModelTests"`
Expected: PASS (todavía con la API vieja presente).

- [ ] **Step 4: Borrar lo deprecado**
- Los campos `wood` y `hasAxe` de `HudState` y su relleno en `hudState`, con su `@Suppress`.
- `ForestLabels.WOOD` y `ForestLabels.AXE`.
- `WebHud.wood` / `hasAxe` y su relleno en `WebMappers`, con su `@Suppress`.
- En `WebLabels`, sólo quedan `build` y `quests`. En `ForestWebController.labels()` queda `WebLabels(ForestLabels.BUILD, ForestLabels.QUESTS)`.

- [ ] **Step 5: Verificación completa** (los comandos del paso 13 de T0.1, más `xcodebuild test`)

Expected: todo en verde y **sin** *warnings* de deprecación.

- [ ] **Step 6: Commit**

```bash
git add shared webApp
git commit -m "[PROJECT-X]: Remove wood and axe specific HUD fields"
```

Después, `/cerrar-tarea`. Con esto se cierra el milestone F0.
