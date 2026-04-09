#!/bin/bash

# Development Quality Check and Server Script
# This script runs a complete development workflow including:
# 1. Code formatting validation
# 2. Static analysis with Dialyzer
# 3. Code quality checks with Credo
# 4. Test suite execution
# 5. Phoenix development server startup

set -e  # Exit on any error (except for the server at the end)

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
    echo -e "${PURPLE}🔍 STEP $step_num: $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to handle errors gracefully
handle_error() {
    local step_name=$1
    echo -e "${RED}❌ $step_name failed!${NC}"
    echo -e "${RED}💡 Please fix the issues above before continuing${NC}"
    exit 1
}

# Start the development workflow
echo -e "${CYAN}🛠️  DEVELOPMENT QUALITY CHECK & SERVER${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${BLUE}This will run the complete development workflow:${NC}"
echo -e "${BLUE}• Check code formatting${NC}"
echo -e "${BLUE}• Run static analysis (Dialyzer)${NC}"
echo -e "${BLUE}• Perform code quality checks (Credo)${NC}"
echo -e "${BLUE}• Execute test suite${NC}"
echo -e "${BLUE}• Start Phoenix development server${NC}"
echo -e "\n${CYAN}🚀 Starting development workflow...${NC}"

# Step 1: Code Formatting Check
print_step "1" "CODE FORMATTING VALIDATION"
echo -e "${YELLOW}🎨 Checking code formatting with mix format...${NC}"
echo -e "${BLUE}💡 Ensuring all Elixir code follows consistent formatting${NC}"
if ! mix format --check-formatted; then
    handle_error "Code formatting check"
fi
echo -e "${GREEN}✅ Code formatting validation passed${NC}"

# Step 2: Static Analysis
print_step "2" "STATIC ANALYSIS (DIALYZER)"
echo -e "${YELLOW}🔬 Running static analysis with Dialyzer...${NC}"
echo -e "${BLUE}💡 Checking for type inconsistencies and potential bugs${NC}"
if ! mix dialyzer; then
    handle_error "Dialyzer static analysis"
fi
echo -e "${GREEN}✅ Static analysis completed successfully${NC}"

# Step 3: Code Quality Checks
print_step "3" "CODE QUALITY ANALYSIS (CREDO)"
echo -e "${YELLOW}📏 Running code quality checks with Credo...${NC}"
echo -e "${BLUE}💡 Analyzing code for consistency, readability, and best practices${NC}"
if ! mix credo; then
    handle_error "Credo code quality check"
fi
echo -e "${GREEN}✅ Code quality analysis passed${NC}"

# Step 4: Test Suite
print_step "4" "TEST SUITE EXECUTION"
echo -e "${YELLOW}🧪 Running complete test suite...${NC}"
echo -e "${BLUE}💡 Executing all unit tests, integration tests, and feature tests${NC}"
if ! mix test; then
    handle_error "Test suite execution"
fi
echo -e "${GREEN}✅ All tests passed successfully${NC}"

# Quality checks complete
echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 ALL QUALITY CHECKS PASSED!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ Code quality validated - ready for development!${NC}"

# Step 5: Phoenix Server
print_step "5" "PHOENIX DEVELOPMENT SERVER"
echo -e "${YELLOW}🌐 Starting Phoenix development server...${NC}"
echo -e "${BLUE}💡 Server will be available at http://localhost:4000${NC}"
echo -e "${BLUE}💡 Press Ctrl+C to stop the server${NC}"
echo -e "\n${GREEN}🚀 Launching server...${NC}"

# Disable exit on error for the server (so it can run indefinitely)
set +e
mix phx.server
