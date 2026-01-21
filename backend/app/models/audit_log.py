"""
Drishti AI - Audit Log Model

MongoDB document model for audit logging.
"""

from beanie import Document, Indexed
from pydantic import Field
from typing import Optional, Any
from datetime import datetime


class AuditLog(Document):
    """Audit log document model for tracking admin actions."""
    
    # The user who performed the action
    user_id: Optional[Indexed(str)] = None  # User ID as string
    
    # Action details
    action: str
    resource: Optional[str] = None
    details: Optional[Any] = None  # Mixed content
    
    # Request metadata
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    
    # Timestamp
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "audit_logs"
        indexes = [
            [("user_id", 1), ("timestamp", -1)],
            [("action", 1), ("timestamp", -1)]
        ]
