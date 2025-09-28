provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "snowflake-monitoring-rg"
  location = "westeurope"
}

# Storage for Function App
resource "azurerm_storage_account" "storage" {
  name                     = "sfmntrstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# App Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "snowflake-events-monitoring-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# Function App Plan
resource "azurerm_service_plan" "plan" {
  name                = "snowflake-events-monitoring-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

# Function App
resource "azurerm_linux_function_app" "func" {
  name                       = "snowflake-monitoring-func"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.appinsights.instrumentation_key

    # Snowflake references from Key Vault
    SNOWFLAKE_ACCOUNT   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_account.id})"
    SNOWFLAKE_USER      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_user.id})"
    SNOWFLAKE_PASSWORD  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_password.id})"
    SNOWFLAKE_WAREHOUSE = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_warehouse.id})"
    SNOWFLAKE_DATABASE  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_database.id})"
    SNOWFLAKE_SCHEMA    = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_schema.id})"
    SNOWFLAKE_ROLE      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.snowflake_role.id})"
  }
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = "sf-mntr-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

# Secrets in Key Vault
resource "azurerm_key_vault_secret" "snowflake_account" {
  name         = "SnowflakeAccount"
  value        = var.snowflake_account
  key_vault_id = azurerm_key_vault.kv.id
}
resource "azurerm_key_vault_secret" "snowflake_user" {
  name         = "SnowflakeUser"
  value        = var.snowflake_user
  key_vault_id = azurerm_key_vault.kv.id
}
resource "azurerm_key_vault_secret" "snowflake_password" {
  name         = "SnowflakePassword"
  value        = var.snowflake_password
  key_vault_id = azurerm_key_vault.kv.id
}
resource "azurerm_key_vault_secret" "snowflake_warehouse" {
  name         = "SnowflakeWarehouse"
  value        = var.snowflake_warehouse
  key_vault_id = azurerm_key_vault.kv.id
}
resource "azurerm_key_vault_secret" "snowflake_database" {
  name         = "SnowflakeDatabase"
  value        = var.snowflake_database
  key_vault_id = azurerm_key_vault.kv.id
}
resource "azurerm_key_vault_secret" "snowflake_schema" {
  name         = "SnowflakeSchema"
  value        = var.snowflake_schema
  key_vault_id = azurerm_key_vault.kv.id
}
resource "azurerm_key_vault_secret" "snowflake_role" {
  name         = "SnowflakeRole"
  value        = coalesce(var.snowflake_role, "")
  key_vault_id = azurerm_key_vault.kv.id
}
