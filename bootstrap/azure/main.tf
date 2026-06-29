data "azurerm_client_config" "current" {}

locals {
  rg_name      = "${var.name_prefix}-rg"
  aks_name     = "${var.name_prefix}-aks"
  vnet_name    = "${var.name_prefix}-vnet"
  subnet_name  = "${var.name_prefix}-aks-subnet"
  kv_name      = substr("${replace(var.name_prefix, "-", "")}kv${substr(md5(var.subscription_id), 0, 6)}", 0, 24)
  dns_dns_name = var.base_domain

  state_rg_name = coalesce(var.state_resource_group_name, "${var.name_prefix}-tfstate-rg")
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "state" {
  count    = var.create_state_backend ? 1 : 0
  name     = local.state_rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  count                           = var.create_state_backend ? 1 : 0
  name                            = var.state_storage_account_name
  resource_group_name             = azurerm_resource_group.state[0].name
  location                        = azurerm_resource_group.state[0].location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "state" {
  count                 = var.create_state_backend ? 1 : 0
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.state[0].id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "state_blob" {
  count                = var.create_state_backend ? 1 : 0
  scope                = azurerm_storage_account.state[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_address_prefix
}

resource "azurerm_kubernetes_cluster" "this" {
  name                      = local.aks_name
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_prefix                = var.name_prefix
  kubernetes_version        = var.cluster.kubernetes_version
  sku_tier                  = var.cluster.sku_tier
  private_cluster_enabled   = var.cluster.private_cluster
  automatic_upgrade_channel = "patch"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.cluster.node_vm_size
    os_disk_size_gb      = var.cluster.os_disk_size_gb
    vnet_subnet_id       = azurerm_subnet.aks.id
    auto_scaling_enabled = var.cluster.auto_scaling
    node_count           = var.cluster.auto_scaling ? null : var.cluster.node_count
    min_count            = var.cluster.auto_scaling ? var.cluster.min_count : null
    max_count            = var.cluster.auto_scaling ? var.cluster.max_count : null
    orchestrator_version = var.cluster.kubernetes_version
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    load_balancer_sku   = "standard"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
  }

  tags = var.tags
}

resource "azurerm_key_vault" "this" {
  name                       = local.kv_name
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = var.tenant_id
  sku_name                   = var.key_vault.sku
  enable_rbac_authorization  = true
  purge_protection_enabled   = var.key_vault.purge_protection_enabled
  soft_delete_retention_days = var.key_vault.soft_delete_retention_days
  tags                       = var.tags
}

resource "azurerm_role_assignment" "deployer_kv_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "age_key" {
  count        = var.age_private_key == null ? 0 : 1
  name         = "sops-age"
  value        = var.age_private_key
  key_vault_id = azurerm_key_vault.this.id
  content_type = "text/plain; sops-age-private-key"
  tags         = var.tags

  depends_on = [azurerm_role_assignment.deployer_kv_officer]
}

resource "azurerm_dns_zone" "this" {
  name                = local.dns_dns_name
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "kubernetes_namespace_v1" "flux_system" {
  metadata {
    name = "flux-system"
    labels = {
      "app.kubernetes.io/part-of" = "gitops-k8s-platform"
    }
  }

  depends_on = [azurerm_role_assignment.deployer_aks_admin]
}

resource "helm_release" "flux2" {
  name       = "flux2"
  namespace  = kubernetes_namespace_v1.flux_system.metadata[0].name
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  version    = var.flux.flux2_chart_version

  values = [yamlencode({
    policies = {
      create = true
    }
  })]

  depends_on = [
    azurerm_kubernetes_cluster.this,
    kubernetes_namespace_v1.flux_system,
  ]
}

resource "helm_release" "flux2_sync" {
  name       = "flux-system"
  namespace  = kubernetes_namespace_v1.flux_system.metadata[0].name
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = var.flux.flux2_sync_chart_version

  set = concat(
    [
      {
        name  = "gitRepository.spec.url"
        value = var.flux.git_url
      },
      {
        name  = "gitRepository.spec.ref.branch"
        value = var.flux.git_branch
      },
      {
        name  = "gitRepository.spec.interval"
        value = var.flux.git_interval
      },
      {
        name  = "kustomization.spec.path"
        value = var.flux.git_path
      },
    ],
    var.flux.git_secret_ref == null ? [] : [
      {
        name  = "gitRepository.spec.secretRef.name"
        value = var.flux.git_secret_ref
      },
    ],
  )

  depends_on = [helm_release.flux2]
}
