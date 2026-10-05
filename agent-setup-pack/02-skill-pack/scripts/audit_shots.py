#!/usr/bin/env python3
"""Audit a markdown-Hybrid script draft before it goes to the words-gate.

Run this INSTEAD of adding shot durations up by hand. It reports the numbers the
budget depends on:

  * shot count and runtime per episode, plus the season total
  * a generation + master cost range
  * how many clips carry dialogue (one speaker per block is no longer required --
    the one-speaker-per-clip rule was retired Oct 2026)

Usage
-----
    python audit_shots.py path/to/script.md
    python audit_shots.py path/to/script.md --clip-cost 2.31 \
        --keyframe-cost 0.045 --master-cost 0.14 --min-sec 45 --max-sec 75

The cost flags default to the PREMIUM lane at the cheaper host (5s 720p = 2.31
Higgsfield / 2.84 fal). BUDGET lane: 0.30 (minimax/h3) or 0.40 (minimax/h3-max).
Quote live before a batch and pass the real figure.

Exit code is 1 when anything is flagged, so it can gate a hand-off.
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import OrderedDict

# Shot heading, as produced by the markdown-Hybrid format:
#   **1-01 - INT. SHAFT - NIGHT** *(6s)*    (also accepts **Ep1-01 - ...**)
SHOT_RE = re.compile(
    r"^\*\*(?:Ep)?(?P<ep>\d+)-(?P<num>\d+)\b(?P<title>[^*]*)\*\*\s*\*\((?P<dur>\d+)\s*s\)\*",
    re.M,
)

# ALL-CAPS attributions such as "NADIA (V, log)" or "VOSS".
SPEAKER_RE = re.compile(r"^([A-Z][A-Z0-9 .'&-]{1,28}?)\s*(?:\(([^)]*)\))?\s*$")

# Uppercase lines that are stagecraft, not a speaker.
STOPWORDS = {
    "INT", "EXT", "INT./EXT", "CONTINUOUS", "BLACK", "MUSIC", "SFX",
    "CAMERA", "TRANSITION", "FADE", "FADE IN", "FADE OUT", "CUT TO",
    "SMASH CUT", "HARD CUT", "MATCH CUT", "DISSOLVE", "TEXT ON SCREEN",
    "TITLE CARD", "BEAT", "END", "END EPISODE", "TITLE", "LOGLINE",
    "GENRE", "TONE", "TOTAL DURATION", "PROJECT", "V", "V.O.", "O.S.",
}


def iter_blocks(text):
    """Yield (match, body) for every shot heading in the draft."""
    marks = list(SHOT_RE.finditer(text))
    for i, m in enumerate(marks):
        end = marks[i + 1].start() if i + 1 < len(marks) else len(text)
        yield m, text[m.end():end]


def speakers_in(body):
    """Names of the distinct speakers attributed inside one shot block."""
    found = []
    for raw in body.splitlines():
        line = raw.strip()
        if not line or line[0] in ">|#*-(":
            continue
        m = SPEAKER_RE.match(line)
        if not m:
            continue
        name = m.group(1).strip().rstrip(":").strip()
        if len(name) < 3 or name in STOPWORDS:
            continue
        if name not in found:
            found.append(name)
    return found


def main(argv=None):
    ap = argparse.ArgumentParser(description="Audit a script draft's shots and speakers.")
    ap.add_argument("script", help="path to the markdown script draft")
    ap.add_argument("--clip-cost", type=float, default=2.31,
                    help="cost per clip (default 2.31 = a 5s 720p clip on the PREMIUM lane at the "
                         "CHEAPER host, Higgsfield; fal is 2.84. BUDGET lane: 0.30 (minimax/h3) or "
                         "0.40 (minimax/h3-max). These are 28 Sep 2026 list rates -- quote live "
                         "before a batch and pass the real figure.")
    ap.add_argument("--keyframe-cost", type=float, default=0.045,
                    help="cost per keyframe (default 0.045 = GPT Image 2.5 Sunburst edit at high)")
    ap.add_argument("--master-cost", type=float, default=0.14,
                    help="cost per 4K master (default 0.14 = one 5s clip upscaled to 4K)")
    ap.add_argument("--min-sec", type=int, default=45, help="flag episodes shorter than this (default 45)")
    ap.add_argument("--max-sec", type=int, default=75, help="flag episodes longer than this (default 75)")
    ap.add_argument("--retake-pct", type=float, default=25.0, help="retake allowance for the range (default 25)")
    args = ap.parse_args(argv)

    with open(args.script, encoding="utf-8") as fh:
        text = fh.read()

    eps = OrderedDict()
    issues = []
    shots = 0

    for m, body in iter_blocks(text):
        ep, num = int(m.group("ep")), int(m.group("num"))
        label = "%d-%02d" % (ep, num)
        dur = int(m.group("dur"))
        shots += 1

        bucket = eps.setdefault(ep, {"shots": 0, "sec": 0, "talk": 0})
        bucket["shots"] += 1
        bucket["sec"] += dur

        # Two speakers in one block are allowed (the one-speaker-per-clip rule was
        # retired Oct 2026); the scan only counts how many clips carry dialogue.
        if speakers_in(body):
            bucket["talk"] += 1

        if dur < 4:
            issues.append(
                "%s: %ds is below the 4s shot floor -- the PREMIUM lane's minimum is 4s "
                "and the BUDGET H3 lane's is 5s, so a 3s shot cannot be generated on either "
                "lane; merge it into its neighbour or hold longer and trim in the edit"
                % (label, dur)
            )
        elif dur == 4:
            issues.append(
                "%s: 4s is premium-lane only (H3's floor is 5s) -- if this batch may run on "
                "the budget lane, write it at 5s+" % label
            )
        elif dur > 30:
            issues.append(
                "%s: %ds is ABOVE the 30s ceiling -- Seedance 2.5 caps at 30s and the budget "
                "H3 lane caps at 15s, so this shot cannot be generated on any lane; split it"
                % (label, dur)
            )
        elif dur > 15:
            issues.append(
                "%s: %ds is PREMIUM-lane only (the budget H3 lane caps at 15s) -- legal, but it "
                "forces the premium lane for this batch" % (label, dur)
            )

    if not shots:
        print(
            "No shot headings found in %s.\nExpected lines shaped like:\n"
            "  **1-01 - INT. SHAFT - NIGHT** *(6s)*" % args.script,
            file=sys.stderr,
        )
        return 2

    print("\nShot audit: %s" % args.script)
    print("\n%-6s %7s %7s %7s" % ("ep", "shots", "secs", "talk"))
    total_sec = 0
    for ep, b in eps.items():
        total_sec += b["sec"]
        print("%-6s %7d %7d %7d" % ("Ep%d" % ep, b["shots"], b["sec"], b["talk"]))
        if b["sec"] < args.min_sec or b["sec"] > args.max_sec:
            issues.append(
                "Ep%d: %ds is outside the %d-%ds target -- flag it to the user with "
                "the trim identified rather than hiding it"
                % (ep, b["sec"], args.min_sec, args.max_sec)
            )

    talk = sum(b["talk"] for b in eps.values())
    gen = shots * (args.keyframe_cost + args.clip_cost)
    masters = shots * args.master_cost
    low = gen + masters
    high = low * (1 + args.retake_pct / 100.0)

    print("\n%-6s %7d %7d %7d" % ("TOTAL", shots, total_sec, talk))
    print("runtime: %dm %02ds" % (total_sec // 60, total_sec % 60))
    print("clips:   %d  (%d with dialogue, %d silent)" % (shots, talk, shots - talk))
    print(
        "cost:    ~$%.2f generation+masters; ~$%.2f with a %.0f%% retake allowance"
        % (low, high, args.retake_pct)
    )

    if issues:
        print("\nFLAGGED (%d):" % len(issues))
        for i in issues:
            print("  - %s" % i)
        return 1

    print("\nClean: every shot inside its lane floor and ceiling.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
