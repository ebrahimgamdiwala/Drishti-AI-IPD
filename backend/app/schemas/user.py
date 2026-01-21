"""
Drishti AI - User Schemas

Pydantic schemas for user-related requests/responses.
"""

from pydantic import BaseModel, EmailStr
from typing import Optional, List


class EmergencyContactSchema(BaseModel):
    """Schema for emergency contact."""
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    relationship: Optional[str] = None


class AlertPreferencesSchema(BaseModel):
    """Schema for alert preferences."""
    email_alerts: Optional[bool] = True
    critical_only: Optional[bool] = False


class UserSettingsSchema(BaseModel):
    """Schema for user settings."""
    voice_speed: Optional[float] = 1.0
    high_contrast: Optional[bool] = False
    continuous_listening: Optional[bool] = False
    alert_preferences: Optional[AlertPreferencesSchema] = None


class UpdateProfileRequest(BaseModel):
    """Request schema for updating user profile."""
    name: Optional[str] = None
    emergency_contacts: Optional[List[EmergencyContactSchema]] = None
    settings: Optional[UserSettingsSchema] = None


class ConnectUserRequest(BaseModel):
    """Request schema for connecting to another user."""
    target_user_id: str


class ConnectedUserResponse(BaseModel):
    """Response schema for connected user."""
    id: str
    name: str
    email: str
    role: str
