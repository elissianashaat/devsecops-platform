# Debugging Log

| # | Error | Cause | Fix |
|---|-------|-------|-----|
| 1 | Helm can't import existing resources | Resources were installed with `kubectl apply`, not Helm — no ownership labels | Delete namespace, reinstall via Helm only |
| 2 | CRD exists after namespace delete | CRDs are cluster-scoped, not namespaced — survive `kubectl delete ns` | `kubectl delete crd <name>` separately |
| 3 | ClusterRole exists after namespace delete | Same as above — ClusterRoles are cluster-scoped | `kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/part-of=argocd` |
| 4 | CRD annotation too long (262144 bytes) | ArgoCD client-side apply stores full manifest in annotation — too big for large CRDs | Add `ServerSideApply=true` to Application syncOptions |
| 5 | Runner-set can't find controller at render time | Chart does cluster lookup during `helm template` — controller isn't deployed yet | Set `controllerServiceAccount.name` explicitly in values.yaml |
| 6 | Controller forbidden from reading secret | Wrong SA name — ArgoCD uses Application name as Helm release name, not `arc` but `arc-controller` | Fix: `name: arc-controller-gha-rs-controller` |
