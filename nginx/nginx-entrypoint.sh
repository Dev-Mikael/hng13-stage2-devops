#!/bin/sh
set -eu

TEMPLATE="/etc/nginx/templates/default.conf.template"
FINAL="/etc/nginx/conf.d/default.conf"

# Resolve ACTIVE_POOL default
ACTIVE_POOL="${ACTIVE_POOL:-blue}"

# Helper: produce the server lines for upstream using ACTIVE_POOL
render_upstream() {
  if [ "$ACTIVE_POOL" = "blue" ] || [ "$ACTIVE_POOL" = "BLUE" ]; then
    echo "server app_blue:${PORT:-8080} max_fails=1 fail_timeout=3s;"
    echo "server app_green:${PORT:-8080} backup;"
  else
    echo "server app_green:${PORT:-8080} max_fails=1 fail_timeout=3s;"
    echo "server app_blue:${PORT:-8080} backup;"
  fi
}

# Validate template exists
if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: Nginx template not found at $TEMPLATE"
  exit 1
fi

# Create a temporary copy of template and substitute the two special tokens
# We cannot rely purely on envsubst for server list generation, so we expand placeholders
# Replace placeholder ${ACTIVE_POOL}_PRIMARY and ..._BACKUP with generated server lines
UPSTREAM_BLOCK=$(render_upstream)

# cat template, replace the two placeholder tokens with the actual lines
# (Use sed to replace the multi-line placeholder block safely)
awk -v lines="$UPSTREAM_BLOCK" '
  { print }
' "$TEMPLATE" | sed "s/\${ACTIVE_POOL}_PRIMARY/${UPSTREAM_BLOCK%%$'\n'*}/; s/\${ACTIVE_POOL}_BACKUP//" > "$FINAL.tmp"

# The above sed is a simple attempt; safer to build from template tokens:
# We'll do a robust replacement: read template and replace the token block markers.
# Rebuild final accurately:
awk -v a="$UPSTREAM_BLOCK" '{
  if (index($0,"${ACTIVE_POOL}_PRIMARY")>0) {
    print a
  } else if (index($0,"${ACTIVE_POOL}_BACKUP")>0) {
    # skip - already printed in a
  } else {
    print $0
  }
}' "$TEMPLATE" > "$FINAL"

# Create a wrapper for /usr/sbin/nginx so that calling "nginx -s reload" regenerates config
if [ -x /usr/sbin/nginx ]; then
  if [ ! -f /usr/sbin/nginx.real ]; then
    mv /usr/sbin/nginx /usr/sbin/nginx.real
    cat > /usr/sbin/nginx <<'WRAPPER'
#!/bin/sh
# Wrapper for nginx binary inside container.
# When called with -s reload, regenerate config from template then delegate to real nginx.
if [ "$1" = "-s" ] && [ "$2" = "reload" ]; then
  # regenerate conf: execute entrypoint's template expansion logic (simple approach)
  # Here we call the same script to rebuild default.conf (re-run substitution)
  /usr/local/bin/nginx-entrypoint.sh --reload-only
  exec /usr/sbin/nginx.real "$@"
else
  exec /usr/sbin/nginx.real "$@"
fi
WRAPPER
    chmod +x /usr/sbin/nginx
  fi
fi

# Support an optional flag to only regenerate config (used by wrapper)
if [ "${1:-}" = "--reload-only" ]; then
  # regenerate final config with current env
  ACTIVE_POOL="${ACTIVE_POOL:-blue}"
  # reuse the generation logic above: write final again
  render_upstream() {
    if [ "$ACTIVE_POOL" = "blue" ] || [ "$ACTIVE_POOL" = "BLUE" ]; then
      echo "server app_blue:${PORT:-8080} max_fails=1 fail_timeout=3s;"
      echo "server app_green:${PORT:-8080} backup;"
    else
      echo "server app_green:${PORT:-8080} max_fails=1 fail_timeout=3s;"
      echo "server app_blue:${PORT:-8080} backup;"
    fi
  }
  UPSTREAM_BLOCK=$(render_upstream)
  awk -v a="$UPSTREAM_BLOCK" '{
    if (index($0,"${ACTIVE_POOL}_PRIMARY")>0) {
      print a
    } else if (index($0,"${ACTIVE_POOL}_BACKUP")>0) {
      # skip
    } else {
      print $0
    }
  }' "$TEMPLATE" > "$FINAL"
  exit 0
fi

# Start nginx in foreground
exec nginx -g "daemon off;"
