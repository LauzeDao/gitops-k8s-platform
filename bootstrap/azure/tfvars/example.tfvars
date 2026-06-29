# =============================================================================
# example.tfvars — TEMPLATE. Copy to a gitignored file (e.g. azure.tfvars) and
# fill in real values, OR pass values via TF_VAR_* env vars in CI.
#   cp tfvars/example.tfvars tfvars/azure.tfvars   # azure.tfvars is gitignored
# NEVER commit real subscription/tenant IDs, domains or the age key.
# =============================================================================

# --- Azure context -----------------------------------------------------------
subscription_id = "00000000-0000-0000-0000-000000000000"
tenant_id       = "00000000-0000-0000-0000-000000000000"

# --- Naming / region ---------------------------------------------------------
location    = "westeurope"
name_prefix = "gitops" # 2-13 chars, [a-z0-9-], used to derive all resource names

tags = {
  "app.kubernetes.io/part-of" = "gitops-k8s-platform"
  managed-by                  = "opentofu"
  mode                        = "azure"
  owner                       = "your-name-or-team"
}

# --- Networking (defaults are fine for most cases) ---------------------------
# vnet_address_space        = ["10.40.0.0/16"]
# aks_subnet_address_prefix = ["10.40.0.0/22"]

# --- AKS ---------------------------------------------------------------------
cluster = {
  # kubernetes_version = "1.30"   # null => region default
  sku_tier        = "Free"
  private_cluster = false
  node_vm_size    = "Standard_D2s_v5"
  auto_scaling    = true
  min_count       = 2
  max_count       = 4
}

# Entra group(s) that get cluster-admin (optional; deployer is admin anyway).
# admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]

# --- DNS / domain ------------------------------------------------------------
base_domain = "gitops.example.com" # public zone created in Azure DNS

# app_subdomains = {
#   grafana = "grafana"
#   pgadmin = "pgadmin"
# }

# --- Key Vault ---------------------------------------------------------------
# key_vault = {
#   sku                        = "standard"
#   purge_protection_enabled   = true
#   soft_delete_retention_days = 7
# }

# --- SOPS age private key ----------------------------------------------------
# Prefer setting this via env: export TF_VAR_age_private_key="AGE-SECRET-KEY-..."
# Leave commented to seed the Key Vault secret out-of-band instead.
# age_private_key = "AGE-SECRET-KEY-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# --- Workload Identity SA mapping (override only if your manifests differ) ---
# workload_identities = {
#   cert_manager = { namespace = "cert-manager",  service_account = "cert-manager" }
#   external_dns = { namespace = "external-dns",  service_account = "external-dns" }
#   sops         = { namespace = "flux-system",   service_account = "sops-age" }
# }

# --- Flux --------------------------------------------------------------------
flux = {
  # Versions pinned per CLAUDE.md (Flux 2.8.8). Bump via Renovate.
  flux2_chart_version      = "2.18.4"
  flux2_sync_chart_version = "1.14.6"

  git_url      = "https://github.com/<your-org>/gitops-k8s-platform.git"
  git_branch   = "main"
  git_path     = "./clusters/azure"
  git_interval = "1m"
  # git_secret_ref = null   # null for a PUBLIC repo (anonymous HTTPS poll)
}

# --- Remote state backend (created by this module) ---------------------------
create_state_backend = true
# state_resource_group_name  = "gitops-tfstate-rg"   # null => <name_prefix>-tfstate-rg
state_storage_account_name = "gitopstfstate1234" # 3-24 chars, [a-z0-9], GLOBALLY UNIQUE
state_container_name       = "tfstate"
