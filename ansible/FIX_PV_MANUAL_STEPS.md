# Manual Steps to Fix PV with Wrong NFS Server IP

## Problem
The PersistentVolume `myhotel-app-v2-pv` has the wrong NFS server IP (`10.0.11.35` instead of `10.0.11.240`). PVs cannot be patched because `spec.persistentvolumesource` is immutable.

## Solution
Delete the PV and PVC, then let Helm recreate them with the correct IP.

---

## Step-by-Step Fix

### Step 1: Check Current Status
```bash
# Check Helm release
helm list -n default

# Check PV status
kubectl get pv myhotel-app-v2-pv

# Check PVC status
kubectl get pvc myhotel-app-v2-app-pvc -n default

# Check pods
kubectl get pods -n default | grep myhotel-app-v2
```

### Step 2: Scale Down Application Pods (Optional but recommended)
```bash
# Scale down to 0 to avoid issues during PV deletion
kubectl scale deployment myhotel-app-v2 -n default --replicas=0

# Wait for pods to terminate
kubectl get pods -n default -w
# Press Ctrl+C when all pods are terminated
```

### Step 3: Delete PVC First
```bash
# Delete the PVC (this will release the PV)
kubectl delete pvc myhotel-app-v2-app-pvc -n default

# Verify PVC is deleted
kubectl get pvc -n default | grep myhotel-app-v2
```

### Step 4: Delete the PV
```bash
# Delete the PV with wrong IP
kubectl delete pv myhotel-app-v2-pv

# Verify PV is deleted
kubectl get pv | grep myhotel-app-v2
```

### Step 5: Verify Helm Chart Values Have Correct IP
```bash
# Check if values.yaml has correct IP (should be 10.0.11.240)
grep -A 2 "serverIP" helm-charts/myhotel-app/values.yaml

# If it shows 10.0.11.35, update it:
# Edit: helm-charts/myhotel-app/values.yaml
# Change: serverIP: "10.0.11.35"
# To:     serverIP: "10.0.11.240"
```

### Step 6: Upgrade Helm Release (or Reinstall)

**Option A: Upgrade without wait (monitor manually)**
```bash
# Start the upgrade (runs in background, returns immediately)
helm upgrade myhotel-app-v2 ./helm-charts/myhotel-app \
  -n default \
  --set nfsServer.serverIP=10.0.11.240

# Monitor progress in another terminal:
# Watch Helm release status
watch -n 2 'helm status myhotel-app-v2 -n default'

# Or check status manually
helm status myhotel-app-v2 -n default

# Watch pods being created
kubectl get pods -n default -w

# Watch PV/PVC creation
kubectl get pv,pvc -n default -w
```

**Option B: Upgrade with wait and shorter timeout**
```bash
# Upgrade with 2 minute timeout (adjust as needed)
helm upgrade myhotel-app-v2 ./helm-charts/myhotel-app \
  -n default \
  --set nfsServer.serverIP=10.0.11.240 \
  --wait \
  --timeout 2m

# If it times out but resources are created, check status:
helm status myhotel-app-v2 -n default
```

**Option C: If upgrade fails, uninstall and reinstall**
```bash
helm uninstall myhotel-app-v2 -n default

# Install without wait to monitor
helm install myhotel-app-v2 ./helm-charts/myhotel-app \
  -n default \
  --set nfsServer.serverIP=10.0.11.240

# Then monitor as shown in Option A
```

### Step 7: Verify New PV Has Correct IP
```bash
# Check PV was recreated
kubectl get pv myhotel-app-v2-pv

# Verify the NFS server IP is correct
kubectl get pv myhotel-app-v2-pv -o jsonpath='{.spec.nfs.server}'
# Should output: 10.0.11.240

# Check full PV details
kubectl get pv myhotel-app-v2-pv -o yaml | grep -A 5 "nfs:"
```

### Step 8: Verify PVC is Bound
```bash
# Check PVC status
kubectl get pvc -n default | grep myhotel-app-v2
# Should show STATUS: Bound

# Check PVC details
kubectl get pvc myhotel-app-v2-app-pvc -n default -o yaml
```

### Step 9: Scale Up Application Pods (if you scaled down)
```bash
# Scale back up
kubectl scale deployment myhotel-app-v2 -n default --replicas=2

# Watch pods come up
kubectl get pods -n default -w
# Press Ctrl+C when pods are Running
```

### Step 10: Verify Pods Can Mount NFS
```bash
# Check pod status
kubectl get pods -n default | grep myhotel-app-v2

# Check if pods are running (not in CrashLoopBackOff)
kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Check pod events for mount issues
kubectl describe pod <pod-name> -n default | grep -A 10 "Events:"

# Test NFS mount in a pod
POD_NAME=$(kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2 -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n default $POD_NAME -- ls -la /app/data/

# Check if hotel_rooms.json exists
kubectl exec -n default $POD_NAME -- cat /app/data/hotel_rooms.json
```

---

## Troubleshooting

### If PVC won't delete:
```bash
# Check if PVC is in use
kubectl get pvc myhotel-app-v2-app-pvc -n default -o yaml | grep -A 5 "finalizers"

# If finalizers exist, remove them
kubectl patch pvc myhotel-app-v2-app-pvc -n default -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### If PV won't delete:
```bash
# Check PV status
kubectl get pv myhotel-app-v2-pv -o yaml | grep -A 5 "status:"

# If PV is Released but won't delete, remove finalizers
kubectl patch pv myhotel-app-v2-pv -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### If Helm upgrade still fails:
```bash
# Check for stuck Helm operations
helm list -n default --pending

# Rollback if needed
helm rollback myhotel-app-v2 -n default

# Or completely uninstall and reinstall
helm uninstall myhotel-app-v2 -n default
helm install myhotel-app-v2 ./helm-charts/myhotel-app -n default --set nfsServer.serverIP=10.0.11.240
```

### Verify NFS Server is Accessible:
```bash
# From control plane, test NFS connection
nc -zv 10.0.11.240 2049
nc -zv 10.0.11.240 111
nc -zv 10.0.11.240 20048

# If connection fails, check:
# 1. NFS server is running on controller: sudo systemctl status nfs-kernel-server
# 2. Security groups allow NFS ports (2049, 111, 20048)
# 3. Firewall rules allow NFS traffic
```

---

## Quick One-Liner (if you're confident)
```bash
# Delete everything and let Helm recreate (without wait, monitor manually)
kubectl delete pvc myhotel-app-v2-app-pvc -n default && \
kubectl delete pv myhotel-app-v2-pv && \
helm upgrade myhotel-app-v2 ./helm-charts/myhotel-app -n default \
  --set nfsServer.serverIP=10.0.11.240

# Then monitor in another terminal:
# watch -n 2 'kubectl get pv,pvc,pods -n default | grep myhotel-app-v2'
```

## Monitoring Commands (run in separate terminal)

While Helm is upgrading, use these commands to monitor progress:

```bash
# 1. Check Helm release status
helm status myhotel-app-v2 -n default

# 2. Watch all resources
watch -n 2 'kubectl get pv,pvc,pods,deployments -n default | grep myhotel-app-v2'

# 3. Check PV creation specifically
kubectl get pv myhotel-app-v2-pv -w

# 4. Check PVC binding
kubectl get pvc myhotel-app-v2-app-pvc -n default -w

# 5. Watch pods starting
kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2 -w

# 6. Check for errors
kubectl get events -n default --sort-by='.lastTimestamp' | grep myhotel-app-v2
```

