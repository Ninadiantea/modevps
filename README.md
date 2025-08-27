# 🚀 Nautica Proxy Server - VPS Ubuntu Installer

A complete implementation of Nautica Proxy Server for VPS Ubuntu, providing the same functionality as the original Cloudflare Workers version.

## ✨ Features

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

## 🚀 Quick Install

### One Command Installation

```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh | sudo bash
```

### Manual Installation

```bash
# Clone repository
git clone https://github.com/Ninadiantea/modevps.git
cd modevps

# Run installer
sudo bash install-nautica.sh
```

## 🌐 Usage

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

## ⚙️ Configuration

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

## 🔌 API Usage

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

## 🏗️ Architecture

```
Client → VPS Ubuntu → Proxy Server (from GitHub)
   ↓         ↓              ↓
WebSocket → Node.js → TCP/UDP Connection
```

## 📋 Requirements

- Ubuntu 20.04 or higher
- Root access (sudo)
- Domain name with DNS pointing to VPS
- Minimum 1GB RAM
- 10GB storage

## 📁 Installation Directory

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

## 🔧 Troubleshooting

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

## 🔒 Security

- ✅ **Firewall**: UFW configured with necessary ports
- ✅ **SSL/TLS**: Automatic Let's Encrypt certificates
- ✅ **Security Headers**: Nginx security headers configured
- ✅ **Process Management**: PM2 for reliable service management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the logs for error details

## 🙏 Credits

- Original Nautica project by FoolVPN-ID
- Adapted for VPS Ubuntu deployment
- Enhanced with additional features and management tools

---

**Repository**: https://github.com/Ninadiantea/modevps  
**One Command Install**: `curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh | sudo bash`

**Status**: ✅ Ready to Deploy
