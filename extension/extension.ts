// extension.ts - Enhanced VS Code extension with HTTP metrics endpoint and insight pulse
import * as vscode from 'vscode';
import * as http from 'http';
import { telemetryCollector } from './telemetry';
import { kgTaskManager } from './kg_task_manager';

let httpServer: http.Server | null = null;
let statusBarItem: vscode.StatusBarItem;
let insightStatusItem: vscode.StatusBarItem;

export function activate(context: vscode.ExtensionContext) {
    console.log('[EXTENSION] Super Alita extension activating...');

    // Create main status bar item
    statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
    statusBarItem.text = "$(pulse) Super Alita";
    statusBarItem.tooltip = "Super Alita Agent System";
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);

    // Create insight pulse status bar item
    insightStatusItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    insightStatusItem.text = '$(pulse) Self-Insight: warming up…';
    insightStatusItem.tooltip = 'Real-time system insights and adaptive recommendations';
    insightStatusItem.show();
    context.subscriptions.push(insightStatusItem);

    // Connect to insight updates
    kgTaskManager.onInsight((msg: string) => {
        insightStatusItem.text = `$(pulse) ${msg}`;
    });

    // Start HTTP metrics server
    startMetricsServer();

    // Register commands
    const disposable = vscode.commands.registerCommand('super-alita.showMetrics', () => {
        showMetricsPanel();
    });
    context.subscriptions.push(disposable);

    console.log('[EXTENSION] Super Alita extension activated');
}

export function deactivate() {
    console.log('[EXTENSION] Super Alita extension deactivating...');

    if (httpServer) {
        httpServer.close();
        httpServer = null;
    }

    if (statusBarItem) {
        statusBarItem.dispose();
    }

    console.log('[EXTENSION] Super Alita extension deactivated');
}

function startMetricsServer(): void {
    const port = 17893;

    httpServer = http.createServer((req, res) => {
        // CORS headers for development
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

        if (req.method === 'OPTIONS') {
            res.writeHead(200);
            res.end();
            return;
        }

        if (req.url === '/metrics' && req.method === 'GET') {
            // Prometheus metrics endpoint
            res.setHeader('Content-Type', 'text/plain; version=0.0.4; charset=utf-8');
            res.writeHead(200);

            const metrics = telemetryCollector.getMetricsForPrometheus();
            res.end(metrics);

            console.log('[METRICS] Served Prometheus metrics');
        } else if (req.url === '/events' && req.method === 'GET') {
            // Recent events endpoint for debugging
            res.setHeader('Content-Type', 'application/json');
            res.writeHead(200);

            const events = telemetryCollector.getRecentEvents(50);
            res.end(JSON.stringify(events, null, 2));

            console.log('[METRICS] Served recent events');
        } else if (req.url === '/health' && req.method === 'GET') {
            // Health check endpoint
            res.setHeader('Content-Type', 'application/json');
            res.writeHead(200);
            res.end(JSON.stringify({
                status: 'healthy',
                timestamp: Date.now(),
                extension: 'super-alita'
            }));
        } else {
            res.writeHead(404);
            res.end('Not Found');
        }
    });

    httpServer.listen(port, 'localhost', () => {
        console.log(`[METRICS] HTTP server listening on http://localhost:${port}`);
        console.log(`[METRICS] Prometheus metrics: http://localhost:${port}/metrics`);
        console.log(`[METRICS] Recent events: http://localhost:${port}/events`);
        console.log(`[METRICS] Health check: http://localhost:${port}/health`);

        // Update status bar
        statusBarItem.text = `$(pulse) Super Alita :${port}`;
        statusBarItem.tooltip = `Super Alita metrics server on port ${port}`;
    });

    httpServer.on('error', (err) => {
        console.error('[METRICS] HTTP server error:', err);
        statusBarItem.text = "$(alert) Super Alita (metrics error)";
        statusBarItem.tooltip = `Metrics server error: ${err.message}`;
    });
}

function showMetricsPanel(): void {
    const panel = vscode.window.createWebviewPanel(
        'superAlitaMetrics',
        'Super Alita Metrics',
        vscode.ViewColumn.Two,
        {
            enableScripts: true,
            retainContextWhenHidden: true
        }
    );

    const events = telemetryCollector.getRecentEvents(100);
    const metrics = telemetryCollector.getMetricsForPrometheus();

    panel.webview.html = getMetricsHtml(events, metrics);

    // Refresh every 5 seconds
    const interval = setInterval(() => {
        if (panel.visible) {
            const newEvents = telemetryCollector.getRecentEvents(100);
            const newMetrics = telemetryCollector.getMetricsForPrometheus();
            panel.webview.html = getMetricsHtml(newEvents, newMetrics);
        }
    }, 5000);

    panel.onDidDispose(() => {
        clearInterval(interval);
    });
}

function getMetricsHtml(events: any[], metrics: string): string {
    const eventsHtml = events.slice(-20).map(event =>
        `<tr>
            <td>${new Date(event.timestamp).toLocaleTimeString()}</td>
            <td>${event.event_type}</td>
            <td>${event.source}</td>
            <td>${event.why || '-'}</td>
        </tr>`
    ).join('');

    const metricsLines = metrics.split('\n').filter(line => line.trim()).map(line =>
        `<tr><td style="font-family: monospace;">${line}</td></tr>`
    ).join('');

    return `<!DOCTYPE html>
    <html>
    <head>
        <title>Super Alita Metrics</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 20px; }
            table { border-collapse: collapse; width: 100%; margin: 20px 0; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .timestamp { width: 100px; }
            .type { width: 150px; }
            .source { width: 120px; }
            h2 { color: #333; border-bottom: 2px solid #007acc; }
        </style>
    </head>
    <body>
        <h1>🤖 Super Alita Metrics Dashboard</h1>

        <h2>📊 Current Metrics (Prometheus Format)</h2>
        <table>
            ${metricsLines}
        </table>

        <h2>📝 Recent Events (Last 20)</h2>
        <table>
            <thead>
                <tr>
                    <th class="timestamp">Time</th>
                    <th class="type">Event Type</th>
                    <th class="source">Source</th>
                    <th>Why/Reason</th>
                </tr>
            </thead>
            <tbody>
                ${eventsHtml}
            </tbody>
        </table>

        <p><strong>Metrics endpoint:</strong> <code>http://localhost:17893/metrics</code></p>
        <p><strong>Events endpoint:</strong> <code>http://localhost:17893/events</code></p>

        <script>
            // Auto-refresh every 5 seconds
            setTimeout(() => location.reload(), 5000);
        </script>
    </body>
    </html>`;
}
