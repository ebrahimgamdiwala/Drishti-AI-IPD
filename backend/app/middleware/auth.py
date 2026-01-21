"""
Drishti AI - Auth Middleware

JWT authentication middleware and dependencies.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional, List
from datetime import datetime

from app.utils.jwt import verify_token
from app.models.user import User, UserRole


# HTTP Bearer security scheme
security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> User:
    """
    Dependency to get the current authenticated user.
    Raises 401 if not authenticated.
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No token provided",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    token = credentials.credentials
    payload = verify_token(token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload"
        )
    
    # Get user from database
    user = await User.get(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    # Update last active timestamp
    user.last_active = datetime.utcnow()
    await user.save()
    
    return user


async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[User]:
    """
    Dependency to optionally get the current user.
    Returns None if not authenticated (doesn't raise error).
    """
    if not credentials:
        return None
    
    try:
        token = credentials.credentials
        payload = verify_token(token)
        
        if not payload:
            return None
        
        user_id = payload.get("user_id")
        if not user_id:
            return None
        
        user = await User.get(user_id)
        return user
        
    except Exception:
        return None


def require_role(*allowed_roles: UserRole):
    """
    Dependency factory to require specific user roles.
    
    Usage:
        @router.get("/admin-only")
        async def admin_only(user: User = Depends(require_role(UserRole.ADMIN))):
            ...
    """
    async def role_checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error": "Access denied",
                    "required": [r.value for r in allowed_roles],
                    "current": user.role.value
                }
            )
        return user
    
    return role_checker


# Convenience dependencies for common role checks
async def get_admin_user(user: User = Depends(get_current_user)) -> User:
    """Require admin role."""
    if user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return user


async def get_admin_or_relative(user: User = Depends(get_current_user)) -> User:
    """Require admin or relative role."""
    if user.role not in [UserRole.ADMIN, UserRole.RELATIVE]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin or relative access required"
        )
    return user
