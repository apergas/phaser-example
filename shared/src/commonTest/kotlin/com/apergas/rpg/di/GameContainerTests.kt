package com.apergas.rpg.di

import com.apergas.rpg.domain.entities.tree.TreeKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GameContainerTests {
    @Test
    fun testWhenStartingAGameThenTheProceduralForestIsLoaded() {
        // given
        val gameUseCase = GameContainer.makeGameUseCase()

        // when
        gameUseCase.startGame()
        val snapshot = gameUseCase.worldSnapshot()

        // then
        assertEquals(70, snapshot.trees.size)
        assertEquals(388, snapshot.trees.sumOf { it.woodYield })
        assertEquals(TreeKind.Broad, snapshot.trees.first().kind)
        assertTrue(snapshot.decorations.size >= 40)
    }

    @Test
    fun testWhenTwoUseCasesAreMadeThenTheyShareTheSameGame() {
        // given
        val first = GameContainer.makeGameUseCase()
        val second = GameContainer.makeGameUseCase()
        first.startGame()

        // when
        first.movePlayerTo(800.0, 500.0)
        first.advance(2000.0)

        // then
        assertEquals(500.0, second.playerStatus().position.y)
    }
}
