@echo off
REM 🚀 Super Alita - Windows Production Launch
REM =========================================

echo 🧠 Super Alita Neuro-Symbolic Agent
echo 🚀 Production Launch System
echo ==================================

REM Check Python
python --version
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python not found. Please install Python 3.8+
    pause
    exit /B 1
)

REM Install dependencies if needed
echo 📦 Checking dependencies...
python -c "import chromadb, google.generativeai, scipy, numpy, networkx, sentence_transformers" 2>NUL
if %ERRORLEVEL% NEQ 0 (
    echo Installing required packages...
    pip install google-generativeai chromadb scipy numpy pytest networkx sentence-transformers
    echo ✅ Dependencies installed
) else (
    echo ✅ All dependencies satisfied
)

REM Create data directories  
if not exist data\chroma_db mkdir data\chroma_db
if not exist data\genealogy mkdir data\genealogy
if not exist logs mkdir logs

echo 📁 Data directories ready

REM Launch options
if "%1"=="--demo" (
    echo 🎬 Running demo...
    python demo.py
) else if "%1"=="--interactive" (
    echo 🎮 Starting interactive mode...
    python launch.py --interactive
) else if "%1"=="--test" (
    echo 🧪 Running tests...
    python -m pytest tests/ -v
) else (
    echo 🚀 Launching Super Alita Agent...
    if not "%1"=="" (
        python launch.py --goal "%1"
    ) else (
        python launch.py --goal "Initialize and self-optimize"
    )
)

echo.
echo 🎉 Super Alita is LIVE and OPERATIONAL!
echo    Use 'status', 'export', or 'goal ^<text^>' commands
echo    Press Ctrl+C to shutdown gracefully
pause
