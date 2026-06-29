# Phase 9 — Azure-Overlay (alles per IaC, keine Handarbeit)

## Ziel

`task up:azure` (bzw. GitHub-Actions-Pipeline) erzeugt in Azure **sämtliche** Ressourcen per
OpenTofu: Cluster, Netz, Key Vault, DNS, **App-Registrations/Identitäten** — und installiert
Flux, das denselben `infrastructure/`+`apps/`-Kern über den `azure`-Overlay ausrollt.
**Kein manueller Portal-/Konsolen-Schritt, keine manuell erstellte Enterprise Application.**

## Voraussetzungen

- Phase 2–8 (lauffähiger Kern lokal, Overlays existieren).

## Dateien

```
bootstrap/azure/providers.tf        # azurerm, azuread, helm, kubernetes, tls
bootstrap/azure/main.tf             # RG, VNet/Subnet, AKS(OIDC+WI), KeyVault, DNS-Zone, Flux-Helm
bootstrap/azure/identity.tf         # azuread App-Regs, Federated Credentials, Role Assignments
bootstrap/azure/backend.tf          # State-Backend (Storage) — Bootstrap-Henne-Ei dokumentiert
bootstrap/azure/variables.tf
bootstrap/azure/outputs.tf
bootstrap/azure/tfvars/example.tfvars   # Vorlage; echte tfvars gitignored
.github/workflows/azure-bootstrap.yml   # tofu init/plan/apply (OIDC-Login zu Azure)
clusters/azure/**                       # Flux-Entrypoint (path ./apps/overlays/azure)
```

## Vorgaben & Werte

- **AKS:** `oidc_issuer_enabled = true`, `workload_identity_enabled = true`. Privat oder
  public je `tfvars`. System-assigned/UserAssigned Identities nach Bedarf.
- **`azuread`-Provider** erzeugt **per Code**:
  - App-Registration je OAuth-App (Grafana, pgAdmin): Redirect-URIs aus `${BASE_DOMAIN}`,
    Group-/Optional-Claims, Service Principal.
  - **Federated Identity Credentials** (Subject = K8s-ServiceAccount) für Workload Identity —
    **keine Client-Secrets**.
- **Workload-Identity-Nutzer:** cert-manager (DNS-01 gegen Azure DNS), external-dns
  (DNS-Contributor auf die Zone), age-Key-Abruf aus Key Vault (`Key Vault Secrets User`).
- **Key Vault:** speichert den age-Key (für SOPS) und ggf. den LE-Account-Key. Zugriff
  ausschließlich per WI-Rollenzuweisung (RBAC), nicht per Access Policy mit Secret.
- **DNS-Zone** `${BASE_DOMAIN}`: external-dns legt Records automatisch an; cert-manager macht
  ACME-DNS-01.
- **State-Backend:** Storage Account/Container per Tofu — Henne-Ei sauber dokumentieren
  (erster Lauf mit lokalem/temporärem Backend, dann Migration), **kein** manuelles Anlegen.
- **GitHub→Azure-Auth:** Actions per **OIDC** (federated) zu Azure, **kein** gespeichertes
  Service-Principal-Secret im Repo.
- **OpenTofu-Code** vollständig parametrisiert anlegen: alle Org-/Repo-/Tenant-/Host-Werte über
  `variables`/`tfvars`, nichts hartkodiert; CI über GitHub Actions.

## Definition of Done

- `tofu apply` (über Pipeline) erzeugt Cluster + alle Ressourcen + App-Regs **ohne** manuelle
  Schritte; Flux wird installiert und reconciled den azure-Overlay.
- Apps unter `https://<app>.${BASE_DOMAIN}` mit **gültigem Let's-Encrypt-Zertifikat** erreichbar.
- SSO gegen Entra funktioniert bis „Approval"/Login (App-Regs existieren per IaC).
- `tofu destroy` räumt vollständig ab.
- Kein Client-Secret und kein age-Key im Repo; WI-Rollen greifen.

## Verifikation

```bash
cd bootstrap/azure && tofu init && tofu plan
# nach apply:
flux get kustomizations -A
kubectl get certificate -A          # Ready=True, Issuer=letsencrypt
az aks show ... --query oidcIssuerProfile   # OIDC aktiv (read-only Check)
```
