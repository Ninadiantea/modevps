#!/bin/bash

# Test Menu Script
# Author: AI Assistant

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Set domain
SERVICE_DOMAIN="bas.ahemmm.my.id"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  NAUTICA PROXY SERVER - TEST MENU${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

while true; do
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
    
    echo -n "Choose option (1-7): "
    read choice
    
    case $choice in
        1)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Creating VLESS Account"
            echo "========================"
            echo -n "Enter account name: "
            read name
            
            if [ -z "$name" ]; then
                echo "Account name is required"
            else
                uuid=$(uuidgen)
                config="vless://$uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#$name"
                
                echo ""
                echo "Account created successfully!"
                echo "UUID: $uuid"
                echo "Config: $config"
            fi
            ;;
        2)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Creating Trojan Account"
            echo "=========================="
            echo -n "Enter account name: "
            read name
            
            if [ -z "$name" ]; then
                echo "Account name is required"
            else
                uuid=$(uuidgen)
                config="trojan://$uuid@$SERVICE_DOMAIN:443?type=ws&path=/proxy&security=tls&sni=$SERVICE_DOMAIN#$name"
                
                echo ""
                echo "Account created successfully!"
                echo "UUID: $uuid"
                echo "Config: $config"
            fi
            ;;
        3)
            echo ""
            echo -e "${GREEN}[INFO]${NC} All Accounts"
            echo "============="
            echo "No accounts found (test mode)"
            ;;
        4)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Delete Account"
            echo "==============="
            echo -n "Enter account ID: "
            read id
            
            if [ -z "$id" ]; then
                echo "Account ID is required"
            else
                echo "Account deleted!"
            fi
            ;;
        5)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Service Status"
            echo "================"
            echo "Service is running (test mode)"
            ;;
        6)
            echo ""
            echo -e "${GREEN}[INFO]${NC} Viewing Logs"
            echo "============="
            echo "No logs available (test mode)"
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
    
    echo ""
    echo -n "Press Enter to continue..."
    read
    clear
done