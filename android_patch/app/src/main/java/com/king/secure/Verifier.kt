package com.king.secure
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import android.util.Base64

object Verifier {
    // TODO: Replace with your real key
    private const val PUBKEY_B64 = "MCowBQYDK2VwAyEA______________________________"

    fun verifyEd25519(message: ByteArray, sig: ByteArray): Boolean {
        return try {
            val keyBytes = Base64.decode(PUBKEY_B64, Base64.DEFAULT)
            val kf = KeyFactory.getInstance("Ed25519")
            val pub = kf.generatePublic(X509EncodedKeySpec(keyBytes))
            val s = Signature.getInstance("Ed25519")
            s.initVerify(pub)
            s.update(message)
            s.verify(sig)
        } catch (e: Throwable) { false }
    }
}
