# Fix NFS Server Connectivity Issue

## Problem
The `wait-for-nfs-server` init container cannot connect to the NFS server at `10.0.11.240` (controller node).

## Diagnosis Steps

### Step 1: Verify NFS Server is Running on Controller
```bash
# SSH to controller node
ssh -i labsuser.pem ubuntu@10.0.11.240

# Check NFS server status
sudo systemctl status nfs-kernel-server

# If not running, start it
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# Verify NFS exports
showmount -e localhost
# Should show: /srv/nfs/k8s-data 10.0.0.0/16

# Check if NFS ports are listening
sudo netstat -tlnp | grep -E '2049|111|20048'
# Or
sudo ss -tlnp | grep -E '2049|111|20048'
```

### Step 2: Test Connectivity from Worker Node
```bash
# SSH to the worker node where the pod is running (k8s-worker-ec2-instance-3)
# From inventory.ini, find the worker node IP, then:
ssh -i labsuser.pem ubuntu@<worker-node-ip>

# Test NFS ports from worker node
nc -zv 10.0.11.240 2049
nc -zv 10.0.11.240 111
nc -zv 10.0.11.240 20048

# If connection fails, it's a security group or network issue
```

### Step 3: Check Security Groups
The security groups should allow NFS traffic (ports 2049, 111, 20048) between nodes.

```bash
# From your local machine, check Terraform security group rules
cd terraform/main
terraform show | grep -A 10 "allow_nfs"
```

### Step 4: Test from Control Plane
```bash
# From control plane, test connectivity
nc -zv 10.0.11.240 2049
nc -zv 10.0.11.240 111
nc -zv 10.0.11.240 20048
```

## Solutions

### Solution 1: Start NFS Server (if not running)
```bash
# On controller node (10.0.11.240)
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Verify
sudo systemctl status nfs-kernel-server
showmount -e localhost
```

### Solution 2: Re-run NFS Installation Playbook
If NFS server wasn't installed properly:

```bash
# From Ansible server
ansible-playbook -i inventory.ini install-nfs-server.yml
```

### Solution 3: Check Security Group Rules
Ensure NFS ports are allowed in security groups:

```bash
# Check if NFS security group rules exist in Terraform
cd terraform/main
grep -A 5 "allow_nfs" ../modules/vpc/main.tf

# If missing, you may need to apply Terraform changes
terraform plan
terraform apply
```

### Solution 4: Temporarily Remove Init Container (Quick Test)
If you want to test if the main container works without the init container check:

```bash
# Edit the deployment to comment out or remove the wait-for-nfs-server init container
# Or scale down and test NFS mount manually
```

## Quick Fix Commands

### On Controller Node:
```bash
# Ensure NFS is running
sudo systemctl status nfs-kernel-server || sudo systemctl start nfs-kernel-server

# Verify exports
showmount -e localhost

# Check ports
sudo ss -tlnp | grep -E '2049|111|20048'
```

### Test from Worker Node:
```bash
# Replace <worker-ip> with actual worker node IP from inventory.ini
ssh -i labsuser.pem ubuntu@<worker-ip>
nc -zv 10.0.11.240 2049
```

### Restart Pods After Fix:
```bash
# Once NFS is accessible, restart pods
kubectl delete pods -n default -l app.kubernetes.io/instance=myhotel-app-v2
kubectl get pods -n default -w
```

## Expected Output

### When NFS Server is Working:
```bash
# From controller
$ showmount -e localhost
Export list for localhost:
/srv/nfs/k8s-data 10.0.0.0/16

# From worker node
$ nc -zv 10.0.11.240 2049
Connection to 10.0.11.240 2049 port [tcp/nfs] succeeded!
```

### When Fixed, Pod Logs Should Show:
```
Waiting for NFS server to be ready...
NFS server is ready!
Copying hotel rooms JSON file to NFS volume...
```

