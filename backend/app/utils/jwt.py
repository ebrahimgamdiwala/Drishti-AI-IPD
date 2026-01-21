"""
Drishti AI - JWT Utilities

JWT token generation and verification.
"""

import jwt
from datetime import datetime, timedelta
from typing import Optional
from app.config import get_settings


def generate_token(user_id: str, expires_in_days: Optional[int] = None) -> str:
    """Generate a JWT token for a user."""
    settings = get_settings()
    
    if expires_in_days is None:
        expires_in_days = settings.jwt_expire_days
    
    payload = {
        "user_id": str(user_id),
        "exp": datetime.utcnow() + timedelta(days=expires_in_days),
        "iat": datetime.utcnow()
    }
    
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def verify_token(token: str) -> Optional[dict]:
    """Verify a JWT token and return the payload."""
    settings = get_settings()
    
    try:
        payload = jwt.decode(
            token, 
            settings.jwt_secret, 
            algorithms=[settings.jwt_algorithm]
        )
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def generate_verification_token() -> str:
    """Generate a token for email verification."""
    settings = get_settings()
    
    payload = {
        "purpose": "email-verification",
        "timestamp": datetime.utcnow().timestamp(),
        "exp": datetime.utcnow() + timedelta(hours=24)
    }
    
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def generate_reset_token() -> str:
    """Generate a token for password reset."""
    settings = get_settings()
    
    payload = {
        "purpose": "password-reset",
        "timestamp": datetime.utcnow().timestamp(),
        "exp": datetime.utcnow() + timedelta(hours=1)
    }
    
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
