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
