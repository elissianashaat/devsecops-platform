# Load .env if it exists — never commit .env, use .env.example as the template
-include .env
export

NAMESPACE_ARGOCD    := argocd
NAMESPACE_ARC_RUNNERS := arc-runners

.PHONY: bootstrap install-argocd create-github-secret apply-apps argocd-ui verify teardown

## Full bootstrap — run once to bring the cluster up from scratch
## Prereq: GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID, GITHUB_APP_PRIVATE_KEY_PATH must be set
bootstrap: install-argocd create-github-secret apply-apps
	@echo ""
	@echo "Bootstrap complete. ArgoCD is now syncing the cluster from the repo."
	@echo "Run 'make argocd-ui' to open the dashboard."

## Install ArgoCD — the only component not managed by ArgoCD itself (bootstrapping paradox)
## Chart: https://artifacthub.io/packages/helm/argo/argo-cd
install-argocd:
	helm repo add argo https://argoproj.github.io/argo-helm --force-update
	helm upgrade --install argocd argo/argo-cd \
		--namespace $(NAMESPACE_ARGOCD) \
		--create-namespace \
		--values infra/argocd/values.yaml \
		--wait

## Create the GitHub App secret from env vars — never stored in the repo
## Usage:
##   export GITHUB_APP_ID=123456
##   export GITHUB_APP_INSTALLATION_ID=78901234
##   export GITHUB_APP_PRIVATE_KEY_PATH=/path/to/app.pem
##   make create-github-secret
create-github-secret:
	kubectl create namespace $(NAMESPACE_ARC_RUNNERS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic arc-github-app-secret \
		--namespace $(NAMESPACE_ARC_RUNNERS) \
		--from-literal=github_app_id=$(GITHUB_APP_ID) \
		--from-literal=github_app_installation_id=$(GITHUB_APP_INSTALLATION_ID) \
		--from-file=github_app_private_key=$(GITHUB_APP_PRIVATE_KEY_PATH) \
		--dry-run=client -o yaml | kubectl apply -f -

## Hand control to ArgoCD — apply the root app-of-apps, ArgoCD syncs everything else
apply-apps:
	kubectl apply -f argocd/app-of-apps.yaml

## Open ArgoCD UI in the browser (port-forward + print credentials)
argocd-ui:
	@echo "ArgoCD URL:  http://localhost:8080"
	@echo "Username:    admin"
	@echo "Password:    $$(kubectl -n $(NAMESPACE_ARGOCD) get secret argocd-initial-admin-secret \
	  -o jsonpath='{.data.password}' | base64 -d)"
	kubectl port-forward svc/argocd-server -n $(NAMESPACE_ARGOCD) 8080:80

## Show the sync status of all ArgoCD-managed components
verify:
	@echo "\n=== ArgoCD Applications ==="
	kubectl get applications -n $(NAMESPACE_ARGOCD) 2>/dev/null || true
	@echo "\n=== ARC Controller pods ==="
	kubectl get pods -n arc-systems 2>/dev/null || true
	@echo "\n=== Runner pods (should be 0 at idle) ==="
	kubectl get pods -n $(NAMESPACE_ARC_RUNNERS) 2>/dev/null || true
	@echo "\n=== AutoscalingRunnerSets ==="
	kubectl get autoscalingrunnersets -n $(NAMESPACE_ARC_RUNNERS) 2>/dev/null || true

## Wipe everything — useful when you want a clean restart
teardown:
	kubectl delete -f argocd/app-of-apps.yaml 2>/dev/null || true
	helm uninstall argocd -n $(NAMESPACE_ARGOCD) 2>/dev/null || true
	kubectl delete ns $(NAMESPACE_ARGOCD) arc-systems $(NAMESPACE_ARC_RUNNERS) cert-manager 2>/dev/null || true
