"""
Drishti AI - Security Utilities

Password hashing and verification.
"""

from passlib.context import CryptContext

# Password hashing context (use sha256_crypt to avoid bcrypt backend issues and length limits)
pwd_context = CryptContext(schemes=["sha256_crypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)
