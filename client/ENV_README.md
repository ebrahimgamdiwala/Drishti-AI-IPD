Frontend environment variables

This project uses Vite. Environment variables intended for client-side code must be prefixed with `VITE_`.

Files:
- `.env` — local overrides (not committed)
- `.env.example` — example values to copy

Useful variables:
- VITE_API_URL: full URL of backend API (e.g. http://localhost:5000). Leave empty to use relative paths (recommended with Vite proxy).
- VITE_FRONTEND_URL: frontend base URL used for CORS or links (e.g. http://localhost:5173)

Usage:
- After editing `.env`, restart the dev server so `import.meta.env` values are refreshed.
