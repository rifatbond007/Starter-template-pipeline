# Hackathon GitOps CI/CD Pipeline

A complete GitOps pipeline for a Turborepo monorepo using GitHub Actions, Docker, Kubernetes (k3s), and ArgoCD.

## Pipeline Flow

```
Push to dev ──► CI (lint+test) ──► auto-merge to main
                                        │
                                        ▼
                                   Build Docker images
                                   Push to Docker Hub
                                        │
                                        ▼
                          Update manifests/ in same repo
                                        │
                                        ▼
                              ArgoCD auto-syncs to K8s cluster
```

## Repository Structure

```
├── apps/
│   ├── client/          # Frontend (Next.js 14)
│   │   └── Dockerfile
│   └── server/          # Backend (Express)
│       └── Dockerfile
├── packages/
│   └── shared/          # Shared types/utilities
├── .github/workflows/
│   ├── dev-ci.yml       # CI on dev + auto-promote to main
│   └── main-cd.yml      # Build/push images + update manifests in-repo
├── k8s/
│   ├── manifests/       # K8s resources (Deployment, Service, Ingress)
│   └── argocd/          # ArgoCD Application & Project CRDs
├── scripts/
│   └── bootstrap-k3s-argocd.sh  # One-shot EC2 bootstrap
├── guides/
│   ├── argocd-install.md
│   └── secrets-management.md
└── SETUP_GUIDE.md       # Step-by-step from zero to deployed
```
