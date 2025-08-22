// kgClient.ts - Knowledge Graph API client with proper headers
import { telemetryCollector } from './telemetry';

interface KGNode {
    id: string;
    type: string;
    properties: Record<string, any>;
}

interface KGRelationship {
    from: string;
    to: string;
    type: string;
    properties?: Record<string, any>;
}

interface KGQueryResponse {
    nodes: KGNode[];
    relationships: KGRelationship[];
    metadata?: {
        query_time_ms: number;
        total_nodes: number;
        total_relationships: number;
    };
}

interface APIResponse<T = any> {
    success: boolean;
    data?: T;
    error?: string;
    statusCode?: number;
}

class KnowledgeGraphClient {
    private baseUrl: string;
    private timeout: number = 5000;

    constructor(baseUrl: string = 'http://localhost:8000') {
        this.baseUrl = baseUrl.replace(/\/$/, ''); // Remove trailing slash
    }

    private async post(path: string, payload: any): Promise<any> {
        return new Promise((resolve, reject) => {
            const url = `${this.baseUrl}${path}`;
            const data = JSON.stringify(payload);

            fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: data,
                signal: AbortSignal.timeout(this.timeout)
            })
            .then(async response => {
                if (response.ok) {
                    const responseText = await response.text();
                    resolve(responseText ? JSON.parse(responseText) : {});
                } else {
                    const errorText = await response.text().catch(() => '');
                    reject(new Error(`POST ${path} failed: ${response.status} ${response.statusText} - ${errorText}`));
                }
            })
            .catch(reject);
        });
    }

    private async makeRequest<T>(
        endpoint: string,
        method: 'GET' | 'POST' | 'PUT' | 'DELETE' = 'GET',
        body?: any
    ): Promise<APIResponse<T>> {
        const url = `${this.baseUrl}${endpoint}`;
        const startTime = Date.now();

        try {
            const headers: Record<string, string> = {
                'Accept': 'application/json',
                'User-Agent': 'SuperAlita-VSCode-Extension/1.0'
            };

            if (body) {
                headers['Content-Type'] = 'application/json';
            }

            const response = await fetch(url, {
                method,
                headers,
                body: body ? JSON.stringify(body) : undefined,
                signal: AbortSignal.timeout(this.timeout)
            });

            const responseTime = Date.now() - startTime;
            console.log(`[KG-CLIENT] ${method} ${endpoint} - ${response.status} (${responseTime}ms)`);

            if (!response.ok) {
                const errorText = await response.text().catch(() => 'Unknown error');
                console.error(`[KG-CLIENT] API Error: ${response.status} ${response.statusText} - ${errorText}`);

                return {
                    success: false,
                    error: `HTTP ${response.status}: ${response.statusText}`,
                    statusCode: response.status
                };
            }

            // Check if response has content
            const contentLength = response.headers.get('content-length');
            if (contentLength === '0' || !response.headers.get('content-type')?.includes('application/json')) {
                return {
                    success: true,
                    data: null as T
                };
            }

            const data = await response.json();
            return {
                success: true,
                data
            };

        } catch (error: any) {
            const responseTime = Date.now() - startTime;
            console.error(`[KG-CLIENT] Request failed after ${responseTime}ms:`, error.message);

            let errorMessage = 'Network error';
            if (error.name === 'AbortError') {
                errorMessage = `Request timeout after ${this.timeout}ms`;
            } else if (error.name === 'TypeError') {
                errorMessage = 'Network connection failed';
            } else {
                errorMessage = error.message || 'Unknown error';
            }

            return {
                success: false,
                error: errorMessage
            };
        }
    }

    async getNodes(nodeType?: string, limit: number = 100): Promise<APIResponse<KGNode[]>> {
        const params = new URLSearchParams();
        if (nodeType) params.set('type', nodeType);
        params.set('limit', limit.toString());

        const endpoint = `/api/kg/nodes?${params.toString()}`;
        return this.makeRequest<KGNode[]>(endpoint);
    }

    async getNode(nodeId: string): Promise<APIResponse<KGNode>> {
        return this.makeRequest<KGNode>(`/api/kg/nodes/${encodeURIComponent(nodeId)}`);
    }

    async createNode(node: Omit<KGNode, 'id'>): Promise<APIResponse<KGNode>> {
        return this.makeRequest<KGNode>('/api/kg/nodes', 'POST', node);
    }

    async updateNode(nodeId: string, updates: Partial<KGNode>): Promise<APIResponse<KGNode>> {
        return this.makeRequest<KGNode>(`/api/kg/nodes/${encodeURIComponent(nodeId)}`, 'PUT', updates);
    }

    async deleteNode(nodeId: string): Promise<APIResponse<void>> {
        return this.makeRequest<void>(`/api/kg/nodes/${encodeURIComponent(nodeId)}`, 'DELETE');
    }

    async getRelationships(fromNode?: string, toNode?: string, relType?: string): Promise<APIResponse<KGRelationship[]>> {
        const params = new URLSearchParams();
        if (fromNode) params.set('from', fromNode);
        if (toNode) params.set('to', toNode);
        if (relType) params.set('type', relType);

        const endpoint = `/api/kg/relationships?${params.toString()}`;
        return this.makeRequest<KGRelationship[]>(endpoint);
    }

    async createRelationship(rel: KGRelationship): Promise<APIResponse<KGRelationship>> {
        return this.makeRequest<KGRelationship>('/api/kg/relationships', 'POST', rel);
    }

    async query(cypherQuery: string, params?: Record<string, any>): Promise<APIResponse<KGQueryResponse>> {
        const body = { query: cypherQuery, params };
        return this.makeRequest<KGQueryResponse>('/api/kg/query', 'POST', body);
    }

    async getGraphSummary(): Promise<APIResponse<{
        total_nodes: number;
        total_relationships: number;
        node_types: Record<string, number>;
        relationship_types: Record<string, number>;
    }>> {
        return this.makeRequest('/api/kg/summary');
    }

    async exportGraph(format: 'json' | 'cypher' = 'json'): Promise<APIResponse<any>> {
        return this.makeRequest(`/api/kg/export?format=${format}`);
    }

    // Health check with metrics recording
    async healthCheck(): Promise<APIResponse<{status: string, timestamp: number}>> {
        const result = await this.makeRequest<{status: string, timestamp: number}>('/api/health');

        if (result.success) {
            telemetryCollector.recordCacheEvent('cache_hit', 'kg_health_check');
        } else {
            telemetryCollector.recordCacheEvent('cache_miss', 'kg_health_check');
        }

        return result;
    }

    // Set custom timeout
    setTimeout(timeoutMs: number): void {
        this.timeout = timeoutMs;
    }

    // Get current configuration
    getConfig(): {baseUrl: string, timeout: number} {
        return {
            baseUrl: this.baseUrl,
            timeout: this.timeout
        };
    }

    // New: persist policy changes / consolidated insights / personality snapshots
    async updatePolicy(policy: string, action: string, payload: any): Promise<any> {
        return this.post('/policy_update', { policy, action, payload });
    }

    async upsertConsolidatedInsight(insight: {
        pattern: string;
        confidence: number;
        sessionsObserved: number;
        effectivenessScore: number;
        lastValidated: string;
    }): Promise<any> {
        return this.post('/upsert_consolidated_insight', insight);
    }

    async recordPersonality(snapshot: {
        riskTolerance: number;
        optimizationPreference: string;
        learningStyle: string;
        timestamp: string;
    }): Promise<any> {
        return this.post('/record_personality', snapshot);
    }
}

export const kgClient = new KnowledgeGraphClient();
export type { KGNode, KGRelationship, KGQueryResponse, APIResponse };
