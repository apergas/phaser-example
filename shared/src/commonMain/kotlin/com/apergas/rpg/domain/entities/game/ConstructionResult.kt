package com.apergas.rpg.domain.entities.game

import com.apergas.rpg.domain.entities.building.Building

sealed interface ConstructionResult {
    data class Started(val building: Building) : ConstructionResult
    data class Rejected(val reason: ConstructionRejection) : ConstructionResult
}

enum class ConstructionRejection { NotEnoughWood, Blocked }
