from fastapi import APIRouter, Query
import httpx, time
from cachetools import TTLCache

router = APIRouter(prefix="/v1/market", tags=["market"])
_cache = TTLCache(maxsize=512, ttl=5)

@router.get("/klines")
async def klines(symbol: str, interval: str = "1m", limit: int = 500):
    key = f"{symbol}:{interval}:{limit}"
    now = time.time()
    if key in _cache:
        return _cache[key]
    url = "https://api.binance.com/api/v3/klines"
    async with httpx.AsyncClient(timeout=5.0) as cli:
        r = await cli.get(url, params={"symbol": symbol, "interval": interval, "limit": limit})
        r.raise_for_status()
        data = r.json()
    _cache[key] = {"t": now, "data": data}
    return _cache[key]
