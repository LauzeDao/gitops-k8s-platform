output "resource_group_name" {
  description = "Main resource group containing the platform resources."
  value       = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL (issuer for all Federated Identity Credentials)."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "key_vault_name" {
  description = "Key Vault holding the SOPS age key (RBAC authorization)."
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "Key Vault URI."
  value       = azurerm_key_vault.this.vault_uri
}

output "dns_zone_name" {
  description = "Public DNS zone (= base_domain)."
  value       = azurerm_dns_zone.this.name
}

output "dns_zone_name_servers" {
  description = <<-EOT
    Authoritative name servers for the DNS zone. Delegate base_domain at your
    registrar to these NS records so external-dns/cert-manager work publicly.
  EOT
  value       = azurerm_dns_zone.this.name_servers
}

output "workload_identity_client_ids" {
  description = "Client IDs of the user-assigned identities, keyed by workload. Use as azure.workload.identity/client-id SA annotations."
  value = {
    cert_manager = azurerm_user_assigned_identity.cert_manager.client_id
    external_dns = azurerm_user_assigned_identity.external_dns.client_id
    sops         = azurerm_user_assigned_identity.sops.client_id
  }
}

output "oauth_app_client_ids" {
  description = "Client (application) IDs of the OAuth App Registrations."
  value = {
    grafana = azuread_application.grafana.client_id
    pgadmin = azuread_application.pgadmin.client_id
  }
}

output "tenant_id" {
  description = "Entra ID tenant ID (for OAuth issuer/authority URLs)."
  value       = var.tenant_id
}

output "state_backend" {
  description = "Storage account/container created for the remote tofu state."
  value = var.create_state_backend ? {
    resource_group_name  = azurerm_resource_group.state[0].name
    storage_account_name = azurerm_storage_account.state[0].name
    container_name       = azurerm_storage_container.state[0].name
  } : null
}
