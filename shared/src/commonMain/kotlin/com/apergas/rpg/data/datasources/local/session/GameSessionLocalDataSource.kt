package com.apergas.rpg.data.datasources.local.session

import com.apergas.rpg.domain.entities.game.GameSession

interface GameSessionLocalDataSource {
    fun get(): GameSession?
    fun set(session: GameSession)
}
