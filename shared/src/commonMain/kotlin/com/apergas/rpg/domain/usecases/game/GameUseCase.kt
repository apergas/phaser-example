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
