# Architektur — gitops-k8s-platform

Diese Doku erklärt das Setup visuell. Sie ist bewusst diagrammlastig und richtet sich an alle,
die das Repo zum ersten Mal sehen. Inhaltliche Quelle der Wahrheit bleibt
[`../CLAUDE.md`](../CLAUDE.md).

- [1. Kontext (Big Picture)](#1-kontext-big-picture)
- [2. Zwei Layer: Bootstrap vs. Application](#2-zwei-layer-bootstrap-vs-application)
- [3. GitOps-Reconciliation-Loop](#3-gitops-reconciliation-loop)
- [4. Dual-Mode: local (kind) vs. azure (AKS)](#4-dual-mode-local-kind-vs-azure-aks)
- [5. Request-/TLS-/DNS-Flow](#5-request-tls-dns-flow)
- [6. Secrets-Flow (SOPS + age)](#6-secrets-flow-sops--age)
- [7. Identität & SSO](#7-identität--sso)
- [8. Bootstrap-Sequenz Azure (alles per IaC)](#8-bootstrap-sequenz-azure-alles-per-iac)

---

## 1. Kontext (Big Picture)

```mermaid
flowchart LR
    dev([Developer]) -- git push --> repo[(GitHub Repo\ngitops-k8s-platform)]
    repo -- Actions: validate/security --> ci{{GitHub Actions}}
    repo -- poll ~1min --> flux[Flux Controllers\nin cluster]
    flux -- reconcile --> cluster[(Kubernetes Cluster\nkind OR AKS)]
    subgraph cluster_content [Cluster contents]
        infra[infrastructure/\nIngress · cert-manager · DNS · Kyverno · Observability]
        apps[apps/\nGrafana · Loki · pgAdmin · Headlamp · podinfo]
    end
    cluster --- cluster_content
    renovate[Renovate Bot] -- update PRs --> repo
    user([User]) -- HTTPS --> apps
```

**Kernaussage:** Menschen reden nur mit Git. Flux ist die einzige Instanz, die den Cluster
verändert. CI prüft, Renovate hält Versionen aktuell.

---

## 2. Zwei Layer: Bootstrap vs. Application

```mermaid
flowchart TB
    subgraph bootstrap [Bootstrap layer — one-time, creates cluster + Flux]
        direction LR
        b_local["bootstrap/local\nkind + Flux + age key"]
        b_azure["bootstrap/azure\nOpenTofu: AKS(OIDC+WI), RG, VNet,\nKeyVault, DNS, azuread App-Regs"]
    end
    subgraph app [Application layer — continuous, polled by Flux]
        direction LR
        clusters["clusters/{local,azure}\nFlux entrypoint Kustomizations"]
        infra["infrastructure/**"]
        apps2["apps/**"]
        clusters --> infra --> apps2
    end
    bootstrap -- installs Flux, which takes over from here --> app

    changeA["Change in infrastructure/ or apps/"] -. just git push .-> app
    changeB["Change in bootstrap/**, *.tf, Flux version"] -. bootstrap run .-> bootstrap
```

**Faustregel:** App-/Infra-Ordner → nur `git push`. Bootstrap/Tofu/Flux-Version →
Bootstrap-Lauf (lokal `task`, Azure GitHub-Actions-Pipeline).

---

## 3. GitOps-Reconciliation-Loop

```mermaid
sequenceDiagram
    participant Git as GitHub Repo
    participant SC as Flux source-controller
    participant KC as Flux kustomize-controller
    participant HC as Flux helm-controller
    participant K8s as Kubernetes API

    SC->>Git: poll GitRepository (interval 1m)
    Git-->>SC: new commit (revision)
    SC->>KC: artifact ready
    KC->>KC: build + SOPS decrypt + dependsOn order
    KC->>K8s: apply infrastructure/ (Server-Side Apply)
    KC->>HC: HelmRelease objects
    HC->>K8s: install/upgrade Charts (apps/)
    K8s-->>KC: Status (Ready/Drift)
    Note over KC,K8s: Drift is corrected on the next reconcile
```

---

## 4. Dual-Mode: local (kind) vs. azure (AKS)

```mermaid
flowchart TB
    base["Shared core\ninfrastructure/ + apps/base/"]
    base --> ol["overlays/local"]
    base --> oa["overlays/azure"]

    subgraph L [Mode local — kind]
        ol --> l1["cert-manager: self-signed Issuer"]
        ol --> l2["DNS: /etc/hosts → 127.0.0.1"]
        ol --> l3["SSO: Dex (static users)"]
        ol --> l4["age key: file"]
    end
    subgraph A [Mode azure — AKS]
        oa --> a1["cert-manager: Let's Encrypt (ACME)"]
        oa --> a2["DNS: external-dns → Azure DNS"]
        oa --> a3["SSO: Entra ID (azuread App-Regs)"]
        oa --> a4["age key: Key Vault via Workload Identity"]
    end
```

**Designregel:** Unterschiede leben **nur** in Overlays. `apps/base` und `infrastructure`
sind modus-agnostisch.

---

## 5. Request-/TLS-/DNS-Flow

```mermaid
flowchart LR
    user([User]) -- "https://grafana.&dollar;{BASE_DOMAIN}" --> dns{DNS}
    dns -- local: /etc/hosts --> lb
    dns -- azure: external-dns Record --> lb[Ingress LoadBalancer/NodePort]
    lb --> ing[ingress-nginx]
    ing -- TLS termination\n(Secret <app>-ingress-secret) --> svc[Service]
    svc --> pod[App pod]
    cm[cert-manager] -. issues certificate .-> ing
    cm -- local --> issuerL[self-signed ClusterIssuer]
    cm -- azure --> issuerA[Let's Encrypt ClusterIssuer]
```

---

## 6. Secrets-Flow (SOPS + age)

```mermaid
flowchart LR
    dev([Developer]) -- "sops -e" --> enc["secret.sops.yaml\n(encrypted in Git)"]
    enc --> repo[(GitHub)]
    repo --> kc[Flux kustomize-controller]
    age["age key\n(sops-age Secret in flux-system)"] --> kc
    kc -- decrypts at apply time --> k8s[(K8s Secret in cluster)]
    k8s --> app[App reads via existingSecret/secretKeyRef]

    subgraph keyherkunft [age key origin]
        f1["local: file at bootstrap"]
        f2["azure: Key Vault → Workload Identity"]
    end
    keyherkunft -.-> age
```

**Wichtig:** Im Git liegen nur verschlüsselte Werte. Der age-Key ist das einzige Bootstrap-
Geheimnis und gelangt nie ins Repo.

---

## 7. Identität & SSO

```mermaid
flowchart TB
    subgraph local [local — Dex]
        gL[Grafana] -- OIDC --> dex[Dex IdP in cluster]
        pL[pgAdmin] -- OAuth --> dex
        dex --> users[(static demo users)]
    end
    subgraph azure [azure — Entra ID]
        gA[Grafana] -- OIDC --> entra[Entra ID]
        pA[pgAdmin] -- OAuth --> entra
        tofu["azuread provider (IaC)"] -- creates App-Regs/redirects/claims --> entra
    end
```

---

## 8. Bootstrap-Sequenz Azure (alles per IaC)

```mermaid
sequenceDiagram
    participant GH as GitHub Actions
    participant TF as OpenTofu
    participant AZ as Azure (azurerm)
    participant AAD as Entra (azuread)
    participant AKS as AKS cluster

    GH->>TF: tofu init/plan/apply (bootstrap/azure)
    TF->>AZ: RG, VNet, Storage (state backend), Key Vault, DNS zone
    TF->>AZ: AKS with OIDC issuer + Workload Identity
    TF->>AAD: App-Registrations (Grafana/pgAdmin), Federated Credentials
    TF->>AZ: Role Assignments (KV-Get, DNS-Contributor) to WI identities
    TF->>AKS: install Flux2 + Flux2-Sync (Helm)
    AKS-->>GH: Flux takes over, polls Git, rolls out infra/+apps/
    Note over GH,AKS: No manual portal step
```

---

## Legende / Konventionen in den Diagrammen

- **`flux-system`**: Namespace der Flux-Controller.
- **`tools`**: Namespace der vier Apps + podinfo.
- **`monitoring`**: kube-prometheus-stack + Loki + Collector.
- Pfeile „nur git push" = Application-Layer; „Bootstrap-Lauf" = Bootstrap-Layer.
