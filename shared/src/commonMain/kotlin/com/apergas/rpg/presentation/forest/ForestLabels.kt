package com.apergas.rpg.presentation.forest

import com.apergas.rpg.domain.entities.building.BlueprintId
import com.apergas.rpg.domain.quests.QuestId

/** Every player-facing text of the gameplay screen, in one place. */
object ForestLabels {
    const val WOOD = "Madera"
    const val AXE = "Hacha"
    const val BUILD = "Construir"
    const val QUESTS = "Misiones"
    const val QUEST_DONE = "Hecha"

    fun cost(wood: Int) = "$wood de madera"
    fun missing(wood: Int) = "Faltan $wood"

    fun blueprint(id: BlueprintId) = when (id) {
        BlueprintId.House -> "Casa"
    }

    fun questTitle(id: QuestId) = when (id) {
        QuestId.PickUpAxe -> "Recoge el hacha"
        QuestId.GatherWood -> "Consigue al menos 15 de madera"
        QuestId.BuildHouse -> "Construye una casa"
    }

    object Messages {
        const val WELCOME = "Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima."
        const val NEED_AXE = "Necesitas un hacha para talar."
        const val BLOCKED_PATH = "Hay algo en medio. Acércate por otro lado."
        const val PICKED_UP_AXE = "¡Hacha recogida! Haz clic en un árbol para talarlo."
        const val BLOCKED_SITE = "Ahí no cabe. Busca un sitio despejado."
        const val NOT_ENOUGH_WOOD = "No tienes madera suficiente."
        const val BUILDING_STARTED = "Manos a la obra…"
        const val ALL_QUESTS_COMPLETED = "¡Has completado todas las misiones!"

        fun woodGained(wood: Int) = "+$wood de madera"
        fun placing(name: String) = "Elige dónde construir: $name. Clic derecho o Esc para cancelar."
        fun buildingCompleted(name: String) = "¡$name construida!"
        fun questCompleted(title: String) = "Misión completada: $title"
    }

    /** Bar shown on touch screens while placing a building (the web uses right click / Esc instead). */
    object Placement {
        const val CONFIRM = "Construir aquí"
        const val CANCEL = "Cancelar"
    }

    /** Screen-reader descriptions (TalkBack / VoiceOver). */
    object Accessibility {
        const val GAME_WORLD = "Mundo de juego: bosque con árboles, el personaje y los edificios"
    }
}
