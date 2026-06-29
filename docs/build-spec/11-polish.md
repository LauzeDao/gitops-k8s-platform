# Phase 11 — Politur (README, ADRs, Diagramme)

## Ziel

Das Repo ist sauber und verständlich: ein klares README, gepflegte ADRs, aktuelle Diagramme
und ein klarer „in 5 Minuten lauffähig"-Pfad.

## Voraussetzungen

- Phasen 2–10 (es gibt etwas vorzuzeigen).

## Dateien

```
README.md                      # README (s. u.)
docs/adr/0001-*.md ...         # die getroffenen Entscheidungen
docs/architecture.md           # aktuell halten (Diagramme = Stand des Codes)
docs/screenshots/              # Grafana-Dashboard, Headlamp, podinfo-Canary
```

## Vorgaben & Werte

- **README-Struktur:**
  1. Ein-Satz-Pitch + Architektur-Bild (aus `docs/architecture.md`).
  2. **Badges:** CI (validate/security), „GitOps with Flux", Renovate.
  3. **Features** (Bullet-Highlights: dual-mode, WI/OIDC, SOPS, Observability, Canary).
  4. **Quickstart `local`** — exakt die Befehle (`task up:local` …) inkl. `/etc/hosts`-Hinweis.
  5. **Azure-Pfad** — Kurzbeschreibung + Verweis auf `09-azure-overlay.md`.
  6. **Architektur-Überblick** (Verweis auf docs) + **„Wie es funktioniert"** (GitOps-Loop).
  7. **Sicherheit** (keine Secrets im Repo, SOPS, WI), **Kosten** (local 0 €).
  8. **Repo-Struktur**-Baum, **Roadmap/Status**.
- **ADRs** (mindestens): GitHub statt Azure DevOps; SOPS+age statt akv2k8s; Workload Identity
  statt Client-Secret; Grafana aus kube-prometheus-stack; kind als Local-Tool.
- **Screenshots** des Custom-Dashboards und der Canary-Demo einbinden.
- **Sprache:** Doku und Code-Kommentare auf **Deutsch**, Mermaid-Diagramme und Code-Identifier
  auf **Englisch** — Entscheidung als ADR festhalten.
- **Hygiene:** `CONTRIBUTING.md` optional, konsistente Conventional Commits, keine toten
  Dateien/auskommentierten Blöcke.

## Definition of Done

- README erklärt das Projekt in < 2 Minuten und führt „clone & run" vor.
- Badges sind grün und verlinkt; Diagramme entsprechen dem Code.
- ADRs decken alle wesentlichen Entscheidungen ab.
- Allein anhand des Repos lässt sich `task up:local` erfolgreich ausführen.

## Verifikation

- Review durch eine projektfremde Person / zweiten Agenten: „Ist alles verständlich und konsistent?"
- Markdown-Linter über `docs/` und `README.md`.
- Links-Check (keine toten internen Links).
