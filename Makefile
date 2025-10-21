# ---- config ----
NS_MON=monitoring
NS_MIMIR=monitoring-mimir

REL_ALLOY=alloy
REL_LOKI=loki
REL_GRAFANA=grafana
REL_MIMIR_MON=mimir

GRAFANA_CHART=grafana/grafana
ALLOY_CHART=grafana/alloy
LOKI_CHART=grafana/loki
MIMIR_CHART=grafana/mimir-distributed

ALLOY_VALUES=alloy.values.yaml
LOKI_VALUES=loki.values.yaml
GRAFANA_VALUES=grafana.values.yaml

# ---- helper macros ----
K=kubectl
H=helm

.PHONY: up status pf pf-all down nuke

# 1) Create everything
up:
	@echo "==> Creating namespaces"
	-$(K) create namespace $(NS_MON)
	-$(K) create namespace $(NS_MIMIR)
	@echo ""

	@echo "==> Installing Alloy"
	$(H) upgrade --install --namespace $(NS_MON) $(REL_ALLOY) $(ALLOY_CHART) -f $(ALLOY_VALUES)
	@echo ""

	@echo "==> Installing Loki"
	$(H) upgrade --install --namespace $(NS_MON) $(REL_LOKI) $(LOKI_CHART) -f $(LOKI_VALUES)
	@echo ""

	@echo "==> Installing Mimir"
	$(H) upgrade --install --namespace $(NS_MIMIR)       $(REL_MIMIR_MON) $(MIMIR_CHART)
	@echo ""

	@echo "==> Installing Grafana (with sidecars enabled)"
	$(H) upgrade --install --namespace $(NS_MON) $(REL_GRAFANA) $(GRAFANA_CHART) -f $(GRAFANA_VALUES)
	@echo ""

	@echo "==> Applying Grafana datasources & dashboards"
	$(K) apply -f grafana-datasources.yaml
	$(K) apply -f grafana-dashboard.yaml
	@echo ""

	@echo "==> Applying test apps"
	$(K) apply -f test-app.yaml
	@echo ""

	@echo "==> Waiting for core pods to be Ready"
	$(K) rollout status -n $(NS_MON)     deploy/$(REL_GRAFANA) --timeout=180s || true
	$(K) rollout status -n $(NS_MON)     ds/$(REL_ALLOY)       --timeout=180s || true
	$(K) rollout status -n $(NS_MON)     deploy/$(REL_LOKI)-gateway --timeout=180s || true

	@echo ""
	@echo "==> Done. Use 'make pf' to open Grafana on localhost:3000"

# 2) Show status across both namespaces
status:
	@echo "==> $(NS_MON) pods"
	@$(K) get pods -n $(NS_MON) -o wide
	@echo ""
	@echo "==> $(NS_MIMIR) pods"
	@$(K) get pods -n $(NS_MIMIR) -o wide

# 3a) Port-forward Grafana only (enough for dashboards)
pf:
	@echo "==> Port-forwarding Grafana on http://localhost:3000"
	@POD=$$($(K) get pods -n $(NS_MON) -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath='{.items[0].metadata.name}'); \
	GRAFANA_PASSWD=$$($(K) get secret --namespace $(NS_MON) grafana -o jsonpath="{.data.admin-password}" | base64 --decode); \
	echo "Grafana Password: $$GRAFANA_PASSWD"; echo; \
	$(K) -n $(NS_MON) port-forward $$POD 3000:3000 \

# 3b) (Optional) Forward Loki & Mimir too for CLI testing
pf-all:
	@echo "Open 3 terminals and run:"
	@echo "1) make pf"
	@echo "2) kubectl -n $(NS_MON)     port-forward svc/$(REL_LOKI)-gateway 3100:80"
	@echo "3) kubectl -n $(NS_MIMIR)   port-forward svc/mimir-nginx 9009:80"

# 4) Tear down Helm releases (keeps namespaces/PVCs)
down:
	-$(H) uninstall -n $(NS_MON)   $(REL_GRAFANA)
	@echo ""
	-$(H) uninstall -n $(NS_MON)   $(REL_LOKI)
	@echo ""
	-$(H) uninstall -n $(NS_MON)   $(REL_ALLOY)
	@echo ""
	-$(H) uninstall -n $(NS_MIMIR)   $(REL_MIMIR_MON)
	@echo ""
	-$(K) delete -n $(NS_MON)     -f grafana-datasources.yaml -f grafana-dashboard.yaml || true
	@echo ""
	-$(K) delete -f test-app.yaml || true
	@echo ""
	@echo "==> Uninstalled charts. To fully wipe namespaces/volumes, run 'make nuke'."

# 5) Fully delete EVERYTHING (namespaces, PVCs, etc.)
nuke: down
	-$(K) delete namespace $(NS_MON) --wait=false
	-$(K) delete namespace $(NS_MIMIR) --wait=false
	@echo "==> Deleting dangling PVCs (if namespaces linger while terminating)"
	@echo ""
	-$(K) get pvc -A | grep -E '$(NS_MON)|$(NS_MIMIR)' | awk '{print $$1" "$$2}' | xargs -r -n2 $(K) delete pvc -n
	@echo ""
	@echo "==> Nuke complete."
