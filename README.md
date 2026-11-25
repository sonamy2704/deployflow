# DeployFlow – Automated CI/CD Platform

[![CI/CD](https://github.com/YOUR_USERNAME/deployflow/actions/workflows/deploy.yml/badge.svg)](https://github.com/YOUR_USERNAME/deployflow/actions)

Every push to `main` is tested, built into a Docker image, pushed to GHCR, and deployed to an AWS EC2 server behind Nginx. A failed health check triggers an automatic rollback.

**Stack:** GitHub Actions · Docker · GHCR · AWS EC2 · Nginx · Flask

## Architecture

```
git push → GitHub Actions → pytest → docker build → push to GHCR
                                                        │
                                          SSH + deploy.sh on EC2
                                                        │
                    Nginx :80 → container :5000 → /health OK? ── yes → record SUCCESS
                                                        └─ no → roll back to previous image
```

## Endpoints

| Path | Purpose |
|---|---|
| `/` | Dashboard with the running version and recent deployments |
| `/health` | Health check used by the deploy script |
| `/version` | Git SHA of the running build |
| `/status` | JSON deployment history |

## Setup

### 1. Run locally
```bash
pip install -r requirements.txt
pytest
python app.py          # http://localhost:5000
docker build -t deployflow . && docker run -p 5000:5000 deployflow
```

### 2. Prepare EC2 (Ubuntu)
1. Launch an instance and allow ports 22 and 80 in the security group. Attach an Elastic IP.
2. Copy `scripts/setup-ec2.sh` and `nginx/deployflow.conf` to the server (keep the `scripts/` and `nginx/` folder layout) and run `bash scripts/setup-ec2.sh`.
3. Generate a dedicated deploy key: `ssh-keygen -t ed25519 -f deployflow_key`. Add the `.pub` to `~/.ssh/authorized_keys` on EC2.

### 3. GitHub secrets
Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `EC2_HOST` | Elastic IP or hostname |
| `EC2_SSH_KEY` | Contents of the private `deployflow_key` |
| `GHCR_TOKEN` | Personal access token with `read:packages` |

Also make the GHCR package accessible to the token owner (Package settings → Manage access).

### 4. Deploy
`git push origin main` and watch the Actions tab. Visit `http://<EC2_HOST>/`.

## Rollback

- **Automatic:** `deploy.sh` health-checks the new container 10 times (3s apart) and restores the previous image if it never becomes healthy.
- **Manual:** `ssh ubuntu@<host> ./rollback.sh`

## Demo checklist
1. Normal change → green pipeline, new SHA at `/version`.
2. Break a test → pipeline stops before deploy.
3. Break `/health` → deploy fails, rollback logged on the dashboard.
