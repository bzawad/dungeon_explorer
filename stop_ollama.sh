#!/bin/bash

# Ollama Stop Script
# This script stops the Ollama service and provides status information including:
# 1. Checking current service status
# 2. Stopping the Ollama service
# 3. Verifying the service has stopped
# 4. Providing restart instructions

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print step headers
print_step() {
    local step_num=$1
    local step_name=$2
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}🛑 STEP $step_num: $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Default: no LLM (dungeon runs without Ollama flavor text). Example: export OLLAMA_MODEL=llama3:latest
OLLAMA_MODEL=${OLLAMA_MODEL:-none}

# Start the Ollama stop process
echo -e "${CYAN}🛑 OLLAMA SERVICE SHUTDOWN${NC}"
echo -e "${CYAN}===========================${NC}"
echo -e "${BLUE}This will stop the Ollama service:${NC}"
echo -e "${BLUE}• Check current service status${NC}"
echo -e "${BLUE}• Stop Ollama service${NC}"
echo -e "${BLUE}• Verify shutdown${NC}"
echo -e "${BLUE}• Provide restart instructions${NC}"
echo -e "\n${YELLOW}📋 Current model: ${OLLAMA_MODEL}${NC}"
echo -e "\n${CYAN}🚀 Starting Ollama shutdown...${NC}"

# Step 1: Check Prerequisites
print_step "1" "CHECKING PREREQUISITES"
echo -e "${YELLOW}🔍 Checking if Homebrew is installed...${NC}"
if ! command_exists brew; then
    echo -e "${RED}❌ Homebrew is not installed${NC}"
    echo -e "${BLUE}💡 Homebrew is required to manage Ollama service${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Homebrew is available${NC}"

echo -e "${YELLOW}🔍 Checking if Ollama is installed...${NC}"
if ! command_exists ollama; then
    echo -e "${YELLOW}⚠️  Ollama is not installed${NC}"
    echo -e "${BLUE}💡 Nothing to stop - Ollama is not installed${NC}"
    exit 0
fi
echo -e "${GREEN}✅ Ollama is installed${NC}"

# Step 2: Check Current Status
print_step "2" "CHECKING CURRENT STATUS"
echo -e "${YELLOW}📊 Checking Ollama service status...${NC}"

if brew services list | grep -q "ollama.*started"; then
    echo -e "${GREEN}✅ Ollama service is currently running${NC}"
    
    # Test API connectivity
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✅ API is responding${NC}"
        
        # Show available models
        echo -e "${BLUE}💡 Available models:${NC}"
        ollama list 2>/dev/null | head -5 || echo -e "${YELLOW}   Could not list models${NC}"
    else
        echo -e "${YELLOW}⚠️  Service running but API not responding${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Ollama service is not running${NC}"
    echo -e "${BLUE}💡 Nothing to stop - service is already stopped${NC}"
    
    # Check if process might be running outside of brew services
    if pgrep -f ollama >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Ollama process detected outside of brew services${NC}"
        echo -e "${BLUE}💡 You may need to manually kill the process${NC}"
        echo -e "${BLUE}   Run: pkill -f ollama${NC}"
    fi
    
    exit 0
fi

# Step 3: Stop Service
print_step "3" "STOPPING OLLAMA SERVICE"
echo -e "${YELLOW}🛑 Stopping Ollama service...${NC}"
echo -e "${BLUE}💡 This will stop the background service${NC}"

if brew services stop ollama; then
    echo -e "${GREEN}✅ Stop command executed successfully${NC}"
else
    echo -e "${RED}❌ Failed to stop Ollama service${NC}"
    echo -e "${BLUE}💡 You may need to force stop: brew services kill ollama${NC}"
    exit 1
fi

# Wait a moment for service to stop
echo -e "${BLUE}💡 Waiting for service to stop...${NC}"
sleep 2

# Step 4: Verify Shutdown
print_step "4" "VERIFYING SHUTDOWN"
echo -e "${YELLOW}🔍 Verifying Ollama service has stopped...${NC}"

# Check service status
if brew services list | grep -q "ollama.*started"; then
    echo -e "${RED}❌ Service appears to still be running${NC}"
    echo -e "${BLUE}💡 Try force stopping: brew services kill ollama${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Service has stopped${NC}"
fi

# Check API connectivity (should fail)
if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  API is still responding (may take a moment to fully stop)${NC}"
else
    echo -e "${GREEN}✅ API is no longer responding${NC}"
fi

# Check for any remaining processes
if pgrep -f ollama >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Ollama processes still detected${NC}"
    echo -e "${BLUE}💡 Processes may take a moment to fully terminate${NC}"
    echo -e "${BLUE}💡 If needed, force kill with: pkill -f ollama${NC}"
else
    echo -e "${GREEN}✅ No Ollama processes detected${NC}"
fi

# Final success message
echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 OLLAMA SERVICE STOPPED SUCCESSFULLY!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ Ollama service has been shut down${NC}"
echo -e "\n${BLUE}📋 Shutdown Summary:${NC}"
echo -e "${BLUE}• Service status: Stopped${NC}"
echo -e "${BLUE}• API endpoint: Offline${NC}"
echo -e "${BLUE}• Models preserved: Yes (cached locally)${NC}"
echo -e "\n${BLUE}🔄 To restart Ollama:${NC}"
echo -e "${BLUE}• Quick restart: brew services start ollama${NC}"
echo -e "${BLUE}• Full setup: ./start_ollama.sh${NC}"
echo -e "${BLUE}• Manual start: ollama serve${NC}"
echo -e "\n${BLUE}💡 Note: Your downloaded models (including ${OLLAMA_MODEL}) are still cached${NC}"
echo -e "${BLUE}   and will be available when you restart the service.${NC}"
echo -e "\n${BLUE}🔧 Troubleshooting:${NC}"
echo -e "${BLUE}• Check status: brew services list | grep ollama${NC}"
echo -e "${BLUE}• Force stop: brew services kill ollama${NC}"
echo -e "${BLUE}• Kill processes: pkill -f ollama${NC}" 