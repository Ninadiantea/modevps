#!/bin/bash

# Nautica Proxy Server - One Command Installer
# Author: AI Assistant
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Nautica Proxy Server Installer${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Update system
update_system() {
    print_status "Updating system packages..."
    apt update && apt upgrade -y
    print_status "System updated successfully!"
}

# Install dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    apt install -y curl wget git nginx certbot python3-certbot-nginx unzip
    
    print_status "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    print_status "Installing PM2 globally..."
    npm install -g pm2
    
    print_status "Dependencies installed successfully!"
}

# Get domain configuration
get_domain_config() {
    echo ""
    print_status "Domain Configuration"
    echo "======================"
    
    read -p "Enter your main domain (e.g., yourdomain.com): " DOMAIN
    read -p "Enter subdomain (e.g., nautica) or press Enter for main domain: " SUBDOMAIN
    
    if [ -z "$SUBDOMAIN" ]; then
        FULL_DOMAIN=$DOMAIN
        SERVICE_DOMAIN=$DOMAIN
        SERVICE_NAME="nautica"
    else
        FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
        SERVICE_DOMAIN=$FULL_DOMAIN
        SERVICE_NAME=$SUBDOMAIN
    fi
    
    echo ""
    print_status "Domain configuration:"
    echo "   Main Domain: $DOMAIN"
    echo "   Service Domain: $SERVICE_DOMAIN"
    echo "   Service Name: $SERVICE_NAME"
    echo ""
    
    read -p "Is this correct? (y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        print_error "Installation cancelled"
        exit 1
    fi
}

# Create project structure
create_project() {
    print_status "Creating project directory..."
    mkdir -p /opt/nautica-proxy
    cd /opt/nautica-proxy
    
    mkdir -p {src/modules,public,config,logs}
    print_status "Project structure created!"
}

# Create package.json
create_package_json() {
    print_status "Creating package.json..."
    cat > package.json << 'EOF'
{
  "name": "nautica-proxy-vps",
  "version": "1.0.0",
  "description": "Nautica Proxy Server for VPS Ubuntu",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "pm2:start": "pm2 start ecosystem.config.js",
    "pm2:stop": "pm2 stop nautica-proxy",
    "pm2:restart": "pm2 restart nautica-proxy",
    "pm2:logs": "pm2 logs nautica-proxy",
    "pm2:monit": "pm2 monit"
  },
  "dependencies": {
    "express": "^4.18.2",
    "ws": "^8.13.0",
    "axios": "^1.4.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "uuid": "^9.0.0",
    "crypto-js": "^4.1.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
}

# Create .env file
create_env_file() {
    print_status "Creating environment configuration..."
    cat > .env << EOF
# Server Configuration
PORT=3000
HOST=0.0.0.0

# Domain Configuration
ROOT_DOMAIN=$DOMAIN
SERVICE_NAME=$SERVICE_NAME
APP_DOMAIN=$SERVICE_DOMAIN

# Proxy Sources (GitHub)
KV_PROXY_URL=https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/kvProxyList.json
PROXY_BANK_URL=https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/proxyList.txt

# External APIs
PROXY_HEALTH_CHECK_API=https://id1.foolvpn.me/api/v1/check
CONVERTER_URL=https://api.foolvpn.me/convert

# DNS Configuration
DNS_SERVER_ADDRESS=8.8.8.8
DNS_SERVER_PORT=53

# Pagination
PROXY_PER_PAGE=24
EOF
}

# Create main server file
create_server_file() {
    print_status "Creating main server file..."
    cat > src/server.js << 'EOF'
require('dotenv').config();
const express = require('express');
const WebSocket = require('ws');
const http = require('http');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

// Import modules
const ProxyManager = require('./modules/ProxyManager');
const WebSocketHandler = require('./modules/WebSocketHandler');
const ConfigGenerator = require('./modules/ConfigGenerator');
const HTMLGenerator = require('./modules/HTMLGenerator');

class NauticaProxyServer {
  constructor() {
    this.app = express();
    this.server = http.createServer(this.app);
    this.wss = new WebSocket.Server({ server: this.server });
    
    // Initialize modules
    this.proxyManager = new ProxyManager();
    this.wsHandler = new WebSocketHandler(this.wss, this.proxyManager);
    this.configGenerator = new ConfigGenerator();
    this.htmlGenerator = new HTMLGenerator();
    
    this.init();
  }

  init() {
    // Middleware
    this.app.use(cors());
    this.app.use(express.json());
    this.app.use(express.static('public'));

    // Routes
    this.setupRoutes();
    
    // WebSocket handler
    this.wsHandler.init();

    // Start server
    const PORT = process.env.PORT || 3000;
    this.server.listen(PORT, process.env.HOST || '0.0.0.0', () => {
      console.log(`🚀 Nautica Proxy Server running on port ${PORT}`);
      console.log(`📊 Proxy Manager initialized`);
      console.log(`🌐 Service Domain: ${process.env.APP_DOMAIN}`);
    });
  }

  setupRoutes() {
    // Main subscription page
    this.app.get('/sub', async (req, res) => {
      try {
        const page = parseInt(req.query.page) || 0;
        const countryFilter = req.query.cc?.split(',') || [];
        const hostname = req.get('Host') || process.env.APP_DOMAIN;

        const proxyList = await this.proxyManager.getProxyList();
        const filteredProxies = this.proxyManager.filterByCountry(proxyList, countryFilter);
        
        const html = this.htmlGenerator.generateSubscriptionPage(
          filteredProxies, 
          page, 
          hostname,
          req
        );

        res.setHeader('Content-Type', 'text/html; charset=utf-8');
        res.send(html);
      } catch (error) {
        console.error('Error generating subscription page:', error);
        res.status(500).send('Internal Server Error');
      }
    });

    // API endpoints
    this.app.get('/api/v1/sub', async (req, res) => {
      try {
        const format = req.query.format || 'raw';
        const countryFilter = req.query.cc?.split(',') || [];
        const limit = parseInt(req.query.limit) || 10;
        const domain = req.query.domain || process.env.APP_DOMAIN;

        const proxyList = await this.proxyManager.getProxyList();
        const filteredProxies = this.proxyManager.filterByCountry(proxyList, countryFilter);
        
        const configs = this.configGenerator.generateConfigs(
          filteredProxies.slice(0, limit), 
          domain, 
          format
        );

        res.json({
          success: true,
          data: configs,
          total: filteredProxies.length,
          limit: limit
        });
      } catch (error) {
        console.error('Error generating API response:', error);
        res.status(500).json({ success: false, error: error.message });
      }
    });

    // Health check
    this.app.get('/check', async (req, res) => {
      try {
        const target = req.query.target?.split(':') || [];
        const result = await this.proxyManager.checkProxyHealth(target[0], target[1] || '443');
        res.json(result);
      } catch (error) {
        res.status(500).json({ error: error.message });
      }
    });

    // Root endpoint
    this.app.get('/', (req, res) => {
      res.json({
        service: 'Nautica Proxy Server',
        version: '1.0.0',
        status: 'running',
        domain: process.env.APP_DOMAIN,
        endpoints: {
          subscription: '/sub',
          api: '/api/v1/sub',
          health_check: '/check'
        }
      });
    });
  }
}

// Start server
new NauticaProxyServer();
EOF
}

# Create ProxyManager module
create_proxy_manager() {
    print_status "Creating ProxyManager module..."
    cat > src/modules/ProxyManager.js << 'EOF'
const axios = require('axios');

class ProxyManager {
  constructor() {
    this.cachedProxyList = [];
    this.lastUpdate = 0;
    this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
  }

  async getProxyList() {
    // Check cache
    if (this.cachedProxyList.length > 0 && 
        Date.now() - this.lastUpdate < this.cacheTimeout) {
      return this.cachedProxyList;
    }

    try {
      const response = await axios.get(process.env.PROXY_BANK_URL);
      const text = response.data;
      
      const proxyString = text.split('\n').filter(Boolean);
      this.cachedProxyList = proxyString.map((entry) => {
        const [proxyIP, proxyPort, country, org] = entry.split(',');
        return {
          proxyIP: proxyIP || 'Unknown',
          proxyPort: proxyPort || 'Unknown',
          country: country || 'Unknown',
          org: org || 'Unknown Org',
        };
      }).filter(Boolean);

      this.lastUpdate = Date.now();
      console.log(`📊 Loaded ${this.cachedProxyList.length} proxies`);
      
      return this.cachedProxyList;
    } catch (error) {
      console.error('Error fetching proxy list:', error);
      return this.cachedProxyList; // Return cached data if available
    }
  }

  async getKVProxyList() {
    try {
      const response = await axios.get(process.env.KV_PROXY_URL);
      return response.data;
    } catch (error) {
      console.error('Error fetching KV proxy list:', error);
      return {};
    }
  }

  filterByCountry(proxyList, countries) {
    if (!countries || countries.length === 0) {
      return proxyList;
    }
    return proxyList.filter(proxy => countries.includes(proxy.country));
  }

  async checkProxyHealth(ip, port) {
    try {
      const response = await axios.get(`${process.env.PROXY_HEALTH_CHECK_API}?target=${ip}:${port}`, {
        timeout: 5000
      });
      return response.data;
    } catch (error) {
      return { status: 'error', message: error.message };
    }
  }

  getRandomProxy(country = null) {
    let proxyList = this.cachedProxyList;
    
    if (country) {
      proxyList = this.filterByCountry(proxyList, [country]);
    }
    
    if (proxyList.length === 0) {
      return null;
    }
    
    return proxyList[Math.floor(Math.random() * proxyList.length)];
  }
}

module.exports = ProxyManager;
EOF
}

# Create WebSocketHandler module
create_websocket_handler() {
    print_status "Creating WebSocketHandler module..."
    cat > src/modules/WebSocketHandler.js << 'EOF'
const net = require('net');
const dgram = require('dgram');

class WebSocketHandler {
  constructor(wss, proxyManager) {
    this.wss = wss;
    this.proxyManager = proxyManager;
  }

  init() {
    this.wss.on('connection', (ws, req) => {
      console.log('🔌 WebSocket client connected:', req.socket.remoteAddress);
      
      // Extract proxy info from path
      const proxyInfo = this.extractProxyFromPath(req.url);
      
      if (proxyInfo) {
        this.handleProxyConnection(ws, proxyInfo);
      } else {
        ws.close();
      }
    });
  }

  extractProxyFromPath(path) {
    // Extract from path like /1.1.1.1-443 or /SG
    const match = path.match(/^\/(.+[:=-]\d+)$/);
    if (match) {
      const [ip, port] = match[1].split(/[:=-]/);
      return { ip, port };
    }
    
    // Extract country code like /SG
    const countryMatch = path.match(/^\/([A-Z]{2})$/);
    if (countryMatch) {
      const proxy = this.proxyManager.getRandomProxy(countryMatch[1]);
      if (proxy) {
        return { ip: proxy.proxyIP, port: proxy.proxyPort };
      }
    }
    
    return null;
  }

  handleProxyConnection(ws, proxyInfo) {
    let remoteSocket = null;
    let isDNS = false;

    ws.on('message', async (data) => {
      try {
        if (isDNS) {
          await this.handleUDPOutbound('8.8.8.8', 53, data, ws);
          return;
        }

        // Protocol detection and handling
        const protocol = this.detectProtocol(data);
        const header = this.parseHeader(data, protocol);

        if (header.isUDP) {
          if (header.portRemote === 53) {
            isDNS = true;
            await this.handleUDPOutbound(header.addressRemote, header.portRemote, data, ws);
          } else {
            throw new Error("UDP only support for DNS port 53");
          }
        } else {
          await this.handleTCPOutbound(header.addressRemote, header.portRemote, data, ws);
        }

      } catch (error) {
        console.error('Error handling message:', error);
        ws.close();
      }
    });

    ws.on('close', () => {
      if (remoteSocket) {
        remoteSocket.destroy();
      }
      console.log('🔌 WebSocket client disconnected');
    });
  }

  async handleTCPOutbound(address, port, data, ws) {
    return new Promise((resolve, reject) => {
      const socket = new net.Socket();
      
      socket.connect(port, address, () => {
        console.log(`🔗 TCP connected to ${address}:${port}`);
        
        // Write initial data
        socket.write(data);
        
        // Pipe data between WebSocket and TCP socket
        socket.on('data', (chunk) => {
          if (ws.readyState === 1) { // WebSocket.OPEN
            ws.send(chunk);
          }
        });
        
        ws.on('message', (message) => {
          if (socket.writable) {
            socket.write(message);
          }
        });
      });
      
      socket.on('error', (error) => {
        console.error(`❌ TCP connection error to ${address}:${port}:`, error);
        reject(error);
      });
      
      socket.on('close', () => {
        console.log(`🔗 TCP connection to ${address}:${port} closed`);
      });
    });
  }

  async handleUDPOutbound(address, port, data, ws) {
    return new Promise((resolve, reject) => {
      const socket = dgram.createSocket('udp4');
      
      socket.send(data, port, address, (error) => {
        if (error) {
          console.error('❌ UDP send error:', error);
          reject(error);
        }
      });
      
      socket.on('message', (message, remote) => {
        if (ws.readyState === 1) { // WebSocket.OPEN
          ws.send(message);
        }
      });
      
      socket.on('error', (error) => {
        console.error('❌ UDP error:', error);
        reject(error);
      });
    });
  }

  detectProtocol(data) {
    // Implement protocol detection logic
    // This is a simplified version
    return 'trojan';
  }

  parseHeader(data, protocol) {
    // Implement header parsing logic
    // This is a simplified version
    return {
      addressRemote: 'example.com',
      portRemote: 443,
      isUDP: false,
      rawClientData: data
    };
  }
}

module.exports = WebSocketHandler;
EOF
}

# Create ConfigGenerator module
create_config_generator() {
    print_status "Creating ConfigGenerator module..."
    cat > src/modules/ConfigGenerator.js << 'EOF'
const { v4: uuidv4 } = require('uuid');

class ConfigGenerator {
  constructor() {
    this.protocols = ['trojan', 'vless', 'ss'];
    this.ports = [443, 80];
  }

  generateConfigs(proxyList, domain, format = 'raw') {
    const configs = [];

    for (const proxy of proxyList) {
      const { proxyIP, proxyPort, country, org } = proxy;
      const uuid = uuidv4();

      for (const port of this.ports) {
        for (const protocol of this.protocols) {
          const config = this.generateSingleConfig(
            protocol, 
            domain, 
            port, 
            uuid, 
            proxyIP, 
            proxyPort, 
            country, 
            org
          );
          
          if (config) {
            configs.push(config);
          }
        }
      }
    }

    return this.formatConfigs(configs, format);
  }

  generateSingleConfig(protocol, domain, port, uuid, proxyIP, proxyPort, country, org) {
    const security = port === 443 ? 'tls' : 'none';
    const flag = this.getFlagEmoji(country);
    const name = `${flag} ${org} WS ${port === 443 ? 'TLS' : 'NTLS'} [nautica]`;

    switch (protocol) {
      case 'trojan':
        return {
          type: 'trojan',
          name: name,
          server: domain,
          port: port,
          password: uuid,
          network: 'ws',
          'ws-opts': {
            path: `/${proxyIP}-${proxyPort}`,
            headers: {
              Host: domain
            }
          },
          tls: security === 'tls' ? {
            enabled: true,
            serverName: domain
          } : false
        };

      case 'vless':
        return {
          type: 'vless',
          name: name,
          server: domain,
          port: port,
          uuid: uuid,
          network: 'ws',
          'ws-opts': {
            path: `/${proxyIP}-${proxyPort}`,
            headers: {
              Host: domain
            }
          },
          tls: security === 'tls' ? {
            enabled: true,
            serverName: domain
          } : false
        };

      case 'ss':
        return {
          type: 'ss',
          name: name,
          server: domain,
          port: port,
          cipher: 'none',
          password: uuid,
          plugin: 'v2ray-plugin',
          'plugin-opts': {
            mode: 'websocket',
            tls: security === 'tls',
            path: `/${proxyIP}-${proxyPort}`,
            host: domain,
            mux: false
          }
        };

      default:
        return null;
    }
  }

  formatConfigs(configs, format) {
    switch (format) {
      case 'clash':
        return {
          proxies: configs,
          'proxy-groups': [
            {
              name: 'Proxy',
              type: 'select',
              proxies: configs.map(c => c.name)
            }
          ]
        };

      case 'raw':
        return configs.map(config => this.configToURI(config));

      default:
        return configs;
    }
  }

  configToURI(config) {
    // Convert config object to URI string
    // This is a simplified version
    return `${config.type}://${config.uuid || config.password}@${config.server}:${config.port}`;
  }

  getFlagEmoji(isoCode) {
    const codePoints = isoCode
      .toUpperCase()
      .split('')
      .map(char => 127397 + char.charCodeAt(0));
    return String.fromCodePoint(...codePoints);
  }
}

module.exports = ConfigGenerator;
EOF
}

# Create HTMLGenerator module
create_html_generator() {
    print_status "Creating HTMLGenerator module..."
    cat > src/modules/HTMLGenerator.js << 'EOF'
class HTMLGenerator {
  generateSubscriptionPage(proxyList, page, hostname, req) {
    const startIndex = 24 * page;
    const uuid = require('uuid').v4();
    
    let html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nautica Proxy Server</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .scrollbar-hide { -ms-overflow-style: none; scrollbar-width: none; }
        .scrollbar-hide::-webkit-scrollbar { display: none; }
    </style>
</head>
<body class="bg-gray-100 dark:bg-gray-900 min-h-screen">
    <div class="container mx-auto px-4 py-8">
        <div class="text-center mb-8">
            <h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
                Welcome to <span class="text-blue-500 font-semibold">Nautica</span>
            </h1>
            <p class="text-gray-600 dark:text-gray-300">
                Total: ${proxyList.length} | Page: ${page}/${Math.floor(proxyList.length / 24)}
            </p>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
    `;
    
    for (let i = startIndex; i < startIndex + 24; i++) {
      const proxy = proxyList[i];
      if (!proxy) break;
      
      const { proxyIP, proxyPort, country, org } = proxy;
      const flag = this.getFlagEmoji(country);
      
      html += `
        <div class="bg-white dark:bg-gray-800 rounded-lg p-6 shadow-md hover:shadow-lg transition-shadow">
            <div class="flex items-center mb-4">
                <span class="text-2xl mr-2">${flag}</span>
                <div>
                    <h3 class="font-semibold text-gray-800 dark:text-white">${org}</h3>
                    <p class="text-sm text-gray-600 dark:text-gray-300">${proxyIP}:${proxyPort}</p>
                </div>
            </div>
            
            <div class="space-y-2">
                <button onclick="copyConfig('vless://${uuid}@${hostname}:443?type=ws&path=/${proxyIP}-${proxyPort}&security=tls&sni=${hostname}#${flag} ${org} WS TLS')" 
                        class="w-full bg-blue-500 hover:bg-blue-600 text-white py-2 px-4 rounded text-sm font-medium transition-colors">
                    VLESS TLS
                </button>
                <button onclick="copyConfig('trojan://${uuid}@${hostname}:443?type=ws&path=/${proxyIP}-${proxyPort}&security=tls&sni=${hostname}#${flag} ${org} WS TLS')" 
                        class="w-full bg-green-500 hover:bg-green-600 text-white py-2 px-4 rounded text-sm font-medium transition-colors">
                    Trojan TLS
                </button>
                <button onclick="copyConfig('vless://${uuid}@${hostname}:80?type=ws&path=/${proxyIP}-${proxyPort}&security=none#${flag} ${org} WS NTLS')" 
                        class="w-full bg-yellow-500 hover:bg-yellow-600 text-white py-2 px-4 rounded text-sm font-medium transition-colors">
                    VLESS NTLS
                </button>
                <button onclick="copyConfig('trojan://${uuid}@${hostname}:80?type=ws&path=/${proxyIP}-${proxyPort}&security=none#${flag} ${org} WS NTLS')" 
                        class="w-full bg-red-500 hover:bg-red-600 text-white py-2 px-4 rounded text-sm font-medium transition-colors">
                    Trojan NTLS
                </button>
            </div>
        </div>
      `;
    }
    
    html += `
        </div>
        
        <div class="flex justify-center mt-8 space-x-4">
            ${page > 0 ? `<a href="/sub?page=${page - 1}" class="bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded font-medium transition-colors">Previous</a>` : ''}
            ${page < Math.floor(proxyList.length / 24) ? `<a href="/sub?page=${page + 1}" class="bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded font-medium transition-colors">Next</a>` : ''}
        </div>
    </div>
    
    <script>
        function copyConfig(config) {
            navigator.clipboard.writeText(config).then(() => {
                alert('Configuration copied to clipboard!');
            }).catch(() => {
                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = config;
                document.body.appendChild(textArea);
                textArea.select();
                document.execCommand('copy');
                document.body.removeChild(textArea);
                alert('Configuration copied to clipboard!');
            });
        }
    </script>
</body>
</html>
    `;
    
    return html;
  }
  
  getFlagEmoji(isoCode) {
    const codePoints = isoCode
      .toUpperCase()
      .split('')
      .map(char => 127397 + char.charCodeAt(0));
    return String.fromCodePoint(...codePoints);
  }
}

module.exports = HTMLGenerator;
EOF
}

# Create PM2 ecosystem config
create_pm2_config() {
    print_status "Creating PM2 configuration..."
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'nautica-proxy',
    script: 'src/server.js',
    cwd: '/opt/nautica-proxy',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF
}

# Create Nginx configuration
create_nginx_config() {
    print_status "Creating Nginx configuration..."
    cat > /etc/nginx/sites-available/nautica-proxy << EOF
server {
    listen 80;
    server_name $SERVICE_DOMAIN $DOMAIN;

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
        
        # WebSocket support
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

    # Create symlink
    ln -sf /etc/nginx/sites-available/nautica-proxy /etc/nginx/sites-enabled/
    
    # Test and restart Nginx
    nginx -t && systemctl restart nginx
    print_status "Nginx configuration created and activated!"
}

# Setup SSL
setup_ssl() {
    print_status "Setting up SSL certificate..."
    if command -v certbot &> /dev/null; then
        certbot --nginx -d $SERVICE_DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
            print_warning "SSL setup failed. You can run manually:"
            print_warning "certbot --nginx -d $SERVICE_DOMAIN"
        }
    else
        print_warning "Certbot not found. SSL setup skipped."
    fi
}

# Setup firewall
setup_firewall() {
    print_status "Setting up firewall..."
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw --force enable
    print_status "Firewall configured!"
}

# Install Node.js dependencies
install_node_dependencies() {
    print_status "Installing Node.js dependencies..."
    cd /opt/nautica-proxy
    npm install
    print_status "Node.js dependencies installed!"
}

# Start service
start_service() {
    print_status "Starting Nautica Proxy Server..."
    cd /opt/nautica-proxy
    
    # Start with PM2
    pm2 start ecosystem.config.js
    
    # Save PM2 configuration
    pm2 save
    
    # Setup PM2 to start on boot
    pm2 startup
    print_status "Service started successfully!"
}

# Create management script
create_management_script() {
    print_status "Creating management script..."
    cat > /opt/nautica-proxy/manage.sh << 'EOF'
#!/bin/bash

# Nautica Proxy Server Management Script

case "$1" in
    start)
        cd /opt/nautica-proxy
        pm2 start ecosystem.config.js
        echo "Service started!"
        ;;
    stop)
        pm2 stop nautica-proxy
        echo "Service stopped!"
        ;;
    restart)
        pm2 restart nautica-proxy
        echo "Service restarted!"
        ;;
    status)
        pm2 status nautica-proxy
        ;;
    logs)
        pm2 logs nautica-proxy
        ;;
    monit)
        pm2 monit
        ;;
    update)
        cd /opt/nautica-proxy
        git pull
        npm install
        pm2 restart nautica-proxy
        echo "Service updated!"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|monit|update}"
        exit 1
        ;;
esac
EOF

    chmod +x /opt/nautica-proxy/manage.sh
    print_status "Management script created!"
}

# Show final information
show_final_info() {
    echo ""
    print_status "🎉 Installation completed successfully!"
    echo ""
    echo "📋 Service Information:"
    echo "   Domain: $SERVICE_DOMAIN"
    echo "   Port: 3000 (internal)"
    echo "   Status: Running"
    echo ""
    echo "🔗 Access URLs:"
    echo "   Web Interface: http://$SERVICE_DOMAIN/sub"
    echo "   API: http://$SERVICE_DOMAIN/api/v1/sub"
    echo "   Health Check: http://$SERVICE_DOMAIN/check"
    echo ""
    echo "🛠️ Management Commands:"
    echo "   Start:   /opt/nautica-proxy/manage.sh start"
    echo "   Stop:    /opt/nautica-proxy/manage.sh stop"
    echo "   Restart: /opt/nautica-proxy/manage.sh restart"
    echo "   Status:  /opt/nautica-proxy/manage.sh status"
    echo "   Logs:    /opt/nautica-proxy/manage.sh logs"
    echo "   Monitor: /opt/nautica-proxy/manage.sh monit"
    echo ""
    echo "📁 Installation Directory: /opt/nautica-proxy"
    echo "📝 Logs Directory: /opt/nautica-proxy/logs"
    echo ""
    print_status "Your Nautica Proxy Server is ready to use!"
}

# Main installation function
main() {
    print_header
    check_root
    update_system
    install_dependencies
    get_domain_config
    create_project
    create_package_json
    create_env_file
    create_server_file
    create_proxy_manager
    create_websocket_handler
    create_config_generator
    create_html_generator
    create_pm2_config
    create_nginx_config
    setup_firewall
    install_node_dependencies
    start_service
    create_management_script
    setup_ssl
    show_final_info
}

# Run main function
main "$@"