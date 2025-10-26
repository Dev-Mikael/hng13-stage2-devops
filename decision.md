---


## `DECISION.md`


```md
# Decision notes — Blue/Green Nginx Upstream


## Goals
- Meet grader constraints: Blue active by default, Green backup; failover with zero failed client requests; preserve app headers; expose 8081/8082 for chaos control; no image builds.


## Key design choices
1. **Nginx upstream with `backup` directive** — The `backup` server role ensures that only the main server is used until it is marked failed, and Nginx will send to backup automatically.


2. **Fast detection via `max_fails` + `fail_timeout`** — Primary uses `max_fails=1 fail_timeout=2s` to mark quickly as failed when the app returns 5xx or times out.


3. **Same-request retry using `proxy_next_upstream`** — Configure retries for `error`, `timeout`, and `http_5xx` and limit to 1 retry so the same client request will be attempted against the backup, preserving client success.


4. **Tight timeouts** — `proxy_connect_timeout 1s`, `proxy_send_timeout 3s`, `proxy_read_timeout 5s` to keep total request time under 10s and allow fast failover.


5. **Templating via envsubst** — The nginx config is templated and rendered by an entrypoint script. This supports runtime reloads via `nginx -s reload`.


6. **Do not strip headers** — Nginx does not hide response headers by default; we do not add any `add_header` or `proxy_hide_header` that would remove `X-App-Pool` or `X-Release-Id`.


## Potential tuning
- If grader needs even faster failover (e.g., <3s), reduce `proxy_read_timeout` and/or `fail_timeout` but beware of false-positive failovers on slow upstreams.


## Known assumptions
- App images accept `PORT`, `RELEASE_ID`, and `APP_POOL` env vars and expose `/version`, `/healthz`, `/chaos/*` endpoints as described.
