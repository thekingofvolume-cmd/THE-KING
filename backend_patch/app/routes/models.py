from fastapi import APIRouter, Header, HTTPException
from app.core.config import settings
from app.core.store import get_approvals, set_approved

router = APIRouter(prefix="/v1/models", tags=["models"])

@router.get("/approvals")
def approvals():
    return get_approvals()

@router.post("/approve")
def approve(version: str, approved: bool, x_api_key: str | None = Header(default=None)):
    if x_api_key != settings.admin_api_key:
        raise HTTPException(401, "unauthorized")
    return set_approved(version, approved)
