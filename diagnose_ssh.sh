#!/bin/bash
# SSH Connection Diagnostic Script
# Run this on LAPTOP/CLIENT to gather connection diagnostics

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IT_SUPPORT_MSG_FILE="$SCRIPT_DIR/it_support_message.txt"

echo "=========================================="
echo "SSH Connection Diagnostics"
echo "Run from: CLIENT/LAPTOP"
echo "Date: $(date)"
echo "=========================================="
echo ""

# Check if SSH config exists and extract target info
if [ -f ~/.ssh/config ]; then
    # Try to find the first Host entry and its HostName
    TARGET_HOST=$(grep -m 1 "^Host " ~/.ssh/config | awk '{print $2}')
    TARGET_IP=$(grep -A 5 "^Host $TARGET_HOST" ~/.ssh/config | grep "HostName" | awk '{print $2}')

    if [ -z "$TARGET_IP" ]; then
        echo -e "${YELLOW}⚠️  No HostName found in SSH config${NC}"
        echo "Please enter your desktop IP address:"
        read TARGET_IP
    fi
else
    echo -e "${YELLOW}⚠️  No SSH config found at ~/.ssh/config${NC}"
    echo "Please enter your desktop IP address:"
    read TARGET_IP
    TARGET_HOST="(manual entry)"
fi

echo "Target Host: $TARGET_HOST"
echo "Target IP: $TARGET_IP"
echo ""

# Validate IP format
if [[ ! $TARGET_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}❌ Invalid IP address format${NC}"
    exit 1
fi

echo "### 1. VPN Interface Check ###"
if ip addr show tun0 &>/dev/null; then
    echo -e "${GREEN}✅ VPN interface (tun0) exists${NC}"
    ip addr show tun0 | grep "inet "
else
    echo -e "${RED}❌ No VPN interface found${NC}"
fi
echo ""

echo "### 2. Client IP Addresses ###"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"
echo ""

echo "### 3. VPN Interface Details ###"
if ip addr show tun0 &>/dev/null; then
    VPN_IP=$(ip addr show tun0 | grep "inet " | awk '{print $2}')
    echo -e "${GREEN}✅ VPN connected: $VPN_IP${NC}"
    ip addr show tun0 | grep "inet "
else
    echo -e "${RED}❌ No tun0 interface - VPN not connected?${NC}"
fi
echo ""

echo "### 4. Routing to Server ###"
echo "Route to $TARGET_IP:"
ip route get "$TARGET_IP" 2>&1
echo ""

echo "### 5. VPN Routes ###"
echo "Routes via VPN gateway (looking for private network routes):"
VPN_ROUTES=$(ip route | grep -E "^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)" | head -5)
if [ -n "$VPN_ROUTES" ]; then
    echo "$VPN_ROUTES"
else
    echo -e "${YELLOW}⚠️  No private-network routes found through VPN${NC}"
    echo "VPN might not be routing traffic correctly."
fi
echo ""

echo "### 6. SSH Config ###"
if [ -f ~/.ssh/config ]; then
    echo "Current SSH config:"
    cat ~/.ssh/config
else
    echo -e "${YELLOW}⚠️  No SSH config found at ~/.ssh/config${NC}"
fi
echo ""

echo "### 7. Ping Test ###"
echo "Pinging $TARGET_IP (3 packets)..."
PING_OUTPUT=$(ping -c 3 -W 2 "$TARGET_IP" 2>&1)
if echo "$PING_OUTPUT" | grep -q "bytes from"; then
    echo -e "${GREEN}✅ Ping successful${NC}"
    echo "$PING_OUTPUT" | tail -2
else
    echo -e "${RED}❌ Ping failed - 100% packet loss${NC}"
    echo "$PING_OUTPUT" | tail -2
fi
echo ""

echo "### 8. SSH Connection Test ###"
echo "Testing SSH connection (10 second timeout)..."
if [ -n "$TARGET_HOST" ] && [ "$TARGET_HOST" != "(manual entry)" ]; then
    timeout 10 ssh -v -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        "$TARGET_HOST" "echo 'SSH connection successful!'" 2>&1 | \
        grep -E "(Connecting|connect|Connection|debug1:|SUCCESS|Permission denied)" | head -15
else
    echo "Testing direct IP connection..."
    timeout 10 ssh -v -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
        "$TARGET_IP" "echo 'SSH connection successful!'" 2>&1 | \
        grep -E "(Connecting|connect|Connection|debug1:|SUCCESS|Permission denied)" | head -15
fi
echo ""

echo "### 9. Port Check ###"
echo "Checking if SSH port 22 is reachable on $TARGET_IP..."
NC_OUTPUT=$(timeout 5 nc -zv "$TARGET_IP" 22 2>&1)
if echo "$NC_OUTPUT" | grep -qi "succeeded\|open\|connected"; then
    echo -e "${GREEN}✅ Port 22 is open${NC}"
    echo "$NC_OUTPUT"
else
    echo -e "${RED}❌ Port 22 is closed or filtered${NC}"
    echo "$NC_OUTPUT"
fi
echo ""

echo "### 10. Check Desktop IP Range ###"
echo "Checking whether desktop IP is private or public..."
if [[ $TARGET_IP =~ ^10\. ]] || [[ $TARGET_IP =~ ^172\.(1[6-9]|2[0-9]|3[01])\. ]] || [[ $TARGET_IP =~ ^192\.168\. ]]; then
    echo -e "${GREEN}✅ Desktop IP ($TARGET_IP) is in a private range${NC}"
    echo "   This is typical for home or corporate internal networks."
elif [[ $TARGET_IP =~ ^169\.254\. ]]; then
    echo -e "${RED}❌ Desktop IP ($TARGET_IP) is link-local (169.254.x.x)${NC}"
    echo "   This usually means DHCP failed on the desktop."
else
    echo -e "${YELLOW}⚠️  Desktop IP ($TARGET_IP) appears to be public/unexpected${NC}"
    echo "   Verify this is the intended SSH target for your VPN/network setup."
fi
echo ""

echo "### 11. Summary ###"
echo "=========================================="

# VPN Status
if ip addr show tun0 &>/dev/null; then
    VPN_STATUS="${GREEN}✅ Connected${NC}"
else
    VPN_STATUS="${RED}❌ Not Connected${NC}"
fi

# Ping Status
if ping -c 1 -W 2 "$TARGET_IP" &>/dev/null; then
    PING_STATUS="${GREEN}✅ Reachable${NC}"
else
    PING_STATUS="${RED}❌ Unreachable${NC}"
fi

# SSH Port Status
if timeout 5 nc -zv "$TARGET_IP" 22 &>/dev/null; then
    SSH_STATUS="${GREEN}✅ Port Open${NC}"
else
    SSH_STATUS="${RED}❌ Port Closed/Timeout${NC}"
fi

echo -e "VPN Status:     $VPN_STATUS"
echo -e "Server Ping:    $PING_STATUS"
echo -e "SSH Port (22):  $SSH_STATUS"
echo ""

# Diagnosis
if ip addr show tun0 &>/dev/null; then
    if ! ping -c 1 -W 2 "$TARGET_IP" &>/dev/null; then
        echo -e "${RED}⚠️  ISSUE DETECTED:${NC}"
        echo "   VPN is connected but server is unreachable."
        echo ""
        echo "   Possible causes:"
        echo "   1. Desktop is on a different network segment than VPN routes"
        echo "   2. Desktop is on WiFi instead of Ethernet"
        echo "   3. Firewall blocking traffic"
        echo "   4. Desktop is powered off or not on network"
        echo ""
        echo "   Next steps:"
        echo "   1. Verify desktop IP on desktop: hostname -I"
        if [ -f "$IT_SUPPORT_MSG_FILE" ]; then
            echo "   2. If network mismatch is suspected, contact IT/network support (template: $IT_SUPPORT_MSG_FILE)"
        else
            echo "   2. If network mismatch is suspected, contact IT/network support"
        fi
        echo "   3. Verify desktop is connected to Ethernet"
    elif ! timeout 5 nc -zv "$TARGET_IP" 22 &>/dev/null; then
        echo -e "${YELLOW}⚠️  ISSUE DETECTED:${NC}"
        echo "   Server is reachable but SSH port is closed."
        echo ""
        echo "   Possible causes:"
        echo "   1. SSH server not running on desktop"
        echo "   2. Firewall blocking port 22"
        echo ""
        echo "   Next steps:"
        echo "   1. On desktop, check SSH: sudo systemctl status ssh"
        echo "   2. If not running: sudo systemctl start ssh"
        echo "   3. Check firewall: sudo ufw status"
    else
        echo -e "${GREEN}✅ Everything looks good!${NC}"
        echo ""
        echo "   If SSH still doesn't work, check:"
        echo "   1. SSH key is copied: ssh-copy-id -i ~/.ssh/id_ed25519 user@$TARGET_IP"
        echo "   2. SSH config is correct: cat ~/.ssh/config"
    fi
else
    echo -e "${RED}⚠️  ISSUE DETECTED:${NC}"
    echo "   VPN is not connected."
    echo ""
    echo "   Next steps:"
    echo "   1. Reconnect VPN: vpn-disconnect && vpn-connect (from ~/.local/bin after setup_zsh.sh)"
    echo "   2. Re-run this diagnostic script"
fi

echo "=========================================="
echo ""
echo "For IT support, attach this output to your ticket."
if [ -f "$IT_SUPPORT_MSG_FILE" ]; then
    echo "Template file: $IT_SUPPORT_MSG_FILE"
else
    echo "No it_support_message.txt template found in this folder."
fi
