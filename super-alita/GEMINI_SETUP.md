# 🚀 Super Alita - Quick Reference

## 🔧 Switch to Real Gemini Embeddings

### Setup (One-time)
```powershell
# Get API key from: https://makersuite.google.com/app/apikey
$env:GEMINI_API_KEY="AIza..."  # Your actual key

# Test connection
python demo_embeddings.py
```

### Verification Signs

| **System** | **Fallback Mode** | **Real Gemini Mode** |
|------------|-------------------|----------------------|
| **Log Message** | `Gemini embedding failed: 400 API key not valid` | `✅ Generated 3 embeddings` |
| **Embedding Dim** | 1024 (deterministic) | 768 (Gemini text-embedding-004) |
| **Similarity** | Random/deterministic | Semantic similarity |

### Configuration Files

- **`src/config/agent.yaml`**: Main config
- **Environment**: `GEMINI_API_KEY` variable
- **Test**: `python demo_embeddings.py`

### Architecture Benefits

✅ **Graceful Fallback**: Always works, even without API key  
✅ **Real AI**: Gemini text-embedding-004 when configured  
✅ **Consistent Interface**: Same API regardless of backend  
✅ **Production Ready**: Error handling and logging  

### Next Steps

1. Set your API key
2. Run `python demo_embeddings.py` 
3. Look for "Gemini API configured" message
4. Run full agent: `python src/main.py`
5. Enjoy semantic AI! 🎉
