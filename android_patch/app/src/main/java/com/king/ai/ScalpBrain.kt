package com.king.ai
import com.king.AppConfig

object ScalpBrain {
    data class Signal(val dir: Direction, val conf: Float, val reason: String)

    fun decide(ensemble: Ensemble.Vote, model: Pair<Direction, Float>): Signal {
        val (mDir, mConf) = model
        if (mConf < AppConfig.MODEL_MIN_CONF && ensemble.conf < AppConfig.ENSEMBLE_MIN_CONF)
            return Signal(Direction.NEUTRAL, 0f, "Low confidence")
        if (ensemble.dir == Direction.NEUTRAL && mDir == Direction.NEUTRAL)
            return Signal(Direction.NEUTRAL, 0f, "Consensus neutral")
        if (ensemble.dir == mDir) {
            val conf = (mConf + ensemble.conf) / 2f
            return Signal(mDir, conf, "Consensus")
        }
        // Disagreement gate
        return if (mConf >= 0.7f) Signal(mDir, mConf, "Model override")
               else Signal(Direction.NEUTRAL, 0f, "Disagree gate")
    }
}
