package com.apergas.rpg.data.datasources.local.session

import com.apergas.rpg.domain.entities.game.GameSession

/** Keeps the session in memory for the lifetime of the app. A save-game datasource would persist it. */
class GameSessionLocalDataSourceImpl : GameSessionLocalDataSource {
    private var session: GameSession? = null

    override fun get(): GameSession? = session

    override fun set(session: GameSession) {
        this.session = session
    }
}
