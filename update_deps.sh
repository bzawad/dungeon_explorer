#!/bin/bash

# Update Dependencies Script
# This script updates all Hex dependencies in your Elixir project
# Uses: mix deps.update --all

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
    echo -e "${PURPLE}📦 STEP $step_num: $step_name${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Start the dependency update process
echo -e "${CYAN}📦 DEPENDENCY UPDATE${NC}"
echo -e "${CYAN}====================${NC}"
echo -e "${BLUE}This will update ALL Hex dependencies in your project${NC}"
echo -e "${BLUE}• Updates all packages to their latest compatible versions${NC}"
echo -e "${BLUE}• Respects version constraints in mix.exs${NC}"
echo -e "${BLUE}• Downloads and compiles updated packages${NC}"
echo -e "\n${YELLOW}⚠️  This will modify your mix.lock file${NC}"
echo -e "${YELLOW}⚠️  Make sure to test your application after updating${NC}"
echo -e "\n${CYAN}🚀 Starting dependency update...${NC}"

# Step 1: Check Current Status
print_step "1" "CHECKING CURRENT DEPENDENCIES"
echo -e "${YELLOW}📋 Checking current dependency status...${NC}"
echo -e "${BLUE}💡 This shows what will be updated${NC}"

# Show current outdated dependencies
if mix hex.outdated --all 2>/dev/null; then
    echo -e "${GREEN}✅ Current dependency status checked${NC}"
else
    echo -e "${YELLOW}⚠️  Could not check current status, but continuing with update${NC}"
fi

# Step 2: Update Dependencies
print_step "2" "UPDATING ALL DEPENDENCIES"
echo -e "${YELLOW}📦 Running mix deps.update --all...${NC}"
echo -e "${BLUE}💡 This will update all dependencies to their latest compatible versions${NC}"
echo -e "${BLUE}💡 This may take a few minutes depending on the number of updates${NC}"

# Run the update command
if mix deps.update --all; then
    echo -e "\n${GREEN}✅ Dependencies updated successfully${NC}"
else
    echo -e "\n${RED}❌ Failed to update dependencies${NC}"
    echo -e "${BLUE}💡 Check the error messages above${NC}"
    echo -e "${BLUE}💡 You may need to resolve version conflicts manually${NC}"
    exit 1
fi

# Step 3: Compile Updated Dependencies
print_step "3" "COMPILING UPDATED DEPENDENCIES"
echo -e "${YELLOW}⚙️  Compiling updated dependencies...${NC}"
echo -e "${BLUE}💡 This ensures all updated packages compile correctly${NC}"

if mix deps.compile; then
    echo -e "${GREEN}✅ Dependencies compiled successfully${NC}"
else
    echo -e "${RED}❌ Failed to compile dependencies${NC}"
    echo -e "${BLUE}💡 Check for compilation errors above${NC}"
    echo -e "${BLUE}💡 You may need to fix compatibility issues${NC}"
    exit 1
fi

# Step 4: Verify Application Compiles
print_step "4" "VERIFYING APPLICATION"
echo -e "${YELLOW}🔍 Verifying application compiles with updated dependencies...${NC}"
echo -e "${BLUE}💡 This ensures your application works with the updates${NC}"

if mix compile; then
    echo -e "${GREEN}✅ Application compiles successfully${NC}"
else
    echo -e "${RED}❌ Application failed to compile${NC}"
    echo -e "${BLUE}💡 You may need to update your code for compatibility${NC}"
    echo -e "${BLUE}💡 Check deprecation warnings and breaking changes${NC}"
    exit 1
fi

# Step 5: Run Tests (Optional)
print_step "5" "RUNNING TESTS"
echo -e "${YELLOW}🧪 Running tests to verify everything still works...${NC}"
echo -e "${BLUE}💡 This helps catch any issues introduced by updates${NC}"

if mix test; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed${NC}"
    echo -e "${BLUE}💡 Review test failures - they may be related to dependency updates${NC}"
    echo -e "${BLUE}💡 Consider this a warning, not a fatal error${NC}"
fi

# Final success message
echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 DEPENDENCY UPDATE COMPLETE!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${CYAN}✨ All dependencies have been updated!${NC}"
echo -e "\n${BLUE}📋 What was updated:${NC}"
echo -e "${BLUE}• mix.lock file contains new dependency versions${NC}"
echo -e "${BLUE}• All packages compiled successfully${NC}"
echo -e "${BLUE}• Application compiles with updated dependencies${NC}"
echo -e "${BLUE}• Tests were run to verify compatibility${NC}"
echo -e "\n${BLUE}🔄 Next steps:${NC}"
echo -e "${BLUE}• Test your application thoroughly${NC}"
echo -e "${BLUE}• Check for any deprecation warnings${NC}"
echo -e "${BLUE}• Review changelogs for major version updates${NC}"
echo -e "${BLUE}• Commit the updated mix.lock file${NC}"
echo -e "\n${BLUE}🔧 If you encounter issues:${NC}"
echo -e "${BLUE}• Check specific package: ./check_deps.sh${NC}"
echo -e "${BLUE}• Revert mix.lock: git checkout mix.lock${NC}"
echo -e "${BLUE}• Update specific package: mix deps.update package_name${NC}" 