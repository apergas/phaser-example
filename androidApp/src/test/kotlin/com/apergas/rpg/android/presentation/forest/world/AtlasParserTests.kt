package com.apergas.rpg.android.presentation.forest.world

import kotlin.test.Test
import kotlin.test.assertEquals

class AtlasParserTests {
    @Test
    fun testWhenParsingAPhaserJsonHashAtlasThenReturnsFramesWithPivots() {
        // given
        val json = """
            {"frames": {"tree-oak": {"frame": {"x": 10, "y": 20, "w": 125, "h": 151},
              "rotated": false, "trimmed": false, "pivot": {"x": 0.568, "y": 1.0}}},
             "meta": {"image": "forest.png"}}
        """.trimIndent()

        // when
        val frames = AtlasParser.parse(json)

        // then
        assertEquals(AtlasFrame("tree-oak", 10, 20, 125, 151, 0.568f, 1.0f), frames.getValue("tree-oak"))
    }
}
