# ArgoCD Installation on EC2 (k3s)

## 1. SSH into your EC2 instance

```bash
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
```

## 2. Run the bootstrap script

```bash
# Copy the scripts/ folder to your EC2 instance first
scp -i your-key.pem -r scripts/ ubuntu@<EC2_PUBLIC_IP>:~/
scp -i your-key.pem -r k8s/ ubuntu@<EC2_PUBLIC_IP>:~/

# SSH in and run
ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
chmod +x ~/scripts/bootstrap-k3s-argocd.sh
sudo ~/scripts/bootstrap-k3s-argocd.sh
```

## 3. Access the ArgoCD UI

Port-forward locally (from your machine, not EC2):

```bash
# First, from your local machine, SSH with port forwarding:
ssh -i your-key.pem -L 8080:localhost:8080 ubuntu@<EC2_PUBLIC_IP>
# Inside the SSH session:
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Then open https://localhost:8080 in your browser.

**Login credentials:**
- Username: `admin`
- Password: run `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## 4. Alternative: Use the ArgoCD CLI

```bash
# Install CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login via port-forward
argocd login localhost:8080 --username admin
```

## 5. Verify deployment

```bash
kubectl get pods -n hackathon
kubectl get svc -n hackathon
# If you have an Ingress controller:
kubectl get ingress -n hackathon
```

## 6. Access the application

Once the Ingress controller is configured, the app should be reachable at:

```
http://<EC2_PUBLIC_IP>       # Client (frontend)
http://<EC2_PUBLIC_IP>/api   # Server (backend)
```

> **Note**: If you don't have a domain/DNS set up, you can use port-forward instead:
> ```bash
> kubectl port-forward -n hackathon svc/client-service 3000:80
> kubectl port-forward -n hackathon svc/server-service 4000:4000
> ```
