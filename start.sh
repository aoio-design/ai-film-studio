#!/usr/bin/env bash
# Start the studio.
#
# Logins are email + password. Create your account first (one time):
#   python3 accounts/aoio_auth.py add you@example.com --name "Your Name"
# It prints a generated password — save it. Change it any time with:
#   python3 accounts/aoio_auth.py passwd you@example.com
# List accounts:
#   python3 accounts/aoio_auth.py list
#
# FIRST RUN, before any account exists: the app prints a RANDOM one-time setup
# code to studio.log — use it to open the page once, then create your account.
# No password is hardcoded here or in the source, so this public repo gives an
# attacker nothing: `grep setup- studio.log` on YOUR server is the only way in.
cd "$(dirname "$0")"

# Stable session key so restarting the studio does not sign you out.
if [ ! -f .secret ]; then
  head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > .secret
  chmod 600 .secret
fi
export STUDIO_SECRET="$(cat .secret)"

# Set this to 1 once the studio is reached only over HTTPS (Cloudflare tunnel):
# it marks the session cookie Secure. Leave unset while testing on 127.0.0.1.
# export STUDIO_SECURE_COOKIE=1

export STUDIO_PORT=80
# Use port 8080 instead if port 80 is unavailable on your server.

# Who may use the studio without its own login (see the "Trust" section in app.py):
# exactly one case - a request that never left this machine (no CF-Connecting-IP
# header), i.e. a browser on the server itself. Anything arriving through the
# tunnel always meets the studio's own login below, so with a Cloudflare Access
# gate in front of the address your devices pass TWO doors (the gate, then this
# login), and with no gate the login is still the thing protecting the studio.
# Set AOIO_TRUST_LOCAL=0 to require the login on this machine too.
export AOIO_TRUST_LOCAL=1
.venv/bin/python app.py > studio.log 2>&1 &
echo "Studio started"
