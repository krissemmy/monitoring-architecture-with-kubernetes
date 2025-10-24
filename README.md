# Kubernetes Monitoring Setup (Alloy + Loki + Mimir + Grafana )

This repo shows how I’d deploy a monitoring stack on Kubernetes using Helm and simple YAML manifests.

- single-cluster-setup/ considers for single cluster
- base/ and overlay/ using kustomize considers for multi-cluster


<img width="1492" height="497" alt="Screenshot 2025-10-22 at 15 02 18" src="https://github.com/user-attachments/assets/094fd04b-7616-491c-97db-8f8fb0acf4fd" />

_Mimir and Loki Charts on Grafana_

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

## References

- [Grafana Alloy Docs](https://grafana.com/docs/alloy/latest/set-up/install/kubernetes/)

- [Grafana Loki logs in kubernetes](https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/)

- [Grafana Mimir/prometheus relabel example](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/)

- [Grafana Helm Chart](https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/)
