terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 4.13.1"
    }
  }
}

provider "okta" {
  org_name       = var.org_name
  base_url       = var.base_url
  client_id      = var.client_id
  private_key_id = var.private_key_id
  private_key    = var.private_key
  scopes         = ["okta.apps.manage", "okta.apps.read", "okta.groups.manage", "okta.groups.read", "okta.policies.manage", "okta.policies.read", "okta.profileMappings.manage", "okta.profileMappings.read"]
}