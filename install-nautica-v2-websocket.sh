#!/bin/bash

echo "================================================"
echo "  NAUTICA PROXY V2 - WEBSOCKET INSTALLER"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Domain configuration
echo "🌐 Domain Configuration"
echo "======================"
read -p "Enter your main domain (e.g., yourdomain.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain cannot be empty"
    exit 1
fi

echo "✅ Domain: $DOMAIN"
echo ""

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y
echo "✅ System updated!"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw

# Install Node.js
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install PM2
echo "📦 Installing PM2..."
npm install -g pm2

echo "✅ Dependencies installed!"
echo ""

# Create project directory
echo "📁 Creating project..."
mkdir -p /opt/nautica-proxy-v2
cd /opt/nautica-proxy-v2

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "nautica-proxy-v2",
  "version": "3.0.0",
  "description": "Nautica Proxy Server V2 with WebSocket Support",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.14.2",
    "axios": "^1.5.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "uuid": "^9.0.0",
    "crypto-js": "^4.1.1",
    "nodemon": "^3.0.1"
  },
  "keywords": ["proxy", "vless", "trojan", "shadowsocks", "websocket"],
  "author": "Nautica Team",
  "license": "MIT"
}
EOF

# Create server.js with WebSocket support
echo "🔧 Creating server.js with WebSocket handler..."
cat > server.js << 'EOF'
const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const cors = require('cors');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
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
    
    // Handle WebSocket proxy traffic
    ws.on('message', async (data) => {
        try {
            // Forward data to proxy server
            const proxyResponse = await axios({
                method: 'POST',
                url: `http://${proxyIP}:${proxyPort}`,
                data: data,
                responseType: 'arraybuffer',
                timeout: 5000
            });
            
            // Send response back to client
            ws.send(proxyResponse.data);
        } catch (error) {
            console.log(`❌ Proxy error: ${error.message}`);
            ws.close();
        }
    });
    
    ws.on('close', () => {
        console.log('🔌 WebSocket connection closed');
    });
    
    ws.on('error', (error) => {
        console.log(`❌ WebSocket error: ${error.message}`);
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

# Create public directory and index.html
echo "🌐 Creating web dashboard..."
mkdir -p public

cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nautica Proxy V2 - Web Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .toast {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 8px;
            color: white;
            font-weight: bold;
            z-index: 1000;
            transition: opacity 0.3s;
        }
        .toast-success { background-color: #10b981; }
        .toast-error { background-color: #ef4444; }
    </style>
</head>
<body class="bg-gray-100 min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <div class="bg-white rounded-lg shadow-lg p-6 mb-8">
            <h1 class="text-3xl font-bold text-gray-800 mb-4">🌊 Nautica Proxy V2</h1>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div class="bg-blue-50 p-3 rounded">
                    <span class="font-semibold">Domain:</span> <span id="domain">Loading...</span>
                </div>
                <div class="bg-green-50 p-3 rounded">
                    <span class="font-semibold">Status:</span> <span id="status">Loading...</span>
                </div>
                <div class="bg-purple-50 p-3 rounded">
                    <span class="font-semibold">Accounts:</span> <span id="accountCount">Loading...</span>
                </div>
            </div>
        </div>

        <!-- Create Account Form -->
        <div class="bg-white rounded-lg shadow-lg p-6 mb-8">
            <h2 class="text-2xl font-bold text-gray-800 mb-4">📝 Create Account</h2>
            <form id="createForm" class="space-y-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Account Name</label>
                    <input type="text" id="accountName" name="name" required 
                           class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                           placeholder="Enter account name">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Select Proxy</label>
                    <select id="proxySelect" name="proxyId" required 
                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="">Loading proxies...</option>
                    </select>
                </div>
                <button type="submit" 
                        class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors">
                    Create Account
                </button>
            </form>
        </div>

        <!-- Accounts List -->
        <div class="bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-2xl font-bold text-gray-800 mb-4">📋 Accounts List</h2>
            <div id="accountsList" class="space-y-4">
                <p class="text-gray-500">Loading accounts...</p>
            </div>
        </div>
    </div>

    <script>
        let accounts = [];

        // Show toast notification
        function showToast(message, type = 'success') {
            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;
            toast.textContent = message;
            document.body.appendChild(toast);
            setTimeout(() => toast.remove(), 3000);
        }

        // Load health status
        async function loadHealth() {
            try {
                const response = await fetch('/health');
                const data = await response.json();
                document.getElementById('domain').textContent = data.domain;
                document.getElementById('status').textContent = data.status;
                document.getElementById('accountCount').textContent = data.accounts;
            } catch (error) {
                console.error('Error loading health:', error);
            }
        }

        // Load proxies
        async function loadProxies() {
            try {
                const response = await fetch('/api/v1/proxies');
                const data = await response.json();
                if (data.success) {
                    const select = document.getElementById('proxySelect');
                    select.innerHTML = '<option value="">Select a proxy...</option>';
                    
                    data.proxies.forEach(proxy => {
                        const option = document.createElement('option');
                        option.value = proxy.id;
                        option.textContent = `${proxy.proxyIP}:${proxy.proxyPort} (${proxy.country}) - ${proxy.org}`;
                        select.appendChild(option);
                    });
                }
            } catch (error) {
                console.error('Error loading proxies:', error);
            }
        }

        // Load accounts
        async function loadAccounts() {
            try {
                const response = await fetch('/api/v1/accounts');
                const data = await response.json();
                if (data.success) {
                    accounts = data.accounts;
                    displayAccounts();
                }
            } catch (error) {
                console.error('Error loading accounts:', error);
            }
        }

        // Display accounts
        function displayAccounts() {
            const container = document.getElementById('accountsList');
            if (accounts.length === 0) {
                container.innerHTML = '<p class="text-gray-500">No accounts created yet.</p>';
                return;
            }

            container.innerHTML = accounts.map(account => `
                <div class="border border-gray-200 rounded-lg p-4">
                    <div class="flex justify-between items-start mb-3">
                        <div>
                            <h3 class="font-semibold text-lg">${account.name}</h3>
                            <p class="text-sm text-gray-600">Proxy: ${account.proxyName} (${account.proxyCountry})</p>
                            <p class="text-sm text-gray-600">Org: ${account.proxyOrg}</p>
                        </div>
                        <button onclick="deleteAccount('${account.id}')" 
                                class="bg-red-600 text-white px-3 py-1 rounded text-sm hover:bg-red-700">
                            Delete
                        </button>
                    </div>
                    <div class="space-y-2">
                        <div class="flex items-center justify-between">
                            <span class="text-sm font-medium">VLESS:</span>
                            <button onclick="copyConfig('${account.id}', 'vless')" 
                                    class="bg-blue-600 text-white px-2 py-1 rounded text-xs hover:bg-blue-700">
                                Copy
                            </button>
                        </div>
                        <div class="flex items-center justify-between">
                            <span class="text-sm font-medium">Trojan:</span>
                            <button onclick="copyConfig('${account.id}', 'trojan')" 
                                    class="bg-green-600 text-white px-2 py-1 rounded text-xs hover:bg-green-700">
                                Copy
                            </button>
                        </div>
                        <div class="flex items-center justify-between">
                            <span class="text-sm font-medium">Shadowsocks:</span>
                            <button onclick="copyConfig('${account.id}', 'shadowsocks')" 
                                    class="bg-purple-600 text-white px-2 py-1 rounded text-xs hover:bg-purple-700">
                                Copy
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        }

        // Copy configuration
        async function copyConfig(accountId, type) {
            const account = accounts.find(a => a.id === accountId);
            if (account && account.configs[type]) {
                try {
                    await navigator.clipboard.writeText(account.configs[type]);
                    showToast(`${type.toUpperCase()} configuration copied!`);
                } catch (error) {
                    showToast('Failed to copy configuration', 'error');
                }
            }
        }

        // Delete account
        async function deleteAccount(id) {
            if (!confirm('Are you sure you want to delete this account?')) {
                return;
            }
            try {
                const response = await fetch(`/api/v1/accounts/${id}`, {
                    method: 'DELETE'
                });
                const data = await response.json();
                if (data.success) {
                    showToast('Account deleted successfully!');
                    loadAccounts();
                } else {
                    showToast(data.message, 'error');
                }
            } catch (error) {
                showToast('Error deleting account', 'error');
            }
        }

        // Create account form handler
        document.getElementById('createForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const name = formData.get('name');
            const proxyId = formData.get('proxyId');

            try {
                const response = await fetch('/api/v1/accounts', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ name, proxyId })
                });
                const data = await response.json();
                if (data.success) {
                    showToast('Account created successfully!');
                    document.getElementById('createForm').reset();
                    loadAccounts();
                } else {
                    showToast(data.message, 'error');
                }
            } catch (error) {
                showToast('Error creating account', 'error');
            }
        });

        // Load data on page load
        loadHealth();
        loadProxies();
        loadAccounts();
    </script>
</body>
</html>
EOF

# Create .env file
echo "⚙️ Creating environment file..."
cat > .env << EOF
PORT=3000
DOMAIN=$DOMAIN
EOF

# Create PM2 ecosystem config
echo "📋 Creating PM2 config..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'nautica-proxy-v2',
    script: 'server.js',
    cwd: '/opt/nautica-proxy-v2',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      DOMAIN: process.env.DOMAIN || 'localhost'
    },
    log_file: '/var/log/nautica-proxy-v2.log',
    out_file: '/var/log/nautica-proxy-v2-out.log',
    error_file: '/var/log/nautica-proxy-v2-error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G'
  }]
};
EOF

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/nautica-proxy-v2 << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/nautica-proxy-v2 /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t

# Setup SSL
echo "🔒 Setting up SSL certificate..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80
ufw allow 443
ufw --force enable

# Start service
echo "🚀 Starting service..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Final status
echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "📋 Service Information:"
echo "   Domain: https://$DOMAIN"
echo "   Dashboard: https://$DOMAIN/"
echo "   Health Check: https://$DOMAIN/health"
echo "   API: https://$DOMAIN/api/v1/"
echo ""
echo "🔧 Management Commands:"
echo "   Status: pm2 status"
echo "   Logs: pm2 logs nautica-proxy-v2"
echo "   Restart: pm2 restart nautica-proxy-v2"
echo ""
echo "✅ WebSocket handler is included and ready!"
echo "✅ Proxy traffic will be handled automatically!"
echo ""