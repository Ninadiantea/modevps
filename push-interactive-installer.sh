diff --git a/push-interactive-installer.sh b/push-interactive-installer.sh
--- a/push-interactive-installer.sh
+++ b/push-interactive-installer.sh
@@ -0,0 +1,50 @@
+#!/bin/bash
+
+# Push Interactive Installer to GitHub Repository
+# Author: AI Assistant
+
+set -e
+
+# Colors
+GREEN='\033[0;32m'
+YELLOW='\033[1;33m'
+NC='\033[0m'
+
+print_status() {
+    echo -e "${GREEN}[INFO]${NC} $1"
+}
+
+print_warning() {
+    echo -e "${YELLOW}[WARNING]${NC} $1"
+}
+
+# Check if we're in the right directory
+if [ ! -f "install-nautica-interactive.sh" ]; then
+    print_warning "install-nautica-interactive.sh not found in current directory"
+    exit 1
+fi
+
+print_status "Pushing Interactive Installer to GitHub..."
+
+# Add the new file
+git add install-nautica-interactive.sh
+
+# Commit
+git commit -m "Add interactive installer with menu system for account management"
+
+# Push to main branch
+git push origin main
+
+print_status "✅ Interactive installer pushed successfully!"
+print_status "📋 Repository: https://github.com/Ninadiantea/modevps"
+print_status "🚀 One Command Install:"
+echo ""
+echo "curl -fsSL https://raw.githubusercontent.com/Ninadiantea/modevps/main/install-nautica-interactive.sh | sudo bash"
+echo ""
+print_status "✨ Features:"
+echo "   • Interactive domain setup"
+echo "   • Menu system for account management"
+echo "   • Create VLESS/Trojan/SS accounts"
+echo "   • Service management"
+echo "   • Log viewing"
+echo "   • Web interface access"
