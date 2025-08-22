// hypothesis.ts - Super-light hypothesis lifecycle management
import { HypothesisEvent, HypothesisStatus } from './telemetry';

export interface Hypothesis {
    id: string;
    statement: string;
    confidence: number;
    windowMs: number;
    createdAt: number;
    evidence: Evidence[];
    status: HypothesisStatus;
}

export interface Evidence {
    metric: string;
    expectedValue: number;
    actualValue: number;
    confidence: number;
    timestamp: number;
    supports: boolean; // true if evidence supports hypothesis
}

// Global hypothesis registry
const activeHypotheses = new Map<string, Hypothesis>();

export function createHypothesis(
    id: string,
    statement: string,
    confidence: number,
    windowMs: number
): Omit<HypothesisEvent, 'status' | 'timestamp' | 'source'> {
    const hypothesis: Hypothesis = {
        id,
        statement,
        confidence,
        windowMs,
        createdAt: Date.now(),
        evidence: [],
        status: 'testing'
    };

    activeHypotheses.set(id, hypothesis);

    return { id, statement, confidence, windowMs };
}

export function updateHypothesis(
    h: Omit<HypothesisEvent, 'status' | 'timestamp' | 'source'>,
    status: HypothesisStatus,
    confidence: number
): { id: string; statement: string; confidence: number; status: HypothesisStatus; windowMs: number } {
    const hypothesis = activeHypotheses.get(h.id);
    if (hypothesis) {
        hypothesis.status = status;
        hypothesis.confidence = confidence;
    }

    return { ...h, status, confidence };
}

export function addEvidence(hypothesisId: string, evidence: Omit<Evidence, 'timestamp'>): boolean {
    const hypothesis = activeHypotheses.get(hypothesisId);
    if (!hypothesis) {
        console.warn(`[HYPOTHESIS] Hypothesis ${hypothesisId} not found`);
        return false;
    }

    const fullEvidence: Evidence = {
        ...evidence,
        timestamp: Date.now()
    };

    hypothesis.evidence.push(fullEvidence);

    // Auto-evaluate hypothesis if enough evidence collected
    if (hypothesis.evidence.length >= 3) {
        evaluateHypothesis(hypothesisId);
    }

    console.log(`[HYPOTHESIS] Added evidence to ${hypothesisId}: ${evidence.metric} = ${evidence.actualValue} (expected ${evidence.expectedValue})`);
    return true;
}

export function evaluateHypothesis(hypothesisId: string): HypothesisStatus | null {
    const hypothesis = activeHypotheses.get(hypothesisId);
    if (!hypothesis || hypothesis.status !== 'testing') {
        return null;
    }

    const supportingEvidence = hypothesis.evidence.filter(e => e.supports);
    const contradictingEvidence = hypothesis.evidence.filter(e => !e.supports);

    const supportRatio = supportingEvidence.length / hypothesis.evidence.length;
    const avgConfidence = hypothesis.evidence.reduce((sum, e) => sum + e.confidence, 0) / hypothesis.evidence.length;

    let newStatus: HypothesisStatus;
    let newConfidence: number;

    if (supportRatio >= 0.7 && avgConfidence >= 0.6) {
        newStatus = 'confirmed';
        newConfidence = Math.min(0.95, hypothesis.confidence + 0.2);
    } else if (supportRatio <= 0.3 || avgConfidence <= 0.3) {
        newStatus = 'rejected';
        newConfidence = Math.max(0.1, hypothesis.confidence - 0.3);
    } else {
        // Keep testing if evidence is mixed
        return hypothesis.status;
    }

    hypothesis.status = newStatus;
    hypothesis.confidence = newConfidence;

    console.log(`[HYPOTHESIS] ${hypothesisId} ${newStatus} with confidence ${newConfidence.toFixed(3)} (support ratio: ${supportRatio.toFixed(3)})`);

    return newStatus;
}

export function getActiveHypotheses(): Hypothesis[] {
    return Array.from(activeHypotheses.values()).filter(h => h.status === 'testing');
}

export function getHypothesisSummary(): { testing: number; confirmed: number; rejected: number } {
    const hypotheses = Array.from(activeHypotheses.values());
    return {
        testing: hypotheses.filter(h => h.status === 'testing').length,
        confirmed: hypotheses.filter(h => h.status === 'confirmed').length,
        rejected: hypotheses.filter(h => h.status === 'rejected').length
    };
}

export function cleanupExpiredHypotheses(): number {
    const now = Date.now();
    let cleaned = 0;

    for (const [id, hypothesis] of activeHypotheses.entries()) {
        if (now - hypothesis.createdAt > hypothesis.windowMs && hypothesis.status === 'testing') {
            // Auto-reject expired hypotheses
            hypothesis.status = 'rejected';
            hypothesis.confidence = 0.1;
            console.log(`[HYPOTHESIS] Auto-rejected expired hypothesis ${id}`);
            cleaned++;
        }
    }

    return cleaned;
}

// Auto-cleanup expired hypotheses every 5 minutes
setInterval(() => {
    cleanupExpiredHypotheses();
}, 5 * 60 * 1000);
