# Odin Chat Assistant - Deployment Guide

This guide provides step-by-step instructions for deploying the Odin chat assistant application to Azure. The application is a Flask-based web application that leverages Azure OpenAI, Azure AI Search, Cosmos DB, and other Azure services.

## Architecture Overview

The application consists of:
- **Frontend**: Flask web application with HTML/CSS/JavaScript UI
- **Backend**: Python Flask API with LangGraph AI agent
- **Storage**: Azure Cosmos DB for chat history persistence
- **Search**: Azure AI Search for RAG (Retrieval Augmented Generation)
- **AI**: Azure OpenAI for chat completions and embeddings
- **Storage**: Azure Blob Storage for document storage
- **Monitoring**: Azure Application Insights for telemetry
- **Security**: Azure Key Vault for secrets management

## Prerequisites

Before deploying, ensure you have:

### 1. Software Requirements
- **Azure CLI**: Version 2.0.0 or later
- **Azure Developer CLI (azd)**: Latest version (recommended)
- **Python**: Version 3.11 or later
- **Git**: For source code management

### 2. Azure Requirements
- **Azure Subscription**: With sufficient permissions to create resources
- **Azure Account**: With at least Contributor role on the subscription
- **Resource Group**: Or permissions to create one
- **Azure OpenAI Access**: Your subscription must have access to Azure OpenAI services

### 3. Service Limits
Ensure your Azure subscription has adequate quota for:
- Azure OpenAI deployments
- Cosmos DB accounts
- Azure AI Search services
- App Service plans
- Storage accounts

## Step 1: Environment Setup

### Install Required Tools

1. **Install Azure CLI**:
   ```bash
   # Windows
   winget install Microsoft.AzureCLI
   
   # macOS
   brew install azure-cli
   
   # Linux (Ubuntu/Debian)
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Install Azure Developer CLI** (recommended):
   ```bash
   # Windows
   winget install Microsoft.Azd
   
   # macOS
   brew install azure-dev
   
   # Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

3. **Verify installations**:
   ```bash
   az --version
   azd version  # if installed
   python3 --version
   ```

### Expected Output:
- Azure CLI version 2.0.0+
- Python version 3.11+
- azd version (if using Azure Developer CLI)

## Step 2: Authentication and Preparation

### Authenticate with Azure

1. **Login to Azure**:
   ```bash
   az login
   ```
   
2. **Set your subscription** (if you have multiple):
   ```bash
   az account list --output table
   az account set --subscription "Your-Subscription-Name-or-ID"
   ```

3. **Get your Azure AD user principal ID** (needed for deployment):
   ```bash
   az ad signed-in-user show --query objectId --output tsv
   ```
   Save this ID - you'll need it for the deployment.

### Expected Output:
- Successful login confirmation
- List of available subscriptions
- Your user principal ID (a GUID)

## Step 3: Clone and Prepare the Repository

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lordaouy/odin.git
   cd odin
   ```

2. **Install Python dependencies** (for local testing):
   ```bash
   cd src
   pip install -r requirements.txt
   cd ..
   ```

### Expected Output:
- Repository cloned successfully
- Python dependencies installed without errors

## Step 4: Infrastructure Deployment

### Option A: Using Azure Developer CLI (Recommended)

1. **Initialize the Azure Developer environment**:
   ```bash
   azd init
   ```

2. **Set required environment variables**:
   ```bash
   azd env set AZURE_LOCATION "eastus"  # or your preferred region
   azd env set AZURE_PRINCIPAL_ID "your-principal-id-from-step-2"
   ```

3. **Deploy the infrastructure and application**:
   ```bash
   azd up
   ```

### Option B: Using Azure CLI and Bicep

1. **Set environment variables**:
   ```bash
   export AZURE_ENV_NAME="odin-dev"  # or your preferred environment name
   export AZURE_LOCATION="eastus"    # or your preferred region
   export AZURE_PRINCIPAL_ID="your-principal-id-from-step-2"
   ```

2. **Deploy the infrastructure**:
   ```bash
   az deployment sub create \
     --location $AZURE_LOCATION \
     --template-file infra/main.bicep \
     --parameters environmentName=$AZURE_ENV_NAME \
                  location=$AZURE_LOCATION \
                  principalId=$AZURE_PRINCIPAL_ID
   ```

### Expected Output:
The deployment will create the following Azure resources:
- Resource Group (e.g., `rg-odin-dev`)
- Azure OpenAI Service with chat and embedding deployments
- Azure AI Search Service
- Cosmos DB Account with database and container
- Azure App Service and App Service Plan
- Azure Storage Account with blob container
- Azure Key Vault
- Azure Application Insights
- Log Analytics Workspace

**Deployment time**: Approximately 10-15 minutes

## Step 5: Post-Deployment Configuration

### 1. Verify Resource Deployment

Check that all resources were created successfully:
```bash
# List resources in your resource group
az resource list --resource-group "rg-$AZURE_ENV_NAME" --output table
```

### Expected Output:
You should see approximately 10-12 Azure resources listed, including:
- OpenAI service
- Search service  
- Cosmos DB account
- App Service
- Storage account
- Key Vault
- Application Insights

### 2. Configure Azure AI Search Index

The search service needs to be configured with document indexing:

1. **Navigate to the search service**:
   ```bash
   # Get the search service name
   az search service list --resource-group "rg-$AZURE_ENV_NAME" --query "[0].name" -o tsv
   ```

2. **Configure the search index** (if using custom documents):
   - Upload your documents to the storage account's 'docs' container
   - Use the Azure portal or the provided script to configure indexing
   - Update the search configuration in `infra/search-subresources/`

### Expected Output:
- Search service name retrieved
- Documents uploaded to storage (if applicable)
- Search index configured and populated

## Step 6: Application Deployment

### Option A: Automatic Deployment (with azd)

If you used `azd up`, the application is already deployed. Skip to Step 7.

### Option B: Manual Application Deployment

1. **Get the App Service name**:
   ```bash
   az webapp list --resource-group "rg-$AZURE_ENV_NAME" --query "[0].name" -o tsv
   ```

2. **Deploy the application**:
   ```bash
   # Navigate to source directory
   cd src
   
   # Create a deployment package
   zip -r ../app.zip . -x "__pycache__/*" "*.pyc" ".env*"
   cd ..
   
   # Deploy to App Service
   az webapp deployment source config-zip \
     --resource-group "rg-$AZURE_ENV_NAME" \
     --name "your-app-service-name" \
     --src app.zip
   ```

### Expected Output:
- App Service name retrieved
- Application package created and deployed successfully
- Deployment status shows as "Succeeded"

## Step 7: Verify Deployment

### 1. Check Application Health

1. **Get the application URL**:
   ```bash
   az webapp show --resource-group "rg-$AZURE_ENV_NAME" --name "your-app-service-name" --query "defaultHostName" -o tsv
   ```

2. **Test the health endpoint**:
   ```bash
   curl https://your-app-url.azurewebsites.net/health
   ```

### Expected Output:
- Application URL retrieved (e.g., `your-app-name.azurewebsites.net`)
- Health endpoint returns "OK"

### 2. Test the Application

1. **Open the application in a browser**:
   ```
   https://your-app-url.azurewebsites.net
   ```

2. **Verify functionality**:
   - Application loads without errors
   - You can see the chat interface
   - Basic navigation works

### Expected Output:
- Application loads successfully in browser
- Chat interface is visible and responsive
- No JavaScript console errors

## Step 8: Environment Variables and Configuration

### Verify Environment Variables

Check that all required environment variables are set in the App Service:

```bash
az webapp config appsettings list --resource-group "rg-$AZURE_ENV_NAME" --name "your-app-service-name" --output table
```

### Required Environment Variables:
- `AZURE_OPENAI_ENDPOINT`
- `AZURE_OPENAI_DEPLOYMENT`
- `AZURE_OPENAI_VERSION`
- `AZURE_AI_SEARCH_SERVICE_NAME`
- `AZURE_AI_SEARCH_INDEX_NAME`
- `COSMOS_ACCOUNT_URI`
- `COSMOS_DB_NAME`
- `COSMOS_CONTAINER_NAME`
- `AZURE_STORAGE_ENDPOINT`
- `AZURE_APP_INSIGHTS_CONN_STR`

### Expected Output:
All required environment variables should be present with non-empty values.

## Local Development Setup

### 1. Environment Configuration

1. **Copy the sample environment file**:
   ```bash
   cd src
   cp .env.sample .env
   ```

2. **Update the .env file** with values from your Azure deployment:
   ```bash
   # Get values from Azure
   az deployment sub show --name "main" --query "properties.outputs" --output table
   ```

3. **Fill in the .env file**:
   ```env
   AZURE_OPENAI_ENDPOINT=https://your-openai-service.openai.azure.com/
   AZURE_OPENAI_DEPLOYMENT=chat
   AZURE_OPENAI_VERSION=2024-08-01-preview
   AZURE_AI_SEARCH_SERVICE_NAME=your-search-service
   AZURE_AI_SEARCH_INDEX_NAME=claims-index
   COSMOS_ACCOUNT_URI=https://your-cosmos-account.documents.azure.com:443/
   COSMOS_DB_NAME=chathistory
   COSMOS_CONTAINER_NAME=messages
   AZURE_STORAGE_ENDPOINT=https://yourstorageaccount.blob.core.windows.net/
   IS_DEPLOYED=False
   LANGCHAIN_TRACING_V2=False
   ```

### 2. Local Development

1. **Run the application locally**:
   ```bash
   cd src
   python app.py
   ```

2. **Access the local application**:
   ```
   http://localhost:5000
   ```

### Expected Output:
- Flask development server starts successfully
- Application accessible at localhost:5000
- All Azure service connections work properly

## Troubleshooting

### Common Issues and Solutions

#### 1. Azure OpenAI Access Denied
**Problem**: "Access denied" errors when calling Azure OpenAI
**Solution**: 
- Verify your subscription has Azure OpenAI access
- Check that the managed identity has proper permissions
- Ensure the OpenAI resource is deployed in a supported region

#### 2. Cosmos DB Connection Issues
**Problem**: Cannot connect to Cosmos DB
**Solution**:
- Verify the Cosmos DB firewall settings allow your App Service
- Check that the managed identity has appropriate Cosmos DB roles
- Ensure the database and container were created successfully

#### 3. Search Service Configuration
**Problem**: Search queries return no results
**Solution**:
- Verify documents are uploaded to the storage container
- Check that the search index is properly configured
- Ensure the indexer has run successfully

#### 4. App Service Deployment Failures
**Problem**: Application fails to start in App Service
**Solution**:
- Check App Service logs: `az webapp log tail --resource-group "rg-$AZURE_ENV_NAME" --name "your-app-name"`
- Verify all environment variables are set correctly
- Check Python version compatibility (should be 3.11)

#### 5. Permission Issues
**Problem**: "Insufficient permissions" errors
**Solution**:
- Verify your Azure account has Contributor access to the resource group
- Check that the principal ID used in deployment is correct
- Ensure managed identity permissions were assigned correctly

### Getting Help

1. **Check App Service logs**:
   ```bash
   az webapp log tail --resource-group "rg-$AZURE_ENV_NAME" --name "your-app-name"
   ```

2. **View deployment logs**:
   ```bash
   az deployment sub show --name "main" --query "properties"
   ```

3. **Check resource status**:
   ```bash
   az resource list --resource-group "rg-$AZURE_ENV_NAME" --query "[].{Name:name,Type:type,Status:status}" --output table
   ```

## Cleanup

To remove all deployed resources:

### Using Azure Developer CLI:
```bash
azd down
```

### Using Azure CLI:
```bash
az group delete --resource-group "rg-$AZURE_ENV_NAME" --yes --no-wait
```

**Warning**: This will permanently delete all resources and data. Ensure you have backups if needed.

## Security Considerations

1. **Secrets Management**: All secrets are stored in Azure Key Vault
2. **Network Security**: Consider using private endpoints for production
3. **Authentication**: Implement proper authentication for production use
4. **RBAC**: Use least-privilege access principles
5. **Monitoring**: Enable security monitoring through Azure Security Center

## Next Steps

After successful deployment:

1. **Configure Authentication**: Set up Azure AD authentication for production use
2. **Upload Documents**: Add your documents to Azure Storage for RAG functionality
3. **Customize UI**: Modify the Flask templates to match your branding
4. **Monitor Usage**: Set up alerts and monitoring dashboards
5. **Scale Configuration**: Adjust App Service plan and Cosmos DB settings based on usage

## Support

For issues specific to this deployment:
1. Check the troubleshooting section above
2. Review Azure portal for resource-specific errors
3. Check the application logs in App Service
4. Consult Azure documentation for service-specific issues