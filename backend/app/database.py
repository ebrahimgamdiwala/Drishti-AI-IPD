"""
Drishti AI - Database Module

MongoDB connection using Motor (async driver) and Beanie ODM.
"""

from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from typing import Optional
from urllib.parse import urlparse

from app.config import get_settings

# Global database client/state
_client: Optional[AsyncIOMotorClient] = None
_db_name: Optional[str] = None


def _resolve_db_name(uri: str, fallback: str) -> str:
    """Pick DB name from URI path when present, otherwise use fallback."""
    parsed = urlparse(uri)
    if parsed.path and parsed.path not in {"", "/"}:
        return parsed.path.lstrip("/").split("/")[0]
    return fallback


async def init_db():
    """Initialize database connection and Beanie ODM."""
    global _client, _db_name
    
    settings = get_settings()
    
    # Create Motor client with SSL configuration for Windows compatibility
    _client = AsyncIOMotorClient(
        settings.mongo_uri,
        tlsAllowInvalidCertificates=True,
        serverSelectionTimeoutMS=30000
    )
    _db_name = _resolve_db_name(settings.mongo_uri, settings.mongo_db_name)
    db = _client[_db_name]
    
    # Import models here to avoid circular imports
    from app.models.user import User
    from app.models.alert import Alert
    from app.models.known_person import KnownPerson
    from app.models.subscription import Subscription
    from app.models.audit_log import AuditLog
    
    # Initialize Beanie with document models
    await init_beanie(
        database=db,
        document_models=[
            User,
            Alert,
            KnownPerson,
            Subscription,
            AuditLog
        ]
    )
    
    print(f"✅ Connected to MongoDB (db='{_db_name}')")


async def close_db():
    """Close database connection."""
    global _client, _db_name
    
    if _client:
        _client.close()
        _client = None
        _db_name = None
        print("🔌 MongoDB connection closed")


def get_database():
    """Get the database instance."""
    if _client is None or _db_name is None:
        raise RuntimeError("Database not initialized. Call init_db() first.")
    return _client[_db_name]
