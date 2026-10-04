package com.apergas.rpg.android.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.apergas.rpg.android.presentation.forest.ForestScreen
import com.apergas.rpg.domain.usecases.game.GameUseCase
import com.apergas.rpg.presentation.forest.ForestViewModel

@Composable
fun NavGraph(gameUseCase: GameUseCase) {
    val navController = rememberNavController()
    NavHost(navController = navController, startDestination = AppDestination.Forest) {
        composable<AppDestination.Forest> {
            val viewModel: ForestViewModel = viewModel(factory = viewModelFactory { initializer { ForestViewModel(gameUseCase) } })
            ForestScreen(viewModel = viewModel)
        }
    }
}
