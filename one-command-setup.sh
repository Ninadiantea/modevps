#!/bin/bash

# One Command Setup for Nautica Proxy Server
# This script creates all files and pushes to GitHub

echo "🚀 Creating Nautica Proxy Server installer..."

# Make scripts executable
chmod +x install-nautica.sh
chmod +x push-to-github.sh
chmod +x setup-and-push.sh

echo "✅ All scripts are ready!"
echo ""
echo "📋 Next steps:"
echo "1. Run: sudo bash setup-and-push.sh"
echo "2. Enter your GitHub username when prompted"
echo "3. The script will create everything and push to GitHub"
echo "4. You'll get a one-command installation URL"
echo ""
echo "🎯 The final result will be:"
echo "   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/nautica-proxy-vps/main/install-nautica.sh | sudo bash"
echo ""
echo "Ready to proceed? Run: sudo bash setup-and-push.sh"