"""
Drishti AI - Admin Router

Admin-only endpoints for user and system management.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List

from app.models.user import User, UserRole
from app.models.alert import Alert
from app.models.known_person import KnownPerson
from app.models.audit_log import AuditLog
from app.middleware.auth import get_admin_user


router = APIRouter(prefix="/api/admin", tags=["Admin"])


@router.get("/users")
async def list_users(
    role: Optional[str] = None,
    limit: int = Query(100, ge=1, le=500),
    page: int = Query(1, ge=1),
    admin: User = Depends(get_admin_user)
):
    """List all users (admin only)."""
    
    skip = (page - 1) * limit
    
    if role:
        query = {"role": role}
    else:
        query = {}
    
    users = await User.find(query).sort(-User.created_at).skip(skip).limit(limit).to_list()
    total = await User.find(query).count()
    
    return {
        "users": [u.to_safe_dict() for u in users],
        "pagination": {
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit
        }
    }


@router.get("/users/{user_id}")
async def get_user(
    user_id: str,
    admin: User = Depends(get_admin_user)
):
    """Get user details (admin only)."""
    
    user = await User.get(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {"user": user.to_safe_dict()}


@router.put("/users/{user_id}/role")
async def update_user_role(
    user_id: str,
    role: str,
    admin: User = Depends(get_admin_user)
):
    """Update user role (admin only)."""
    
    if role not in [r.value for r in UserRole]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid role"
        )
    
    user = await User.get(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    old_role = user.role.value
    user.role = UserRole(role)
    await user.save()
    
    # Create audit log
    await AuditLog(
        user_id=str(admin.id),
        action="update_user_role",
        resource="user",
        details={
            "target_user_id": str(user.id),
            "old_role": old_role,
            "new_role": role
        }
    ).insert()
    
    return {
        "message": "Role updated successfully",
        "user": user.to_safe_dict()
    }


@router.delete("/users/{user_id}")
async def delete_user(
    user_id: str,
    admin: User = Depends(get_admin_user)
):
    """Delete a user (admin only)."""
    
    user = await User.get(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if str(user.id) == str(admin.id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    user_email = user.email
    await user.delete()
    
    # Create audit log
    await AuditLog(
        user_id=str(admin.id),
        action="delete_user",
        resource="user",
        details={
            "deleted_user_id": user_id,
            "deleted_user_email": user_email
        }
    ).insert()
    
    return {"message": "User deleted successfully"}


@router.get("/alerts")
async def list_alerts_admin(
    severity: Optional[str] = None,
    acknowledged: Optional[bool] = None,
    limit: int = Query(100, ge=1, le=500),
    page: int = Query(1, ge=1),
    admin: User = Depends(get_admin_user)
):
    """List all alerts (admin only)."""
    
    skip = (page - 1) * limit
    query = {}
    
    if severity:
        query["severity"] = severity
    if acknowledged is not None:
        query["acknowledged"] = acknowledged
    
    alerts = await Alert.find(query).sort(-Alert.created_at).skip(skip).limit(limit).to_list()
    total = await Alert.find(query).count()
    
    # Populate user info
    alerts_with_users = []
    for alert in alerts:
        alert_dict = {
            "id": str(alert.id),
            "user_id": alert.user_id,
            "type": alert.type.value,
            "severity": alert.severity.value,
            "description": alert.description,
            "acknowledged": alert.acknowledged,
            "created_at": alert.created_at.isoformat()
        }
        
        # Get user info
        user = await User.get(alert.user_id)
        if user:
            alert_dict["user"] = {
                "name": user.name,
                "email": user.email
            }
        
        alerts_with_users.append(alert_dict)
    
    return {
        "alerts": alerts_with_users,
        "pagination": {
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit
        }
    }


@router.get("/stats")
async def get_stats(admin: User = Depends(get_admin_user)):
    """Get system statistics (admin only)."""
    
    # User stats
    user_count = await User.find().count()
    users_by_role = {}
    for role in UserRole:
        count = await User.find(User.role == role).count()
        if count > 0:
            users_by_role[role.value] = count
    
    # Alert stats
    alert_count = await Alert.find().count()
    unacknowledged = await Alert.find(Alert.acknowledged == False).count()
    critical_alerts = await Alert.find(
        Alert.severity == "critical",
        Alert.acknowledged == False
    ).count()
    
    # Known persons count
    known_person_count = await KnownPerson.find().count()
    
    # Recent alerts
    recent_alerts = await Alert.find().sort(-Alert.created_at).limit(5).to_list()
    recent_activity = []
    for alert in recent_alerts:
        activity = {
            "id": str(alert.id),
            "type": alert.type.value,
            "severity": alert.severity.value,
            "created_at": alert.created_at.isoformat()
        }
        user = await User.get(alert.user_id)
        if user:
            activity["user"] = {"name": user.name, "email": user.email}
        recent_activity.append(activity)
    
    return {
        "users": {
            "total": user_count,
            "byRole": users_by_role
        },
        "alerts": {
            "total": alert_count,
            "unacknowledged": unacknowledged,
            "critical": critical_alerts
        },
        "knownPersons": known_person_count,
        "recentActivity": recent_activity
    }


@router.get("/audit-logs")
async def get_audit_logs(
    limit: int = Query(50, ge=1, le=200),
    page: int = Query(1, ge=1),
    admin: User = Depends(get_admin_user)
):
    """Get audit logs (admin only)."""
    
    skip = (page - 1) * limit
    
    logs = await AuditLog.find().sort(-AuditLog.timestamp).skip(skip).limit(limit).to_list()
    total = await AuditLog.find().count()
    
    # Populate user info
    logs_with_users = []
    for log in logs:
        log_dict = {
            "id": str(log.id),
            "user_id": log.user_id,
            "action": log.action,
            "resource": log.resource,
            "details": log.details,
            "timestamp": log.timestamp.isoformat()
        }
        
        if log.user_id:
            user = await User.get(log.user_id)
            if user:
                log_dict["user"] = {"name": user.name, "email": user.email}
        
        logs_with_users.append(log_dict)
    
    return {
        "logs": logs_with_users,
        "pagination": {
            "total": total,
            "page": page,
            "limit": limit,
            "pages": (total + limit - 1) // limit
        }
    }
