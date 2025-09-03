package com.king.secure
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import java.security.MessageDigest

object AntiTamper {
    // TODO: Replace with actual signing cert SHA-256 fingerprint (hex lowercase, no colons)
    private const val EXPECTED_CERT_SHA256 = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

    fun isDebuggable(ctx: Context): Boolean =
        (ctx.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0

    fun certFingerprintOk(ctx: Context): Boolean {
        return try {
            val pkg = ctx.packageName
            val pm = ctx.packageManager
            val info = if (Build.VERSION.SDK_INT >= 28)
                pm.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES)
            else
                pm.getPackageInfo(pkg, PackageManager.GET_SIGNATURES)

            val sigBytes = if (Build.VERSION.SDK_INT >= 28)
                info.signingInfo.apkContentsSigners[0].toByteArray()
            else
                info.signatures[0].toByteArray()

            val md = MessageDigest.getInstance("SHA-256")
            val hex = md.digest(sigBytes).joinToString("") { "%02x".format(it) }
            hex == EXPECTED_CERT_SHA256
        } catch (e: Throwable) { false }
    }

    fun detectHooks(): Boolean {
        val suspects = listOf("frida", "xposed", "substrate", "edxposed")
        val maps = try { java.io.File("/proc/self/maps").readText() } catch (_: Throwable) { "" }
        val env = System.getenv().toString()
        return (suspects.any { maps.contains(it, true) || env.contains(it, true) })
    }

    fun shouldKill(ctx: Context): Boolean =
        isDebuggable(ctx) || !certFingerprintOk(ctx) || detectHooks()
}
