# Kubernetes Guide

This guide covers setting up a local Kubernetes cluster with Kind, integrating it with the Floci-provisioned AWS infrastructure, and deploying workloads.

---

## Why Kind

Floci's EKS emulation covers the AWS control-plane API — you can create cluster resources, describe them, and manage node group metadata. What it cannot do is run a real Kubernetes API server or launch actual worker nodes.

Kind fills this gap. It runs a fully functional Kubernetes cluster inside Docker containers, giving you a real `kubectl`, real deployments, real services, and real ingress — all on your laptop.

The combination looks like this:

```
Floci EKS resource     → "This cluster exists in AWS" (metadata)
Kind cluster           → "This is where workloads actually run" (runtime)
```

This mirrors real EKS: AWS manages the control plane and you manage the data plane nodes.

---

## Current Status

Kind is installed on this machine (`kind-services` cluster, Kubernetes v1.31.1). It is currently stopped to avoid resource conflicts during Terraform development. The existing cluster can be restarted at any time — no data was lost.

```bash
# Check existing clusters
kind get clusters
# Output: services

# Restart the existing cluster's container
docker start services-control-plane

# Verify
kubectl get nodes
```

---

## Creating a Fresh Multi-Node Cluster

If you want a new cluster modelled after EKS (one control plane, two worker nodes), create it with a Kind config file.

Create `kind-configs/eks-like-cluster.yaml`:

```yaml
# kind-configs/eks-like-cluster.yaml
# Simulates an EKS cluster: 1 control plane + 2 worker nodes
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

name: floci-eks

nodes:
  # Control plane — equivalent to the EKS managed control plane
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      # HTTP ingress
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      # HTTPS ingress
      - containerPort: 443
        hostPort: 8443
        protocol: TCP

  # Worker node 1 — simulates an EKS managed node in us-east-1a
  - role: worker
    labels:
      topology.kubernetes.io/zone: us-east-1a
      node.kubernetes.io/instance-type: t3.medium

  # Worker node 2 — simulates an EKS managed node in us-east-1b
  - role: worker
    labels:
      topology.kubernetes.io/zone: us-east-1b
      node.kubernetes.io/instance-type: t3.medium
```

Create the cluster:

```bash
mkdir -p kind-configs
# create the file above, then:
kind create cluster --config kind-configs/eks-like-cluster.yaml
```

Expected output:
```
Creating cluster "floci-eks" ...
 ✓ Ensuring node image (kindest/node:v1.31.1) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-floci-eks"
```

Verify:

```bash
kubectl get nodes
# NAME                        STATUS   ROLES           AGE   VERSION
# floci-eks-control-plane     Ready    control-plane   1m    v1.31.1
# floci-eks-worker            Ready    <none>          1m    v1.31.1
# floci-eks-worker2           Ready    <none>          1m    v1.31.1
```

---

## kubectl Basics

```bash
# Switch between clusters
kubectl config get-contexts
kubectl config use-context kind-floci-eks

# Check cluster info
kubectl cluster-info

# View all nodes with labels
kubectl get nodes --show-labels

# View system pods
kubectl get pods -n kube-system
```

---

## Deploying a Sample Application

This example deploys a simple nginx application to verify the cluster works.

```bash
# Create a namespace
kubectl create namespace demo

# Deploy nginx
kubectl create deployment nginx --image=nginx:alpine -n demo --replicas=2

# Expose as a service
kubectl expose deployment nginx --port=80 --type=ClusterIP -n demo

# Verify
kubectl get pods -n demo
kubectl get service -n demo

# Port-forward to test locally
kubectl port-forward service/nginx 8080:80 -n demo &
curl http://localhost:8080
# Expected: nginx welcome page HTML
```

---

## Installing an Ingress Controller

The NGINX ingress controller routes external traffic into the cluster. With Kind's port mappings from the config above, HTTP on port 8080 reaches the ingress.

```bash
# Install using Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.hostPort.enabled=true \
  --set controller.nodeSelector."ingress-ready"=true

# Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

Create an Ingress resource for the demo app:

```yaml
# manifests/demo-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: demo.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80
```

```bash
kubectl apply -f manifests/demo-ingress.yaml

# Test (add demo.local to /etc/hosts first)
echo "127.0.0.1 demo.local" | sudo tee -a /etc/hosts
curl http://demo.local:8080
```

---

## Installing Helm Charts

```bash
# Add common repos
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Example: deploy a Redis instance
helm install redis bitnami/redis \
  --namespace demo \
  --set auth.enabled=false \
  --set master.persistence.enabled=false

kubectl get pods -n demo
```

---

## Pushing Images to Floci ECR

After deploying ECR with Terraform, you can tag and push local images. Because Floci runs a real OCI-compatible registry, standard `docker` commands work.

```bash
# Get the repository URL from Terraform output
ECR_URL=$(terraform -chdir=infrastructure/environments/eks-local output -raw ecr_repository_url)
# Example: 000000000000.dkr.ecr.us-east-1.amazonaws.com/floci-eks-app
# In Floci, this resolves to: localhost:4566/floci-eks-app

# Tag your image
docker tag nginx:alpine ${ECR_URL}:v1.0.0

# Push (Floci accepts pushes without real ECR auth)
docker push ${ECR_URL}:v1.0.0

# Verify
aws --endpoint-url http://localhost:4566 --no-cli-pager ecr list-images \
  --repository-name floci-eks-app
```

---

## RBAC Practice

```bash
# Create a service account
kubectl create serviceaccount app-sa -n demo

# Create a role that allows reading pods
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n demo

# Bind the role to the service account
kubectl create rolebinding app-pod-reader \
  --role=pod-reader \
  --serviceaccount=demo:app-sa \
  -n demo

# Test the permissions
kubectl auth can-i list pods \
  --as=system:serviceaccount:demo:app-sa \
  -n demo
# Expected: yes
```

---

## Managing Kind Clusters

```bash
# List all clusters
kind get clusters

# Stop a cluster (stops Docker containers, preserves state)
docker stop $(kind get nodes --name floci-eks)

# Start it again
docker start $(kind get nodes --name floci-eks)

# Delete a cluster permanently
kind delete cluster --name floci-eks
```

---

## Integrating Kind with Floci Infrastructure

The EKS resources provisioned by Terraform in Floci contain the networking metadata for the cluster (VPC ID, subnet IDs, security group IDs). When deploying real Kubernetes components that read AWS metadata (like the AWS Load Balancer Controller), you configure them with these values.

```bash
# Get infrastructure outputs
terraform -chdir=infrastructure/environments/eks-local output

# Key values to note for Kubernetes integration:
# - vpc_id
# - private_subnet_ids (worker node subnets)
# - public_subnet_ids (load balancer subnets)
# - ecr_repository_url
# - cluster_name
```

When you deploy an application that expects AWS metadata (e.g. assumes an IAM role via IRSA), you can point it at Floci's IAM endpoint instead. This is advanced usage and requires configuring the application's AWS SDK endpoint override.
