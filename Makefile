ENV ?= dev

apply:
	@kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f - || true
	@kustomize build overlays/$(ENV) --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl apply -f -

diff:
	@kustomize build overlays/$(ENV) --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl diff -f - || true

delete:
	@kustomize build overlays/$(ENV) --enable-helm --load-restrictor=LoadRestrictionsNone | kubectl delete -f - || true

pf:
	@set -e; \
	POD=$$(kubectl -n monitoring get pod -l app.kubernetes.io/name=alloy -o jsonpath='{.items[0].metadata.name}'); \
	echo "Forwarding to $$POD"; \
	kubectl -n monitoring port-forward $$POD 12345:12345 --pod-running-timeout=2m

status:
	@kubectl -n monitoring get deploy alloy
	@kubectl -n monitoring get pods -l app.kubernetes.io/name=alloy -o wide
	@kubectl -n monitoring get svc alloy
