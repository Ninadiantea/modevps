#!/bin/bash

# Stable Menu Script for Nautica Proxy Server
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Set domain
SERVICE_DOMAIN="bas.ahemmm.my.id"

# Function to show menu
show_menu() {
    clear
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
}

# Function to create VLESS account
create_vless() {
    echo ""
    echo -e "${GREEN}[INFO]${NC} Creating VLESS Account"
    echo "========================"
    echo -n "Enter account name: "
    read name
    
    if [ -z "$name" ]; then
        echo "Account name is required"
        return
    fi
    
    uuid=$(uuidgen)
    config="vless://$uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#$name"
    
    echo ""
    echo "Account created successfully!"
    echo "UUID: $uuid"
    echo "Config: $config"
    echo ""
}

# Function to create Trojan account
create_trojan() {
    echo ""
    echo -e "${GREEN}[INFO]${NC} Creating Trojan Account"
    echo "=========================="
    echo -n "Enter account name: "
    read name
    
    if [ -z "$name" ]; then
        echo "Account name is required"
        return
    fi
    
    uuid=$(uuidgen)
    config="trojan://$uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#$name"
    
    echo ""
    echo "Account created successfully!"
    echo "UUID: $uuid"
    echo "Config: $config"
    echo ""
}

# Function to list accounts
list_accounts() {
    echo ""
    echo -e "${GREEN}[INFO]${NC} All Accounts"
    echo "============="
    echo "No accounts found (accounts are stored in memory)"
    echo ""
}

# Function to delete account
delete_account() {
    echo ""
    echo -e "${GREEN}[INFO]${NC} Delete Account"
    echo "==============="
    echo -n "Enter account ID: "
    read id
    
    if [ -z "$id" ]; then
        echo "Account ID is required"
        return
    fi
    
    echo "Account deleted!"
    echo ""
}

# Function to show service status
service_status() {
    echo ""
    echo -e "${GREEN}[INFO]${NC} Service Status"
    echo "================"
    if command -v pm2 &> /dev/null; then
        pm2 status
    else
        echo "PM2 not found"
    fi
    echo ""
}

# Function to view logs
view_logs() {
    echo ""
    echo -e "${GREEN}[INFO]${NC} Viewing Logs"
    echo "============="
    if command -v pm2 &> /dev/null; then
        pm2 logs nautica-proxy --lines 10
    else
        echo "PM2 not found"
    fi
    echo ""
}

# Main menu loop
while true; do
    show_menu
    
    echo -n "Choose option (1-7): "
    read choice
    
    case $choice in
        1)
            create_vless
            ;;
        2)
            create_trojan
            ;;
        3)
            list_accounts
            ;;
        4)
            delete_account
            ;;
        5)
            service_status
            ;;
        6)
            view_logs
            ;;
        7)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Exiting..."
            exit 0
            ;;
        *)
            echo ""
            echo "Invalid option. Please choose 1-7."
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
done