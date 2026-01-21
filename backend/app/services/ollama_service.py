"""
Drishti AI - Ollama Service

Vision Language Model integration via Ollama API.
"""

import httpx
from typing import Optional
from app.config import get_settings


async def analyze_image(image_base64: str, prompt: str) -> dict:
    """
    Analyze an image using Ollama vision model.
    
    Args:
        image_base64: Base64 encoded image (without data URL prefix)
        prompt: Text prompt for the model
        
    Returns:
        dict with success, response, model, and optional error
    """
    settings = get_settings()
    
    if not image_base64:
        return {"success": False, "error": "No image data provided"}
    
    # Strip data URL prefix if present
    if image_base64.startswith("data:"):
        # Extract base64 portion after the comma
        parts = image_base64.split(",", 1)
        if len(parts) == 2:
            image_base64 = parts[1]
    
    # Basic sanity check
    size_kb = len(image_base64) * 3 // 4 // 1024
    if size_kb > 10000:  # > 10MB
        print(f"Warning: Large image payload (~{size_kb} KB)")
    
    try:
        payload = {
            "model": settings.ollama_model,
            "prompt": prompt,
            "images": [image_base64],
            "stream": False
        }
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{settings.ollama_url}/api/generate",
                json=payload,
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                }
            )
            
            if response.status_code != 200:
                return {
                    "success": False,
                    "error": f"Ollama returned status {response.status_code}"
                }
            
            data = response.json()
            
            return {
                "success": True,
                "response": data.get("response", ""),
                "model": settings.ollama_model,
                "context": data.get("context")
            }
            
    except httpx.ConnectError:
        return {
            "success": False,
            "error": f"Cannot connect to Ollama. Make sure Ollama is running on {settings.ollama_url}"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


async def check_ollama_health() -> dict:
    """
    Check if Ollama is available and has the required model.
    
    Returns:
        dict with available, models, and hasRequiredModel
    """
    settings = get_settings()
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.ollama_url}/api/tags")
            
            if response.status_code != 200:
                return {"available": False, "error": "Ollama not responding"}
            
            data = response.json()
            models = [m.get("name", "") for m in data.get("models", [])]
            
            has_model = any(settings.ollama_model in m for m in models)
            
            return {
                "available": True,
                "models": models,
                "hasRequiredModel": has_model
            }
            
    except Exception as e:
        return {
            "available": False,
            "error": str(e)
        }


def detect_threat(model_response: str) -> dict:
    """
    Detect potential threats and hazards in the model response.
    
    Args:
        model_response: Text response from the vision model
        
    Returns:
        dict with severity, type, detected, and keywords
    """
    response = model_response.lower()
    
    # Critical threats
    critical_keywords = [
        "danger", "hazard", "collision", "emergency", "fire",
        "falling", "cliff", "edge", "vehicle approaching",
        "life threat", "immediate danger"
    ]
    
    # Warning level
    warning_keywords = [
        "obstacle", "close", "near", "blocked", "stairs",
        "uneven", "wet floor", "construction", "caution",
        "watch out", "be careful"
    ]
    
    # Check for critical threats
    for keyword in critical_keywords:
        if keyword in response:
            return {
                "severity": "critical",
                "type": "life-threat",
                "detected": True,
                "keywords": [keyword]
            }
    
    # Check for warnings
    for keyword in warning_keywords:
        if keyword in response:
            return {
                "severity": "high",
                "type": "close-call",
                "detected": True,
                "keywords": [keyword]
            }
    
    return {
        "severity": "low",
        "type": "info",
        "detected": False,
        "keywords": []
    }
