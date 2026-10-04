package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.world.World

/** Everything that makes up a game in progress. */
data class GameSession(val world: World, val quests: QuestLog)
