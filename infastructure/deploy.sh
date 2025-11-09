#!/bin/bash

# ==========================================
# Nutrify - Quick Deployment Script
# ==========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Nutrify Deployment Script"
echo "============================"
echo ""

# Check if terraform.tfvars exists
if [ ! -f "$SCRIPT_DIR/terraform.tfvars" ]; then
    echo "❌ Error: terraform.tfvars not found"
    echo "📝 Please copy variables.tfvars.example to terraform.tfvars and fill in your values:"
    echo "   cd infastructure && cp variables.tfvars.example terraform.tfvars"
    exit 1
fi

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Error: Azure CLI not installed"
    echo "📦 Install: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform not installed"
    echo "📦 Install: brew install terraform"
    exit 1
fi

# Check Azure login
if ! az account show &> /dev/null; then
    echo "🔐 Please login to Azure..."
    az login
fi

echo "✅ Prerequisites check passed"
echo ""

# Ask for deployment action
echo "What would you like to do?"
echo "1) Deploy/Update infrastructure"
echo "2) Build and push Docker images"
echo "3) Deploy infrastructure + Build images (full deployment)"
echo "4) View deployment URLs"
echo "5) Destroy infrastructure"
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo ""
        echo "📦 Deploying infrastructure..."
        cd "$SCRIPT_DIR"
        terraform init
        terraform plan -var-file="terraform.tfvars"
        read -p "Proceed with deployment? (yes/no): " confirm
        if [ "$confirm" == "yes" ]; then
            terraform apply -var-file="terraform.tfvars"
            echo ""
            echo "✅ Infrastructure deployed!"
            terraform output
        fi
        ;;
    
    2)
        echo ""
        echo "🐳 Building and pushing Docker images..."
        cd "$SCRIPT_DIR"
        
        # Get ACR credentials
        ACR_SERVER=$(terraform output -raw acr_login_server 2>/dev/null)
        ACR_USERNAME=$(terraform output -raw acr_admin_username 2>/dev/null)
        ACR_PASSWORD=$(terraform output -raw acr_admin_password 2>/dev/null)
        
        if [ -z "$ACR_SERVER" ]; then
            echo "❌ Error: Infrastructure not deployed. Run option 1 first."
            exit 1
        fi
        
        echo "🔐 Logging into ACR..."
        echo "$ACR_PASSWORD" | docker login "$ACR_SERVER" -u "$ACR_USERNAME" --password-stdin
        
        echo "🏗️  Building backend..."
        cd "$PROJECT_ROOT/backend"
        docker build -t "$ACR_SERVER/backend:latest" .
        
        echo "📤 Pushing backend..."
        docker push "$ACR_SERVER/backend:latest"
        
        echo "🏗️  Building frontend..."
        cd "$PROJECT_ROOT/frontend"
        docker build -t "$ACR_SERVER/frontend:latest" .
        
        echo "📤 Pushing frontend..."
        docker push "$ACR_SERVER/frontend:latest"
        
        echo ""
        echo "🔄 Restarting container apps..."
        cd "$SCRIPT_DIR"
        RG_NAME=$(terraform output -raw resource_group_name)
        
        az containerapp revision restart \
            --name nutrify-backend-dev \
            --resource-group "$RG_NAME" || echo "⚠️  Backend restart failed (may need manual restart)"
        
        az containerapp revision restart \
            --name nutrify-frontend-dev \
            --resource-group "$RG_NAME" || echo "⚠️  Frontend restart failed (may need manual restart)"
        
        echo ""
        echo "✅ Images built and deployed!"
        ;;
    
    3)
        echo ""
        echo "🚀 Full deployment starting..."
        
        # Deploy infrastructure
        cd "$SCRIPT_DIR"
        terraform init
        terraform plan -var-file="terraform.tfvars"
        read -p "Proceed with deployment? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "❌ Deployment cancelled"
            exit 1
        fi
        
        terraform apply -var-file="terraform.tfvars" -auto-approve
        
        echo ""
        echo "⏳ Waiting 30 seconds for infrastructure to stabilize..."
        sleep 30
        
        # Build and push images
        ACR_SERVER=$(terraform output -raw acr_login_server)
        ACR_USERNAME=$(terraform output -raw acr_admin_username)
        ACR_PASSWORD=$(terraform output -raw acr_admin_password)
        
        echo "🔐 Logging into ACR..."
        echo "$ACR_PASSWORD" | docker login "$ACR_SERVER" -u "$ACR_USERNAME" --password-stdin
        
        echo "🏗️  Building and pushing backend..."
        cd "$PROJECT_ROOT/backend"
        docker build -t "$ACR_SERVER/backend:latest" .
        docker push "$ACR_SERVER/backend:latest"
        
        echo "🏗️  Building and pushing frontend..."
        cd "$PROJECT_ROOT/frontend"
        docker build -t "$ACR_SERVER/frontend:latest" .
        docker push "$ACR_SERVER/frontend:latest"
        
        echo ""
        echo "🔄 Restarting container apps..."
        cd "$SCRIPT_DIR"
        RG_NAME=$(terraform output -raw resource_group_name)
        
        sleep 10
        
        az containerapp revision restart \
            --name nutrify-backend-dev \
            --resource-group "$RG_NAME" || echo "⚠️  Backend restart may be needed"
        
        az containerapp revision restart \
            --name nutrify-frontend-dev \
            --resource-group "$RG_NAME" || echo "⚠️  Frontend restart may be needed"
        
        echo ""
        echo "✅ Full deployment complete!"
        echo ""
        echo "📋 Deployment URLs:"
        terraform output
        ;;
    
    4)
        echo ""
        cd "$SCRIPT_DIR"
        echo "📋 Deployment Information:"
        echo "=========================="
        terraform output
        ;;
    
    5)
        echo ""
        echo "⚠️  WARNING: This will destroy ALL resources!"
        read -p "Are you sure? Type 'destroy' to confirm: " confirm
        if [ "$confirm" == "destroy" ]; then
            cd "$SCRIPT_DIR"
            terraform destroy -var-file="terraform.tfvars"
            echo "✅ Infrastructure destroyed"
        else
            echo "❌ Destruction cancelled"
        fi
        ;;
    
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✨ Done!"
