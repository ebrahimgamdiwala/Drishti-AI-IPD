"""
Drishti AI - Alert Model

MongoDB document model for alerts/warnings.
"""

from beanie import Document, Indexed
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class AlertType(str, Enum):
    """Alert type enumeration."""
    CLOSE_CALL = "close-call"
    LIFE_THREAT = "life-threat"
    OBSTACLE = "obstacle"
    WARNING = "warning"
    INFO = "info"


class AlertSeverity(str, Enum):
    """Alert severity enumeration."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class DetectedObject(BaseModel):
    """Detected object embedded document."""
    object: str
    confidence: float = 0.0
    distance: str = "unknown"


class Location(BaseModel):
    """Location embedded document."""
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class EmailSent(BaseModel):
    """Email sent record embedded document."""
    recipient_email: str
    sent_at: datetime = Field(default_factory=datetime.utcnow)
    status: str = "sent"


class Alert(Document):
    """Alert document model."""
    
    # Reference to user
    user_id: Indexed(str)  # Store as string ID
    
    # Alert details
    type: AlertType = AlertType.INFO
    severity: AlertSeverity = AlertSeverity.MEDIUM
    description: str
    
    # Image reference
    image_ref: Optional[str] = None
    
    # Detected objects
    detected_objects: List[DetectedObject] = Field(default_factory=list)
    
    # Location
    location: Optional[Location] = None
    
    # Model response
    model_response: Optional[str] = None
    
    # Acknowledgement
    acknowledged: bool = False
    acknowledged_by: Optional[str] = None  # User ID as string
    acknowledged_at: Optional[datetime] = None
    
    # Email tracking
    emails_sent: List[EmailSent] = Field(default_factory=list)
    
    # Timestamp
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "alerts"
        indexes = [
            [("user_id", 1), ("created_at", -1)],
            [("severity", 1), ("acknowledged", 1)]
        ]
