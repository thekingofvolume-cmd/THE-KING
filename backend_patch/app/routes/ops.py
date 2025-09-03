from fastapi import APIRouter, Request
router = APIRouter(prefix="/v1/ops", tags=["ops"])

@router.post("/error")
async def error(req: Request):
    body = await req.json()
    ip = req.client.host if req.client else "unknown"
    # In production: send to SIEM/alerts
    return {"ok": True, "ip": ip, "echo": body}
