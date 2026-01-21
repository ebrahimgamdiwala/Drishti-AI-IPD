"""
Drishti AI - Auth Service

Authentication business logic including Google OAuth.
"""

import httpx
from typing import Optional, Tuple
from app.config import get_settings
from app.models.user import User, UserRole, AuthProvider
from app.utils.security import hash_password, verify_password
from app.utils.jwt import generate_token
import secrets


async def authenticate_user(email: str, password: str) -> Tuple[Optional[User], Optional[str]]:
    """
    Authenticate a user with email and password.
    Returns (user, token) on success, (None, None) on failure.
    """
    user = await User.find_one(User.email == email.lower())
    
    if not user:
        return None, None
    
    if user.auth_provider == AuthProvider.GOOGLE:
        return None, None  # Google users cannot login with password
    
    if not user.password or not verify_password(password, user.password):
        return None, None
    
    token = generate_token(str(user.id))
    return user, token


async def create_user(
    email: str, 
    password: str, 
    name: str, 
    role: str = "user"
) -> Tuple[User, str, str]:
    """
    Create a new user with email and password.
    Returns (user, token, verification_token).
    """
    # Generate verification token
    verification_token = secrets.token_hex(32)
    
    # Create user
    user = User(
        email=email.lower(),
        password=hash_password(password),
        name=name,
        role=UserRole(role) if role in [r.value for r in UserRole] else UserRole.USER,
        auth_provider=AuthProvider.LOCAL,
        email_verification_token=verification_token
    )
    
    await user.insert()
    
    token = generate_token(str(user.id))
    return user, token, verification_token


async def google_auth(
    code: Optional[str] = None,
    id_token: Optional[str] = None,
    access_token: Optional[str] = None
) -> Tuple[Optional[User], Optional[str], Optional[str]]:
    """
    Authenticate or register a user via Google OAuth.
    Returns (user, token, error).
    """
    settings = get_settings()
    
    if not settings.google_client_id or not settings.google_client_secret:
        return None, None, "Google OAuth not configured"
    
    google_user_info = None
    
    # If we have an authorization code, exchange it for tokens
    if code:
        try:
            async with httpx.AsyncClient() as client:
                # Exchange code for tokens
                token_response = await client.post(
                    "https://oauth2.googleapis.com/token",
                    data={
                        "code": code,
                        "client_id": settings.google_client_id,
                        "client_secret": settings.google_client_secret,
                        "redirect_uri": f"{settings.frontend_url}/auth/google/callback",
                        "grant_type": "authorization_code"
                    }
                )
                
                if token_response.status_code != 200:
                    return None, None, f"Failed to exchange code: {token_response.text}"
                
                tokens = token_response.json()
                access_token = tokens.get("access_token")
        except Exception as e:
            return None, None, f"Token exchange failed: {str(e)}"
    
    # Get user info using access token
    if access_token:
        try:
            async with httpx.AsyncClient() as client:
                user_info_response = await client.get(
                    "https://www.googleapis.com/oauth2/v2/userinfo",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
                
                if user_info_response.status_code != 200:
                    return None, None, "Failed to get user info from Google"
                
                google_user_info = user_info_response.json()
        except Exception as e:
            return None, None, f"Failed to get user info: {str(e)}"
    
    # If we have an ID token, decode it
    elif id_token:
        try:
            async with httpx.AsyncClient() as client:
                # Verify token with Google
                verify_response = await client.get(
                    f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
                )
                
                if verify_response.status_code != 200:
                    return None, None, "Invalid ID token"
                
                token_info = verify_response.json()
                
                # Verify the token is for our app
                if token_info.get("aud") != settings.google_client_id:
                    return None, None, "Token not issued for this application"
                
                google_user_info = {
                    "id": token_info.get("sub"),
                    "email": token_info.get("email"),
                    "name": token_info.get("name"),
                    "verified_email": token_info.get("email_verified") == "true"
                }
        except Exception as e:
            return None, None, f"ID token verification failed: {str(e)}"
    
    if not google_user_info:
        return None, None, "No valid authentication method provided"
    
    google_id = google_user_info.get("id")
    email = google_user_info.get("email", "").lower()
    name = google_user_info.get("name", email.split("@")[0])
    
    if not google_id or not email:
        return None, None, "Could not get user info from Google"
    
    # Check if user exists by Google ID
    user = await User.find_one(User.google_id == google_id)
    
    if not user:
        # Check if user exists by email
        user = await User.find_one(User.email == email)
        
        if user:
            # Link Google account to existing user
            user.google_id = google_id
            user.auth_provider = AuthProvider.GOOGLE
            user.is_email_verified = True  # Google emails are verified
            await user.save()
        else:
            # Create new user
            user = User(
                email=email,
                name=name,
                google_id=google_id,
                auth_provider=AuthProvider.GOOGLE,
                is_email_verified=True,
                role=UserRole.USER
            )
            await user.insert()
    
    token = generate_token(str(user.id))
    return user, token, None
