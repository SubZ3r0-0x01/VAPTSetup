#!/bin/bash

# Script: Automated VAPT Setup for Ubuntu 24
# Author: Parth Padhiyar
# Purpose: Set up a fully functional automated bug bounty and VAPT environment on an Oracle VPS
# Features: Proper directory structure, logging, shell UI, error handling, and verbosity

LOGFILE="/var/log/vps_vapt_setup.log"
mkdir -p $(dirname "$LOGFILE")
touch "$LOGFILE"

# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for logging
echo_log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo_log "${RED}Please run this script as root (sudo). Exiting.${NC}"
    exit 1
fi

# Update & upgrade system
echo_log "${YELLOW}Updating and upgrading system...${NC}"
apt update && apt upgrade -y

# Install essential dependencies
echo_log "${YELLOW}Installing essential system packages...${NC}"
apt install -y git curl wget tmux vim build-essential jq unzip cron zsh fail2ban

# Check and install Python if missing
echo_log "${YELLOW}Checking and installing Python...${NC}"
if ! command -v python3 &> /dev/null; then
    apt install -y python3 python3-pip python3-venv
    echo_log "${GREEN}Python installed successfully.${NC}"
else
    echo_log "${BLUE}Python is already installed. Skipping...${NC}"
fi

# Check and install Go if missing
echo_log "${YELLOW}Checking and installing Go...${NC}"
if ! command -v go &> /dev/null; then
    apt install -y golang
    echo_log "${GREEN}Go installed successfully.${NC}"
else
    echo_log "${BLUE}Go is already installed. Skipping...${NC}"
fi

# Define directories
INSTALL_DIR="/opt/vapt_tools"
mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR"

# Install tools function
install_tool() {
    TOOL_NAME=$1
    INSTALL_CMD=$2
    CHECK_CMD=$3

    if ! command -v $CHECK_CMD &> /dev/null; then
        echo_log "${YELLOW}Installing $TOOL_NAME...${NC}"
        eval "$INSTALL_CMD"
        echo_log "${GREEN}$TOOL_NAME installed successfully.${NC}"
    else
        echo_log "${BLUE}$TOOL_NAME is already installed. Skipping...${NC}"
    fi
}

# Installing security tools
echo_log "${YELLOW}Installing security tools...${NC}"
install_tool "Nmap" "apt install -y nmap" "nmap"
install_tool "Masscan" "apt install -y masscan" "masscan"
install_tool "Amass" "snap install amass" "amass"
install_tool "Nikto" "apt install -y nikto" "nikto"
install_tool "SQLmap" "apt install -y sqlmap" "sqlmap"
install_tool "Seclists" "apt install -y seclists" "ls /usr/share/seclists"
install_tool "Metasploit" "snap install metasploit-framework" "msfconsole"
install_tool "JWT Toolkit" "pipx install jwt-tool" "jwt-tool"

# Install WordPress Security Tools
echo_log "${YELLOW}Installing WordPress security tools...${NC}"
install_tool "WPScan" "gem install wpscan" "wpscan"
install_tool "WordPress Exploit Framework" "git clone https://github.com/rastating/wordpress-exploit-framework.git && cd wordpress-exploit-framework && bundle install" "wpsf"

# Install Go-based tools
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
install_tool "Subfinder" "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "subfinder"
install_tool "Naabu" "go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" "naabu"
install_tool "httpx" "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest" "httpx"
install_tool "Jaeles" "go install github.com/jaeles-project/jaeles@latest" "jaeles"
install_tool "Nuclei" "go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest && nuclei -update-templates" "nuclei"
install_tool "Dalfox" "go install github.com/hahwul/dalfox/v2@latest" "dalfox"
install_tool "Assetfinder" "go install github.com/tomnomnom/assetfinder@latest" "assetfinder"
install_tool "Waybackurls" "go install github.com/tomnomnom/waybackurls@latest" "waybackurls"
install_tool "Gospider" "go install github.com/jaeles-project/gospider@latest" "gospider"
install_tool "Shuffledns" "go install github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest" "shuffledns"
install_tool "ffuf" "go install github.com/ffuf/ffuf@latest" "ffuf"

# Finishing setup
echo_log "${GREEN}VAPT automation setup complete! Reboot your system to apply changes.${NC}"
echo_log "${GREEN}Run the following command to start a scan: $INSTALL_DIR/recon_scan.sh${NC}"
