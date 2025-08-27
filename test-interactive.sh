#!/bin/bash

# Test Interactive Installer
# Author: AI Assistant

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Interactive Installer${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Test domain configuration
test_domain_config() {
    print_status "Testing domain configuration..."
    
    # Default domain
    DEFAULT_DOMAIN="bas.ahemmm.my.id"
    
    echo "Enter your main domain (default: $DEFAULT_DOMAIN)"
    echo "Press Enter to use default or type your domain:"
    read -p "Domain: " DOMAIN
    DOMAIN=${DOMAIN:-$DEFAULT_DOMAIN}
    
    echo "Enter subdomain (e.g., nautica) or press Enter for main domain"
    read -p "Subdomain: " SUBDOMAIN
    
    if [ -z "$SUBDOMAIN" ]; then
        FULL_DOMAIN=$DOMAIN
        SERVICE_DOMAIN=$DOMAIN
        SERVICE_NAME="nautica"
    else
        FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
        SERVICE_DOMAIN=$FULL_DOMAIN
        SERVICE_NAME=$SUBDOMAIN
    fi
    
    echo ""
    print_status "Domain configuration:"
    echo "   Main Domain: $DOMAIN"
    echo "   Service Domain: $SERVICE_DOMAIN"
    echo "   Service Name: $SERVICE_NAME"
    echo ""
    
    echo "Is this correct? (y/n, default: y)"
    read -p "Confirm: " CONFIRM
    CONFIRM=${CONFIRM:-y}
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        print_status "Test cancelled"
        exit 0
    fi
    
    print_status "Domain configuration test passed!"
    print_status "Proceeding with installation..."
}

# Simulate installation steps
simulate_installation() {
    print_status "Simulating installation steps..."
    
    echo "1. Updating system packages..."
    sleep 1
    
    echo "2. Installing dependencies..."
    sleep 1
    
    echo "3. Creating project structure..."
    sleep 1
    
    echo "4. Setting up configuration..."
    sleep 1
    
    echo "5. Starting service..."
    sleep 1
    
    print_status "Installation simulation completed!"
}

# Show menu
show_test_menu() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  NAUTICA PROXY SERVER - TEST MENU${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} Create VLESS Account"
    echo -e "${GREEN}2.${NC} Create Trojan Account"
    echo -e "${GREEN}3.${NC} Create Shadowsocks Account"
    echo -e "${GREEN}4.${NC} List All Accounts"
    echo -e "${GREEN}5.${NC} Delete Account"
    echo -e "${GREEN}6.${NC} View Web Interface"
    echo -e "${GREEN}7.${NC} Service Management"
    echo -e "${GREEN}8.${NC} View Logs"
    echo -e "${GREEN}9.${NC} Exit"
    echo ""
    echo -e "${YELLOW}Current Domain:${NC} $SERVICE_DOMAIN"
    echo -e "${YELLOW}Service Status:${NC} Test Mode"
    echo ""
}

# Menu functions
create_vless_account() {
    echo ""
    print_status "Creating VLESS Account (Test Mode)"
    echo "====================================="
    
    read -p "Enter account name: " ACCOUNT_NAME
    read -p "Enter email (optional): " ACCOUNT_EMAIL
    
    if [ -z "$ACCOUNT_NAME" ]; then
        echo "Account name is required"
        return
    fi
    
    echo "Account created successfully!"
    echo "UUID: $(uuidgen)"
    echo "Domain: $SERVICE_DOMAIN"
    echo "Config: vless://uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#VLESS-TLS"
}

create_trojan_account() {
    echo ""
    print_status "Creating Trojan Account (Test Mode)"
    echo "======================================"
    
    read -p "Enter account name: " ACCOUNT_NAME
    read -p "Enter email (optional): " ACCOUNT_EMAIL
    
    if [ -z "$ACCOUNT_NAME" ]; then
        echo "Account name is required"
        return
    fi
    
    echo "Account created successfully!"
    echo "UUID: $(uuidgen)"
    echo "Domain: $SERVICE_DOMAIN"
    echo "Config: trojan://uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#Trojan-TLS"
}

create_ss_account() {
    echo ""
    print_status "Creating Shadowsocks Account (Test Mode)"
    echo "============================================"
    
    read -p "Enter account name: " ACCOUNT_NAME
    read -p "Enter email (optional): " ACCOUNT_EMAIL
    
    if [ -z "$ACCOUNT_NAME" ]; then
        echo "Account name is required"
        return
    fi
    
    echo "Account created successfully!"
    echo "UUID: $(uuidgen)"
    echo "Domain: $SERVICE_DOMAIN"
    echo "Config: ss://uuid@$SERVICE_DOMAIN:443?plugin=v2ray-plugin;mode=websocket;path=/proxy;host=$SERVICE_DOMAIN#Shadowsocks"
}

list_accounts() {
    echo ""
    print_status "All Accounts (Test Mode)"
    echo "============================"
    echo "No accounts found (test mode)"
}

delete_account() {
    echo ""
    print_status "Delete Account (Test Mode)"
    echo "=============================="
    echo "No accounts to delete (test mode)"
}

view_web_interface() {
    echo ""
    print_status "Web Interface URLs (Test Mode)"
    echo "==================================="
    echo "Subscription Page: https://$SERVICE_DOMAIN/sub"
    echo "API Endpoint: https://$SERVICE_DOMAIN/api/v1/sub"
    echo "Health Check: https://$SERVICE_DOMAIN/check"
}

service_management() {
    echo ""
    print_status "Service Management (Test Mode)"
    echo "==================================="
    echo "1. Start service"
    echo "2. Stop service"
    echo "3. Restart service"
    echo "4. Check status"
    echo "5. Back to main menu"
    echo ""
    
    read -p "Choose option (1-5): " SERVICE_OPTION
    
    case $SERVICE_OPTION in
        1) echo "Service started (test mode)" ;;
        2) echo "Service stopped (test mode)" ;;
        3) echo "Service restarted (test mode)" ;;
        4) echo "Service status: Running (test mode)" ;;
        5) return ;;
        *) echo "Invalid option" ;;
    esac
}

view_logs() {
    echo ""
    print_status "Viewing Logs (Test Mode)"
    echo "============================"
    echo "1. Application logs"
    echo "2. PM2 logs"
    echo "3. Nginx logs"
    echo "4. Back to main menu"
    echo ""
    
    read -p "Choose option (1-4): " LOG_OPTION
    
    case $LOG_OPTION in
        1) echo "Application logs (test mode)" ;;
        2) echo "PM2 logs (test mode)" ;;
        3) echo "Nginx logs (test mode)" ;;
        4) return ;;
        *) echo "Invalid option" ;;
    esac
}

# Main menu loop
show_menu() {
    while true; do
        clear
        show_test_menu
        
        read -p "Choose option (1-9): " MENU_OPTION
        
        case $MENU_OPTION in
            1) create_vless_account ;;
            2) create_trojan_account ;;
            3) create_ss_account ;;
            4) list_accounts ;;
            5) delete_account ;;
            6) view_web_interface ;;
            7) service_management ;;
            8) view_logs ;;
            9) 
                print_status "Exiting test mode..."
                exit 0
                ;;
            *) 
                echo "Invalid option"
                sleep 2
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main function
main() {
    print_header
    test_domain_config
    simulate_installation
    
    echo ""
    print_status "🎉 Test installation completed successfully!"
    echo ""
    echo "📋 Service Information:"
    echo "   Domain: $SERVICE_DOMAIN"
    echo "   Port: 3000 (internal)"
    echo "   Status: Test Mode"
    echo ""
    echo "🔗 Access URLs:"
    echo "   Web Interface: https://$SERVICE_DOMAIN/sub"
    echo "   API: https://$SERVICE_DOMAIN/api/v1/sub"
    echo "   Health Check: https://$SERVICE_DOMAIN/check"
    echo ""
    print_status "Starting test menu..."
    echo ""
    
    # Export domain for menu
    export SERVICE_DOMAIN
    
    # Show menu
    show_menu
}

# Run main function
main "$@"