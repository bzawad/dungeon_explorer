#!/bin/bash

# Development Quality Fix and Check Script
# This script runs quality fixes and validations including:
# 1. Auto-format code (fixes formatting issues)
# 2. Static analysis with Dialyzer
# 3. Code quality checks with Credo
# 4. Test suite execution

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
    echo -e "${PURPLE}🔧 STEP $step_num: $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to handle errors gracefully
handle_error() {
    local step_name=$1
    echo -e "${RED}❌ $step_name failed!${NC}"
    echo -e "${RED}💡 Please review and fix the issues above${NC}"
    exit 1
}

# Start the development checks workflow
echo -e "${CYAN}🔧 DEVELOPMENT QUALITY FIX & CHECK${NC}"
echo -e "${CYAN}====================================${NC}"
echo -e "${BLUE}This will run quality fixes and validations:${NC}"
echo -e "${BLUE}• Auto-format code (fixes formatting issues)${NC}"
echo -e "${BLUE}• Run static analysis (Dialyzer)${NC}"
echo -e "${BLUE}• Perform code quality checks (Credo)${NC}"
echo -e "${BLUE}• Execute test suite${NC}"
echo -e "\n${CYAN}🚀 Starting development checks workflow...${NC}"

# Step 1: Code Auto-Formatting
print_step "1" "CODE AUTO-FORMATTING"
echo -e "${YELLOW}🎨 Auto-formatting code with mix format...${NC}"
echo -e "${BLUE}💡 This will automatically fix formatting issues in your code${NC}"
if ! mix format; then
    handle_error "Code auto-formatting"
fi
echo -e "${GREEN}✅ Code auto-formatting completed${NC}"

# Step 2: Static Analysis
print_step "2" "STATIC ANALYSIS (DIALYZER)"
echo -e "${YELLOW}🔬 Running static analysis with Dialyzer...${NC}"
echo -e "${BLUE}💡 Checking for type inconsistencies and potential bugs${NC}"
if ! mix dialyzer; then
    handle_error "Dialyzer static analysis"
fi
echo -e "${GREEN}✅ Static analysis completed successfully${NC}"

# Step 3: Code Quality Checks
print_step "3" "CODE QUALITY ANALYSIS (CREDO STRICT)"
echo -e "${YELLOW}📏 Running strict code quality checks with Credo...${NC}"
echo -e "${BLUE}💡 Analyzing code for consistency, readability, and best practices (strict mode)${NC}"
if ! mix credo --strict; then
    handle_error "Credo strict code quality analysis"
fi
echo -e "${GREEN}✅ Strict code quality analysis passed${NC}"

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
echo -e "${GREEN}🎉 ALL QUALITY CHECKS COMPLETED SUCCESSFULLY!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ Code has been formatted and validated - ready for commit!${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "${BLUE}• Review any changes made by auto-formatting${NC}"
echo -e "${BLUE}• Commit your changes: git add . && git commit${NC}"
echo -e "${BLUE}• Start development server: ./iex.sh${NC}"
