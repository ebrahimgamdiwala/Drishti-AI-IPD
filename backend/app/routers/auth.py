"""
Drishti AI - Auth Router

Authentication endpoints: signup, login, Google OAuth, email verification, password reset.
"""

from fastapi import APIRouter, HTTPException, status
from datetime import datetime
import secrets

from app.schemas.auth import (
    SignupRequest,
    LoginRequest,
    GoogleAuthRequest,
    VerifyEmailRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    AuthResponse
)
from app.models.user import User
from app.services.auth_service import (
    create_user,
    authenticate_user,
    google_auth
)
from app.services.email_service import (
    send_verification_email,
    send_password_reset_email
)
from app.utils.security import hash_password


router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignupRequest):
    """Register a new user with email and password."""
    
    # Check if email already exists
    existing_user = await User.find_one(User.email == request.email.lower())
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user
    user, token, verification_token = await create_user(
        email=request.email,
        password=request.password,
        name=request.name,
        role=request.role or "user"
    )
    
    # Send verification email
    await send_verification_email(user.email, user.name, verification_token)
    
    return AuthResponse(
        message="User created successfully. Please check your email to verify your account.",
        token=token,
        user=user.to_safe_dict()
    )


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest):
    """Login with email and password."""
    
    user, token = await authenticate_user(request.email, request.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials"
        )
    
    return AuthResponse(
        message="Login successful",
        token=token,
        user=user.to_safe_dict()
    )


@router.post("/google", response_model=AuthResponse)
async def google_login(request: GoogleAuthRequest):
    """Login or register with Google OAuth."""
    
    user, token, error = await google_auth(
        code=request.code,
        id_token=request.id_token,
        access_token=request.access_token
    )
    
    if error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error
        )
    
    return AuthResponse(
        message="Google authentication successful",
        token=token,
        user=user.to_safe_dict()
    )


@router.post("/verify-email", response_model=AuthResponse)
async def verify_email(request: VerifyEmailRequest):
    """Verify email address with token."""
    
    if not request.token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token is required"
        )
    
    user = await User.find_one(User.email_verification_token == request.token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired token"
        )
    
    user.is_email_verified = True
    user.email_verification_token = None
    await user.save()
    
    return AuthResponse(
        message="Email verified successfully",
        user=user.to_safe_dict()
    )


@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest):
    """Request password reset email."""
    
    if not request.email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is required"
        )
    
    user = await User.find_one(User.email == request.email.lower())
    
    # Always return success to prevent email enumeration
    if not user:
        return {"message": "If the email exists, a reset link has been sent"}
    
    # Generate reset token
    reset_token = secrets.token_hex(32)
    user.reset_password_token = reset_token
    user.reset_password_expires = datetime.utcnow()
    await user.save()
    
    # Send reset email
    await send_password_reset_email(user.email, user.name, reset_token)
    
    return {"message": "If the email exists, a reset link has been sent"}


@router.post("/reset-password")
async def reset_password(request: ResetPasswordRequest):
    """Reset password with token."""
    
    if not request.token or not request.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token and password are required"
        )
    
    if len(request.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters"
        )
    
    user = await User.find_one(User.reset_password_token == request.token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired token"
        )
    
    # Update password
    user.password = hash_password(request.password)
    user.reset_password_token = None
    user.reset_password_expires = None
    await user.save()
    
    return {"message": "Password reset successful"}
