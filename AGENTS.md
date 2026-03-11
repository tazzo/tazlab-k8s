# AGENTS.md — tazlab-k8s

GitOps repository for the TazLab cluster managed by Flux CD.
Bare-metal Kubernetes on Talos Linux / Proxmox.

Talos machine configs and cluster lifecycle scripts live in
`../ephemeral-castle/clusters/tazlab-k8s/proxmox/`.

## Cluster

- **Name**: `talos-proxmox-cluster` — 1 Control Plane + 2 Workers on Proxmox
- **OS**: Talos Linux (immutable, API-managed)
- **GitOps**: Flux CD v2
- **KUBECONFIG**: `../ephemeral-castle/clusters/tazlab-k8s/proxmox/configs/kubeconfig`

## Repository Structure

```
clusters/tazlab-k8s/         Flux Kustomization entrypoints — one file per layer
  infrastructure-operators-namespaces.yaml
  infrastructure-operators-core.yaml
  infrastructure-operators-data.yaml
  infrastructure-configs.yaml
  infrastructure-instances.yaml
  infrastructure-auth.yaml
  infrastructure-bridge.yaml
  infrastructure-monitoring.yaml
  apps-static.yaml           hugo-blog (static, image-automated)
  apps-data.yaml             mnemosyne-mcp (stateful, DB-backed)
  flux-system/               Flux bootstrap manifests

flux-system/                 Flux source-of-truth sync config

infrastructure/
  operators/                 HelmReleases + namespaces (controllers/operators)
    traefik/                 Ingress controller
    cert-manager/            TLS certificate management (Cloudflare DNS01)
    postgres-operator/       Crunchy PGO v5
    reloader/                Stakater Reloader (auto-restart on Secret/ConfigMap change)
    monitoring/              kube-prometheus-stack (Grafana + Prometheus + dashboards)
    dex/                     OIDC provider
    cloudflare-ddns/         Dynamic DNS
    hugo-blog/               namespace only
    tazlab-db/               namespace only
    auth/                    namespace only

  configs/                   ExternalSecrets + static config for operators
    cert-manager/            Cloudflare API secret + ClusterIssuer
    dex/                     Dex config secret
    tazlab-db/               S3 backup secret, Grafana password
    wildcard-tls/            Wildcard TLS cert (*.tazlab.net)
    storage/
    github-external-secret.yaml

  instances/                 Deployed instances of operators
    traefik/                 Traefik Service + Ingress
    tazlab-db/               PostgresCluster CR (Crunchy PGO)
    dex/                     Dex Deployment + Ingress + ConfigMap
    longhorn/                Longhorn Service + Ingress
    cloudflare-ddns/         DDNS Deployment
    pgadmin/                 PGAdmin Deployment + Ingress
    homepage/                Homepage dashboard + Ingress

  auth/                      OAuth2 Proxy (Deployment + Ingress + Middleware)
  bridge/                    Shared: IngressClass, ClusterIssuer
  automation/                Flux ImageUpdateAutomation + ImagePolicy
    hugo-blog/
    mnemosyne-mcp/
  common/                    Shared patches (e.g. wait-for-db init container)

apps/
  base/                      Base manifests (cluster-agnostic)
    hugo-blog/               Deployment, Certificate, Middlewares
    mnemosyne-mcp/           Deployment, Service, ExternalSecret, RBAC
  cluster/                   Cluster-specific Kustomize overlays
    hugo-blog/
    mnemosyne-mcp/

tests/
  verify_manifest_purity.sh  Checks no plaintext secrets in manifests
```

## Flux Load Order

Flux applies layers in dependency order (defined via `dependsOn` in `clusters/tazlab-k8s/`):

```
namespaces → core operators → data operators → configs → instances
          → auth → bridge → monitoring → apps
```

Never apply instances before their operator is ready.

## Stack Components

| Component | Type | Namespace |
|---|---|---|
| Traefik | Ingress controller | `traefik` |
| cert-manager | TLS (Cloudflare DNS01) | `cert-manager` |
| Crunchy PGO v5 | Postgres operator | `tazlab-db` |
| Stakater Reloader | Secret/CM watcher | `reloader` |
| kube-prometheus-stack | Monitoring | `monitoring` |
| Dex | OIDC provider | `dex` |
| OAuth2 Proxy | Auth gateway | `auth` |
| Cloudflare DDNS | Dynamic DNS | `cloudflare-ddns` |
| Longhorn | Block storage | `longhorn-system` |
| ESO | Infisical → K8s Secrets | `external-secrets` |
| hugo-blog | Static site | `hugo-blog` |
| mnemosyne-mcp | MCP server | `tazlab-db` |
| Homepage | Dashboard | `homepage` |
| PGAdmin | Postgres UI | `pgadmin` |

## Secrets Management

- **Source of truth**: Infisical EU
- **Bridge**: External Secrets Operator syncs Infisical → Kubernetes Secrets
- **In this repo**: only `ExternalSecret` CRDs — no plaintext secrets, no SOPS, no AGE keys
- Wildcard TLS cert `*.tazlab.net` is managed via cert-manager + Cloudflare DNS01

## Apps Pattern

`apps/base/<app>/` contains cluster-agnostic manifests.
`apps/cluster/<app>/kustomization.yaml` overlays cluster-specific patches.
Flux Image Automation in `infrastructure/automation/<app>/` handles tag updates.

## Validation Commands

```bash
# Lint YAML
yamllint .
yamllint apps/base/hugo-blog/hugo-blog.yaml

# Helm dry-run
helm lint ./charts/my-chart
helm template my-release ./charts/my-chart -f values.yaml --debug

# Kubernetes dry-run (requires active cluster)
kubectl apply -f apps/base/mnemosyne-mcp/ --dry-run=server
kubectl diff -f apps/base/mnemosyne-mcp/

# Check for plaintext secrets
./tests/verify_manifest_purity.sh
```

## Flux Workflow

```bash
# Force reconcile
flux reconcile source git flux-system
flux reconcile kustomization infrastructure-operators-core
flux reconcile kustomization apps-static

# Status
flux get all -A
flux get kustomizations -A

# Suspend / resume
flux suspend kustomization <name>
flux resume kustomization <name>

# Image automation status
flux get images all -A
```

## Code Style

- **Indentation**: 2 spaces, no tabs
- **Naming**: `kebab-case` for files and Kubernetes resource names
- **Images**: always specific tags, never `latest`
- **Resources**: define `requests` and `limits` for all containers
- **Namespace**: always specify `namespace` in manifests or via `kustomization.yaml`

## Agent Rules

- Infer load order from `dependsOn` in `clusters/tazlab-k8s/*.yaml` before touching infra
- Secrets → ExternalSecret only, never inline values
- Before adding an app: check if its namespace has a corresponding operator namespace entry
- Run `./tests/verify_manifest_purity.sh` after any change to manifests
