# Fix NFS with Dynamic Ports - Step by Step Guide

## Overview
We've updated the configuration to allow mountd to use dynamic ports (32768-65535) instead of requiring port 20048. This simplifies the setup and works with the security group rules.

## Steps to Apply Changes

### Step 1: Apply Terraform Changes (Add Dynamic Port Range Rules)

```bash
# Navigate to Terraform directory
cd terraform/main

# Review the changes (optional)
terraform plan

# Apply the changes to add dynamic port range security group rules
terraform apply

# Confirm when prompted (type 'yes')
```

**What this does:**
- Adds security group rules allowing TCP/UDP ports 32768-65535 between VMs
- This allows mountd to use any dynamic port it chooses

### Step 2: Re-run NFS Installation Playbook

```bash
# From Ansible server (or your local machine if you have access)
# Make sure you're in the directory with inventory.ini

# Run the updated NFS installation playbook
ansible-playbook -i inventory.ini install-nfs-server.yml
```

**What this does:**
- Installs/verifies NFS server on controller
- Installs NFS client on worker nodes
- Verifies mountd is running (using dynamic port via rpcbind)
- No longer tries to force port 20048

### Step 3: Restart Application Pods (Use Updated Init Container)

```bash
# SSH to controller or use kubectl from Ansible server
# Make sure KUBECONFIG is set correctly

# Delete the existing pods to force recreation with new init container
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Or if you want to upgrade the Helm release (recommended):
helm upgrade myhotel-app-v2 /home/ubuntu/helm-charts/myhotel-app \
  --namespace default \
  --wait \
  --timeout 1m
```

**What this does:**
- New pods will use the updated init container
- Init container only checks ports 2049 and 111 (no port 20048 check)
- Mountd will be discovered via rpcbind automatically

### Step 4: Verify Everything Works

```bash
# Check pod status
kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

# Check init container logs (should show success)
POD_NAME=$(kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2 -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME -n default -c wait-for-nfs-server

# Verify NFS mount works
kubectl exec $POD_NAME -n default -- ls -la /app/data/

# Check if hotel_rooms.json exists
kubectl exec $POD_NAME -n default -- cat /app/data/hotel_rooms.json
```

## Quick All-in-One Script

If you want to run everything from the Ansible server:

```bash
#!/bin/bash
# Run from Ansible server

echo "=== Step 1: Apply Terraform changes ==="
cd ~/terraform/main  # Adjust path if needed
terraform apply -auto-approve

echo ""
echo "=== Step 2: Re-run NFS installation ==="
cd ~  # Back to home directory
ansible-playbook -i inventory.ini install-nfs-server.yml

echo ""
echo "=== Step 3: Restart application pods ==="
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2

echo ""
echo "=== Step 4: Wait for pods to be ready ==="
kubectl wait --for=condition=ready pod -n default -l app.kubernetes.io/instance=myhotel-app-v2 --timeout=5m

echo ""
echo "=== Verification ==="
kubectl get pods -n default -l app.kubernetes.io/instance=myhotel-app-v2
```

## Troubleshooting

### If Terraform apply fails:
- Check that you're in the correct directory
- Verify AWS credentials are configured
- Check if there are any state lock issues

### If NFS playbook fails:
- Check that inventory.ini has correct IPs
- Verify SSH access to all nodes
- Check if apt locks are causing issues (playbook now has timeout)

### If pods still stuck in Init:
- Check init container logs: `kubectl logs <pod-name> -c wait-for-nfs-server`
- Verify NFS server is running on controller: `ssh controller "sudo systemctl status nfs-kernel-server"`
- Check if ports 2049 and 111 are accessible from worker nodes
- Verify security group rules are applied

### If mountd not found:
- Check on controller: `rpcinfo -p localhost | grep mountd`
- If not found, restart NFS: `sudo systemctl restart nfs-kernel-server`
- Verify exports: `showmount -e localhost`

## Expected Results

After completing all steps:
- ✅ Security group allows dynamic ports 32768-65535
- ✅ NFS server running on controller with mountd using dynamic port
- ✅ Application pods start successfully
- ✅ Init container shows "NFS server is ready"
- ✅ Pods can access `/app/data/hotel_rooms.json`

