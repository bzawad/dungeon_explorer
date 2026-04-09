#!/bin/bash

# Ollama Start Script
# This script installs (if needed) and starts Ollama for the dungeon game including:
# 1. Installing Ollama via Homebrew
# 2. Starting the Ollama service
# 3. Pulling the specified model from environment variable
# 4. Verifying the installation

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
    echo -e "${PURPLE}🤖 STEP $step_num: $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to handle errors gracefully
handle_error() {
    local step_name=$1
    echo -e "${RED}❌ $step_name failed!${NC}"
    echo -e "${RED}💡 Please check the error above and try again${NC}"
    exit 1
}

# Default: no LLM (dungeon runs without Ollama flavor text). Example: export OLLAMA_MODEL=llama3:latest
OLLAMA_MODEL=${OLLAMA_MODEL:-none}

# Start the Ollama start process
echo -e "${CYAN}🤖 OLLAMA START FOR DUNGEON GAME${NC}"
echo -e "${CYAN}==================================${NC}"
echo -e "${BLUE}This will install (if needed) and start Ollama:${NC}"
echo -e "${BLUE}• Install Ollama via Homebrew${NC}"
echo -e "${BLUE}• Start Ollama service${NC}"
if [ "$OLLAMA_MODEL" = "none" ]; then
echo -e "${BLUE}• Skip model pull (OLLAMA_MODEL=none — set OLLAMA_MODEL to enable AI descriptions)${NC}"
else
echo -e "${BLUE}• Pull model: ${OLLAMA_MODEL}${NC}"
fi
echo -e "${BLUE}• Verify installation${NC}"
echo -e "\n${YELLOW}📋 Model: ${OLLAMA_MODEL}${NC}"
echo -e "${BLUE}💡 Change with OLLAMA_MODEL (e.g. llama3:latest) or use none to disable LLM calls${NC}"
echo -e "\n${CYAN}🚀 Starting Ollama...${NC}"

# Step 1: Check Prerequisites
print_step "1" "CHECKING PREREQUISITES"
echo -e "${YELLOW}🔍 Checking if Homebrew is installed...${NC}"
if ! command_exists brew; then
    echo -e "${RED}❌ Homebrew is not installed${NC}"
    echo -e "${BLUE}💡 Please install Homebrew first: https://brew.sh${NC}"
    echo -e "${BLUE}   Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Homebrew is installed${NC}"

# Step 2: Install Ollama
print_step "2" "INSTALLING OLLAMA"
if command_exists ollama; then
    echo -e "${YELLOW}📦 Ollama is already installed${NC}"
    ollama_version=$(ollama --version 2>/dev/null || echo "unknown")
    echo -e "${BLUE}💡 Current version: ${ollama_version}${NC}"
    echo -e "${BLUE}💡 Updating to latest version...${NC}"
    if ! brew upgrade ollama; then
        echo -e "${YELLOW}⚠️  Upgrade failed, but continuing with existing installation${NC}"
    fi
else
    echo -e "${YELLOW}📦 Installing Ollama via Homebrew...${NC}"
    if ! brew install ollama; then
        handle_error "Ollama installation"
    fi
fi
echo -e "${GREEN}✅ Ollama installation complete${NC}"

# Step 3: Start Ollama Service
print_step "3" "STARTING OLLAMA SERVICE"
echo -e "${YELLOW}🚀 Starting Ollama service...${NC}"
echo -e "${BLUE}💡 This will start Ollama as a background service${NC}"

# Check if service is already running
if brew services list | grep -q "ollama.*started"; then
    echo -e "${BLUE}💡 Ollama service is already running${NC}"
else
    if ! brew services start ollama; then
        handle_error "Starting Ollama service"
    fi
    echo -e "${BLUE}💡 Waiting for service to start...${NC}"
    sleep 3
fi

# Verify service is running
if brew services list | grep -q "ollama.*started"; then
    echo -e "${GREEN}✅ Ollama service is running${NC}"
else
    echo -e "${RED}❌ Ollama service failed to start${NC}"
    echo -e "${BLUE}💡 Try running: brew services restart ollama${NC}"
    exit 1
fi

# Step 4: Pull Model (skipped when OLLAMA_MODEL=none)
if [ "$OLLAMA_MODEL" != "none" ]; then
print_step "4" "PULLING MODEL: ${OLLAMA_MODEL}"
echo -e "${YELLOW}📥 Pulling ${OLLAMA_MODEL} model...${NC}"
echo -e "${BLUE}💡 This may take several minutes depending on model size${NC}"
echo -e "${BLUE}💡 Model will be downloaded and cached locally${NC}"

if ! ollama pull "$OLLAMA_MODEL"; then
    handle_error "Pulling model ${OLLAMA_MODEL}"
fi
echo -e "${GREEN}✅ Model ${OLLAMA_MODEL} downloaded successfully${NC}"
else
print_step "4" "SKIPPING MODEL PULL"
echo -e "${BLUE}💡 OLLAMA_MODEL=none — no model will be pulled (dungeon will not use Ollama for flavor text)${NC}"
fi

# Step 5: Verify Installation
print_step "5" "VERIFYING INSTALLATION"
echo -e "${YELLOW}🔍 Testing Ollama installation...${NC}"

# Test basic connectivity
echo -e "${BLUE}💡 Testing API connectivity...${NC}"
if ! curl -s http://localhost:11434/api/tags >/dev/null; then
    echo -e "${RED}❌ Cannot connect to Ollama API${NC}"
    echo -e "${BLUE}💡 Try restarting: brew services restart ollama${NC}"
    exit 1
fi
echo -e "${GREEN}✅ API connectivity verified${NC}"

if [ "$OLLAMA_MODEL" != "none" ]; then
# Test model availability
echo -e "${BLUE}💡 Verifying model ${OLLAMA_MODEL} is available...${NC}"
if ! ollama list | grep -q "$OLLAMA_MODEL"; then
    echo -e "${RED}❌ Model ${OLLAMA_MODEL} not found in local models${NC}"
    echo -e "${BLUE}💡 Try running: ollama pull ${OLLAMA_MODEL}${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Model ${OLLAMA_MODEL} is available${NC}"

# Test model generation
echo -e "${BLUE}💡 Testing model generation...${NC}"
test_response=$(ollama run "$OLLAMA_MODEL" "Say 'Hello from Ollama!' in exactly those words." 2>/dev/null | head -1 || echo "")
if [[ -z "$test_response" ]]; then
    echo -e "${YELLOW}⚠️  Model test generated empty response, but model is installed${NC}"
else
    echo -e "${GREEN}✅ Model generation test successful${NC}"
    echo -e "${BLUE}💡 Test response: ${test_response}${NC}"
fi
else
echo -e "${BLUE}💡 Skipping model checks (OLLAMA_MODEL=none)${NC}"
fi

# Final success message
echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 OLLAMA START SUCCESSFUL!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ Ollama is now ready for the dungeon game!${NC}"
echo -e "\n${BLUE}📋 Installation Summary:${NC}"
echo -e "${BLUE}• Ollama service: Running${NC}"
if [ "$OLLAMA_MODEL" = "none" ]; then
echo -e "${BLUE}• LLM flavor text: disabled (OLLAMA_MODEL=none; try OLLAMA_MODEL=llama3:latest)${NC}"
else
echo -e "${BLUE}• Model installed: ${OLLAMA_MODEL}${NC}"
fi
echo -e "${BLUE}• API endpoint: http://localhost:11434${NC}"
echo -e "\n${BLUE}🎮 Next steps:${NC}"
echo -e "${BLUE}• Start the dungeon game: ./iex.sh${NC}"
echo -e "${BLUE}• Or run Phoenix server: mix phx.server${NC}"
if [ "$OLLAMA_MODEL" != "none" ]; then
echo -e "${BLUE}• AI descriptions will be generated when you explore${NC}"
else
echo -e "${BLUE}• Set OLLAMA_MODEL (e.g. llama3:latest) and re-run this script to enable AI descriptions${NC}"
fi
echo -e "\n${BLUE}🔧 Troubleshooting:${NC}"
echo -e "${BLUE}• Restart service: brew services restart ollama${NC}"
echo -e "${BLUE}• Check status: brew services list | grep ollama${NC}"
if [ "$OLLAMA_MODEL" != "none" ]; then
echo -e "${BLUE}• Test manually: ollama run ${OLLAMA_MODEL}${NC}"
fi 