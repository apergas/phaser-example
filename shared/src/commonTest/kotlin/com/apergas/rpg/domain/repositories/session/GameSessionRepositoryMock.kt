package com.apergas.rpg.domain.repositories.session

import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.errors.AppError

class GameSessionRepositoryMock : GameSessionRepository {
    var error: Throwable? = null
    var session: GameSession? = null
    var currentCalled = false
    var saveCalled = false

    override fun current(): GameSession {
        currentCalled = true
        error?.let { throw it }
        return session ?: throw AppError.GeneralError()
    }

    override fun save(session: GameSession) {
        saveCalled = true
        error?.let { throw it }
        this.session = session
    }
}
