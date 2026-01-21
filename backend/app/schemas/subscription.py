"""
Drishti AI - Subscription Schemas

Pydantic schemas for subscription requests/responses.
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class SubscribeRequest(BaseModel):
    """Request schema for subscribing to alerts."""
    user_id: str
    alert_types: Optional[List[str]] = ["all"]


class UpdateSubscriptionRequest(BaseModel):
    """Request schema for updating a subscription."""
    alert_types: Optional[List[str]] = None
    is_active: Optional[bool] = None


class SubscriptionResponse(BaseModel):
    """Response schema for a subscription."""
    id: str
    relative_id: str
    user_id: str
    alert_types: List[str]
    is_active: bool
    created_at: datetime


class SubscriberResponse(BaseModel):
    """Response schema for a subscriber."""
    id: str
    name: str
    email: str
