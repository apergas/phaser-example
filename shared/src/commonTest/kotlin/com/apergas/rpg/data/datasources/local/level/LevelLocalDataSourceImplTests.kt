package com.apergas.rpg.data.datasources.local.level

import com.apergas.rpg.data.datasources.local.level.dto.ItemDto
import com.apergas.rpg.data.datasources.local.level.dto.PointDto
import com.apergas.rpg.data.datasources.local.level.dto.TreeDto
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LevelLocalDataSourceImplTests {
    private val sut = LevelLocalDataSourceImpl()

    @Test
    fun testWhenFetchingTwiceThenReturnsTheSameForest() {
        // given
        val first = sut.fetch()

        // when
        val second = sut.fetch()

        // then
        assertEquals(first, second)
    }

    @Test
    fun testWhenFetchingThenForestMatchesTheWebVersionExactly() {
        // given
        val expectedFirstTrees = listOf(
            TreeDto(id = "tree-1", kind = "broad", x = 433.47085868008435, y = 155.17504904419184, wood = 6),
            TreeDto(id = "tree-2", kind = "old", x = 389.38031366094947, y = 465.71301287971437, wood = 5),
            TreeDto(id = "tree-3", kind = "pine", x = 721.9763031136245, y = 187.9368040524423, wood = 6),
        )

        // when
        val level = sut.fetch()
        val trees = level.trees.orEmpty()

        // then
        assertEquals(1600.0, level.width)
        assertEquals(1200.0, level.height)
        assertEquals(PointDto(800.0, 600.0), level.playerStart)
        assertEquals(70, trees.size)
        assertEquals(expectedFirstTrees, trees.take(3))
        assertEquals(TreeDto(id = "tree-70", kind = "dense", x = 1487.0892029069364, y = 676.5116280969232, wood = 6), trees.last())
        assertEquals(
            mapOf<String?, Int>("broad" to 3, "old" to 6, "pine" to 8, "slim" to 4, "dense" to 4, "branches" to 7, "big" to 4,
                "lumpy" to 4, "leaning" to 8, "oak" to 6, "round" to 5, "wide" to 6, "twisted" to 3, "dome" to 2),
            trees.groupingBy { it.kind }.eachCount(),
        )
        assertEquals(388, trees.sumOf { it.wood ?: 0 })
        assertEquals(listOf(ItemDto(id = "axe", kind = "axe", x = 856.0, y = 608.0)), level.items)
    }

    @Test
    fun testWhenFetchingThenTreesKeepClearOfTheSpawnPoint() {
        // given
        val level = sut.fetch()

        // when
        val closest = level.trees.orEmpty().minOf { hypot((it.x ?: 0.0) - 800.0, (it.y ?: 0.0) - 600.0) }

        // then
        assertTrue(closest >= 200.0)
    }

    @Test
    fun testWhenFetchingThenDecorationsAreVariedAndNeverUnderATreeOrOnTheSpawn() {
        // given
        val level = sut.fetch()
        val trees = level.trees.orEmpty()

        // when
        val decorations = level.decorations.orEmpty()

        // then
        assertTrue(decorations.size >= 40)
        assertEquals(setOf("tall-grass", "leaves", "mushrooms", "rock"), decorations.map { it.kind }.toSet())
        for (decoration in decorations) {
            val x = decoration.x ?: 0.0
            val y = decoration.y ?: 0.0
            assertTrue(trees.none { abs(x - (it.x ?: 0.0)) < 64 && y > (it.y ?: 0.0) - 170 && y < (it.y ?: 0.0) + 20 })
            assertTrue(abs(x - 800.0) >= 48 || y < 504.0 || y > 648.0)
        }
    }
}
