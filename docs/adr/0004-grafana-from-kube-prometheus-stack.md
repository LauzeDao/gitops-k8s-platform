# ADR 0004 — Grafana aus kube-prometheus-stack

## Kontext

Die Plattform benötigt Grafana für Dashboards/Visualisierung und außerdem einen vollständigen
Metrik-Stack (Prometheus, Alertmanager). Grafana kann entweder als **eigene, eigenständige
HelmRelease** oder als das in den **kube-prometheus-stack**-Chart gebündelte Grafana ausgerollt
werden.

Ein eigenständiges Grafana _zusätzlich_ zu dem von kube-prometheus-stack mitgelieferten zu
betreiben, würde **zwei Grafana-Instanzen** bedeuten — zwei zu konfigurierende SSO-Integrationen,
zwei Sätze von Datasources und über beide verteilte Dashboards. Das ist mehr Wartungsaufwand und für
einen Reviewer verwirrender.

## Entscheidung

Die **einzelne Grafana-Instanz verwenden, die mit kube-prometheus-stack ausgeliefert wird**:

- Ein Grafana, eine SSO-Integration (Dex lokal / Entra ID auf Azure), alle Datasources (Prometheus,
  Loki) und Dashboards an einem Ort.
- Das **benutzerdefinierte „Platform Overview"-Dashboard** wird als Code in diese Instanz
  provisioniert.
- Keine separate eigenständige Grafana-HelmRelease.

## Konsequenzen

- **Positiv:** ein Single Pane of Glass; eine SSO-Konfiguration; Dashboards-as-Code landen in einer
  Instanz; weniger zu wartende und zu pinnende Oberfläche.
- **Positiv:** Prometheus, Alertmanager und Grafana sind innerhalb eines Charts versionsabgestimmt.
- **Negativ / Trade-off:** Der Lebenszyklus von Grafana ist an die Chart-Version von
  kube-prometheus-stack gekoppelt; tiefe Grafana-Anpassungen sind auf das beschränkt, was die
  `grafana.*`-Values des Charts freigeben (für die Bedürfnisse dieses Projekts akzeptabel).
- **Hinweis:** Da Grafana eine RWO-PVC verwendet, muss `deploymentStrategy.type` auf `Recreate`
  stehen, um beim Upgrade einen Multi-Attach-Deadlock zu vermeiden (siehe `CLAUDE.md` §8).
