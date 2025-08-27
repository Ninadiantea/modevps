#!/bin/bash

# Quick Setup for Nautica Proxy Server
# Author: AI Assistant

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Check git
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install git first:"
    print_error "sudo apt update && sudo apt install -y git"
    exit 1
fi

print_status "🚀 Setting up Nautica Proxy Server..."

# Get domain configuration
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
    print_error "Setup cancelled"
    exit 1
fi

# Setup git repository
print_status "Setting up GitHub repository..."

if [ -d ".git" ]; then
    rm -rf .git
fi

git init
git remote add origin https://github.com/Ninadiantea/modevps.git

# Fetch existing content
git fetch origin || true

# Check if main branch exists
if git ls-remote --heads origin main | grep -q main; then
    git checkout -b main origin/main
else
    git checkout -b main
fi

print_status "Git repository setup complete!"

# Create .env file
print_status "Creating configuration file..."
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

print_status "Configuration file created!"

# Add files to git
print_status "Adding files to git..."
git add .
git commit -m "Add Nautica Proxy Server VPS installer

- Complete Node.js implementation
- One-command installation script
- WebSocket proxy support
- Multi-protocol support (VLESS, Trojan, SS)
- Web interface with subscription page
- API endpoints for configuration generation
- PM2 process management
- Nginx reverse proxy configuration
- SSL certificate automation
- Management scripts
- Comprehensive documentation"

# Push to GitHub
print_status "Pushing to GitHub..."
git push -u origin main

print_status "Successfully pushed to GitHub!"

# Show final information
echo ""
print_status "🎉 Setup completed successfully!"
echo ""
echo "📋 Repository Information:"
echo "   URL: https://github.com/Ninadiantea/modevps"
echo "   Branch: main"
echo ""
echo "🔗 Installation URLs:"
echo "   Raw Installer: https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh"
echo "   One Command: curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh | sudo bash"
echo ""
echo "📖 Documentation:"
echo "   README: https://github.com/Ninadiantea/modevps#readme"
echo ""
echo "🚀 Next Steps:"
echo "   1. Share the one-command installation URL with users"
echo "   2. Users can install with: curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh | sudo bash"
echo "   3. The installer will prompt for domain configuration"
echo "   4. Everything will be set up automatically"
echo ""
print_status "Your Nautica Proxy Server installer is now available on GitHub!"