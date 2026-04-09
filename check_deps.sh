#!/bin/bash

# Check Dependencies Script
# This script checks for outdated Hex dependencies in your Elixir project
# Uses: mix hex.outdated

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
    local step_name=$1
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}📦 $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Start the dependency check process
echo -e "${CYAN}📦 DEPENDENCY OUTDATED CHECK${NC}"
echo -e "${CYAN}=============================${NC}"
echo -e "${BLUE}This will check for outdated Hex dependencies in your project${NC}"
echo -e "${BLUE}• Analyzes current dependencies in mix.exs${NC}"
echo -e "${BLUE}• Compares with latest versions on Hex.pm${NC}"
echo -e "${BLUE}• Shows which packages can be updated${NC}"
echo -e "\n${CYAN}🔍 Checking for outdated dependencies...${NC}"

# Check Dependencies
print_step "CHECKING OUTDATED DEPENDENCIES"
echo -e "${YELLOW}🔍 Running mix hex.outdated...${NC}"
echo -e "${BLUE}💡 This compares your current dependencies with the latest versions${NC}"

# Run the command and capture output
if mix hex.outdated; then
    echo -e "\n${GREEN}✅ Dependency check completed successfully${NC}"
else
    echo -e "\n${RED}❌ Failed to check dependencies${NC}"
    echo -e "${BLUE}💡 Make sure you're in an Elixir project directory${NC}"
    echo -e "${BLUE}💡 Try running: mix deps.get${NC}"
    exit 1
fi

# Final message
echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 DEPENDENCY CHECK COMPLETE!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ Dependency analysis complete!${NC}"
echo -e "\n${BLUE}📋 What the output means:${NC}"
echo -e "${BLUE}• Green packages: Up to date${NC}"
echo -e "${BLUE}• Yellow packages: Minor updates available${NC}"
echo -e "${BLUE}• Red packages: Major updates available${NC}"
echo -e "\n${BLUE}🔄 Next steps:${NC}"
echo -e "${BLUE}• Update all dependencies: ./update_deps.sh${NC}"
echo -e "${BLUE}• Update manually: mix deps.update package_name${NC}"
echo -e "${BLUE}• Update all manually: mix deps.update --all${NC}"
echo -e "\n${BLUE}💡 Tip: Review CHANGELOG files before updating major versions${NC}" 