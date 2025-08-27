# Nautica Proxy Server - Complete Setup Instructions

## 🚀 One Command Setup

Saya telah membuat script lengkap yang bisa langsung dijalankan dengan **satu perintah** untuk membuat installer Nautica Proxy Server dan push ke repository GitHub Anda.

### Langkah 1: Jalankan Script Setup

```bash
# Jalankan script setup
sudo bash setup-and-push.sh
```

### Langkah 2: Otomatis Push ke GitHub

Script akan otomatis:
- ✅ Menggunakan repository: https://github.com/Ninadiantea/modevps
- ✅ Membuat semua file installer
- ✅ Membuat README.md lengkap
- ✅ Push ke repository GitHub
- ✅ Memberikan URL installer siap pakai

## 📋 Hasil Akhir

Setelah script selesai, Anda akan mendapatkan:

### Repository GitHub
```
https://github.com/Ninadiantea/modevps
```

### One Command Installation URL
```bash
curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica.sh | sudo bash
```

## 🎯 Cara Penggunaan

### Untuk Anda (Developer)
1. Jalankan `sudo bash setup-and-push.sh`
2. Script otomatis push ke repository Anda
3. Dapatkan URL installer

### Untuk User (End User)
1. Copy URL installer yang Anda dapatkan
2. Jalankan di VPS Ubuntu mereka
3. Masukkan domain saat diminta
4. Server otomatis terinstall dan running

## 📁 File yang Dibuat

### 1. `install-nautica.sh`
- Script installer utama
- Otomatis setup semua dependencies
- Konfigurasi domain interaktif
- Setup Nginx + SSL
- PM2 process management

### 2. `setup-and-push.sh`
- Script untuk setup dan push ke GitHub
- Membuat semua file yang diperlukan
- Push otomatis ke repository

### 3. `README.md`
- Dokumentasi lengkap
- Instruksi penggunaan
- Troubleshooting guide
- API documentation

## 🔧 Fitur Installer

### Otomatis Setup
- ✅ Node.js 18.x
- ✅ PM2 process manager
- ✅ Nginx reverse proxy
- ✅ SSL certificate (Let's Encrypt)
- ✅ UFW firewall
- ✅ Domain configuration

### Konfigurasi Interaktif
- Domain input
- Subdomain option
- SSL setup
- Service management

### Management Tools
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

## 🌐 Endpoints yang Tersedia

### Web Interface
- **Subscription Page**: `https://yourdomain.com/sub`
- **API Endpoint**: `https://yourdomain.com/api/v1/sub`
- **Health Check**: `https://yourdomain.com/check`

### API Usage
```bash
# Get raw configurations
curl "https://yourdomain.com/api/v1/sub?format=raw&limit=10"

# Get Clash configuration
curl "https://yourdomain.com/api/v1/sub?format=clash&cc=SG,US"

# Filter by country
curl "https://yourdomain.com/api/v1/sub?cc=SG&limit=5"
```

## 🔄 Alur Kerja

```
1. Developer: sudo bash setup-and-push.sh
   ↓
2. Otomatis push ke https://github.com/Ninadiantea/modevps
   ↓
3. Dapatkan URL installer
   ↓
4. Share URL dengan user
   ↓
5. User: curl -fsSL URL | sudo bash
   ↓
6. Masukkan domain
   ↓
7. Server otomatis running
```

## 🎉 Keunggulan

### Untuk Developer
- ✅ **Satu perintah** untuk setup semuanya
- ✅ **Otomatis push** ke repository Anda
- ✅ **URL installer** siap pakai
- ✅ **Dokumentasi lengkap** otomatis dibuat

### Untuk End User
- ✅ **Satu perintah** untuk install
- ✅ **Konfigurasi otomatis** domain
- ✅ **SSL otomatis** setup
- ✅ **Management tools** lengkap
- ✅ **Support sama** dengan Cloudflare Workers

## 🚨 Requirements

### Untuk Setup (Developer)
- Ubuntu 20.04+
- Root access (sudo)
- Git installed
- GitHub account

### Untuk Install (End User)
- Ubuntu 20.04+
- Root access (sudo)
- Domain name dengan DNS pointing ke VPS
- Minimum 1GB RAM

## 📞 Support

Jika ada masalah:
1. Check logs: `/opt/nautica-proxy/manage.sh logs`
2. Check status: `/opt/nautica-proxy/manage.sh status`
3. Restart service: `/opt/nautica-proxy/manage.sh restart`

## 🎯 Kesimpulan

Dengan script ini, Anda bisa:
1. **Setup sekali** dengan `sudo bash setup-and-push.sh`
2. **Dapatkan URL installer** yang bisa dishare
3. **User install** dengan satu perintah
4. **Server running** otomatis dengan semua fitur

**Sangat mudah dan user-friendly!** 🚀

---

**Repository: https://github.com/Ninadiantea/modevps**