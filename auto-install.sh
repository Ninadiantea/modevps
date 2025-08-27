#!/bin/bash

# Auto Install Nautica Proxy Server
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Nautica Proxy Server - Auto Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Set domain automatically
DOMAIN="bas.ahemmm.my.id"
SERVICE_DOMAIN="bas.ahemmm.my.id"

echo -e "${GREEN}[INFO]${NC} Starting auto installation..."
echo -e "${GREEN}[INFO]${NC} Domain: $DOMAIN"
echo ""

# Update system
echo -e "${GREEN}[INFO]${NC} Updating system packages..."
apt update -y > /dev/null 2>&1
echo -e "${GREEN}[INFO]${NC} System updated!"

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing dependencies..."
apt install -y curl wget git nginx certbot python3-certbot-nginx unzip jq > /dev/null 2>&1

# Install Node.js
echo -e "${GREEN}[INFO]${NC} Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1

# Install PM2
echo -e "${GREEN}[INFO]${NC} Installing PM2..."
npm install -g pm2 > /dev/null 2>&1

echo -e "${GREEN}[INFO]${NC} Dependencies installed!"

# Create project
echo -e "${GREEN}[INFO]${NC} Creating project..."
mkdir -p /opt/nautica-proxy
cd /opt/nautica-proxy

# Create package.json
cat > package.json << 'EOF'
{
  "name": "nautica-proxy",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.0"
  }
}
EOF

# Create server
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors());
app.use(express.json());

// Store accounts in memory
let accounts = [];

app.get('/', (req, res) => {
  res.json({
    service: 'Nautica Proxy Server',
    status: 'running',
    domain: 'bas.ahemmm.my.id',
    accounts: accounts.length
  });
});

app.get('/sub', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Nautica Proxy</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .header { text-align: center; margin-bottom: 30px; }
          .account { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
          .config { background: #e8f4fd; padding: 10px; border-radius: 3px; font-family: monospace; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Welcome to Nautica Proxy Server</h1>
          <p>Service is running on bas.ahemmm.my.id</p>
          <p>Total Accounts: ${accounts.length}</p>
        </div>
        ${accounts.map(acc => `
          <div class="account">
            <h3>${acc.name} (${acc.type})</h3>
            <div class="config">${acc.config}</div>
          </div>
        `).join('')}
      </body>
    </html>
  `);
});

app.post('/api/v1/accounts', (req, res) => {
  const { type, name, email } = req.body;
  const uuid = uuidv4();
  const domain = 'bas.ahemmm.my.id';
  
  let config = '';
  if (type === 'vless') {
    config = `vless://${uuid}@${domain}:443?type=ws&path=/proxy&security=tls&sni=${domain}#${name}`;
  } else if (type === 'trojan') {
    config = `trojan://${uuid}@${domain}:443?type=ws&path=/proxy&security=tls&sni=${domain}#${name}`;
  }
  
  const account = {
    id: uuidv4(),
    type,
    name,
    email,
    uuid,
    config,
    createdAt: new Date().toISOString()
  };
  
  accounts.push(account);
  res.json({ success: true, data: account });
});

app.get('/api/v1/accounts', (req, res) => {
  res.json({ success: true, data: accounts });
});

app.delete('/api/v1/accounts/:id', (req, res) => {
  const { id } = req.params;
  accounts = accounts.filter(acc => acc.id !== id);
  res.json({ success: true, message: 'Account deleted' });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
EOF

# Install dependencies
echo -e "${GREEN}[INFO]${NC} Installing Node.js dependencies..."
npm install > /dev/null 2>&1

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
nginx -t > /dev/null 2>&1 && systemctl restart nginx

# Start service
echo -e "${GREEN}[INFO]${NC} Starting service..."
cd /opt/nautica-proxy
pm2 start ecosystem.config.js > /dev/null 2>&1
pm2 save > /dev/null 2>&1
pm2 startup > /dev/null 2>&1

# Setup firewall
echo -e "${GREEN}[INFO]${NC} Setting up firewall..."
ufw allow 22 > /dev/null 2>&1
ufw allow 80 > /dev/null 2>&1
ufw allow 443 > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1

echo ""
echo -e "${GREEN}[INFO]${NC} 🎉 Installation completed successfully!"
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

# Create management script
cat > /opt/nautica-proxy/manage.sh << 'EOF'
#!/bin/bash

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
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF

chmod +x /opt/nautica-proxy/manage.sh

echo -e "${GREEN}[INFO]${NC} Starting interactive menu..."
echo ""

# Show menu
while true; do
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  NAUTICA PROXY SERVER - MENU${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Create VLESS Account"
    echo -e "${GREEN}2.${NC} Create Trojan Account"
    echo -e "${GREEN}3.${NC} List All Accounts"
    echo -e "${GREEN}4.${NC} Delete Account"
    echo -e "${GREEN}5.${NC} Service Status"
    echo -e "${GREEN}6.${NC} View Logs"
    echo -e "${GREEN}7.${NC} Exit"
    echo ""
    echo -e "${YELLOW}Current Domain:${NC} $SERVICE_DOMAIN"
    echo ""
    
    read -p "Choose option (1-7): " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Creating VLESS Account"
            echo "========================"
            read -p "Enter account name: " name
            if [ ! -z "$name" ]; then
                response=$(curl -s -X POST http://localhost:3000/api/v1/accounts \
                    -H "Content-Type: application/json" \
                    -d "{\"type\":\"vless\",\"name\":\"$name\",\"email\":\"\"}")
                echo "Account created successfully!"
                echo "Config: $(echo $response | grep -o 'vless://[^"]*')"
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
                response=$(curl -s -X POST http://localhost:3000/api/v1/accounts \
                    -H "Content-Type: application/json" \
                    -d "{\"type\":\"trojan\",\"name\":\"$name\",\"email\":\"\"}")
                echo "Account created successfully!"
                echo "Config: $(echo $response | grep -o 'trojan://[^"]*')"
            else
                echo "Account name is required"
            fi
            ;;
        3)
            echo ""
            echo -e "${GREEN}[INFO]${NC} All Accounts"
            echo "============="
            curl -s http://localhost:3000/api/v1/accounts | jq '.data[] | {name: .name, type: .type, config: .config}' 2>/dev/null || echo "No accounts found"
            ;;
        4)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Delete Account"
            echo "==============="
            read -p "Enter account ID: " id
            if [ ! -z "$id" ]; then
                curl -s -X DELETE http://localhost:3000/api/v1/accounts/$id
                echo "Account deleted!"
            else
                echo "Account ID is required"
            fi
            ;;
        5)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Service Status"
            echo "================"
            pm2 status
            ;;
        6)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Viewing Logs"
            echo "============="
            pm2 logs nautica-proxy --lines 10
            ;;
        7)
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