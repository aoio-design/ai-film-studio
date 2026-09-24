#!/usr/bin/env python3
# Reports new studio feedback. Silent when there is nothing new.
import json, os
from datetime import datetime, timezone
H = os.environ.get("HERMES_HOME") or os.path.join(os.path.expanduser("~"), ".hermes")
S = os.environ.get("STUDIO_DIR") or os.path.join(H, "studio")
STATE = os.path.join(S, ".feedback-watch-state")
if not os.path.isdir(S): raise SystemExit(0)
def ts(s):
    try: return datetime.fromisoformat(s).timestamp()
    except Exception: return 0.0
last = 0.0
first = not os.path.exists(STATE)
if not first:
    try: last = float(open(STATE).read().strip())
    except Exception: last = 0.0
found = []
# Feedback lands in two trees: shots/ (shot cards + the episode script) and
# assets/ (Character Bible, locations, props). The studio-wide inbox list also
# lives under shots/, so both trees are walked here.
for root_dir in (os.path.join(S, "shots"), os.path.join(S, "assets")):
    if not os.path.isdir(root_dir): continue
    for root, _dirs, files in os.walk(root_dir):
        for fn in files:
            if fn not in ("metadata.json", "_episode_script.json", "_studio_feedback.json"): continue
            try: data = json.load(open(os.path.join(root, fn)))
            except Exception: continue
            # A studio-wide inbox is a plain list; every other file is an object
            # with a "feedback" list inside.
            entries = data if isinstance(data, list) else data.get("feedback") or []
            for fb in entries:
                if not isinstance(fb, dict): continue
                if ts(fb.get("timestamp", "")) > last + 60:
                    t = fb.get("timestamp", "")
                    found.append((ts(t), os.path.join(root, fn), t[:16], (fb.get("text") or "")[:2000]))
open(STATE, "w").write(str(datetime.now(timezone.utc).timestamp()))
if first or not found: raise SystemExit(0)
found.sort(key=lambda x: (x[0], x[1]))
print(f"\U0001F3AC New studio feedback ({len(found)}):")
for _t, path, stamp, txt in found:
    print(f"  {stamp} \u00b7 {path}")
    print(f"    {txt}")
print("Process it: read each file above, act on the note, then append your reply to shots/_agent_replies.json.")
