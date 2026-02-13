@echo off
echo ========================================
echo Starting Drishti AI FastAPI Server
echo ========================================
echo.

REM Activate virtual environment if it exists
if exist venv\Scripts\activate.bat (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo Warning: Virtual environment not found!
    echo Run: python -m venv venv
    echo.
)

REM Check if .env file exists
if not exist .env (
    echo Error: .env file not found!
    echo Please copy .env.example to .env and configure it.
    pause
    exit /b 1
)

REM Display network information
echo Your PC's IP addresses:
ipconfig | findstr /i "IPv4"
echo.

REM Start the server
echo Starting server on http://0.0.0.0:5000
echo Access from:
echo   - This PC: http://localhost:5000
echo   - Mobile device: http://192.168.1.11:5000
echo   - API Docs: http://localhost:5000/docs
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
