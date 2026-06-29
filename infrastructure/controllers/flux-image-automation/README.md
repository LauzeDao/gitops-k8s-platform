# Flux Image Automation — Bootstrap Requirement

This directory does **not** ship any Kubernetes resources. The two controllers that
power Phase 10's image automation are **part of Flux itself** and are installed by the
**bootstrap layer**, not reconciled from this repo:

- `image-reflector-controller` — scans container registries and reflects tags into the
  cluster (`ImageRepository` / `ImagePolicy`).
- `image-automation-controller` — writes the selected image tag back into Git via a
  bot commit (`ImageUpdateAutomation`).

By default `flux install` / `flux bootstrap` only deploys the GitOps-Toolkit core
(`source`, `kustomize`, `helm`, `notification`). The image-automation controllers are
**optional components** and must be explicitly enabled.

## What the bootstrap must do

Enable the two extra components when Flux is installed.

### Local (`bootstrap/local`, uses `flux install`)

```bash
flux install \
  --components-extra=image-reflector-controller,image-automation-controller
```

### Azure / `flux bootstrap` (same flag)

```bash
flux bootstrap github \
  ... \
  --components-extra=image-reflector-controller,image-automation-controller
```

> If Flux is installed via the `flux2` Helm chart instead of the CLI, set the equivalent
> chart values:
>
> ```yaml
> imageReflectorController:
>   create: true
> imageAutomationController:
>   create: true
> ```

## CRs owned elsewhere

The actual `ImageRepository`, `ImagePolicy` and `ImageUpdateAutomation` custom resources
for podinfo live under `apps/base/podinfo/` (owned by the apps layer). This directory only
documents the controller prerequisite so the orchestrator can wire the bootstrap flag in.

## Verification (after bootstrap)

```bash
kubectl -n flux-system get deploy image-reflector-controller image-automation-controller
flux check
```
