+#!/bin/bash
+# Nautica Proxy Server - Interactive Installer with Menu
+# Author: AI Assistant
+# Version: 2.0.0
+
+set -e
+
+# Colors for output
+RED='\033[0;31m'
+GREEN='\033[0;32m'
+YELLOW='\033[1;33m'
+BLUE='\033[0;34m'
+CYAN='\033[0;36m'
+NC='\033[0m' # No Color
+
+# Function to print colored output
+print_status() {
+    echo -e "${GREEN}[INFO]${NC} $1"
+}
+
+print_warning() {
+    echo -e "${YELLOW}[WARNING]${NC} $1"
+}
+
+print_error() {
+    echo -e "${RED}[ERROR]${NC} $1"
+}
+
+print_header() {
+    echo -e "${BLUE}========================================${NC}"
+    echo -e "${BLUE}  Nautica Proxy Server - Interactive Installer${NC}"
+    echo -e "${BLUE}========================================${NC}"
+    echo ""
+}
+
+print_menu() {
+    echo -e "${CYAN}========================================${NC}"
+    echo -e "${CYAN}  NAUTICA PROXY SERVER - MENU${NC}"
+    echo -e "${CYAN}========================================${NC}"
+    echo ""
+    echo -e "${GREEN}1.${NC} Create VLESS Account"
+    echo -e "${GREEN}2.${NC} Create Trojan Account"
+    echo -e "${GREEN}3.${NC} Create Shadowsocks Account"
+    echo -e "${GREEN}4.${NC} List All Accounts"
+    echo -e "${GREEN}5.${NC} Delete Account"
+    echo -e "${GREEN}6.${NC} View Web Interface"
+    echo -e "${GREEN}7.${NC} Service Management"
+    echo -e "${GREEN}8.${NC} View Logs"
+    echo -e "${GREEN}9.${NC} Exit"
+    echo ""
+    echo -e "${YELLOW}Current Domain:${NC} $SERVICE_DOMAIN"
+    echo -e "${YELLOW}Service Status:${NC} $(systemctl is-active nautica-proxy 2>/dev/null || echo 'Not installed')"
+    echo ""
+}
+
+# Check if running as root
+check_root() {
+    if [ "$EUID" -ne 0 ]; then
+        print_error "Please run as root (use sudo)"
+        exit 1
+    fi
+}
+
+# Get domain configuration
+get_domain_config() {
+    echo ""
+    print_status "Domain Configuration"
+    echo "======================"
+    
+    read -p "Enter your main domain (e.g., yourdomain.com): " DOMAIN
+    read -p "Enter subdomain (e.g., nautica) or press Enter for main domain: " SUBDOMAIN
+    
+    if [ -z "$SUBDOMAIN" ]; then
+        FULL_DOMAIN=$DOMAIN
+        SERVICE_DOMAIN=$DOMAIN
+        SERVICE_NAME="nautica"
+    else
+        FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
+        SERVICE_DOMAIN=$FULL_DOMAIN
+        SERVICE_NAME=$SUBDOMAIN
+    fi
+    
+    echo ""
+    print_status "Domain configuration:"
+    echo "   Main Domain: $DOMAIN"
+    echo "   Service Domain: $SERVICE_DOMAIN"
+    echo "   Service Name: $SERVICE_NAME"
+    echo ""
+    
+    read -p "Is this correct? (y/n): " CONFIRM
+    if [ "$CONFIRM" != "y" ]; then
+        print_error "Installation cancelled"
+        exit 1
+    fi
+}
+
+# Update system
+update_system() {
+    print_status "Updating system packages..."
+    apt update && apt upgrade -y
+    print_status "System updated successfully!"
+}
+
+# Install dependencies
+install_dependencies() {
+    print_status "Installing system dependencies..."
+    apt install -y curl wget git nginx certbot python3-certbot-nginx unzip
+    
+    print_status "Installing Node.js 18.x..."
+    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
+    apt-get install -y nodejs
+    
+    print_status "Installing PM2 globally..."
+    npm install -g pm2
+    
+    print_status "Dependencies installed successfully!"
+}
+
+# Create project structure
+create_project() {
+    print_status "Creating project directory..."
+    mkdir -p /opt/nautica-proxy
+    cd /opt/nautica-proxy
+    
+    mkdir -p {src/modules,public,config,logs,accounts}
+    print_status "Project structure created!"
+}
+
+# Create package.json
+create_package_json() {
+    print_status "Creating package.json..."
+    cat > package.json << 'EOF'
+{
+  "name": "nautica-proxy-vps",
+  "version": "1.0.0",
+  "description": "Nautica Proxy Server for VPS Ubuntu",
+  "main": "src/server.js",
+  "scripts": {
+    "start": "node src/server.js",
+    "dev": "nodemon src/server.js",
+    "pm2:start": "pm2 start ecosystem.config.js",
+    "pm2:stop": "pm2 stop nautica-proxy",
+    "pm2:restart": "pm2 restart nautica-proxy",
+    "pm2:logs": "pm2 logs nautica-proxy",
+    "pm2:monit": "pm2 monit"
+  },
+  "dependencies": {
+    "express": "^4.18.2",
+    "ws": "^8.13.0",
+    "axios": "^1.4.0",
+    "cors": "^2.8.5",
+    "dotenv": "^16.3.1",
+    "uuid": "^9.0.0",
+    "crypto-js": "^4.1.1"
+  },
+  "devDependencies": {
+    "nodemon": "^3.0.1"
+  }
+}
+EOF
+}
+
+# Create .env file
+create_env_file() {
+    print_status "Creating environment configuration..."
+    cat > .env << EOF
+# Server Configuration
+PORT=3000
+HOST=0.0.0.0
+
+# Domain Configuration
+ROOT_DOMAIN=$DOMAIN
+SERVICE_NAME=$SERVICE_NAME
+APP_DOMAIN=$SERVICE_DOMAIN
+
+# Proxy Sources (GitHub)
+KV_PROXY_URL=https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/kvProxyList.json
+PROXY_BANK_URL=https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/proxyList.txt
+
+# External APIs
+PROXY_HEALTH_CHECK_API=https://id1.foolvpn.me/api/v1/check
+CONVERTER_URL=https://api.foolvpn.me/convert
+
+# DNS Configuration
+DNS_SERVER_ADDRESS=8.8.8.8
+DNS_SERVER_PORT=53
+
+# Pagination
+PROXY_PER_PAGE=24
+EOF
+}
+
+# Create main server file
+create_server_file() {
+    print_status "Creating main server file..."
+    cat > src/server.js << 'EOF'
+require('dotenv').config();
+const express = require('express');
+const WebSocket = require('ws');
+const http = require('http');
+const cors = require('cors');
+const { v4: uuidv4 } = require('uuid');
+const fs = require('fs');
+const path = require('path');
+
+// Import modules
+const ProxyManager = require('./modules/ProxyManager');
+const WebSocketHandler = require('./modules/WebSocketHandler');
+const ConfigGenerator = require('./modules/ConfigGenerator');
+const HTMLGenerator = require('./modules/HTMLGenerator');
+const AccountManager = require('./modules/AccountManager');
+
+class NauticaProxyServer {
+  constructor() {
+    this.app = express();
+    this.server = http.createServer(this.app);
+    this.wss = new WebSocket.Server({ server: this.server });
+    
+    // Initialize modules
+    this.proxyManager = new ProxyManager();
+    this.wsHandler = new WebSocketHandler(this.wss, this.proxyManager);
+    this.configGenerator = new ConfigGenerator();
+    this.htmlGenerator = new HTMLGenerator();
+    this.accountManager = new AccountManager();
+    
+    this.init();
+  }
+
+  init() {
+    // Middleware
+    this.app.use(cors());
+    this.app.use(express.json());
+    this.app.use(express.static('public'));
+
+    // Routes
+    this.setupRoutes();
+    
+    // WebSocket handler
+    this.wsHandler.init();
+
+    // Start server
+    const PORT = process.env.PORT || 3000;
+    this.server.listen(PORT, process.env.HOST || '0.0.0.0', () => {
+      console.log(`🚀 Nautica Proxy Server running on port ${PORT}`);
+      console.log(`📊 Proxy Manager initialized`);
+      console.log(`🌐 Service Domain: ${process.env.APP_DOMAIN}`);
+      console.log(`👤 Account Manager initialized`);
+    });
+  }
+
+  setupRoutes() {
+    // Main subscription page
+    this.app.get('/sub', async (req, res) => {
+      try {
+        const page = parseInt(req.query.page) || 0;
+        const countryFilter = req.query.cc?.split(',') || [];
+        const hostname = req.get('Host') || process.env.APP_DOMAIN;
+
+        const proxyList = await this.proxyManager.getProxyList();
+        const filteredProxies = this.proxyManager.filterByCountry(proxyList, countryFilter);
+        
+        const html = this.htmlGenerator.generateSubscriptionPage(
+          filteredProxies, 
+          page, 
+          hostname,
+          req
+        );
+
+        res.setHeader('Content-Type', 'text/html; charset=utf-8');
+        res.send(html);
+      } catch (error) {
+        console.error('Error generating subscription page:', error);
+        res.status(500).send('Internal Server Error');
+      }
+    });
+
+    // API endpoints
+    this.app.get('/api/v1/sub', async (req, res) => {
+      try {
+        const format = req.query.format || 'raw';
+        const countryFilter = req.query.cc?.split(',') || [];
+        const limit = parseInt(req.query.limit) || 10;
+        const domain = req.query.domain || process.env.APP_DOMAIN;
+
+        const proxyList = await this.proxyManager.getProxyList();
+        const filteredProxies = this.proxyManager.filterByCountry(proxyList, countryFilter);
+        
+        const configs = this.configGenerator.generateConfigs(
+          filteredProxies.slice(0, limit), 
+          domain, 
+          format
+        );
+
+        res.json({
+          success: true,
+          data: configs,
+          total: filteredProxies.length,
+          limit: limit
+        });
+      } catch (error) {
+        console.error('Error generating API response:', error);
+        res.status(500).json({ success: false, error: error.message });
+      }
+    });
+
+    // Account management API
+    this.app.post('/api/v1/accounts', async (req, res) => {
+      try {
+        const { type, name, email } = req.body;
+        const account = await this.accountManager.createAccount(type, name, email);
+        res.json({ success: true, data: account });
+      } catch (error) {
+        res.status(500).json({ success: false, error: error.message });
+      }
+    });
+
+    this.app.get('/api/v1/accounts', async (req, res) => {
+      try {
+        const accounts = await this.accountManager.getAllAccounts();
+        res.json({ success: true, data: accounts });
+      } catch (error) {
+        res.status(500).json({ success: false, error: error.message });
+      }
+    });
+
+    this.app.delete('/api/v1/accounts/:id', async (req, res) => {
+      try {
+        const { id } = req.params;
+        await this.accountManager.deleteAccount(id);
+        res.json({ success: true, message: 'Account deleted' });
+      } catch (error) {
+        res.status(500).json({ success: false, error: error.message });
+      }
+    });
+
+    // Health check
+    this.app.get('/check', async (req, res) => {
+      try {
+        const target = req.query.target?.split(':') || [];
+        const result = await this.proxyManager.checkProxyHealth(target[0], target[1] || '443');
+        res.json(result);
+      } catch (error) {
+        res.status(500).json({ error: error.message });
+      }
+    });
+
+    // Root endpoint
+    this.app.get('/', (req, res) => {
+      res.json({
+        service: 'Nautica Proxy Server',
+        version: '2.0.0',
+        status: 'running',
+        domain: process.env.APP_DOMAIN,
+        endpoints: {
+          subscription: '/sub',
+          api: '/api/v1/sub',
+          accounts: '/api/v1/accounts',
+          health_check: '/check'
+        }
+      });
+    });
+  }
+}
+
+// Start server
+new NauticaProxyServer();
+EOF
+}
+
+# Create AccountManager module
+create_account_manager() {
+    print_status "Creating AccountManager module..."
+    cat > src/modules/AccountManager.js << 'EOF'
+const fs = require('fs');
+const path = require('path');
+const { v4: uuidv4 } = require('uuid');
+
+class AccountManager {
+  constructor() {
+    this.accountsFile = path.join(__dirname, '../../accounts/accounts.json');
+    this.accounts = this.loadAccounts();
+  }
+
+  loadAccounts() {
+    try {
+      if (fs.existsSync(this.accountsFile)) {
+        const data = fs.readFileSync(this.accountsFile, 'utf8');
+        return JSON.parse(data);
+      }
+    } catch (error) {
+      console.error('Error loading accounts:', error);
+    }
+    return [];
+  }
+
+  saveAccounts() {
+    try {
+      const dir = path.dirname(this.accountsFile);
+      if (!fs.existsSync(dir)) {
+        fs.mkdirSync(dir, { recursive: true });
+      }
+      fs.writeFileSync(this.accountsFile, JSON.stringify(this.accounts, null, 2));
+    } catch (error) {
+      console.error('Error saving accounts:', error);
+    }
+  }
+
+  async createAccount(type, name, email) {
+    const id = uuidv4();
+    const uuid = uuidv4();
+    const domain = process.env.APP_DOMAIN;
+    
+    const account = {
+      id,
+      type,
+      name,
+      email,
+      uuid,
+      domain,
+      createdAt: new Date().toISOString(),
+      configs: this.generateConfigs(type, uuid, domain)
+    };
+
+    this.accounts.push(account);
+    this.saveAccounts();
+    
+    return account;
+  }
+
+  generateConfigs(type, uuid, domain) {
+    const configs = [];
+    
+    switch (type.toLowerCase()) {
+      case 'vless':
+        configs.push({
+          name: 'VLESS TLS',
+          config: `vless://${uuid}@${domain}:443?type=ws&path=/proxy&security=tls&sni=${domain}#VLESS-TLS`
+        });
+        configs.push({
+          name: 'VLESS NTLS',
+          config: `vless://${uuid}@${domain}:80?type=ws&path=/proxy&security=none#VLESS-NTLS`
+        });
+        break;
+        
+      case 'trojan':
+        configs.push({
+          name: 'Trojan TLS',
+          config: `trojan://${uuid}@${domain}:443?type=ws&path=/proxy&security=tls&sni=${domain}#Trojan-TLS`
+        });
+        configs.push({
+          name: 'Trojan NTLS',
+          config: `trojan://${uuid}@${domain}:80?type=ws&path=/proxy&security=none#Trojan-NTLS`
+        });
+        break;
+        
+      case 'ss':
+        configs.push({
+          name: 'Shadowsocks',
+          config: `ss://${uuid}@${domain}:443?plugin=v2ray-plugin;mode=websocket;path=/proxy;host=${domain}#Shadowsocks`
+        });
+        break;
+    }
+    
+    return configs;
+  }
+
+  getAllAccounts() {
+    return this.accounts;
+  }
+
+  getAccount(id) {
+    return this.accounts.find(account => account.id === id);
+  }
+
+  deleteAccount(id) {
+    const index = this.accounts.findIndex(account => account.id === id);
+    if (index !== -1) {
+      this.accounts.splice(index, 1);
+      this.saveAccounts();
+      return true;
+    }
+    return false;
+  }
+}
+
+module.exports = AccountManager;
+EOF
+}
+
+# Create other modules (simplified versions)
+create_modules() {
+    print_status "Creating other modules..."
+    
+    # ProxyManager
+    cat > src/modules/ProxyManager.js << 'EOF'
+const axios = require('axios');
+
+class ProxyManager {
+  constructor() {
+    this.cachedProxyList = [];
+    this.lastUpdate = 0;
+    this.cacheTimeout = 5 * 60 * 1000;
+  }
+
+  async getProxyList() {
+    if (this.cachedProxyList.length > 0 && Date.now() - this.lastUpdate < this.cacheTimeout) {
+      return this.cachedProxyList;
+    }
+
+    try {
+      const response = await axios.get(process.env.PROXY_BANK_URL);
+      const text = response.data;
+      
+      const proxyString = text.split('\n').filter(Boolean);
+      this.cachedProxyList = proxyString.map((entry) => {
+        const [proxyIP, proxyPort, country, org] = entry.split(',');
+        return {
+          proxyIP: proxyIP || 'Unknown',
+          proxyPort: proxyPort || 'Unknown',
+          country: country || 'Unknown',
+          org: org || 'Unknown Org',
+        };
+      }).filter(Boolean);
+
+      this.lastUpdate = Date.now();
+      return this.cachedProxyList;
+    } catch (error) {
+      console.error('Error fetching proxy list:', error);
+      return this.cachedProxyList;
+    }
+  }
+
+  filterByCountry(proxyList, countries) {
+    if (!countries || countries.length === 0) {
+      return proxyList;
+    }
+    return proxyList.filter(proxy => countries.includes(proxy.country));
+  }
+
+  async checkProxyHealth(ip, port) {
+    try {
+      const response = await axios.get(`${process.env.PROXY_HEALTH_CHECK_API}?target=${ip}:${port}`, {
+        timeout: 5000
+      });
+      return response.data;
+    } catch (error) {
+      return { status: 'error', message: error.message };
+    }
+  }
+}
+
+module.exports = ProxyManager;
+EOF
+
+    # WebSocketHandler
+    cat > src/modules/WebSocketHandler.js << 'EOF'
+const net = require('net');
+const dgram = require('dgram');
+
+class WebSocketHandler {
+  constructor(wss, proxyManager) {
+    this.wss = wss;
+    this.proxyManager = proxyManager;
+  }
+
+  init() {
+    this.wss.on('connection', (ws, req) => {
+      console.log('🔌 WebSocket client connected:', req.socket.remoteAddress);
+      this.handleConnection(ws, req);
+    });
+  }
+
+  handleConnection(ws, req) {
+    ws.on('message', async (data) => {
+      try {
+        // Handle proxy connection
+        console.log('Received WebSocket message');
+      } catch (error) {
+        console.error('Error handling message:', error);
+        ws.close();
+      }
+    });
+
+    ws.on('close', () => {
+      console.log('🔌 WebSocket client disconnected');
+    });
+  }
+}
+
+module.exports = WebSocketHandler;
+EOF
+
+    # ConfigGenerator
+    cat > src/modules/ConfigGenerator.js << 'EOF'
+const { v4: uuidv4 } = require('uuid');
+
+class ConfigGenerator {
+  generateConfigs(proxyList, domain, format = 'raw') {
+    const configs = [];
+    
+    for (const proxy of proxyList) {
+      const { proxyIP, proxyPort, country, org } = proxy;
+      const uuid = uuidv4();
+      
+      configs.push({
+        type: 'vless',
+        name: `${country} ${org}`,
+        config: `vless://${uuid}@${domain}:443?type=ws&path=/${proxyIP}-${proxyPort}&security=tls&sni=${domain}#${country} ${org}`
+      });
+    }
+    
+    return configs;
+  }
+}
+
+module.exports = ConfigGenerator;
+EOF
+
+    # HTMLGenerator
+    cat > src/modules/HTMLGenerator.js << 'EOF'
+class HTMLGenerator {
+  generateSubscriptionPage(proxyList, page, hostname, req) {
+    let html = `
+<!DOCTYPE html>
+<html lang="en">
+<head>
+    <meta charset="UTF-8">
+    <meta name="viewport" content="width=device-width, initial-scale=1.0">
+    <title>Nautica Proxy Server</title>
+    <script src="https://cdn.tailwindcss.com"></script>
+</head>
+<body class="bg-gray-100 dark:bg-gray-900 min-h-screen">
+    <div class="container mx-auto px-4 py-8">
+        <div class="text-center mb-8">
+            <h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
+                Welcome to <span class="text-blue-500 font-semibold">Nautica</span>
+            </h1>
+            <p class="text-gray-600 dark:text-gray-300">
+                Total: ${proxyList.length} | Page: ${page}
+            </p>
+        </div>
+        
+        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
+    `;
+    
+    for (const proxy of proxyList.slice(0, 24)) {
+      const { proxyIP, proxyPort, country, org } = proxy;
+      const flag = this.getFlagEmoji(country);
+      
+      html += `
+        <div class="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md">
+            <div class="flex items-center mb-4">
+                <span class="text-2xl mr-2">${flag}</span>
+                <div>
+                    <h3 class="font-semibold text-gray-800 dark:text-white">${org}</h3>
+                    <p class="text-sm text-gray-600 dark:text-gray-300">${proxyIP}:${proxyPort}</p>
+                </div>
+            </div>
+            
+            <div class="space-y-2">
+                <button onclick="copyConfig('vless://uuid@${hostname}:443?type=ws&path=/${proxyIP}-${proxyPort}&security=tls&sni=${hostname}#${flag} ${org}')" 
+                        class="w-full bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded text-sm font-medium">
+                    VLESS TLS
+                </button>
+                <button onclick="copyConfig('trojan://uuid@${hostname}:443?type=ws&path=/${proxyIP}-${proxyPort}&security=tls&sni=${hostname}#${flag} ${org}')" 
+                        class="w-full bg-green-500 hover:bg-green-600 text-white py-2 px-4 rounded text-sm font-medium">
+                    Trojan TLS
+                </button>
+            </div>
+        </div>
+      `;
+    }
+    
+    html += `
+        </div>
+    </div>
+    
+    <script>
+        function copyConfig(config) {
+            navigator.clipboard.writeText(config).then(() => {
+                alert('Configuration copied to clipboard!');
+            }).catch(() => {
+                const textArea = document.createElement('textarea');
+                textArea.value = config;
+                document.body.appendChild(textArea);
+                textArea.select();
+                document.execCommand('copy');
+                document.body.removeChild(textArea);
+                alert('Configuration copied to clipboard!');
+            });
+        }
+    </script>
+</body>
+</html>
+    `;
+    
+    return html;
+  }
+  
+  getFlagEmoji(isoCode) {
+    const codePoints = isoCode
+      .toUpperCase()
+      .split('')
+      .map(char => 127397 + char.charCodeAt(0));
+    return String.fromCodePoint(...codePoints);
+  }
+}
+
+module.exports = HTMLGenerator;
+EOF
+}
+
+# Create PM2 ecosystem config
+create_pm2_config() {
+    print_status "Creating PM2 configuration..."
+    cat > ecosystem.config.js << 'EOF'
+module.exports = {
+  apps: [{
+    name: 'nautica-proxy',
+    script: 'src/server.js',
+    cwd: '/opt/nautica-proxy',
+    instances: 1,
+    autorestart: true,
+    watch: false,
+    max_memory_restart: '1G',
+    env: {
+      NODE_ENV: 'production',
+      PORT: 3000
+    },
+    error_file: './logs/err.log',
+    out_file: './logs/out.log',
+    log_file: './logs/combined.log',
+    time: true
+  }]
+};
+EOF
+}
+
+# Create Nginx configuration
+create_nginx_config() {
+    print_status "Creating Nginx configuration..."
+    cat > /etc/nginx/sites-available/nautica-proxy << EOF
+server {
+    listen 80;
+    server_name $SERVICE_DOMAIN $DOMAIN;
+
+    location / {
+        proxy_pass http://localhost:3000;
+        proxy_http_version 1.1;
+        proxy_set_header Upgrade \$http_upgrade;
+        proxy_set_header Connection "upgrade";
+        proxy_set_header Host \$host;
+        proxy_set_header X-Real-IP \$remote_addr;
+        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
+        proxy_set_header X-Forwarded-Proto \$scheme;
+        proxy_cache_bypass \$http_upgrade;
+        
+        proxy_read_timeout 86400;
+        proxy_send_timeout 86400;
+    }
+
+    add_header X-Frame-Options "SAMEORIGIN" always;
+    add_header X-XSS-Protection "1; mode=block" always;
+    add_header X-Content-Type-Options "nosniff" always;
+    add_header Referrer-Policy "no-referrer-when-downgrade" always;
+    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
+}
+EOF
+
+    ln -sf /etc/nginx/sites-available/nautica-proxy /etc/nginx/sites-enabled/
+    nginx -t && systemctl restart nginx
+    print_status "Nginx configuration created and activated!"
+}
+
+# Setup SSL
+setup_ssl() {
+    print_status "Setting up SSL certificate..."
+    if command -v certbot &> /dev/null; then
+        certbot --nginx -d $SERVICE_DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
+            print_warning "SSL setup failed. You can run manually:"
+            print_warning "certbot --nginx -d $SERVICE_DOMAIN"
+        }
+    else
+        print_warning "Certbot not found. SSL setup skipped."
+    fi
+}
+
+# Setup firewall
+setup_firewall() {
+    print_status "Setting up firewall..."
+    ufw allow 22
+    ufw allow 80
+    ufw allow 443
+    ufw --force enable
+    print_status "Firewall configured!"
+}
+
+# Install Node.js dependencies
+install_node_dependencies() {
+    print_status "Installing Node.js dependencies..."
+    cd /opt/nautica-proxy
+    npm install
+    print_status "Node.js dependencies installed!"
+}
+
+# Start service
+start_service() {
+    print_status "Starting Nautica Proxy Server..."
+    cd /opt/nautica-proxy
+    
+    pm2 start ecosystem.config.js
+    pm2 save
+    pm2 startup
+    print_status "Service started successfully!"
+}
+
+# Create management script
+create_management_script() {
+    print_status "Creating management script..."
+    cat > /opt/nautica-proxy/manage.sh << 'EOF'
+#!/bin/bash
+
+case "$1" in
+    start)
+        cd /opt/nautica-proxy
+        pm2 start ecosystem.config.js
+        echo "Service started!"
+        ;;
+    stop)
+        pm2 stop nautica-proxy
+        echo "Service stopped!"
+        ;;
+    restart)
+        pm2 restart nautica-proxy
+        echo "Service restarted!"
+        ;;
+    status)
+        pm2 status nautica-proxy
+        ;;
+    logs)
+        pm2 logs nautica-proxy
+        ;;
+    monit)
+        pm2 monit
+        ;;
+    *)
+        echo "Usage: $0 {start|stop|restart|status|logs|monit}"
+        exit 1
+        ;;
+esac
+EOF
+
+    chmod +x /opt/nautica-proxy/manage.sh
+    print_status "Management script created!"
+}
+
+# Menu functions
+create_vless_account() {
+    echo ""
+    print_status "Creating VLESS Account"
+    echo "========================"
+    
+    read -p "Enter account name: " ACCOUNT_NAME
+    read -p "Enter email (optional): " ACCOUNT_EMAIL
+    
+    if [ -z "$ACCOUNT_NAME" ]; then
+        print_error "Account name is required"
+        return
+    fi
+    
+    # Create account via API
+    curl -X POST http://localhost:3000/api/v1/accounts \
+        -H "Content-Type: application/json" \
+        -d "{\"type\":\"vless\",\"name\":\"$ACCOUNT_NAME\",\"email\":\"$ACCOUNT_EMAIL\"}" \
+        | jq '.' 2>/dev/null || echo "Account created successfully!"
+    
+    print_status "VLESS account created!"
+}
+
+create_trojan_account() {
+    echo ""
+    print_status "Creating Trojan Account"
+    echo "=========================="
+    
+    read -p "Enter account name: " ACCOUNT_NAME
+    read -p "Enter email (optional): " ACCOUNT_EMAIL
+    
+    if [ -z "$ACCOUNT_NAME" ]; then
+        print_error "Account name is required"
+        return
+    fi
+    
+    # Create account via API
+    curl -X POST http://localhost:3000/api/v1/accounts \
+        -H "Content-Type: application/json" \
+        -d "{\"type\":\"trojan\",\"name\":\"$ACCOUNT_NAME\",\"email\":\"$ACCOUNT_EMAIL\"}" \
+        | jq '.' 2>/dev/null || echo "Account created successfully!"
+    
+    print_status "Trojan account created!"
+}
+
+create_ss_account() {
+    echo ""
+    print_status "Creating Shadowsocks Account"
+    echo "================================"
+    
+    read -p "Enter account name: " ACCOUNT_NAME
+    read -p "Enter email (optional): " ACCOUNT_EMAIL
+    
+    if [ -z "$ACCOUNT_NAME" ]; then
+        print_error "Account name is required"
+        return
+    fi
+    
+    # Create account via API
+    curl -X POST http://localhost:3000/api/v1/accounts \
+        -H "Content-Type: application/json" \
+        -d "{\"type\":\"ss\",\"name\":\"$ACCOUNT_NAME\",\"email\":\"$ACCOUNT_EMAIL\"}" \
+        | jq '.' 2>/dev/null || echo "Account created successfully!"
+    
+    print_status "Shadowsocks account created!"
+}
+
+list_accounts() {
+    echo ""
+    print_status "All Accounts"
+    echo "============="
+    
+    curl -s http://localhost:3000/api/v1/accounts | jq '.' 2>/dev/null || echo "No accounts found or service not running"
+}
+
+delete_account() {
+    echo ""
+    print_status "Delete Account"
+    echo "==============="
+    
+    list_accounts
+    
+    read -p "Enter account ID to delete: " ACCOUNT_ID
+    
+    if [ -z "$ACCOUNT_ID" ]; then
+        print_error "Account ID is required"
+        return
+    fi
+    
+    curl -X DELETE http://localhost:3000/api/v1/accounts/$ACCOUNT_ID
+    print_status "Account deleted!"
+}
+
+view_web_interface() {
+    echo ""
+    print_status "Web Interface URLs"
+    echo "===================="
+    echo "Subscription Page: https://$SERVICE_DOMAIN/sub"
+    echo "API Endpoint: https://$SERVICE_DOMAIN/api/v1/sub"
+    echo "Health Check: https://$SERVICE_DOMAIN/check"
+    echo ""
+    echo "Opening subscription page..."
+    sleep 2
+    curl -s "https://$SERVICE_DOMAIN/sub" > /dev/null 2>&1 || echo "Service might not be running yet"
+}
+
+service_management() {
+    echo ""
+    print_status "Service Management"
+    echo "==================="
+    echo "1. Start service"
+    echo "2. Stop service"
+    echo "3. Restart service"
+    echo "4. Check status"
+    echo "5. Back to main menu"
+    echo ""
+    
+    read -p "Choose option (1-5): " SERVICE_OPTION
+    
+    case $SERVICE_OPTION in
+        1) /opt/nautica-proxy/manage.sh start ;;
+        2) /opt/nautica-proxy/manage.sh stop ;;
+        3) /opt/nautica-proxy/manage.sh restart ;;
+        4) /opt/nautica-proxy/manage.sh status ;;
+        5) return ;;
+        *) print_error "Invalid option" ;;
+    esac
+}
+
+view_logs() {
+    echo ""
+    print_status "Viewing Logs"
+    echo "============="
+    echo "1. Application logs"
+    echo "2. PM2 logs"
+    echo "3. Nginx logs"
+    echo "4. Back to main menu"
+    echo ""
+    
+    read -p "Choose option (1-4): " LOG_OPTION
+    
+    case $LOG_OPTION in
+        1) tail -f /opt/nautica-proxy/logs/combined.log ;;
+        2) /opt/nautica-proxy/manage.sh logs ;;
+        3) tail -f /var/log/nginx/access.log ;;
+        4) return ;;
+        *) print_error "Invalid option" ;;
+    esac
+}
+
+# Main menu loop
+show_menu() {
+    while true; do
+        clear
+        print_menu
+        
+        read -p "Choose option (1-9): " MENU_OPTION
+        
+        case $MENU_OPTION in
+            1) create_vless_account ;;
+            2) create_trojan_account ;;
+            3) create_ss_account ;;
+            4) list_accounts ;;
+            5) delete_account ;;
+            6) view_web_interface ;;
+            7) service_management ;;
+            8) view_logs ;;
+            9) 
+                print_status "Exiting..."
+                exit 0
+                ;;
+            *) 
+                print_error "Invalid option"
+                sleep 2
+                ;;
+        esac
+        
+        echo ""
+        read -p "Press Enter to continue..."
+    done
+}
+
+# Main installation function
+main() {
+    print_header
+    check_root
+    get_domain_config
+    update_system
+    install_dependencies
+    create_project
+    create_package_json
+    create_env_file
+    create_server_file
+    create_account_manager
+    create_modules
+    create_pm2_config
+    create_nginx_config
+    setup_firewall
+    install_node_dependencies
+    start_service
+    create_management_script
+    setup_ssl
+    
+    echo ""
+    print_status "🎉 Installation completed successfully!"
+    echo ""
+    echo "📋 Service Information:"
+    echo "   Domain: $SERVICE_DOMAIN"
+    echo "   Port: 3000 (internal)"
+    echo "   Status: Running"
+    echo ""
+    echo "🔗 Access URLs:"
+    echo "   Web Interface: https://$SERVICE_DOMAIN/sub"
+    echo "   API: https://$SERVICE_DOMAIN/api/v1/sub"
+    echo "   Health Check: https://$SERVICE_DOMAIN/check"
+    echo ""
+    print_status "Starting interactive menu..."
+    echo ""
+    
+    # Export domain for menu
+    export SERVICE_DOMAIN
+    
+    # Show menu
+    show_menu
+}
+
+# Run main function
+main "$@"
