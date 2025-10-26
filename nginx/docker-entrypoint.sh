#!/bin/sh
set -eu


# Render the nginx.conf from template using envsubst then start nginx
TEMPLATE=/etc/nginx/nginx.conf.template
OUT=/etc/nginx/nginx.conf


if [ ! -f "$TEMPLATE" ]; then
echo "Missing $TEMPLATE"
exit 1
fi


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


: "${RELEASE_ID_BLUE:=}"
: "${RELEASE_ID_GREEN:=}"


# Render template
envsubst '\$PRIMARY_HOST \$PRIMARY_PORT \$BACKUP_HOST \$BACKUP_PORT \$RELEASE_ID_BLUE \$RELEASE_ID_GREEN' \
< "$TEMPLATE" > "$OUT"


# Start nginx in foreground
nginx -g 'daemon off;'
