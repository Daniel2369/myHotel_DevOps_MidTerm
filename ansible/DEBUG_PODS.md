# Debug Pods Stuck in Init State

## Quick Diagnosis Commands

### 1. Check Pod Events (shows what's failing)
```bash
# Check events for a specific pod
kubectl describe pod <pod-name> -n default | grep -A 20 "Events:"

# Or check all events
kubectl get events -n default --sort-by='.lastTimestamp' | grep myhotel-app-v2 | tail -20
```

### 2. Check Init Container Logs
```bash
# Get pod name
POD_NAME=$(kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2 -o jsonpath='{.items[0].metadata.name}')

# Check first init container (wait-for-nfs-server)
kubectl logs $POD_NAME -n default -c wait-for-nfs-server

# Check second init container (copy-hotel-rooms-json)
kubectl logs $POD_NAME -n default -c copy-hotel-rooms-json
```

### 3. Check PV/PVC Status
```bash
# Check if PV exists and has correct IP
kubectl get pv myhotel-app-v2-pv
kubectl get pv myhotel-app-v2-pv -o jsonpath='{.spec.nfs.server}'
# Should show: 10.0.11.240

# Check if PVC is bound
kubectl get pvc myhotel-app-v2-app-pvc -n default
# Should show STATUS: Bound
```

### 4. Test NFS Server Connectivity
```bash
# From control plane, test if NFS server is reachable
nc -zv 10.0.11.240 2049
nc -zv 10.0.11.240 111
nc -zv 10.0.11.240 20048

# Check if NFS server is running on controller
ssh ubuntu@10.0.11.240 "sudo systemctl status nfs-kernel-server"
ssh ubuntu@10.0.11.240 "showmount -e localhost"
```

### 5. Check Pod Details
```bash
# Get full pod description
kubectl describe pod <pod-name> -n default

# Check pod status
kubectl get pod <pod-name> -n default -o yaml | grep -A 10 "status:"
```

## Common Issues and Fixes

### Issue 1: NFS Server Not Reachable
**Symptom**: `wait-for-nfs-server` init container fails with "No route to host"

**Fix**:
```bash
# Verify NFS server is running on controller
ssh ubuntu@10.0.11.240 "sudo systemctl status nfs-kernel-server"

# If not running, start it
ssh ubuntu@10.0.11.240 "sudo systemctl start nfs-kernel-server"
ssh ubuntu@10.0.11.240 "sudo systemctl enable nfs-kernel-server"
```

### Issue 2: PVC Not Bound
**Symptom**: PVC shows "Pending" status

**Fix**:
```bash
# Check why PVC is pending
kubectl describe pvc myhotel-app-v2-app-pvc -n default

# If PV exists but not bound, check PV status
kubectl get pv myhotel-app-v2-pv -o yaml | grep -A 5 "status:"
```

### Issue 3: Init Container Timeout
**Symptom**: Init containers keep retrying

**Fix**: Check if NFS server is actually accessible from worker nodes:
```bash
# Test from a worker node (if you can SSH to it)
# Or check pod events for specific error messages
kubectl describe pod <pod-name> -n default | grep -i "error\|failed\|timeout"
```

## Restart Pods (After Fixing Issues)

### Option 1: Delete Pods (Kubernetes will recreate them)
```bash
# Delete all application pods (they will be recreated automatically)
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Watch them come back up
kubectl get pods -n default -w
```

### Option 2: Restart Deployment
```bash
# Restart the deployment
kubectl rollout restart deployment myhotel-app-v2 -n default

# Watch rollout status
kubectl rollout status deployment myhotel-app-v2 -n default
```

### Option 3: Scale Down and Up
```bash
# Scale to 0
kubectl scale deployment myhotel-app-v2 -n default --replicas=0

# Wait a moment
sleep 5

# Scale back up
kubectl scale deployment myhotel-app-v2 -n default --replicas=2

# Watch pods
kubectl get pods -n default -w
```

## Quick Diagnostic Script

Run this to get all diagnostic info at once:

```bash
#!/bin/bash
echo "=== Pod Status ==="
kubectl get pods -n default | grep myhotel-app-v2
echo ""

echo "=== PV Status ==="
kubectl get pv myhotel-app-v2-pv
echo ""

echo "=== PVC Status ==="
kubectl get pvc myhotel-app-v2-app-pvc -n default
echo ""

echo "=== PV NFS Server IP ==="
kubectl get pv myhotel-app-v2-pv -o jsonpath='{.spec.nfs.server}'
echo ""
echo ""

POD_NAME=$(kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2 -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [[ -n "$POD_NAME" ]]; then
  echo "=== Pod Events ==="
  kubectl describe pod $POD_NAME -n default | grep -A 15 "Events:"
  echo ""
  
  echo "=== Init Container Logs (wait-for-nfs-server) ==="
  kubectl logs $POD_NAME -n default -c wait-for-nfs-server --tail=20 2>&1 || echo "No logs yet"
  echo ""
fi
```

