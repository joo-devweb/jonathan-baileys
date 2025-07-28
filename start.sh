#!/bin/bash

# WhatsApp Defender Ultra - Startup Script
# Usage: ./start.sh [mode]
# Modes: main, defender, ultra, performance, python

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Banner
echo -e "${PURPLE}"
cat << "EOF"
██╗    ██╗██╗  ██╗ █████╗ ████████╗███████╗ █████╗ ██████╗ ██████╗ 
██║    ██║██║  ██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗
██║ █╗ ██║███████║███████║   ██║   ███████╗███████║██████╔╝██████╔╝
██║███╗██║██╔══██║██╔══██║   ██║   ╚════██║██╔══██║██╔═══╝ ██╔═══╝ 
╚███╔███╔╝██║  ██║██║  ██║   ██║   ███████║██║  ██║██║     ██║     
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝     
                                                                    
██████╗ ███████╗███████╗███████╗███╗   ██╗██████╗ ███████╗██████╗  
██╔══██╗██╔════╝██╔════╝██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗ 
██║  ██║█████╗  █████╗  █████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝ 
██║  ██║██╔══╝  ██╔══╝  ██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗ 
██████╔╝███████╗██║     ███████╗██║ ╚████║██████╔╝███████╗██║  ██║ 
╚═════╝ ╚══════╝╚═╝     ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝ 
                                                                    
                    🛡️  ULTRA ANTI BUG SYSTEM 🛡️
EOF
echo -e "${NC}"

# Function to check if Node.js is installed
check_nodejs() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed. Please install Node.js v20+ first.${NC}"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        echo -e "${RED}❌ Node.js version $NODE_VERSION detected. Please upgrade to v20+${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Node.js $(node -v) detected${NC}"
}

# Function to check if Python is installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        echo -e "${GREEN}✅ Python $PYTHON_VERSION detected${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Python3 not found. Python monitoring will be disabled.${NC}"
        return 1
    fi
}

# Function to install dependencies
install_deps() {
    echo -e "${YELLOW}📦 Checking dependencies...${NC}"
    
    if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
        echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
        npm install
        echo -e "${GREEN}✅ Node.js dependencies installed${NC}"
    else
        echo -e "${GREEN}✅ Node.js dependencies already installed${NC}"
    fi
    
    if check_python; then
        if [ -f "requirements.txt" ]; then
            echo -e "${YELLOW}📦 Installing Python dependencies...${NC}"
            python3 -m pip install -r requirements.txt --quiet
            echo -e "${GREEN}✅ Python dependencies installed${NC}"
        fi
    fi
}

# Function to create necessary directories
create_dirs() {
    echo -e "${YELLOW}📁 Creating directories...${NC}"
    mkdir -p logs session temp backup
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Function to show system info
show_system_info() {
    echo -e "${BLUE}📋 System Information:${NC}"
    echo -e "${BLUE}   • OS: $(uname -s) $(uname -r)${NC}"
    echo -e "${BLUE}   • Architecture: $(uname -m)${NC}"
    echo -e "${BLUE}   • CPU Cores: $(nproc)${NC}"
    echo -e "${BLUE}   • Memory: $(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo 'Unknown')${NC}"
    echo -e "${BLUE}   • Node.js: $(node -v)${NC}"
    if check_python &>/dev/null; then
        echo -e "${BLUE}   • Python: $(python3 --version)${NC}"
    fi
    echo -e "${BLUE}────────────────────────────────────${NC}"
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}Usage: $0 [mode]${NC}"
    echo -e "${CYAN}Modes:${NC}"
    echo -e "${CYAN}  main        - Run main bot (default)${NC}"
    echo -e "${CYAN}  defender    - Run basic defender only${NC}"
    echo -e "${CYAN}  ultra       - Run ultra defender with clustering${NC}"
    echo -e "${CYAN}  performance - Run performance monitor only${NC}"
    echo -e "${CYAN}  python      - Run Python performance monitor${NC}"
    echo -e "${CYAN}  install     - Install dependencies only${NC}"
    echo -e "${CYAN}  help        - Show this help${NC}"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0           # Run main bot${NC}"
    echo -e "${CYAN}  $0 ultra     # Run ultra defender${NC}"
    echo -e "${CYAN}  $0 install   # Install dependencies${NC}"
}

# Function to run main bot
run_main() {
    echo -e "${GREEN}🚀 Starting WhatsApp Defender Ultra (Main Bot)...${NC}"
    node index.js
}

# Function to run defender only
run_defender() {
    echo -e "${GREEN}🛡️  Starting Basic Defender...${NC}"
    node Defender.js
}

# Function to run ultra defender
run_ultra() {
    echo -e "${GREEN}🔥 Starting Ultra Defender with Clustering...${NC}"
    node DefendUltra.js
}

# Function to run performance monitor
run_performance() {
    echo -e "${GREEN}📊 Starting Performance Monitor...${NC}"
    node Performa.js
}

# Function to run Python monitor
run_python() {
    if ! check_python &>/dev/null; then
        echo -e "${RED}❌ Python3 is required but not installed${NC}"
        exit 1
    fi
    echo -e "${GREEN}🐍 Starting Python Performance Monitor...${NC}"
    python3 Performa.py
}

# Function to handle cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🔄 Shutting down gracefully...${NC}"
    # Kill any background processes if needed
    jobs -p | xargs -r kill
    echo -e "${GREEN}✅ Cleanup completed${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
main() {
    local mode=${1:-main}
    
    case $mode in
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        "install")
            check_nodejs
            install_deps
            create_dirs
            echo -e "${GREEN}✅ Installation completed${NC}"
            exit 0
            ;;
        "main"|"")
            check_nodejs
            install_deps
            create_dirs
            show_system_info
            run_main
            ;;
        "defender")
            check_nodejs
            install_deps
            create_dirs
            show_system_info
            run_defender
            ;;
        "ultra")
            check_nodejs
            install_deps
            create_dirs
            show_system_info
            run_ultra
            ;;
        "performance")
            check_nodejs
            install_deps
            create_dirs
            show_system_info
            run_performance
            ;;
        "python")
            install_deps
            create_dirs
            show_system_info
            run_python
            ;;
        *)
            echo -e "${RED}❌ Unknown mode: $mode${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi