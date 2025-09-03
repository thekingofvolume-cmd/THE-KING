from pydantic import BaseModel
from dotenv import load_dotenv
import os
load_dotenv()

class Settings(BaseModel):
    admin_api_key: str = os.getenv("ADMIN_API_KEY","change-me")
    allow_origins: list[str] = ["*"]

settings = Settings()
