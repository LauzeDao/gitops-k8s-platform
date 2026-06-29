# Phase 5 — Apps (Grafana, Loki, pgAdmin, Headlamp, podinfo)

## Ziel

Die vier Apps + die Demo-App podinfo laufen `READY` und sind über ihre Custom-Hosts per HTTPS
erreichbar. SSO ist verdrahtet (Dex lokal), Secrets über SOPS (Phase 6) bzw. zunächst Demo-Werte.

## Voraussetzungen

- Phase 4 (Ingress + cert-manager + Issuer stehen).

## Dateien

```
apps/base/grafana/        # ODER Nutzung der Grafana aus kube-prometheus-stack (s. Phase 7)
apps/base/loki/{helmrelease,values,kustomization}.yaml
apps/base/pgadmin/{helmrelease,values,ingress,config_local,kustomization}.yaml
apps/base/headlamp/{helmrelease,values,ingress,kustomization}.yaml
apps/base/podinfo/{helmrelease,values,ingress,kustomization}.yaml
apps/overlays/local/kustomization.yaml   # Hosts *.local.gitops.lab, selfsigned-Issuer, Dex-SSO
apps/overlays/azure/kustomization.yaml   # Hosts *.${BASE_DOMAIN}, LE-Issuer, Entra-SSO
```

## Vorgaben & Werte

- **Namespace:** alle Apps in `tools`.
- **Grafana:** primär die Instanz aus **kube-prometheus-stack** (Phase 7) nutzen — hier nur die
  SSO-/Ingress-Verdrahtung vorbereiten. Falls in Phase 5 eine eigenständige Grafana nötig ist,
  später auf die Stack-Grafana konsolidieren (ADR festhalten).
- **Loki:** SingleBinary + Filesystem-PVC (kein Objektspeicher lokal). **RWO-PVC** beachten.
- **pgAdmin:** runix `pgadmin4`; **`strategy.type: Recreate`** (RWO-PVC!); OAuth via
  `config_local.py`; Secret-Referenz via `existingSecret`.
- **Headlamp:** `baseURL: /headlamp`; Ingress-Path entsprechend.
- **podinfo:** Canary-fähige Demo (`stefanprodan/podinfo`-Chart), Host
  `podinfo.<domain>`; dient in Phase 10 als Image-Automation-/Canary-Ziel.
- **Ingress-TLS-Secrets:** Konvention `<app>-ingress-secret` (alle Apps gleich), ausgestellt
  von cert-manager über die ClusterIssuer-Annotation.
- **RWO-PVCs → `Recreate`** (Grafana `deploymentStrategy.type`, pgAdmin `strategy.type`) —
  RollingUpdate = Multi-Attach-Deadlock.
- **SSO local:** OIDC-Client-Configs zeigen auf Dex (Phase 4/7 stellt Dex bereit). Demo-User
  dokumentieren.
- **Secrets:** in dieser Phase Platzhalter/SOPS-Referenzen, scharfe Werte in Phase 6.
- **Chart-Versionen pinnen.**

## Definition of Done

- `kubectl -n tools get pods` → alle `Running/Ready`.
- Jede App über `https://<app>.local.gitops.lab` erreichbar (TLS vom selfsigned-Issuer).
- Headlamp lädt unter `/headlamp`; pgAdmin-Login-Seite erscheint; podinfo zeigt seine UI/JSON.
- Keine Klartext-Secrets in den Manifesten.

## Verifikation

```bash
kubectl -n tools get pods,ingress,pvc
curl -k https://podinfo.local.gitops.lab/healthz
flux get helmreleases -n tools
```
