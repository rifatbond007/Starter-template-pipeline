# Complete Setup Guide — One Repo, Zero to Deployed

---

## Prerequisites

- A GitHub account
- A Docker Hub account
- An AWS EC2 instance (Ubuntu 22.04, t2.medium or larger)
- An SSH key pair to access the EC2 instance
- A domain name (optional — use port-forwarding instead)

---

## Step 1: Create one repo on GitHub

Create a single **private** repo called `hackathon-app`.

---

## Step 2: Push the source code

```bash
cd /home/user/Desktop/setup

# Customize your Docker Hub username in the workflow
# Edit .github/workflows/main-cd.yml line 11: DOCKER_ORG
# Edit k8s/manifests/client-deployment.yaml and server-deployment.yaml image fields
# Edit k8s/argocd/application.yaml line 9: repoURL

git init
git add .
git commit -m "init: Turborepo monorepo with Next.js client, Express server"
git branch -M main
git remote add origin https://github.com/rifatbond007/hackathon-app.git
git push -u origin main

# Create the dev branch
git checkout -b dev
git push -u origin dev
```

---

## Step 3: Create GitHub Actions secrets

Go to repo → **Settings → Secrets and variables → Actions**

Add these **repository secrets**:

| Secret | Value |
|---|---|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | A Docker Hub access token (hub.docker.com → Account Settings → Security → New Access Token) |
| `GH_PAT` | Classic GitHub PAT with `repo` (all) and `workflow` scopes (github.com → Settings → Developer settings → Personal access tokens) |

---

## Step 4: Set up the EC2 instance

### 4a. Launch an EC2 instance

- AWS Console → EC2 → Launch instance
- Name: `hackathon-cluster`
- AMI: **Ubuntu 22.04 LTS**
- Instance type: **t2.medium**
- Key pair: Select or create your SSH key
- Security group: allow **SSH (22)**, **HTTP (80)**, **HTTPS (443)** from 0.0.0.0/0
- Storage: **20 GB gp3**
- Launch

Note the **Public IPv4 address**.

### 4b. SSH in and bootstrap

```bash
# From your local machine
scp -i /path/to/your-key.pem -r k8s/ scripts/ ubuntu@<EC2_PUBLIC_IP>:~/

ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
chmod +x ~/scripts/bootstrap-k3s-argocd.sh
sudo ~/scripts/bootstrap-k3s-argocd.sh
```

The script installs k3s + Helm + ingress-nginx + ArgoCD, then applies the Project and Application CRDs.

### 4c. Get the ArgoCD admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 4d. Verify

```bash
kubectl get nodes
kubectl get pods -n argocd
```

---

## Step 5: Access the ArgoCD UI

```bash
# From your local machine — port-forward through SSH
ssh -i /path/to/your-key.pem -L 8080:localhost:8080 ubuntu@<EC2_PUBLIC_IP>

# Inside the SSH session:
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Open **https://localhost:8080** — login: `admin` / password from Step 4c.

The `hackathon` app should appear. It may show `OutOfSync` initially — that's fine.

---

## Step 6: (Optional) Sealed Secrets

### 6a. Install controller

```bash
# On EC2
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml
```

### 6b. Install kubeseal locally

```bash
# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/kubeseal-linux-amd64
sudo install -m 555 kubeseal-linux-amd64 /usr/local/bin/kubeseal
```

### 6c. Create and seal

```bash
cat > /tmp/app-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: hackathon
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:pass@your-db-host:5432/hackathon"
  API_KEY: "your-actual-api-key"
EOF

kubeseal --format yaml < /tmp/app-secrets.yaml > k8s/manifests/sealed-app-secrets.yaml
rm /tmp/app-secrets.yaml
git add k8s/manifests/sealed-app-secrets.yaml
git commit -m "add: sealed app secrets"
git push
```

---

## Step 7: Test the full pipeline

### 7a. Make a change and push to dev

```bash
git checkout dev
echo "// test change" >> apps/client/src/app/page.tsx
git add .
git commit -m "test: trigger pipeline"
git push origin dev
```

### 7b. Watch the CI run

Repo → **Actions** tab → **Dev CI — Test & Auto-Promote**:
1. Runs lint + test on affected apps (Turbo-aware)
2. On green: auto-merges `dev` into `main`

### 7c. Watch the CD run

After merge to `main`, **Main CD — Build, Push, Update Manifests** triggers:
1. Builds Docker images for client & server
2. Pushes to Docker Hub with `latest` + `sha-<commit>` tags
3. Commits updated image tags to `k8s/manifests/` on `main`

### 7d. Watch ArgoCD sync

ArgoCD detects the manifest change and auto-syncs. The UI shows sync events and pod rollout.

### 7e. Verify

```bash
# From EC2
kubectl get pods -n hackathon
kubectl get svc -n hackathon

# Via port-forward
kubectl port-forward -n hackathon svc/client-service 3000:3000
# In another terminal:
curl http://localhost:3000
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| ArgoCD shows OutOfSync | Check ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller` |
| Pods in CrashLoopBackOff | `kubectl logs -n hackathon <pod-name>` |
| Docker push fails | Verify DOCKER_USERNAME / DOCKER_PASSWORD secrets |
| Auto-promote fails | Check CI logs; GH_PAT needs `repo` + `workflow` scopes |
| main branch diverged | `git push origin dev --force` (only if you're sure no one else uses it) |
