#!/bin/bash

# Odin Chat Assistant - Local Development Setup Script
# This script sets up the local development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Python
    if ! command_exists python3; then
        print_error "Python 3 is not installed. Please install Python 3.11 or later."
        exit 1
    fi
    
    python_version=$(python3 --version | grep -oE '[0-9]+\.[0-9]+')
    if (( $(echo "$python_version < 3.11" | bc -l) 2>/dev/null || echo 0 )); then
        print_warning "Python version $python_version detected. Python 3.11+ is recommended."
    else
        print_success "Python $python_version found"
    fi
    
    # Check pip
    if ! command_exists pip3 && ! python3 -m pip --version >/dev/null 2>&1; then
        print_error "pip is not installed. Please install pip."
        exit 1
    fi
    print_success "pip found"
}

# Function to setup Python virtual environment
setup_virtual_environment() {
    print_status "Setting up Python virtual environment..."
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_status "Virtual environment already exists"
    fi
    
    # Activate virtual environment
    print_status "Activating virtual environment..."
    source venv/bin/activate
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    print_success "Virtual environment ready"
}

# Function to install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    cd src
    pip install -r requirements.txt
    cd ..
    
    print_success "Dependencies installed successfully"
}

# Function to setup environment configuration
setup_environment_config() {
    print_status "Setting up environment configuration..."
    
    if [ ! -f "src/.env" ]; then
        print_status "Copying .env.sample to .env..."
        cp src/.env.sample src/.env
        print_success "Environment file created: src/.env"
        
        print_warning "IMPORTANT: You need to update src/.env with your Azure service values"
        print_status "Required values include:"
        echo "  - Azure OpenAI endpoint and deployment"
        echo "  - Azure AI Search service details"
        echo "  - Cosmos DB connection information"
        echo "  - Azure Storage account details"
        echo "  - Application Insights connection string"
        echo ""
        print_status "See DEPLOYMENT.md for instructions on getting these values from your Azure deployment"
    else
        print_status "Environment file already exists: src/.env"
        print_warning "Please ensure src/.env contains valid Azure service values"
    fi
}

# Function to verify local setup
verify_setup() {
    print_status "Verifying local setup..."
    
    # Check if we can import the main modules
    cd src
    if python3 -c "import flask, azure.cosmos, azure.search.documents; print('Core imports successful')" 2>/dev/null; then
        print_success "Python dependencies are correctly installed"
    else
        print_error "Some Python dependencies are missing or incorrectly installed"
        print_status "Try running: pip install -r requirements.txt"
        cd ..
        return 1
    fi
    cd ..
    
    # Check environment file
    if [ -f "src/.env" ]; then
        # Basic validation of .env file
        if grep -q "your-" src/.env; then
            print_warning ".env file contains placeholder values - you need to update it with real Azure values"
        else
            print_success "Environment configuration file looks updated"
        fi
    else
        print_error ".env file is missing"
        return 1
    fi
    
    print_success "Local setup verification completed"
}

# Function to provide instructions for running the app
show_run_instructions() {
    print_status "Local development setup completed!"
    echo ""
    print_success "To run the application locally:"
    echo "  1. Activate the virtual environment:"
    echo "     source venv/bin/activate"
    echo ""
    echo "  2. Navigate to the src directory:"
    echo "     cd src"
    echo ""
    echo "  3. Run the Flask application:"
    echo "     python app.py"
    echo ""
    echo "  4. Open your browser to:"
    echo "     http://localhost:5000"
    echo ""
    print_warning "BEFORE RUNNING:"
    echo "  - Update src/.env with your Azure service values"
    echo "  - Ensure your Azure services are deployed and accessible"
    echo "  - Test the health endpoint: http://localhost:5000/health"
    echo ""
    print_status "For Azure deployment, see DEPLOYMENT.md or run ./deploy.sh"
}

# Function to show Azure values extraction help
show_azure_values_help() {
    print_status "Getting Azure values for local development:"
    echo ""
    echo "If you have deployed to Azure, get the values with:"
    echo ""
    echo "1. Get deployment outputs:"
    echo "   az deployment sub show --name main --query 'properties.outputs' --output table"
    echo ""
    echo "2. Or get specific values:"
    echo "   # OpenAI Endpoint"
    echo "   az cognitiveservices account show --resource-group rg-<env-name> --name <openai-name> --query 'properties.endpoint'"
    echo ""
    echo "   # Search Service"
    echo "   az search service show --resource-group rg-<env-name> --name <search-name>"
    echo ""
    echo "   # Cosmos DB"
    echo "   az cosmosdb show --resource-group rg-<env-name> --name <cosmos-name> --query 'documentEndpoint'"
    echo ""
    echo "   # Storage Account"
    echo "   az storage account show --resource-group rg-<env-name> --name <storage-name> --query 'primaryEndpoints.blob'"
    echo ""
    echo "3. Get API keys from Azure Portal or using Azure CLI with appropriate commands"
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} Odin Chat Assistant - Local Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "azure.yaml" ] || [ ! -d "src" ]; then
        print_error "Please run this script from the root directory of the Odin project"
        exit 1
    fi
    
    check_prerequisites
    setup_virtual_environment
    install_dependencies
    setup_environment_config
    
    if verify_setup; then
        show_run_instructions
        echo ""
        show_azure_values_help
    else
        print_error "Setup verification failed. Please check the errors above and try again."
        exit 1
    fi
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi