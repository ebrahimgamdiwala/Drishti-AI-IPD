"""
Drishti AI - Model Router

Image analysis and face recognition endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional, List
import os
import base64
from datetime import datetime
import uuid

from app.models.user import User
from app.models.alert import Alert, AlertType, AlertSeverity, DetectedObject
from app.models.subscription import Subscription
from app.models.known_person import KnownPerson
from app.middleware.auth import get_current_user
from app.services.ollama_service import analyze_image, check_ollama_health
from app.services.alert_detector import analyze_for_alerts, extract_objects
from app.services.email_service import send_alert_email
from app.services.face_service import identify_face, extract_embedding_from_base64
from app.config import get_settings


router = APIRouter(prefix="/api/model", tags=["Model"])


class AnalyzeRequest(BaseModel):
    """Request schema for image analysis."""
    image: str  # Base64 encoded image
    prompt: str
    session_id: Optional[str] = None
    image_mime: Optional[str] = "image/jpeg"


class IdentifyRequest(BaseModel):
    """Request schema for face identification."""
    image: str  # Base64 encoded image


@router.post("/analyze")
async def analyze(
    request: AnalyzeRequest,
    user: User = Depends(get_current_user)
):
    """Analyze an image using the vision language model."""
    
    if not request.image or not request.prompt:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image and prompt are required"
        )
    
    # Normalize base64 image
    image_base64 = request.image
    if image_base64.startswith("data:"):
        parts = image_base64.split(",", 1)
        if len(parts) == 2:
            image_base64 = parts[1]
    
    # Validate base64 length
    if len(image_base64) < 20:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image data"
        )
    
    # Save image to uploads directory
    saved_image_url = None
    settings = get_settings()
    
    try:
        uploads_dir = os.path.join(os.path.dirname(__file__), "..", "..", "uploads")
        os.makedirs(uploads_dir, exist_ok=True)
        
        # Generate filename
        ext = request.image_mime.split("/")[1] if request.image_mime else "jpg"
        filename = f"capture-{datetime.now().strftime('%Y%m%d%H%M%S')}-{uuid.uuid4().hex[:8]}.{ext}"
        filepath = os.path.join(uploads_dir, filename)
        
        # Decode and save
        image_bytes = base64.b64decode(image_base64)
        with open(filepath, "wb") as f:
            f.write(image_bytes)
        
        saved_image_url = f"/uploads/{filename}"
    except Exception as e:
        print(f"Failed to save image: {e}")
    
    # Analyze with Ollama
    result = await analyze_image(image_base64, request.prompt)
    
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=result.get("error", "AI analysis failed")
        )
    
    # Analyze for alerts
    alert_analysis = analyze_for_alerts(result["response"])
    detected_objects = extract_objects(result["response"])
    
    alert_id = None
    
    # Create alert if needed
    if alert_analysis["detected"] and alert_analysis["severity"] != "low":
        alert = Alert(
            user_id=str(user.id),
            type=AlertType(alert_analysis["type"]),
            severity=AlertSeverity(alert_analysis["severity"]),
            description=result["response"],
            model_response=result["response"],
            image_ref=saved_image_url,
            detected_objects=[DetectedObject(**obj) for obj in detected_objects]
        )
        await alert.insert()
        alert_id = str(alert.id)
        
        # Send email alerts if needed
        if alert_analysis.get("email_alert"):
            # Find subscribers
            subscriptions = await Subscription.find(
                Subscription.user_id == str(user.id),
                Subscription.is_active == True
            ).to_list()
            
            for sub in subscriptions:
                # Check if subscriber wants this alert type
                alert_types = [at.value for at in sub.alert_types]
                if "all" in alert_types or alert_analysis["type"] in alert_types:
                    relative = await User.get(sub.relative_id)
                    if relative and relative.email:
                        email_result = await send_alert_email(
                            relative.email,
                            relative.name,
                            alert,
                            user.name
                        )
                        if email_result.get("success"):
                            from app.models.alert import EmailSent
                            alert.emails_sent.append(EmailSent(
                                recipient_email=relative.email,
                                status="sent"
                            ))
            
            await alert.save()
    
    return {
        "success": True,
        "response": result["response"],
        "model": result["model"],
        "savedImageUrl": saved_image_url,
        "sessionId": request.session_id,
        "alert": {
            "detected": alert_analysis["detected"],
            "severity": alert_analysis["severity"],
            "type": alert_analysis["type"],
            "keywords": alert_analysis["keywords"],
            "alertId": alert_id
        },
        "detectedObjects": detected_objects
    }


@router.get("/health")
async def health():
    """Check Ollama health status."""
    health_status = await check_ollama_health()
    return health_status


@router.post("/identify")
async def identify(
    request: IdentifyRequest,
    user: User = Depends(get_current_user)
):
    """Identify a face against known persons."""
    
    if not request.image:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image is required"
        )
    
    # Get known persons for this user
    known_persons = await KnownPerson.find(
        KnownPerson.for_user == str(user.id)
    ).to_list()
    
    # Convert to dict format for face service
    known_persons_data = [
        {
            "id": str(kp.id),
            "name": kp.name,
            "relationship": kp.relationship,
            "face_embeddings": kp.face_embeddings
        }
        for kp in known_persons if kp.face_embeddings
    ]
    
    if not known_persons_data:
        return {
            "success": True,
            "identified": False,
            "message": "No known persons with face data found",
            "confidence": 0,
            "person": None
        }
    
    # Identify face
    result = await identify_face(request.image, known_persons_data)
    
    return {
        "success": True,
        **result
    }
