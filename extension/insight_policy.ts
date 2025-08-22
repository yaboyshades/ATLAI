// insight_policy.ts - Apply and record policy changes with persistence
import { telemetryCollector } from './telemetry';

export interface PolicyChange {
    policy: string;
    rationale: string;
    suggestedDelta?: number;
    currentValue?: any;
    newValue?: any;
}

export async function applyInsightPolicy(
    p: PolicyChange,
    kgClient?: any
): Promise<boolean> {
    try {
        // Record the policy change attempt
        telemetryCollector.recordPolicyChange(p.policy, 'apply', 'insight_oracle');

        console.log(`[POLICY] Applying ${p.policy}: ${p.rationale}`);

        // Simulate policy application (in real implementation, this would adjust actual system parameters)
        const success = await simulatePolicyApplication(p);

        if (success) {
            telemetryCollector.recordPolicySuccess(p.policy, 'insight_oracle');
            console.log(`[POLICY] Successfully applied ${p.policy} (delta: ${p.suggestedDelta})`);

            // Persist to knowledge graph if client available
            if (kgClient && typeof kgClient.updatePolicy === 'function') {
                try {
                    await kgClient.updatePolicy(p.policy, 'apply', {
                        rationale: p.rationale,
                        suggestedDelta: p.suggestedDelta,
                        currentValue: p.currentValue,
                        newValue: p.newValue,
                        timestamp: new Date().toISOString()
                    });
                } catch (error) {
                    console.warn(`[POLICY] Failed to persist policy change to KG: ${error}`);
                }
            }
        } else {
            console.warn(`[POLICY] Failed to apply ${p.policy}: ${p.rationale}`);
        }

        return success;
    } catch (error) {
        console.error(`[POLICY] Error applying policy ${p.policy}:`, error);
        return false;
    }
}

async function simulatePolicyApplication(policy: PolicyChange): Promise<boolean> {
    // Simulate policy application with different success rates based on policy type
    const policySuccessRates: Record<string, number> = {
        'concurrency_backoff': 0.85,
        'cache_ttl_increase': 0.90,
        'timeout_adjustment': 0.80,
        'load_shedding_threshold': 0.75,
        'circuit_breaker_timeout': 0.85
    };

    const successRate = policySuccessRates[policy.policy] || 0.70;
    const success = Math.random() < successRate;

    // Simulate async policy application time
    await new Promise(resolve => setTimeout(resolve, 50 + Math.random() * 100));

    return success;
}

export function createPolicyRecommendation(
    metric: string,
    currentValue: number,
    threshold: number,
    direction: 'increase' | 'decrease'
): PolicyChange {
    const delta = direction === 'increase' ? 0.2 : -0.2;
    const newValue = currentValue * (1 + delta);

    return {
        policy: `${metric}_adjustment`,
        rationale: `${metric} ${direction === 'increase' ? 'above' : 'below'} threshold ${threshold}`,
        suggestedDelta: delta,
        currentValue,
        newValue
    };
}
