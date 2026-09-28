---
name: ai-film-pipeline
description: "Master pipeline skill for producing AI short films and micro-dramas with the owner's studio: idea → script → shots → Style Reference → images (GPT Image 2.5 Sunburst) → clips (two lanes: Seedance 2.5 premium, MiniMax H3 family budget) → studio review → 4K masters (bytedance upscaler)."
version: 4.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [film, video, production, pipeline, fal-ai, higgsfield, gpt-image-2-5-sunburst, seedance, automation]
    related_skills: [ai-film-scriptwriting, ai-film-cinematography, ai-film-keyframe-authoring, ai-film-prompt-engineering, studio-ops, fal-ai-ops]
---

# AI Film Production Pipeline

## Overview

The owner's end-to-end pipeline for AI short films and micro-dramas. Generation
runs through paid media APIs — their **fal.ai** account, and **Higgsfield** as a
second host for the same models once its key is configured (see `fal-ai-ops` for
the models, commands and spending rule); all review happens in their **studio**
(see `studio-ops`). Post-production (assembly, titles, music) is done by the
owner in their video editor.

## The pipeline (follow this order)

> **Which model runs which stage is decided by the model registry, not by the
> prose below.** Read `references/model-registry.yaml` + `references/model-routing.md`
> before any generation. The stack below is the current global default; if the
> owner selects an alternative for a step (shot / project / global), follow the
> mapping protocol and append, don't override.
>
> **The other models stay in the registry as alternatives — never delete them, and
> label them as alternatives whenever you mention them:** the **MiniMax H3 family**
> (the *budget lane* — `minimax/h3` ~US$0.06/s and `minimax/h3-max` ~US$0.08/s at
> 768P, 5-second minimum, so a 3s or 4s shot cannot be made on that lane) and the
> GPT Image 2 family (rollback).

```
1. IDEA        →  talk it through with the owner; nothing is created yet
2. SCRIPT      →  write it, break it into 4–6 second shots — the premium lane's floor is
                  4s; the budget lane's floor is 5s (see ai-film-scriptwriting)
3. WORDS OK    →  two gates, in order: owner approves the SCRIPT first, then
                  you write the character bible + asset text and they approve
                  that (words only — nothing is generated yet)
4. STYLE REF   →  optional but best done early: the owner sends a few images of
                  the look they want, you save them on the assets page's Style
                  Reference section, they star the approved look — from then on
                  every image you generate carries it (never re-renders assets)
5. IMAGES      →  reference images: character sheets + locations/props
                  (openai/gpt-image-2.5/sunburst/edit — every request carries
                  the approved Style Reference first; character sheet high
                  ~$0.04, location/prop medium ~$0.01)
6. KEYFRAMES   →  first frame per shot (openai/gpt-image-2.5/sunburst/edit: Style
                  Reference + character sheet + location refs, compose the
                  frozen moment; 2048×1152 for 16:9, 1152×2048 for 9:16)
7. CLIPS       →  ONE LANE CHOICE FIRST (premium vs budget — the lane rule below),
                  then one clip per shot on the chosen lane (premium = Seedance 2.5
                  reference-to-video: keyframe as @Image1, character sheets as
                  @Image2+, the speaker's voice as @Audio1; dialogue in quotes in
                  the prompt — the model speaks it and syncs the lips)
8. REVIEW      →  owner reviews in the studio; feedback on a card =
                  regenerate that one shot; "approved" = done
9. MASTER      →  approved clip → 4K upscale (bytedance upscaler, aigc
                  preset) → $HERMES_HOME/studio/masters/<film>/<shot_id>.mp4
```

## Rules that never bend

- **CLARIFY FIRST — ambiguous instruction = ask, then wait.** If any instruction is ambiguous (chat, studio review loop, anywhere), ASK the user what they mean and WAIT before taking ANY action. Never guess, never pick a "reasonable default". Ambiguity includes: which assets/steps are meant, whether a review message means "approved, go ahead", which phase "generate" refers to, or anything readable more than one way. A clarifying question is correct action; acting on a guess is not.
- **Run the shot auditor before you hand a script back — don't add durations up by hand.**
  `scripts/audit_shots.py` (shipped in this pack) reads a shot-plan markdown and reports what the
  budget depends on: shot count, runtime per episode, the season total, and a generation + master
  cost range. It also enforces the two rules that silently break a shoot — **one speaker per clip**
  (a shot block naming two speakers cannot be generated as written) and the **shot floor** (under
  4 seconds cannot be generated; 4 seconds is available on the higher-quality model only, because
  the lower-cost model's floor is 5 seconds). Exit code 1 means something was flagged, so it can
  gate the hand-off. Usage: `python3 scripts/audit_shots.py path/to/script.md`
- **Words before media.** Never generate before the script, shot plan and
  character bible are approved.
- **Two approval gates, in order.** (1) After drafting a script, hand it back
  to the owner for review and WAIT — never offer or start keyframe,
  video-prompt or clip work in the same breath. (2) Only after the script is
  approved, write the character bible + asset text and populate the studio's
  assets page (words only — every character gets all six bible fields
  plus the Character Sheet Prompt composed from them; schema in studio-ops),
  then hand THAT back for approval too.
  Generation starts only after both gates pass. Skipping ahead wastes review
  time and spends money early.
- **The price gate — quote both providers before every paid stage, no exceptions.**
  Price the SAME job at every provider you have configured that can do it — reading the
  current rate from the provider's own pricing surface at that moment, never from this
  skill, the Guide or an older chat (rates move monthly; a stale figure is a wrong
  quote). Show the owner a short comparison (provider · exact model · settings ·
  per-unit rate · batch total), name the cheaper one, recommend one and say why (price,
  capability, or consistency), then WAIT for the explicit yes. Never generate on an
  unquoted price. Say plainly when the two providers come out equal — for images they
  normally do. If only one provider can run that stage, say so plainly instead of
  implying a choice, and never switch provider silently. Mechanics, the comparison
  format and what each provider currently covers: `references/provider-price-comparison.md`.
  On the **video** stage there is a second comparison on top of the platforms — the
  choice between two model lanes (the rule directly below).
- **Two model lanes on every video batch — price both, then let the owner pick.**
  Before ANY video batch, price the same shots on both lanes and state the trade-off
  in one line, then WAIT for the owner's choice:
  - **Premium lane — Seedance 2.5 reference-to-video.** Native audio + lip-sync in one
    pass, clips **4–30s**, up to **30 image refs**, and image and audio refs add no
    cost. About **US$0.57 per second at 720p on fal.ai** (≈US$2.84 per 5s), about
    **US$0.46 on Higgsfield** (≈US$2.31 per 5s; roughly **19% cheaper at 720p, 22% at
    480p**).
  - **Budget lane — the MiniMax H3 family**, two tiers: **`minimax/h3` about US$0.06
    per second at 768p** (≈US$0.30 per 5s) and **`minimax/h3-max` about US$0.08 per
    second at 768p** (≈US$0.40 per 5s). Clips run **5–15 seconds with a 5-second
    minimum** — a **3s or 4s shot CANNOT be made on this lane** (the 4-second floor
    belongs to the premium lane only). The first **5 reference images are free**, then
    about US$0.08 each on the cheaper tier, or about US$0.02 per 2048px image on the
    other tier.
  - **Where each lane is sold.** Higgsfield sells the H3 family at **2K only**, at
    about US$0.13 per second — the same rate fal.ai charges at 2K, so the platforms
    **match** there, and **below 2K only fal.ai sells it**. Seedance 2.5 is about
    **19% cheaper on Higgsfield**. So the budget lane is in practice a fal.ai lane and
    the premium lane is in practice a Higgsfield lane — but **where both platforms
    sell the model you are quoting, compare both platform prices too**.
  - **Ask ONCE per batch.** State the trade-off in a single line, record the owner's
    choice for the project, and hold it for the whole batch — never re-ask clip by
    clip.
  - **Scale, so you can say it out loud:** a 70-second film's video (a 60-second film)
    is about **US$39.73 on fal** or **US$32.35 on Higgsfield** on the premium lane,
    against about **US$5.60 (`h3-max`)** or **US$4.20 (`h3`)** on the budget lane — a
    roughly **7–9× spread**, the biggest single cost decision in the production.
  - **LIST PRICES ONLY.** Quote the live model page every time; a promo or discounted
    rate must never be quoted, repeated or stored anywhere.
- **Spending rule.** Every successful generation bills the owner (about US$0.04
  per character sheet, US$0.01 per location or prop, US$0.045 per first frame,
  ~US$2.31–2.84 per 5-second clip at 720p on the premium lane depending on host,
  ~US$0.30–0.40 per 5-second clip at 768p on the budget lane, ~US$0.14 per 4K
  upscale — these are orientation only and must be re-quoted live). Never
  start a paid batch without asking the owner first — in the chat you are talking
  to them in, or on their messenger if one is connected ("shall I generate
  the N shots now? it'll cost about US$X"), check the balance first, report
  the actual cost when done. See `fal-ai-ops` and
  `references/provider-price-comparison.md`.
- **Quote first, then get an explicit yes — even when the owner says "go
  generate".** "Go" or "yes" to an earlier step is NOT approval for a paid
  batch: state the exact scope and the estimated cost and WAIT for an
  explicit yes to THAT message. Never announce a batch and its cost in the
  same message as launching it — the quote comes first, on its own.
- **Clip length depends on the lane.** On the premium lane the minimum is **4 whole
  seconds** (maximum 30) and the practical shot length is 5–6s (the plan's range is 5–30s — 5s because the budget lane cannot go below it); on the budget lane the
  minimum is **5 seconds** (maximum 15), so a 3s or 4s shot simply cannot be generated
  on that lane — plan 5–6s or put the beat on the premium lane. Never plan a clip
  shorter than the chosen lane's floor, and don't stretch a beat to fill a
  longer one.
- **One speaker per clip, lines ≤ 5 seconds.** The model syncs one mouth to
  one voice per clip. Break dialogue into shot/reverse-shot close-ups. A
  multi-speaker clip is a legitimate experiment on this model, never the
  default.
- **Consistency comes from reference images.** Anchor every shot with the
  same character sheet, named honestly in the prompt text (@Image1, @Image2…) —
  the model has no memory between clips.
- **Every image request carries the Style Reference.** The look the owner
  starred on the assets page's **Style Reference** section goes FIRST in
  `image_urls` on every image the agent generates — character sheets, location
  and prop images, and each shot's first frame — and you also describe that look
  in words (palette, contrast, light quality, lens feel) so it cannot drift.
  Nothing starred yet? Generate without one and say so. (A style reference
  never re-renders existing assets.)
- **The keyframe sets the scene; the prompt owns motion and time.** Don't
  re-describe the whole frame in words — say what moves, what the camera does,
  and for a multi-beat shot what happens in each stage or time range.
- **Verify before claiming success.** Every generated file must exist on
  disk with a sensible size and be copied into the right studio folder under
  its descriptive versioned name (the studio-ops skill's naming standard) —
  never a bare `image.png`/`video.mp4`, and never overwrite an existing
  file. Masters go in `masters/`.
- **The card's prompt field is the reviewed words; the sent prompt lives in a
  provenance map.** A shot's `image_prompt`/`video_prompt` in its
  `metadata.json` are what the owner reviewed and what the NEXT run must send
  verbatim — generators READ them, never write them. After each successful
  generation, record the exact text actually sent under
  `metadata["prompts"][<take filename>] = {"prompt": …, "model": …,
  "sent_at": …}`. That provenance map is a BACKEND-ONLY audit record: never
  render it in the Studio UI. Draft-authoring scripts must refuse to touch any
  card that already holds media (drafting happens only BEFORE generation).
  Two writers fighting over one field is how a review surface ends up
  displaying text that never ran — one field, one meaning, immutable
  send-log. (This is the same contract the owner's own studio follows.)

## Where things live

- Project words: `$HERMES_HOME/studio/` (projects.json, shot cards, script pane)
- Reference media: `$HERMES_HOME/studio/assets/<season>/<asset>/`
- Review copies: `$HERMES_HOME/studio/shots/<film>/<shot>/` (versioned media files)
- Masters: `$HERMES_HOME/studio/masters/<film>/<shot_id>.mp4`
- By-hand commands behind every guided step (install, restart, tunnel, browser, keys):
  `references/manual-fallbacks.md`. Only `$HERMES_HOME` survives an app update.

## Done?

Tell the owner what is ready to review, what each batch cost, and — when a
shot is approved and upscaled — the exact master path. Then back to step 1
for the next episode: same characters, same voices, same rules.
