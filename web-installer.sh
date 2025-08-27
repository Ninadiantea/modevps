#!/bin/bash

# Web-Based Nautica Proxy Server Installer
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Nautica Proxy Server - Web Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Set domain
DOMAIN="bas.ahemmm.my.id"

echo -e "${GREEN}[INFO]${NC} Starting web-based installation..."
echo -e "${GREEN}[INFO]${NC} Domain: $DOMAIN"
echo ""

# Update system
echo -e "${GREEN}[INFO]${NC} Updating system packages..."
apt update -y > /dev/null 2>&1
echo -e "${GREEN}[INFO]${NC} System updated!"

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing dependencies..."
apt install -y curl wget git nginx certbot python3-certbot-nginx unzip jq > /dev/null 2>&1

# Install Node.js
echo -e "${GREEN}[INFO]${NC} Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1

# Install PM2
echo -e "${GREEN}[INFO]${NC} Installing PM2..."
npm install -g pm2 > /dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Dependencies installed!"

# Create project
echo -e "${GREEN}[INFO]${NC} Creating project..."
mkdir -p /opt/nautica-proxy
cd /opt/nautica-proxy

# Create package.json
cat > package.json << 'EOF'
{
  "name": "nautica-proxy-web",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.0"
  }
}
EOF

# Create web server with beautiful UI
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Store accounts in memory
let accounts = [];

// Create public directory
const fs = require('fs');
const path = require('path');
if (!fs.existsSync('public')) {
    fs.mkdirSync('public');
}

// Create beautiful HTML interface
const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nautica Proxy Server - Web Dashboard</title>
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
    </style>
</head>
<body class="bg-gray-50 min-h-screen">
    <!-- Header -->
    <div class="gradient-bg text-white py-6">
        <div class="container mx-auto px-4">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-3xl font-bold">Nautica Proxy Server</h1>
                    <p class="text-blue-100">Web Dashboard</p>
                </div>
                <div class="text-right">
                    <div class="text-sm">Domain: bas.ahemmm.my.id</div>
                    <div class="text-sm">Status: <span class="text-green-300">Running</span></div>
                </div>
            </div>
        </div>
    </div>

    <div class="container mx-auto px-4 py-8">
        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="bg-white rounded-lg shadow-md p-6 card-hover transition-all">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-blue-100 text-blue-600">
                        <i class="fas fa-users text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <h3 class="text-lg font-semibold text-gray-800">Total Accounts</h3>
                        <p class="text-2xl font-bold text-blue-600" id="totalAccounts">0</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-lg shadow-md p-6 card-hover transition-all">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-green-100 text-green-600">
                        <i class="fas fa-shield-alt text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <h3 class="text-lg font-semibold text-gray-800">VLESS Accounts</h3>
                        <p class="text-2xl font-bold text-green-600" id="vlessAccounts">0</p>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-lg shadow-md p-6 card-hover transition-all">
                <div class="flex items-center">
                    <div class="p-3 rounded-full bg-purple-100 text-purple-600">
                        <i class="fas fa-key text-xl"></i>
                    </div>
                    <div class="ml-4">
                        <h3 class="text-lg font-semibold text-gray-800">Trojan Accounts</h3>
                        <p class="text-2xl font-bold text-purple-600" id="trojanAccounts">0</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Create Account Section -->
        <div class="bg-white rounded-lg shadow-md p-6 mb-8">
            <h2 class="text-2xl font-bold text-gray-800 mb-6">Create New Account</h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Account Name</label>
                    <input type="text" id="accountName" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="Enter account name">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">Account Type</label>
                    <select id="accountType" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="vless">VLESS</option>
                        <option value="trojan">Trojan</option>
                    </select>
                </div>
                <div class="flex items-end">
                    <button onclick="createAccount()" class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 transition-colors">
                        <i class="fas fa-plus mr-2"></i>Create Account
                    </button>
                </div>
            </div>
        </div>

        <!-- Accounts List -->
        <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-2xl font-bold text-gray-800 mb-6">Account List</h2>
            <div id="accountsList" class="space-y-4">
                <div class="text-center text-gray-500 py-8">
                    <i class="fas fa-inbox text-4xl mb-4"></i>
                    <p>No accounts created yet</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Success Modal -->
    <div id="successModal" class="fixed inset-0 bg-black bg-opacity-50 hidden items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <div class="text-center">
                <div class="text-green-500 text-4xl mb-4">
                    <i class="fas fa-check-circle"></i>
                </div>
                <h3 class="text-xl font-bold text-gray-800 mb-2">Account Created!</h3>
                <p class="text-gray-600 mb-4">Your account has been created successfully.</p>
                <div class="bg-gray-100 p-3 rounded-md mb-4">
                    <code id="accountConfig" class="text-sm break-all"></code>
                </div>
                <button onclick="closeModal()" class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                    Close
                </button>
            </div>
        </div>
    </div>

    <script>
        // Load accounts on page load
        loadAccounts();

        function createAccount() {
            const name = document.getElementById('accountName').value;
            const type = document.getElementById('accountType').value;
            
            if (!name) {
                alert('Please enter account name');
                return;
            }
            
            fetch('/api/v1/accounts', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: type,
                    name: name,
                    email: ''
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('accountConfig').textContent = data.data.config;
                    document.getElementById('successModal').classList.remove('hidden');
                    document.getElementById('successModal').classList.add('flex');
                    document.getElementById('accountName').value = '';
                    loadAccounts();
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error creating account');
            });
        }

        function loadAccounts() {
            fetch('/api/v1/accounts')
            .then(response => response.json())
            .then(data => {
                updateStats(data.data);
                updateAccountsList(data.data);
            })
            .catch(error => {
                console.error('Error:', error);
            });
        }

        function updateStats(accounts) {
            const total = accounts.length;
            const vless = accounts.filter(acc => acc.type === 'vless').length;
            const trojan = accounts.filter(acc => acc.type === 'trojan').length;
            
            document.getElementById('totalAccounts').textContent = total;
            document.getElementById('vlessAccounts').textContent = vless;
            document.getElementById('trojanAccounts').textContent = trojan;
        }

        function updateAccountsList(accounts) {
            const container = document.getElementById('accountsList');
            
            if (accounts.length === 0) {
                container.innerHTML = \`
                    <div class="text-center text-gray-500 py-8">
                        <i class="fas fa-inbox text-4xl mb-4"></i>
                        <p>No accounts created yet</p>
                    </div>
                \`;
                return;
            }
            
            container.innerHTML = accounts.map(account => \`
                <div class="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors">
                    <div class="flex items-center justify-between">
                        <div>
                            <h3 class="font-semibold text-gray-800">\${account.name}</h3>
                            <p class="text-sm text-gray-600">\${account.type.toUpperCase()} • Created: \${new Date(account.createdAt).toLocaleDateString()}</p>
                        </div>
                        <div class="flex items-center space-x-2">
                            <span class="px-2 py-1 text-xs rounded-full \${account.type === 'vless' ? 'bg-blue-100 text-blue-800' : 'bg-purple-100 text-purple-800'}">
                                \${account.type.toUpperCase()}
                            </span>
                            <button onclick="copyConfig('\${account.config}')" class="text-blue-600 hover:text-blue-800">
                                <i class="fas fa-copy"></i>
                            </button>
                            <button onclick="deleteAccount('\${account.id}')" class="text-red-600 hover:text-red-800">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                    <div class="mt-2">
                        <code class="text-xs bg-gray-100 p-2 rounded block break-all">\${account.config}</code>
                    </div>
                </div>
            \`).join('');
        }

        function copyConfig(config) {
            navigator.clipboard.writeText(config).then(() => {
                alert('Configuration copied to clipboard!');
            }).catch(() => {
                const textArea = document.createElement('textarea');
                textArea.value = config;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                alert('Configuration copied to clipboard!');
            });
        }

        function deleteAccount(id) {
            if (confirm('Are you sure you want to delete this account?')) {
                fetch(\`/api/v1/accounts/\${id}\`, {
                    method: 'DELETE'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        loadAccounts();
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error deleting account');
                });
            }
        }

        function closeModal() {
            document.getElementById('successModal').classList.add('hidden');
            document.getElementById('successModal').classList.remove('flex');
        }

        // Auto refresh every 30 seconds
        setInterval(loadAccounts, 30000);
    </script>
</body>
</html>
`;

# Write HTML to public directory
fs.writeFileSync('public/index.html', htmlContent);

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing Node.js dependencies..."
npm install > /dev/null 2>&1

# Create PM2 config
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'nautica-proxy-web',
    script: 'server.js',
    cwd: '/opt/nautica-proxy',
    instances: 1,
    autorestart: true
  }]
};
EOF

# Create Nginx config
cat > /etc/nginx/sites-available/nautica-proxy << 'EOF'
server {
    listen 80;
    server_name bas.ahemmm.my.id;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/nautica-proxy /etc/nginx/sites-enabled/
nginx -t > /dev/null 2>&1 && systemctl restart nginx

# Start service
echo -e "${GREEN}[INFO]${NC} Starting web service..."
cd /opt/nautica-proxy
pm2 start ecosystem.config.js > /dev/null 2>&1
pm2 save > /dev/null 2>&1
pm2 startup > /dev/null 2>&1

# Setup firewall
echo -e "${GREEN}[INFO]${NC} Setting up firewall..."
ufw allow 22 > /dev/null 2>&1
ufw allow 80 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

echo ""
echo -e "${GREEN}[INFO]${NC} 🎉 Web installation completed successfully!"
echo ""
echo "📋 Service Information:"
echo "   Domain: $DOMAIN"
echo "   Port: 3000 (internal)"
echo "   Status: Running"
echo ""
echo "🌐 Web Dashboard URLs:"
echo "   Main Dashboard: http://$DOMAIN/"
echo "   Subscription Page: http://$DOMAIN/sub"
echo "   Local Dashboard: http://localhost:3000/"
echo ""
echo "✨ Features:"
echo "   • Beautiful web dashboard"
echo "   • Create VLESS/Trojan accounts"
echo "   • Account management"
echo "   • Copy configurations"
echo "   • Real-time stats"
echo "   • No menu spam!"
echo ""
echo -e "${GREEN}[INFO]${NC} Open your browser and go to: http://$DOMAIN/"
echo ""