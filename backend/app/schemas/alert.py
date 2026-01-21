"""
Drishti AI - Alert Schemas

Pydantic schemas for alert-related requests/responses.
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class DetectedObjectSchema(BaseModel):
    """Schema for detected object."""
    object: str
    confidence: float = 0.0
    distance: str = "unknown"


class LocationSchema(BaseModel):
    """Schema for location."""
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class CreateAlertRequest(BaseModel):
    """Request schema for creating an alert."""
    type: Optional[str] = "info"
    severity: Optional[str] = "medium"
    description: str
    image_ref: Optional[str] = None
    detected_objects: Optional[List[DetectedObjectSchema]] = None
    location: Optional[LocationSchema] = None


class AlertResponse(BaseModel):
    """Response schema for an alert."""
    id: str
    user_id: str
    type: str
    severity: str
    description: str
    image_ref: Optional[str] = None
    detected_objects: List[DetectedObjectSchema] = []
    acknowledged: bool = False
    created_at: datetime


class AlertStatsResponse(BaseModel):
    """Response schema for alert statistics."""
    total: int
    unacknowledged: int
    by_severity: dict = {}
