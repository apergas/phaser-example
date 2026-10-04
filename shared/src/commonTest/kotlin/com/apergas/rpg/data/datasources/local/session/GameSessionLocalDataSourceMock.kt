package com.apergas.rpg.data.datasources.local.session

import com.apergas.rpg.domain.entities.game.GameSession

class GameSessionLocalDataSourceMock : GameSessionLocalDataSource {
    var error: Throwable? = null
    var session: GameSession? = null
    var getCalled = false
    var setCalled = false

    override fun get(): GameSession? {
        getCalled = true
        error?.let { throw it }
        return session
    }

    override fun set(session: GameSession) {
        setCalled = true
        error?.let { throw it }
        this.session = session
    }
}
