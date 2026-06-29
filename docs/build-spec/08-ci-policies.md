# Phase 8 — CI, Policies & Automatisierung

## Ziel

GitHub Actions validieren jeden Push/PR, scannen auf Schwachstellen/Secrets, Renovate hält
Versionen aktuell, Kyverno-Policies wechseln von Audit auf Enforce, pre-commit fängt Fehler
lokal ab.

## Voraussetzungen

- Phase 2–7 (es gibt etwas zu validieren), Kyverno aus Phase 4.

## Dateien

```
.github/workflows/validate.yml      # fmt, kustomize build, kubeconform, tflint
.github/workflows/security.yml      # trivy (config+fs), gitleaks
.github/renovate.json               # Helm-/GitHub-Action-/Tofu-Updates
.pre-commit-config.yaml             # sops-check, gitleaks, yaml/tf fmt, kubeconform
```

## Vorgaben & Werte

- **validate.yml** (PR + push auf main):
  - `tofu fmt -check` + `tflint` über `bootstrap/azure`.
  - `kustomize build clusters/local` **und** `clusters/azure` → Pipe in `kubeconform -strict
    -ignore-missing-schemas`.
  - `helm template`/Schema-Check optional.
- **security.yml:**
  - `trivy config .` (Misconfig in K8s/Tofu) und `trivy fs` (Dependencies).
  - `gitleaks detect` (keine Klartext-Secrets).
- **renovate.json:** Manager für `helm-values`/`flux`/`github-actions`/`terraform`;
  Gruppierung minor/patch; Pin-Strategie beibehalten (kein Auto-Major-Merge).
- **pre-commit:** Hooks für `sops` (verschlüsselt?), `gitleaks`, `terraform_fmt`, `yamllint`,
  `kubeconform`. In der README als `pre-commit install` dokumentieren.
- **Kyverno:** die Policies aus Phase 4 von `Audit` auf **`Enforce`** umstellen, sobald der Cluster
  konform ist. Dokumentierte Ausnahmen via `PolicyException`.
- **Branch-Schutz** (README-Hinweis): PRs müssen grüne Checks haben.

## Definition of Done

- PRs lösen `validate` + `security` aus; beide grün auf einem sauberen Stand.
- Ein absichtlich eingebauter Fehler (z. B. `:latest`-Tag, Klartext-Secret) lässt CI **rot**
  werden → danach zurückbauen.
- Renovate öffnet (Test-)Update-PRs.
- Kyverno blockt im Enforce-Mode eine verletzende Test-Ressource.

## Verifikation

```bash
# lokal:
pre-commit run --all-files
kustomize build clusters/local | kubeconform -strict -ignore-missing-schemas
trivy config .
gitleaks detect --no-banner
```
