#!/usr/bin/env python3
"""
Demo script showing Gemini API embedding integration
"""

import asyncio
import os
import sys
from datetime import datetime

async def demo_embeddings():
    """Demonstrate embedding functionality with and without Gemini API."""
    
    print("🧠 Super Alita - Embedding Demo")
    print("=" * 50)
    
    # Import after path setup
    sys.path.insert(0, os.path.abspath('.'))
    from src.main import SuperAlita
    from src.plugins.semantic_memory_plugin import SemanticMemoryPlugin
    
    # Check API key status
    api_key = os.getenv("GEMINI_API_KEY")
    if api_key:
        print(f"✅ Gemini API Key detected: {api_key[:8]}...")
    else:
        print("⚠️  No Gemini API key - using fallback embeddings")
    
    print("\n🚀 Initializing Super Alita...")
    
    try:
        # Initialize agent
        agent = SuperAlita()
        await agent.initialize()
        await agent.start()
        
        print("✅ Agent started successfully")
        
        # Get semantic memory plugin
        memory_plugin = agent.plugins.get("semantic_memory")
        if not memory_plugin:
            print("❌ Semantic memory plugin not found")
            return
            
        print("\n📝 Testing embedding generation...")
        
        # Test texts
        test_texts = [
            "Super Alita is a neuro-symbolic agent",
            "Machine learning and artificial intelligence",
            "Task planning using And-Or graphs"
        ]
        
        # Generate embeddings
        embeddings = await memory_plugin.embed_text(test_texts)
        
        print(f"✅ Generated {len(embeddings)} embeddings")
        print(f"   Dimension: {len(embeddings[0])}")
        print(f"   Sample values: {embeddings[0][:5]}")
        
        # Test similarity
        similarity = embeddings[0] @ embeddings[1]
        print(f"   Similarity (text 1 vs 2): {similarity:.3f}")
        
        # Shutdown
        await agent.shutdown()
        print("\n✅ Demo completed successfully!")
        
    except Exception as e:
        print(f"❌ Demo failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print(f"🕐 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    asyncio.run(demo_embeddings())
