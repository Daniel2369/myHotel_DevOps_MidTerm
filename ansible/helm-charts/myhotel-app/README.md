# MyHotel Application Helm Chart

This Helm chart deploys the MyHotel application with NFS-backed persistent storage on Kubernetes.

## Prerequisites

- Kubernetes cluster (1.24+)
- Helm 3.x
- kubectl configured to access the cluster

## Architecture

- **NFS Server**: Deploys an NFS server using `itsthenetwork/nfs-server-alpine` image
- **Persistent Volume (PV)**: Points to the NFS server for shared storage
- **Persistent Volume Claim (PVC)**: Claims the PV for application pods
- **Application Deployment**: Runs the MyHotel application with NFS storage mounted
- **Service**: LoadBalancer service for AWS integration (creates AWS NLB)

## Installation

1. Ensure your Kubernetes cluster is set up and kubectl is configured.

2. Install the chart:
```bash
helm install myhotel-app ./helm-charts/myhotel-app
```

3. Wait for all pods to be ready:
```bash
kubectl get pods -w
```

4. Get the LoadBalancer endpoint:
```bash
kubectl get svc myhotel-app
```

## Testing NFS Mount

After deployment, verify the hotel rooms JSON file is accessible in the pods:

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=myhotel-app -o jsonpath='{.items[0].metadata.name}')

# Check if hotel rooms JSON file exists in the mounted volume
kubectl exec $POD_NAME -- ls -la /app/data/

# View the hotel rooms JSON file content
kubectl exec $POD_NAME -- cat /app/data/hotel_rooms.json

# Check if the application is reading from the JSON file
kubectl logs $POD_NAME | grep -i "loaded\|rooms"
```

## Configuration

See `values.yaml` for configurable parameters including:
- Application image and replicas
- NFS server configuration
- Persistent volume settings
- Service configuration
- Dummy JSON file content

## Troubleshooting

### NFS Mount Issues

If pods cannot mount the NFS volume, verify:

1. NFS server pod is running:
```bash
kubectl get pods -l app.kubernetes.io/component=nfs-server
```

2. NFS server service is accessible:
```bash
kubectl get svc myhotel-app-nfs-server
```

3. If the PV cannot connect to the NFS server using the service name, you may need to update the PV with the actual NFS server pod IP:
```bash
# Get NFS server pod IP
NFS_POD_IP=$(kubectl get pods -l app.kubernetes.io/component=nfs-server -o jsonpath='{.items[0].status.podIP}')

# Update the PV (edit the spec.nfs.server field)
kubectl patch pv myhotel-app-pv --type='json' -p='[{"op": "replace", "path": "/spec/nfs/server", "value": "'$NFS_POD_IP'"}]'

# Delete and recreate PVC to rebind
kubectl delete pvc myhotel-app-app-pvc
kubectl apply -f templates/pvc.yaml
```

### Check Application Logs

```bash
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=myhotel-app -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

### Verify LoadBalancer

```bash
kubectl get svc myhotel-app
# Wait for EXTERNAL-IP to be assigned (AWS NLB)
```

## Uninstallation

```bash
helm uninstall myhotel-app
```

**Note**: PVs are set to `Retain` policy, so they will persist after uninstallation. Manually delete them if needed:
```bash
kubectl delete pv myhotel-app-pv
```

