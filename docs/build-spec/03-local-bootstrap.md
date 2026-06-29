# Phase 3 — Local-Bootstrap (kind + Flux + SOPS + Taskfile)

## Ziel

`task up:local` erzeugt auf einer frischen Maschine (Docker vorhanden) einen `kind`-Cluster,
installiert Flux, hinterlegt den age-Key und lässt Flux das Repo reconcilen. `task down:local`
räumt restlos auf.

## Voraussetzungen

- Phase 2 (Repo-Struktur, `clusters/local` existiert).

## Dateien

```
Taskfile.yml                         # Targets: up:local, down:local, validate, reconcile, decrypt-check
bootstrap/local/kind-config.yaml     # 1 control-plane + N worker, extraPortMappings 80/443
bootstrap/local/bootstrap.sh         # oder als Task-Steps: kind create, flux install, age-secret, git source
bootstrap/local/age.key.example      # Platzhalter/Hinweis — echter Key NICHT im Repo
.sops.yaml                           # creation_rules (Phase 6 verfeinert; hier Grundgerüst)
.gitignore                           # *.age, age.key, *.tfvars, kubeconfig, .task/
```

## Vorgaben & Werte

- **kind-Config:** `extraPortMappings` für Container-Port 80→Host 80 und 443→Host 443, damit
  ingress-nginx lokal über die Custom-Hosts erreichbar ist. Mindestens 1 control-plane,
  optional 2 worker.
- **Flux-Install lokal:** entweder `flux install` (CLI) **oder** der flux2-Helm-Chart in
  derselben Version wie Azure (Chart **2.18.4** = Flux **2.8.8**), damit beide Modi identische
  Flux-Versionen nutzen.
- **GitRepository-Quelle lokal:** zeigt auf das GitHub-Repo (`https://github.com/<user>/gitops-k8s-platform`),
  Branch `main`, `interval: 1m`. Für lokal-only-Tests auch lokaler Pfad/`flux create source git`
  möglich — Default ist GitHub.
- **age-Key:** wird als Secret `sops-age` (Key `age.agekey`) in `flux-system` geladen. Quelle:
  lokale Datei aus `bootstrap/local/` (gitignored). Generierung dokumentieren:
  `age-keygen -o age.key`.
- **Custom-Domain lokal:** `/etc/hosts`-Einträge für `grafana.local.gitops.lab`,
  `pgadmin.local.gitops.lab`, `headlamp.local.gitops.lab`, `podinfo.local.gitops.lab` → `127.0.0.1`.
  Task-Target `hosts:print` gibt die nötigen Zeilen aus (kein automatisches Editieren von
  `/etc/hosts` ohne Zustimmung).
- **Taskfile** nutzt nur Tools, die im README als Voraussetzung gelistet sind: `docker`, `kind`,
  `kubectl`, `flux`, `sops`, `age`, `kustomize`, `task`.

## Definition of Done

- `task up:local` läuft idempotent durch; danach:
  - `flux get kustomizations -A` zeigt alle `Ready=True`.
  - `flux get sources git -A` zeigt die GitRepository `Ready=True`.
- `task down:local` löscht den kind-Cluster vollständig.
- Kein age-Key/kubeconfig/Secret im Git (gitignore greift).

## Verifikation

```bash
task up:local
flux get kustomizations -A
kubectl get pods -A
task down:local
```
