#!/bin/bash

# Nautica Proxy Server - Complete Installer (FIXED)
# Author: AI Assistant
# Version: 2.1 - Fixed Input Handling

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}"
echo "================================================"
echo "  NAUTICA PROXY SERVER - COMPLETE INSTALLER"
echo "================================================"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (use sudo)${NC}"
    exit 1
fi

# Get domain input with better handling
echo -e "${CYAN}🌐 Domain Configuration${NC}"
echo -e "${YELLOW}Enter your domain (e.g., yourdomain.com):${NC}"
echo -e "${YELLOW}Press Enter to use default: bas.ahemmm.my.id${NC}"

# Read domain with timeout and default
read -t 30 -p "Domain: " DOMAIN

# Set default if empty
if [ -z "$DOMAIN" ]; then
    DOMAIN="bas.ahemmm.my.id"
    echo -e "${GREEN}✅ Using default domain: ${CYAN}$DOMAIN${NC}"
else
    echo -e "${GREEN}✅ Domain set to: ${CYAN}$DOMAIN${NC}"
fi

echo ""
echo -e "${GREEN}✅ Domain confirmed: ${CYAN}$DOMAIN${NC}"
echo -e "${YELLOW}Starting installation in 3 seconds...${NC}"
sleep 3

# Update system
echo -e "${BLUE}📦 Updating system packages...${NC}"
apt update -y > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
echo -e "${GREEN}✅ System updated!${NC}"

# Install dependencies
echo -e "${BLUE}📦 Installing system dependencies...${NC}"
apt install -y curl wget git nginx certbot python3-certbot-nginx unzip jq ufw > /dev/null 2>&1
echo -e "${GREEN}✅ System dependencies installed!${NC}"

# Install Node.js
echo -e "${BLUE}📦 Installing Node.js 18.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt install -y nodejs > /dev/null 2>&1
echo -e "${GREEN}✅ Node.js installed!${NC}"

# Install PM2
echo -e "${BLUE}📦 Installing PM2...${NC}"
npm install -g pm2 > /dev/null 2>&1
echo -e "${GREEN}✅ PM2 installed!${NC}"

# Create project directory
echo -e "${BLUE}📁 Creating project directory...${NC}"
mkdir -p /opt/nautica-proxy
cd /opt/nautica-proxy

# Create package.json
echo -e "${BLUE}📦 Creating package.json...${NC}"
cat > package.json << 'EOF'
{
  "name": "nautica-proxy-server",
  "version": "2.0.0",
  "description": "Nautica Proxy Server with Web Dashboard",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.0",
    "axios": "^1.4.0",
    "ws": "^8.13.0",
    "dotenv": "^16.3.1",
    "crypto-js": "^4.1.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "keywords": ["proxy", "vless", "trojan", "shadowsocks"],
  "author": "Nautica Team",
  "license": "MIT"
}
EOF

# Create server.js
echo -e "${BLUE}📄 Creating server.js...${NC}"
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// In-memory storage for accounts
let accounts = [];

// Load existing accounts
const accountsFile = path.join(__dirname, 'accounts', 'accounts.json');
if (fs.existsSync(accountsFile)) {
    try {
        accounts = JSON.parse(fs.readFileSync(accountsFile, 'utf8'));
    } catch (error) {
        console.log('No existing accounts found, starting fresh');
    }
}

// Ensure accounts directory exists
const accountsDir = path.join(__dirname, 'accounts');
if (!fs.existsSync(accountsDir)) {
    fs.mkdirSync(accountsDir, { recursive: true });
}

// Save accounts to file
function saveAccounts() {
    fs.writeFileSync(accountsFile, JSON.stringify(accounts, null, 2));
}

// Generate configuration
function generateConfig(type, name, domain) {
    const id = uuidv4();
    const port = type === 'vless' ? 443 : 8443;
    
    if (type === 'vless') {
        return {
            id,
            name,
            type: 'vless',
            config: `vless://${id}@${domain}:${port}?type=ws&security=tls&path=/ws#${name}`,
            subscription: `vless://${id}@${domain}:${port}?type=ws&security=tls&path=/ws#${name}`
        };
    } else if (type === 'trojan') {
        return {
            id,
            name,
            type: 'trojan',
            config: `trojan://${id}@${domain}:${port}?security=tls&type=ws&path=/ws#${name}`,
            subscription: `trojan://${id}@${domain}:${port}?security=tls&type=ws&path=/ws#${name}`
        };
    }
}

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/sub', (req, res) => {
    const domain = process.env.DOMAIN || 'localhost';
    let subscription = '';
    
    accounts.forEach(account => {
        subscription += account.subscription + '\n';
    });
    
    res.setHeader('Content-Type', 'text/plain');
    res.send(subscription);
});

// API Routes
app.get('/api/v1/accounts', (req, res) => {
    res.json({
        success: true,
        data: accounts,
        stats: {
            total: accounts.length,
            vless: accounts.filter(a => a.type === 'vless').length,
            trojan: accounts.filter(a => a.type === 'trojan').length
        }
    });
});

app.post('/api/v1/accounts', (req, res) => {
    const { name, type } = req.body;
    const domain = process.env.DOMAIN || 'localhost';
    
    if (!name || !type) {
        return res.status(400).json({
            success: false,
            message: 'Name and type are required'
        });
    }
    
    if (!['vless', 'trojan'].includes(type)) {
        return res.status(400).json({
            success: false,
            message: 'Type must be vless or trojan'
        });
    }
    
    const config = generateConfig(type, name, domain);
    accounts.push(config);
    saveAccounts();
    
    res.json({
        success: true,
        message: 'Account created successfully',
        data: config
    });
});

app.delete('/api/v1/accounts/:id', (req, res) => {
    const { id } = req.params;
    const initialLength = accounts.length;
    accounts = accounts.filter(account => account.id !== id);
    
    if (accounts.length < initialLength) {
        saveAccounts();
        res.json({
            success: true,
            message: 'Account deleted successfully'
        });
    } else {
        res.status(404).json({
            success: false,
            message: 'Account not found'
        });
    }
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        service: 'Nautica Proxy Server',
        status: 'running',
        domain: process.env.DOMAIN || 'localhost',
        port: PORT,
        accounts: accounts.length
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🌐 Domain: ${process.env.DOMAIN || 'localhost'}`);
    console.log(`📊 Total accounts: ${accounts.length}`);
});
EOF

# Create public directory and index.html
echo -e "${BLUE}📄 Creating web dashboard...${NC}"
mkdir -p public

cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nautica Proxy Server - Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .gradient-bg {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .card-hover:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
        }
        .copy-btn {
            transition: all 0.3s ease;
        }
        .copy-btn:hover {
            background-color: #059669;
        }
        .delete-btn {
            transition: all 0.3s ease;
        }
        .delete-btn:hover {
            background-color: #dc2626;
        }
    </style>
</head>
<body class="bg-gray-50 min-h-screen">
    <!-- Header -->
    <header class="gradient-bg text-white shadow-lg">
        <div class="container mx-auto px-6 py-8">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-3xl font-bold">🌊 Nautica Proxy Server</h1>
                    <p class="text-blue-100 mt-2">Complete Proxy Management Dashboard</p>
                </div>
                <div class="text-right">
                    <div class="text-2xl font-bold" id="totalAccounts">0</div>
                    <div class="text-blue-100">Total Accounts</div>
                </div>
            </div>
        </div>
    </header>

    <!-- Stats Cards -->
    <div class="container mx-auto px-6 -mt-6">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-white rounded-lg shadow-md p-6 card-hover">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-blue-100 text-blue-600">
                        <i class="fas fa-shield-alt text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <div class="text-2xl font-bold text-gray-800" id="vlessCount">0</div>
                        <div class="text-gray-600">VLESS Accounts</div>
                    </div>
                </div>
            </div>
            <div class="bg-white rounded-lg shadow-md p-6 card-hover">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-green-100 text-green-600">
                        <i class="fas fa-lock text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <div class="text-2xl font-bold text-gray-800" id="trojanCount">0</div>
                        <div class="text-gray-600">Trojan Accounts</div>
                    </div>
                </div>
            </div>
            <div class="bg-white rounded-lg shadow-md p-6 card-hover">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-purple-100 text-purple-600">
                        <i class="fas fa-link text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <div class="text-lg font-bold text-gray-800" id="domain">localhost</div>
                        <div class="text-gray-600">Domain</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Main Content -->
    <div class="container mx-auto px-6">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Create Account Form -->
            <div class="lg:col-span-1">
                <div class="bg-white rounded-lg shadow-md p-6">
                    <h2 class="text-xl font-bold text-gray-800 mb-4">
                        <i class="fas fa-plus-circle text-blue-600 mr-2"></i>
                        Create New Account
                    </h2>
                    <form id="createForm" class="space-y-4">
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">Account Name</label>
                            <input type="text" id="accountName" required
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                                placeholder="Enter account name">
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">Account Type</label>
                            <select id="accountType" required
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="">Select type</option>
                                <option value="vless">VLESS</option>
                                <option value="trojan">Trojan</option>
                            </select>
                        </div>
                        <button type="submit"
                            class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition duration-200 font-medium">
                            <i class="fas fa-plus mr-2"></i>
                            Create Account
                        </button>
                    </form>
                </div>

                <!-- Quick Links -->
                <div class="bg-white rounded-lg shadow-md p-6 mt-6">
                    <h3 class="text-lg font-bold text-gray-800 mb-4">
                        <i class="fas fa-link text-green-600 mr-2"></i>
                        Quick Links
                    </h3>
                    <div class="space-y-3">
                        <a href="/sub" target="_blank"
                            class="flex items-center justify-between p-3 bg-gray-50 rounded-md hover:bg-gray-100 transition duration-200">
                            <span class="text-gray-700">
                                <i class="fas fa-download mr-2"></i>
                                Subscription URL
                            </span>
                            <i class="fas fa-external-link-alt text-gray-400"></i>
                        </a>
                        <a href="/health" target="_blank"
                            class="flex items-center justify-between p-3 bg-gray-50 rounded-md hover:bg-gray-100 transition duration-200">
                            <span class="text-gray-700">
                                <i class="fas fa-heartbeat mr-2"></i>
                                Health Check
                            </span>
                            <i class="fas fa-external-link-alt text-gray-400"></i>
                        </a>
                    </div>
                </div>
            </div>

            <!-- Accounts List -->
            <div class="lg:col-span-2">
                <div class="bg-white rounded-lg shadow-md">
                    <div class="p-6 border-b border-gray-200">
                        <h2 class="text-xl font-bold text-gray-800">
                            <i class="fas fa-list text-purple-600 mr-2"></i>
                            Account List
                        </h2>
                    </div>
                    <div class="p-6">
                        <div id="accountsList" class="space-y-4">
                            <div class="text-center text-gray-500 py-8">
                                <i class="fas fa-inbox text-4xl mb-4"></i>
                                <p>No accounts created yet</p>
                                <p class="text-sm">Create your first account using the form</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Toast Notification -->
    <div id="toast" class="fixed top-4 right-4 bg-green-500 text-white px-6 py-3 rounded-md shadow-lg transform translate-x-full transition-transform duration-300 z-50">
        <div class="flex items-center">
            <i class="fas fa-check-circle mr-2"></i>
            <span id="toastMessage">Success!</span>
        </div>
    </div>

    <script>
        let accounts = [];
        const domain = window.location.hostname;

        // Update domain display
        document.getElementById('domain').textContent = domain;

        // Show toast notification
        function showToast(message, type = 'success') {
            const toast = document.getElementById('toast');
            const toastMessage = document.getElementById('toastMessage');
            
            toast.className = `fixed top-4 right-4 px-6 py-3 rounded-md shadow-lg transform translate-x-full transition-transform duration-300 z-50 ${
                type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
            }`;
            
            toastMessage.textContent = message;
            toast.classList.remove('translate-x-full');
            
            setTimeout(() => {
                toast.classList.add('translate-x-full');
            }, 3000);
        }

        // Load accounts
        async function loadAccounts() {
            try {
                const response = await fetch('/api/v1/accounts');
                const data = await response.json();
                
                if (data.success) {
                    accounts = data.data;
                    updateStats();
                    renderAccounts();
                }
            } catch (error) {
                console.error('Error loading accounts:', error);
            }
        }

        // Update statistics
        function updateStats() {
            document.getElementById('totalAccounts').textContent = accounts.length;
            document.getElementById('vlessCount').textContent = accounts.filter(a => a.type === 'vless').length;
            document.getElementById('trojanCount').textContent = accounts.filter(a => a.type === 'trojan').length;
        }

        // Render accounts list
        function renderAccounts() {
            const accountsList = document.getElementById('accountsList');
            
            if (accounts.length === 0) {
                accountsList.innerHTML = `
                    <div class="text-center text-gray-500 py-8">
                        <i class="fas fa-inbox text-4xl mb-4"></i>
                        <p>No accounts created yet</p>
                        <p class="text-sm">Create your first account using the form</p>
                    </div>
                `;
                return;
            }
            
            accountsList.innerHTML = accounts.map(account => `
                <div class="border border-gray-200 rounded-lg p-4 hover:shadow-md transition duration-200">
                    <div class="flex items-center justify-between mb-3">
                        <div class="flex items-center">
                            <div class="w-10 h-10 rounded-full flex items-center justify-center ${
                                account.type === 'vless' ? 'bg-blue-100 text-blue-600' : 'bg-green-100 text-green-600'
                            }">
                                <i class="fas ${account.type === 'vless' ? 'fa-shield-alt' : 'fa-lock'}"></i>
                            </div>
                            <div class="ml-3">
                                <h3 class="font-semibold text-gray-800">${account.name}</h3>
                                <p class="text-sm text-gray-500 capitalize">${account.type}</p>
                            </div>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="copyConfig('${account.id}')" 
                                class="copy-btn bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700">
                                <i class="fas fa-copy mr-1"></i>
                                Copy
                            </button>
                            <button onclick="deleteAccount('${account.id}')" 
                                class="delete-btn bg-red-600 text-white px-3 py-1 rounded text-sm hover:bg-red-700">
                                <i class="fas fa-trash mr-1"></i>
                                Delete
                            </button>
                        </div>
                    </div>
                    <div class="bg-gray-50 rounded p-3">
                        <p class="text-xs text-gray-600 break-all">${account.config}</p>
                    </div>
                </div>
            `).join('');
        }

        // Create account
        document.getElementById('createForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const name = document.getElementById('accountName').value;
            const type = document.getElementById('accountType').value;
            
            try {
                const response = await fetch('/api/v1/accounts', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ name, type })
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

        // Copy configuration
        async function copyConfig(id) {
            const account = accounts.find(a => a.id === id);
            if (account) {
                try {
                    await navigator.clipboard.writeText(account.config);
                    showToast('Configuration copied to clipboard!');
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

        // Load accounts on page load
        loadAccounts();
    </script>
</body>
</html>
EOF

# Create ecosystem.config.js
echo -e "${BLUE}📄 Creating PM2 configuration...${NC}"
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'nautica-proxy',
    script: 'server.js',
    cwd: '/opt/nautica-proxy',
    env: {
      NODE_ENV: 'production',
      PORT: 3000,
      DOMAIN: '$DOMAIN'
    },
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    log_file: '/opt/nautica-proxy/logs/combined.log',
    out_file: '/opt/nautica-proxy/logs/out.log',
    error_file: '/opt/nautica-proxy/logs/error.log'
  }]
}
EOF

# Create logs directory
mkdir -p logs

# Install dependencies
echo -e "${BLUE}📦 Installing Node.js dependencies...${NC}"
npm install > /dev/null 2>&1
echo -e "${GREEN}✅ Dependencies installed!${NC}"

# Start PM2 service
echo -e "${BLUE}🚀 Starting service with PM2...${NC}"
pm2 start ecosystem.config.js > /dev/null 2>&1
pm2 save > /dev/null 2>&1
pm2 startup > /dev/null 2>&1
echo -e "${GREEN}✅ Service started!${NC}"

# Configure Nginx
echo -e "${BLUE}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/nautica-proxy << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/nautica-proxy /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and start Nginx
nginx -t > /dev/null 2>&1
if [ $? -eq 0 ]; then
    systemctl start nginx > /dev/null 2>&1
    systemctl enable nginx > /dev/null 2>&1
    echo -e "${GREEN}✅ Nginx configured and started!${NC}"
else
    echo -e "${RED}❌ Nginx configuration error${NC}"
    exit 1
fi

# Configure firewall
echo -e "${BLUE}🔥 Configuring firewall...${NC}"
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow ssh > /dev/null 2>&1
ufw allow 80 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
echo -e "${GREEN}✅ Firewall configured!${NC}"

# Setup SSL certificate
echo -e "${BLUE}🔒 Setting up SSL certificate...${NC}"
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate installed!${NC}"
    SSL_STATUS="✅ HTTPS Enabled"
    PROTOCOL="https"
else
    echo -e "${YELLOW}⚠️ SSL certificate failed, using HTTP${NC}"
    SSL_STATUS="⚠️ HTTP Only"
    PROTOCOL="http"
fi

# Test service
echo -e "${BLUE}🧪 Testing service...${NC}"
sleep 5
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ Service is running!${NC}"
else
    echo -e "${RED}❌ Service test failed${NC}"
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

# Final output
clear
echo -e "${BLUE}"
echo "================================================"
echo "  🎉 INSTALLATION COMPLETED SUCCESSFULLY!"
echo "================================================"
echo -e "${NC}"
echo ""
echo -e "${GREEN}✅ All components installed and configured!${NC}"
echo ""
echo -e "${CYAN}📋 Service Information:${NC}"
echo -e "   Domain: ${YELLOW}$DOMAIN${NC}"
echo -e "   Server IP: ${YELLOW}$SERVER_IP${NC}"
echo -e "   SSL Status: ${YELLOW}$SSL_STATUS${NC}"
echo -e "   Internal Port: ${YELLOW}3000${NC}"
echo ""
echo -e "${CYAN}🌐 Access URLs:${NC}"
echo -e "   Dashboard: ${GREEN}$PROTOCOL://$DOMAIN/${NC}"
echo -e "   Subscription: ${GREEN}$PROTOCOL://$DOMAIN/sub${NC}"
echo -e "   Health Check: ${GREEN}$PROTOCOL://$DOMAIN/health${NC}"
echo -e "   Local Access: ${GREEN}http://localhost:3000/${NC}"
echo ""
echo -e "${CYAN}🔧 Management Commands:${NC}"
echo -e "   View Logs: ${YELLOW}pm2 logs nautica-proxy${NC}"
echo -e "   Restart: ${YELLOW}pm2 restart nautica-proxy${NC}"
echo -e "   Status: ${YELLOW}pm2 status${NC}"
echo -e "   Stop: ${YELLOW}pm2 stop nautica-proxy${NC}"
echo ""
echo -e "${CYAN}✨ Features:${NC}"
echo -e "   • Beautiful web dashboard"
echo -e "   • Create VLESS/Trojan accounts"
echo -e "   • Account management"
echo -e "   • Copy configurations"
echo -e "   • Real-time statistics"
echo -e "   • Subscription URL"
echo -e "   • SSL certificate (if available)"
echo ""
echo -e "${GREEN}🚀 Your Nautica Proxy Server is ready!${NC}"
echo -e "${YELLOW}Open your browser and visit: $PROTOCOL://$DOMAIN/${NC}"
echo ""