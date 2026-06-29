# ADR 0006 — Infrastruktur-Dual-Mode-Unterschiede via Overlays (Roadmap)

Datum: 2026-06-29

## Status

Vorgeschlagen

## Kontext

Die Plattform ist Dual-Mode (`local` kind / `azure` AKS). Der Application-Layer
(`apps/`) ist über Kustomize-Overlays (`apps/overlays/{local,azure}`) bereits
modus-bewusst und wird je Cluster durch die Flux-`apps`-Kustomization
ausgewählt. Der **Infrastructure-Layer** ist hingegen derzeit geteilt: Sowohl
`clusters/local` als auch `clusters/azure` reconcilen *dieselben* Pfade
`./infrastructure/controllers` und `./infrastructure/configs` ohne
modus-spezifisches Overlay.

Einige Infrastruktur-Komponenten sind von Natur aus modus-spezifisch:

| Komponente | local (kind) | azure (AKS) |
|---|---|---|
| ingress-nginx Service | hostPort auf `ingress-ready`-Node | `type: LoadBalancer` |
| cert-manager ClusterIssuer | `selfsigned-issuer` | `letsencrypt-prod` (ACME + azureDNS) |
| external-dns | nicht deployt (DNS = `/etc/hosts`) | deployt (Azure DNS + Workload Identity) |

Da es kein Infrastruktur-Overlay gibt, wurde der geteilte Satz so validiert, dass
er **standardmäßig local-korrekt** ist: ingress-nginx bindet hostPort, nur der
`selfsigned-issuer` wird angewendet, und `external-dns` + der
`letsencrypt-prod`-ACME-Issuer sind aus den geteilten Kustomizations bewusst
**ausgeschlossen** (ihre Dateien verbleiben für den azure-Pfad im Repo). Den
azure-only-ACME-Issuer auf ein lokales Cluster anzuwenden schlägt bei der
Validierung fehl (`azureDNS.resourceGroupName/subscriptionID` erforderlich), und
`external-dns` läuft ohne Azure-Credentials in eine Crash-Loop — daher der
Ausschluss.

## Entscheidung

Den Infrastructure-Layer vorerst geteilt und **local-korrekt** halten. Eine
vollständige Aufteilung `infrastructure/overlays/{local,azure}` — analog zum
apps-Layer — auf einen Follow-up verschieben. Bei der Umsetzung werden die
Cluster-Flux-Kustomizations (`clusters/{local,azure}/infra-*.yaml`) auf die
modus-spezifischen Overlay-Pfade zeigen, die Overlays werden den Service-Typ von
ingress-nginx patchen und den korrekten ClusterIssuer auswählen, und das
azure-Overlay wird `external-dns` und den `letsencrypt-prod`-Issuer (wieder)
einführen.

Der knifflige Teil ist, dass die Helm-Values der Controller in generierten
ConfigMaps (`configMapGenerator`) liegen, die ein Kustomize-Overlay nicht
in-place patchen kann. Der Follow-up wird daher für den
ingress-nginx-Service-Unterschied wahrscheinlich **Values-ConfigMaps pro
Overlay** (oder Flux-`postBuild`-Substitution) verwenden.

## Konsequenzen

- **Positiv:** Der lokale Modus ist heute vollständig reconcilebar und
  Ende-zu-Ende verifiziert; keine azure-only-Ressource verschmutzt oder bricht
  ein lokales Cluster.
- **Positiv:** azure-Manifeste/IaC verbleiben im Repo, bereit zur Verdrahtung.
- **Negativ:** Ein echtes `azure`-Apply ist **noch nicht schlüsselfertig** — es
  benötigt die obige Overlay-Aufteilung, bevor `external-dns`, der ACME-Issuer
  und ein LoadBalancer-Ingress reconcilen. Das ist die wichtigste verbleibende
  Lücke auf dem azure-Pfad (der per Projektentscheidung IaC-only / nicht live
  deployt ist).
- **Negativ:** Bis dahin lautet das Dual-Mode-Versprechen „apps fully overlaid,
  infra local-first" statt „infra fully overlaid".
