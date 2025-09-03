package com.king.net
import okhttp3.CertificatePinner
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

object NetworkModule {
    private const val HOST = "api.the-king.trade"
    private const val PIN = "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" // e.g., sha256/BASE64==
    val client: OkHttpClient by lazy {
        val pinner = CertificatePinner.Builder().add(HOST, PIN).build()
        OkHttpClient.Builder()
            .certificatePinner(pinner)
            .connectTimeout(6, TimeUnit.SECONDS)
            .readTimeout(6, TimeUnit.SECONDS)
            .writeTimeout(6, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build()
    }
}
