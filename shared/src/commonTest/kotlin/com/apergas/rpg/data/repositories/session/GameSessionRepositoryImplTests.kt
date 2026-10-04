package com.apergas.rpg.data.repositories.session

import com.apergas.rpg.data.datasources.local.session.GameSessionLocalDataSourceMock
import com.apergas.rpg.data.errors.DataErrorHandlerImpl
import com.apergas.rpg.domain.entities.game.GameSession
import com.apergas.rpg.domain.errors.AppError
import com.apergas.rpg.domain.quests.QuestLog
import com.apergas.rpg.domain.world.World
import com.apergas.rpg.domain.world.mock
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertSame
import kotlin.test.assertTrue

class GameSessionRepositoryImplTests {
    private lateinit var localDataSource: GameSessionLocalDataSourceMock
    private lateinit var sut: GameSessionRepositoryImpl

    @BeforeTest
    fun setUp() {
        localDataSource = GameSessionLocalDataSourceMock()
        sut = GameSessionRepositoryImpl(localDataSource, DataErrorHandlerImpl())
    }

    @Test
    fun testWhenSavingThenCurrentReturnsTheSameSession() {
        // given
        val session = GameSession(World.mock(), QuestLog())

        // when
        sut.save(session)
        val current = sut.current()

        // then
        assertTrue(localDataSource.setCalled)
        assertTrue(localDataSource.getCalled)
        assertSame(session, current)
    }

    @Test
    fun testWhenNoGameWasStartedThenCurrentThrowsGeneralError() {
        // given
        localDataSource.session = null

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.current() }
    }

    @Test
    fun testWhenDataSourceFailsThenErrorIsRoutedThroughTheHandler() {
        // given
        localDataSource.error = IllegalStateException("storage unavailable")

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.save(GameSession(World.mock(), QuestLog())) }
    }
}
