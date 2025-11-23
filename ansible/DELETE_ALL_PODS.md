# Delete All Pods to Force Recreation

## Quick Delete

```bash
# Delete all pods for the release (they'll be recreated automatically)
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Or delete all pods including evicted ones
kubectl delete pods --field-selector status.phase!=Running -n default

# Or delete all pods in namespace (use with caution)
kubectl delete pods --all -n default
```

## Watch New Pods Start

```bash
# Watch pods being recreated
kubectl get pods -n default -w

# Or check status
kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2
```

## Complete Cleanup (if needed)

```bash
# 1. Delete all pods
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# 2. Delete evicted pods
kubectl delete pods --field-selector status.phase!=Running -n default

# 3. Wait a moment for cleanup
sleep 5

# 4. Watch new pods start
kubectl get pods -n default -w
```

## Verify New Pods Are Healthy

```bash
# Check pod status
kubectl get pods -n default

# Check init container logs
POD_NAME=$(kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
kubectl logs $POD_NAME -c wait-for-nfs-server -n default

# Check if pods are running (not evicted)
kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2
```

