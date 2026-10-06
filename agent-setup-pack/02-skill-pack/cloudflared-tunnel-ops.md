---
name: cloudflared-tunnel-ops
description: "Operate and troubleshoot cloudflared named tunnels routing subdomains to local services (Hermes WebUI, studio, dashboards). Covers 502 vs origin-down diagnosis, tunnel lifecycle, config validation, and health-check cron patterns."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [cloudflared, cloudflare-tunnel, webui, devops, 502, health-check, cron]
    related_skills: [hermes-agent]
---

# Cloudflared Tunnel Operations

> **Buyer image boundary:** the owner creates a named Cloudflare Tunnel; enables Cloudflare's One-time PIN identity provider; creates Access apps/policies; changes the desktop password; then enters the per-tunnel `CLOUDFLARE_TUNNEL_TOKEN` in the private Hostinger Docker Manager YAML while the tunnel has no public hostname routes. After the connector is healthy, the owner adds the two routes; Access must exist before either route is published. The token hook depends on an image build; an empty/sample token means no tunnel. Never print or request the token, use a Quick Tunnel, create API-token/custom-OAuth credentials, or change Cloudflare routes or Access policies from this skill. See `references/manual-fallbacks.md` §2.
>
> On the buyer image, the token hook is the tunnel lifecycle. Do not run `cloudflared tunnel login/create/run` or add a second daemon to "repair" it. Check the existing process/log without reading secrets; if the image-managed process cannot recover, ask the owner to apply/restart the project in Hostinger after confirming the image build supports the hook. The CLI lifecycle below is for non-buyer named-tunnel deployments only.

## When to Use

- A subdomain (e.g. `cloud.MY-DOMAIN`, `studio.MY-DOMAIN`) is down / 502 / unreachable
- Restarting the Hermes WebUI or other tunneled local services
- Validating or editing the tunnel ingress config
- Investigating why a health-check cron stopped firing
- Any "site stopped working after update/restart" report for tunneled services

## Diagnosis: 502 vs Connection Refused

**502 Bad Gateway from Cloudflare = the tunnel is ALIVE but the origin (local service) is DOWN or not listening.** DNS and Cloudflare edge are fine. Do NOT restart the tunnel first — check the local service first.

Diagnostic order:
1. `curl -sS -m 5 -o /dev/null -w "local:PORT -> HTTP %{http_code}\n" http://127.0.0.1:PORT/health` — if this fails to connect, the origin is down. That's the root cause.
2. `ps aux | grep cloudflared` — tunnel process alive? (It will still be running when you get 502; the tunnel doesn't die when the origin does.)
3. Check the service log tail for the crash: `tail -30 $HERMES_HOME/logs/webui.log` — look for `[crash-visibility] process exit pid=NNNN` (Hermes WebUI logs this when it dies).
4. If origin is up but tunnel is down → restart tunnel (see Lifecycle).

**Connection refused / DNS failure on a buyer hostname** = tunnel or dashboard route problem. Check the token-backed process and local service; ask the owner to inspect the Cloudflare published route and Access application in the dashboard. Do not run `cloudflared tunnel route dns` or change the route for the buyer.

**Cloudflare error 1033 / 530 on EVERY subdomain = the tunnel process is DOWN** (not the origins). 530 = "origin unreachable" at the edge; when ALL hostnames through the same named tunnel fail at once (store, studio, agent, guide…), the cloudflared process died (this deployment: watchdog race or a background session ending silently — the process can vanish while the watchdog believes it healthy). Diagnosis: `pgrep -af "[c]loudflared"` returns nothing → restart the tunnel (see Lifecycle). A single 502 on one subdomain while the others work = origin down (start the service); ALL subdomains 530/1033 = restart the tunnel. After restarting, verify each subdomain: 302/200 = fine, 502 on one = that origin is down, 530 again = tunnel still not connected.

## Tunnel Lifecycle

### Config
- Tunnel config: `$HERMES_HOME/.cloudflared/config.yml` (ingress rules: hostname → local service, fallback 404)
- Validate: `cloudflared tunnel ingress validate` (or parse with python yaml)
- After editing config, restart the tunnel process (it reads config at startup)

### Start tunnel (background, detached)

cloudflared is a single static binary — never rely on a copy in `/tmp`. **Container
recreates wipe `/tmp`** (this is exactly how the tunnel "mysteriously" died after a
Hermes update: binary lived at `/tmp/cloudflared`, the recreate erased it, and
nothing reinstalled it). Keep the real binary under the home folder
(`$HERMES_HOME/bin/cloudflared`, the layout `references/manual-fallbacks.md` installs)
and symlink it so legacy scripts referencing `/tmp/cloudflared` keep working:

```bash
CF=$HERMES_HOME/bin/cloudflared
if [ ! -x "$CF" ]; then
  mkdir -p "$(dirname "$CF")"
  curl -sL -o "$CF" https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  chmod +x "$CF"
fi
ln -sf "$CF" /tmp/cloudflared
"$CF" tunnel run <TUNNEL_NAME> >> $HERMES_HOME/logs/cloudflared.log 2>&1 </dev/null &
```
GitHub release downloads return 200 from this VPS (redirect to objects.githubusercontent.com works even though api.github.com is blocked).

### Restart Hermes WebUI (port 8787)
```
cd $HERMES_HOME/hermes-webui
HERMES_WEBUI_PYTHON=/opt/hermes/.venv/bin/python3 nohup python3 bootstrap.py \
  --skip-agent-install --no-browser --foreground 8787 >> $HERMES_HOME/logs/webui.log 2>&1 &
```
Wait ~8-10s, then verify: local `/health` returns 200, subdomain returns 302 (login redirect = working).

### Verify end-to-end
```
curl -sS -m 5 -o /dev/null -w "local:8787 -> %{http_code}\n" http://127.0.0.1:8787/health
curl -sS -m 10 -o /dev/null -w "subdomain -> %{http_code}\n" https://cloud.MY-DOMAIN
```

## Health-Check Cron Pattern

When a service is supervised by a cron job ("health check every 5m"), the cron can silently stop firing while the scheduler itself stays alive. Diagnosis:
- `cronjob list` — compare `last_run_at` against the schedule. A gap of hours/days with `enabled: true` means the job stopped ticking.
- Other jobs firing normally (recent `last_run_at`) proves the scheduler is fine — the specific job is the problem.
- Fix: run the job manually once via `cronjob action=run job_id=<id>` — this re-arms it and confirms the job logic works.

Never rely solely on a cron health check for critical services — a crashed service + silent cron gap = prolonged outage. Consider a systemd-style supervisor for truly critical services.

**Durable watchdog = no_agent script, not an LLM-prompt cron.** An LLM-based
health-check cron (prompt + terminal toolset) is fragile for daemons:
- Its terminal tool REJECTS shell-level backgrounding — `nohup ... &`, `disown`,
  `setsid` fail with "Foreground command uses shell-level background wrappers
  (nohup/disown/setsid). Use terminal(background=true)". The agent can sometimes
  sneak past via a `bash -lic set +m; ...` wrapper, but that's luck, not design —
  and it can't survive the next restart.
- Its instructions hardcode paths that go stale after an update (the `/tmp/cloudflared`
  failure above).

Convert the job to a plain script watchdog instead: `no_agent=true` + `script=...`.
Scripts run under bash directly — no tool restrictions — and the watchdog pattern
(empty stdout = silent; print only when something was restarted) keeps it quiet:
```
cronjob(action='update', job_id=..., no_agent=true, script='webui-tunnel-health.sh', schedule='every 5m', deliver='local')
```
The script must: probe the service (/health), check the binary exists (re-download
if missing), re-create the `/tmp` symlink, `pgrep` the daemon and restart only when
absent. Known-good example: `$HERMES_HOME/studio/scripts/keep-alive.sh` — shipped with the studio and wired to the machine's own schedule in the Guide's Chapter 2 (it probes the desktop in-machine, restarts the studio via `start.sh`, and restarts the tunnel from `.cloudflared/config.yml`).

**Cron script-path quirk:** the cronjob tool validates script paths relative to
`~/.hermes/scripts/` (rejects absolute paths), but the scheduler RUNNER resolves bare
filenames under `$HERMES_HOME/scripts/` (observed: "Script not found:
$HERMES_HOME/scripts/guide-health.sh" while the file sat in `~/.hermes/scripts/` —
the same folder seen under two names).
Keep every watchdog script in BOTH locations — copy after every edit.

**A firing check can also FALSE-NEGATIVE.** Before restarting anything on a failed check, verify the check's port matches what the service actually serves on: read the ingress from `$HERMES_HOME/.cloudflared/config.yml` (`hostname → http://localhost:<PORT>`) and curl THAT port. A cron checking a stale port (e.g. 5001 after the service moved to 80) false-negatives every run; if the check's failure handler runs a start script, each false negative spawns another duplicate daemon/tunnel. Connection refused on the checked port + the service responding on the ingress port (or the public subdomain returning 302) = healthy, no action needed — report the check as stale rather than restarting.

## Pitfalls

1. **Restarting the tunnel when the origin is down** — wastes time; 502 means origin, not tunnel. Check local port first.
2. **Foreground `&` backgrounding in terminal tool** — the terminal tool rejects `&` in foreground commands. Use `terminal(background=true)` for long-lived processes, then verify in a follow-up call.
3. **Forgetting the service is session-bound** — `nohup ... &` processes tied to a TUI session die when the session ends. Persist via entrypoint/systemd or a dedicated watchdog.
4. **Editing tunnel config without validating** — a YAML typo breaks ALL ingress rules. Validate before restarting.
5. **Duplicate instances of the same named tunnel** — each `cloudflared tunnel run <name>` spawns a competing instance; multiple racing instances cause edge routing flapping and log noise. They accumulate when a start script (e.g. `start.sh`, which launches the tunnel) gets invoked repeatedly by a health-check cron. Identify with `ps -o pid,lstart,cmd -C cloudflared`: keep the OLDEST instance (the known-good one that has been serving), kill only the recent duplicates by PID (`kill <pid>`), then re-verify the subdomain still returns 302. Avoid blanket `pkill -x cloudflared` unless a brief tunnel interruption is acceptable — it forces a full reconnect. NOTE: check for existing instances right before starting one — a "no tunnel running" verdict can be stale by seconds if a health-check cron is mid-recovery.
6. **Any daemon binary in `/tmp` dies on container/image recreate** — cloudflared, etc. Persist binaries under `$HERMES_HOME` and make every start script/watchdog re-download when missing (see Start tunnel).
7. **`pkill -f "cloudflared tunnel run X"` kills your own shell** — `pkill -f` pattern-matches the full command line, which includes the bash wrapper running your command (observed: exit -15 and "nothing happened"). List with `pgrep -af "[c]loudflared"` (the `[c]` trick stops self-match) and kill by PID instead.
8. **New subdomain returns 502 until the local server is up** — in a non-buyer CLI-managed tunnel, 502 may follow a published route while the origin is still down; check the origin before changing tunnel settings. For the buyer image, do not run `tunnel route dns`: the owner manages published routes in Cloudflare's dashboard.
9. **Host-Docker origin services need the HOST IP, not `localhost`, in ingress** — when cloudflared runs INSIDE a container (this deployment) and the target service is a separate docker-compose project on the HOST with a published port (e.g. a Hostinger Docker-catalog deploy, which picks a random 3276x–3279x host port), `service: http://localhost:<port>` yields permanent 502: from the tunnel's perspective `localhost` is the cloudflared container, and the service lives on the host. The docker bridge gateway (`172.17.0.1`) is often ALSO unreachable from inside the container — use the host's public IP in the ingress line (`service: http://<host-ip>:32779`). Verify reachability from inside the container first: `curl -s -o /dev/null -w "%{http_code}" http://<host-ip>:<port>/` — the ONLY address that answers is the one to put in the config. Note the random host port may change if the catalog project is recreated; re-check before assuming the ingress is stale.
10. **Infinite 302 redirect loop on every path = app force-redirects to https while the origin sees http** — cloudflared terminates TLS at the edge and forwards plain HTTP to the origin. Any app configured with an https "site URL" that sets a `force_https`-style flag will redirect every request to https → tunnel → http → loop forever (`location:` header equals the requested URL on every hop). Seen with app installers that write a `force_https` flag into their config file when the site URL starts with https:// and then force-redirect every request. Fix inside the app (container console): switch that flag off in its config and reload. Public visitors still get https; only the origin sees http. Diagnose with a redirect-chain probe (`for i in 1 2 3; do curl -s -o /dev/null -D - https://host/ | grep -iE '^(HTTP|location)'; done`) — identical self-location = this loop.
