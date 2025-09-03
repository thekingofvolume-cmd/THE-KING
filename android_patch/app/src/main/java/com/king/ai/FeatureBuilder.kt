package com.king.ai
data class Features(val x: FloatArray)
object FeatureBuilder {
    // TODO: Implement with your tick buffer and OHLCV
    fun build1m(o: Float, h: Float, l: Float, c: Float, v: Float): Features {
        val feats = floatArrayOf(
            c, v,
            (c - o) / (o + 1e-8f),
            (h - l) / (c + 1e-8f)
        )
        return Features(feats)
    }
}
