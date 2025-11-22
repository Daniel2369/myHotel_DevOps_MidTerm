# Manual Helm Deployment Verification Guide

This guide helps you verify that the Helm chart `myhotel-app` is properly deployed on your Kubernetes cluster.

**Prerequisites:** SSH to the control plane node and ensure kubectl is configured.

```bash
# SSH to control plane
ssh -i labsuser.pem ubuntu@<control-plane-ip>
```

---
# 1. Check if Helm release exists
helm list

# 2. Check if deployment exists
kubectl get deployment myhotel-app

# 3. Check if pods are running
kubectl get pods | grep myhotel-app

# 4. Check PV and PVC
kubectl get pv | grep myhotel-app
kubectl get pvc | grep myhotel-app

# 5. Check service
kubectl get svc myhotel-app

**Expected Output:**
- PVC name: `myhotel-app-app-pvc`
- Status: `Bound`
- Volume: Should show `myhotel-app-pv`
- Access Mode: `ReadWriteMany`
- Capacity: `10Gi`

---

## 5. Verify Service

Check the LoadBalancer service:

```bash
# List all services
kubectl get svc

# Get service details
kubectl get svc myhotel-app -o wide

# Describe service (shows endpoints, events)
kubectl describe svc myhotel-app

# Get LoadBalancer endpoint (may take a few minutes to provision)
kubectl get svc myhotel-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
kubectl get svc myhotel-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Check service endpoints (should show pod IPs)
kubectl get endpoints myhotel-app
```

**Expected Output:**
- Service name: `myhotel-app`
- Type: `LoadBalancer`
- Port: `80` → `8000`
- Endpoints should show pod IPs (if pods are ready)
- LoadBalancer ingress will show AWS NLB DNS name once provisioned
