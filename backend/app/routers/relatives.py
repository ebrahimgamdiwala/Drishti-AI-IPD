from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from typing import List, Optional
from app.models.user import User
from app.models.known_person import KnownPerson, PersonImage
from app.middleware.auth import get_current_user
from app.services.face_service import extract_face_embedding, decode_base64_image
import base64
from datetime import datetime
from bson import ObjectId

router = APIRouter(prefix="/api/known-persons", tags=["Relatives"])

@router.post("")
async def create_relative(
    name: str = Form(...),
    relationship: str = Form(...),
    notes: Optional[str] = Form(None),
    phone_number: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new relative/known person with a face image.
    """
    # Read image content
    contents = await image.read()
    
    # Encode to base64 for storage/processing
    image_base64 = base64.b64encode(contents).decode("utf-8")
    
    # Decode for face analysis
    img_array = decode_base64_image(image_base64)
    
    if img_array is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format"
        )
        
    # Extract embedding
    embedding = extract_face_embedding(img_array)
    
    if embedding is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No face detected in the image. Please try another photo."
        )
        
    # Save image to disk
    import shutil
    import os
    import uuid
    
    # Create uploads directory if it doesn't exist
    uploads_dir = "uploads"
    os.makedirs(uploads_dir, exist_ok=True)
    
    # Generate unique filename
    file_extension = os.path.splitext(image.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(uploads_dir, unique_filename)
    
    # Save file
    with open(file_path, "wb") as buffer:
        buffer.write(contents)
        
    # Create person record
    person = KnownPerson(
        name=name,
        relationship=relationship,
        added_by=str(current_user.id),
        for_user=str(current_user.id),
        notes=notes,
        phone_number=phone_number,
        email=email,
        face_embeddings=[embedding],
        images=[
            PersonImage(
                filename=image.filename,
                path=f"/uploads/{unique_filename}",
                uploaded_at=datetime.utcnow()
            )
        ]
    )
    
    await person.save()
    
    # Return formatted response with explicit id
    return {
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

@router.get("")
async def get_relatives(current_user: User = Depends(get_current_user)):
    """
    Get all relatives for the current user.
    """
    persons = await KnownPerson.find(KnownPerson.for_user == str(current_user.id)).to_list()
    
    # Format response with explicit id field
    return [
        {
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
        for person in persons
    ]

@router.get("/{person_id}")
async def get_relative(person_id: str, current_user: User = Depends(get_current_user)):
    """
    Get a specific relative by ID.
    """
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(status_code=404, detail="Relative not found")
        
    if person.for_user != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to view this relative")
    
    return {
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

@router.put("/{person_id}")
async def update_relative(
    person_id: str,
    name: Optional[str] = Form(None),
    relationship: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    phone_number: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user)
):
    """
    Update relative details.
    """
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(status_code=404, detail="Relative not found")
        
    if person.for_user != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to edit this relative")
    
    if name:
        person.name = name
    if relationship:
        person.relationship = relationship
    if notes is not None:
        person.notes = notes
    if phone_number is not None:
        person.phone_number = phone_number
    if email is not None:
        person.email = email
        
    await person.save()
    
    return {
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

@router.delete("/{person_id}")
async def delete_relative(person_id: str, current_user: User = Depends(get_current_user)):
    """
    Delete a relative.
    """
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(status_code=404, detail="Relative not found")
        
    if person.for_user != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to delete this relative")
        
    await person.delete()
    return {"message": "Relative deleted successfully"}

@router.post("/{person_id}/photos")
async def add_relative_photo(
    person_id: str,
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Add another photo to an existing relative to improve recognition.
    """
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(status_code=404, detail="Relative not found")
        
    if person.for_user != str(current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to edit this relative")
        
    # Process image
    contents = await image.read()
    image_base64 = base64.b64encode(contents).decode("utf-8")
    img_array = decode_base64_image(image_base64)
    
    if img_array is None:
        raise HTTPException(status_code=400, detail="Invalid image format")
        
    embedding = extract_face_embedding(img_array)
    
    if embedding is None:
        raise HTTPException(status_code=400, detail="No face detected in image")
        
    # Save image to disk
    import shutil
    import os
    import uuid
    
    # Create uploads directory if it doesn't exist
    uploads_dir = "uploads"
    os.makedirs(uploads_dir, exist_ok=True)
    
    # Generate unique filename
    file_extension = os.path.splitext(image.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(uploads_dir, unique_filename)
    
    # Save file
    with open(file_path, "wb") as buffer:
        buffer.write(contents)
        
    # Add embedding and image record
    person.face_embeddings.append(embedding)
    person.images.append(
        PersonImage(
            filename=image.filename,
            path=f"/uploads/{unique_filename}",
            uploaded_at=datetime.utcnow()
        )
    )
    
    await person.save()
    
    return {
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
