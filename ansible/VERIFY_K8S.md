# Manual Kubernetes Cluster Verification Commands

These commands should be run on the **control plane node** (first EC2 instance) after the `install-k8s-cluster.yml` playbook completes.

## SSH to Control Plane Node

```bash
# Get the control plane IP from Terraform outputs or inventory.ini
ssh -i labsuser.pem ubuntu@<control-plane-ip>
```

## 1. Check Cluster Status

```bash
# kubectl is already configured for ubuntu user (no export needed)
# But if you need it, you can use: export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl cluster-info

# Check cluster nodes status
kubectl get nodes

# More detailed node information
kubectl get nodes -o wide


```

**Expected Output:**
- Should see 1 control plane node (k8s-controller) and worker nodes (k8s-worker-*) all in `Ready` status
- All nodes should show `NotReady` -> `Ready` after Calico installation

## 2. Verify System Components

```bash
# Check if all control plane pods are running
kubectl get pods -n kube-system

# Check system component status
kubectl get componentstatuses

# Check all namespaces
kubectl get namespaces

# Detailed pod status
kubectl get pods -n kube-system -o wide
```

```

## 3. Test Cluster Functionality

```bash
# Create a test deployment
kubectl create deployment nginx-test --image=nginx

# Check if deployment is running
kubectl get deployment nginx-test

# Check pod status
kubectl get pods -l app=nginx-test

# Check pod logs
kubectl logs -l app=nginx-test

# Clean up test deployment
kubectl delete deployment nginx-test
```