# ADR 0002 — SOPS + age statt akv2k8s

## Kontext

Secrets dürfen niemals im Klartext ins Repo committet werden, dennoch muss die Plattform in **beiden
Modi** laufen — lokal `kind` (keine Cloud) und Azure AKS — aus demselben Basiscode. Unterschiede
sollen ausschließlich in Overlays leben.

Für das Secret-Management betrachtete Optionen:

- **akv2k8s** (oder ähnliche, rein auf Azure Key Vault ausgerichtete Controller): zieht Secrets
  direkt aus Azure Key Vault. Funktioniert nur, wenn ein Key Vault existiert, ist also
  **Azure-spezifisch** und bricht den lokalen, cloud-freien „clone & run"-Pfad.
- **SOPS + age, von Flux entschlüsselt:** Secrets werden **verschlüsselt** committet (`*.sops.yaml`),
  und Flux entschlüsselt sie beim Apply mithilfe eines age-Keys, der im `sops-age`-Secret in
  `flux-system` liegt. Derselbe Mechanismus funktioniert in beiden Modi identisch; nur die
  **Herkunft des age-Keys** unterscheidet sich.

## Entscheidung

**SOPS + age** als einheitlichen Secret-Mechanismus für beide Modi verwenden:

- Secrets liegen verschlüsselt im Git als `*.sops.yaml`; die `creation_rules` in `.sops.yaml` legen
  fest, welche Pfade auf welchen age-Recipient verschlüsselt werden.
- Flux' kustomize-controller entschlüsselt beim Apply — für den Basispfad ist kein zusätzlicher
  Controller nötig.
- **Herkunft des age-Keys:** lokal → eine Datei, die beim Bootstrap ins Cluster geladen wird
  (gitignored); Azure → **Key Vault, geholt per Workload Identity** beim Bootstrap.
- Ein rein für Azure gedachter External Secrets Operator, der aus Key Vault zieht, bleibt eine
  **optionale** „enterprise pattern"-Demo im azure-Overlay — nicht der Standardpfad.

## Konsequenzen

- **Positiv:** ein Mechanismus, beide Modi; funktioniert komplett offline auf `kind`; Secrets sind
  (als Chiffretext) in der Git-Historie nachvollziehbar; keine Cloud-Abhängigkeit für den lokalen
  Quickstart.
- **Positiv:** der age-Key ist das einzige Bootstrap-Secret und gelangt nie ins Repo.
- **Negativ / Trade-off:** Mitwirkende benötigen `sops` + `age` installiert und müssen den age-Key
  außerhalb des Repos verwalten; das Rotieren des Recipients erfordert ein erneutes Verschlüsseln
  betroffener Dateien.
