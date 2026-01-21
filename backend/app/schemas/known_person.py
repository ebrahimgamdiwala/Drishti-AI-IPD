"""
Drishti AI - Known Person Schemas

Pydantic schemas for known person requests/responses.
"""

from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class PersonImageSchema(BaseModel):
    """Schema for person image."""
    filename: str
    path: str
    uploaded_at: Optional[datetime] = None


class CreateKnownPersonRequest(BaseModel):
    """Request schema for creating a known person."""
    name: str
    relationship: str
    for_user_id: str
    notes: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None


class UpdateKnownPersonRequest(BaseModel):
    """Request schema for updating a known person."""
    name: Optional[str] = None
    relationship: Optional[str] = None
    notes: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None


class KnownPersonResponse(BaseModel):
    """Response schema for a known person."""
    id: str
    name: str
    relationship: str
    added_by: str
    for_user: str
    images: List[PersonImageSchema] = []
    has_face_embeddings: bool = False
    notes: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    created_at: datetime
    updated_at: datetime
