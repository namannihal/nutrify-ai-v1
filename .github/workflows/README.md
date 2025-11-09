# GitHub Actions CI/CD Setup Guide

Complete guide to setting up automated deployments to Azure Container Apps.

## Overview

We have 3 workflows:

1. **`deploy.yml`** - Full deployment (backend + frontend)
2. **`backend.yml`** - Backend-specific CI/CD with tests
3. **`frontend.yml`** - Frontend-specific CI/CD with tests

## Prerequisites

1. **Azure Account** with active subscription
2. **GitHub Repository** with admin access
3. **Terraform** deployed infrastructure (or manual Azure setup)

## Setup Steps

### 1. Create Azure Service Principal

Create a service principal for GitHub Actions to authenticate with Azure:

```bash
# Get your subscription ID
az account show --query id -o tsv

# Create service principal (replace SUBSCRIPTION_ID)
az ad sp create-for-rbac \
  --name "github-actions-nutrify" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/nutrify-dev-rg \
  --sdk-auth
```

This will output JSON like:
```json
{
  "clientId": "xxx",
  "clientSecret": "xxx",
  "subscriptionId": "xxx",
  "tenantId": "xxx",
  ...
}
```

**Save this entire JSON output** - you'll need it for GitHub Secrets.

### 2. Get ACR Credentials

Get your Azure Container Registry details:

```bash
# From your infrastructure directory
cd infastructure

# Get ACR name (without .azurecr.io)
terraform output -raw acr_login_server | cut -d. -f1

# Get full ACR login server
terraform output -raw acr_login_server
```

### 3. Configure GitHub Secrets

Go to your GitHub repository: **Settings → Secrets and variables → Actions**

#### Required Secrets:

Click **"New repository secret"** for each:

| Secret Name | Value | How to Get |
|------------|-------|-----------|
| `AZURE_CREDENTIALS` | JSON from step 1 | The entire JSON output from service principal creation |
| `ACR_NAME` | e.g., `nutrifymvpacr` | From `terraform output` or Azure Portal |
| `ACR_LOGIN_SERVER` | e.g., `nutrifymvpacr.azurecr.io` | From `terraform output acr_login_server` |

#### Required Variables:

Go to: **Settings → Secrets and variables → Actions → Variables tab**

Click **"New repository variable"** for each:

| Variable Name | Value | Example |
|--------------|-------|---------|
| `AZURE_RESOURCE_GROUP` | Your resource group name | `nutrify-dev-rg` |
| `BACKEND_CONTAINER_APP` | Backend app name | `nutrify-backend-dev` |
| `FRONTEND_CONTAINER_APP` | Frontend app name | `nutrify-frontend-dev` |

### 4. Grant Service Principal ACR Access

Give the service principal permission to push to ACR:

```bash
# Get service principal ID
SP_ID=$(az ad sp list --display-name "github-actions-nutrify" --query [0].id -o tsv)

# Get ACR resource ID
ACR_ID=$(az acr show --name nutrifymvpacr --query id -o tsv)

# Assign AcrPush role
az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope $ACR_ID
```

### 5. Test the Workflow

#### Option A: Push to trigger

```bash
git add .
git commit -m "Setup CI/CD"
git push origin main
```

#### Option B: Manual trigger

1. Go to **Actions** tab in GitHub
2. Select **Deploy to Azure Container Apps**
3. Click **Run workflow**
4. Select branch (main)
5. Click **Run workflow**

## Workflow Details

### Deploy Workflow (`deploy.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Manual trigger via GitHub UI

**What it does:**
1. Builds Docker images for backend & frontend
2. Pushes to ACR with git SHA and `latest` tags
3. Updates Container Apps with new images
4. Runs database migrations (if supported)
5. Outputs deployment URLs

### Backend Workflow (`backend.yml`)

**Triggers:**
- Push/PR to `backend/` directory
- Manual trigger

**What it does:**
1. Runs Python tests with pytest
2. Linting with Ruff
3. Type checking with mypy
4. Builds and pushes Docker image
5. Deploys to Container Apps (main branch only)

### Frontend Workflow (`frontend.yml`)

**Triggers:**
- Push/PR to `frontend/` directory
- Manual trigger

**What it does:**
1. Runs frontend tests
2. Linting with ESLint
3. Builds production bundle
4. Builds and pushes Docker image
5. Deploys to Container Apps (main branch only)

## Troubleshooting

### "Error: Login failed with Error: Fail to get Http response"

**Issue:** Azure credentials invalid or expired

**Fix:**
```bash
# Recreate service principal
az ad sp create-for-rbac \
  --name "github-actions-nutrify" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/nutrify-dev-rg \
  --sdk-auth

# Update AZURE_CREDENTIALS secret in GitHub
```

### "Error: Failed to push image"

**Issue:** Service principal lacks ACR push permissions

**Fix:**
```bash
# Add AcrPush role (see step 4 above)
az role assignment create \
  --assignee $SP_ID \
  --role AcrPush \
  --scope $ACR_ID
```

### "Error: Container app not found"

**Issue:** Wrong resource group or app name

**Fix:**
- Verify names match Terraform outputs:
  ```bash
  terraform output resource_group_name
  ```
- Update GitHub Variables with correct names

### Deployment succeeded but app not working

**Check logs:**
```bash
# Backend logs
az containerapp logs show \
  --name nutrify-backend-dev \
  --resource-group nutrify-dev-rg \
  --follow

# Frontend logs
az containerapp logs show \
  --name nutrify-frontend-dev \
  --resource-group nutrify-dev-rg \
  --follow
```

### Migrations not running

**Manual migration:**
```bash
# Option 1: Via Azure CLI (if exec is supported)
az containerapp exec \
  --name nutrify-backend-dev \
  --resource-group nutrify-dev-rg \
  --command "alembic upgrade head"

# Option 2: Via local terminal (connect to Supabase directly)
cd backend
alembic upgrade head
```

## Monitoring Deployments

### Via GitHub Actions UI

1. Go to **Actions** tab
2. Click on workflow run
3. View logs for each step

### Via Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Resource Group → Container App
3. Check **Revisions** for deployment history
4. View **Log stream** for real-time logs

### Via Azure CLI

```bash
# List revisions
az containerapp revision list \
  --name nutrify-backend-dev \
  --resource-group nutrify-dev-rg

# Get current ingress URL
az containerapp show \
  --name nutrify-backend-dev \
  --resource-group nutrify-dev-rg \
  --query properties.configuration.ingress.fqdn -o tsv
```

## Branch Strategy

### Recommended Setup:

- **`main`** → Production environment
- **`develop`** → Development environment
- **`feature/*`** → Feature branches (CI only, no deploy)

### Multi-Environment Setup:

Update `deploy.yml` to use different resource groups:

```yaml
env:
  AZURE_RESOURCE_GROUP: ${{ github.ref == 'refs/heads/main' && 'nutrify-prod-rg' || 'nutrify-dev-rg' }}
  BACKEND_CONTAINER_APP: ${{ github.ref == 'refs/heads/main' && 'nutrify-backend-prod' || 'nutrify-backend-dev' }}
  FRONTEND_CONTAINER_APP: ${{ github.ref == 'refs/heads/main' && 'nutrify-frontend-prod' || 'nutrify-frontend-dev' }}
```

## Cost Optimization

- Workflows run on GitHub-hosted runners (free for public repos)
- ACR Basic tier: ~$5/month
- Container Apps: Pay per vCPU-second (scale to zero in dev)
- Estimated CI/CD cost: **Free** (within GitHub Actions free tier)

## Security Best Practices

✅ **Implemented:**
- Service principal with minimal permissions
- Secrets stored in GitHub Secrets (encrypted)
- No hardcoded credentials in code

⚠️ **Recommended additions:**
- Enable branch protection rules
- Require PR reviews before merge
- Add CODEOWNERS file
- Use GitHub Environments for approval gates
- Rotate service principal credentials quarterly

## Next Steps

1. ✅ Set up secrets and variables
2. ✅ Test initial deployment
3. Add integration tests
4. Set up staging environment
5. Configure custom domains
6. Add monitoring/alerts (Application Insights)
7. Implement blue-green deployments

## Support

For issues:
- Check workflow logs in GitHub Actions
- Review Container App logs in Azure
- Consult [Azure Container Apps docs](https://learn.microsoft.com/en-us/azure/container-apps/)
- Review [GitHub Actions docs](https://docs.github.com/en/actions)
