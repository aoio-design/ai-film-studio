---
name: ai-film-cost-benchmarking
description: "Planning and checking what your own film costs: per-unit list rates per stage (reference images, keyframes, voice refs, video clips, 4K masters), how to estimate a film's cost before generating anything, how to read a provider bill, and what makes spend balloon (re-rolls, resolution, clip length, shot count, lane choice)."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [cost, budgeting, pricing, fal-ai, higgsfield, film, planning]
    related_skills: [fal-ai-ops, ai-film-pipeline, ai-film-craft-fundamentals]
---

# Cost Planning & Bill Reading — what your own film costs

*Use when: estimating what a film, episode or batch will cost before generating
anything; explaining a bill or a figure; deciding between the two video lanes; working out
why a batch cost more than expected; or sanity-checking a rate your agent quoted.*

## Overview

Every generation is a paid API call that returns a finished file. There is no GPU you rent
by the hour and no resource you leave running: **cost is per successful output**, and the
number that matters is the total for the batch you are about to run.

This skill is about *your own spend* — what each stage costs, how to estimate a film
before spending, how to read a bill, and what makes spend balloon. It is deliberately
provider-neutral: read the live rate from whichever providers you have configured. For the
mechanics of pricing and the two-lane rule, `fal-ai-ops` and
`references/provider-price-comparison.md` are the operational authority; this file is the
budgeting layer above them.

**Two rules sit above everything in this file:**

1. **Every figure below is a LIST RATE that must be re-quoted live before any paid batch.**
   Rates move monthly, per resolution, per tier. A figure read from this file, from the
   guide, or from an old chat is *orientation*, never a quote.
2. **Never start a paid batch without quoting it first and getting an explicit yes.**
   "Go" on an earlier step is not approval for a spend. The quote goes in its own message.

## When to Use

- "What will this episode cost?" — before a single image is generated
- Deciding premium lane vs budget lane for a batch (price both, always)
- Explaining why a finished batch cost what it did
- A bill, a unit rate, or a per-image cost looks wrong
- Planning a season or a series and needing a realistic envelope
- Judging whether output quality justifies a re-roll, or whether the problem is upstream

---

## 1. What each stage costs (list rates — re-quote live before every batch)

| Stage | What it is | List rate (orientation) |
|---|---|---|
| Character sheet | 1536×1024 reference image, high quality | ≈ **US$0.04** per sheet |
| Location / prop reference | 1536×864 / 1024×768, medium quality | ≈ **US$0.01** per image |
| First-frame keyframe | 2048×1152 (16:9) or 1152×2048 (9:16), high quality | ≈ **US$0.045** per frame |
| Reference voice | One short line per character, generated once and reused on every clip | ≈ **US$0.01** per character |
| **Clip — premium lane** | Seedance 2.5, 720p, native audio + lip-sync, 4–30s clips | **US$0.5676/s on fal.ai ≈ US$2.84 per 5s** · **US$0.4622/s on Higgsfield ≈ US$2.31 per 5s** |
| **Clip — budget lane (cheaper tier)** | MiniMax H3, 768p, 5–15s with a **hard 5s floor** | **US$0.06/s ≈ US$0.30 per 5s** |
| **Clip — budget lane (upper tier)** | MiniMax H3 Max, 768p, 5–15s, 5s floor | **US$0.08/s ≈ US$0.40 per 5s** |
| Clip — budget lane at 2K | MiniMax H3 at 2K (Higgsfield sells this family at 2K only) | **US$0.13/s** |
| 4K master | One approved clip upscaled | a **separate per-second cost**, quoted with the batch |

Facts that follow from the table, and that drive every estimate below:

- **The images are not the bill; the clips are.** A character sheet costs roughly *one
  seventieth* of a 5-second 720p premium clip. If you need to economise, economise on
  footage seconds, not on reference images — and never cut a reference image to save money
  when consistency (which is what those images buy) is the thing that prevents re-rolls.
- **The clip price is per second, per resolution.** A 10-second clip is roughly twice a
  5-second one; a higher resolution raises the per-second rate. Quote the exact resolution
  and the exact clip length you will ship, never a rounded guess.
- **The clip stage has two lanes, and the spread between them is roughly 7–9×** at these
  list rates. It is the single biggest cost decision in a production, which is why the lane
  is priced on both sides and chosen by the person paying — once per batch, not per clip.
- **Reference images and audio cost nothing extra on the premium lane** (the clip's
  seconds are the whole price, and native audio/lip-sync is included). On the budget lane
  the first 5 reference images are free and further references are billed — so keep the
  budget-lane reference set tight.
- **The 5s floor is a hard constraint.** A 3-second or 4-second shot cannot be generated on
  the budget lane; a 4-second shot exists only on the premium lane. A plan with lots of 4s
  beats forces the premium lane — that is a budget decision made at the script stage.

## 2. Estimating a film before you generate anything

Estimate in this order. The point is to have a number *before* the batch, so a surprise is
a check, not a discovery.

1. **Count the shots.** Runtime ÷ your coverage length. At the plan's 5–6s coverage, a
   60-second film is about 12 shots and a 3-minute film about 33. Use the shot auditor
   (`scripts/audit_shots.py` in this pack) rather than adding durations up by hand — it
   reports the shot count, the runtime and a generation + master cost range, and flags the
   two things that silently break a shoot (two speakers in one clip; durations below a
   lane's floor).
2. **Keyframes = shots.** One first-frame image per shot.
3. **Clip seconds = the sum of the shot durations** — that is what the per-second rate
   multiplies.
4. **References are one-time, per project.** Character sheets for the characters in the
   film, plus location/prop images; voice references once per speaking character and reused
   on every clip they speak in.
5. **Upscaling is optional and per second of *selected* footage** — only the shots you
   actually ship as masters.
6. **Add a retake allowance.** Re-rolls are normal; a **25% allowance** over the
   generation subtotal is the pack's planning default (a stricter 30% for a first episode
   with new characters and a new look). This line is the difference between a plan and a
   surprise.
7. **Price the whole job on both lanes, then multiply out.** Provider · model · settings ·
   per-unit rate · batch total, for each lane, at *this project's* resolution and clip
   length.

### Worked example — a 60-second film (12 shots × 5s = 60s of clip)

Assumptions: 3 characters (3 sheets + 3 voice refs), 8 location/prop images, all 12 shots
upscaled. Media that isn't clips:

| Line | Working | US$ |
|---|---|---|
| Reference images (3 sheets + 8 locations/props) | 3×0.04 + 8×0.01 | 0.20 |
| Keyframes (12) | 12 × 0.045 | 0.54 |
| Voice references (3) | 3 × 0.01 | 0.03 |
| 4K masters (12 shots) — *estimate at the pack's planning default of US$0.14/clip; quote the real per-second rate* | 12 × 0.14 | 1.68 |
| **Sub-total, non-clip** | | **2.45** |

| Lane (this batch) | Clips (60s) | + non-clip | **+25% retakes** |
|---|---|---|---|
| Premium — 720p on fal.ai ($0.5676/s) | 34.06 | 36.51 | **≈ 45.63** |
| Premium — 720p on Higgsfield ($0.4622/s) | 27.73 | 30.18 | **≈ 37.73** |
| Budget — `minimax/h3` 768p ($0.06/s) | 3.60 | 6.05 | **≈ 7.56** |
| Budget — `minimax/h3-max` 768p ($0.08/s) | 4.80 | 7.25 | **≈ 9.06** |
| Budget — H3 at 2K ($0.13/s) | 7.80 | 10.25 | **≈ 12.81** |

Scaling: the same film at 3 minutes (about 33 shots, 180s of clip, 4 characters, 12
location/prop images) lands at roughly **US$112–136** on the premium lane (Higgsfield–fal,
retakes included) against roughly **US$22–37** on the budget lane — i.e. the clip line
scales linearly with seconds, while the image and voice lines barely move.

**Reading it out loud:** total ÷ runtime in minutes is your own cost per finished minute.
For the 60-second example, the totals above *are* the per-minute figures.

All of these numbers move with list rates, resolution and clip length — re-quote them live
and re-run the arithmetic at the real figures before you commit.

## 3. How to read a bill

- **Only successful outputs are billed.** Failed requests and queue time are free, so a
  re-roll costs one clip, not a session. If a failure shows up on a bill, that is worth
  querying with the provider.
- **Billing is per successful generation, not per request.** Twelve approved shots plus
  three re-rolls is fifteen billed clips, whatever the wall-clock time.
- **Clip billing is per second of generated length.** A 10-second clip that you trim in the
  edit to 4 seconds was still billed as 10 seconds. Trimming is free only if the generation
  was short.
- **Image billing is per listed size × quality tier — and is not proportional to pixel
  area.** A slightly larger frame can be cheaper than a smaller one, and a non-canonical
  custom size is not safely interpolated: quote listed sizes exactly, treat a custom size as
  an estimate, and generate one image at that exact size to read the real billed cost.
- **The quality tier is the price dial, not a free label.** Name the tier in every quote
  and in every bill check. A "high" tier at one size can cost more than a much larger frame
  at a lower tier — the tier, not the dimensions, is usually what moved.
- **References and audio.** On the premium lane, image and audio references add nothing to
  the clip price; on the budget lane, references past the first five images are billed.
  A budget-lane quote with a fat reference set is not the price you expected.
- **Upscaling bills for the seconds you actually upscaled.** Only send approved shots, and
  only the ones you need as masters.
- **Reconcile every batch: quote ↔ actual.** Count the delivered files on disk, compare
  them with the successes you believe were billed, and compare the total with the quote you
  approved. Two minutes of arithmetic per batch is how a wrong rate gets caught while it is
  still cheap.

## 4. What makes spend balloon

In rough order of how much they matter:

1. **Re-rolls.** Every rejected take is a full-priced generation. A loose brief — no
   approved script, no approved character bible, no style reference, vague shot prompts —
   converts directly into paid takes. The cheapest cost control in the whole production is
   the words-gate: approve the script, then approve the character bible and asset text,
   *before* anything is generated.
2. **The lane.** Premium vs budget is roughly a 7–9× difference at 720p vs 768p. Both lanes
   are legitimate; the point is that it must be a *decision*, quoted both ways, not a
   default.
3. **Total clip seconds.** Cost is per second, so runtime and coverage density multiply the
   bill directly. Extra coverage, uncovered scenes that have to be re-generated whole, and
   shots that exist because nobody could name their job are all seconds you pay for twice
   (once to generate, once in the edit you didn't need to fight).
4. **Long takes.** A 20-second clip costs four times a 5-second one, is harder to keep
   coherent, and removes your ability to cut. Long single takes are the most expensive way
   to cover a scene.
5. **Resolution.** The per-second rate rises with resolution, and it rises on the upscale
   too (1080p vs 4K, and only for selected footage).
6. **The quality tier on images.** Raising the tier is a real multiple, not a nudge.
   Use a higher tier where fidelity matters (faces, hero frames, a deliverable sheet) and
   the lower tier where it is a texture reference.
7. **Re-generating whole scenes instead of one shot.** Review at shot level: feedback on a
   shot should re-run that shot, not the scene. A scene-level re-run is 3–9× the necessary
   spend.
8. **Paying for a mistake twice.** Generating before the style reference is chosen, then
   re-rendering every asset with it; or running a batch on the wrong aspect ratio; or
   discovering the lane floor after the plan is locked. Each of these is a full re-run.
9. **Custom and non-canonical image sizes.** Snapped or re-billed sizes are a silent drift
   between plan and bill.
10. **Batch hygiene.** Asking twice for the same batch, or launching a batch without a
    balance check, turns a scheduled spend into an unplanned one.

## 5. Cost discipline that isn't a discount

- **One quote, one yes, per batch.** State the scope and the estimated total, wait for an
  explicit yes to *that* message, then run the whole batch in one go.
- **Price both lanes, then both providers, before any paid batch.** A single-lane quote is
  an incomplete quote. State the trade-off in one line, ask once per batch, hold the answer
  for the project.
- **List prices only.** Never plan a budget on a promotional or discounted rate — promos
  expire and a plan built on one is wrong from the day it lapses.
- **Approval gates before media.** Script → words → style reference → assets → keyframes →
  clips → masters. Skipping a gate is not saving time; it is paying for takes you discard.
- **Plan 5–6s coverage.** It sits inside both lanes' floors, gives the edit something to
  trim, and keeps the lane choice open right up to the quote.
- **Keep the reference set to what is on screen.** It costs money on the budget lane, and a
  wide reference set does not buy consistency beyond the sheets that actually matter.
- **Report the actual cost when a batch finishes**, next to the quote. That comparison is
  the only thing that keeps future estimates honest.
- **Use the shot auditor before quoting.** It turns "about 12 shots, call it X" into a
  counted shot list and a range, at no cost.

## 6. When a number or an output looks wrong

**A bill looks high.** Check, in this order: which model and quality tier actually ran (the
per-unit cost is the fastest tell — a suspiciously cheap image is not a high-tier image);
the actual billed size (snapped or non-canonical dimensions); how many references rode
along; how many takes were generated versus approved; and whether anything was upscaled
that didn't need to be.

**Output looks weak.** Do not spend more first — establish what ran. Cheapest-first:
(1) the model and tier actually used, and the cost per output as the tell; (2) whether
reference images were attached at all — consistency comes from the anchor, not from a
longer adjective list; (3) whether the agent can *see* its own output (an agent generating
images it cannot inspect pushes all quality control — and all re-roll cost — onto you);
(4) only then a like-for-like comparison: same prompt, same tier, same references, same
settings on both sides. Most quality complaints are a missing reference, the wrong tier, or
a prompt that never carried the style reference — all of which are free to fix.

## 7. Pitfalls

- **Quoting from a table instead of the provider's live pricing surface.** A stale rate is
  a wrong quote, and it costs trust in every number afterwards. Say where you read it.
- **Quoting a promo.** Never stored, never repeated, never planned on.
- **Area-scaling a custom image size.** Image pricing is not proportional to pixels;
  measure one.
- **Forgetting the retake allowance.** A plan without one is not a budget, it's a wish.
- **Assuming images are the expensive part.** They are a rounding error against the clip
  line; the clip seconds are the bill.
- **Comparing a 480p draft with a 720p final.** Like-for-like settings or no comparison.
- **Hiding retries inside a per-unit rate.** Re-roll expectations are a separate, explicit
  line.
- **Assuming one lane.** Two lanes, both quoted, one decision per batch.
- **Assuming the budget lane can do a 3s or 4s shot.** It cannot — the floor is 5 seconds
  there, and 4 seconds on the premium lane.

## 8. The quote template

Every paid batch, in this shape, before anything runs:

```
Batch: <stage> — <N> items · <resolution> · <clip length>
Provider A · <exact model id> · <settings>   <rate> × <units> = <total>
Provider B · <exact model id> · <settings>   <rate> × <units> = <total>
Retakes: <N>% allowance, quoted separately
Recommendation: <which, and why — price, capability or consistency>
Nothing is generated until you confirm.
```

For clips, the same batch is quoted **twice — once per lane**, each with its own provider
rows, so the choice is between complete options rather than a model and a number.
