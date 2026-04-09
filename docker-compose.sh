#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to load existing .env file
load_env_file() {
    if [ -f .env ]; then
        echo -e "${BLUE}💡 Loading existing .env file...${NC}"
        # Source the .env file to get existing values
        set -a  # automatically export all variables
        source .env
        set +a  # stop automatically exporting
        echo -e "${GREEN}✅ Loaded existing .env configuration${NC}"
        return 0
    else
        echo -e "${YELLOW}💡 No existing .env file found${NC}"
        return 1
    fi
}

# Load existing .env file first
load_env_file

# Command line parameters (will override .env values if provided)
ENV=${1:-prod}
APP_PORT=${2:-${APP_PORT:-4000}}
OLLAMA_PORT=${3:-${OLLAMA_PORT:-11434}}
OLLAMA_MODEL=${4:-${OLLAMA_MODEL:-none}}

# Function to print step headers
print_step() {
    local step_num=$1
    local step_name=$2
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 STEP $step_num: $step_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to handle errors gracefully
handle_error() {
    local step_name=$1
    echo -e "${RED}❌ $step_name failed!${NC}"
    echo -e "${RED}💡 Please check the error above and try again${NC}"
    exit 1
}

# Create or update .env file for docker-compose
create_env_file() {
    print_step "1" "CREATING/UPDATING ENVIRONMENT FILE"
    
    if [ -f .env ]; then
        echo -e "${YELLOW}📝 Updating existing .env file...${NC}"
    else
        echo -e "${YELLOW}📝 Creating new .env file for $ENV environment...${NC}"
    fi
    
    cat > .env << EOL
APP_PORT=$APP_PORT
OLLAMA_PORT=$OLLAMA_PORT
OLLAMA_MODEL=$OLLAMA_MODEL
EOL
    
    echo -e "${GREEN}✅ Environment file configured${NC}"
    echo -e "${BLUE}💡 Current configuration:${NC}"
    echo -e "${BLUE}• App Port: $APP_PORT${NC}"
    echo -e "${BLUE}• Ollama Port: $OLLAMA_PORT${NC}"
    echo -e "${BLUE}• Ollama Model: $OLLAMA_MODEL${NC}"
}

# Build and start the app (which includes Ollama)
start_app() {
    print_step "2" "BUILDING AND STARTING APPLICATION"
    echo -e "${YELLOW}🚀 Building and starting the application (with integrated Ollama)...${NC}"
    echo -e "${BLUE}💡 Using configuration:${NC}"
    echo -e "${BLUE}• App Port: $APP_PORT${NC}"
    echo -e "${BLUE}• Ollama Port: $OLLAMA_PORT${NC}"
    echo -e "${BLUE}• Ollama Model: $OLLAMA_MODEL${NC}"
    echo -e "${BLUE}💡 This may take a few minutes for the first build...${NC}"
    
    if ! docker-compose up -d --build app; then
        handle_error "Building and starting application"
    fi
    
    echo -e "${GREEN}✅ Application container started${NC}"
}

# Wait for services to be ready
wait_for_services() {
    print_step "3" "WAITING FOR SERVICES TO BE READY"
    echo -e "${YELLOW}⏳ Waiting for Ollama and Phoenix to start up...${NC}"
    if [ "$OLLAMA_MODEL" != "none" ]; then
        echo -e "${BLUE}💡 This includes downloading the $OLLAMA_MODEL model on first run${NC}"
    fi
    
    local max_attempts=60  # Increased timeout for model download
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check if Phoenix app is responding
        if curl -f http://localhost:$APP_PORT/ >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Application is ready${NC}"
            break
        fi
        
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts - waiting for application...${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${RED}❌ Application failed to become ready${NC}"
        echo -e "${YELLOW}💡 Checking logs for more information:${NC}"
        docker-compose logs app
        handle_error "Application startup timeout"
    fi
}

# Verify everything is working
verify_setup() {
    print_step "4" "VERIFYING SETUP"
    echo -e "${YELLOW}🔍 Checking service health...${NC}"
    
    # Check Phoenix app
    if curl -f http://localhost:$APP_PORT/ >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Phoenix application is responding${NC}"
    else
        echo -e "${RED}❌ Phoenix application is not responding${NC}"
    fi
    
    # Check Ollama internally within the container
    if docker-compose exec -T app curl -f http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Ollama is ready internally${NC}"
    else
        echo -e "${RED}❌ Ollama is not ready internally${NC}"
    fi
    
    # Check if app container is running
    if docker-compose ps app | grep -q "Up"; then
        echo -e "${GREEN}✅ Application container is running${NC}"
    else
        echo -e "${RED}❌ Application container is not running${NC}"
    fi
}

# Main execution
echo -e "${BLUE}🚀 DOCKER COMPOSE SETUP FOR DUNGEON GAME${NC}"
echo -e "${BLUE}==================================${NC}"
echo -e "${YELLOW}📋 Environment: $ENV${NC}"
echo -e "${YELLOW}📋 App Port: $APP_PORT${NC}"
echo -e "${YELLOW}📋 Ollama Port: $OLLAMA_PORT${NC}"
echo -e "${YELLOW}📋 Ollama Model: $OLLAMA_MODEL${NC}"
echo -e "${BLUE}💡 Note: Ollama runs inside the app container${NC}"
echo -e "\n${BLUE}💡 Usage: $0 [environment] [app_port] [ollama_port] [ollama_model]${NC}"
echo -e "${BLUE}💡 Example: $0 prod 4000 11434 llama2${NC}"
echo -e "${BLUE}💡 Tip: Edit .env file directly to persist settings between runs${NC}"

create_env_file
start_app
wait_for_services
verify_setup

echo -e "\n${GREEN}🎉 SETUP COMPLETE!${NC}"
echo -e "\n${BLUE}📋 Access Points:${NC}"
echo -e "${BLUE}• Phoenix App: http://localhost:$APP_PORT${NC}"
echo -e "${BLUE}• Ollama API: http://localhost:$OLLAMA_PORT (if exposed)${NC}"
echo -e "\n${BLUE}🔧 Commands:${NC}"
echo -e "${BLUE}• View logs: docker-compose logs -f${NC}"
echo -e "${BLUE}• Stop: docker-compose down${NC}"
echo -e "${BLUE}• Restart: docker-compose restart${NC}"
echo -e "\n${BLUE}🔧 Configuration:${NC}"
echo -e "${BLUE}• Model: $OLLAMA_MODEL${NC}"
echo -e "${BLUE}• Change model: Edit .env file directly for persistence${NC}"
echo -e "${BLUE}• Override: Use command line parameters for one-time changes${NC}" 