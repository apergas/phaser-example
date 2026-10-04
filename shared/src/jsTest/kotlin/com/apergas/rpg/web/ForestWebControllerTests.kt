package com.apergas.rpg.web

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ForestWebControllerTests {
    @Test
    fun testWhenTickingThenStateAndWelcomeEffectAreExposedAsPlainValues() {
        // given
        val sut = ForestWebController()

        // when
        sut.tick(16.0)
        val effects = sut.takeEffects()
        val state = sut.state()

        // then
        assertEquals("message", effects.first().kind)
        assertEquals("0/3", state.hud.questBadge)
        assertEquals("idle", state.player.pose)
        assertEquals(800.0, state.player.position.x)
        assertTrue(sut.takeEffects().isEmpty())
    }

    @Test
    fun testWhenAskingForTheWorldThenTreesAndAxeAreExposed() {
        // given
        val sut = ForestWebController()

        // when
        val world = sut.world()

        // then
        assertEquals(70, world.trees.size)
        assertEquals("tree-broad", world.trees.first().frame)
        assertEquals("axe", world.items.single().kind)
        assertTrue(world.decorations.all { it.frame.startsWith("decor-") })
    }
}
