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
