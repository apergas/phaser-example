package com.apergas.rpg.util

/**
 * Deterministic pseudo-random generator (LCG): same seed, same sequence, on every platform and
 * identical to the web version, so levels and decor look the same everywhere.
 */
class SeededRandom(seed: Long) {
    private var state = seed and MASK

    /** Next value in [0, 1). */
    fun next(): Double {
        state = (state * MULTIPLIER + INCREMENT) and MASK
        return state.toDouble() / MODULUS
    }

    private companion object {
        const val MULTIPLIER = 1_664_525L
        const val INCREMENT = 1_013_904_223L
        const val MASK = 0xFFFF_FFFFL
        const val MODULUS = 4_294_967_296.0
    }
}
