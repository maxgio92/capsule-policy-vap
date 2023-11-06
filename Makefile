.PHONY: e2e
e2e: cluster crd tenant policy test

.PHONY: cluster
cluster:
	@kind create cluster --config ./kind.yaml || true

.PHONY: crd
crd:
	@kubectl apply -k ./crds >/dev/null

.PHONY: policy
policy:
	@kubectl apply -f ./ingressclasses-validatingadmissionpolicy.yaml

.PHONY: tenant
tenant:
	@kubectl apply -f ./oil-tenant.yaml
	@kubectl apply -f ./alice-tenant-owner-rolebinding.yaml

.PHONY: test
test: tenant policy test/ingressclass test/ingressclass/teardown

.PHONY: test/ingressclass
test/ingressclass:
	@echo -n "* As tenant owner I'm allowed to create ingress of class allowed to my tenant: "
	@{ kubectl --as "alice" --as-group "capsule.clastix.io" apply -f ./ingress-bronze.yaml && echo OK; } || { echo FAILED; exit 1; }
	@echo -n "* As tenant owner I'm not allowed to create ingress of class denied to my tenant: "
	@kubectl --as "alice" --as-group "capsule.clastix.io" apply -f ./ingress-silver.yaml && { echo FAILED; exit 1; } || echo OK
	@echo -n "* As cluster admin I'm allowed to create ingress of all classes: "
	@{ kubectl  apply -f ./ingress-silver.yaml && echo OK; } || { echo FAILED; exit 1; }
	@{ kubectl  apply -f ./ingress-bronze.yaml && echo OK; } || { echo FAILED; exit 1; }

.PHONY: test/ingressclass/teardown
test/ingressclass/teardown:
	@kubectl delete -f ./ingress-silver.yaml >/dev/null 2>&1 || true
	@kubectl delete -f ./ingress-bronze.yaml >/dev/null 2>&1 || true

.PHONY: cleanup
cleanup:
	@kind delete cluster --name capsule
