#!/bin/bash

echo "================================================"
echo "  FIX WEBSOCKET HANDLER - RAW TCP FORWARDING"
echo "================================================"
echo ""

# Check if directory exists
if [ ! -d "/opt/nautica-proxy-v2" ]; then
    echo "❌ Directory /opt/nautica-proxy-v2 not found!"
    exit 1
fi

cd /opt/nautica-proxy-v2

# Backup current server.js
echo "✅ Creating backup of server.js..."
cp server.js server.js.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Create fixed server.js with proper WebSocket handling
echo "🔧 Creating fixed server.js with raw TCP forwarding..."

cat > server.js << 'EOF'
const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const cors = require('cors');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
const net = require('net');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ noServer: true });

const PORT = process.env.PORT || 3000;
const DOMAIN = process.env.DOMAIN || 'localhost';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Store accounts
let accounts = [];
let proxyList = [];

// WebSocket Handler for Proxy Traffic
wss.on('connection', (ws, request) => {
    console.log('🔗 WebSocket connection established');
    
    const url = new URL(request.url, `http://${request.headers.host}`);
    const pathname = url.pathname;
    
    // Parse proxy path like _worker.js: /IP-PORT
    const proxyMatch = pathname.match(/^\/(.+[:=-]\d+)$/);
    if (!proxyMatch) {
        console.log('❌ Invalid proxy path:', pathname);
        ws.close();
        return;
    }
    
    const proxyInfo = proxyMatch[1];
    const [proxyIP, proxyPort] = proxyInfo.split(/[:=-]/);
    
    console.log(`🌐 Proxy connection: ${proxyIP}:${proxyPort}`);
    
    // Create TCP connection to proxy server
    const tcpSocket = new net.Socket();
    
    tcpSocket.connect(parseInt(proxyPort), proxyIP, () => {
        console.log(`✅ TCP connected to ${proxyIP}:${proxyPort}`);
    });
    
    // Handle WebSocket messages - forward to TCP
    ws.on('message', (data) => {
        try {
            // Forward raw data to TCP socket
            tcpSocket.write(data);
        } catch (error) {
            console.log(`❌ TCP write error: ${error.message}`);
            ws.close();
        }
    });
    
    // Handle TCP data - forward to WebSocket
    tcpSocket.on('data', (data) => {
        try {
            if (ws.readyState === WebSocket.OPEN) {
                ws.send(data);
            }
        } catch (error) {
            console.log(`❌ WebSocket send error: ${error.message}`);
        }
    });
    
    // Handle WebSocket close
    ws.on('close', () => {
        console.log('🔌 WebSocket connection closed');
        tcpSocket.destroy();
    });
    
    // Handle WebSocket error
    ws.on('error', (error) => {
        console.log(`❌ WebSocket error: ${error.message}`);
        tcpSocket.destroy();
    });
    
    // Handle TCP close
    tcpSocket.on('close', () => {
        console.log(`🔌 TCP connection to ${proxyIP}:${proxyPort} closed`);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
    });
    
    // Handle TCP error
    tcpSocket.on('error', (error) => {
        console.log(`❌ TCP error: ${error.message}`);
        if (ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
    });
});

// Handle WebSocket upgrade
server.on('upgrade', (request, socket, head) => {
    const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;
    
    // Check if it's a proxy path
    const proxyMatch = pathname.match(/^\/(.+[:=-]\d+)$/);
    if (proxyMatch) {
        console.log(`🔄 WebSocket upgrade for proxy: ${pathname}`);
        wss.handleUpgrade(request, socket, head, (ws) => {
            wss.emit('connection', ws, request);
        });
    } else {
        socket.destroy();
    }
});

// Load proxy list from GitHub
async function loadProxyList() {
    try {
        const proxyUrls = [
            'https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/proxyList.txt',
            'https://raw.githubusercontent.com/Ninadiantea/modevps/main/proxyList.txt',
            'https://raw.githubusercontent.com/mahdibland/ShadowsocksAggregator/master/sub/sub_merge.txt'
        ];

        for (const url of proxyUrls) {
            try {
                const response = await axios.get(url);
                const lines = response.data.split('\n').filter(line => line.trim());
                
                for (const line of lines) {
                    const parts = line.split(',');
                    if (parts.length >= 4) {
                        const [ip, port, country, org] = parts;
                        proxyList.push({
                            id: `${ip}-${port}`,
                            proxyIP: ip.trim(),
                            proxyPort: port.trim(),
                            country: country.trim(),
                            org: org.trim()
                        });
                    }
                }
                console.log(`✅ Loaded ${lines.length} proxies from ${url}`);
                break; // Use first successful source
            } catch (error) {
                console.log(`❌ Failed to load from ${url}: ${error.message}`);
            }
        }
        
        console.log(`📊 Total proxies loaded: ${proxyList.length}`);
    } catch (error) {
        console.log(`❌ Error loading proxy list: ${error.message}`);
    }
}

// Generate configuration from proxy
function generateConfigFromProxy(proxy, name) {
    const uuid = uuidv4();
    const domain = DOMAIN;
    const port = 443;
    
    // Get country flag emoji
    function getFlagEmoji(country) {
        const codePoints = country
            .toUpperCase()
            .split('')
            .map(char => 127397 + char.charCodeAt(0));
        return String.fromCodePoint(...codePoints);
    }
    
    const countryFlag = getFlagEmoji(proxy.country);
    
    // Build path like _worker.js: /IP-PORT
    const path = `/${proxy.proxyIP}-${proxy.proxyPort}`;
    
    // VLESS Configuration (matching _worker.js format)
    const vlessConfig = `vless://${uuid}@${domain}:${port}?encryption=none&type=ws&host=${domain}&security=tls&sni=${domain}&path=${encodeURIComponent(path)}#${countryFlag} VLESS WS TLS [${name}]`;
    
    // Trojan Configuration
    const trojanConfig = `trojan://${uuid}@${domain}:${port}?security=tls&type=ws&host=${domain}&path=${encodeURIComponent(path)}#${countryFlag} Trojan WS TLS [${name}]`;
    
    // Shadowsocks Configuration
    const ssConfig = `ss://${btoa(`none:${uuid}`)}@${domain}:${port}?plugin=v2ray-plugin;tls;mux=0;mode=websocket;path=${encodeURIComponent(path)};host=${domain}#${countryFlag} SS WS TLS [${name}]`;
    
    return {
        id: uuid,
        name,
        proxyName: `${proxy.proxyIP}:${proxy.proxyPort}`,
        proxyCountry: proxy.country,
        proxyOrg: proxy.org,
        type: 'multi',
        configs: {
            vless: vlessConfig,
            trojan: trojanConfig,
            shadowsocks: ssConfig
        }
    };
}

// API Routes
app.get('/health', (req, res) => {
    res.json({
        service: 'Nautica Proxy Server V2',
        status: 'running',
        domain: DOMAIN,
        port: PORT,
        accounts: accounts.length,
        proxies: proxyList.length
    });
});

app.get('/api/v1/proxies', (req, res) => {
    res.json({
        success: true,
        proxies: proxyList
    });
});

app.get('/api/v1/accounts', (req, res) => {
    res.json({
        success: true,
        accounts: accounts
    });
});

app.post('/api/v1/accounts', (req, res) => {
    try {
        const { name, proxyId } = req.body;
        
        if (!name || !proxyId) {
            return res.status(400).json({
                success: false,
                message: 'Name and proxyId are required'
            });
        }
        
        const proxy = proxyList.find(p => p.id === proxyId);
        if (!proxy) {
            return res.status(400).json({
                success: false,
                message: 'Proxy not found'
            });
        }
        
        const account = generateConfigFromProxy(proxy, name);
        accounts.push(account);
        
        res.json({
            success: true,
            account: account
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

app.delete('/api/v1/accounts/:id', (req, res) => {
    try {
        const { id } = req.params;
        const index = accounts.findIndex(account => account.id === id);
        
        if (index === -1) {
            return res.status(404).json({
                success: false,
                message: 'Account not found'
            });
        }
        
        accounts.splice(index, 1);
        
        res.json({
            success: true,
            message: 'Account deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT} (IPv4 only)`);
    console.log(`🌐 Domain: ${DOMAIN}`);
    console.log(`📊 Total accounts: ${accounts.length}`);
    console.log(`🔗 Loading proxy list...`);
    
    // Load proxy list on startup
    loadProxyList();
});
EOF

echo "✅ Fixed server.js created with raw TCP forwarding"

# Restart PM2 service
echo "🔄 Restarting PM2 service..."
pm2 restart nautica-proxy-v2
echo "💾 Saving PM2 configuration..."
pm2 save

echo ""
echo "✅ WebSocket handler fixed with raw TCP forwarding!"
echo ""
echo "📋 Changes made:"
echo "   - Replaced HTTP POST with raw TCP socket"
echo "   - Added proper TCP connection handling"
echo "   - Fixed data forwarding between WebSocket and TCP"
echo ""
echo "🔧 Verification commands:"
echo "   pm2 status"
echo "   pm2 logs nautica-proxy-v2"
echo "   curl -i -N -H 'Connection: Upgrade' -H 'Upgrade: websocket' https://bas.ahemmm.my.id/test"
echo ""