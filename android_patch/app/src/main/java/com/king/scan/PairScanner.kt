package com.king.scan
import com.king.ai.*
import com.king.policy.LeveragePolicy

data class ScanRow(
    val symbol: String,
    val dir: Direction,
    val conf: Float,
    val lev: Double,
    val reason: String
)

object PairScanner {
    // TODO: wire Binance ws and OHLCV cache. This is a stub.
    fun scan(symbols: List<String>, feats: Features, model: Next1mModel): List<ScanRow> {
        val m = model.predict(feats.x)
        val e = Ensemble.vote(feats)
        val s = ScalpBrain.decide(e, m)
        val lev = LeveragePolicy.suggest(s.conf, vol = 0.01, tfMinutes = 1)
        return symbols.map { sym -> ScanRow(sym, s.dir, s.conf, lev, s.reason) }
    }
}
