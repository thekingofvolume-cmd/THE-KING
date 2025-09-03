package com.king.ai
object Ensemble {
    data class Vote(val dir: Direction, val conf: Float)
    // TODO: Plug in your TA/ICT modules
    fun vote(feats: Features): Vote {
        val bias = if (feats.x.firstOrNull() ?: 0f > 0f) Direction.LONG else Direction.NEUTRAL
        val conf = 0.6f
        return Vote(bias, conf)
    }
}
