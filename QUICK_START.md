# Odin Chat Assistant - Quick Start Guide

This guide gets you up and running with the Odin chat assistant in minutes.

## What is Odin?
Odin is an AI-powered chat assistant built with:
- **Azure OpenAI** for intelligent responses
- **Azure AI Search** for document search and RAG
- **Azure Cosmos DB** for chat history persistence  
- **Flask** web framework for the user interface
- **LangGraph** for AI agent workflows

## Prerequisites
- Azure subscription with OpenAI access
- Azure CLI installed
- Python 3.11+ installed
- Git installed

## Option 1: Deploy to Azure (Recommended for Testing)

**Time Required**: ~15 minutes

1. **Clone and prepare**:
   ```bash
   git clone https://github.com/lordaouy/odin.git
   cd odin
   ```

2. **Login to Azure**:
   ```bash
   az login
   ```

3. **Deploy everything**:
   ```bash
   ./deploy.sh
   ```

4. **What happens**:
   - ✅ Creates Azure resource group
   - ✅ Deploys Azure OpenAI service
   - ✅ Sets up Azure AI Search
   - ✅ Creates Cosmos DB for chat history
   - ✅ Configures Azure App Service
   - ✅ Sets up monitoring and storage
   - ✅ Deploys the Flask application

5. **Result**: 
   - Your application will be available at `https://your-app-name.azurewebsites.net`
   - All Azure services configured and connected
   - Ready to use chat interface

## Option 2: Local Development Setup

**Time Required**: ~5 minutes

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lordaouy/odin.git
   cd odin
   ```

2. **Setup local environment**:
   ```bash
   ./setup-local.sh
   ```

3. **Configure Azure services** (requires existing Azure deployment):
   - Update `src/.env` with your Azure service values
   - See [DEPLOYMENT.md](DEPLOYMENT.md) for getting these values

4. **Run locally**:
   ```bash
   source venv/bin/activate
   cd src
   python app.py
   ```

5. **Access**: http://localhost:5000

## What You Get

### 🤖 AI Chat Interface
- Clean, modern web interface for chatting
- Persistent conversation history
- AI-powered responses using Azure OpenAI

### 🔍 Document Search (RAG)
- Upload documents to Azure Storage
- AI searches through documents to answer questions
- Contextual responses based on your content

### 💾 Persistent History
- All conversations saved to Cosmos DB
- Retrieve past conversations anytime
- Organized by claims or topics

### 📊 Monitoring & Insights
- Application performance monitoring
- Usage analytics and error tracking
- Real-time health monitoring

## Troubleshooting

### Common Issues

**"Azure OpenAI access denied"**
- Ensure your Azure subscription has OpenAI access
- Check if the deployment region supports OpenAI services

**"Application won't start"**
- Check App Service logs: `az webapp log tail --resource-group rg-<env> --name <app-name>`
- Verify all environment variables are set

**"Search returns no results"**
- Upload documents to the Storage Account > docs container
- Ensure search indexing is configured

**"Local development not working"**
- Update `src/.env` with valid Azure service values
- Ensure Azure services are accessible from your network

### Get Help

1. **Check the logs**:
   ```bash
   # Azure App Service logs
   az webapp log tail --resource-group rg-<env-name> --name <app-name>
   
   # Local development
   python app.py  # Error messages will show in terminal
   ```

2. **Verify connectivity**:
   ```bash
   # Test health endpoint
   curl https://your-app-url.azurewebsites.net/health
   ```

3. **Review configuration**:
   - Check environment variables in App Service
   - Verify Azure service permissions and connectivity

## Next Steps

After successful deployment:

1. **Upload Documents**: Add your documents to Azure Storage for search functionality
2. **Customize UI**: Modify Flask templates to match your branding  
3. **Add Authentication**: Configure Azure AD for secure access
4. **Scale**: Adjust App Service plan based on usage
5. **Monitor**: Set up alerts and monitoring dashboards

## Resources

- **[Complete Deployment Guide](DEPLOYMENT.md)** - Detailed instructions and troubleshooting
- **[Azure OpenAI Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)**
- **[Flask Documentation](https://flask.palletsprojects.com/)**
- **[LangGraph Documentation](https://langchain-ai.github.io/langgraph/)**

## Support

- Review the troubleshooting sections in [DEPLOYMENT.md](DEPLOYMENT.md)
- Check Azure portal for service-specific errors
- Examine application logs for detailed error information

---

**Ready to get started? Run `./deploy.sh` for Azure deployment or `./setup-local.sh` for local development!**