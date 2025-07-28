#!/bin/bash
# 🚀 Super Alita - One-Command Production Launch
# ===============================================

set -e

echo "🧠 Super Alita Neuro-Symbolic Agent"
echo "🚀 Production Launch System"
echo "=================================="

# Check Python version
python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
echo "🐍 Python version: $python_version"

# Install dependencies if needed
echo "📦 Checking dependencies..."
if ! python3 -c "import chromadb, google.generativeai, scipy, numpy, networkx, sentence_transformers" 2>/dev/null; then
    echo "Installing required packages..."
    pip install google-generativeai chromadb scipy numpy pytest networkx sentence_transformers
    echo "✅ Dependencies installed"
else
    echo "✅ All dependencies satisfied"
fi

# Create data directories
mkdir -p data/chroma_db
mkdir -p data/genealogy
mkdir -p logs

echo "📁 Data directories ready"

# Launch options
if [ "$1" = "--demo" ]; then
    echo "🎬 Running demo..."
    python3 demo.py
elif [ "$1" = "--interactive" ]; then
    echo "🎮 Starting interactive mode..."
    python3 launch.py --interactive
elif [ "$1" = "--test" ]; then
    echo "🧪 Running tests..."
    python3 -m pytest tests/ -v
else
    echo "🚀 Launching Super Alita Agent..."
    if [ -n "$1" ]; then
        python3 launch.py --goal "$1"
    else
        python3 launch.py --goal "Initialize and self-optimize"
    fi
fi

echo ""
echo "🎉 Super Alita is LIVE and OPERATIONAL!"
echo "   Use 'status', 'export', or 'goal <text>' commands"
echo "   Press Ctrl+C to shutdown gracefully"
