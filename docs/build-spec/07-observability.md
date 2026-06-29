# Phase 7 — Observability (Prometheus, Loki-Collector, Custom-Dashboard)

## Ziel

Vollständiger Observability-Stack: Metriken (Prometheus), Logs (Loki **mit Collector**),
Alerting (Alertmanager), Grafana mit provisionierten Datasources, kuratierten Stack-Dashboards
**und einem projektspezifischen „Platform Overview"-Dashboard als Code**.

## Voraussetzungen

- Phase 4 (Infra) und Phase 5 (Loki-Backend, Apps liefern Logs/Metriken).

## Dateien

```
infrastructure/controllers/kube-prometheus-stack/{helmrelease,values}.yaml
infrastructure/controllers/grafana-alloy/{helmrelease,values}.yaml   # Log-Collector → Loki
infrastructure/configs/alloy-config.yaml                              # Discovery + loki.write
infrastructure/configs/dashboards/platform-overview.json             # eigenes Dashboard (JSON)
infrastructure/configs/dashboards/kustomization.yaml                 # ConfigMaps generieren
infrastructure/configs/grafana-datasources.yaml                      # Prometheus + Loki (als Code)
```

## Vorgaben & Werte

- **kube-prometheus-stack** (prometheus-community) liefert Prometheus, Alertmanager, Grafana,
  kube-state-metrics, node-exporter und **kuratierte Dashboards** automatisch über den
  Grafana-**Sidecar** (ConfigMaps mit Label `grafana_dashboard: "1"`).
- **Grafana = die Stack-Grafana.** Die Datasources **Prometheus** und **Loki** als Code
  provisionieren (Sidecar `grafana_datasource: "1"` oder `grafana.additionalDataSources`).
- **Log-Collector:** **Grafana Alloy** (oder Promtail) als DaemonSet, sammelt Pod-Logs und
  schreibt nach Loki (`loki.write`). Das schließt die in der alten Doku notierte Lücke
  („KEIN Collector").
- **Custom-Dashboard `platform-overview.json`** — als ConfigMap mit Label
  `grafana_dashboard: "1"` ausliefern (über `configMapGenerator`/`kustomize`). Inhalt (Panels):
  1. **App-Health** der 4 Apps + podinfo: Up/Ready, Restarts, PVC-Auslastung
     (`kube_pod_status_ready`, `kube_pod_container_status_restarts_total`,
     `kubelet_volume_stats_used_bytes`).
  2. **Ingress-Traffic** pro Host: Requests/s, 4xx/5xx-Rate, p95-Latenz
     (ingress-nginx-Metriken `nginx_ingress_controller_requests`,
     `nginx_ingress_controller_request_duration_seconds_bucket`).
  3. **TLS-Zertifikate**: Tage bis Ablauf (`certmanager_certificate_expiration_timestamp_seconds`).
  4. **Loki-Log-Raten** pro App + ein eingebettetes **Logs-Panel** (LogQL).
  5. **Flux/GitOps-Status**: Reconcile-Erfolg/Drift (`gotk_reconcile_condition`).
  - Templating-Variable `namespace` (Default `tools`) und `app`. Zeitbereich Default 6h.
- **Alerting:** mindestens je eine sinnvolle Regel (App down, Zertifikat < 14 Tage,
  Flux-Reconcile-Fehler, hohe 5xx-Rate).
- **ServiceMonitor/PodMonitor** für ingress-nginx, cert-manager, Flux aktivieren, damit deren
  Metriken in Prometheus landen.
- **Chart-Versionen pinnen.** Ressourcen-Requests für local klein halten.

## Definition of Done

- Grafana zeigt die **Stack-Dashboards** und das **„Platform Overview"** automatisch (ohne
  manuellen Import).
- Beide Datasources (Prometheus, Loki) sind provisioniert und liefern Daten.
- Logs der Apps erscheinen via Collector in Loki und im Logs-Panel.
- Mindestens eine Alert-Regel ist in Alertmanager sichtbar (Test feuert).

## Verifikation

```bash
kubectl -n monitoring get pods
# Datasources/Dashboards prüfen (port-forward Grafana), dann im UI:
#  - Dashboard "Platform Overview" vorhanden und mit Daten
#  - Explore → Loki → {namespace="tools"} liefert Logs
kubectl -n monitoring get configmap -l grafana_dashboard=1
```
