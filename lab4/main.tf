terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.8.0"
}

provider "azurerm" {
  features {}
  subscription_id = #
  tenant_id       = #
}

resource "azurerm_resource_group" "rg4" {
  name     = "az104-rg4"
  location = "East US"
}

resource "azurerm_virtual_network" "core_vnet" {
  name                = "CoreServicesVnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_subnet" "shared_services" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.20.0/24"]
}

resource "azurerm_virtual_network" "manufacturing_vnet" {
  name                = "ManufacturingVnet"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_subnet" "sensor1" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.manufacturing_vnet.name
  address_prefixes     = ["10.30.20.0/24"]
}

resource "azurerm_subnet" "sensor2" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.manufacturing_vnet.name
  address_prefixes     = ["10.30.21.0/24"]
}

resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  resource_group_name = azurerm_resource_group.rg4.name
  location            = azurerm_resource_group.rg4.location
}


resource "azurerm_network_security_group" "nsg_secure" {
  name                = "myNSGSecure"
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_network_security_rule" "allow_asg" {
  name                        = "AllowASG"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = ["80", "443"]
  source_application_security_group_ids = [azurerm_application_security_group.asg_web.id]
  destination_address_prefix   = "*"
  network_security_group_name  = azurerm_network_security_group.nsg_secure.name
  resource_group_name          = azurerm_network_security_group.nsg_secure.resource_group_name
}


resource "azurerm_network_security_rule" "deny_internet" {
  name                       = "DenyInternetOutbound"
  priority                   = 4096
  direction                  = "Outbound"
  access                     = "Deny"
  protocol                   = "*"
  source_address_prefix       = "*"      # <- додано
  source_port_range           = "*"
  destination_address_prefix  = "Internet"
  destination_port_range      = "*"
  network_security_group_name = azurerm_network_security_group.nsg_secure.name
  resource_group_name         = azurerm_network_security_group.nsg_secure.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "assoc_shared" {
  subnet_id                 = azurerm_subnet.shared_services.id
  network_security_group_id = azurerm_network_security_group.nsg_secure.id
}

resource "azurerm_dns_zone" "public_zone" {
  name                = "labcloudtechbasiuryn.com"
  resource_group_name = "az104-rg4"
}

resource "azurerm_dns_a_record" "www_record" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_zone.name
  resource_group_name = "az104-rg4"
  ttl                 = 3600
  records             = ["10.1.1.4"]
}

resource "azurerm_private_dns_zone" "private_zone" {
  name                = "private.labcloudtechbasiuryn"
  resource_group_name = "az104-rg4"
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "manufacturing-link"
  resource_group_name   = "az104-rg4"
  private_dns_zone_name = azurerm_private_dns_zone.private_zone.name
  virtual_network_id    = azurerm_virtual_network.manufacturing_vnet.id
  registration_enabled  = true
}

resource "azurerm_private_dns_a_record" "sensorvm_record" {
  name                = "sensorvm"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = "az104-rg4"
  ttl                 = 3600
  records             = ["10.1.1.4"]
}

output "core_vnet_id" {
  value = azurerm_virtual_network.core_vnet.id
}

output "manufacturing_vnet_id" {
  value = azurerm_virtual_network.manufacturing_vnet.id
}

output "asg_id" {
  value = azurerm_application_security_group.asg_web.id
}

output "nsg_id" {
  value = azurerm_network_security_group.nsg_secure.id
}
