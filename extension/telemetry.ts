// telemetry.ts - Enhanced causal telemetry for self-insight loop with decision confidence, learning velocity, and personality tracking
import * as vscode from 'vscode';

interface TelemetryEvent {
    timestamp: number;
    event_type: string;
    source: string;
    why?: string;  // Decision rationale
}

export interface ToolChoiceEvent {
    toolCandidates: string[];
    chosenTool: string;
    rationale: string;
    confidence?: number;           // 0..1
    alternativesConsidered?: number;
    timestamp: string;
    source: string;
}

export interface LearningVelocity {
    metric: string;                // e.g., "cache_hit_ratio" or "rtt_ewma_ms"
    baseline: number;
    current: number;
    windowMs: number;
    improvement: number;           // signed delta (direction depends on metric semantics)
    confidence: number;            // 0..1
    timestamp: string;
    source: string;
}

export type HypothesisStatus = 'testing' | 'confirmed' | 'rejected';
export interface HypothesisEvent {
    id: string;
    statement: string;
    confidence: number;            // 0..1
    status: HypothesisStatus;
    windowMs: number;
    timestamp: string;
    source: string;
}

export interface AgentPersonality {
    riskTolerance: number;         // 0..1
    optimizationPreference: 'speed' | 'accuracy' | 'reliability';
    learningStyle: 'conservative' | 'aggressive' | 'balanced';
    timestamp: string;
    source: string;
}

interface BreakerStateChange extends TelemetryEvent {
    event_type: 'breaker_state_change';
    from_state: 'closed' | 'open' | 'half_open';
    to_state: 'closed' | 'open' | 'half_open';
    failure_count: number;
    why: string;  // Why the transition happened
}

interface CacheEvent extends TelemetryEvent {
    event_type: 'cache_hit' | 'cache_miss';
    cache_key: string;
    hit_ratio?: number;
}

class TelemetryCollector {
    private events: TelemetryEvent[] = [];
    private metrics: Map<string, number> = new Map();

    // Enhanced metrics for self-insight
    private decisionConfidenceHistogram: Map<string, number[]> = new Map();
    private learningVelocityGauges: Map<string, number> = new Map();
    private hypothesisByStatus: Map<string, number> = new Map();
    private personalityMetrics: Map<string, number> = new Map();
    private policyChanges: Map<string, number> = new Map();
    private policySuccesses: Map<string, number> = new Map();

    constructor() {
        // Initialize key metrics
        this.metrics.set('tool_choices_total', 0);
        this.metrics.set('shed_decisions_total', 0);
        this.metrics.set('breaker_transitions_total', 0);
        this.metrics.set('cache_hit_ratio', 0);

        // Initialize self-insight metrics
        this.hypothesisByStatus.set('testing', 0);
        this.hypothesisByStatus.set('confirmed', 0);
        this.hypothesisByStatus.set('rejected', 0);
        this.personalityMetrics.set('risk_tolerance', 0.6);
    }    recordToolChoice(evt: ToolChoiceEvent): void {
        this.metrics.set('tool_choices_total', (this.metrics.get('tool_choices_total') || 0) + 1);

        if (typeof evt.confidence === 'number') {
            const key = `${evt.chosenTool}_${evt.source}`;
            if (!this.decisionConfidenceHistogram.has(key)) {
                this.decisionConfidenceHistogram.set(key, []);
            }
            this.decisionConfidenceHistogram.get(key)!.push(evt.confidence);
        }

        console.log(`[TELEMETRY] Tool choice: ${evt.chosenTool} (conf=${evt.confidence}, alternatives=${evt.alternativesConsidered}) - ${evt.rationale}`);
    }

    recordLearningVelocity(lv: LearningVelocity): void {
        const key = `${lv.metric}_${lv.source}`;
        this.learningVelocityGauges.set(key, lv.improvement);

        console.log(`[TELEMETRY] Learning velocity: ${lv.metric} improved by ${lv.improvement} (confidence=${lv.confidence})`);
    }

    recordHypothesis(evt: HypothesisEvent): void {
        const currentCount = this.hypothesisByStatus.get(evt.status) || 0;
        this.hypothesisByStatus.set(evt.status, currentCount + 1);

        console.log(`[TELEMETRY] Hypothesis ${evt.id}: ${evt.status} (conf=${evt.confidence}) - ${evt.statement}`);
    }

    recordPersonality(p: AgentPersonality): void {
        this.personalityMetrics.set('risk_tolerance', p.riskTolerance);

        console.log(`[TELEMETRY] Personality update: risk=${p.riskTolerance}, style=${p.learningStyle}, pref=${p.optimizationPreference}`);
    }

    recordPolicyChange(policy: string, action: string, source: string): void {
        const key = `${policy}_${action}_${source}`;
        this.policyChanges.set(key, (this.policyChanges.get(key) || 0) + 1);

        console.log(`[TELEMETRY] Policy change: ${policy} ${action} from ${source}`);
    }

    recordPolicySuccess(policy: string, source: string): void {
        const key = `${policy}_${source}`;
        this.policySuccesses.set(key, (this.policySuccesses.get(key) || 0) + 1);

        console.log(`[TELEMETRY] Policy success: ${policy} from ${source}`);
    }

    recordToolChoiceLegacy(toolName: string, confidence: number, fallbackConsidered: boolean, why: string): void {
        const legacyEvent: TelemetryEvent = {
            timestamp: Date.now(),
            event_type: 'tool_choice',
            source: 'mcp_router',
            why
        };

        this.events.push(legacyEvent);
        this.metrics.set('tool_choices_total', (this.metrics.get('tool_choices_total') || 0) + 1);

        console.log(`[TELEMETRY] Tool choice: ${toolName} (conf=${confidence}, fallback=${fallbackConsidered}) - ${why}`);
    }

    recordShed(reason: string, toolName?: string): void {
        const event: TelemetryEvent = {
            timestamp: Date.now(),
            event_type: 'shed_decision',
            source: 'load_shedder',
            why: reason
        };

        this.events.push(event);
        this.metrics.set('shed_decisions_total', (this.metrics.get('shed_decisions_total') || 0) + 1);

        console.log(`[TELEMETRY] Shed decision: ${reason} ${toolName ? `(tool=${toolName})` : ''}`);
    }

    recordBreakerTransition(fromState: string, toState: string, failureCount: number, why: string): void {
        const event: BreakerStateChange = {
            timestamp: Date.now(),
            event_type: 'breaker_state_change',
            source: 'circuit_breaker',
            from_state: fromState as any,
            to_state: toState as any,
            failure_count: failureCount,
            why
        };

        this.events.push(event);
        this.metrics.set('breaker_transitions_total', (this.metrics.get('breaker_transitions_total') || 0) + 1);

        console.log(`[TELEMETRY] Breaker transition: ${fromState} → ${toState} (failures=${failureCount}) - ${why}`);
    }

    recordCacheEvent(eventType: 'cache_hit' | 'cache_miss', cacheKey: string, hitRatio?: number): void {
        const event: CacheEvent = {
            timestamp: Date.now(),
            event_type: eventType,
            source: 'cache_manager',
            cache_key: cacheKey,
            hit_ratio: hitRatio
        };

        this.events.push(event);
        if (hitRatio !== undefined) {
            this.metrics.set('cache_hit_ratio', hitRatio);
        }
    }

    getMetricsForPrometheus(): string {
        let output = '';

        // Convert basic metrics to Prometheus format
        for (const [key, value] of this.metrics.entries()) {
            output += `super_alita_${key} ${value}\n`;
        }

        // Add decision confidence histograms
        for (const [tool_source, confidences] of this.decisionConfidenceHistogram.entries()) {
            if (confidences.length > 0) {
                const avg = confidences.reduce((a, b) => a + b, 0) / confidences.length;
                const p50 = confidences.sort()[Math.floor(confidences.length * 0.5)];
                const p90 = confidences.sort()[Math.floor(confidences.length * 0.9)];

                output += `sa_decision_confidence_avg{tool_source="${tool_source}"} ${avg.toFixed(3)}\n`;
                output += `sa_decision_confidence_p50{tool_source="${tool_source}"} ${p50.toFixed(3)}\n`;
                output += `sa_decision_confidence_p90{tool_source="${tool_source}"} ${p90.toFixed(3)}\n`;
            }
        }

        // Add learning velocity gauges
        for (const [metric_source, improvement] of this.learningVelocityGauges.entries()) {
            output += `sa_learning_velocity{metric_source="${metric_source}"} ${improvement}\n`;
        }

        // Add hypothesis counters
        for (const [status, count] of this.hypothesisByStatus.entries()) {
            output += `sa_hypothesis_total{status="${status}"} ${count}\n`;
        }

        // Add personality metrics
        for (const [metric, value] of this.personalityMetrics.entries()) {
            output += `sa_personality_${metric} ${value}\n`;
        }

        // Add policy change counters
        for (const [policy_action_source, count] of this.policyChanges.entries()) {
            output += `sa_policy_changes_total{policy_action_source="${policy_action_source}"} ${count}\n`;
        }

        // Add policy success counters
        for (const [policy_source, count] of this.policySuccesses.entries()) {
            output += `sa_policy_success_total{policy_source="${policy_source}"} ${count}\n`;
        }

        // Add gauge metrics from recent events
        const recentEvents = this.events.filter(e => Date.now() - e.timestamp < 60000); // Last minute
        const toolChoices = recentEvents.filter(e => e.event_type === 'tool_choice').length;
        const shedDecisions = recentEvents.filter(e => e.event_type === 'shed_decision').length;
        const breakerTransitions = recentEvents.filter(e => e.event_type === 'breaker_state_change').length;

        output += `super_alita_tool_choices_per_minute ${toolChoices}\n`;
        output += `super_alita_shed_decisions_per_minute ${shedDecisions}\n`;
        output += `super_alita_breaker_transitions_per_minute ${breakerTransitions}\n`;

        return output;
    }

    getRecentEvents(limit: number = 100): TelemetryEvent[] {
        return this.events.slice(-limit);
    }

    // Cleanup old events to prevent memory growth
    cleanup(): void {
        const cutoff = Date.now() - (24 * 60 * 60 * 1000); // 24 hours
        this.events = this.events.filter(e => e.timestamp > cutoff);
    }
}

export const telemetryCollector = new TelemetryCollector();

// Cleanup timer
setInterval(() => {
    telemetryCollector.cleanup();
}, 60 * 60 * 1000); // Every hour
