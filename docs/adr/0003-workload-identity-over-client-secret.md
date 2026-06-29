# ADR 0003 — Workload Identity (OIDC) statt Client-Secrets

## Kontext

Auf Azure müssen In-Cluster-Workloads (cert-manager für DNS-01, external-dns zur Verwaltung der
DNS-Zone und das Abholen des age-Keys aus Key Vault) sich bei Azure authentifizieren. Ein
naheliegender Ansatz wären **Client-Secrets** an App-Registrations — langlebige Credentials, die
gespeichert, rotiert und geschützt werden müssen und die leicht zu leaken sind.

AKS unterstützt einen **OIDC-Issuer + Workload Identity**, womit Kubernetes-ServiceAccounts ihre
projizierten Tokens über **Federated Identity Credentials** gegen Azure-AD-Tokens tauschen können —
ganz ohne gespeichertes Secret. Das ist eine bewusste Entscheidung gegen langlebige Client-Secrets.

## Entscheidung

**Workload Identity (OIDC)** für jegliche Azure-Authentifizierung von Workloads verwenden:

- AKS wird mit `oidc_issuer_enabled = true` und `workload_identity_enabled = true` provisioniert.
- Der `azuread`-Provider erzeugt **App-Registrations und Federated Identity Credentials** (Subject =
  der Kubernetes-ServiceAccount) vollständig **per Code** — **keine Client-Secrets**.
- Rollenzuweisungen (Key Vault Secrets User, DNS Contributor usw.) werden den Workload-Identitäten
  via Azure RBAC erteilt.
- GitHub Actions selbst authentifiziert sich bei Azure ebenfalls über **OIDC-Föderation**, nicht
  über ein gespeichertes Service-Principal-Secret (siehe ADR 0001).

## Konsequenzen

- **Positiv:** keine langlebigen Secrets zum Speichern, Rotieren oder Leaken; Least-Privilege über
  RBAC pro Identität; das gesamte Identitäts-Setup ist aus IaC reproduzierbar, ohne manuelle
  Portal-Schritte.
- **Positiv:** demonstriert ein aktuelles, empfohlenes Azure-Security-Pattern.
- **Negativ / Trade-off:** erfordert AKS mit aktiviertem OIDC-Issuer und korrekten
  Federated-Credential-Subjects; etwas mehr bewegliche Teile als ein einzelnes Client-Secret, und es
  ist Azure-spezifisch (der lokale Modus verwendet stattdessen eine age-Key-Datei).
