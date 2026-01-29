"""
Drishti AI - Connected Users Router

Manage connections between users (family/friends network).
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from pydantic import BaseModel, EmailStr
from app.models.user import User
from app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/connected-users", tags=["Connected Users"])


class ConnectUserRequest(BaseModel):
    """Schema for connecting with another user."""
    email: Optional[EmailStr] = None
    user_id: Optional[str] = None


@router.get("")
async def get_connected_users(user: User = Depends(get_current_user)):
    """Get all users connected to the current user."""
    
    connected_user_ids = user.connected_users or []
    
    if not connected_user_ids:
        return {"connected_users": [], "count": 0}
    
    # Fetch the actual user documents
    connected_users = []
    for user_id in connected_user_ids:
        connected_user = await User.get(user_id)
        if connected_user:
            # Return safe user data (no passwords, tokens, etc.)
            connected_users.append({
                "id": str(connected_user.id),
                "name": connected_user.name,
                "email": connected_user.email,
                "profile_image": connected_user.profile_image,
                "role": connected_user.role,
                "last_active": connected_user.last_active.isoformat() if connected_user.last_active else None
            })
    
    return {
        "connected_users": connected_users,
        "count": len(connected_users)
    }


@router.post("/connect")
async def connect_user(
    request: ConnectUserRequest,
    user: User = Depends(get_current_user)
):
    """
    Connect with another user by email or user ID.
    Creates a bidirectional connection.
    """
    
    # Find the user to connect with
    target_user = None
    
    if request.email:
        target_user = await User.find_one(User.email == request.email)
    elif request.user_id:
        target_user = await User.get(request.user_id)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either email or user_id must be provided"
        )
    
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Can't connect with yourself
    if str(target_user.id) == str(user.id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot connect with yourself"
        )
    
    # Initialize connected_users if it doesn't exist
    if not user.connected_users:
        user.connected_users = []
    if not target_user.connected_users:
        target_user.connected_users = []
    
    # Check if already connected
    target_id_str = str(target_user.id)
    user_id_str = str(user.id)
    
    if target_id_str in user.connected_users:
        return {
            "message": "Already connected with this user",
            "user": {
                "id": target_id_str,
                "name": target_user.name,
                "email": target_user.email
            }
        }
    
    # Create bidirectional connection
    user.connected_users.append(target_id_str)
    target_user.connected_users.append(user_id_str)
    
    await user.save()
    await target_user.save()
    
    return {
        "message": "Successfully connected",
        "user": {
            "id": target_id_str,
            "name": target_user.name,
            "email": target_user.email,
            "profile_image": target_user.profile_image
        }
    }


@router.delete("/{user_id}")
async def disconnect_user(
    user_id: str,
    user: User = Depends(get_current_user)
):
    """
    Disconnect from another user.
    Removes the bidirectional connection.
    """
    
    if not user.connected_users or user_id not in user.connected_users:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connection not found"
        )
    
    # Get the other user
    other_user = await User.get(user_id)
    
    # Remove from current user's connections
    user.connected_users.remove(user_id)
    await user.save()
    
    # Remove bidirectional connection if other user exists
    if other_user and user.connected_users:
        user_id_str = str(user.id)
        if user_id_str in other_user.connected_users:
            other_user.connected_users.remove(user_id_str)
            await other_user.save()
    
    return {
        "message": "Successfully disconnected",
        "user_id": user_id
    }


@router.get("/search")
async def search_users(
    query: str,
    user: User = Depends(get_current_user)
):
    """
    Search for users by name or email to connect with.
    Excludes already connected users and self.
    """
    
    if len(query) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Query must be at least 2 characters"
        )
    
    # Search by name or email (case-insensitive)
    # Using regex for partial matching
    users = await User.find(
        {
            "$or": [
                {"name": {"$regex": query, "$options": "i"}},
                {"email": {"$regex": query, "$options": "i"}}
            ],
            "_id": {"$ne": user.id}  # Exclude self
        }
    ).limit(20).to_list()
    
    # Filter out already connected users
    connected_ids = set(user.connected_users or [])
    
    results = []
    for found_user in users:
        user_id_str = str(found_user.id)
        if user_id_str not in connected_ids:
            results.append({
                "id": user_id_str,
                "name": found_user.name,
                "email": found_user.email,
                "profile_image": found_user.profile_image,
                "role": found_user.role
            })
    
    return {
        "results": results,
        "count": len(results)
    }


@router.get("/{user_id}/status")
async def get_user_status(
    user_id: str,
    user: User = Depends(get_current_user)
):
    """
    Get status of a connected user.
    Only works if users are connected.
    """
    
    if not user.connected_users or user_id not in user.connected_users:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not connected with this user"
        )
    
    connected_user = await User.get(user_id)
    
    if not connected_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {
        "id": str(connected_user.id),
        "name": connected_user.name,
        "last_active": connected_user.last_active.isoformat() if connected_user.last_active else None,
        "status": "active" if connected_user.last_active else "inactive"
    }
