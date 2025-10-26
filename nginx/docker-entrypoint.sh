#!/bin/sh
set -eu

TEMPLATE=/etc/nginx/templates/nginx.conf.template
OUT=/etc/nginx/nginx.conf

if [ ! -f "$TEMPLATE" ]; then
  echo "template $TEMPLATE not found"
  exit 1
fi

# default fallbacks
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

# Render template and start nginx
envsubst '\$PRIMARY_HOST \$PRIMARY_PORT \$BACKUP_HOST \$BACKUP_PORT' < "$TEMPLATE" > "$OUT"

# Run nginx in foreground so docker can manage it and nginx -s reload works
nginx -g 'daemon off;'
