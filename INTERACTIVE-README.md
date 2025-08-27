# 🚀 Nautica Proxy Server - Interactive Installer

## 📋 Overview

Script installer interaktif untuk Nautica Proxy Server dengan menu sistem untuk manajemen akun langsung dari VPS.

## ✨ Fitur Utama

### 🔧 Instalasi Otomatis
- **Domain Configuration**: Input domain secara interaktif
- **System Setup**: Install semua dependencies otomatis
- **SSL Certificate**: Setup Let's Encrypt otomatis
- **Firewall**: Konfigurasi UFW otomatis
- **Service Management**: PM2 untuk auto-restart

### 🎛️ Menu Interaktif
Setelah instalasi selesai, script akan menampilkan menu dengan opsi:

1. **Create VLESS Account** - Buat akun VLESS
2. **Create Trojan Account** - Buat akun Trojan
3. **Create Shadowsocks Account** - Buat akun Shadowsocks
4. **List All Accounts** - Lihat semua akun
5. **Delete Account** - Hapus akun
6. **View Web Interface** - Akses web interface
7. **Service Management** - Kelola service
8. **View Logs** - Lihat log
9. **Exit** - Keluar

## 🚀 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica-interactive.sh | sudo bash
```

## 📝 Cara Penggunaan

### 1. Jalankan Installer
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica-interactive.sh | sudo bash
```

### 2. Input Domain
Script akan meminta input:
- **Main Domain**: `bas.ahemmm.my.id`
- **Subdomain** (opsional): `nautica` atau kosongkan untuk main domain

### 3. Tunggu Instalasi
Script akan otomatis:
- Update system
- Install dependencies (Node.js, PM2, Nginx, Certbot)
- Setup project structure
- Configure Nginx
- Setup SSL certificate
- Start service

### 4. Menu Interaktif
Setelah instalasi selesai, menu akan muncul:

```
========================================
  NAUTICA PROXY SERVER - MENU
========================================

1. Create VLESS Account
2. Create Trojan Account
3. Create Shadowsocks Account
4. List All Accounts
5. Delete Account
6. View Web Interface
7. Service Management
8. View Logs
9. Exit

Current Domain: bas.ahemmm.my.id
Service Status: active
```

## 🎯 Fitur Menu

### Create Account
- **Input**: Nama akun dan email (opsional)
- **Output**: Akun dengan UUID unik dan konfigurasi lengkap
- **Format**: VLESS/Trojan/Shadowsocks dengan TLS dan NTLS

### Service Management
- Start service
- Stop service
- Restart service
- Check status

### Logs
- Application logs
- PM2 logs
- Nginx logs

## 🌐 Web Interface

Setelah instalasi, akses:
- **Subscription Page**: `https://bas.ahemmm.my.id/sub`
- **API Endpoint**: `https://bas.ahemmm.my.id/api/v1/sub`
- **Health Check**: `https://bas.ahemmm.my.id/check`

## 📁 File Structure

```
/opt/nautica-proxy/
├── src/
│   ├── server.js
│   └── modules/
│       ├── AccountManager.js
│       ├── ProxyManager.js
│       ├── WebSocketHandler.js
│       ├── ConfigGenerator.js
│       └── HTMLGenerator.js
├── accounts/
│   └── accounts.json
├── logs/
├── package.json
├── ecosystem.config.js
├── .env
└── manage.sh
```

## 🔧 Management Commands

```bash
# Service management
/opt/nautica-proxy/manage.sh start
/opt/nautica-proxy/manage.sh stop
/opt/nautica-proxy/manage.sh restart
/opt/nautica-proxy/manage.sh status
/opt/nautica-proxy/manage.sh logs
/opt/nautica-proxy/manage.sh monit
```

## 📊 Account Management

### API Endpoints
- `POST /api/v1/accounts` - Create account
- `GET /api/v1/accounts` - List all accounts
- `DELETE /api/v1/accounts/:id` - Delete account

### Account Types
- **VLESS**: Modern proxy protocol
- **Trojan**: Obfuscated proxy protocol
- **Shadowsocks**: Legacy proxy protocol

## 🔒 Security Features

- **SSL/TLS**: Automatic Let's Encrypt certificates
- **Firewall**: UFW configured with minimal ports
- **PM2**: Process management and auto-restart
- **Nginx**: Reverse proxy with security headers

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

### SSL Issues
```bash
# Manual SSL setup
certbot --nginx -d bas.ahemmm.my.id
```

### Domain Issues
```bash
# Check DNS
nslookup bas.ahemmm.my.id

# Check Nginx config
nginx -t
```

## 📈 Monitoring

### PM2 Monitoring
```bash
pm2 monit
```

### Log Monitoring
```bash
# Real-time logs
tail -f /opt/nautica-proxy/logs/combined.log

# Nginx logs
tail -f /var/log/nginx/access.log
```

## 🎉 Benefits

1. **One Command Install**: Install lengkap dengan satu perintah
2. **Interactive Setup**: Input domain secara interaktif
3. **Menu System**: Manajemen akun langsung dari VPS
4. **Auto SSL**: Setup SSL certificate otomatis
5. **Service Management**: Kelola service dengan mudah
6. **Log Monitoring**: Monitor log secara real-time
7. **Account Management**: Buat/hapus akun dengan mudah

## 🔗 Repository

**GitHub**: https://github.com/Ninadiantea/modevps

**One Command Install**:
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica-interactive.sh | sudo bash
```

---

**Nautica Proxy Server** - Interactive Installer dengan Menu System 🚀