package com.apergas.rpg.android.presentation.forest

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.apergas.rpg.presentation.forest.ForestViewModel

@Composable
fun ForestScreen(viewModel: ForestViewModel, modifier: Modifier = Modifier) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    Text(text = "${state.hud.questBadge} · ${state.hud.wood}", modifier = modifier)
}
