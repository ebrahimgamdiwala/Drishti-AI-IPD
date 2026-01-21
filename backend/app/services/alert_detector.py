"""
Drishti AI - Alert Detector Service

Enhanced alert detection with configurable rules.
"""

from typing import List


# Alert detection rules
ALERT_RULES = {
    "critical": {
        "keywords": [
            "danger", "hazard", "collision", "emergency", "fire", "smoke",
            "falling", "cliff", "edge", "vehicle approaching", "car coming",
            "life threat", "immediate danger", "toxic", "electric"
        ],
        "severity": "critical",
        "type": "life-threat",
        "email_alert": True
    },
    "high": {
        "keywords": [
            "obstacle ahead", "close", "very near", "blocked path", "stairs ahead",
            "uneven ground", "construction zone", "caution required",
            "watch out", "be careful", "step down", "curb ahead",
            "person approaching", "bicycle"
        ],
        "severity": "high",
        "type": "close-call",
        "email_alert": True
    },
    "medium": {
        "keywords": [
            "door", "wall", "furniture", "slight obstacle", "narrow path",
            "crowded area", "noisy environment", "poor lighting"
        ],
        "severity": "medium",
        "type": "warning",
        "email_alert": False
    }
}

# Object detection patterns
OBJECT_PATTERNS = [
    {"name": "person", "patterns": ["person", "people", "human", "pedestrian"]},
    {"name": "vehicle", "patterns": ["car", "vehicle", "bicycle", "motorcycle", "truck", "bus"]},
    {"name": "obstacle", "patterns": ["obstacle", "barrier", "pole", "post", "sign"]},
    {"name": "furniture", "patterns": ["chair", "table", "desk", "shelf", "cabinet"]},
    {"name": "door", "patterns": ["door", "doorway", "entrance", "exit"]},
    {"name": "stairs", "patterns": ["stairs", "staircase", "steps"]},
    {"name": "wall", "patterns": ["wall"]},
    {"name": "floor_hazard", "patterns": ["wet floor", "uneven", "curb", "pothole"]}
]


def analyze_for_alerts(model_response: str) -> dict:
    """
    Analyze model response and detect alerts.
    
    Args:
        model_response: Text response from vision model
        
    Returns:
        dict with severity, type, detected, email_alert, and keywords
    """
    response = model_response.lower()
    detected_alerts = []
    
    # Check each rule category
    for level, rule in ALERT_RULES.items():
        matched_keywords = [
            keyword for keyword in rule["keywords"]
            if keyword.lower() in response
        ]
        
        if matched_keywords:
            detected_alerts.append({
                "level": level,
                "severity": rule["severity"],
                "type": rule["type"],
                "email_alert": rule["email_alert"],
                "matched_keywords": matched_keywords,
                "confidence": _calculate_confidence(len(matched_keywords), len(rule["keywords"]))
            })
    
    # Return highest severity alert
    if not detected_alerts:
        return {
            "severity": "low",
            "type": "info",
            "detected": False,
            "email_alert": False,
            "keywords": []
        }
    
    # Sort by severity (critical > high > medium)
    severity_order = {"critical": 0, "high": 1, "medium": 2}
    detected_alerts.sort(key=lambda a: severity_order.get(a["severity"], 3))
    
    best_alert = detected_alerts[0]
    return {
        "severity": best_alert["severity"],
        "type": best_alert["type"],
        "detected": True,
        "email_alert": best_alert["email_alert"],
        "keywords": best_alert["matched_keywords"],
        "confidence": best_alert["confidence"]
    }


def _calculate_confidence(matched: int, total: int) -> float:
    """Calculate confidence score based on matched keywords."""
    return min(0.5 + (matched / total) * 0.5, 1.0)


def extract_objects(model_response: str) -> List[dict]:
    """
    Extract detected objects from model response.
    
    Args:
        model_response: Text response from vision model
        
    Returns:
        List of detected objects with name, confidence, and distance
    """
    objects = []
    response = model_response.lower()
    
    import re
    
    for obj in OBJECT_PATTERNS:
        for pattern in obj["patterns"]:
            if pattern in response:
                # Try to extract distance
                distance_match = re.search(
                    rf"{pattern}.*?(\d+)\s*(meter|meters|feet|foot|m|ft)",
                    response,
                    re.IGNORECASE
                )
                
                distance = "unknown"
                if distance_match:
                    distance = f"{distance_match.group(1)} {distance_match.group(2)}"
                
                objects.append({
                    "object": obj["name"],
                    "confidence": 0.8,
                    "distance": distance
                })
                break  # Only add once per object type
    
    return objects
