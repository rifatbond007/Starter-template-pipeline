#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
# Bootstrap script for EC2 instance:
#   1. Install k3s (lightweight K8s)
#   2. Install ArgoCD
#   3. Apply manifests and register the app
# ---------------------------------------------------------------

echo "=== Updating system ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== Installing k3s ==="
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

echo "=== Waiting for k3s nodes ==="
sleep 10
kubectl get nodes

echo "=== Installing Helm ==="
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Installing ingress-nginx ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml

echo "=== Installing ArgoCD ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Waiting for ArgoCD pods ==="
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "=== Patching ArgoCD Server to NodePort (for SSH port-forward) ==="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

echo "=== Getting initial admin password ==="
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "=== Applying project & application ==="
kubectl apply -f k8s/argocd/project.yaml
kubectl apply -f k8s/argocd/application.yaml

echo "=== Done ==="
echo "ArgoCD UI:     port-forward with: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "ArgoCD admin:  admin / password printed above"
echo ""
echo "To check the app sync status:"
echo "  argocd app get hackathon"
