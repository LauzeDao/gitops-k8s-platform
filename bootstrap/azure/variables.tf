variable "subscription_id" {
  description = "Target Azure subscription ID where all resources are created."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID (Azure AD) tenant ID used by azurerm/azuread providers."
  type        = string
}

variable "aks_aad_server_app_id" {
  description = <<-EOT
    Well-known AKS AAD server application ID used by kubelogin to request a
    cluster token. This is a Microsoft-published constant (the same for every
    public-cloud AKS), not a tenant secret. Override only for sovereign clouds.
  EOT
  type        = string
  default     = "6dae42f8-4368-4678-94ff-3960e28e3630"
}

variable "location" {
  description = "Azure region for all regional resources (e.g. westeurope)."
  type        = string
}

variable "name_prefix" {
  description = <<-EOT
    Short prefix used to derive resource names (RG, AKS, VNet, ...). Lowercase
    letters/digits/hyphens, e.g. "gitops". Keep it short — some resources (Key
    Vault, Storage Account) have tight length/charset limits.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,12}$", var.name_prefix))
    error_message = "name_prefix must be 2-13 chars, lowercase letters/digits/hyphens, starting with a letter."
  }
}

variable "tags" {
  description = "Tags applied to all resources that support tagging."
  type        = map(string)
  default = {
    "app.kubernetes.io/part-of" = "gitops-k8s-platform"
    managed-by                  = "opentofu"
    mode                        = "azure"
  }
}

variable "vnet_address_space" {
  description = "Address space for the AKS VNet."
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS node subnet."
  type        = list(string)
  default     = ["10.40.0.0/22"]
}

variable "cluster" {
  description = "AKS cluster sizing and behaviour."
  type = object({
    kubernetes_version = optional(string, null)
    sku_tier           = optional(string, "Free")
    private_cluster    = optional(bool, false)
    node_count         = optional(number, 2)
    node_vm_size       = optional(string, "Standard_D2s_v5")
    os_disk_size_gb    = optional(number, 64)
    auto_scaling       = optional(bool, true)
    min_count          = optional(number, 2)
    max_count          = optional(number, 4)
  })
  default = {}
}

variable "admin_group_object_ids" {
  description = <<-EOT
    Entra ID group object IDs granted cluster-admin via Azure AD RBAC. The
    deploying principal is also granted RBAC Cluster Admin automatically so the
    bootstrap (Flux install) works. Leave empty to rely solely on the deployer.
  EOT
  type        = list(string)
  default     = []
}

variable "base_domain" {
  description = <<-EOT
    Public base domain hosted in the created Azure DNS zone, e.g.
    "gitops.example.com". App hostnames are derived as <subdomain>.<base_domain>
    (grafana.<base_domain>, pgadmin.<base_domain>, ...). external-dns manages the
    records; cert-manager solves ACME DNS-01 in this zone. After apply, delegate
    this zone at your registrar using the NS records from the outputs.
  EOT
  type        = string
}

variable "app_subdomains" {
  description = "Subdomain labels for the OAuth-protected apps (used for redirect URIs)."
  type = object({
    grafana = optional(string, "grafana")
    pgadmin = optional(string, "pgadmin")
  })
  default = {}
}

variable "key_vault" {
  description = "Key Vault settings. RBAC authorization is always enabled (no access policies)."
  type = object({
    sku                        = optional(string, "standard")
    purge_protection_enabled   = optional(bool, true)
    soft_delete_retention_days = optional(number, 7)
  })
  default = {}
}

variable "age_private_key" {
  description = <<-EOT
    The SOPS age PRIVATE key (AGE-SECRET-KEY-...). When set, it is stored as the
    `sops-age` secret in Key Vault so Flux can fetch it via Workload Identity.
    Provide it ONLY through a gitignored tfvars file or TF_VAR_age_private_key in
    CI — never commit it. Leave null to seed the secret out-of-band.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "workload_identities" {
  description = <<-EOT
    Maps each Azure-authenticating workload to the Kubernetes ServiceAccount it
    federates with. The federated credential subject becomes
    system:serviceaccount:<namespace>:<service_account>.
  EOT
  type = object({
    cert_manager = optional(object({
      namespace       = optional(string, "cert-manager")
      service_account = optional(string, "cert-manager")
    }), {})
    external_dns = optional(object({
      namespace       = optional(string, "external-dns")
      service_account = optional(string, "external-dns")
    }), {})
    sops = optional(object({
      namespace       = optional(string, "flux-system")
      service_account = optional(string, "sops-age")
    }), {})
  })
  default = {}
}

variable "flux" {
  description = "Flux Helm chart configuration and the Git source it reconciles."
  type = object({
    flux2_chart_version      = optional(string, "2.18.4")
    flux2_sync_chart_version = optional(string, "1.14.6")
    git_url                  = string
    git_branch               = optional(string, "main")
    git_path                 = optional(string, "./clusters/azure")
    git_interval             = optional(string, "1m")
    git_secret_ref = optional(string, null)
  })
}

variable "create_state_backend" {
  description = "Create the Storage Account/Container that holds the remote tofu state."
  type        = bool
  default     = true
}

variable "state_resource_group_name" {
  description = "Resource group for the tofu state Storage Account."
  type        = string
  default     = null
}

variable "state_storage_account_name" {
  description = <<-EOT
    Globally unique Storage Account name for tofu state (3-24 chars, lowercase
    letters/digits only). Must be supplied because it has to be globally unique.
  EOT
  type        = string
  default     = null
}

variable "state_container_name" {
  description = "Blob container name holding the tofu state."
  type        = string
  default     = "tfstate"
}
