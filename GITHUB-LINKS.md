# 🚀 GitHub Repository Links - Nautica Proxy Server

## 📋 Repository Information
- **Repository**: https://github.com/Ninadiantea/modevps
- **Owner**: Ninadiantea
- **Branch**: main

## 🔗 Direct File Links

### 📁 Install Scripts
- **Simple Installer (Recommended)**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/simple-installer.sh
- **Auto Installer**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/auto-install.sh
- **Test Menu**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/test-menu.sh
- **Stable Menu**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/stable-menu.sh

### 📁 Documentation
- **Interactive README**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/INTERACTIVE-README.md
- **Main README**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/README.md

### 📁 Original Files
- **Original Installer**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh
- **Worker File**: https://raw.githubusercontent.com/Ninadiantea/modevps/main/_worker.js

## 🚀 One Command Installation

### 1. Simple Installer (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/simple-installer.sh | sudo bash
```

### 2. Auto Installer
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/auto-install.sh | sudo bash
```

### 3. Test Menu (Safe - No Installation)
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/test-menu.sh | bash
```

## 📊 Features

### ✨ Menu System
- **Stable Menu**: No spam, proper input handling
- **Account Creation**: VLESS, Trojan, Shadowsocks
- **Account Management**: List, delete accounts
- **Service Management**: Start, stop, restart, status
- **Logs**: View application logs

### 🌐 Web Interface
- **Subscription Page**: `http://bas.ahemmm.my.id/sub`
- **API Endpoint**: `http://bas.ahemmm.my.id/`
- **Health Check**: `http://bas.ahemmm.my.id/check`

### 🔧 Technical Features
- **Node.js Server**: Express.js with PM2
- **Nginx Reverse Proxy**: SSL ready
- **Firewall**: UFW configured
- **Auto-restart**: PM2 process management
- **Account Storage**: In-memory with API

## 📝 Installation Process

### Step 1: Run Installer
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/simple-installer.sh | sudo bash
```

### Step 2: Wait for Installation
- System update
- Dependencies installation (Node.js, PM2, Nginx)
- Project setup
- Service start
- Menu system launch

### Step 3: Use Menu
```
========================================
  NAUTICA PROXY SERVER - MENU
========================================

1. Create VLESS Account
2. Create Trojan Account
3. List All Accounts
4. Delete Account
5. Service Status
6. View Logs
7. Exit

Current Domain: bas.ahemmm.my.id
```

## 🎯 Account Creation

### VLESS Account
- **Protocol**: VLESS over WebSocket
- **Port**: 443 (TLS)
- **Path**: /proxy
- **Security**: TLS with SNI

### Trojan Account
- **Protocol**: Trojan over WebSocket
- **Port**: 443 (TLS)
- **Path**: /proxy
- **Security**: TLS with SNI

## 🔧 Management Commands

### Service Management
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
```

### PM2 Commands
```bash
# PM2 status
pm2 status

# PM2 logs
pm2 logs nautica-proxy

# PM2 monitor
pm2 monit
```

## 🌐 Access URLs

### After Installation
- **Web Interface**: http://bas.ahemmm.my.id/sub
- **API**: http://bas.ahemmm.my.id/
- **Health Check**: http://bas.ahemmm.my.id/check

### Local Access
- **Local API**: http://localhost:3000/
- **Local Subscription**: http://localhost:3000/sub

## 📁 File Structure

```
/opt/nautica-proxy/
├── server.js              # Main server file
├── package.json           # Node.js dependencies
├── ecosystem.config.js    # PM2 configuration
├── manage.sh             # Management script
└── stable-menu.sh        # Menu system
```

## 🔒 Security Features

- **Firewall**: UFW with minimal ports (22, 80, 443)
- **Process Management**: PM2 with auto-restart
- **Reverse Proxy**: Nginx with security headers
- **SSL Ready**: Certbot integration

## 🛠️ Troubleshooting

### Service Not Starting
```bash
# Check logs
/opt/nautica-proxy/manage.sh logs

# Check status
/opt/nautica-proxy/manage.sh status

# Restart service
/opt/nautica-proxy/manage.sh restart
```

### Domain Issues
```bash
# Check DNS
nslookup bas.ahemmm.my.id

# Check Nginx
nginx -t
systemctl status nginx
```

### Node.js Issues
```bash
# Check Node.js
node --version
npm --version

# Reinstall dependencies
cd /opt/nautica-proxy
npm install
```

## 📞 Support

- **Repository**: https://github.com/Ninadiantea/modevps
- **Issues**: Create issue on GitHub
- **Documentation**: Check README files

---

**Nautica Proxy Server** - VPS Installer with Menu System 🚀