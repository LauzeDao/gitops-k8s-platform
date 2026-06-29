# Phase 2 — Repo-Struktur (Flux-Monorepo-Layout)

## Ziel

Das Standard-**Flux-Monorepo-Layout** aus CLAUDE.md §3 anlegen — modus-agnostischer Kern in
`infrastructure/` + `apps/base/`, Unterschiede in `apps/overlays/{local,azure}` und
`clusters/{local,azure}`. Danach ist die Struktur fertig, auch wenn einzelne Komponenten erst
in späteren Phasen scharf geschaltet werden.

## Voraussetzungen

- Phase 1 (CLAUDE.md, architecture.md) vorhanden.

## Dateien (Soll-Struktur anlegen)

```
clusters/local/flux-system/         # GitRepository + root-Kustomization (interval, path ./clusters/local)
clusters/local/infrastructure.yaml  # Kustomization → ./infrastructure (dependsOn: -)
clusters/local/apps.yaml            # Kustomization → ./apps/overlays/local (dependsOn: infrastructure)
clusters/azure/...                  # analog, path ./apps/overlays/azure
infrastructure/controllers/kustomization.yaml
infrastructure/configs/kustomization.yaml
apps/base/<app>/...                 # je App: helmrelease.yaml, values.yaml, kustomization.yaml
apps/overlays/local/kustomization.yaml   # patcht Hosts/Issuer/SSO für local
apps/overlays/azure/kustomization.yaml   # patcht Hosts/Issuer/SSO für azure
```

## Vorgaben & Werte

- **Helm-Apps** (`grafana/`, `loki/`, `pgadmin/`, `headlamp/`) je unter `apps/base/<app>/`
  anlegen (helmrelease/values/ingress/kustomization), Namespaces sauber setzen.
- **HelmRepositories** (`sources/`) unter `infrastructure/controllers/` (bzw. eigene
  `sources/`-Kustomization) anlegen.
- **Secrets** ausschließlich über SOPS (Phase 6); in Azure optional zusätzlich der External
  Secrets Operator (Phase 9) — kein Pflichtpfad.
- **Bootstrap-Code** für Azure (`*.tf`) unter `bootstrap/azure/` anlegen; alle Org-/Repo-/
  Tenant-/Host-Werte über `variables`/`tfvars`, nichts hartkodiert.
- **Flux-`dependsOn`-Kette:** `infrastructure` (controllers → configs) vor `apps`.
- **Namespaces** als eigene Manifeste in `infrastructure/controllers/` anlegen
  (`tools`, `monitoring`, `dex`, …); `ingress-nginx`/`cert-manager` legen ihre NS selbst an.

## Definition of Done

- `kustomize build clusters/local` und `kustomize build clusters/azure` laufen **fehlerfrei**.
- Verzeichnisbaum entspricht CLAUDE.md §3.
- Keine hartkodierten Hostnames/Tenant-IDs im Basiscode (`apps/base`, `infrastructure`) —
  nur in Overlays/`tfvars`. (grep-Check, s. u.)

## Verifikation

```bash
kustomize build clusters/local  | kubeconform -strict -summary -ignore-missing-schemas
kustomize build clusters/azure | kubeconform -strict -summary -ignore-missing-schemas
# Im Basiscode dürfen keine echten Hostnames/Tenant-IDs/Subscriptions stehen (nur Overlays/tfvars):
grep -RInE "<echte-domain>|<tenant-id>|<subscription-id>" infrastructure apps/base clusters || echo "clean"
```
