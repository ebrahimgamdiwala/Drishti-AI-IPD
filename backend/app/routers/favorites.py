"""
Drishti AI - Favorites Router

Manage favorite known persons for quick access.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.models.user import User
from app.models.known_person import KnownPerson
from app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/favorites", tags=["Favorites"])


@router.get("")
async def get_favorites(user: User = Depends(get_current_user)):
    """Get user's favorite known persons."""
    
    # Get user's favorites list (stored as IDs)
    favorite_ids = getattr(user, 'favorite_persons', [])
    
    if not favorite_ids:
        return {"favorites": []}
    
    # Fetch the actual known persons
    favorites = []
    for person_id in favorite_ids:
        person = await KnownPerson.get(person_id)
        if person and person.for_user == str(user.id):
            favorites.append({
                "id": str(person.id),
                "name": person.name,
                "relationship": person.relationship,
                "images": [img.model_dump() for img in person.images],
                "has_face_embeddings": len(person.face_embeddings) > 0
            })
    
    return {"favorites": favorites}


@router.post("/{person_id}")
async def add_to_favorites(
    person_id: str,
    user: User = Depends(get_current_user)
):
    """Add a known person to favorites."""
    
    # Verify the person exists and belongs to the user
    person = await KnownPerson.get(person_id)
    
    if not person:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Person not found"
        )
    
    if person.for_user != str(user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    # Initialize favorites list if it doesn't exist
    if not hasattr(user, 'favorite_persons'):
        user.favorite_persons = []
    
    # Add to favorites if not already there
    if person_id not in user.favorite_persons:
        user.favorite_persons.append(person_id)
        await user.save()
    
    return {"message": "Added to favorites", "person_id": person_id}


@router.delete("/{person_id}")
async def remove_from_favorites(
    person_id: str,
    user: User = Depends(get_current_user)
):
    """Remove a known person from favorites."""
    
    if not hasattr(user, 'favorite_persons'):
        user.favorite_persons = []
    
    if person_id in user.favorite_persons:
        user.favorite_persons.remove(person_id)
        await user.save()
    
    return {"message": "Removed from favorites", "person_id": person_id}
