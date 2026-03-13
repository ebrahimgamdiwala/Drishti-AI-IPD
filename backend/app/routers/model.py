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
from app.middleware.auth import get_current_user, get_current_user_optional
from app.services.ollama_service import analyze_image, check_ollama_health
from app.services.gemini_service import analyze_image_with_gemini, check_gemini_health
from app.services.alert_detector import analyze_for_alerts, extract_objects
from app.services.email_service import send_alert_email
from app.services.face_service import identify_face, extract_embedding_from_base64
from app.config import get_settings
from app.database import is_database_available


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
    user: Optional[User] = Depends(get_current_user_optional)
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
    
    # Analyze with backend-managed cloud vision first, then backend Ollama fallback.
    result = None
    if settings.gemini_api_key:
        result = await analyze_image_with_gemini(
            image_base64=image_base64,
            prompt=request.prompt,
            image_mime=request.image_mime or "image/jpeg",
        )

    if not result or not result.get("success"):
        ollama_result = await analyze_image(image_base64, request.prompt)
        if ollama_result.get("success"):
            ollama_result["engine"] = "ollama"
            ollama_result["description"] = ollama_result.get("response", "")
            ollama_result["objects"] = []
            ollama_result["prompt_tokens"] = 0
            ollama_result["completion_tokens"] = 0
            ollama_result["inference_ms"] = 0
            result = ollama_result
        elif result and result.get("error"):
            result = {
                "success": False,
                "error": f"Cloud vision failed: {result['error']}. Local backend fallback failed: {ollama_result.get('error', 'unknown error')}"
            }
        else:
            result = ollama_result
    
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=result.get("error", "AI analysis failed")
        )
    
    # Analyze for alerts
    alert_analysis = analyze_for_alerts(result["response"])
    detected_objects = result.get("objects") or extract_objects(result["response"])
    
    alert_id = None
    
    can_use_db = is_database_available() and user is not None

    # Create alert if needed and DB/auth are available
    if can_use_db and alert_analysis["detected"] and alert_analysis["severity"] != "low":
        alert = Alert(
            user_id=str(user.id),
            type=AlertType(alert_analysis["type"]),
            severity=AlertSeverity(alert_analysis["severity"]),
            description=result["response"],
            model_response=result["response"],
            image_ref=saved_image_url,
            detected_objects=[
                DetectedObject(
                    object=obj.get("label") or obj.get("object") or "unknown",
                    confidence=float(obj.get("confidence", 0.0) or 0.0),
                    distance=obj.get("distance") or "unknown",
                )
                for obj in detected_objects
            ]
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
        "description": result.get("description", result["response"]),
        "model": result["model"],
        "engine": result.get("engine", "ollama"),
        "promptTokens": result.get("prompt_tokens", 0),
        "completionTokens": result.get("completion_tokens", 0),
        "inferenceTimeMs": result.get("inference_ms", 0),
        "savedImageUrl": saved_image_url,
        "sessionId": request.session_id,
        "alert": {
            "detected": alert_analysis["detected"],
            "severity": alert_analysis["severity"],
            "type": alert_analysis["type"],
            "keywords": alert_analysis["keywords"],
            "alertId": alert_id
        },
        "dbAvailable": can_use_db,
        "detectedObjects": detected_objects
    }


@router.get("/health")
async def health():
    """Check backend vision engine health status."""
    settings = get_settings()
    return {
        "preferred": "gemini" if settings.gemini_api_key else "ollama",
        "gemini": await check_gemini_health(),
        "ollama": await check_ollama_health(),
    }


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
