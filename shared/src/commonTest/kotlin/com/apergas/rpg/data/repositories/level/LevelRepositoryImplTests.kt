package com.apergas.rpg.data.repositories.level

import com.apergas.rpg.data.datasources.local.level.LevelLocalDataSourceMock
import com.apergas.rpg.data.datasources.local.level.mockWithUnknownItem
import com.apergas.rpg.data.datasources.local.level.mockWithUnknownTreeKind
import com.apergas.rpg.data.datasources.local.level.mockWithoutSize
import com.apergas.rpg.data.datasources.local.level.dto.LevelDto
import com.apergas.rpg.data.errors.DataErrorHandlerImpl
import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.geometry.Position
import com.apergas.rpg.domain.entities.player.ToolKind
import com.apergas.rpg.domain.entities.tree.TreeKind
import com.apergas.rpg.domain.errors.AppError
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class LevelRepositoryImplTests {
    private lateinit var localDataSource: LevelLocalDataSourceMock
    private lateinit var sut: LevelRepositoryImpl

    @BeforeTest
    fun setUp() {
        localDataSource = LevelLocalDataSourceMock()
        sut = LevelRepositoryImpl(localDataSource, DataErrorHandlerImpl())
    }

    @Test
    fun testWhenLoadWithSuccessThenBuildsTheWorldWithDomainRules() {
        // given
        // localDataSource.levelDto is LevelDto.mock by default

        // when
        val world = sut.load()

        // then
        assertTrue(localDataSource.fetchCalled)
        assertEquals(400.0, world.width)
        assertEquals(Position(200.0, 150.0), world.player.position)
        assertEquals(110.0, world.player.speed)
        assertEquals("tree-a", world.trees.single().id)
        assertEquals(5, world.trees.single().woodYield)
        assertEquals(12.0, world.trees.single().trunkRadius)
        assertEquals(5, world.trees.single().hitsToFell)
        assertEquals(ToolKind.Axe, world.items.single().kind)
        assertEquals(TreeKind.Oak, world.trees.single().kind)
        assertEquals(DecorationKind.TallGrass, world.decorations.single().kind)
        assertEquals(Position(300.0, 200.0), world.decorations.single().position)
    }

    @Test
    fun testWhenLoadTwiceThenEachWorldIsIndependent() {
        // given
        val first = sut.load()

        // when
        first.movePlayerTo(Position(10.0, 10.0))
        first.advance(1000.0)
        val second = sut.load()

        // then
        assertEquals(Position(200.0, 150.0), second.player.position)
    }

    @Test
    fun testWhenLevelHasUnknownItemKindThenThrowsLevelError() {
        // given
        localDataSource.levelDto = LevelDto.mockWithUnknownItem

        // when
        val error = assertFailsWith<AppError.LevelError.UnknownItemKind> { sut.load() }

        // then
        assertEquals("mystery", error.itemId)
        assertEquals("laser", error.kind)
    }

    @Test
    fun testWhenLevelHasUnknownTreeKindThenThrowsLevelError() {
        // given
        localDataSource.levelDto = LevelDto.mockWithUnknownTreeKind

        // when
        val error = assertFailsWith<AppError.LevelError.UnknownTreeKind> { sut.load() }

        // then
        assertEquals("tree-x", error.treeId)
        assertEquals("palm", error.kind)
    }

    @Test
    fun testWhenLevelHasNoSizeThenThrowsInvalidLevel() {
        // given
        localDataSource.levelDto = LevelDto.mockWithoutSize

        // when / then
        assertFailsWith<AppError.LevelError.InvalidLevel> { sut.load() }
    }

    @Test
    fun testWhenDataSourceFailsThenErrorIsRoutedThroughTheHandler() {
        // given
        localDataSource.error = IllegalStateException("disk unavailable")

        // when / then
        assertFailsWith<AppError.GeneralError> { sut.load() }
        assertTrue(localDataSource.fetchCalled)
    }
}
