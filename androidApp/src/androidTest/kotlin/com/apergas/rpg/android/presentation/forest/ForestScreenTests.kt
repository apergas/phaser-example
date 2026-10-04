package com.apergas.rpg.android.presentation.forest

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import com.apergas.rpg.android.presentation.theme.RpgTheme
import com.apergas.rpg.di.GameContainer
import com.apergas.rpg.presentation.forest.ForestViewModel
import org.junit.Rule
import org.junit.Test

class ForestScreenTests {
    @get:Rule val composeRule = createComposeRule()

    @Test
    fun testWhenOpeningQuestsThenTheFirstQuestIsListed() {
        // given
        // The game loop asks for a frame every frame, so Compose never idles: the clock is driven by hand.
        composeRule.mainClock.autoAdvance = false
        composeRule.setContent { RpgTheme { ForestScreen(viewModel = ForestViewModel(GameContainer.makeGameUseCase())) } }
        composeRule.mainClock.advanceTimeByFrame()

        // when
        composeRule.onNodeWithText("Misiones 0/3").performClick()
        composeRule.mainClock.advanceTimeByFrame()

        // then
        composeRule.onNodeWithText("Recoge el hacha").assertIsDisplayed()
    }
}
