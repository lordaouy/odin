#!/bin/bash

# Odin Chat Assistant - Quick Deployment Script
# This script automates the deployment of the Odin chat assistant to Azure

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

# Function to get user input
get_input() {
    local prompt=$1
    local var_name=$2
    local default_value=$3
    
    if [ -n "$default_value" ]; then
        read -p "$prompt [$default_value]: " input
        if [ -z "$input" ]; then
            input=$default_value
        fi
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            print_warning "This field is required."
            read -p "$prompt: " input
        done
    fi
    
    eval "$var_name='$input'"
}

# Function to validate Azure CLI login
check_azure_login() {
    if ! az account show >/dev/null 2>&1; then
        print_error "You are not logged in to Azure CLI. Please run 'az login' first."
        exit 1
    fi
    print_success "Azure CLI authentication verified"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Azure CLI
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI found"
    
    # Check Python
    if ! command_exists python3; then
        print_error "Python 3 is not installed. Please install Python 3.11 or later."
        exit 1
    fi
    
    python_version=$(python3 --version | grep -oE '[0-9]+\.[0-9]+')
    if (( $(echo "$python_version < 3.11" | bc -l) )); then
        print_warning "Python version $python_version detected. Python 3.11+ is recommended."
    else
        print_success "Python $python_version found"
    fi
    
    # Check Git
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git."
        exit 1
    fi
    print_success "Git found"
    
    check_azure_login
}

# Function to get deployment parameters
get_deployment_parameters() {
    print_status "Gathering deployment parameters..."
    
    # Get current user principal ID
    AZURE_PRINCIPAL_ID=$(az ad signed-in-user show --query objectId --output tsv 2>/dev/null || echo "")
    if [ -z "$AZURE_PRINCIPAL_ID" ]; then
        print_warning "Could not automatically retrieve your user principal ID."
        get_input "Enter your Azure AD user principal ID" AZURE_PRINCIPAL_ID
    else
        print_success "Using principal ID: $AZURE_PRINCIPAL_ID"
    fi
    
    # Get environment name
    get_input "Enter environment name (e.g., dev, test, prod)" AZURE_ENV_NAME "dev"
    
    # Get Azure region
    get_input "Enter Azure region" AZURE_LOCATION "eastus"
    
    # Confirm subscription
    current_subscription=$(az account show --query name --output tsv)
    print_status "Current subscription: $current_subscription"
    read -p "Continue with this subscription? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        print_status "Available subscriptions:"
        az account list --query "[].{Name:name, SubscriptionId:id}" --output table
        get_input "Enter subscription ID to use" subscription_id
        az account set --subscription "$subscription_id"
        print_success "Switched to subscription: $(az account show --query name --output tsv)"
    fi
}

# Function to deploy infrastructure using Azure CLI
deploy_infrastructure() {
    print_status "Deploying Azure infrastructure..."
    
    # Create deployment name with timestamp
    deployment_name="odin-deployment-$(date +%Y%m%d-%H%M%S)"
    
    # Deploy the infrastructure
    print_status "Starting infrastructure deployment (this may take 10-15 minutes)..."
    
    deployment_result=$(az deployment sub create \
        --location "$AZURE_LOCATION" \
        --template-file infra/main.bicep \
        --parameters environmentName="$AZURE_ENV_NAME" \
                     location="$AZURE_LOCATION" \
                     principalId="$AZURE_PRINCIPAL_ID" \
        --name "$deployment_name" \
        --query "properties.provisioningState" \
        --output tsv)
    
    if [ "$deployment_result" = "Succeeded" ]; then
        print_success "Infrastructure deployment completed successfully"
        
        # Get resource group name
        RESOURCE_GROUP="rg-$AZURE_ENV_NAME"
        print_status "Resources deployed to resource group: $RESOURCE_GROUP"
        
        # List deployed resources
        print_status "Deployed resources:"
        az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,Type:type}" --output table
        
    else
        print_error "Infrastructure deployment failed with status: $deployment_result"
        print_error "Check the deployment logs in Azure portal for details"
        exit 1
    fi
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application..."
    
    # Get App Service name
    app_service_name=$(az webapp list --resource-group "rg-$AZURE_ENV_NAME" --query "[0].name" --output tsv)
    
    if [ -z "$app_service_name" ]; then
        print_error "Could not find App Service in resource group rg-$AZURE_ENV_NAME"
        exit 1
    fi
    
    print_status "Deploying to App Service: $app_service_name"
    
    # Create deployment package
    print_status "Creating deployment package..."
    cd src
    zip -r ../app.zip . -x "__pycache__/*" "*.pyc" ".env*" "*.log" || {
        print_error "Failed to create deployment package"
        exit 1
    }
    cd ..
    
    # Deploy to App Service
    print_status "Uploading application to Azure App Service..."
    az webapp deployment source config-zip \
        --resource-group "rg-$AZURE_ENV_NAME" \
        --name "$app_service_name" \
        --src app.zip || {
        print_error "Application deployment failed"
        exit 1
    }
    
    # Clean up deployment package
    rm -f app.zip
    
    print_success "Application deployed successfully"
    
    # Get application URL
    app_url=$(az webapp show --resource-group "rg-$AZURE_ENV_NAME" --name "$app_service_name" --query "defaultHostName" --output tsv)
    print_success "Application URL: https://$app_url"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Get App Service name and URL
    app_service_name=$(az webapp list --resource-group "rg-$AZURE_ENV_NAME" --query "[0].name" --output tsv)
    app_url=$(az webapp show --resource-group "rg-$AZURE_ENV_NAME" --name "$app_service_name" --query "defaultHostName" --output tsv)
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    if curl -f -s "https://$app_url/health" >/dev/null; then
        print_success "Health endpoint is responding"
    else
        print_warning "Health endpoint is not responding. The application may still be starting up."
        print_status "You can check the application logs with:"
        print_status "az webapp log tail --resource-group rg-$AZURE_ENV_NAME --name $app_service_name"
    fi
    
    # Show application URL
    print_success "Deployment completed!"
    print_status "Application URL: https://$app_url"
    print_status "Health URL: https://$app_url/health"
}

# Function to show post-deployment steps
show_post_deployment_steps() {
    print_status "Post-deployment steps:"
    echo ""
    echo "1. Open your application: https://$app_url"
    echo "2. For local development, update src/.env with the deployed values:"
    echo "   - Copy src/.env.sample to src/.env"
    echo "   - Get values from: az deployment sub show --name main --query properties.outputs"
    echo ""
    echo "3. To upload documents for search functionality:"
    echo "   - Go to Azure Portal > Storage Account > Containers > docs"
    echo "   - Upload your documents"
    echo "   - Configure search indexing"
    echo ""
    echo "4. Monitor your application:"
    echo "   - Application Insights: Check logs and metrics"
    echo "   - App Service: Monitor performance and scale as needed"
    echo ""
    echo "5. For production use:"
    echo "   - Configure authentication (Azure AD)"
    echo "   - Set up custom domain and SSL"
    echo "   - Configure backup and disaster recovery"
    echo ""
    print_status "Deployment guide: See DEPLOYMENT.md for detailed instructions"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Odin Chat Assistant Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -f "azure.yaml" ] || [ ! -d "infra" ]; then
        print_error "Please run this script from the root directory of the Odin project"
        exit 1
    fi
    
    check_prerequisites
    get_deployment_parameters
    
    echo ""
    print_status "Deployment Summary:"
    echo "  Environment: $AZURE_ENV_NAME"
    echo "  Location: $AZURE_LOCATION"
    echo "  Principal ID: $AZURE_PRINCIPAL_ID"
    echo "  Subscription: $(az account show --query name --output tsv)"
    echo ""
    
    read -p "Continue with deployment? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        print_status "Deployment cancelled"
        exit 0
    fi
    
    deploy_infrastructure
    deploy_application
    verify_deployment
    show_post_deployment_steps
    
    print_success "Deployment completed successfully!"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi