"""
Drishti AI - FastAPI Application Entry Point

Main application configuration with route registration, CORS, and lifecycle events.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from datetime import datetime

from app.config import get_settings
from app.database import init_db, close_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup and shutdown events."""
    # Startup
    print("🚀 Starting Drishti AI FastAPI Server...")
    await init_db()
    
    # Create uploads directory
    uploads_dir = os.path.join(os.path.dirname(__file__), "..", "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    
    yield
    
    # Shutdown
    print("🛑 Shutting down Drishti AI Server...")
    await close_db()


# Create FastAPI app
app = FastAPI(
    title="Drishti AI",
    description="Vision Assistant Backend API with Face Recognition and VLM Integration",
    version="1.0.0",
    lifespan=lifespan
)

# Get settings
settings = get_settings()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        settings.frontend_url,
        "http://localhost:5173",
        "http://localhost:3000",
        "*"  # Allow all for mobile app development
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files for uploads
uploads_path = os.path.join(os.path.dirname(__file__), "..", "uploads")
if not os.path.exists(uploads_path):
    os.makedirs(uploads_path)
app.mount("/uploads", StaticFiles(directory=uploads_path), name="uploads")


# Import and register routers
from app.routers import (
    auth, 
    users, 
    model, 
    relatives, 
    favorites, 
    content,
    emergency_contacts,
    connected_users
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(model.router)
app.include_router(relatives.router)
app.include_router(favorites.router)
app.include_router(content.router)
app.include_router(emergency_contacts.router)
app.include_router(connected_users.router)


# Health check endpoint
@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "ollama": settings.ollama_url
    }


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API info."""
    return {
        "name": "Drishti AI API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
        "health": "/api/health"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.port,
        reload=settings.debug
    )
