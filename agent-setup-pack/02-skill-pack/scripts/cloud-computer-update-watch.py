#!/usr/bin/env python3
"""cloud-computer-update-watch — tell you when a newer version of your cloud
computer has been published.

How it works: it asks the public image registry for the digest of the current
`latest` image and compares it with the digest it saw last time. A new digest
means a new version was published. On the first run it records a baseline and
says nothing.

Silent by default. It sends one Telegram message per published version — never a
reminder, never a daily digest. If Telegram is not configured it stays silent and
logs to ~/.cloud-computer-update-watch.log instead.

Install (once): see the Guide, Section 2.5 — Updating your cloud computer.
"""

import json
import os
import sys
import time
import urllib.parse
import urllib.request

REGISTRY = "ghcr.io"
REPO = "aoio-design/aoiostudios-cloud-computer"
TAG = "latest"

HOME = os.path.expanduser("~") or "/config"
STATE = os.path.join(HOME, ".cloud-computer-update-watch.json")
LOG = os.path.join(HOME, ".cloud-computer-update-watch.log")
ENV_FILE = os.path.join(HOME, ".hermes", ".env")

MANIFEST_ACCEPT = ", ".join((
    "application/vnd.oci.image.index.v1+json",
    "application/vnd.docker.distribution.manifest.list.v2+json",
    "application/vnd.oci.image.manifest.v1+json",
    "application/vnd.docker.distribution.manifest.v2+json",
))

MESSAGE = """A new version of your cloud computer is ready.

It takes about two minutes, and nothing in your files, your agent or your studio changes.

Steps: your Guide, Section 2.5 — Updating your cloud computer.

Do it when you are not in the middle of something: the desktop closes briefly while the new version starts."""


def log(text):
    try:
        with open(LOG, "a", encoding="utf-8") as fh:
            fh.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S%z')} {text}\n")
    except OSError:
        pass


def published_digest():
    """The digest of the tag as the registry currently serves it."""
    token_url = f"https://{REGISTRY}/token?service={REGISTRY}&scope=repository:{REPO}:pull"
    req = urllib.request.Request(token_url, headers={"User-Agent": "cloud-computer-update-watch"})
    with urllib.request.urlopen(req, timeout=25) as resp:
        token = json.load(resp)["token"]
    req = urllib.request.Request(
        f"https://{REGISTRY}/v2/{REPO}/manifests/{TAG}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": MANIFEST_ACCEPT,
            "User-Agent": "cloud-computer-update-watch",
        },
    )
    with urllib.request.urlopen(req, timeout=25) as resp:
        # The registry states the digest; fall back to hashing the body it sent.
        digest = resp.headers.get("Docker-Content-Digest")
        if not digest:
            import hashlib
            digest = "sha256:" + hashlib.sha256(resp.read()).hexdigest()
        return digest.strip()


def telegram_credentials():
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "")
    chat = os.environ.get("TELEGRAM_HOME_CHANNEL", "") or os.environ.get("TELEGRAM_CHAT_ID", "")
    if token and chat:
        return token, chat
    try:
        with open(ENV_FILE, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("TELEGRAM_BOT_TOKEN=") and not token:
                    token = line.split("=", 1)[1].strip()
                elif line.startswith("TELEGRAM_HOME_CHANNEL=") and not chat:
                    chat = line.split("=", 1)[1].strip()
    except OSError:
        pass
    return token, chat


def send(text):
    token, chat = telegram_credentials()
    if not (token and chat):
        log("no Telegram credentials — message not sent: " + text.splitlines()[0])
        return False
    body = urllib.parse.urlencode({"chat_id": chat, "text": text}).encode()
    req = urllib.request.Request(
        f"https://api.telegram.org/bot{token}/sendMessage", data=body,
        headers={"User-Agent": "cloud-computer-update-watch"},
    )
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            return 200 <= resp.status < 300
    except Exception as exc:                     # noqa: BLE001
        log(f"send failed: {exc}")
        return False


def load_state():
    try:
        with open(STATE, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def save_state(state):
    tmp = STATE + ".tmp"
    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(state, fh, indent=1, sort_keys=True)
        os.replace(tmp, STATE)
    except OSError as exc:
        log(f"could not save state: {exc}")


def main():

    try:
        digest = published_digest()
    except Exception as exc:                     # noqa: BLE001 - stay quiet, log only
        log(f"registry check failed: {exc}")
        return 0

    state = load_state()
    seen = state.get("published_digest")

    if not seen:
        state["published_digest"] = digest
        state["first_run"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        save_state(state)
        log(f"baseline recorded: {digest}")
        return 0

    if digest != seen:
        if send(MESSAGE):
            state["published_digest"] = digest
            state["last_notified"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            save_state(state)
            log(f"notified for new digest {digest} (was {seen})")
        else:
            # Leave the old digest in place so the next run tries again.
            log(f"new digest {digest} seen but notification failed; will retry")
    return 0


if __name__ == "__main__":
    sys.exit(main())
