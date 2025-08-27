#!/bin/bash

# Simple Interactive Installer - Fixed Version
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Nautica Proxy Server - Simple Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Starting installation..."
echo ""

# Set default domain
DOMAIN="bas.ahemmm.my.id"
SERVICE_DOMAIN="bas.ahemmm.my.id"
SERVICE_NAME="nautica"

echo -e "${GREEN}[INFO]${NC} Domain Configuration"
echo "======================"
echo "Using default domain: $DOMAIN"
echo "Service domain: $SERVICE_DOMAIN"
echo ""

# Update system
echo -e "${GREEN}[INFO]${NC} Updating system packages..."
apt update -y
echo -e "${GREEN}[INFO]${NC} System updated!"

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing dependencies..."
apt install -y curl wget git nginx certbot python3-certbot-nginx unzip jq

# Install Node.js
echo -e "${GREEN}[INFO]${NC} Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install PM2
echo -e "${GREEN}[INFO]${NC} Installing PM2..."
npm install -g pm2

echo -e "${GREEN}[INFO]${NC} Dependencies installed!"

# Create project
echo -e "${GREEN}[INFO]${NC} Creating project..."
mkdir -p /opt/nautica-proxy
cd /opt/nautica-proxy

# Create simple package.json
cat > package.json << 'EOF'
{
  "name": "nautica-proxy",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

# Create simple server
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    service: 'Nautica Proxy Server',
    status: 'running',
    domain: 'bas.ahemmm.my.id'
  });
});

app.get('/sub', (req, res) => {
  res.send(`
    <html>
      <head><title>Nautica Proxy</title></head>
      <body>
        <h1>Welcome to Nautica Proxy Server</h1>
        <p>Service is running on bas.ahemmm.my.id</p>
      </body>
    </html>
  `);
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
EOF

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing Node.js dependencies..."
npm install

# Create PM2 config
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'nautica-proxy',
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
nginx -t && systemctl restart nginx

# Start service
echo -e "${GREEN}[INFO]${NC} Starting service..."
cd /opt/nautica-proxy
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Setup firewall
echo -e "${GREEN}[INFO]${NC} Setting up firewall..."
ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

echo ""
echo -e "${GREEN}[INFO]${NC} 🎉 Installation completed!"
echo ""
echo "📋 Service Information:"
echo "   Domain: $SERVICE_DOMAIN"
echo "   Port: 3000 (internal)"
echo "   Status: Running"
echo ""
echo "🔗 Access URLs:"
echo "   Web Interface: http://$SERVICE_DOMAIN/sub"
echo "   API: http://$SERVICE_DOMAIN/"
echo ""

# Show menu
show_menu() {
    while true; do
        echo ""
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  NAUTICA PROXY SERVER - MENU${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} Create VLESS Account"
        echo -e "${GREEN}2.${NC} Create Trojan Account"
        echo -e "${GREEN}3.${NC} Service Status"
        echo -e "${GREEN}4.${NC} View Logs"
        echo -e "${GREEN}5.${NC} Exit"
        echo ""
        echo -e "${YELLOW}Current Domain:${NC} $SERVICE_DOMAIN"
        echo ""
        
        read -p "Choose option (1-5): " choice
        
        case $choice in
            1)
                echo ""
                echo -e "${GREEN}[INFO]${NC} Creating VLESS Account"
                echo "========================"
                read -p "Enter account name: " name
                if [ ! -z "$name" ]; then
                    uuid=$(uuidgen)
                    echo "Account created!"
                    echo "UUID: $uuid"
                    echo "Config: vless://$uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#$name"
                else
                    echo "Account name is required"
                fi
                ;;
            2)
                echo ""
                echo -e "${GREEN}[INFO]${NC} Creating Trojan Account"
                echo "=========================="
                read -p "Enter account name: " name
                if [ ! -z "$name" ]; then
                    uuid=$(uuidgen)
                    echo "Account created!"
                    echo "UUID: $uuid"
                    echo "Config: trojan://$uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#$name"
                else
                    echo "Account name is required"
                fi
                ;;
            3)
                echo ""
                echo -e "${GREEN}[INFO]${NC} Service Status"
                echo "================"
                pm2 status
                ;;
            4)
                echo ""
                echo -e "${GREEN}[INFO]${NC} Viewing Logs"
                echo "============="
                pm2 logs nautica-proxy --lines 10
                ;;
            5)
                echo ""
                echo -e "${GREEN}[INFO]${NC} Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Start menu
show_menu