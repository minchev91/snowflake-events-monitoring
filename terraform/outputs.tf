# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

# Function App
output "function_app_name" {
  description = "The name of the Azure Function App"
  value       = azurerm_linux_function_app.func.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the Function App"
  value       = azurerm_linux_function_app.func.default_hostname
}

# Key Vault
output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

# Storage Account
output "storage_account_name" {
  description = "The name of the storage account used by the Function App"
  value       = azurerm_storage_account.storage.name
}

# Application Insights
output "app_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}
