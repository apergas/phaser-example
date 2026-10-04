package com.apergas.rpg.domain.entities.tree

/**
 * The species/shape of a tree, decided by the level. Apps map it to their sprite; gameplay may use it
 * later (e.g. oaks yielding more wood). Order matters: the level generator indexes this list.
 */
enum class TreeKind { Slim, Round, Wide, Broad, Twisted, Branches, Leaning, Lumpy, Pine, Dome, Oak, Dense, Old, Big }
