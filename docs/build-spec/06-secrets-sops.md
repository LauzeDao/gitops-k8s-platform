# Phase 6 — Secrets mit SOPS + age

## Ziel

Alle Geheimnisse liegen **verschlüsselt** im Git und werden von Flux zur Apply-Zeit
entschlüsselt. Kein Klartext-Geheimnis im Repo, ein einheitlicher Mechanismus für beide Modi.

## Voraussetzungen

- Phase 3 (age-Key als `sops-age`-Secret in `flux-system`).
- Phase 5 (Apps referenzieren Secrets via `existingSecret`/`secretKeyRef`).

## Dateien

```
.sops.yaml                                  # creation_rules: Pfade → age-Recipient(s)
apps/base/<app>/secret.sops.yaml            # verschlüsselte App-/OAuth-Secrets
infrastructure/configs/*/secret.sops.yaml   # z.B. LE-Account-Key (azure)
clusters/local/apps.yaml / infrastructure   # Kustomization mit decryption.provider=sops
```

## Vorgaben & Werte

- **`.sops.yaml`** `creation_rules`: alle `*.sops.yaml`-Dateien werden mit dem Projekt-age-Recipient
  (`age1...`) verschlüsselt. Den **public** Recipient ins Repo (in `.sops.yaml`), den
  **private** Key niemals.
- **Flux-Decryption:** an den relevanten `Kustomization`-Objekten:
  ```yaml
  spec:
    decryption:
      provider: sops
      secretRef:
        name: sops-age      # Secret in flux-system, Key: age.agekey
  ```
- **Secret-Form:** Kubernetes-`Secret`-Manifest, dessen `data`/`stringData` per SOPS
  verschlüsselt ist (nur die Werte; die Struktur bleibt lesbar).
- **Verschlüsseln:** `sops -e -i apps/base/<app>/secret.sops.yaml`. Editieren via `sops <file>`.
- **azure-Variante (optional, Phase 9):** der age-Key kommt aus dem Key Vault via Workload Identity;
  alternativ der External Secrets Operator als „Enterprise-Pattern"-Demo — **nicht** Pflicht.
- **SOPS ist der einzige Secrets-Mechanismus** im Basiscode (kein akv2k8s o. Ä.). In einem ADR dokumentieren.
- **CI-Guard:** gitleaks/trivy-Secret-Scan + pre-commit verhindern versehentlichen Klartext.

## Definition of Done

- Es existiert **kein** unverschlüsseltes Secret im Repo (`grep`/gitleaks sauber).
- Nach `task up:local` sind die entschlüsselten K8s-Secrets im Cluster vorhanden und die Apps
  konsumieren sie (Login/Datasource funktioniert).
- `sops -d <file>` funktioniert nur mit dem privaten Key (Negativtest ohne Key schlägt fehl).

## Verifikation

```bash
sops -d apps/base/grafana/secret.sops.yaml >/dev/null && echo "decrypt ok"
kubectl -n tools get secret
gitleaks detect --no-banner || true
```
