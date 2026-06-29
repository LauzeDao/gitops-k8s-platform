# ADR 0005 — kind als lokales Cluster-Tool

## Kontext

Ein Kernziel ist **reproduzierbar & klonbar**: `task up:local` muss auf einer frischen Maschine
einen laufenden Stack erzeugen — **ohne Cloud-Account** und mit **0 € Kosten**. Das erfordert eine lokale Kubernetes-Option. Kandidaten sind `kind`, `minikube`,
`k3d` und das in Docker Desktop integrierte Kubernetes.

Anforderungen:

- Läuft überall dort, wo Docker läuft (Linux, macOS, Windows), mit minimalen zusätzlichen
  Abhängigkeiten.
- Unterstützt das Mappen der Host-Ports 80/443 ins Cluster, sodass ingress-nginx über die
  benutzerdefinierten `*.local.gitops.lab`-Hosts erreichbar ist.
- Leichtgewichtig, schnell zu erstellen/zu zerstören und skriptbar für ein idempotentes
  `task up:local` / `task down:local`.

## Entscheidung

**`kind` (Kubernetes-in-Docker)** als lokales Cluster-Tool verwenden:

- `bootstrap/local/kind-config.yaml` definiert das Cluster mit `extraPortMappings` für
  Container-Port 80→Host 80 und 443→Host 443.
- `task up:local` erstellt das kind-Cluster, installiert Flux, lädt den age-Key und lässt Flux
  reconcilen; `task down:local` löscht das Cluster vollständig.
- Es werden nur die im README als Voraussetzungen gelisteten Tools benötigt: `docker`, `kind`,
  `kubectl`, `flux`, `sops`, `age`, `kustomize`, `task`.

## Konsequenzen

- **Positiv:** hängt nur von Docker ab; plattformübergreifend; schnelles Erstellen/Abbauen;
  `extraPortMappings` lässt die Ingress-Story sauber funktionieren.
- **Positiv:** hält den lokalen Pfad wirklich kostenlos und offline und erfüllt das
  „clone & run"-Versprechen.
- **Negativ / Trade-off:** kind ist Single-Host und netzwerkseitig nicht produktionsrepräsentativ
  (nutzt NodePort/extraPortMappings statt eines echten LoadBalancers); manches Azure-spezifische
  Verhalten (external-dns, Let's Encrypt) lässt sich nur im azure-Overlay ausüben.
