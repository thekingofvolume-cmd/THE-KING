from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routes import market, indicators, ops, security, models

app = FastAPI(title="THE-KING Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(market.router)
app.include_router(indicators.router)
app.include_router(ops.router)
app.include_router(security.router)
app.include_router(models.router)

@app.get("/health")
def health(): return {"ok": True}
