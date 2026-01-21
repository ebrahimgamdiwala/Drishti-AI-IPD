"""
Drishti AI - Auth Schemas

Pydantic schemas for authentication requests/responses.
"""

from pydantic import BaseModel, EmailStr, Field
from typing import Optional


class SignupRequest(BaseModel):
    """Request schema for user signup."""
    email: EmailStr
    password: str = Field(..., min_length=6)
    name: str = Field(..., min_length=1)
    role: Optional[str] = "user"


class LoginRequest(BaseModel):
    """Request schema for user login."""
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    """Request schema for Google OAuth."""
    code: Optional[str] = None  # Authorization code
    id_token: Optional[str] = None  # ID token (alternative flow)
    access_token: Optional[str] = None  # Access token (alternative flow)


class VerifyEmailRequest(BaseModel):
    """Request schema for email verification."""
    token: str


class ForgotPasswordRequest(BaseModel):
    """Request schema for forgot password."""
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Request schema for password reset."""
    token: str
    password: str = Field(..., min_length=6)


class AuthResponse(BaseModel):
    """Response schema for authentication."""
    message: str
    token: Optional[str] = None
    user: Optional[dict] = None


class UserResponse(BaseModel):
    """Response schema for user data."""
    id: str
    email: str
    name: str
    role: str
    is_email_verified: bool = False
