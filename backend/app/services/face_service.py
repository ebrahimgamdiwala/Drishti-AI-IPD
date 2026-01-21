"""
Drishti AI - Face Recognition Service

Face detection and recognition using InsightFace.
"""

import numpy as np
from typing import Optional, List, Tuple
import cv2
import base64
from io import BytesIO

# Lazy load InsightFace to avoid startup delay
_face_app = None
_initialized = False


def _init_face_app():
    """Initialize InsightFace model (lazy loading)."""
    global _face_app, _initialized
    
    if _initialized:
        return _face_app
    
    try:
        from insightface.app import FaceAnalysis
        
        # Initialize with buffalo_l model (good balance of speed and accuracy)
        _face_app = FaceAnalysis(name="buffalo_l", providers=["CPUExecutionProvider"])
        _face_app.prepare(ctx_id=0, det_size=(640, 640))
        
        _initialized = True
        print("✅ InsightFace initialized successfully")
        return _face_app
        
    except Exception as e:
        print(f"⚠️ Failed to initialize InsightFace: {e}")
        _initialized = True  # Mark as attempted
        return None


def decode_base64_image(image_base64: str) -> Optional[np.ndarray]:
    """
    Decode a base64 image to numpy array.
    
    Args:
        image_base64: Base64 encoded image (with or without data URL prefix)
        
    Returns:
        numpy array (BGR format) or None if failed
    """
    try:
        # Strip data URL prefix if present
        if image_base64.startswith("data:"):
            parts = image_base64.split(",", 1)
            if len(parts) == 2:
                image_base64 = parts[1]
        
        # Decode base64
        image_data = base64.b64decode(image_base64)
        
        # Convert to numpy array
        nparr = np.frombuffer(image_data, np.uint8)
        
        # Decode image
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        return image
        
    except Exception as e:
        print(f"Failed to decode image: {e}")
        return None


def extract_face_embedding(image: np.ndarray) -> Optional[List[float]]:
    """
    Extract face embedding from an image.
    
    Args:
        image: numpy array (BGR format)
        
    Returns:
        512-dimensional embedding as list of floats, or None if no face found
    """
    app = _init_face_app()
    
    if app is None:
        return None
    
    try:
        # Detect faces
        faces = app.get(image)
        
        if not faces:
            return None
        
        # Get the largest face (most likely the main subject)
        largest_face = max(faces, key=lambda f: (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1]))
        
        # Return embedding as list
        return largest_face.embedding.tolist()
        
    except Exception as e:
        print(f"Failed to extract embedding: {e}")
        return None


def extract_all_face_embeddings(image: np.ndarray) -> List[List[float]]:
    """
    Extract all face embeddings from an image.
    
    Args:
        image: numpy array (BGR format)
        
    Returns:
        List of 512-dimensional embeddings
    """
    app = _init_face_app()
    
    if app is None:
        return []
    
    try:
        faces = app.get(image)
        return [face.embedding.tolist() for face in faces]
        
    except Exception as e:
        print(f"Failed to extract embeddings: {e}")
        return []


def cosine_similarity(embedding1: List[float], embedding2: List[float]) -> float:
    """
    Calculate cosine similarity between two embeddings.
    
    Args:
        embedding1: First embedding
        embedding2: Second embedding
        
    Returns:
        Similarity score (0.0 to 1.0)
    """
    try:
        vec1 = np.array(embedding1)
        vec2 = np.array(embedding2)
        
        # Normalize vectors
        vec1_norm = vec1 / np.linalg.norm(vec1)
        vec2_norm = vec2 / np.linalg.norm(vec2)
        
        # Calculate cosine similarity
        similarity = np.dot(vec1_norm, vec2_norm)
        
        # Convert from [-1, 1] to [0, 1]
        return float((similarity + 1) / 2)
        
    except Exception as e:
        print(f"Failed to calculate similarity: {e}")
        return 0.0


async def identify_face(
    image_base64: str,
    known_persons: List[dict],
    threshold: float = 0.6
) -> dict:
    """
    Identify a face against known persons.
    
    Args:
        image_base64: Base64 encoded image
        known_persons: List of known persons with face_embeddings
        threshold: Minimum similarity threshold for a match
        
    Returns:
        dict with identified, person, confidence, and optional error
    """
    # Decode image
    image = decode_base64_image(image_base64)
    
    if image is None:
        return {
            "identified": False,
            "error": "Failed to decode image"
        }
    
    # Extract embedding from the query image
    query_embedding = extract_face_embedding(image)
    
    if query_embedding is None:
        return {
            "identified": False,
            "error": "No face detected in image"
        }
    
    # Find best match
    best_match = None
    best_confidence = 0.0
    
    for person in known_persons:
        embeddings = person.get("face_embeddings", [])
        
        for embedding in embeddings:
            similarity = cosine_similarity(query_embedding, embedding)
            
            if similarity > best_confidence:
                best_confidence = similarity
                best_match = person
    
    if best_match and best_confidence >= threshold:
        return {
            "identified": True,
            "person": {
                "id": str(best_match.get("id", "")),
                "name": best_match.get("name", "Unknown"),
                "relationship": best_match.get("relationship", "")
            },
            "confidence": best_confidence
        }
    
    return {
        "identified": False,
        "confidence": best_confidence,
        "message": "No matching face found"
    }


async def extract_embedding_from_base64(image_base64: str) -> Optional[List[float]]:
    """
    Extract face embedding from a base64 encoded image.
    
    Args:
        image_base64: Base64 encoded image
        
    Returns:
        512-dimensional embedding or None
    """
    image = decode_base64_image(image_base64)
    
    if image is None:
        return None
    
    return extract_face_embedding(image)
