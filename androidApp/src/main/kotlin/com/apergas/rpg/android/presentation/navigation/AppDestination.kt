package com.apergas.rpg.android.presentation.navigation

import kotlinx.serialization.Serializable

sealed interface AppDestination {
    @Serializable data object Forest : AppDestination
}
