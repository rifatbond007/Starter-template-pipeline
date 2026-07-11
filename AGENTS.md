# AGENTS.md — Hackathon GitOps Monorepo

## Quick Reference

| Item | Value |
|---|---|
| Package manager | pnpm 9.15.0 (corepack-managed) |
| Build tool | Turborepo |
| Node (CI) | 22 |
| Node (Docker) | 20-alpine |
| Test framework | vitest |
| Client framework | Next.js 14 (`output: 'standalone'`) |
| Server framework | Express 4 |

## Repo Structure

- `apps/client` — Next.js 14 app (`@hackathon/client`). Outputs `.next/standalone`.
- `apps/server` — Express app (`@hackathon/server`). Outputs `dist/`.
- `packages/shared` — shared types/helpers (`@hackathon/shared`). Outputs `dist/`.
- `k8s/manifests/` — Kubernetes resources (consumed by ArgoCD).
- `k8s/argocd/` — ArgoCD Application & Project CRDs.
- `scripts/agrocd.sh` — one-shot EC2 bootstrap (k3s + Helm + ingress-nginx + ArgoCD).

## Commands

| Command | Meaning |
|---|---|
| `pnpm install --frozen-lockfile` | CI install; use this instead of plain `pnpm install` |
| `pnpm turbo build` | monorepo build (Turbo cache) |
| `pnpm turbo test` | run all tests (vitest) |
| `pnpm turbo lint` | lint all packages (currently no-op: `echo ok`) |
| `pnpm turbo build --filter=@hackathon/client` | build single package |

## Development

| Command | What it runs |
|---|---|
| `pnpm dev` | all packages in parallel |
| `pnpm dev --filter=@hackathon/client` | `next dev` (port 3000) |
| `pnpm dev --filter=@hackathon/server` | `tsx watch src/index.ts` (port 8000) |

## CI/CD Pipeline

1. Push to `dev` → `dev-ci.yml`: `turbo lint` → `turbo test` → auto-merge `dev` into `main` (via `GH_PAT`).
2. Push to `main` → `main-cd.yml`: build & push Docker images → yq-update image tags in `k8s/manifests/*-deployment.yaml` → commit back to `main` with `[skip ci]`.
3. ArgoCD watches `k8s/manifests/` on `main` and auto-syncs (prune+selfHeal).

**Key quirk**: dev branch is the main development branch; `main` is the deploy branch. Don't push directly to `main` — always go through `dev`.

## Docker

- Client Dockerfile uses Next.js `output: 'standalone'` — server entry is `apps/client/server.js` (not `node_modules/.next/...`).
- Server Dockerfile builds with `tsc`, runtime entry is `dist/index.js`.
- Images pushed to `docker.io/rifatbroh/hackathon-{client,server}`.
- `pnpm@9.15.0` required in Dockerfiles (corepack-managed).

## Secrets & Environment

- `.env` at root **contains plaintext secrets** — do NOT commit it (it's in `.gitignore`).
- GitHub secrets required: `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `GH_PAT`.
- K8s secrets managed via Bitnami Sealed Secrets; unsealed secret manifests **never** committed.

## Testing

- All packages use `vitest run`. There's no watch mode in CI.
- Tests are currently placeholder tests (not real assertions).
- Run single package: `pnpm turbo test --filter=@hackathon/server`

## Before You Work

1. Never modify `.env` — it has actual credentials.
2. The `DOCKER_ORG` in `main-cd.yml` is `rifatbroh` (not same as GitHub owner `rifatbond007`).
3. The ArgoCD Application source is `k8s/manifests/` on `main`.
4. Lint is currently a no-op (`echo ok`) — don't rely on it for code quality checks.
5. TypeScript has no separate `typecheck` command — `tsc` only runs as part of `build`.
