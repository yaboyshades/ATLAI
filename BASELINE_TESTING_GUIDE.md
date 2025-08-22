# 🚀 Super Alita Baseline Testing - Execution Guide

## Quick Start Commands

### Terminal 1: Start KG API Server
```powershell
cd "d:\Coding_Projects\ATLAI\super-alita"
python start_kg_api.py
```
*Keep this running - you should see "Uvicorn running on http://0.0.0.0:8000"*

### Terminal 2: Run Baseline Tests
```powershell
cd "d:\Coding_Projects\ATLAI\super-alita"
python baseline_testing_script.py
```
*This will verify the system health and collect initial metrics*

### Terminal 3: Start Monitoring (Optional)
```powershell
cd "d:\Coding_Projects\ATLAI\super-alita"
python baseline_monitor.py
```
*This will monitor for 10 minutes and generate a detailed report*

### Terminal 4: Test Agent Conversations
```powershell
cd "d:\Coding_Projects\ATLAI\super-alita"
python src/main.py
```

## Test Sequences for Agent

When the agent chat interface is ready, test these:

### 🎯 Decision Confidence Tests
1. **BT-DC-001**: `"What is 15 * 23 + 47?"`
   - *Expected: High confidence for calculator tool*

2. **BT-DC-002**: `"Help me with my project"`
   - *Expected: Lower confidence, disambiguation needed*

3. **BT-DC-003**: `"Analyze our event bus performance and suggest optimizations"`
   - *Expected: Multi-step reasoning with confidence progression*

### 🚀 Learning Velocity Tests
Execute this sequence in order:
1. `"Calculate 5 + 3"`
2. `"Calculate 15 * 8"`
3. `"Calculate (45 + 23) * 2 - 17"`
4. `"Calculate sqrt(144) + 25"`
5. `"Calculate 2^8 - 100"`
*Expected: Faster responses as pattern recognition improves*

### 🧪 Hypothesis Tests
1. `"What's the best way to optimize Python code?"`
2. `"Should I use functional or object-oriented programming?"`
3. `"How do you prefer to handle error cases?"`
*Expected: Agent forms hypotheses about your preferences*

## What to Watch For

### 🔍 In Agent Console
- `[INSIGHTS]` log entries
- `TELEMETRY:` events with decision confidence data
- Plugin startup messages (should see all 26 plugins)

### 📊 In KG API Console
- Incoming requests to `/api/kg/policy`, `/api/kg/personality`, `/api/kg/consolidation`
- HTTP 200 responses for health checks

### 💡 In VS Code Extension
- Status bar should show insight pulse during conversations
- Extension should be active and responsive

### 📈 Expected Metrics Growth
- Policy atoms should increase with decisions
- Personality data should show adaptation
- Consolidation insights should accumulate

## Success Indicators

✅ **System Health**: All services running without errors
✅ **Decision Confidence**: Measurable confidence values for each decision
✅ **Learning Velocity**: Response time improvement on repeated tasks
✅ **Hypothesis Formation**: Agent creates and tests hypotheses about user preferences
✅ **Telemetry Active**: Prometheus metrics updating, VS Code extension responsive
✅ **Cross-Session Ready**: Insights persist and can be retrieved via API

## Files Generated

After testing, you'll have:
- `baseline_test_report_*.json` - Initial system validation
- `baseline_monitor.log` - Real-time monitoring logs
- `baseline_monitoring_report_*.json` - Comprehensive analysis

## Next Steps After Baseline

1. **Prometheus Setup**: Point Prometheus to `config/prometheus/super-alita-prometheus.yml`
2. **Grafana Dashboard**: Import `config/grafana/super-alita-dashboard.json`
3. **Extended Testing**: Run longer sessions to validate learning persistence
4. **Cross-Session Testing**: Restart agent and verify insight retention

---

**Ready to begin!** Start with Terminal 1 (KG API Server) and proceed through each step.
