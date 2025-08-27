#!/bin/bash

# Push All Files to GitHub Repository
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Push All Files to GitHub Repository${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "install-nautica.sh" ]; then
    print_warning "Not in the correct directory"
    exit 1
fi

print_status "Adding all new files to Git..."

# Add all new files
git add .

# Commit with descriptive message
git commit -m "Add stable menu system and improved installers

- Add stable-menu.sh: Stable menu without spam
- Add simple-installer.sh: Simple installer with stable menu
- Add test-menu.sh: Test menu for verification
- Add auto-install.sh: Auto installer with menu
- Add install-nautica-interactive-fixed.sh: Fixed interactive installer
- Add INTERACTIVE-README.md: Documentation for interactive installer
- Improve menu stability and input handling
- Fix domain configuration issues
- Add proper error handling"

# Push to main branch
print_status "Pushing to GitHub repository..."
git push origin main

print_status "✅ All files pushed successfully!"
print_status "📋 Repository: https://github.com/Ninadiantea/modevps"
echo ""
print_status "🚀 Available Install Scripts:"
echo ""
echo "1. Simple Installer (Recommended):"
echo "   curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/simple-installer.sh | sudo bash"
echo ""
echo "2. Auto Installer:"
echo "   curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/auto-install.sh | sudo bash"
echo ""
echo "3. Test Menu (Safe):"
echo "   curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/test-menu.sh | bash"
echo ""
print_status "✨ Features:"
echo "   • Stable menu system (no spam)"
echo "   • Create VLESS/Trojan accounts"
echo "   • Account management"
echo "   • Service management"
echo "   • Web interface"
echo "   • API endpoints"