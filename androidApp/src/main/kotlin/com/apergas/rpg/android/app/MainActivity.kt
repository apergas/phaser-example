package com.apergas.rpg.android.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.apergas.rpg.android.presentation.navigation.NavGraph
import com.apergas.rpg.android.presentation.theme.RpgTheme
import com.apergas.rpg.domain.usecases.game.GameUseCase
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var gameUseCase: GameUseCase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { RpgTheme { NavGraph(gameUseCase = gameUseCase) } }
    }
}
