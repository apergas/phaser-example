package com.apergas.rpg.util

import kotlin.test.Test
import kotlin.test.assertEquals

class SeededRandomTests {
    @Test
    fun testWhenSeededWith42ThenProducesTheSameSequenceAsTheWebVersion() {
        // given
        val random = SeededRandom(42)

        // when
        val values = List(5) { random.next() }

        // then
        assertEquals(
            listOf(0.2523451747838408, 0.08812504541128874, 0.5772811982315034, 0.22255426598712802, 0.37566019711084664),
            values,
        )
    }
}
