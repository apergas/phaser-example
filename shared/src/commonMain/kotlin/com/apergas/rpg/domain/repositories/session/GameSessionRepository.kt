package com.apergas.rpg.domain.repositories.session

import com.apergas.rpg.domain.entities.game.GameSession

/** Where the current game lives. Use cases fetch it on every call. */
interface GameSessionRepository {
    fun current(): GameSession
    fun save(session: GameSession)
}
