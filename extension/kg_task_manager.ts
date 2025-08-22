// kg_task_manager.ts - Enhanced Insight Oracle with learning velocity, hypotheses, and personality tracking
import * as vscode from 'vscode';
import { kgClient, KGNode, APIResponse } from './kgClient';
import { telemetryCollector, LearningVelocity, AgentPersonality, HypothesisEvent } from './telemetry';
import { applyInsightPolicy, PolicyChange } from './insight_policy';
import { createHypothesis, updateHypothesis, addEvidence, evaluateHypothesis } from './hypothesis';

interface Task {
    id: string;
    title: string;
    description: string;
    priority: number;
    status: 'todo' | 'in-progress' | 'completed' | 'blocked';
    tags: string[];
    createdAt: number;
    updatedAt: number;
    estimatedHours?: number;
    actualHours?: number;
    dependencies?: string[];
}

interface InsightData {
    avgResponseTime: number;
    failureRate: number;
    toolChoicePattern: string;
    breakerEvents: number;
    recommendation: string;
    confidence: number;
}

interface PolicyRecommendation {
    policy: string;
    currentValue: any;
    recommendedValue: any;
    reason: string;
    confidence: number;
}

class InsightOracle {
    private ewmaRTT: number = 0;
    private alpha: number = 0.1; // EWMA smoothing factor
    private responseTimes: number[] = [];
    private lastInsightTime: number = 0;
    private insightInterval: number = 30000; // 30 seconds
    private lastRttEwmaMs: number = 0;
    private listeners: Array<(msg: string) => void> = [];

    constructor() {
        // Start insight generation loop
        setInterval(() => {
            this.generateInsights();
        }, this.insightInterval);
    }

    recordResponseTime(rtt: number): void {
        this.responseTimes.push(rtt);

        // Update EWMA
        if (this.ewmaRTT === 0) {
            this.ewmaRTT = rtt;
        } else {
            this.ewmaRTT = this.alpha * rtt + (1 - this.alpha) * this.ewmaRTT;
        }

        // Keep only last 100 response times
        if (this.responseTimes.length > 100) {
            this.responseTimes = this.responseTimes.slice(-100);
        }
    }

    private async generateInsights(): Promise<void> {
        const now = Date.now();
        if (now - this.lastInsightTime < this.insightInterval) {
            return;
        }

        this.lastInsightTime = now;

        // Get recent events for analysis
        const events = telemetryCollector.getRecentEvents(50);
        if (events.length === 0) {
            return;
        }

        // Analyze patterns
        const toolChoiceEvents = events.filter(e => e.event_type === 'tool_choice');
        const breakerEvents = events.filter(e => e.event_type === 'breaker_state_change');
        const shedEvents = events.filter(e => e.event_type === 'shed_decision');

        // Calculate metrics
        const avgRTT = this.responseTimes.length > 0
            ? this.responseTimes.reduce((a, b) => a + b, 0) / this.responseTimes.length
            : 0;

        const failureRate = breakerEvents.length / Math.max(toolChoiceEvents.length, 1);

        // Generate insights
        const insights: InsightData = {
            avgResponseTime: Math.round(this.ewmaRTT * 100) / 100,
            failureRate: Math.round(failureRate * 100) / 100,
            toolChoicePattern: this.analyzeToolChoicePattern(toolChoiceEvents),
            breakerEvents: breakerEvents.length,
            recommendation: this.generateRecommendation(avgRTT, failureRate, shedEvents.length),
            confidence: this.calculateConfidence(events.length)
        };

        // Generate policy recommendations
        const policyRecs = this.generatePolicyRecommendations(insights);

        // Log insights
        console.log(`[INSIGHTS] EWMA RTT: ${insights.avgResponseTime}ms, Failure Rate: ${insights.failureRate}, Pattern: ${insights.toolChoicePattern}`);
        console.log(`[INSIGHTS] Recommendation: ${insights.recommendation} (confidence: ${insights.confidence})`);

        if (policyRecs.length > 0) {
            console.log(`[INSIGHTS] Policy Recommendations:`);
            policyRecs.forEach(rec => {
                console.log(`[INSIGHTS]   ${rec.policy}: ${rec.currentValue} → ${rec.recommendedValue} (${rec.reason})`);
            });
        }

        // Record insight event
        telemetryCollector.recordCacheEvent('cache_hit', 'insight_generation', insights.confidence);

        // --- Enhanced Self-Insight Features ---

        // Learning Velocity on EWMA RTT (lower is better)
        const lv: LearningVelocity = {
            metric: 'rtt_ewma_ms',
            baseline: this.lastRttEwmaMs || this.ewmaRTT,
            current: this.ewmaRTT,
            windowMs: 30000,
            improvement: (this.lastRttEwmaMs || this.ewmaRTT) - this.ewmaRTT,
            confidence: 0.8,
            timestamp: new Date().toISOString(),
            source: 'insight_oracle'
        };
        telemetryCollector.recordLearningVelocity(lv);
        this.lastRttEwmaMs = this.ewmaRTT;

        // Hypothesis lifecycle example
        const h = createHypothesis(
            'H1',
            'KG route outperforms upstream on payloads > 50KB by >=20%',
            0.6,
            10 * 60 * 1000
        );
        telemetryCollector.recordHypothesis({
            ...h,
            status: 'testing',
            timestamp: new Date().toISOString(),
            source: 'insight_oracle'
        });

        // Evaluate hypothesis (toy condition)
        const confirmed = this.ewmaRTT < 600;
        const h2 = updateHypothesis(h, confirmed ? 'confirmed' : 'rejected', confirmed ? 0.75 : 0.4);
        telemetryCollector.recordHypothesis({
            ...h2,
            timestamp: new Date().toISOString(),
            source: 'insight_oracle'
        });

        // Apply sample policy for demonstration
        if (insights.avgResponseTime > 500) {
            await applyInsightPolicy({
                policy: 'concurrency_backoff',
                rationale: 'high_rtt_ewma',
                suggestedDelta: -0.25,
                currentValue: 10,
                newValue: 7
            }, kgClient);
        }

        // Emit insight pulse for UI
        this.emitInsight(`RTT: ${Math.round(this.ewmaRTT)}ms | ${insights.recommendation}`);
    }

    onInsight(cb: (msg: string) => void): void {
        this.listeners.push(cb);
    }

    private emitInsight(msg: string): void {
        this.listeners.forEach(cb => cb(msg));
    }

    private analyzeToolChoicePattern(toolEvents: any[]): string {
        if (toolEvents.length === 0) return 'no-activity';

        const toolCounts = toolEvents.reduce((acc, event) => {
            const tool = event.tool_name || 'unknown';
            acc[tool] = (acc[tool] || 0) + 1;
            return acc;
        }, {} as Record<string, number>);

        const sortedTools = Object.entries(toolCounts)
            .sort(([,a], [,b]) => (b as number) - (a as number))
            .slice(0, 3)
            .map(([tool, count]) => `${tool}(${count})`);

        return sortedTools.join(',') || 'diverse';
    }

    private generateRecommendation(avgRTT: number, failureRate: number, shedCount: number): string {
        if (failureRate > 0.2) {
            return 'High failure rate detected - consider increasing circuit breaker timeout';
        }

        if (avgRTT > 5000) {
            return 'High response times - consider reducing tool complexity or adding caching';
        }

        if (shedCount > 5) {
            return 'Frequent load shedding - consider increasing concurrent request limits';
        }

        if (this.ewmaRTT < 100 && failureRate < 0.05) {
            return 'System running optimally - consider increasing request rate';
        }

        return 'System operating within normal parameters';
    }

    private calculateConfidence(eventCount: number): number {
        // Confidence based on sample size
        if (eventCount < 5) return 0.3;
        if (eventCount < 15) return 0.6;
        if (eventCount < 30) return 0.8;
        return 0.95;
    }

    private generatePolicyRecommendations(insights: InsightData): PolicyRecommendation[] {
        const recommendations: PolicyRecommendation[] = [];

        // Circuit breaker timeout recommendation
        if (insights.avgResponseTime > 3000 && insights.failureRate > 0.1) {
            recommendations.push({
                policy: 'circuit_breaker_timeout',
                currentValue: '5000ms',
                recommendedValue: '8000ms',
                reason: 'High RTT and failure rate suggest need for longer timeout',
                confidence: insights.confidence
            });
        }

        // Concurrency recommendation
        if (insights.avgResponseTime < 500 && insights.failureRate < 0.05) {
            recommendations.push({
                policy: 'max_concurrent_requests',
                currentValue: 10,
                recommendedValue: 15,
                reason: 'Low RTT and failure rate suggest capacity for higher concurrency',
                confidence: insights.confidence
            });
        }

        // Cache TTL recommendation
        if (insights.toolChoicePattern.includes('read') && insights.avgResponseTime > 1000) {
            recommendations.push({
                policy: 'cache_ttl',
                currentValue: '300s',
                recommendedValue: '600s',
                reason: 'Read-heavy pattern with high RTT suggests longer cache retention',
                confidence: insights.confidence
            });
        }

        return recommendations;
    }

    getInsightSummary(): InsightData {
        return {
            avgResponseTime: this.ewmaRTT,
            failureRate: 0, // Calculate from recent events
            toolChoicePattern: 'current',
            breakerEvents: 0,
            recommendation: 'Generate real-time recommendation',
            confidence: 0.8
        };
    }
}

class KGTaskManager {
    private oracle: InsightOracle;
    private tasks: Map<string, Task> = new Map();
    private personality: AgentPersonality = {
        riskTolerance: 0.6,
        optimizationPreference: 'reliability',
        learningStyle: 'balanced',
        timestamp: new Date().toISOString(),
        source: 'kg_task_manager'
    };

    constructor() {
        this.oracle = new InsightOracle();
        this.loadTasks();
        this.startPersonalityTracking();
    }

    private startPersonalityTracking(): void {
        // Update personality based on system behavior every 60 seconds
        setInterval(() => {
            this.updatePersonality();
        }, 60000);
    }

    private async updatePersonality(): Promise<void> {
        // Personality drift based on system performance (toy heuristic)
        const currentRTT = this.oracle.getInsightSummary().avgResponseTime;

        if (currentRTT > 700) {
            // High latency -> become more risk-averse
            this.personality.riskTolerance = Math.max(0.2, this.personality.riskTolerance - 0.05);
            this.personality.optimizationPreference = 'reliability';
        } else if (currentRTT < 400) {
            // Low latency -> become more risk-tolerant
            this.personality.riskTolerance = Math.min(0.9, this.personality.riskTolerance + 0.05);
            this.personality.optimizationPreference = 'speed';
        }

        this.personality.timestamp = new Date().toISOString();

        // Record personality changes
        telemetryCollector.recordPersonality(this.personality);

        // Persist to knowledge graph
        try {
            await kgClient.recordPersonality({
                riskTolerance: this.personality.riskTolerance,
                optimizationPreference: this.personality.optimizationPreference,
                learningStyle: this.personality.learningStyle,
                timestamp: this.personality.timestamp
            });
        } catch (error) {
            console.warn('[KG-TASKS] Failed to persist personality update:', error);
        }
    }

    private async loadTasks(): Promise<void> {
        try {
            // Try to load tasks from knowledge graph
            const response = await kgClient.getNodes('Task', 50);

            if (response.success && response.data) {
                response.data.forEach(node => {
                    const task: Task = {
                        id: node.id,
                        title: node.properties.title || 'Untitled',
                        description: node.properties.description || '',
                        priority: node.properties.priority || 1,
                        status: node.properties.status || 'todo',
                        tags: node.properties.tags || [],
                        createdAt: node.properties.createdAt || Date.now(),
                        updatedAt: node.properties.updatedAt || Date.now(),
                        estimatedHours: node.properties.estimatedHours,
                        actualHours: node.properties.actualHours,
                        dependencies: node.properties.dependencies
                    };
                    this.tasks.set(task.id, task);
                });

                console.log(`[KG-TASKS] Loaded ${this.tasks.size} tasks from knowledge graph`);
            }
        } catch (error) {
            console.error('[KG-TASKS] Failed to load tasks from KG:', error);
        }
    }

    async createTask(taskData: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>): Promise<Task> {
        const startTime = Date.now();

        const task: Task = {
            ...taskData,
            id: this.generateTaskId(),
            createdAt: Date.now(),
            updatedAt: Date.now()
        };

        this.tasks.set(task.id, task);

        // Store in knowledge graph
        try {
            const response = await kgClient.createNode({
                type: 'Task',
                properties: task
            });

            const rtt = Date.now() - startTime;
            this.oracle.recordResponseTime(rtt);

            if (response.success) {
                console.log(`[KG-TASKS] Created task ${task.id} in KG (${rtt}ms)`);
            }
        } catch (error) {
            console.error(`[KG-TASKS] Failed to store task in KG:`, error);
        }

        return task;
    }

    async updateTask(taskId: string, updates: Partial<Task>): Promise<Task | null> {
        const startTime = Date.now();
        const task = this.tasks.get(taskId);

        if (!task) {
            console.warn(`[KG-TASKS] Task ${taskId} not found`);
            return null;
        }

        const updatedTask = {
            ...task,
            ...updates,
            updatedAt: Date.now()
        };

        this.tasks.set(taskId, updatedTask);

        // Update in knowledge graph
        try {
            const response = await kgClient.updateNode(taskId, {
                type: 'Task',
                properties: updatedTask
            });

            const rtt = Date.now() - startTime;
            this.oracle.recordResponseTime(rtt);

            if (response.success) {
                console.log(`[KG-TASKS] Updated task ${taskId} in KG (${rtt}ms)`);
            }
        } catch (error) {
            console.error(`[KG-TASKS] Failed to update task in KG:`, error);
        }

        return updatedTask;
    }

    getTasks(status?: Task['status']): Task[] {
        const tasks = Array.from(this.tasks.values());

        if (status) {
            return tasks.filter(task => task.status === status);
        }

        // Sort by priority (higher first) then by creation date
        return tasks.sort((a, b) => {
            if (a.priority !== b.priority) {
                return b.priority - a.priority;
            }
            return a.createdAt - b.createdAt;
        });
    }

    getInsights(): InsightData {
        return this.oracle.getInsightSummary();
    }

    private generateTaskId(): string {
        return `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    // VS Code integration
    async showTasksInWebview(): Promise<void> {
        const panel = vscode.window.createWebviewPanel(
            'kgTasks',
            'Knowledge Graph Tasks',
            vscode.ViewColumn.Two,
            { enableScripts: true }
        );

        const tasks = this.getTasks();
        const insights = this.getInsights();

        panel.webview.html = this.getTasksHtml(tasks, insights);
    }

    private getTasksHtml(tasks: Task[], insights: InsightData): string {
        const tasksHtml = tasks.slice(0, 20).map(task =>
            `<tr class="task-${task.status}">
                <td>${task.title}</td>
                <td>${task.status}</td>
                <td>${task.priority}</td>
                <td>${task.tags.join(', ')}</td>
                <td>${new Date(task.createdAt).toLocaleDateString()}</td>
            </tr>`
        ).join('');

        return `<!DOCTYPE html>
        <html>
        <head>
            <title>KG Task Manager</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 20px; }
                .insights { background: #f0f8ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
                .task-completed { background-color: #d4edda; }
                .task-in-progress { background-color: #fff3cd; }
                .task-blocked { background-color: #f8d7da; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
            </style>
        </head>
        <body>
            <h1>🧠 Knowledge Graph Task Manager</h1>

            <div class="insights">
                <h3>📊 System Insights</h3>
                <p><strong>Avg Response Time:</strong> ${insights.avgResponseTime}ms</p>
                <p><strong>Failure Rate:</strong> ${insights.failureRate}%</p>
                <p><strong>Tool Pattern:</strong> ${insights.toolChoicePattern}</p>
                <p><strong>Recommendation:</strong> ${insights.recommendation}</p>
            </div>

            <h2>📋 Tasks (${tasks.length})</h2>
            <table>
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Status</th>
                        <th>Priority</th>
                        <th>Tags</th>
                        <th>Created</th>
                    </tr>
                </thead>
                <tbody>
                    ${tasksHtml}
                </tbody>
            </table>
        </body>
        </html>`;
    }

    onInsight(cb: (msg: string) => void): void {
        this.oracle.onInsight(cb);
    }
}

export const kgTaskManager = new KGTaskManager();
export type { Task, InsightData, PolicyRecommendation };
