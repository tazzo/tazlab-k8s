# AGENTS.md - Tazlab Kubernetes Repository Guide

This document provides context, guidelines, and commands for AI agents operating within the `tazlab-k8s` repository. 
This is an **Infrastructure as Code (IaC)** repository for a bare-metal Kubernetes cluster managed via Talos Linux on Proxmox.

## 1. Environment & Architecture

- **Cluster Name**: `talos-proxmox-cluster`
- **OS**: Talos Linux (immutable, API-managed OS).
- **Orchestration**: Kubernetes.
- **Core Components**:
  - **Networking**: MetalLB (L2 LoadBalancer), Traefik (Ingress), Kube-VIP.
  - **Storage**: Longhorn (Distributed Block Storage).
  - **Secrets**: SOPS (Mozilla) with AGE encryption, Infisical.
  - **Dev Environment**: DevContainer/DevPod (Debian-based) with `tazpod` vault.

## 2. Build, Lint, and Test Commands

In this IaC context, "build" equates to configuration validation and "test" equates to dry-runs or schema checks.

### Prerequisite Checks
Before running any commands, ensure the required tools are present:
```bash
# Check tool availability
command -v kubectl >/dev/null && echo "kubectl present"
command -v talosctl >/dev/null && echo "talosctl present"
command -v helm >/dev/null && echo "helm present"
command -v yamllint >/dev/null && echo "yamllint present"
```

### Validation (Linting & Formatting)
Run these commands to ensure code quality before proposing changes.

**YAML Validation (General)**
```bash
# Lint all YAML files in a directory (recursive)
yamllint .

# Lint a specific file
yamllint apps/hugo-blog/hugo-blog.yaml
```

**Helm Chart Validation**
```bash
# Lint a Helm chart located in ./charts/my-chart
helm lint ./charts/my-chart

# Verify Helm values against the chart
helm template my-release ./charts/my-chart -f ./charts/my-chart/values.yaml --debug
```

**Talos Configuration Validation**
```bash
# Validate Talos machine config or patches
talosctl validate --config talos/patches/global-patch.yaml --mode cloud
```

**Bash Script Analysis**
```bash
# Static analysis for shell scripts
shellcheck scripts/tazpod
```

### "Running a Single Test"
There is no unit test suite. To test a specific resource (e.g., a new Deployment manifest):

1.  **Syntax Check**:
    ```bash
    yamllint apps/new-app/deployment.yaml
    ```

2.  **Kubernetes Dry-Run** (Simulates server-side validation):
    *Note: Requires active cluster connection via `~/.kube/config`.*
    ```bash
    kubectl apply -f apps/new-app/deployment.yaml --dry-run=server
    ```

3.  **Diff Preview** (If modifying existing resources):
    ```bash
    kubectl diff -f apps/new-app/deployment.yaml
    ```

## 3. Code Style & Development Guidelines

### File Organization
Follow the established directory structure (see `GEMINI.md`):
- **`talos/`**: Machine configs, patches, and OS-level settings.
- **`bootstrap/`**: Core infrastructure manifests (CNI, CSI, Ingress).
- **`apps/`**: Application workloads (e.g., Hugo, Utilities).
- **`secrets/`**: Encrypted secrets. **NEVER** edit these manually without `sops`.
- **`scripts/`**: Automation tools.

### YAML & Kubernetes Manifests
- **Indentation**: Strictly 2 spaces.
- **Naming Conventions**:
  - Files: `kebab-case.yaml` (e.g., `cloudflare-ddns.yaml`).
  - Resources: `kebab-case` (lowercase alphanumeric + hyphens).
- **Comments**:
  - Use comments to explain *magic numbers* (ports, memory limits).
  - Comment out optional fields instead of deleting them if they might be useful later.
- **Best Practices**:
  - Always specify `namespace` in manifests or use a `kustomization.yaml`.
  - Use specific image tags (e.g., `image: nginx:1.21.6`), avoid `latest`.
  - Define `resources` (requests/limits) for all containers.

### Bash Scripting (`scripts/`)
- **Header**: Start with `#!/bin/bash`.
- **Safety**: Enable strict mode immediately:
  ```bash
  set -euo pipefail
  ```
- **Modularity**: Define logic in functions (e.g., `deploy_app() { ... }`).
- **Paths**: Use dynamic root resolution. Do not rely on relative paths from assumed PWD.
  ```bash
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  ```
- **Output**: Use emojis for status updates (✅, ⚠️, ❌) to match the existing style (see `scripts/tazpod`).

### Secrets Management (CRITICAL)
- **Zero Trust**: Assume the repo is public.
- **Encryption**: Use SOPS with AGE.
- **Workflow**:
  - **View**: `sops -d secrets/my-secret.yaml`
  - **Edit**: `sops secrets/my-secret.yaml`
  - **Creation**: Use `sops` to encrypt new files before committing.
- **Vault**: Refer to `scripts/tazpod` for how secrets are mounted in the dev environment.

### Git & Commit Messages
- **Format**: `type(scope): description`
  - Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `ci`.
  - Example: `feat(talos): add longhorn disk patch`
  - Example: `fix(apps): update hugo image tag`

## 4. Operational Workflows

### Refactoring & IaC Transition
Per `GEMINI.md`, the repository is transitioning towards Terraform.
- **Goal**: Move static YAMLs in `apps/` and `bootstrap/` to Terraform resources/modules eventually.
- **Current State**: Manual `kubectl apply` or Helm installs.
- **Agent Task**: When asked to "refactor", check if the resource can be templated or improved for Terraform adoption.

### Deployment Checklist
When adding a new application:
1. Create a folder in `apps/<app-name>`.
2. Define the `Deployment`/`StatefulSet`, `Service`, and `Ingress/HTTPRoute`.
3. If persistent storage is needed, use the `longhorn` StorageClass.
4. Validate with `yamllint`.
5. Add the app to the documentation or status report if necessary.

## 5. Agent-Specific Rules (Cursor/Copilot)

- **Read First**: Always read `GEMINI.md` to understand the current "Sprints" and "Technical Debt".
- **No Hallucinations**: Do not invent new cluster capabilities (e.g., don't assume a GPU is present unless verified).
- **Idempotency**: Ensure any script or command you generate can be run multiple times without side effects.
- **Security**: If you see a hardcoded password, STOP and flag it. Suggest moving it to `secrets/` or Infisical.
- **Context**: You are "Gemini" or "Antigravity" (an engineer pairing with the user). Maintain a professional, helpful, and concise engineering persona.

---
*Reference: .cursor/rules (None), .github/copilot-instructions.md (None)*
*Last Updated: Jan 24 2026*
