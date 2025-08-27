#!/bin/bash

# Install Nginx and Setup Reverse Proxy
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Install Nginx and Setup Reverse Proxy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Updating system packages..."
apt update -y > /dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Installing Nginx..."
apt install -y nginx > /dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Checking Nginx installation..."
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Nginx installed: $(nginx -v 2>&1)"
else
    echo -e "${RED}[ERROR]${NC} Nginx installation failed"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Creating Nginx configuration..."

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
        proxy_cache_bypass $http_upgrade;
        
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

echo -e "${GREEN}[INFO]${NC} Enabling site..."
ln -sf /etc/nginx/sites-available/nautica-proxy /etc/nginx/sites-enabled/

echo -e "${GREEN}[INFO]${NC} Removing default site..."
rm -f /etc/nginx/sites-enabled/default

echo -e "${GREEN}[INFO]${NC} Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Nginx configuration is valid"
    
    echo -e "${GREEN}[INFO]${NC} Starting Nginx..."
    systemctl start nginx
    
    echo -e "${GREEN}[INFO]${NC} Enabling Nginx to start on boot..."
    systemctl enable nginx
    
    echo -e "${GREEN}[INFO]${NC} Checking Nginx status..."
    systemctl status nginx --no-pager -l
    
    echo ""
    echo -e "${GREEN}[INFO]${NC} Setting up firewall..."
    ufw allow 22 > /dev/null 2>&1
    ufw allow 80 > /dev/null 2>&1
    ufw allow 443 > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    
    echo ""
    echo -e "${GREEN}[INFO]${NC} Testing local service..."
    if curl -s http://localhost:3000/ > /dev/null; then
        echo -e "${GREEN}[SUCCESS]${NC} Local service is running"
    else
        echo -e "${RED}[ERROR]${NC} Local service is not running"
        echo -e "${YELLOW}[INFO]${NC} Starting local service..."
        cd /opt/nautica-proxy
        pm2 start ecosystem.config.js > /dev/null 2>&1
        pm2 save > /dev/null 2>&1
    fi
    
    echo ""
    echo -e "${GREEN}[INFO]${NC} Getting server IP..."
    SERVER_IP=$(curl -s ifconfig.me)
    echo -e "${GREEN}[INFO]${NC} Server IP: $SERVER_IP"
    
    echo ""
    echo -e "${GREEN}[INFO]${NC} Testing domain access..."
    sleep 3
    
    if curl -s http://bas.ahemmm.my.id/ > /dev/null; then
        echo -e "${GREEN}[SUCCESS]${NC} Domain is accessible!"
        echo ""
        echo "🌐 Access URLs:"
        echo "   Main Dashboard: http://bas.ahemmm.my.id/"
        echo "   Subscription: http://bas.ahemmm.my.id/sub"
        echo "   API: http://bas.ahemmm.my.id/api/v1/accounts"
        echo ""
        echo -e "${GREEN}[INFO]${NC} Nginx setup completed successfully!"
    else
        echo -e "${YELLOW}[WARNING]${NC} Domain might not be accessible yet"
        echo -e "${YELLOW}[INFO]${NC} This could be due to:"
        echo "   • DNS propagation (wait a few minutes)"
        echo "   • Cloudflare settings"
        echo "   • Domain pointing to wrong IP"
        echo ""
        echo "🔧 Troubleshooting:"
        echo "   1. Check if domain points to this server IP: $SERVER_IP"
        echo "   2. Disable Cloudflare proxy (set to DNS only)"
        echo "   3. Wait for DNS propagation"
        echo ""
        echo "📱 Local access still works:"
        echo "   http://localhost:3000/"
        echo "   http://$SERVER_IP:3000/"
    fi
    
else
    echo -e "${RED}[ERROR]${NC} Nginx configuration is invalid"
    exit 1
fi