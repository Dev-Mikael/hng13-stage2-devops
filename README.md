# hng13-stage2-devops
Repository for HNG13 stage2 devops task
# Blue/Green Nginx Upstream — Docker Compose


This repository implements a Blue/Green Nodejs service behind Nginx with automatic failover and manual toggle. It's designed for the Stage 2 DevOps grader.


## Files
- `docker-compose.yml` — orchestrates `nginx`, `app_blue`, `app_green`.
- `.env.example` — example environment variables.
- `nginx/nginx.conf.template` — templated nginx config (rendered by entrypoint).
- `nginx/docker-entrypoint.sh` — entrypoint that envsubst the template and starts nginx.
- `DECISION.md` — explanation of design choices.


## Requirements
- Docker Engine & Docker Compose


## Usage
1. Copy `.env.example` to `.env` and set the variables (CI/grader will do this automatically). Example:
```bash
cp .env.example .env
# Edit .env if running locally
docker compose up -d
