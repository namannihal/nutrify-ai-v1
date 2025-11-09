# ==========================================
# Nutrify AI - Azure Infrastructure
# ACR + Azure Container Apps + Supabase
# ==========================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

# ==========================================
# Variables
# ==========================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "nutrify"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "supabase_database_url" {
  description = "Supabase PostgreSQL connection string"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Backend JWT secret key"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth client ID (optional)"
  type        = string
  default     = "not-configured"
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth client secret (optional)"
  type        = string
  default     = "not-configured"
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key (optional - not used until AI agents are implemented)"
  type        = string
  default     = "not-configured-yet"
  sensitive   = true
}

variable "langchain_api_key" {
  description = "LangChain API key for tracing (optional - not used until AI agents are implemented)"
  type        = string
  default     = "not-configured-yet"
  sensitive   = true
}

# ==========================================
# Resource Group
# ==========================================

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ==========================================
# Azure Container Registry (ACR)
# ==========================================

resource "azurerm_container_registry" "acr" {
  name                = "${var.project_name}${var.environment}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================
# Log Analytics Workspace
# ==========================================

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================
# Container Apps Environment
# ==========================================

resource "azurerm_container_app_environment" "env" {
  name                       = "${var.project_name}-${var.environment}-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================
# Backend Container App
# ==========================================

resource "azurerm_container_app" "backend" {
  name                         = "${var.project_name}-backend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  secret {
    name  = "database-url"
    value = var.supabase_database_url
  }

  secret {
    name  = "secret-key"
    value = var.secret_key
  }

  secret {
    name  = "google-client-id"
    value = var.google_client_id
  }

  secret {
    name  = "google-client-secret"
    value = var.google_client_secret
  }

  secret {
    name  = "openai-api-key"
    value = var.openai_api_key
  }

  secret {
    name  = "langchain-api-key"
    value = var.langchain_api_key
  }

  template {
    container {
      name   = "backend"
      image  = "${azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "APP_NAME"
        value = "Nutrify-AI"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "DEBUG"
        value = var.environment == "dev" ? "True" : "False"
      }

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name        = "SECRET_KEY"
        secret_name = "secret-key"
      }

      env {
        name  = "ALGORITHM"
        value = "HS256"
      }

      env {
        name  = "ACCESS_TOKEN_EXPIRE_MINUTES"
        value = "30"
      }

      env {
        name  = "REFRESH_TOKEN_EXPIRE_DAYS"
        value = "7"
      }

      env {
        name        = "GOOGLE_CLIENT_ID"
        secret_name = "google-client-id"
      }

      env {
        name        = "GOOGLE_CLIENT_SECRET"
        secret_name = "google-client-secret"
      }

      env {
        name  = "GOOGLE_REDIRECT_URI"
        value = "https://${var.project_name}-backend-${var.environment}.${azurerm_container_app_environment.env.default_domain}/api/v1/auth/google/callback"
      }

      env {
        name        = "OPENAI_API_KEY"
        secret_name = "openai-api-key"
      }

      env {
        name        = "LANGCHAIN_API_KEY"
        secret_name = "langchain-api-key"
      }

      env {
        name  = "LANGCHAIN_TRACING_V2"
        value = "true"
      }

      env {
        name  = "LANGSMITH_ENDPOINT"
        value = "https://api.smith.langchain.com"
      }

      env {
        name  = "LANGCHAIN_PROJECT"
        value = "nutrify-${var.environment}"
      }

      env {
        name  = "AI_MODEL"
        value = "gpt-4-turbo-preview"
      }

      env {
        name  = "AI_TEMPERATURE"
        value = "0.7"
      }

      env {
        name  = "AI_MAX_TOKENS"
        value = "2000"
      }

      env {
        name  = "CORS_ORIGINS"
        value = "https://${var.project_name}-frontend-${var.environment}.${azurerm_container_app_environment.env.default_domain},http://localhost:3000"
      }

      env {
        name  = "CORS_CREDENTIALS"
        value = "True"
      }
    }

    min_replicas = var.environment == "prod" ? 1 : 0
    max_replicas = var.environment == "prod" ? 10 : 3
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "backend"
  }
}

# ==========================================
# Frontend Container App
# ==========================================

resource "azurerm_container_app" "frontend" {
  name                         = "${var.project_name}-frontend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.acr.login_server}/frontend:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "VITE_API_URL"
        value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
      }
    }

    min_replicas = var.environment == "prod" ? 1 : 0
    max_replicas = var.environment == "prod" ? 5 : 2
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "frontend"
  }

  depends_on = [azurerm_container_app.backend]
}

# ==========================================
# Outputs
# ==========================================

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "ACR admin username"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "ACR admin password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "backend_url" {
  description = "Backend API URL"
  value       = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "backend_fqdn" {
  description = "Backend FQDN"
  value       = azurerm_container_app.backend.ingress[0].fqdn
}

output "frontend_fqdn" {
  description = "Frontend FQDN"
  value       = azurerm_container_app.frontend.ingress[0].fqdn
}

output "container_app_environment_id" {
  description = "Container Apps Environment ID"
  value       = azurerm_container_app_environment.env.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.logs.id
}
