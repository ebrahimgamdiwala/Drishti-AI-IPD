"""
Drishti AI - Subscriptions Router

Alert subscription management.
"""

from fastapi import APIRouter, Depends, HTTPException, status

from app.schemas.subscription import (
    SubscribeRequest,
    UpdateSubscriptionRequest,
    SubscriptionResponse
)
from app.models.subscription import Subscription, SubscriptionAlertType
from app.models.user import User, UserRole
from app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/subscribe", tags=["Subscriptions"])


@router.post("")
async def subscribe(
    request: SubscribeRequest,
    user: User = Depends(get_current_user)
):
    """Subscribe to a user's alerts."""
    
    if not request.user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User ID is required"
        )
    
    # Verify target user exists
    target_user = await User.get(request.user_id)
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check for existing subscription
    existing = await Subscription.find_one(
        Subscription.relative_id == str(user.id),
        Subscription.user_id == request.user_id
    )
    
    if existing:
        # Update existing subscription
        alert_types = [
            SubscriptionAlertType(at) for at in (request.alert_types or ["all"])
        ]
        existing.alert_types = alert_types
        existing.is_active = True
        await existing.save()
        
        return {
            "message": "Subscription updated",
            "subscription": {
                "id": str(existing.id),
                "relative_id": existing.relative_id,
                "user_id": existing.user_id,
                "alert_types": [at.value for at in existing.alert_types],
                "is_active": existing.is_active
            }
        }
    
    # Create new subscription
    alert_types = [
        SubscriptionAlertType(at) for at in (request.alert_types or ["all"])
    ]
    
    subscription = Subscription(
        relative_id=str(user.id),
        user_id=request.user_id,
        alert_types=alert_types,
        is_active=True
    )
    
    await subscription.insert()
    
    return {
        "message": "Subscribed successfully",
        "subscription": {
            "id": str(subscription.id),
            "relative_id": subscription.relative_id,
            "user_id": subscription.user_id,
            "alert_types": [at.value for at in subscription.alert_types],
            "is_active": subscription.is_active
        }
    }


@router.get("")
async def list_subscriptions(user: User = Depends(get_current_user)):
    """List subscriptions (who the current user is subscribed to)."""
    
    subscriptions = await Subscription.find(
        Subscription.relative_id == str(user.id)
    ).to_list()
    
    # Populate user info
    subs_with_users = []
    for sub in subscriptions:
        sub_dict = {
            "id": str(sub.id),
            "relative_id": sub.relative_id,
            "user_id": sub.user_id,
            "alert_types": [at.value for at in sub.alert_types],
            "is_active": sub.is_active,
            "created_at": sub.created_at.isoformat()
        }
        
        target_user = await User.get(sub.user_id)
        if target_user:
            sub_dict["user"] = {
                "name": target_user.name,
                "email": target_user.email
            }
        
        subs_with_users.append(sub_dict)
    
    return {"subscriptions": subs_with_users}


@router.get("/subscribers")
async def list_subscribers(user: User = Depends(get_current_user)):
    """List subscribers (who is subscribed to the current user's alerts)."""
    
    subscriptions = await Subscription.find(
        Subscription.user_id == str(user.id),
        Subscription.is_active == True
    ).to_list()
    
    subscribers = []
    for sub in subscriptions:
        relative = await User.get(sub.relative_id)
        if relative:
            subscribers.append({
                "id": str(relative.id),
                "name": relative.name,
                "email": relative.email
            })
    
    return {"subscribers": subscribers}


@router.put("/{subscription_id}")
async def update_subscription(
    subscription_id: str,
    request: UpdateSubscriptionRequest,
    user: User = Depends(get_current_user)
):
    """Update a subscription."""
    
    subscription = await Subscription.get(subscription_id)
    
    if not subscription:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subscription not found"
        )
    
    # Check access
    if subscription.relative_id != str(user.id) and user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    if request.alert_types:
        subscription.alert_types = [
            SubscriptionAlertType(at) for at in request.alert_types
        ]
    
    if request.is_active is not None:
        subscription.is_active = request.is_active
    
    await subscription.save()
    
    return {
        "message": "Subscription updated",
        "subscription": {
            "id": str(subscription.id),
            "alert_types": [at.value for at in subscription.alert_types],
            "is_active": subscription.is_active
        }
    }


@router.delete("/{subscription_id}")
async def unsubscribe(
    subscription_id: str,
    user: User = Depends(get_current_user)
):
    """Unsubscribe from a user's alerts."""
    
    subscription = await Subscription.get(subscription_id)
    
    if not subscription:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subscription not found"
        )
    
    # Check access
    if subscription.relative_id != str(user.id) and user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    await subscription.delete()
    
    return {"message": "Unsubscribed successfully"}
