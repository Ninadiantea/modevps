#!/bin/bash

# Fix Nautica Proxy Service
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fix Nautica Proxy Service${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Checking current service status..."
pm2 status

echo ""
echo -e "${GREEN}[INFO]${NC} Stopping and deleting errored service..."
pm2 stop nautica-proxy
pm2 delete nautica-proxy

echo ""
echo -e "${GREEN}[INFO]${NC} Checking if /opt/nautica-proxy exists..."
if [ ! -d "/opt/nautica-proxy" ]; then
    echo -e "${RED}[ERROR]${NC} /opt/nautica-proxy directory not found!"
    echo -e "${YELLOW}[INFO]${NC} Creating directory and files..."
    
    mkdir -p /opt/nautica-proxy
    cd /opt/nautica-proxy
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "nautica-proxy-web",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "uuid": "^9.0.0"
  }
}
EOF

    # Create simple server
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

else
    echo -e "${GREEN}[INFO]${NC} Directory exists, checking files..."
    cd /opt/nautica-proxy
fi

echo ""
echo -e "${GREEN}[INFO]${NC} Starting service with PM2..."
pm2 start ecosystem.config.js

echo ""
echo -e "${GREEN}[INFO]${NC} Saving PM2 configuration..."
pm2 save

echo ""
echo -e "${GREEN}[INFO]${NC} Checking service status..."
pm2 status

echo ""
echo -e "${GREEN}[INFO]${NC} Checking if service is accessible..."
sleep 3

if curl -s http://localhost:3000/ > /dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Service is running and accessible!"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Local: http://localhost:3000/"
    echo "   Domain: http://bas.ahemmm.my.id/"
    echo "   API: http://bas.ahemmm.my.id/api/v1/accounts"
    echo ""
    echo -e "${GREEN}[INFO]${NC} Service fixed successfully!"
else
    echo -e "${RED}[ERROR]${NC} Service is not accessible. Checking logs..."
    pm2 logs nautica-proxy --lines 10
fi