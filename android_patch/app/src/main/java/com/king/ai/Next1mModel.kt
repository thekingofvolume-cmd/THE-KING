package com.king.ai
import org.tensorflow.lite.Interpreter
import java.nio.MappedByteBuffer
import java.nio.ByteBuffer
import java.nio.ByteOrder

enum class Direction { LONG, SHORT, NEUTRAL }

class Next1mModel(private val model: Interpreter) {
    fun predict(feats: FloatArray): Pair<Direction, Float> {
        val input = ByteBuffer.allocateDirect(feats.size * 4).order(ByteOrder.nativeOrder())
        feats.forEach { input.putFloat(it) }
        input.rewind()
        val output = Array(1) { FloatArray(3) } // [neutral, long, short]
        model.run(input, output)
        val p = output[0]
        val (idx, conf) = p.mapIndexed { i, v -> i to v }.maxBy { it.second }
        val dir = when (idx) {
            1 -> Direction.LONG
            2 -> Direction.SHORT
            else -> Direction.NEUTRAL
        }
        return dir to conf
    }
}
