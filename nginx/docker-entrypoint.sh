#!/bin/sh
set -eu

# This script builds the real nginx.conf from template using ACTIVE_POOL.
# It then starts nginx in foreground so `nginx -s reload` works.

TEMPLATE=/etc/nginx/nginx.conf.template
OUT=/etc/nginx/nginx.conf

# Basic validation
if [ ! -f "$TEMPLATE" ]; then
  echo "Missing $TEMPLATE"
  exit 1
fi

# Determine primary & backup based on ACTIVE_POOL
# Expect env: ACTIVE_POOL, BLUE_HOST, GREEN_HOST, BLUE_PORT, GREEN_PORT
: "${ACTIVE_POOL:=blue}"
: "${BLUE_HOST:=app_blue}"
: "${GREEN_HOST:=app_green}"
: "${BLUE_PORT:=3000}"
: "${GREEN_PORT:=3000}"

if [ "$ACTIVE_POOL" = "blue" ]; then
  export PRIMARY_HOST="$BLUE_HOST"
  export PRIMARY_PORT="$BLUE_PORT"
  export BACKUP_HOST="$GREEN_HOST"
  export BACKUP_PORT="$GREEN_PORT"
else
  export PRIMARY_HOST="$GREEN_HOST"
  export PRIMARY_PORT="$GREEN_PORT"
  export BACKUP_HOST="$BLUE_HOST"
  export BACKUP_PORT="$BLUE_PORT"
fi

# Also expose RELEASE_IDs for access in template if needed
: "${RELEASE_ID_BLUE:=}"
: "${RELEASE_ID_GREEN:=}"

# Render template (envsubst expects ${VAR} style)
envsubst '\$PRIMARY_HOST \$PRIMARY_PORT \$BACKUP_HOST \$BACKUP_PORT \$RELEASE_ID_BLUE \$RELEASE_ID_GREEN' \
  < "$TEMPLATE" > "$OUT"

# Start nginx in foreground so docker can control it
nginx -g 'daemon off;'
