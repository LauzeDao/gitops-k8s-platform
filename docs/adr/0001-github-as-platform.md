# ADR 0001 — GitHub als Plattform

## Kontext

Das Projekt lag ursprünglich in Azure DevOps und wurde für den öffentlichen Zugang nach GitHub
umgezogen; dabei musste der gesamte Pipeline-/IaC-Code entsprechend konvertiert werden.

Das Projekt braucht eine Plattform für Repository und CI, die zum GitOps-Ansatz passt
(Flux pollt Git) und sich ohne langlebige Secrets gegen Azure authentifizieren kann.

Wesentliche Anforderungen:

- Das Repo ist die einzige Wahrheit für einen **GitOps**-Workflow (Flux pollt Git).
- CI soll ohne zusätzliche Konten zugänglich und günstig zu betreiben sein.
- Die Azure-Authentifizierung aus der CI heraus soll gespeicherte, langlebige
  Service-Principal-Secrets vermeiden.

Als Alternative wurde u. a. Azure DevOps betrachtet.

## Entscheidung

Repository und gesamte CI auf **GitHub** hosten:

- Single Source of Truth und Flux-`GitRepository` zeigen auf
  `github.com/LauzeDao/gitops-k8s-platform`.
- CI läuft über **GitHub Actions** (`validate.yml`, `security.yml`).
- Dependency-Updates laufen über **Renovate**.
- Die Azure-Bootstrap-Pipeline authentifiziert sich bei Azure über **GitHub OIDC (Federated
  Credentials)**, sodass kein Service-Principal-Secret im Repo gespeichert wird.

## Konsequenzen

- **Positiv:** native OIDC-Föderation zu Azure (keine gespeicherten Secrets); ein einziger,
  vertrauter Ort für Code, Issues, PRs und Actions.
- **Positiv:** Pipeline-Definitionen sind Teil des Repos und untermauern die
  „everything as code"-Story.
- **Negativ / Trade-off:** Bindung an das GitHub-Ökosystem; Integrationen anderer Plattformen
  (z. B. Azure-DevOps-Boards/-Repos) werden nicht genutzt.
