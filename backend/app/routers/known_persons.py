"""
Drishti AI - Known Persons Router

Known person management with face recognition.
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from typing import Optional, List
import os
import uuid
from datetime import datetime
import base64

from app.schemas.known_person import (
    CreateKnownPersonRequest,
    UpdateKnownPersonRequest,
    KnownPersonResponse
)
from app.models.known_person import KnownPerson, PersonImage
from app.models.user import User, UserRole
from app.middleware.auth import get_current_user
from app.services.face_service import extract_embedding_from_base64


router = APIRouter(prefix="/api/known-persons", tags=["Known Persons"])


@router.get("")
async def list_known_persons(
    for_user_id: Optional[str] = None,
    user: User = Depends(get_current_user)
):
    """List known persons based on user role."""
    
    if user.role == UserRole.ADMIN:
        # Admin can see all, optionally filtered
        if for_user_id:
            query = {"for_user": for_user_id}
        else:
            query = {}
    elif user.role == UserRole.RELATIVE:
        # Relative can see those they added
        query = {"added_by": str(user.id)}
        if for_user_id:
            query["for_user"] = for_user_id
    else:
        # Regular user can see their own
        query = {"for_user": str(user.id)}
    
    known_persons = await KnownPerson.find(query).sort(-KnownPerson.created_at).to_list()
    
    return {
        "knownPersons": [
            {
                "id": str(kp.id),
                "name": kp.name,
                "relationship": kp.relationship,
                "added_by": kp.added_by,
                "for_user": kp.for_user,
                "images": [img.model_dump() for img in kp.images],
                "has_face_embeddings": len(kp.face_embeddings) > 0,
                "notes": kp.notes,
                "phone_number": kp.phone_number,
                "email": kp.email,
                "created_at": kp.created_at.isoformat(),
                "updated_at": kp.updated_at.isoformat()
            }
            for kp in known_persons
        ]
    }


@router.get("/{person_id}")
async def get_known_person(
    person_id: str,
    user: User = Depends(get_current_user)
):
    """Get a single known person."""
    
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Known person not found"
        )
    
    # Check access
    can_view = (
        user.role == UserRole.ADMIN or
        person.added_by == str(user.id) or
        person.for_user == str(user.id)
    )
    
    if not can_view:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    return {
        "knownPerson": {
            "id": str(person.id),
            "name": person.name,
            "relationship": person.relationship,
            "added_by": person.added_by,
            "for_user": person.for_user,
            "images": [img.model_dump() for img in person.images],
            "has_face_embeddings": len(person.face_embeddings) > 0,
            "notes": person.notes,
            "phone_number": person.phone_number,
            "email": person.email,
            "created_at": person.created_at.isoformat(),
            "updated_at": person.updated_at.isoformat()
        }
    }


@router.post("")
async def create_known_person(
    name: str = Form(...),
    relationship: str = Form(...),
    for_user_id: str = Form(...),
    notes: Optional[str] = Form(None),
    phone_number: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    files: List[UploadFile] = File(default=[]),
    user: User = Depends(get_current_user)
):
    """Create a new known person with optional images."""
    
    if not name or not relationship or not for_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Name, relationship, and forUserId are required"
        )
    
    # Save uploaded images
    images = []
    face_embeddings = []
    uploads_dir = os.path.join(os.path.dirname(__file__), "..", "..", "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    
    for file in files:
        # Generate filename
        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        filename = f"face-{uuid.uuid4().hex[:8]}.{ext}"
        filepath = os.path.join(uploads_dir, filename)
        
        # Read file content
        content = await file.read()
        
        # Save file
        with open(filepath, "wb") as f:
            f.write(content)
        
        images.append(PersonImage(
            filename=filename,
            path=f"/uploads/{filename}"
        ))
        
        # Extract face embedding
        image_base64 = base64.b64encode(content).decode("utf-8")
        embedding = await extract_embedding_from_base64(image_base64)
        if embedding:
            face_embeddings.append(embedding)
    
    # Create known person
    person = KnownPerson(
        name=name,
        relationship=relationship,
        added_by=str(user.id),
        for_user=for_user_id,
        images=images,
        face_embeddings=face_embeddings,
        notes=notes,
        phone_number=phone_number,
        email=email
    )
    
    await person.insert()
    
    return {
        "message": "Known person added successfully",
        "person": {
            "id": str(person.id),
            "name": person.name,
            "relationship": person.relationship,
            "has_face_embeddings": len(person.face_embeddings) > 0,
            "images_count": len(person.images)
        }
    }


@router.put("/{person_id}")
async def update_known_person(
    person_id: str,
    request: UpdateKnownPersonRequest,
    user: User = Depends(get_current_user)
):
    """Update a known person."""
    
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Known person not found"
        )
    
    # Check access
    can_edit = user.role == UserRole.ADMIN or person.added_by == str(user.id)
    if not can_edit:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    if request.name:
        person.name = request.name
    if request.relationship:
        person.relationship = request.relationship
    if request.notes is not None:
        person.notes = request.notes
    if request.phone_number is not None:
        person.phone_number = request.phone_number
    if request.email is not None:
        person.email = request.email
    
    person.updated_at = datetime.utcnow()
    await person.save()
    
    return {
        "message": "Known person updated successfully",
        "knownPerson": {
            "id": str(person.id),
            "name": person.name,
            "relationship": person.relationship
        }
    }


@router.post("/{person_id}/images")
async def add_images(
    person_id: str,
    files: List[UploadFile] = File(...),
    user: User = Depends(get_current_user)
):
    """Add images to a known person."""
    
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Known person not found"
        )
    
    # Check access
    can_edit = user.role == UserRole.ADMIN or person.added_by == str(user.id)
    if not can_edit:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    uploads_dir = os.path.join(os.path.dirname(__file__), "..", "..", "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    
    for file in files:
        # Generate filename
        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        filename = f"face-{uuid.uuid4().hex[:8]}.{ext}"
        filepath = os.path.join(uploads_dir, filename)
        
        # Read and save file
        content = await file.read()
        with open(filepath, "wb") as f:
            f.write(content)
        
        person.images.append(PersonImage(
            filename=filename,
            path=f"/uploads/{filename}"
        ))
        
        # Extract face embedding
        image_base64 = base64.b64encode(content).decode("utf-8")
        embedding = await extract_embedding_from_base64(image_base64)
        if embedding:
            person.face_embeddings.append(embedding)
    
    person.updated_at = datetime.utcnow()
    await person.save()
    
    return {
        "message": "Images added successfully",
        "knownPerson": {
            "id": str(person.id),
            "images_count": len(person.images),
            "has_face_embeddings": len(person.face_embeddings) > 0
        }
    }


@router.delete("/{person_id}")
async def delete_known_person(
    person_id: str,
    user: User = Depends(get_current_user)
):
    """Delete a known person."""
    
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Known person not found"
        )
    
    # Check access
    can_delete = user.role == UserRole.ADMIN or person.added_by == str(user.id)
    if not can_delete:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    await person.delete()
    
    return {"message": "Known person deleted successfully"}
