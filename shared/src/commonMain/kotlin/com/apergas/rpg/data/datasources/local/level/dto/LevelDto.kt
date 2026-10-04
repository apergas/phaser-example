package com.apergas.rpg.data.datasources.local.level.dto

import kotlinx.serialization.Serializable

/** A level as it comes from its source (generator, Tiled map, JSON file): untrusted, every field optional. */
@Serializable
data class LevelDto(
    val width: Double? = null,
    val height: Double? = null,
    val playerStart: PointDto? = null,
    val trees: List<TreeDto>? = null,
    val items: List<ItemDto>? = null,
    val decorations: List<DecorationDto>? = null,
) {
    companion object
}

@Serializable
data class PointDto(val x: Double? = null, val y: Double? = null) {
    companion object
}

@Serializable
data class TreeDto(
    val id: String? = null,
    val kind: String? = null,
    val x: Double? = null,
    val y: Double? = null,
    val wood: Int? = null,
) {
    companion object
}

@Serializable
data class ItemDto(val id: String? = null, val kind: String? = null, val x: Double? = null, val y: Double? = null) {
    companion object
}

@Serializable
data class DecorationDto(val id: String? = null, val kind: String? = null, val x: Double? = null, val y: Double? = null) {
    companion object
}
