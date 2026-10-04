package com.apergas.rpg.domain.entities.tree

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class TreeTests {
    @Test
    fun testWhenHitTheRequiredTimesThenTreeIsFelledAndIgnoresMoreHits() {
        // given
        var tree = Tree.mock

        // when
        repeat(5) { tree = tree.hit() }
        val hitAgain = tree.hit()

        // then
        assertTrue(tree.isFelled)
        assertEquals(0, hitAgain.hitsRemaining)
    }

    @Test
    fun testWhenHitOnceThenOriginalTreeIsUnchanged() {
        // given
        val tree = Tree.mock

        // when
        val hitTree = tree.hit()

        // then
        assertEquals(5, tree.hitsRemaining)
        assertEquals(4, hitTree.hitsRemaining)
    }
}
