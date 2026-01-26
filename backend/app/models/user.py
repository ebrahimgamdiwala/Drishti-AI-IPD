"""
Drishti AI - User Model

MongoDB document model for users with Beanie ODM.
"""

from beanie import Document, Indexed
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    """User role enumeration."""
    ADMIN = "admin"
    USER = "user"
    RELATIVE = "relative"


class AuthProvider(str, Enum):
    """Authentication provider type."""
    LOCAL = "local"
    GOOGLE = "google"


class EmergencyContact(BaseModel):
    """Emergency contact embedded document."""
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    relationship: Optional[str] = None


class AlertPreferences(BaseModel):
    """Alert preferences embedded document."""
    email_alerts: bool = True
    critical_only: bool = False


class UserSettings(BaseModel):
    """User settings embedded document."""
    voice_speed: float = 1.0
    high_contrast: bool = False
    continuous_listening: bool = False
    alert_preferences: AlertPreferences = Field(default_factory=AlertPreferences)


class User(Document):
    """User document model."""
    
    # Core fields
    email: Indexed(EmailStr, unique=True)
    password: Optional[str] = None  # Optional for Google OAuth users
    name: str
    role: UserRole = UserRole.USER
    profile_image: Optional[str] = None
    
    # Authentication
    auth_provider: AuthProvider = AuthProvider.LOCAL
    google_id: Optional[str] = None
    
    # Email verification
    is_email_verified: bool = False
    email_verification_token: Optional[str] = None
    
    # Password reset
    reset_password_token: Optional[str] = None
    reset_password_expires: Optional[datetime] = None
    
    # Emergency contacts
    emergency_contacts: List[EmergencyContact] = Field(default_factory=list)
    
    # Settings
    settings: UserSettings = Field(default_factory=UserSettings)
    
    # Connected users (references to other User IDs)
    connected_users: List[str] = Field(default_factory=list)  # Store as string IDs
    
    # Favorite known persons (references to KnownPerson IDs)
    favorite_persons: List[str] = Field(default_factory=list)
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_active: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "users"
        
    def to_safe_dict(self) -> dict:
        """Return user data without sensitive fields."""
        data = self.model_dump()
        # Remove sensitive fields
        data.pop("password", None)
        data.pop("email_verification_token", None)
        data.pop("reset_password_token", None)
        data.pop("reset_password_expires", None)
        # Convert ID to string
        data["id"] = str(self.id)
        return data
