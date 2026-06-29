# Phase 10 — GitOps-Automatik (Image Automation & Canary)

## Ziel

Zeige „echte" GitOps-Automatik an der Demo-App **podinfo**: Flux schreibt neue Image-Tags
selbst per Git-Commit zurück, und ein Flagger-Canary rollt Updates progressiv mit automatischem
Rollback bei Fehlern aus.

## Voraussetzungen

- Phase 5 (podinfo läuft), Phase 7 (Prometheus für Canary-Metriken).

## Dateien

```
infrastructure/controllers/flux-image-automation/   # image-reflector + image-automation aktivieren
infrastructure/controllers/flagger/{helmrelease,values}.yaml
apps/base/podinfo/imagepolicy.yaml         # ImageRepository + ImagePolicy (semver)
apps/base/podinfo/imageupdateautomation.yaml
apps/base/podinfo/canary.yaml              # Flagger Canary (analysis, metrics, thresholds)
```

## Vorgaben & Werte

- **Flux Image Automation:** `image-reflector-controller` + `image-automation-controller`
  (im flux2-Chart aktivieren). `ImageRepository` scannt podinfo-Tags, `ImagePolicy` wählt per
  **semver-Range**, `ImageUpdateAutomation` committet die neue Tag-Referenz zurück ins Repo
  (eigener Bot-Commit, signiert/zugeordnet).
- **Marker** im podinfo-Manifest: `# {"$imagepolicy": "tools:podinfo"}` an der Image-Zeile.
- **Flagger Canary:** Provider `nginx` (ingress-nginx); Analyse über Prometheus-Metriken
  (Request-Success-Rate, p99-Latenz); `stepWeight`/`threshold`/`maxWeight` konservativ;
  automatisches **Rollback** bei Metrik-Verletzung. Optional Load-Gen (`flagger-loadtester`).
- **Demo-Drehbuch** dokumentieren: neuen Tag bereitstellen → Flux committet → Flagger fährt
  Canary hoch → bei „kaputtem" Tag automatischer Rollback. In README/`docs/` als GIF/Schritte.
- **Scope-Hinweis:** Nur **podinfo** ist Automations-/Canary-Ziel. Die vier Stateful-Apps
  (PVCs) bleiben bei `Recreate` ohne Canary.

## Definition of Done

- Ein neuer passender podinfo-Tag führt zu einem **automatischen Git-Commit** durch Flux.
- Flagger zeigt einen erfolgreichen Canary-Rollout (Weight 0→100) im Status.
- Ein bewusst fehlerhafter Tag wird automatisch **zurückgerollt** (Canary `Failed`, Primary stabil).

## Verifikation

```bash
flux get image repository -A
flux get image policy -A
flux get image update -A
kubectl -n tools get canary
kubectl -n tools describe canary podinfo | sed -n '/Events/,$p'
```
