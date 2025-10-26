# Blue/Green Nginx Upstream — Stage 2 (HNG)

## Files included
- docker-compose.yml
- .env.example
- nginx/nginx.conf.template
- nginx/docker-entrypoint.sh
- DECISION.md

## Quick start (local)
1. Copy example env and edit:
   ```bash
   cp .env.example .env
   # edit .env if running locally (CI sets these)
