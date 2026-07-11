#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
# Bootstrap script for EC2 instance:
#   1. Install k3s (lightweight K8s)
#   2. Install ArgoCD
#   3. Apply manifests and register the app
# ---------------------------------------------------------------

echo "=== Installing k3s ==="
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

echo "=== Waiting for k3s ==="
sleep 15
kubectl get nodes

echo "=== Installing ArgoCD ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== Waiting for ArgoCD ==="
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "=== Getting admin password ==="
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "=== Applying project & application ==="
kubectl apply -f ~/k8s/argocd/project.yaml
kubectl apply -f ~/k8s/argocd/application.yaml

echo "=== Done ==="
echo "ArgoCD UI: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "Admin: admin / password above"
