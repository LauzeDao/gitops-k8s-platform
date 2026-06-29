# Build-Spec — Arbeitspakete für (Sub-)Agenten

Dieses Verzeichnis zerlegt das Projekt in **präskriptive, abgeschlossene Phasen**. Jede Datei
ist so geschrieben, dass ein KI-(Sub-)Agent sie **ohne Rückfragen** umsetzen kann.

## So liest ein Agent eine Phase

1. Lies [`../../CLAUDE.md`](../../CLAUDE.md) (Master-Kontext) **und** die Phasen-Spec **ganz**.
2. Prüfe **Voraussetzungen** (welche Phasen müssen fertig sein).
3. Erzeuge **genau** die unter „Dateien" gelisteten Artefakte an den dort genannten Pfaden.
4. Halte **Vorgaben & Werte** ein (Versionen pinnen, Naming, Konventionen aus CLAUDE.md §8).
5. **Verifiziere gegen die Definition of Done (DoD)**, dann committe (Conventional Commits,
   eine Phase pro PR).

## Aufbau jeder Spec

- **Ziel** — was am Ende existiert/funktioniert.
- **Voraussetzungen** — Phasen-Abhängigkeiten.
- **Dateien** — exakte Pfade + Inhalt/Zweck.
- **Vorgaben & Werte** — Versionen, Helm-Values-Eckpunkte, Naming, Guardrails.
- **Definition of Done** — verifizierbare Kriterien.
- **Verifikation** — konkrete Befehle/Checks.

## Phasenübersicht

| # | Datei | Inhalt |
|---|---|---|
| 2 | [`02-repo-structure.md`](02-repo-structure.md) | Flux-Monorepo-Layout |
| 3 | [`03-local-bootstrap.md`](03-local-bootstrap.md) | kind + Flux + SOPS + Taskfile |
| 4 | [`04-infrastructure.md`](04-infrastructure.md) | ingress-nginx, cert-manager, external-dns, Kyverno |
| 5 | [`05-apps.md`](05-apps.md) | Grafana, Loki, pgAdmin, Headlamp, podinfo |
| 6 | [`06-secrets-sops.md`](06-secrets-sops.md) | SOPS+age, `.sops.yaml`, Flux-Decryption |
| 7 | [`07-observability.md`](07-observability.md) | kube-prometheus-stack, Loki-Collector, **Custom-Dashboard** |
| 8 | [`08-ci-policies.md`](08-ci-policies.md) | GitHub Actions, Kyverno-Policies, Renovate, pre-commit |
| 9 | [`09-azure-overlay.md`](09-azure-overlay.md) | OpenTofu AKS+Identitäten, Workload Identity |
| 10 | [`10-gitops-automation.md`](10-gitops-automation.md) | Flux Image Automation, Flagger-Canary |
| 11 | [`11-polish.md`](11-polish.md) | README, ADRs, Diagramme, Badges |

> Phase 1 (Doku & Kontext) ist mit `CLAUDE.md` + `docs/architecture.md` + diesem Verzeichnis
> bereits erbracht.

## Globale Verifikations-Bausteine (in jeder Phase nutzbar)

```bash
# Kustomize-Builds aller Cluster-Entrypoints müssen fehlerfrei sein:
kustomize build clusters/local
kustomize build clusters/azure

# Manifeste gegen K8s-Schema validieren:
kustomize build clusters/local | kubeconform -strict -summary -ignore-missing-schemas

# Im laufenden kind-Cluster:
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A
```
