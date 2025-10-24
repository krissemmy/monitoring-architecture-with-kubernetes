# Kubernetes Monitoring Setup (Alloy + Loki + Mimir + Grafana )

This repo shows how I’d deploy a monitoring stack on Kubernetes using Helm and simple YAML manifests.  
It’s similar to the monitoring setup I’ve used in my previous organization(the logs based monitoring architecture), this time adapted fully for Kubernetes.

<img width="1492" height="497" alt="Screenshot 2025-10-22 at 15 02 18" src="https://github.com/user-attachments/assets/094fd04b-7616-491c-97db-8f8fb0acf4fd" />

_Mimir and Loki Charts on Grafana_

---

## Prerequisites

Make sure the following are ready before running the commands:

- Docker Desktop (Kubernetes cluster enabled)
- Helm installed (`brew install helm` on macOS)
- kubectl configured and pointing to your local cluster

You can check with:

```bash
kubectl get nodes
helm version
```

---

## Quick Start (using Makefile)

You can use the included Makefile for quick setup.

```bash
cd single-cluster-setup/
```

### Create and start everything

```bash
make up
```

### Check if all pods are running

```bash
make status
```

### Delete everything (clean up)

```bash
make down
```

### Forward Grafana port

```bash
make pf
```

- Then open Grafana at http://localhost:3000

### Kill and remove everything(including namespaces, persistent volumes e.t.c)

```bash
make nuke
```

---

## Manual Deployment (step by step)

To do it manually without `make`:

```bash
kubectl create namespace monitoring
kubectl create namespace monitoring-mimir

# Install components with Helm
helm install --namespace monitoring alloy grafana/alloy -f alloy.values.yaml
helm install --namespace monitoring -f loki.values.yaml loki grafana/loki
helm install --namespace monitoring-mimir mimir grafana/mimir-distributed
helm install --namespace monitoring grafana grafana/grafana -f grafana.values.yaml

# create pod to generate sample metrics and logs
kubectl apply -f test-app.yaml

# Port-forward Grafana
export POD_NAME=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward -n monitoring $POD_NAME 3000:3000

# Get Grafana password (run on another terminal)
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

<img width="3294" height="503" alt="Screenshot 2025-10-22 at 15 00 10" src="https://github.com/user-attachments/assets/485af7e4-37f5-4f0c-8843-a0487edebaf2" />

_Mimir and Loki Charts on Grafana_

---

## References

- [Grafana Alloy Docs](https://grafana.com/docs/alloy/latest/set-up/install/kubernetes/)

- [Grafana Loki Helm Chart](https://grafana.com/docs/loki/latest/setup/install/helm/install-microservices/)

- [Grafana Mimir Distributed Chart](https://grafana.com/docs/helm-charts/mimir-distributed/latest/get-started-helm-charts/)

- [Grafana Helm Chart](https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/)
