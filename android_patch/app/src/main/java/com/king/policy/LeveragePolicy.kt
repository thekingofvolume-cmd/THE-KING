package com.king.policy
object LeveragePolicy {
    private const val MAX_CAP = 5.0 // raised only via signed config in your backend
    fun suggest(conf: Float, vol: Float, tfMinutes: Int): Double {
        val base = when {
            conf >= 0.75f -> 4.0
            conf >= 0.65f -> 3.0
            else -> 2.0
        }
        val volAdj = if (vol > 0.02) 0.5 else 1.0
        val tfAdj = if (tfMinutes <= 1) 1.0 else 0.8
        return minOf(MAX_CAP, base * volAdj * tfAdj)
    }
}
