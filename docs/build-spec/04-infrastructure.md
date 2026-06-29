# Phase 4 — Infrastructure (Ingress, TLS, DNS, Policies)

## Ziel

Die cluster-weiten Controller stehen via Flux: ingress-nginx, cert-manager (+ ClusterIssuer),
external-dns (im azure-Overlay aktiv), Kyverno (Policies). Apps können sich ab hier auf
Ingress + TLS verlassen.

## Voraussetzungen

- Phase 3 (`task up:local` bringt einen leeren, Flux-verwalteten Cluster).

## Dateien

```
infrastructure/controllers/kustomization.yaml
infrastructure/controllers/ingress-nginx/{helmrelease,values}.yaml
infrastructure/controllers/cert-manager/{helmrelease,values}.yaml
infrastructure/controllers/external-dns/{helmrelease,values}.yaml
infrastructure/controllers/kyverno/{helmrelease,values}.yaml
infrastructure/controllers/namespaces.yaml            # tools, monitoring, dex
infrastructure/configs/kustomization.yaml
infrastructure/configs/cluster-issuer-selfsigned.yaml # local
infrastructure/configs/cluster-issuer-letsencrypt.yaml# azure (über Overlay aktiviert)
infrastructure/configs/kyverno-policies/*.yaml
```

## Vorgaben & Werte

- **Chart-Versionen pinnen** (Renovate aktualisiert später). Quellen als `HelmRepository`
  in `infrastructure/controllers/` (oder `sources/`):
  - ingress-nginx: `https://kubernetes.github.io/ingress-nginx`
  - cert-manager (jetstack): `https://charts.jetstack.io` — `installCRDs: true`
  - external-dns: `https://kubernetes-sigs.github.io/external-dns/`
  - kyverno: `https://kyverno.github.io/kyverno/`
- **cert-manager ClusterIssuer:**
  - **local:** `selfsigned` ClusterIssuer (kein ACME, kein Internet nötig).
  - **azure:** `letsencrypt` (ACME), DNS-01 oder HTTP-01; Account-Key als SOPS-Secret. Über
    `apps/overlays/azure` referenziert.
- **external-dns:** im local-Overlay **nicht** deployen (oder `replicas: 0`); im azure-Overlay
  aktiv mit Provider `azure`, Auth via **Workload Identity** (keine Credentials im Repo). Zone =
  `${BASE_DOMAIN}`.
- **ingress-nginx:** local als NodePort/`hostPort` passend zu den kind-`extraPortMappings`;
  azure als `LoadBalancer`. Unterschied im Overlay.
- **Kyverno-Policies** (Start, `validationFailureAction: Audit`, später `Enforce`):
  - Pflicht-Label `app.kubernetes.io/part-of: gitops-k8s-platform`.
  - `disallow-latest-tag`.
  - Pod Security Baseline/Restricted (außer dokumentierte Ausnahmen).
- **`dependsOn`:** `infrastructure/configs` hängt von `infrastructure/controllers` ab
  (Issuer braucht cert-manager-CRDs).

## Definition of Done

- ingress-nginx, cert-manager, kyverno Pods `Running`; CRDs vorhanden.
- `selfsigned`-ClusterIssuer `Ready=True` (local).
- Ein Test-Ingress mit `cert-manager.io/cluster-issuer` bekommt ein TLS-Secret ausgestellt.
- Kyverno-Policies sind installiert (Audit-Mode) und reporten.
- external-dns im local-Modus inaktiv, im azure-Overlay konfiguriert (Auth via WI, kein Secret).

## Verifikation

```bash
kubectl -n ingress-nginx get pods
kubectl get clusterissuer
kubectl get clusterpolicy
flux get helmreleases -A
```
