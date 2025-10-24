# Kubernetes Monitoring Setup (Alloy + Loki + Mimir + Grafana )

This repo shows how I’d deploy a monitoring stack on Kubernetes using Helm and simple YAML manifests.

Two ways to deploy:

- `single-cluster-setup/` — simple one-cluster install with Helm values in this folder.
- `**base/` + `overlays/` — Kustomize + Helm for multi-env (e.g., dev/prod/staging).

<img width="1493" height="588" alt="Screenshot 2025-10-24 at 15 35 21" src="https://github.com/user-attachments/assets/c59b1e94-2616-43c6-a7cb-42eafdaf65b8" />

_Alloy UI_

---

## Prerequisites

Make sure the following are ready before running the commands:

- Docker Desktop (Kubernetes cluster enabled)
- Helm installed (`brew install helm` on MacOS)
- kustomize installed(`brew install kustomize` on MacOS)
- kubectl configured and pointing to your local cluster

You can check with:

```bash
kubectl get nodes
helm version
kustomize --help
```

---

## Quick Start (using Makefile)

You can use the included Makefile for quick setup.

```bash
cd single-cluster-setup/
```

### Create and start everything

```bash
make create-namespace
make apply ENV=<ENV_NAME> #e.g ENV=dev
```
> Kustomize build uses Helm charts under the hood, so make apply runs: `kustomize build overlays/$ENV --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -`

### Check if all pods are running

```bash
make status
```

### Delete everything (clean up)

```bash
make delete
```

### Forward Alloy UI port

```bash
make pf
```

- Then open Alloy UI at http://localhost:12345

---

## What’s deployed

1. Alloy as a Deployment (1 replica) with:
    - Kubernetes discovery (pods/endpoints/…)
    - Metrics scrape for annotated targets
    - prometheus.relabel to add cluster, environment, region
    - prometheus.remote_write → Mimir
    - loki.source.kubernetes via K8s API → Loki
    - HTTP UI on :12345

---

## References

- [Grafana Alloy Docs](https://grafana.com/docs/alloy/latest/set-up/install/kubernetes/)

- [Grafana Loki logs in kubernetes](https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/)

- [Grafana Mimir/prometheus relabel example](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/)

- [Grafana Helm Chart](https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/)
