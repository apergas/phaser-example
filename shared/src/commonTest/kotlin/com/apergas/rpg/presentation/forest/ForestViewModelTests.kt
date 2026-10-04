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
