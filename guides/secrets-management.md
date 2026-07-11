# Secrets Management Guide (Hackathon Edition)

We need three layers of secrets. Here is the recommended approach for each.

---

## Layer 1: GitHub Actions Secrets (for CI/CD)

Used by GitHub Actions to authenticate to Docker Hub, GitHub (PAT), etc.

### Setup

1. Go to your repo → **Settings → Secrets and variables → Actions**
2. Add these repository secrets:

| Secret Name | Value |
|---|---|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token (create at hub.docker.com → Account Settings → Security) |
| `GH_PAT` | GitHub Personal Access Token with `repo` and `workflow` scopes |

These are encrypted at rest and injected as env vars at runtime.

---

## Layer 2: App-Level Secrets (DB credentials, API keys)

These need to reach the running pod. **DO NOT commit plaintext to Git.**

### Recommended: Bitnami Sealed Secrets (fastest for hackathons)

**Step 1:** Install the Sealed Secrets controller on the cluster:

```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml
```

**Step 2:** Download the `kubeseal` CLI:

```bash
# On your local machine
wget https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/kubeseal-linux-amd64
sudo install -m 555 kubeseal-linux-amd64 /usr/local/bin/kubeseal
```

**Step 3:** Create a `SealedSecret` from your plain secret (safe to commit):

```bash
# Create a temporary Secret locally (NOT committed)
cat > app-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: hackathon
type: Opaque
stringData:
  DATABASE_URL: "postgresql://user:pass@db-host:5432/hackathon"
  API_KEY: "sk-your-api-key-here"
EOF

# Seal it (encrypts using the cluster's public key)
kubeseal --format yaml < app-secrets.yaml > k8s/manifests/sealed-app-secrets.yaml

# Clean up the plaintext file
rm app-secrets.yaml
```

**Step 4:** Commit `sealed-app-secrets.yaml` to the GitOps repo. Only the cluster can decrypt it.

**Step 5:** Reference in your Deployment via `secretKeyRef` (already done in `server-deployment.yaml`).

### Alternative: SOPS + Age (more portable)

```bash
# Install age and sops
# Generate an age key
age-keygen -o age.key

# Encrypt the secrets file
sops --encrypt --age $(cat age.key | grep public) app-secrets.yaml > k8s/manifests/encrypted-secrets.yaml
```

Requires CI to have the age key (store as `SOPS_AGE_KEY` in GitHub Secrets).

---

## Layer 3: Infrastructure Access (kubeconfig for ArgoCD)

ArgoCD runs *inside* the cluster so it uses the in-cluster ServiceAccount by default — no extra secrets needed.

If you need `kubectl` from CI:

1. Copy the kubeconfig from your EC2 instance:
   ```bash
   scp -i your-key.pem ubuntu@<EC2_IP>:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml
   ```
2. Store as a GitHub Actions secret called `KUBECONFIG_CONTENT`
3. In CI, write it:
   ```bash
   mkdir -p ~/.kube
   echo "${{ secrets.KUBECONFIG_CONTENT }}" > ~/.kube/config
   ```

---

## Quick Reference: GitHub Secrets to Create

| Secret | Purpose |
|---|---|
| `DOCKER_USERNAME` | Docker Hub login for pushing images |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `GH_PAT` | GitHub token (for auto-merge dev→main & pushing to GitOps repo) |
| `KUBECONFIG_CONTENT` | (Optional) kubeconfig for CI kubectl access |

**Minimal setup**: `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `GH_PAT`.

The ArgoCD Application handles syncing to K8s — no kubeconfig needed in CI for CD.
