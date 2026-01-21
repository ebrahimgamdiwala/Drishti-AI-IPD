"""
Drishti AI - Alerts Router

Alert management endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List
from datetime import datetime

from app.schemas.alert import CreateAlertRequest, AlertResponse, AlertStatsResponse
from app.models.alert import Alert, AlertType, AlertSeverity, DetectedObject, Location
from app.models.user import User, UserRole
from app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/alerts", tags=["Alerts"])


@router.get("")
async def list_alerts(
    limit: int = Query(50, ge=1, le=100),
    severity: Optional[str] = None,
    acknowledged: Optional[bool] = None,
    type: Optional[str] = None,
    user: User = Depends(get_current_user)
):
    """List user's alerts."""
    
    # Build query
    query = {"user_id": str(user.id)}
    
    if severity:
        query["severity"] = severity
    if acknowledged is not None:
        query["acknowledged"] = acknowledged
    if type:
        query["type"] = type
    
    alerts = await Alert.find(query).sort(-Alert.created_at).limit(limit).to_list()
    
    return {
        "alerts": [
            {
                "id": str(a.id),
                "user_id": a.user_id,
                "type": a.type.value,
                "severity": a.severity.value,
                "description": a.description,
                "image_ref": a.image_ref,
                "detected_objects": [obj.model_dump() for obj in a.detected_objects],
                "acknowledged": a.acknowledged,
                "created_at": a.created_at.isoformat()
            }
            for a in alerts
        ]
    }


@router.get("/stats")
async def get_stats(user: User = Depends(get_current_user)):
    """Get alert statistics for user."""
    
    user_id = str(user.id)
    
    # Count by severity
    total = await Alert.find(Alert.user_id == user_id).count()
    unacknowledged = await Alert.find(
        Alert.user_id == user_id,
        Alert.acknowledged == False
    ).count()
    
    # Get counts by severity
    by_severity = {}
    for severity in AlertSeverity:
        count = await Alert.find(
            Alert.user_id == user_id,
            Alert.severity == severity
        ).count()
        if count > 0:
            by_severity[severity.value] = count
    
    return AlertStatsResponse(
        total=total,
        unacknowledged=unacknowledged,
        by_severity=by_severity
    )


@router.get("/{alert_id}")
async def get_alert(
    alert_id: str,
    user: User = Depends(get_current_user)
):
    """Get a single alert."""
    
    alert = await Alert.get(alert_id)
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    # Check access
    if alert.user_id != str(user.id) and user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    return {
        "alert": {
            "id": str(alert.id),
            "user_id": alert.user_id,
            "type": alert.type.value,
            "severity": alert.severity.value,
            "description": alert.description,
            "image_ref": alert.image_ref,
            "model_response": alert.model_response,
            "detected_objects": [obj.model_dump() for obj in alert.detected_objects],
            "location": alert.location.model_dump() if alert.location else None,
            "acknowledged": alert.acknowledged,
            "acknowledged_by": alert.acknowledged_by,
            "acknowledged_at": alert.acknowledged_at.isoformat() if alert.acknowledged_at else None,
            "created_at": alert.created_at.isoformat()
        }
    }


@router.post("")
async def create_alert(
    request: CreateAlertRequest,
    user: User = Depends(get_current_user)
):
    """Create a new alert."""
    
    alert = Alert(
        user_id=str(user.id),
        type=AlertType(request.type) if request.type else AlertType.INFO,
        severity=AlertSeverity(request.severity) if request.severity else AlertSeverity.MEDIUM,
        description=request.description,
        image_ref=request.image_ref,
        detected_objects=[DetectedObject(**obj.model_dump()) for obj in (request.detected_objects or [])],
        location=Location(**request.location.model_dump()) if request.location else None
    )
    
    await alert.insert()
    
    return {
        "message": "Alert created successfully",
        "alert": {
            "id": str(alert.id),
            "type": alert.type.value,
            "severity": alert.severity.value,
            "description": alert.description,
            "created_at": alert.created_at.isoformat()
        }
    }


@router.put("/{alert_id}/acknowledge")
async def acknowledge_alert(
    alert_id: str,
    user: User = Depends(get_current_user)
):
    """Acknowledge an alert."""
    
    alert = await Alert.get(alert_id)
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    # Check access
    can_acknowledge = (
        alert.user_id == str(user.id) or
        user.role == UserRole.ADMIN or
        user.role == UserRole.RELATIVE
    )
    
    if not can_acknowledge:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    alert.acknowledged = True
    alert.acknowledged_by = str(user.id)
    alert.acknowledged_at = datetime.utcnow()
    await alert.save()
    
    return {
        "message": "Alert acknowledged",
        "alert": {
            "id": str(alert.id),
            "acknowledged": True,
            "acknowledged_at": alert.acknowledged_at.isoformat()
        }
    }


@router.delete("/{alert_id}")
async def delete_alert(
    alert_id: str,
    user: User = Depends(get_current_user)
):
    """Delete an alert."""
    
    alert = await Alert.get(alert_id)
    
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Alert not found"
        )
    
    # Only owner or admin can delete
    if alert.user_id != str(user.id) and user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    await alert.delete()
    
    return {"message": "Alert deleted successfully"}
