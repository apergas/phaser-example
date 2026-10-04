package com.apergas.rpg.util

import kotlin.test.Test
import kotlin.test.assertTrue

class PlatformTests {
    @Test
    fun testWhenSharedCodeRunsThenItIsTheSameOnEveryTarget() {
        // given
        val greeting = sharedGreeting()

        // when
        val isShared = greeting.startsWith("shared:")

        // then
        assertTrue(isShared)
    }
}
