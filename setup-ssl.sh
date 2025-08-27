#!/bin/bash

# Setup SSL Certificate with Let's Encrypt
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Setup SSL Certificate${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Installing Certbot..."
apt install -y certbot python3-certbot-nginx > /dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Checking Nginx status..."
if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}[ERROR]${NC} Nginx is not running"
    echo -e "${YELLOW}[INFO]${NC} Starting Nginx..."
    systemctl start nginx
fi

echo -e "${GREEN}[INFO]${NC} Testing domain accessibility..."
if curl -s http://bas.ahemmm.my.id/ > /dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Domain is accessible via HTTP"
else
    echo -e "${YELLOW}[WARNING]${NC} Domain might not be accessible"
    echo -e "${YELLOW}[INFO]${NC} Make sure domain points to this server IP"
    echo -e "${YELLOW}[INFO]${NC} Server IP: $(curl -s ifconfig.me)"
fi

echo ""
echo -e "${GREEN}[INFO]${NC} Setting up SSL certificate..."
echo -e "${YELLOW}[INFO]${NC} This will use Let's Encrypt to get SSL certificate"
echo ""

# Get SSL certificate
certbot --nginx -d bas.ahemmm.my.id --non-interactive --agree-tos --email admin@ahemmm.my.id

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} SSL certificate installed successfully!"
    echo ""
    echo "🌐 Access URLs:"
    echo "   HTTPS Dashboard: https://bas.ahemmm.my.id/"
    echo "   HTTPS Subscription: https://bas.ahemmm.my.id/sub"
    echo "   HTTPS API: https://bas.ahemmm.my.id/api/v1/accounts"
    echo ""
    echo "🔒 SSL Features:"
    echo "   • Automatic HTTPS redirect"
    echo "   • SSL certificate valid for 90 days"
    echo "   • Auto-renewal setup"
    echo ""
    echo -e "${GREEN}[INFO]${NC} SSL setup completed successfully!"
else
    echo ""
    echo -e "${RED}[ERROR]${NC} SSL certificate installation failed"
    echo -e "${YELLOW}[INFO]${NC} This could be due to:"
    echo "   • Domain not pointing to this server"
    echo "   • Cloudflare proxy enabled"
    echo "   • DNS propagation not complete"
    echo ""
    echo "🔧 Alternative Solutions:"
    echo "   1. Disable Cloudflare proxy (set to DNS only)"
    echo "   2. Wait for DNS propagation"
    echo "   3. Use local access: http://localhost:3000/"
fi