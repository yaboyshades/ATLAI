@echo off
echo 🔧 Super Alita - Gemini Setup Guide
echo =====================================
echo.
echo 📋 Steps to enable real Gemini embeddings:
echo.
echo 1. Get your API key from: https://makersuite.google.com/app/apikey
echo 2. Set environment variable:
echo    set GEMINI_API_KEY=your_api_key_here
echo.
echo 3. Test the setup:
echo    python demo_embeddings.py
echo.
echo 4. Look for this success message:
echo    "✅ Generated 3 embeddings"
echo    "   Dimension: 768"  ^(real Gemini^)
echo.
echo ⚡ Current status:
if defined GEMINI_API_KEY (
    echo    ✅ GEMINI_API_KEY is set: %GEMINI_API_KEY:~0,8%...
) else (
    echo    ❌ GEMINI_API_KEY is not set
)
echo.
pause
