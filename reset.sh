#!/bin/bash

# Development Environment Reset Script
# This script resets the development environment including:
# 1. Installing/updating dependencies
# 2. Cleaning build artifacts
# 3. Rebuilding assets
# 4. Running tests to verify everything works

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
    echo -e "${PURPLE}🔄 STEP $step_num: $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Start the development environment reset process
echo -e "${CYAN}🔄 DEVELOPMENT ENVIRONMENT RESET${NC}"
echo -e "${CYAN}===================================${NC}"
echo -e "${BLUE}This will perform a complete development environment reset:${NC}"
echo -e "${BLUE}• Install/update dependencies${NC}"
echo -e "${BLUE}• Clean build artifacts${NC}"
echo -e "${BLUE}• Rebuild assets (CSS/JS)${NC}"
echo -e "${BLUE}• Run tests to verify everything works${NC}"
echo -e "\n${CYAN}🚀 Starting development environment reset...${NC}"

# Step 1: Dependencies
print_step "1" "INSTALLING/UPDATING DEPENDENCIES"
echo -e "${YELLOW}📦 Installing and updating Mix dependencies...${NC}"
mix deps.get
echo -e "${GREEN}✅ Dependencies updated successfully${NC}"

# Step 2: Clean Build Artifacts
print_step "2" "CLEANING BUILD ARTIFACTS"
echo -e "${YELLOW}🧹 Cleaning compiled files and build artifacts...${NC}"
echo -e "${BLUE}💡 This removes _build directory and compiled beam files${NC}"
mix clean
echo -e "${GREEN}✅ Build artifacts cleaned successfully${NC}"

# Step 3: Rebuild Assets
print_step "3" "REBUILDING ASSETS"
echo -e "${YELLOW}🎨 Rebuilding CSS and JavaScript assets...${NC}"
echo -e "${BLUE}💡 This will install npm dependencies, Tailwind CSS and ESBuild assets${NC}"

# Install npm dependencies first
echo -e "${YELLOW}📦 Installing npm dependencies...${NC}"
cd assets && npm install && cd ..

# Then setup and build assets
mix assets.setup
mix assets.build
echo -e "${GREEN}✅ Assets rebuilt successfully${NC}"

# Step 4: Compile Application
print_step "4" "COMPILING APPLICATION"
echo -e "${YELLOW}⚙️  Compiling Elixir application...${NC}"
echo -e "${BLUE}💡 This ensures all code compiles without errors${NC}"
# Ensure consolidated directory exists to prevent compilation errors
mkdir -p _build/dev/lib/dungeon/consolidated
mix compile
echo -e "${GREEN}✅ Application compiled successfully${NC}"

# Step 5: Run Tests
print_step "5" "RUNNING TESTS"
echo -e "${YELLOW}🧪 Running test suite to verify everything works...${NC}"
echo -e "${BLUE}💡 This ensures the reset was successful${NC}"
mix test
echo -e "${GREEN}✅ All tests passed successfully${NC}"

# Final success message
echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 DEVELOPMENT ENVIRONMENT RESET SUCCESSFUL!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ Development environment is now clean and ready!${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "${BLUE}• Start development server: ./iex.sh${NC}"
echo -e "${BLUE}• Or start Phoenix server: mix phx.server${NC}"
echo -e "${BLUE}• Run quality checks: ./checks.sh${NC}"
