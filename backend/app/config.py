"""
Drishti AI - Configuration Module

Loads environment variables using Pydantic Settings.
"""

from pydantic_settings import BaseSettings
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # MongoDB
    mongo_uri: str = "mongodb://localhost:27017/drishti-ai"
    mongo_db_name: str = "drishti-ai"
    
    # JWT
    jwt_secret: str = "change-this-secret-key"
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 7
    
    # Email (Resend)
    resend_api_key: Optional[str] = None
    email_from: str = "Drishti AI <noreply@drishti.ai>"
    resend_default_domain: str = "drishti.ai"
    
    # Ollama VLM
    ollama_url: str = "http://localhost:11434"
    ollama_model: str = "llava:7b"
    
    # Frontend URL (for email links)
    frontend_url: str = "http://localhost:5173"
    
    # Google OAuth
    google_client_id: Optional[str] = None
    google_client_secret: Optional[str] = None
    
    # Server
    port: int = 5000
    debug: bool = False
    node_env: str = "development"
    
    # File uploads
    max_file_size: int = 10485760  # 10MB
    upload_dir: str = "./uploads"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
        extra = "ignore"  # Allow extra env variables


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
