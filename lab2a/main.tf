terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

data "azuread_user" "lab_user" {
  user_principal_name = "az104-user1@bohbanbasgmail.onmicrosoft.com"
}

resource "azuread_group" "helpdesk_group" {
  display_name     = "Help Desk"
  mail_nickname    = "helpdesk"
  security_enabled = true
}

resource "azuread_group_member" "member1" {
  group_object_id  = azuread_group.helpdesk_group.id
  member_object_id = data.azuread_user.lab_user.id
}

# Management Group
resource "azurerm_management_group" "lab_mg" {
  name         = "az104-mg1"
  display_name = "az104-mg1"
}

resource "azurerm_role_definition" "custom_support_role" {
  name              = "Custom Support Role"
  scope             = azurerm_management_group.lab_mg.id
  description       = "Custom Support Role for AZ-104 Lab"
  assignable_scopes = [azurerm_management_group.lab_mg.id]

  permissions {
    actions      = ["*"]
    not_actions  = []
    data_actions = []
    not_data_actions = []
  }
}

resource "azurerm_role_assignment" "assign_custom_role" {
  principal_id       = azuread_group.helpdesk_group.id
  role_definition_id = azurerm_role_definition.custom_support_role.role_definition_resource_id
  scope              = azurerm_management_group.lab_mg.id
}

resource "azurerm_role_assignment" "assign_vm_contributor" {
  principal_id         = azuread_group.helpdesk_group.id
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_management_group.lab_mg.id
}

output "helpdesk_group_id" {
  value = azuread_group.helpdesk_group.id
}

output "lab_user_id" {
  value = data.azuread_user.lab_user.id
}

output "management_group_id" {
  value = azurerm_management_group.lab_mg.id
}

output "helpdesk_custom_role_assignment_id" {
  value = azurerm_role_assignment.assign_custom_role.id
}

output "helpdesk_vm_contributor_assignment_id" {
  value = azurerm_role_assignment.assign_vm_contributor.id
}
