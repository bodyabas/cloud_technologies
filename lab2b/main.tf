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


#############################
# Resource Group with Tags
#############################

resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "East US"

  tags = {
    "Cost Center" = "001"
    "Environment" = "Lab"
  }
}

#############################
# Policy: Require Tag
#############################

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag and its value on resources"
}

resource "azurerm_resource_group_policy_assignment" "require_tag_assignment" {
  name                  = "Require-Cost-Center-Tag"
  resource_group_id     = azurerm_resource_group.rg2.id
  policy_definition_id  = data.azurerm_policy_definition.require_tag.id

  parameters = jsonencode({
    tagName  = { value = "Cost Center" }
    tagValue = { value = "001" }
  })
}

#############################
# Policy: Inherit Tag
#############################

data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

resource "azurerm_resource_group_policy_assignment" "inherit_tag_assignment" {
  name                  = "Inherit-Cost-Center-Tag"
  resource_group_id     = azurerm_resource_group.rg2.id
  policy_definition_id  = data.azurerm_policy_definition.inherit_tag.id
  location              = azurerm_resource_group.rg2.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = { value = "Cost Center" }
  })
}

#############################
# Policy: Allowed Locations
#############################

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

resource "azurerm_resource_group_policy_assignment" "allowed_locations_assignment" {
  name                  = "Restrict-Allowed-Locations"
  resource_group_id     = azurerm_resource_group.rg2.id
  policy_definition_id  = data.azurerm_policy_definition.allowed_locations.id
  location              = azurerm_resource_group.rg2.location

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = ["East US", "West Europe"]
    }
  })
}

#############################
# Resource Group Lock
#############################

resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg2.id
  lock_level = "CanNotDelete"
  notes      = "Prevents deletion of this RG during lab"
}

#############################
# Outputs
#############################

output "resource_group_id" {
  value = azurerm_resource_group.rg2.id
}

output "require_tag_policy_id" {
  value       = azurerm_resource_group_policy_assignment.require_tag_assignment.id
  description = "ID of the Require Tag policy assignment"
}

output "inherit_tag_policy_id" {
  value       = azurerm_resource_group_policy_assignment.inherit_tag_assignment.id
  description = "ID of the Inherit Tag policy assignment"
}

output "allowed_locations_policy_id" {
  value       = azurerm_resource_group_policy_assignment.allowed_locations_assignment.id
  description = "ID of the Allowed Locations policy assignment"
}

output "lock_id" {
  value       = azurerm_management_lock.rg_lock.id
  description = "ID of the management lock for the RG"
}
