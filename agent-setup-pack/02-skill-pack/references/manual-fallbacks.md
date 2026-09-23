# Manual fallbacks — the exact commands behind each guided step

The owner's Guide walks them through each of these as a message they paste to you.
**This file is what you use when a guided step fails**, when the owner asks you to do
something by hand, or when you must check something on the box without guessing.

Two rules before anything below:

1. **Only the named volumes persist.** Everything you install must live under
   `$HERMES_HOME` (the agent's home folder). Anything installed into the container's
   own filesystem — `/usr/local/bin`, apt packages, a venv outside the home — is
   destroyed the next time the app is updated from Hostinger. When in doubt, install
   under `$HERMES_HOME` and say where you put it.
2. **Never open a public port.** The app reaches the internet through Hostinger's HTTPS
   proxy; the studio reaches it through the Cloudflare tunnel. Both are covered below.

---

## 1. The studio app (normal path: Guide Chapter 3, Section 3.2)

By hand, in this order:

```bash
git clone https://github.com/aoio-design/ai-film-studio.git "$HERMES_HOME/studio"
cd "$HERMES_HOME/studio"
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
# start.sh ships with STUDIO_PORT=80; add exactly one line near the top:
#   export STUDIO_SECURE_COOKIE=1
# Do NOT set AOIO_AUTH_DIR — the app keeps its own account file in ./accounts.
bash start.sh                      # prints "Studio started"
.venv/bin/python accounts/aoio_auth.py add owner@example.com --name "Owner"   # creates the login
.venv/bin/python accounts/aoio_auth.py list                                   # verify
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:80/                 # expect 302
```

Running it again is safe only when it is down: a second `start.sh` prints
`Address already in use` in `studio.log` (which is `$HERMES_HOME/studio/studio.log`).
Restart by stopping the process and running `start.sh` again — never by editing files
inside a running instance.

If port 80 is unavailable, set `STUDIO_PORT=8080` in `start.sh` and change the tunnel
rule's `service:` to `http://localhost:8080` (they must match).

## 2. The Cloudflare tunnel (normal path: Guide Chapter 2; studio half in 3.3)

```bash
mkdir -p "$HERMES_HOME/bin" "$HERMES_HOME/.cloudflared" "$HERMES_HOME/logs"
curl -fsSL -o "$HERMES_HOME/bin/cloudflared" \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x "$HERMES_HOME/bin/cloudflared"
export TUNNEL_ORIGIN_CERT="$HERMES_HOME/.cloudflared/cert.pem"     # keeps the cert in the volume
"$HERMES_HOME/bin/cloudflared" tunnel login                       # print the URL, wait for the owner
"$HERMES_HOME/bin/cloudflared" tunnel create my-agent             # note the credentials .json path
"$HERMES_HOME/bin/cloudflared" tunnel route dns my-agent agent.MY-DOMAIN
"$HERMES_HOME/bin/cloudflared" tunnel route dns my-agent studio.MY-DOMAIN
```

`$HERMES_HOME/.cloudflared/config.yml`:

```yaml
tunnel: my-agent
credentials-file: <the path printed by tunnel create>
ingress:
  - hostname: agent.MY-DOMAIN
    service: http://hermes-webui:8787      # the web app container, by service name
  - hostname: studio.MY-DOMAIN
    service: http://localhost:80           # the studio, in this container
  - service: http_status:404
```

The app's address must point at the **service name** (`http://hermes-webui:8787`),
never at `localhost` — the app runs in a different container. Verify the name answers
before touching the config:

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://hermes-webui:8787/health   # expect 200
"$HERMES_HOME/bin/cloudflared" --config "$HERMES_HOME/.cloudflared/config.yml" tunnel ingress validate
"$HERMES_HOME/bin/cloudflared" --config "$HERMES_HOME/.cloudflared/config.yml" tunnel ingress rule https://studio.MY-DOMAIN
nohup "$HERMES_HOME/bin/cloudflared" --config "$HERMES_HOME/.cloudflared/config.yml" tunnel run my-agent \
  >> "$HERMES_HOME/logs/tunnel.log" 2>&1 &
```

The config is read only at startup — after any edit, restart the tunnel. `zone not found`
on a DNS route means the domain is not active in Cloudflare yet: report it, do not retry
in a loop.

## 3. The free local browser (normal path: Guide Chapter 1, Section 1.8)

```bash
npx -y agent-browser install --with-deps                       # ~200 MB, one time
echo "AGENT_BROWSER_EXECUTABLE_PATH=$(find ~/.agent-browser/browsers -name chrome -type f | head -1)" >> ~/.hermes/.env
grep AGENT_BROWSER ~/.hermes/.env
hermes config set browser.cloud_provider local --force
hermes config set browser.backend off --force
npx -y agent-browser open https://example.com && npx -y agent-browser close
```

Without the two `config set` lines the agent silently falls back to a **paid cloud
browser**. Re-check them if browsing ever starts costing money.

## 4. The fal.ai key (normal path: Guide Chapter 4, Section 4.4)

**fal.ai is not an LLM provider — it never appears on the app's Settings → Providers page.**
The key belongs in the agent's own environment file, which the owner edits through the
app's file browser (`$HERMES_HOME/.env`) — never in a chat, and never in the studio repo.
**Two routes, and the panel is the second one.** Preferred: hpanel → Docker Manager →
the project → **Manage** → `.yaml` editor → add `FAL_KEY` to the `hermes-agent`
service's `environment:` → **Update** (this is verified: the key lands in your process
environment on restart). Or the owner edits `$HERMES_HOME/.env` in the app's file
browser — but note the panel opens on the project **workspace folder** (usually empty)
and hides dot-folders, so the workspace must be pointed at the agent's home path with
**Show hidden files** on, or they will report that the file does not exist.
By hand (or to check the file):

```bash
grep -c FAL_KEY "$HERMES_HOME/.env" || echo "FAL_KEY=..." >> "$HERMES_HOME/.env"
```

## 5. The app itself (Web UI) — only if the catalog deploy is unusable

The normal path is one click in hpanel → Docker Manager → Compose → One click deploy →
**Hermes WebUI**, which brings the agent and this app together. The manual equivalent,
for a host where that is not an option:

```bash
git clone https://github.com/nesquena/hermes-webui.git "$HERMES_HOME/hermes-webui"
cd "$HERMES_HOME/hermes-webui"
cp .env.docker.example .env      # or .env.example for the native path
# set: HERMES_WEBUI_HOST=127.0.0.1, HERMES_WEBUI_PORT=8787,
#      HERMES_WEBUI_PASSWORD=<long random>, HERMES_HOME=the agent's home
./ctl.sh start && curl -s http://127.0.0.1:8787/health
```

Use this only as a fallback and say so plainly when you do: the standard install keeps
the app and the agent in one managed project where updates preserve the data volume, and
the hand-built path does not.

## 6. The installer script (no fallback needed)

Older builds of the Guide offered a command-line installer for Hermes itself. There is no
agent-side use for it — before that command runs, there is no agent to read this file. If
the owner cannot deploy from the catalog at all, that is a question for Hostinger support,
not a command to improvise.
