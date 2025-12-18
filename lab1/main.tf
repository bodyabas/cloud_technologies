terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {
  tenant_id = #
}

resource "azuread_user" "lab_user" {
  user_principal_name = "az104-user1@bohbanbasgmail.onmicrosoft.com"
  display_name           = "az104-user1"
  mail_nickname          = "az104user1"
  password               = "ChangeMe123!"
  force_password_change  = true
}

resource "azuread_group" "lab_group" {
  display_name     = "IT Lab Administrators"
  mail_nickname    = "it-lab-admins"
  security_enabled = true
}

resource "azuread_group_member" "member1" {
  group_object_id  = azuread_group.lab_group.object_id
  member_object_id = azuread_user.lab_user.object_id
}
