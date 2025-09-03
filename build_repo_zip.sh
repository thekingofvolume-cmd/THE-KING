#!/usr/bin/env bash
set -euo pipefail

ROOT="THE-KING"
TS=$(date +%Y%m%d-%H%M%S)
OUT="THE-KING-repo-pack-$TS.zip"

# Placeholders (edit now or later in code files)
BACKEND_BASE_URL="${BACKEND_BASE_URL:-https://api.example.com}"
BACKEND_HOST="${BACKEND_HOST:-api.example.com}"
BACKEND_SPKI_SHA256_PIN="${BACKEND_SPKI_SHA256_PIN:-sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=}"
ED25519_PUBKEY_B64="${ED25519_PUBKEY_B64:-MCowBQYDK2VwAyEA______________________________}"
EXPECTED_CERT_SHA256="${EXPECTED_CERT_SHA256:-ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff}"

rm -rf "$ROOT" && mkdir -p "$ROOT"

# ----------------- docs -----------------
mkdir -p "$ROOT/docs"
cat > "$ROOT/docs/architecture.md" <<'EOF'
# Architecture

- Android app:
  - Multi-agent ensemble + TFLite next-1m classifier
  - SMC/ICT: BOS, CHOCH, Order Blocks, FVG, liquidity sweeps
  - Volume spikes, RSI divergence, OBV slope
  - Multi-pair/multi-timeframe scanning (1m, 5m, 15m, 30m, 1h)
  - Entry/SL/TP1–TP3 + leverage suggestion (admin-capped)
  - Integrity: Ed25519-signed manifest, SHA-256 checks, TLS pinning, anti-tamper + kill switch

- Backend (FastAPI):
  - /v1/market/klines (proxy+TTL cache)
  - /v1/indicators/summary (pandas_ta)
  - /v1/models/approve + /v1/models/approvals (admin)
  - /v1/ops/error + /v1/security/tamper (IP logging)
EOF

cat > "$ROOT/docs/model_manifest.md" <<'EOF'
# Model manifest and signing

- Files: models/next1m.tflite, config/calib.json
- manifest.json contains SHA-256 of each file and version
- manifest.json.sig is Ed25519 signature
- App verifies signature (embedded public key) and hashes before activating
- Admin approval flag required from backend before activation
EOF

cat > "$ROOT/docs/admin_controls.md" <<'EOF'
# Admin controls

- Approve model version:
  - POST /v1/models/approve?version=X&approved=true with header X-API-Key
- Set leverage cap / config:
  - Deliver as signed config via manifest and have app enforce policy on receipt
- Monitor:
  - /v1/ops/error and /v1/security/tamper log device IP and reason
EOF

# ----------------- releases -----------------
mkdir -p "$ROOT/releases"
cat > "$ROOT/releases/README.md" <<'EOF'
# Releases

Attach these ZIPs to a GitHub Release:
- android_patch.zip — Android security + AI scanner stubs
- backend_patch.zip — FastAPI services (klines, indicators, model approvals, ops)

Upload both here and/or attach to a GitHub Release for stable download URLs.
EOF

# ----------------- patches READMEs -----------------
mkdir -p "$ROOT/patches"
cat > "$ROOT/patches/README.md" <<'EOF'
# Patches

- android_patch/: Drop-in module files (Kotlin + assets)
- backend_patch/: FastAPI app (Dockerfile + requirements)

Fill placeholders in code:
- Verifier.PUBKEY_B64 (Ed25519 public key, Base64)
- AntiTamper.EXPECTED_CERT_SHA256 (release signing cert SHA-256)
- NetworkModule TLS pin (SPKI sha256/…)
- AppConfig.GATEWAY_BASE_URL (your backend)
- .env ADMIN_API_KEY (backend admin key)
EOF

# ----------------- android_patch -----------------
mkdir -p "$ROOT/patches/android_patch/app/src/main/java/com/theking/{secure,net,ai,scan,policy}"
mkdir -p "$ROOT/patches/android_patch/app/src/main/assets/model"

cat > "$ROOT/patches/android_patch/README-PATCH.md" <<EOF
Android patch: security + AI scanner stubs.

Fill these placeholders after upload:
- Verifier.PUBKEY_B64 = $ED25519_PUBKEY_B64
- AntiTamper.EXPECTED_CERT_SHA256 = $EXPECTED_CERT_SHA256
- NetworkModule HOST = $BACKEND_HOST, PIN = $BACKEND_SPKI_SHA256_PIN
- AppConfig.GATEWAY_BASE_URL = $BACKEND_BASE_URL
EOF

# AppConfig
cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/AppConfig.kt" <<EOF
package com.theking

/**
 * Application configuration constants.
 */
object AppConfig {
    /** Base URL for the backend gateway. */
    const val GATEWAY_BASE_URL = "$BACKEND_BASE_URL"
    /** Minimum confidence for model predictions. */
    const val MODEL_MIN_CONF = 0.58f
    /** Minimum confidence for ensemble votes. */
    const val ENSEMBLE_MIN_CONF = 0.62f
}
EOF

# Verifier
cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/secure/Verifier.kt" <<EOF
package com.theking.secure
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import android.util.Base64

object Verifier {
    private const val PUBKEY_B64 = "$ED25519_PUBKEY_B64"
    fun verifyEd25519(message: ByteArray, sig: ByteArray): Boolean = try {
        val keyBytes = Base64.decode(PUBKEY_B64, Base64.NO_WRAP)
        val pub = KeyFactory.getInstance("Ed25519").generatePublic(X509EncodedKeySpec(keyBytes))
        val s = Signature.getInstance("Ed25519")
        s.initVerify(pub); s.update(message); s.verify(sig)
    } catch (_: Throwable) { false }
}
EOF

# AntiTamper
cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/secure/AntiTamper.kt" <<EOF
package com.theking.secure
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest

object AntiTamper {
    private const val EXPECTED_CERT_SHA256 = "$EXPECTED_CERT_SHA256" // hex lowercase, no colons
    fun isDebuggable(ctx: Context) =
        (ctx.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    fun certOk(ctx: Context): Boolean = try {
        val pm = ctx.packageManager; val pkg = ctx.packageName
        val info = if (Build.VERSION.SDK_INT >= 28)
            pm.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES)
          else pm.getPackageInfo(pkg, PackageManager.GET_SIGNATURES)
        val sig = if (Build.VERSION.SDK_INT >= 28) info.signingInfo.apkContentsSigners[0].toByteArray()
                  else info.signatures[0].toByteArray()
        val hex = MessageDigest.getInstance("SHA-256").digest(sig).joinToString("") { "%02x".format(it) }
        hex == EXPECTED_CERT_SHA256
    } catch (_: Throwable) { false }
    fun detectHooks(): Boolean = try {
        val maps = java.io.File("/proc/self/maps").readText()
        listOf("frida","xposed","substrate","edxposed").any { maps.contains(it, true) }
    } catch (_: Throwable) { false }
}
EOF

# NetworkModule with pinning
cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/net/NetworkModule.kt" <<EOF
package com.theking.net
import okhttp3.CertificatePinner
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

object NetworkModule {
    private const val HOST = "$BACKEND_HOST"
    private const val PIN  = "$BACKEND_SPKI_SHA256_PIN"
    val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .certificatePinner(CertificatePinner.Builder().add(HOST, PIN).build())
            .connectTimeout(6, TimeUnit.SECONDS)
            .readTimeout(6, TimeUnit.SECONDS)
            .writeTimeout(6, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build()
    }
}
EOF

# Minimal AI stubs (you will merge with your full AI files already built)
cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/ai/Direction.kt" <<'EOF'
package com.theking.ai
enum class Direction { NEUTRAL, LONG, SHORT }
EOF

cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/ai/Calibrator.kt" <<'EOF'
package com.theking.ai
import kotlin.math.pow
object Calibrator {
    @Volatile var temperature: Double = 1.0
    @Volatile var thrLongShort: Double = 0.34
    fun applyTemp(p: FloatArray): FloatArray {
        if (temperature == 1.0) return p
        val t = 1.0 / temperature
        val out = DoubleArray(p.size); var sum=0.0
        for (i in p.indices){ val v = p[i].toDouble().coerceIn(1e-9,1.0).pow(t); out[i]=v; sum+=v }
        return FloatArray(p.size){ (out[it]/sum).toFloat() }
    }
    fun pick(p: FloatArray): Pair<Direction, Double> {
        val q = applyTemp(p); val lo = q.getOrElse(1){0f}.toDouble(); val sh = q.getOrElse(2){0f}.toDouble()
        return when { lo>sh && lo>thrLongShort -> Direction.LONG to lo
                      sh>lo && sh>thrLongShort -> Direction.SHORT to sh
                      else -> Direction.NEUTRAL to 0.0 }
    }
}
EOF

cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/ai/Ensemble.kt" <<'EOF'
package com.theking.ai
object Ensemble {
    data class Vote(val dir: Direction, val conf: Float, val reason: String)
    fun vote(): Vote = Vote(Direction.NEUTRAL, 0.6f, "stub") // replace with your agents
}
EOF

cat > "$ROOT/patches/android_patch/app/src/main/java/com/theking/ai/ScalpBrain.kt" <<'EOF'
package com.theking.ai
object ScalpBrain {
    data class Signal(val dir: Direction, val conf: Float, val reason: String)
    fun decide(ens: Ensemble.Vote, model: Pair<Direction, Float>): Signal {
        val (md, mc) = model
        if (ens.dir==Direction.NEUTRAL && md==Direction.NEUTRAL) return Signal(Direction.NEUTRAL,0f,"neutral")
        return if (ens.dir==md) Signal(md, ((ens.conf+mc)/2f), "consensus") else
               if (mc>=0.7f) Signal(md, mc, "model_override") else Signal(Direction.NEUTRAL,0f,"disagree_gate")
    }
}
EOF

# Assets
cat > "$ROOT/patches/android_patch/app/src/main/assets/model/manifest.json" <<'EOF'
{
  "version": "bootstrap",
  "files": [
    {"name": "models/next1m.tflite", "sha256": "PLACEHOLDER"},
    {"name": "config/calib.json", "sha256": "PLACEHOLDER"}
  ]
}
EOF

mkdir -p "$ROOT/patches/android_patch/app/src/main/assets"
cat > "$ROOT/patches/android_patch/app/src/main/assets/index.html" <<'EOF'
<!doctype html><html><head><meta charset="utf-8"><title>THE-KING</title>
<style>body{font-family:system-ui;margin:12px}table{border-collapse:collapse;width:100%}td,th{border:1px solid #222;padding:6px}th{background:#111;color:#fff}</style>
</head><body><h3>Signals</h3><table><thead><tr><th>Symbol</th><th>TF</th><th>Dir</th><th>Conf</th><th>Lev</th><th>Reason</th></tr></thead><tbody id="rows"></tbody></table></body></html>
EOF

# Gradle notes
cat > "$ROOT/patches/android_patch/gradle-additions.txt" <<'EOF'
Add to app/build.gradle:
- implementation("com.squareup.okhttp3:okhttp:4.12.0")
- implementation("org.tensorflow:tensorflow-lite:2.14.0")
- implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
Keep: R8/ProGuard rules for okhttp3 and org.tensorflow
EOF

# ----------------- backend_patch -----------------
mkdir -p "$ROOT/patches/backend_patch/app/{routes,core}"
cat > "$ROOT/patches/backend_patch/README-PATCH.md" <<'EOF'
FastAPI patch: klines proxy/cache, indicators summary, model approvals, ops & tamper intake.
Start: uvicorn app.main:app --host 0.0.0.0 --port 8080
EOF

cat > "$ROOT/patches/backend_patch/requirements.txt" <<'EOF'
fastapi==0.115.0
uvicorn[standard]==0.30.6
httpx==0.27.0
pandas==2.2.2
pandas_ta==0.3.14b0
python-dotenv==1.0.1
cachetools==5.3.3
EOF

cat > "$ROOT/patches/backend_patch/app/core/config.py" <<'EOF'
from pydantic import BaseModel
from dotenv import load_dotenv
import os
load_dotenv()
class Settings(BaseModel):
    admin_api_key: str = os.getenv("ADMIN_API_KEY","change-me")
    allow_origins: list[str] = ["*"]
settings = Settings()
EOF

cat > "$ROOT/patches/backend_patch/app/core/store.py" <<'EOF'
import json, threading, os
_LOCK = threading.Lock()
_PATH = os.getenv("MODEL_APPROVALS_PATH", "approvals.json")
def _load():
    if not os.path.exists(_PATH): return {"approved": {}}
    with open(_PATH,"r") as f: return json.load(f)
def _save(d): open(_PATH,"w").write(json.dumps(d, indent=2))
def get_approvals(): 
    with _LOCK: return _load()
def set_approved(version: str, approved: bool):
    with _LOCK:
        d = _load(); d.setdefault("approved", {})[version] = approved; _save(d); return d
EOF

cat > "$ROOT/patches/backend_patch/app/routes/market.py" <<'EOF'
from fastapi import APIRouter
import httpx, time
from cachetools import TTLCache
router = APIRouter(prefix="/v1/market", tags=["market"])
cache = TTLCache(maxsize=512, ttl=5)
@router.get("/klines")
async def klines(symbol: str, interval: str="1m", limit: int=500):
    key = f"{symbol}:{interval}:{limit}"
    if key in cache: return cache[key]
    async with httpx.AsyncClient(timeout=5.0) as cli:
        r = await cli.get("https://api.binance.com/api/v3/klines", params={"symbol":symbol,"interval":interval,"limit":limit})
        r.raise_for_status()
        data = r.json()
    res = {"t": time.time(), "data": data}; cache[key]=res; return res
EOF

cat > "$ROOT/patches/backend_patch/app/routes/indicators.py" <<'EOF'
from fastapi import APIRouter
import pandas as pd, pandas_ta as ta
router = APIRouter(prefix="/v1/indicators", tags=["indicators"])
@router.post("/summary")
def summary(candles: list[list[float]]):
    df = pd.DataFrame(candles, columns=["t","o","h","l","c","v","x","y","z"])
    out = {"rsi14": float(ta.rsi(df["c"],14).iloc[-1]),
           "obv": float(ta.obv(df["c"], df["v"]).iloc[-1]),
           "atr": float(ta.atr(df["h"],df["l"],df["c"],14).iloc[-1])}
    return out
EOF

cat > "$ROOT/patches/backend_patch/app/routes/ops.py" <<'EOF'
from fastapi import APIRouter, Request
router = APIRouter(prefix="/v1/ops", tags=["ops"])
@router.post("/error")
async def error(req: Request):
    body = await req.json()
    ip = req.client.host if req.client else "unknown"
    return {"ok": True, "ip": ip, "echo": body}
EOF

cat > "$ROOT/patches/backend_patch/app/routes/security.py" <<'EOF'
from fastapi import APIRouter, Request
router = APIRouter(prefix="/v1/security", tags=["security"])
@router.post("/tamper")
async def tamper(req: Request):
    body = await req.json()
    ip = req.client.host if req.client else "unknown"
    return {"ok": True, "ip": ip, "tamper": body}
EOF

cat > "$ROOT/patches/backend_patch/app/routes/models.py" <<'EOF'
from fastapi import APIRouter, Header, HTTPException
from app.core.config import settings
from app.core.store import get_approvals, set_approved
router = APIRouter(prefix="/v1/models", tags=["models"])
@router.get("/approvals")
def approvals(): return get_approvals()
@router.post("/approve")
def approve(version: str, approved: bool, x_api_key: str | None = Header(default=None)):
    if x_api_key != settings.admin_api_key: raise HTTPException(401, "unauthorized")
    return set_approved(version, approved)
EOF

cat > "$ROOT/patches/backend_patch/app/main.py" <<'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routes import market, indicators, ops, security, models

app = FastAPI(title="THE-KING Backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allow_origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)
app.include_router(market.router)
app.include_router(indicators.router)
app.include_router(ops.router)
app.include_router(security.router)
app.include_router(models.router)

@app.get("/health")
def health(): return {"ok": True}
EOF

cat > "$ROOT/patches/backend_patch/app/routes/__init__.py" <<'EOF'
# namespace
EOF

cat > "$ROOT/patches/backend_patch/Dockerfile" <<'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host","0.0.0.0","--port","8080"]
EOF

cat > "$ROOT/patches/backend_patch/.env.example" <<'EOF'
ADMIN_API_KEY=change-me
# MODEL_APPROVALS_PATH=approvals.json
EOF

# ----------------- root README -----------------
cat > "$ROOT/README.md" <<EOF
# THE-KING

Most powerful retail trading AI — multi-agent SMC/ICT + on-device TFLite scalper, signed updates, and admin control.

## Quick start (Android)

- Merge files from patches/android_patch into your app.
- Fill placeholders:
  - Verifier.PUBKEY_B64 = $ED25519_PUBKEY_B64
  - AntiTamper.EXPECTED_CERT_SHA256 = $EXPECTED_CERT_SHA256
  - NetworkModule HOST = $BACKEND_HOST, PIN = $BACKEND_SPKI_SHA256_PIN
  - AppConfig.GATEWAY_BASE_URL = $BACKEND_BASE_URL
- Add Gradle deps per patches/android_patch/gradle-additions.txt
- Build and run.

## Quick start (Backend)

- cd patches/backend_patch
- cp .env.example .env && edit ADMIN_API_KEY
- pip install -r requirements.txt
- uvicorn app.main:app --host 0.0.0.0 --port 8080

## Releases

- Upload android_patch.zip and backend_patch.zip under /releases or attach to GitHub Releases.

See docs/ for architecture, manifest, and admin controls.
EOF

# Function to create patch zip with error handling
create_patch_zip() {
    local patch_dir="$1"
    local zip_file="$2"

    # Check if patch directory exists
    if [[ ! -d "$patch_dir" ]]; then
        echo "Error: Patch directory $patch_dir does not exist." >&2
        return 1
    fi

    # Remove existing zip file to ensure clean build
    if [[ -f "$zip_file" ]]; then
        rm -f "$zip_file"
    fi

    # Change to patch directory
    cd "$patch_dir" || {
        echo "Error: Failed to change to directory $patch_dir." >&2
        return 1
    }

    # Create zip file
    zip -qr "$zip_file" . || {
        echo "Error: Failed to create zip file $zip_file." >&2
        return 1
    }
}
# ----------------- make the 2 patch ZIPs -----------------
create_patch_zip "$ROOT/patches/android_patch" "$ROOT/releases/android_patch.zip"
create_patch_zip "$ROOT/patches/backend_patch" "$ROOT/releases/backend_patch.zip"

# ----------------- final pack -----------------
zip -qr "$OUT" "$ROOT"
echo "Generated: $OUT"
echo "Upload this file to your GitHub repo via: https://github.com/thekingofvolume-cmd/THE-KING/upload/main"
