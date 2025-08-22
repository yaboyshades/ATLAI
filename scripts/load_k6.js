// K6 Load Testing Script for Super-Alita Performance Baseline
// Simulates realistic traffic patterns with ramp-up, steady state, and spike testing

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let responseTime = new Trend('response_time');
export let throughput = new Counter('requests_total');

// Test configuration
export let options = {
  stages: [
    // Warm-up
    { duration: '30s', target: 10 },
    // Ramp-up to normal load
    { duration: '1m', target: 50 },
    // Steady state
    { duration: '2m', target: 50 },
    // Spike test
    { duration: '30s', target: 100 },
    // Back to normal
    { duration: '1m', target: 50 },
    // Ramp down
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    // SLA requirements
    'http_req_duration': ['p(95)<500', 'p(99)<1000'], // 95% < 500ms, 99% < 1s
    'http_req_failed': ['rate<0.05'], // Error rate < 5%
    'errors': ['rate<0.05'],
    'response_time': ['p(95)<500'],
  },
};

// Base URL - adjust for your Super-Alita instance
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';

// Request patterns that simulate real usage
const REQUEST_PATTERNS = [
  {
    name: 'health_check',
    weight: 10,
    endpoint: '/health',
    method: 'GET',
  },
  {
    name: 'plugin_list',
    weight: 20,
    endpoint: '/api/plugins',
    method: 'GET',
  },
  {
    name: 'event_query',
    weight: 30,
    endpoint: '/api/events',
    method: 'GET',
    params: { limit: 50, offset: 0 },
  },
  {
    name: 'agent_status',
    weight: 15,
    endpoint: '/api/status',
    method: 'GET',
  },
  {
    name: 'event_create',
    weight: 20,
    endpoint: '/api/events',
    method: 'POST',
    payload: {
      event_type: 'test_event',
      data: { test: true, timestamp: Date.now() },
    },
  },
  {
    name: 'tool_execute',
    weight: 5,
    endpoint: '/api/tools/execute',
    method: 'POST',
    payload: {
      tool_name: 'test_tool',
      parameters: { input: 'test data' },
    },
  },
];

// Calculate cumulative weights for random selection
let cumulativeWeights = [];
let totalWeight = 0;
for (let pattern of REQUEST_PATTERNS) {
  totalWeight += pattern.weight;
  cumulativeWeights.push(totalWeight);
}

function selectRequestPattern() {
  const random = Math.random() * totalWeight;
  for (let i = 0; i < cumulativeWeights.length; i++) {
    if (random <= cumulativeWeights[i]) {
      return REQUEST_PATTERNS[i];
    }
  }
  return REQUEST_PATTERNS[0]; // Fallback
}

function makeRequest(pattern) {
  const url = `${BASE_URL}${pattern.endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'k6-load-test/1.0',
  };

  let response;
  const startTime = Date.now();

  try {
    if (pattern.method === 'GET') {
      const params = pattern.params || {};
      const queryString = Object.keys(params)
        .map(key => `${key}=${encodeURIComponent(params[key])}`)
        .join('&');
      const fullUrl = queryString ? `${url}?${queryString}` : url;

      response = http.get(fullUrl, { headers });
    } else if (pattern.method === 'POST') {
      response = http.post(url, JSON.stringify(pattern.payload), { headers });
    } else {
      response = http.request(pattern.method, url, null, { headers });
    }

    const duration = Date.now() - startTime;
    responseTime.add(duration);
    throughput.add(1);

    // Check response
    const success = check(response, {
      [`${pattern.name}: status is 2xx`]: (r) => r.status >= 200 && r.status < 300,
      [`${pattern.name}: response time < 1s`]: (r) => r.timings.duration < 1000,
      [`${pattern.name}: has body`]: (r) => r.body && r.body.length > 0,
    });

    if (!success) {
      errorRate.add(1);
      console.error(`Request failed: ${pattern.name} - Status: ${response.status}`);
    } else {
      errorRate.add(0);
    }

    return response;
  } catch (error) {
    errorRate.add(1);
    throughput.add(1);
    console.error(`Request error: ${pattern.name} - ${error}`);
    return null;
  }
}

export default function () {
  // Select request pattern based on weights
  const pattern = selectRequestPattern();

  // Make the request
  const response = makeRequest(pattern);

  // Add realistic think time (0.5-2 seconds)
  const thinkTime = 0.5 + Math.random() * 1.5;
  sleep(thinkTime);
}

// Setup function runs once per VU at the beginning
export function setup() {
  console.log('Starting Super-Alita load test...');
  console.log(`Target URL: ${BASE_URL}`);
  console.log('Request patterns:', REQUEST_PATTERNS.map(p => p.name).join(', '));

  // Warmup request to ensure service is ready
  const warmupResponse = http.get(`${BASE_URL}/health`);
  if (warmupResponse.status !== 200) {
    console.warn(`Warning: Warmup request failed with status ${warmupResponse.status}`);
  }

  return { startTime: Date.now() };
}

// Teardown function runs once at the end
export function teardown(data) {
  const duration = (Date.now() - data.startTime) / 1000;
  console.log(`Load test completed in ${duration}s`);
  console.log('Check k6 summary for detailed metrics');
}

// Chaos engineering scenarios (optional)
export function chaosScenario() {
  // Simulate various failure conditions
  const scenarios = [
    'timeout_requests',
    'malformed_payloads',
    'rate_limit_breach',
    'concurrent_spikes',
  ];

  // This would be activated with K6_CHAOS=true environment variable
  if (__ENV.K6_CHAOS === 'true') {
    console.log('Chaos engineering mode enabled');
    // Implement chaos scenarios
  }
}

/*
Usage Examples:

# Basic performance test
k6 run scripts/load_k6.js

# Test against different environment
BASE_URL=https://staging.example.com k6 run scripts/load_k6.js

# Chaos engineering mode
K6_CHAOS=true k6 run scripts/load_k6.js

# Custom test duration
k6 run --duration 5m --vus 20 scripts/load_k6.js

# Cloud testing (if using k6 cloud)
k6 cloud scripts/load_k6.js

Expected SLA Metrics:
- P95 response time: < 500ms
- P99 response time: < 1000ms
- Error rate: < 5%
- Throughput: > 100 req/s at 50 VU
- Memory usage: < 512MB steady state
- CPU usage: < 70% under normal load

Performance Baseline Checklist:
□ Service starts and responds to health checks
□ All endpoints return valid responses under load
□ Response times meet SLA requirements
□ Error rates stay below threshold
□ Circuit breakers trip and recover properly
□ Caching achieves target hit rates
□ Resource usage remains within limits
□ System recovers from spike loads
*/
