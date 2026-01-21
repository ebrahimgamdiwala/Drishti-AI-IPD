"""
Drishti AI - Users Router

User profile and connection endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from app.schemas.user import (
    UpdateProfileRequest,
    ConnectUserRequest,
    ConnectedUserResponse
)
from app.models.user import User
from app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/users", tags=["Users"])


@router.get("/profile")
async def get_profile(user: User = Depends(get_current_user)):
    """Get current user's profile."""
    return {"user": user.to_safe_dict()}


@router.put("/profile")
async def update_profile(
    request: UpdateProfileRequest,
    user: User = Depends(get_current_user)
):
    """Update current user's profile."""
    
    if request.name:
        user.name = request.name
    
    if request.emergency_contacts is not None:
        from app.models.user import EmergencyContact
        user.emergency_contacts = [
            EmergencyContact(**c.model_dump()) 
            for c in request.emergency_contacts
        ]
    
    if request.settings:
        from app.models.user import UserSettings, AlertPreferences
        
        # Update settings while preserving existing values
        if request.settings.voice_speed is not None:
            user.settings.voice_speed = request.settings.voice_speed
        if request.settings.high_contrast is not None:
            user.settings.high_contrast = request.settings.high_contrast
        if request.settings.continuous_listening is not None:
            user.settings.continuous_listening = request.settings.continuous_listening
        if request.settings.alert_preferences:
            if request.settings.alert_preferences.email_alerts is not None:
                user.settings.alert_preferences.email_alerts = request.settings.alert_preferences.email_alerts
            if request.settings.alert_preferences.critical_only is not None:
                user.settings.alert_preferences.critical_only = request.settings.alert_preferences.critical_only
    
    await user.save()
    
    return {"message": "Profile updated successfully", "user": user.to_safe_dict()}


@router.post("/connect")
async def connect_user(
    request: ConnectUserRequest,
    user: User = Depends(get_current_user)
):
    """Connect to another user."""
    
    if not request.target_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Target user ID is required"
        )
    
    # Find target user
    target_user = await User.get(request.target_user_id)
    
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Add to connected users if not already connected
    target_id_str = str(target_user.id)
    if target_id_str not in user.connected_users:
        user.connected_users.append(target_id_str)
        await user.save()
    
    return {
        "message": "Connected successfully",
        "connectedUser": {
            "id": str(target_user.id),
            "name": target_user.name,
            "email": target_user.email,
            "role": target_user.role.value
        }
    }


@router.get("/connected", response_model=dict)
async def get_connected_users(user: User = Depends(get_current_user)):
    """Get list of connected users."""
    
    connected_users = []
    
    for user_id in user.connected_users:
        connected_user = await User.get(user_id)
        if connected_user:
            connected_users.append({
                "id": str(connected_user.id),
                "name": connected_user.name,
                "email": connected_user.email,
                "role": connected_user.role.value
            })
    
    return {"connectedUsers": connected_users}
