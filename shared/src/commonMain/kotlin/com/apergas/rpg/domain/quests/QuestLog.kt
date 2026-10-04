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
