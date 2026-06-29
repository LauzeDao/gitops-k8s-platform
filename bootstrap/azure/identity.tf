locals {
  oidc_issuer = azurerm_kubernetes_cluster.this.oidc_issuer_url
  wi_audience = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "deployer_aks_admin" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_user_assigned_identity" "cert_manager" {
  name                = "${var.name_prefix}-cert-manager"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "cert_manager" {
  name                = "cert-manager"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.cert_manager.id
  audience            = local.wi_audience
  issuer              = local.oidc_issuer
  subject             = "system:serviceaccount:${var.workload_identities.cert_manager.namespace}:${var.workload_identities.cert_manager.service_account}"
}

resource "azurerm_role_assignment" "cert_manager_dns" {
  scope                = azurerm_dns_zone.this.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
}

resource "azurerm_user_assigned_identity" "external_dns" {
  name                = "${var.name_prefix}-external-dns"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "external_dns" {
  name                = "external-dns"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.external_dns.id
  audience            = local.wi_audience
  issuer              = local.oidc_issuer
  subject             = "system:serviceaccount:${var.workload_identities.external_dns.namespace}:${var.workload_identities.external_dns.service_account}"
}

resource "azurerm_role_assignment" "external_dns_zone" {
  scope                = azurerm_dns_zone.this.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

resource "azurerm_role_assignment" "external_dns_reader" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.external_dns.principal_id
}

resource "azurerm_user_assigned_identity" "sops" {
  name                = "${var.name_prefix}-sops-age"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "sops" {
  name                = "sops-age"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.sops.id
  audience            = local.wi_audience
  issuer              = local.oidc_issuer
  subject             = "system:serviceaccount:${var.workload_identities.sops.namespace}:${var.workload_identities.sops.service_account}"
}

resource "azurerm_role_assignment" "sops_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.sops.principal_id
}

data "azuread_client_config" "current" {}

resource "azuread_application" "grafana" {
  display_name     = "${var.name_prefix}-grafana"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  group_membership_claims = ["SecurityGroup"]

  optional_claims {
    id_token {
      name      = "email"
      essential = false
    }
    id_token {
      name      = "preferred_username"
      essential = false
    }
  }

  web {
    redirect_uris = [
      "https://${var.app_subdomains.grafana}.${var.base_domain}/login/generic_oauth",
    ]
    implicit_grant {
      id_token_issuance_enabled = false
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e"
      type = "Scope"
    }
    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1"
      type = "Scope"
    }
    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "grafana" {
  client_id = azuread_application.grafana.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application" "pgadmin" {
  display_name     = "${var.name_prefix}-pgadmin"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  group_membership_claims = ["SecurityGroup"]

  optional_claims {
    id_token {
      name      = "email"
      essential = false
    }
    id_token {
      name      = "preferred_username"
      essential = false
    }
  }

  web {
    redirect_uris = [
      "https://${var.app_subdomains.pgadmin}.${var.base_domain}/oauth2/authorize",
    ]
    implicit_grant {
      id_token_issuance_enabled = false
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e"
      type = "Scope"
    }
    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1"
      type = "Scope"
    }
    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "pgadmin" {
  client_id = azuread_application.pgadmin.client_id
  owners    = [data.azuread_client_config.current.object_id]
}
