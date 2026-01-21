"""
Drishti AI - Subscription Model

MongoDB document model for alert subscriptions.
"""

from beanie import Document, Indexed
from pydantic import Field
from typing import List
from datetime import datetime
from enum import Enum


class SubscriptionAlertType(str, Enum):
    """Subscription alert type enumeration."""
    CLOSE_CALL = "close-call"
    LIFE_THREAT = "life-threat"
    OBSTACLE = "obstacle"
    WARNING = "warning"
    ALL = "all"


class Subscription(Document):
    """Subscription document model for alert notifications."""
    
    # The relative/caregiver who is subscribing
    relative_id: Indexed(str)  # User ID as string
    
    # The user they are subscribing to
    user_id: Indexed(str)  # User ID as string
    
    # Alert types to receive
    alert_types: List[SubscriptionAlertType] = Field(default_factory=lambda: [SubscriptionAlertType.ALL])
    
    # Active status
    is_active: bool = True
    
    # Timestamp
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "subscriptions"
        indexes = [
            [("relative_id", 1), ("user_id", 1)]
        ]
