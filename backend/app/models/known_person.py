"""
Drishti AI - Known Person Model

MongoDB document model for known persons (face recognition).
"""

from beanie import Document, Indexed
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class PersonImage(BaseModel):
    """Image record embedded document."""
    filename: str
    path: str
    uploaded_at: datetime = Field(default_factory=datetime.utcnow)


class KnownPerson(Document):
    """Known person document model for face recognition."""
    
    # Basic info
    name: str
    relationship: str
    
    # User references
    added_by: Indexed(str)  # User ID who added this person (as string)
    for_user: Indexed(str)  # User ID this person is for (as string)
    
    # Images
    images: List[PersonImage] = Field(default_factory=list)
    
    # Face embeddings (512-dim vectors from InsightFace)
    # Each embedding is a list of 512 floats
    face_embeddings: List[List[float]] = Field(default_factory=list)
    
    # Additional info
    notes: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Settings:
        name = "known_persons"
        indexes = [
            [("for_user", 1), ("added_by", 1)]
        ]
    
    def save(self, *args, **kwargs):
        """Update timestamp on save."""
        self.updated_at = datetime.utcnow()
        return super().save(*args, **kwargs)
