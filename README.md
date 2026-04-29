# DevSecOps Pipeline Platform

A self-hosted GitHub Actions runner fleet on Kubernetes with an integrated multi-layer security gate pipeline.

## Security Gates

| Gate | Tool | Blocks On |
|------|------|-----------|
| SAST | SonarQube | Critical/blocker code issues |
| Container Scanning | Trivy | CRITICAL or HIGH CVEs |
| Image Signing | Cosign (keyless) | Pipeline signs all passing images |
| Admission Control | OPA Gatekeeper | Unsigned images, privileged pods, unknown registries |

## Architecture

```
Developer pushes code
        ↓
GitHub Actions (self-hosted runner on Kubernetes)
        ↓
SonarQube SAST → Trivy scan → Cosign sign → push to registry
        ↓
ArgoCD syncs to cluster
        ↓
OPA Gatekeeper (admission webhook) — final enforcement layer
```

## Project Structure

```
devsecops-platform/
├── .github/workflows/          # CI/CD pipeline definitions
├── runners/                    # Actions Runner Controller manifests
├── gatekeeper/                 # OPA constraint templates + constraints
├── app/                        # Sample application for pipeline demo
└── README.md
```

## Components

### Self-Hosted Runners (Actions Runner Controller)
GitHub Actions runners deployed as Kubernetes pods via the ARC operator, with horizontal autoscaling — zero runners at idle, scales up on demand.

### SonarQube
Static analysis gating on every PR. Pipeline fails if the quality gate reports any critical or blocker issue.

### Trivy
Container image vulnerability scanning after `docker build`, before `docker push`. Fails the pipeline on HIGH or CRITICAL severity CVEs.

### Cosign (Keyless Signing)
Every image that clears Trivy is signed using Cosign's keyless mode (GitHub OIDC token). The signature is stored as an OCI artifact alongside the image.

### OPA Gatekeeper
Kubernetes admission controller enforcing:
- Only images with a valid Cosign signature may run
- No privileged containers
- All containers must declare CPU and memory limits
- Images must come from approved registries only

## Status

- [ ] Phase 1: Self-hosted runners on Kubernetes
- [ ] Phase 2: SonarQube SAST integration
- [ ] Phase 3: Trivy container scanning
- [ ] Phase 4: Cosign image signing
- [ ] Phase 5: OPA Gatekeeper admission control
- [ ] Phase 6: Full pipeline wiring + demo
