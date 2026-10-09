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

## 1. The studio app (normal path: Chapter 1, Section 1.4 of *Setting up your AI Film Studio*)

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

## 2. Cloudflare tunnel (normal path: Section 1.5 of *Setting up your Cloud Computer and Hermes Agent* for the desktop's address, then Section 1.3 of *Setting up your AI Film Studio* for the studio's)

The owner manages the Cloudflare dashboard steps: create one named Tunnel and copy its run token; enable Cloudflare's **One-time PIN** identity provider; create the `cloud.MY-DOMAIN` Access application with an Allow policy for the owner's email (the studio's own application and route are added later, before the studio is installed); change the desktop password; then enter `CLOUDFLARE_TUNNEL_TOKEN` in the private Hostinger Docker Manager YAML while the Tunnel has no public routes. After the connector is healthy, add the published hostname routes (`cloud.MY-DOMAIN` → `http://localhost:3000`, desktop; `studio.MY-DOMAIN` → `http://localhost:80`, studio). Access must exist before either route is published. Use only a published buyer image and Compose template that include the token hook; if either is missing, update to the supported release before enabling the Tunnel. An empty/sample token means no tunnel.

**Do not run `cloudflared tunnel login`, `tunnel create`, or `tunnel route dns` for this buyer flow.** Do not use an unauthenticated/password-only Quick Tunnel, create a Cloudflare API token or custom OAuth client, or ask the owner to paste the tunnel token into chat. The owner creates and changes Access applications, policies, and routes in Cloudflare; you may verify them but do not modify them.

For local diagnosis only, check the supported image's tunnel process/log without printing environment values, then check the two origin services from inside the machine. If the token hook is absent, stop and report the image-build dependency; do not improvise another tunnel method.

## 3. The free local browser (normal path: the setup wizard's browser step, Section 2.4 of *Setting up your Cloud Computer and Hermes Agent*)

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

## 4. The fal.ai key (normal path: Chapter 2, Section 2.3 of *Setting up your AI Film Studio*)

**fal.ai is not an LLM provider — it never appears on the app's Settings → Providers page.**
The key ends up in the agent's own environment file as `FAL_KEY`, but **the owner's route is
the app's own key field: Settings → Tools & Keys → the Tools tab → the FAL API key row →
paste → save** (the value then shows masked). That is the route the Guide teaches
(Section 2.3 of *Setting up your AI Film Studio*). Never in a chat, and never in the studio repo.
The by-hand equivalents, if the key field is unavailable: the owner can reach
`$HERMES_HOME/.env` through the app's file panel (**Open folder as project…** →
`/config/.hermes`, then `.env`), or set it from a terminal with
`hermes config set FAL_KEY '<key>'`.
By hand (or to check the file):

```bash
grep -c FAL_KEY "$HERMES_HOME/.env" || echo "FAL_KEY=..." >> "$HERMES_HOME/.env"
```

## 5. The app itself — nothing to install

The app is not a separate product and there is nothing to add: it arrives with you. The
installer's `--include-desktop` flag builds it, and it starts with

```bash
hermes desktop
```

It shares the same config, keys, sessions, memory and skills as your terminal — one
agent, two windows onto it.

If it will not open, check these two, in this order:

- **The container's Electron rule.** Inside this machine Electron's own sandbox cannot
  start, so the app launches with `--no-sandbox`, set once:
  `hermes config set desktop.electron_flags '["--no-sandbox"]'`.
- **Run it with `--skip-build` from a terminal** (`hermes desktop --skip-build`): a
  failure is then printed in plain text instead of dying silently. Report what it says.

Do **not** install a web UI, dashboard or any second interface for the owner. The desktop
app is the supported surface; anything else is a second thing to keep alive and a second
way to be confused about which one has their keys.

## 6. The installer script (no fallback needed)

Older builds of the Guide offered a command-line installer for Hermes itself. There is no
agent-side use for it — before that command runs, there is no agent to read this file. If
the owner cannot deploy from the catalog at all, that is a question for Hostinger support,
not a command to improvise.
