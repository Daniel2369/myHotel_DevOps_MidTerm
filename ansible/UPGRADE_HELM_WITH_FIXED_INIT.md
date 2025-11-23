# Upgrade Helm Release with Fixed Init Container

## Problem
The pods are stuck in `Init:0/2` because they're still using the old init container that checks for port 20048. The updated `deployment.yaml` template hasn't been deployed yet.

## Solution: Copy Updated Chart and Upgrade Helm Release

### Step 1: Copy Updated Helm Chart to Control Plane

From your local machine (where you have the updated Helm chart):

```bash
# Get the control plane IP (controller node)
# From Terraform outputs or inventory.ini
CONTROLLER_IP="10.0.11.240"  # Update with your controller IP

# Copy the entire Helm chart directory
scp -i labsuser.pem -r \
  myHotel_DevOps_MidTerm/ansible/helm-charts/myhotel-app \
  ubuntu@${CONTROLLER_IP}:/home/ubuntu/helm-charts/
```

**Or if you're on the Ansible server and want to copy to controller:**

```bash
# From Ansible server
CONTROLLER_IP="10.0.11.240"  # Update with your controller IP
scp -i labsuser.pem -r \
  /path/to/helm-charts/myhotel-app \
  ubuntu@${CONTROLLER_IP}:/home/ubuntu/helm-charts/
```

### Step 2: Upgrade Helm Release

SSH to the control plane and upgrade:

```bash
# SSH to controller
ssh -i labsuser.pem ubuntu@10.0.11.240

# Verify the updated chart is there
ls -la /home/ubuntu/helm-charts/myhotel-app/templates/deployment.yaml

# Check the init container in the template (should NOT have port 20048 check)
grep -A 5 "wait-for-nfs-server" /home/ubuntu/helm-charts/myhotel-app/templates/deployment.yaml

# Upgrade the Helm release (without --wait first, since pods are stuck)
helm upgrade myhotel-app-v2 /home/ubuntu/helm-charts/myhotel-app \
  --namespace default

# Delete stuck pods so they recreate with new template
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Wait for new pods to start
kubectl wait --for=condition=ready pod -n default -l app.kubernetes.io/instance=myhotel-app-v2 --timeout=5m
```

### Step 3: Verify Pods Start Successfully

```bash
# Watch pods restart
kubectl get pods -w

# Check init container logs (should show success without port 20048 check)
POD_NAME=$(kubectl get pods -l app.kubernetes.io/instance=myhotel-app-v2 -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME -c wait-for-nfs-server

# Verify pods are running
kubectl get pods -l app.kubernetes.io/instance=myhotel-app-v2
```

## Quick One-Liner (if you have access from local machine)

```bash
# Copy chart and upgrade in one go (from local machine)
CONTROLLER_IP="10.0.11.240"
scp -i labsuser.pem -r myHotel_DevOps_MidTerm/ansible/helm-charts/myhotel-app ubuntu@${CONTROLLER_IP}:/home/ubuntu/helm-charts/ && \
ssh -i labsuser.pem ubuntu@${CONTROLLER_IP} "helm upgrade myhotel-app-v2 /home/ubuntu/helm-charts/myhotel-app --namespace default && kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2"
```

## What Changed in the Init Container

**Old (still deployed):**
```bash
until nc -z $NFS_SERVER 2049 && nc -z $NFS_SERVER 111 && nc -z $NFS_SERVER 20048; do
```

**New (in updated template):**
```bash
if nc -z $NFS_SERVER 2049 && nc -z $NFS_SERVER 111; then
  echo "NFS server is ready (ports 2049 and 111 accessible)!"
  echo "mountd will be discovered via rpcbind on port 111"
  break
```

The new version:
- ✅ Only checks ports 2049 and 111
- ✅ Doesn't require port 20048
- ✅ Works with mountd's dynamic port

## Troubleshooting

### If upgrade times out:
```bash
# Upgrade without --wait flag (pods are stuck, so --wait will timeout)
helm upgrade myhotel-app-v2 /home/ubuntu/helm-charts/myhotel-app \
  --namespace default

# Then delete stuck pods to force recreation with new template
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Check Helm release status
helm status myhotel-app-v2 -n default

# Verify new template is applied
helm get manifest myhotel-app-v2 -n default | grep -A 10 "wait-for-nfs-server"
```

### If pods still stuck:
```bash
# Delete old pods to force recreation
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Check new pod init container
kubectl describe pod <new-pod-name> | grep -A 20 "wait-for-nfs-server"
```

### Verify NFS server is accessible:
```bash
# From worker node, test connectivity
ssh worker-node
nc -zv 10.0.11.240 2049
nc -zv 10.0.11.240 111
```

