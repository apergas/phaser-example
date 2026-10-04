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
