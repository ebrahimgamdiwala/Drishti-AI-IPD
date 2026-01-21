# Drishti AI - FastAPI Backend

A full-featured FastAPI backend for the Drishti Vision Assistant, with authentication, face recognition, and VLM integration.

## Quick Start

```powershell
# Create and activate virtual environment
python -m venv venv
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
copy .env.example .env
# Edit .env with your settings

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 5000
```

## API Documentation

Once running, visit `http://localhost:5000/docs` for Swagger UI.

## Features

- JWT Authentication + Google OAuth
- Face Recognition with InsightFace
- VLM Integration (Ollama)
- Alert Management
- Known Person Management
- Admin Dashboard APIs
