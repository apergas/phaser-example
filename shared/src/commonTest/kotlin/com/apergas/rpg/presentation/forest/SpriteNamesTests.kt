package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.decoration.DecorationKind
import com.apergas.rpg.domain.entities.tree.TreeKind
import kotlin.test.Test
import kotlin.test.assertEquals

class SpriteNamesTests {
    @Test
    fun testWhenNamingSpritesThenFollowsTheAtlasFrameNames() {
        // given
        val tree = TreeKind.Broad
        val decoration = DecorationKind.TallGrass

        // when
        val treeName = SpriteNames.tree(tree)
        val decorationName = SpriteNames.decoration(decoration)

        // then
        assertEquals("tree-broad", treeName)
        assertEquals("decor-tall-grass", decorationName)
    }
}
