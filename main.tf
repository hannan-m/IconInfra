# storage account

resource "azurerm_resource_group" "testrg" {
  name     = "${var.prefix}-rg"
  location = "westus"
}

resource "azurerm_storage_account" "testsa" {
  name                     = "storageaccountname"
  resource_group_name      = azurerm_resource_group.testrg.name
  location                 = "westus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

resource "azurerm_storage_container" "staging" {
  name                  = "staging"
  storage_account_name  = azurerm_storage_account.testsa.name
  container_access_type = "private"
}
resource "azurerm_storage_container" "production" {
  name                  = "production"
  storage_account_name  = azurerm_storage_account.testsa.name
  container_access_type = "private"
}