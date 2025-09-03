from fastapi import APIRouter, Request
router = APIRouter(prefix="/v1/security", tags=["security"])

@router.post("/tamper")
async def tamper(req: Request):
    data = await req.json()
    ip = req.client.host if req.client else "unknown"
    # In production: alert + blocklist candidate
    return {"ok": True, "ip": ip, "tamper": data}
