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

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${var.prefix}-vm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${var.prefix}-vm-subnet"
  resource_group_name  = azurerm_resource_group.testrg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${var.prefix}-vm-ip"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${var.prefix}-vm-nsg"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name

}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${var.prefix}-vm-nic"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  admin_username        = "azureuser"
  admin_password        = "Malta-2023#@!"
  location              = azurerm_resource_group.testrg.location
  resource_group_name   = azurerm_resource_group.testrg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]

  # well suited for application that benefits from low latency and high speed local storage
  # Standard_D4lds_v5 can be used in case more CPU, RAM and storage required, 140$/month
  size = "Standard_D2lds_v5" # 70$/month

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"

  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}


# Databse creation
resource "azurerm_mssql_server" "dbserver" {
  name                         = "${var.prefix}-sqlserver"
  resource_group_name          = azurerm_resource_group.testrg.name
  location                     = azurerm_resource_group.testrg.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"

}

#Creating DB instances
resource "azurerm_mssql_database" "db_staging_instance" {
  name           = "db_staging_instance"
  server_id      = azurerm_mssql_server.dbserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_database" "db_production_instance" {
  name           = "db_production_instance"
  server_id      = azurerm_mssql_server.dbserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 100
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true
}

# Create the App Service Plan
resource "azurerm_service_plan" "appserviceplan_staging" {
  name                = "${var.prefix}-service-plan-staging"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name
  os_type             = "Windows"
  sku_name            = "B1"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_windows_web_app" "webapp_staging" {
  name                = "${var.prefix}-web-app-staging"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name
  service_plan_id     = azurerm_service_plan.appserviceplan_staging.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
  }
}
# Create the App Service Plan
resource "azurerm_service_plan" "appserviceplan_prod" {
  name                = "${var.prefix}-service-plan-prod"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name
  os_type             = "Windows"
  sku_name            = "S2"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_windows_web_app" "webapp_prod" {
  name                = "${var.prefix}-web-app-prod"
  location            = azurerm_resource_group.testrg.location
  resource_group_name = azurerm_resource_group.testrg.name
  service_plan_id     = azurerm_service_plan.appserviceplan_prod.id
  https_only          = true
  site_config {
    minimum_tls_version = "1.2"
  }
}