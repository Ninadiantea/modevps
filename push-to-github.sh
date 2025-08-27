#!/bin/bash

# Script to push Nautica Proxy Server installer to GitHub
# Author: AI Assistant

set -e

# Colors for output
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

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install git first."
        exit 1
    fi
}

# Initialize git repository
init_repo() {
    print_status "Initializing git repository..."
    
    if [ ! -d ".git" ]; then
        git init
        print_status "Git repository initialized"
    else
        print_status "Git repository already exists"
    fi
}

# Create README.md
create_readme() {
    print_status "Creating README.md..."
    cat > README.md << 'EOF'
# Nautica Proxy Server - VPS Ubuntu Installer

A complete implementation of Nautica Proxy Server for VPS Ubuntu, providing the same functionality as the original Cloudflare Workers version.

## Features

- ✅ **Multi Protocol Support**: VLESS, Trojan, Shadowsocks
- ✅ **WebSocket Proxy**: Full WebSocket tunneling support
- ✅ **Web Interface**: User-friendly subscription page
- ✅ **API Endpoints**: RESTful API for configuration generation
- ✅ **Auto Update**: Proxy list automatically updated from GitHub
- ✅ **Country Filtering**: Filter proxies by country
- ✅ **SSL Support**: Automatic Let's Encrypt certificate setup
- ✅ **Load Balancing**: Random proxy selection
- ✅ **Health Check**: Proxy health monitoring
- ✅ **Management Tools**: Easy service management

## Quick Install

### One Command Installation

```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/nautica-proxy-vps/main/install-nautica.sh | sudo bash
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/nautica-proxy-vps.git
cd nautica-proxy-vps

# Run installer
sudo bash install-nautica.sh
```

## Usage

### Web Interface
- **Subscription Page**: `https://yourdomain.com/sub`
- **API Endpoint**: `https://yourdomain.com/api/v1/sub`
- **Health Check**: `https://yourdomain.com/check`

### Management Commands
```bash
# Start service
/opt/nautica-proxy/manage.sh start

# Stop service
/opt/nautica-proxy/manage.sh stop

# Restart service
/opt/nautica-proxy/manage.sh restart

# Check status
/opt/nautica-proxy/manage.sh status

# View logs
/opt/nautica-proxy/manage.sh logs

# Monitor resources
/opt/nautica-proxy/manage.sh monit
```

## Configuration

The installer will prompt you for:
- **Main Domain**: Your primary domain (e.g., yourdomain.com)
- **Subdomain**: Optional subdomain (e.g., nautica)

### Environment Variables

Key configuration in `/opt/nautica-proxy/.env`:
```bash
ROOT_DOMAIN=yourdomain.com
SERVICE_NAME=nautica
APP_DOMAIN=nautica.yourdomain.com
PROXY_BANK_URL=https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/proxyList.txt
```

## API Usage

### Get Subscription Configurations
```bash
# Get raw configurations
curl "https://yourdomain.com/api/v1/sub?format=raw&limit=10"

# Get Clash configuration
curl "https://yourdomain.com/api/v1/sub?format=clash&cc=SG,US"

# Filter by country
curl "https://yourdomain.com/api/v1/sub?cc=SG&limit=5"
```

### Health Check
```bash
curl "https://yourdomain.com/check?target=1.1.1.1:443"
```

## Architecture

```
Client → VPS Ubuntu → Proxy Server (from GitHub)
   ↓         ↓              ↓
WebSocket → Node.js → TCP/UDP Connection
```

## Requirements

- Ubuntu 20.04 or higher
- Root access (sudo)
- Domain name with DNS pointing to VPS
- Minimum 1GB RAM
- 10GB storage

## Installation Directory

```
/opt/nautica-proxy/
├── src/
│   ├── server.js
│   └── modules/
│       ├── ProxyManager.js
│       ├── WebSocketHandler.js
│       ├── ConfigGenerator.js
│       └── HTMLGenerator.js
├── logs/
├── .env
├── package.json
├── ecosystem.config.js
└── manage.sh
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Failed**
   ```bash
   # Manual SSL setup
   certbot --nginx -d yourdomain.com
   ```

2. **Service Not Starting**
   ```bash
   # Check logs
   /opt/nautica-proxy/manage.sh logs
   
   # Check PM2 status
   pm2 status
   ```

3. **Proxy List Not Loading**
   ```bash
   # Check network connectivity
   curl https://raw.githubusercontent.com/FoolVPN-ID/Nautica/refs/heads/main/proxyList.txt
   ```

### Logs Location
- **Application Logs**: `/opt/nautica-proxy/logs/`
- **Nginx Logs**: `/var/log/nginx/`
- **PM2 Logs**: `pm2 logs nautica-proxy`

## Security

- ✅ **Firewall**: UFW configured with necessary ports
- ✅ **SSL/TLS**: Automatic Let's Encrypt certificates
- ✅ **Security Headers**: Nginx security headers configured
- ✅ **Process Management**: PM2 for reliable service management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the logs for error details

## Credits

- Original Nautica project by FoolVPN-ID
- Adapted for VPS Ubuntu deployment
- Enhanced with additional features and management tools
EOF
}

# Create .gitignore
create_gitignore() {
    print_status "Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.production

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/

# Dependency directories
node_modules/
jspm_packages/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
EOF
}

# Add files to git
add_files() {
    print_status "Adding files to git..."
    git add .
    print_status "Files added to git"
}

# Commit changes
commit_changes() {
    print_status "Committing changes..."
    git commit -m "Initial commit: Nautica Proxy Server VPS installer

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
    print_status "Changes committed"
}

# Add remote repository
add_remote() {
    print_status "Adding remote repository..."
    
    # Get GitHub username
    read -p "Enter your GitHub username: " GITHUB_USERNAME
    
    # Add remote
    git remote add origin https://github.com/$GITHUB_USERNAME/nautica-proxy-vps.git
    
    print_status "Remote repository added: https://github.com/$GITHUB_USERNAME/nautica-proxy-vps.git"
}

# Push to GitHub
push_to_github() {
    print_status "Pushing to GitHub..."
    
    # Check if remote exists
    if ! git remote get-url origin &> /dev/null; then
        add_remote
    fi
    
    # Push to main branch
    git branch -M main
    git push -u origin main
    
    print_status "Successfully pushed to GitHub!"
}

# Show final information
show_final_info() {
    echo ""
    print_status "🎉 Repository successfully pushed to GitHub!"
    echo ""
    echo "📋 Repository Information:"
    echo "   URL: https://github.com/$GITHUB_USERNAME/nautica-proxy-vps"
    echo "   Branch: main"
    echo ""
    echo "🔗 Installation URLs:"
    echo "   Raw Installer: https://raw.githubusercontent.com/$GITHUB_USERNAME/nautica-proxy-vps/main/install-nautica.sh"
    echo "   One Command: curl -fsSL https://raw.githubusercontent.com/$GITHUB_USERNAME/nautica-proxy-vps/main/install-nautica.sh | sudo bash"
    echo ""
    echo "📖 Documentation:"
    echo "   README: https://github.com/$GITHUB_USERNAME/nautica-proxy-vps#readme"
    echo ""
    print_status "Your Nautica Proxy Server installer is now available on GitHub!"
}

# Main function
main() {
    print_status "🚀 Pushing Nautica Proxy Server installer to GitHub..."
    echo ""
    
    check_git
    init_repo
    create_readme
    create_gitignore
    add_files
    commit_changes
    push_to_github
    show_final_info
}

# Run main function
main "$@"