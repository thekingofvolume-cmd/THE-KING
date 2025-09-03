from fastapi import APIRouter, Query
import pandas as pd, pandas_ta as ta

router = APIRouter(prefix="/v1/indicators", tags=["indicators"])

@router.post("/summary")
def summary(candles: list[list[float]]):
    # candles: [[openTime, open, high, low, close, volume, ...], ...]
    df = pd.DataFrame(candles, columns=["t","o","h","l","c","v","x","y","z"])
    out = {}
    out["rsi14"] = ta.rsi(df["c"], 14).iloc[-1]
    out["obv"] = ta.obv(df["c"], df["v"]).iloc[-1]
    out["atr"] = ta.atr(df["h"], df["l"], df["c"], 14).iloc[-1]
    return out
