#!/usr/bin/env python3
"""
Setup script to configure Gemini API for Super Alita
"""

import os
import sys

def setup_gemini_api():
    """Interactive setup for Gemini API key."""
    
    print("🔧 Super Alita - Gemini API Setup")
    print("=" * 40)
    
    # Check if already configured
    current_key = os.getenv("GEMINI_API_KEY")
    if current_key:
        print(f"✅ GEMINI_API_KEY already set: {current_key[:8]}...")
        response = input("Do you want to update it? (y/N): ").lower()
        if response != 'y':
            print("Keeping existing configuration.")
            return
    
    print("\n📋 To get your Gemini API key:")
    print("1. Go to https://makersuite.google.com/app/apikey")
    print("2. Click 'Create API Key'")
    print("3. Copy the generated key")
    
    api_key = input("\n🔑 Enter your Gemini API key: ").strip()
    
    if not api_key:
        print("❌ No API key provided. Exiting.")
        return
    
    if not api_key.startswith("AIza"):
        print("⚠️  Warning: Gemini API keys usually start with 'AIza'")
        response = input("Continue anyway? (y/N): ").lower()
        if response != 'y':
            return
    
    # Set environment variable for current session
    os.environ["GEMINI_API_KEY"] = api_key
    
    # Create/update .env file
    env_file = ".env"
    with open(env_file, "w") as f:
        f.write(f"GEMINI_API_KEY={api_key}\n")
    
    print(f"\n✅ API key saved to {env_file}")
    print("\n🚀 Next steps:")
    print("1. Restart your terminal or run: set GEMINI_API_KEY=" + api_key)
    print("2. Run: python src/main.py")
    print("3. Look for: 'Gemini API configured for real embeddings'")

def test_gemini_connection():
    """Test if Gemini API is working."""
    try:
        import google.generativeai as genai
        
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            print("❌ GEMINI_API_KEY not found in environment")
            return False
            
        genai.configure(api_key=api_key)
        
        # Test embedding
        response = genai.embed_content(
            model="models/text-embedding-004",
            content="Test embedding",
            task_type="RETRIEVAL_DOCUMENT"
        )
        
        print("✅ Gemini API connection successful!")
        print(f"   Embedding dimension: {len(response['embedding'])}")
        return True
        
    except Exception as e:
        print(f"❌ Gemini API test failed: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        test_gemini_connection()
    else:
        setup_gemini_api()
