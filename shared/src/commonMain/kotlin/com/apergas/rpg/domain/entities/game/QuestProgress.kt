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
