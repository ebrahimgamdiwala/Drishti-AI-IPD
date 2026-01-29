"""
Drishti AI - Emergency Contacts Router

Manage emergency contacts for user safety.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from pydantic import BaseModel, EmailStr
from app.models.user import User, EmergencyContact
from app.middleware.auth import get_current_user


router = APIRouter(prefix="/api/emergency-contacts", tags=["Emergency Contacts"])


class EmergencyContactCreate(BaseModel):
    """Schema for creating emergency contact."""
    name: str
    phone: str
    email: Optional[EmailStr] = None
    relationship: Optional[str] = None


class EmergencyContactUpdate(BaseModel):
    """Schema for updating emergency contact."""
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    relationship: Optional[str] = None


@router.get("")
async def get_emergency_contacts(user: User = Depends(get_current_user)):
    """Get all emergency contacts for the current user."""
    
    contacts = user.emergency_contacts or []
    
    return {
        "contacts": [contact.model_dump() for contact in contacts],
        "count": len(contacts)
    }


@router.post("")
async def add_emergency_contact(
    contact: EmergencyContactCreate,
    user: User = Depends(get_current_user)
):
    """Add a new emergency contact."""
    
    # Initialize emergency_contacts if it doesn't exist
    if not user.emergency_contacts:
        user.emergency_contacts = []
    
    # Check if contact already exists (by phone)
    for existing in user.emergency_contacts:
        if existing.phone == contact.phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Contact with this phone number already exists"
            )
    
    # Create new emergency contact
    new_contact = EmergencyContact(
        name=contact.name,
        phone=contact.phone,
        email=contact.email,
        relationship=contact.relationship
    )
    
    user.emergency_contacts.append(new_contact)
    await user.save()
    
    return {
        "message": "Emergency contact added successfully",
        "contact": new_contact.model_dump()
    }


@router.put("/{contact_index}")
async def update_emergency_contact(
    contact_index: int,
    contact_update: EmergencyContactUpdate,
    user: User = Depends(get_current_user)
):
    """Update an emergency contact by index."""
    
    if not user.emergency_contacts or contact_index >= len(user.emergency_contacts):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found"
        )
    
    # Update fields if provided
    existing_contact = user.emergency_contacts[contact_index]
    
    if contact_update.name is not None:
        existing_contact.name = contact_update.name
    if contact_update.phone is not None:
        existing_contact.phone = contact_update.phone
    if contact_update.email is not None:
        existing_contact.email = contact_update.email
    if contact_update.relationship is not None:
        existing_contact.relationship = contact_update.relationship
    
    await user.save()
    
    return {
        "message": "Emergency contact updated successfully",
        "contact": existing_contact.model_dump()
    }


@router.delete("/{contact_index}")
async def delete_emergency_contact(
    contact_index: int,
    user: User = Depends(get_current_user)
):
    """Delete an emergency contact by index."""
    
    if not user.emergency_contacts or contact_index >= len(user.emergency_contacts):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found"
        )
    
    deleted_contact = user.emergency_contacts.pop(contact_index)
    await user.save()
    
    return {
        "message": "Emergency contact deleted successfully",
        "contact": deleted_contact.model_dump()
    }


@router.post("/call/{contact_index}")
async def initiate_emergency_call(
    contact_index: int,
    user: User = Depends(get_current_user)
):
    """
    Initiate an emergency call (returns contact info for the app to handle).
    The actual calling is handled by the mobile app.
    """
    
    if not user.emergency_contacts or contact_index >= len(user.emergency_contacts):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found"
        )
    
    contact = user.emergency_contacts[contact_index]
    
    # In a real app, you might log this emergency call or send notifications
    # For now, just return the contact info
    
    return {
        "message": "Emergency call initiated",
        "contact": contact.model_dump(),
        "action": "call",
        "phone": contact.phone
    }


@router.post("/alert")
async def send_emergency_alert(
    user: User = Depends(get_current_user)
):
    """
    Send emergency alert to all emergency contacts.
    Returns list of contacts to notify (app handles actual notification).
    """
    
    if not user.emergency_contacts:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No emergency contacts configured"
        )
    
    # In a real app, you would:
    # 1. Send SMS/email to contacts
    # 2. Share user's location
    # 3. Log the emergency event
    
    return {
        "message": "Emergency alert sent to all contacts",
        "contacts": [contact.model_dump() for contact in user.emergency_contacts],
        "timestamp": user.last_active.isoformat() if user.last_active else None
    }
