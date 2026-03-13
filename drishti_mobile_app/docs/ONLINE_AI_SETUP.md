# Online Vision Setup

Online vision is now backend-managed.

- The Flutter app no longer sends Gemini keys or model names through local PowerShell scripts.
- The FastAPI backend owns Gemini configuration and sends all cloud vision requests.
- The mobile app calls the existing backend model route and still falls back to the on-device VLM when backend vision fails or the phone loses internet.

## Backend environment variables

Set these on the FastAPI backend in `backend/.env`:

```env
GEMINI_API_KEY=your_real_key_here
GEMINI_MODEL=gemini-2.5-flash
GEMINI_FALLBACK_MODEL=gemini-flash-latest
```

Optional backend fallback remains available through Ollama:

```env
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llava:7b
```

## How requests flow now

1. The app sends image + prompt to `POST /api/model/analyze`.
2. FastAPI calls Gemini using the backend-held API key.
3. If Gemini fails, FastAPI can fall back to Ollama.
4. If the phone cannot reach the backend cloud path, the app falls back to the local on-device VLM when available.

## Mobile app run flow

Run the app normally. No Gemini PowerShell bootstrap script is required.

```powershell
cd e:\IPD\drishti_mobile_app
flutter run -d DN2101
```

## Notes

- Google Cloud STT in the mobile app is still a separate path and was not moved in this change.
- Local VLM and Sherpa offline models remain unchanged.