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

## 2. Cloudflare tunnel (normal path: Guide Chapter 4, Section 4.1)

The owner manages the Cloudflare dashboard steps: create one named Tunnel and copy its run token; enable Cloudflare's **One-time PIN** identity provider; create the `cloud.MY-DOMAIN` and `studio.MY-DOMAIN` Access applications with Allow policies for the owner's email; change the desktop password; then enter `CLOUDFLARE_TUNNEL_TOKEN` in the private Hostinger Docker Manager YAML while the Tunnel has no public routes. After the connector is healthy, add the published hostname routes (`cloud.MY-DOMAIN` → `http://localhost:3000`, desktop; `studio.MY-DOMAIN` → `http://localhost:80`, studio). Access must exist before either route is published. The token hook depends on an image build that implements it; an empty/sample token means no tunnel.

**Do not run `cloudflared tunnel login`, `tunnel create`, or `tunnel route dns` for this buyer flow.** Do not use an unauthenticated/password-only Quick Tunnel, create a Cloudflare API token or custom OAuth client, or ask the owner to paste the tunnel token into chat. The owner creates and changes Access applications, policies, and routes in Cloudflare; you may verify them but do not modify them.

For local diagnosis only, check the supported image's tunnel process/log without printing environment values, then check the two origin services from inside the machine. If the token hook is absent, stop and report the image-build dependency; do not improvise another tunnel method.

## 3. The free local browser (normal path: Guide Chapter 3, Section 3.2)

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

## 4. The fal.ai key (normal path: Guide Chapter 6, Section 6.5)

**fal.ai is not an LLM provider — it never appears on the app's Settings → Providers page.**
The key belongs in the agent's own environment file, which the owner edits through the
app's file browser (`$HERMES_HOME/.env`) — never in a chat, and never in the studio repo.
**Route (the only one that works): hpanel → Docker Manager → the project → Manage →
`.yaml` editor → add `FAL_KEY` to the `hermes-agent` service's `environment:` →
Update.** Verified: the key then answers `printenv FAL_KEY` in your container.
**There is no in-app route.** The app's Providers page is for chat models only, and the
app's file browser cannot reach your settings file: the two of you run in separate
containers with different paths to the same folder (you see `/home/hermes/.hermes`; the
app sees `/home/hermeswebui/.hermes`). Never quote your own `$HERMES_HOME` path to the
owner as somewhere they can open.
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
