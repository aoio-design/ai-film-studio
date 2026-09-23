# Provider price comparison — before every paid stage

**Rule (also in `ai-film-pipeline` → Rules that never bend):** price the same job at
**every provider you have configured** that can do it, show the owner a short
comparison, recommend one, and WAIT for the explicit yes. Never switch provider
silently, and never mix providers inside one stage without approval.

## Why a rule and not a price list

Third-party rates change monthly, per resolution, per tier, and per audio setting.
**Never quote a figure from this file, from the Guide, or from an old chat.** Read the
current rate from the provider's own pricing surface at the moment you quote, and say
where you read it. A stale number is a wrong quote, and a wrong quote breaks the
owner's trust in every number you give them afterwards.

## What to price, and how to make the figures comparable

Price the WHOLE job for the stage you are about to run — not one unit:

| Stage | What the comparison must fix, on both sides |
|---|---|
| Character sheets / location / prop images | model, quality tier, output size, number of images |
| First-frame keyframes | model (edit vs text-to-image), quality tier, project aspect ratio, number of frames, references attached |
| Clips | model, resolution, clip length in seconds, audio on/off, how many reference images/audio ride in the request |
| Upscale | model, target (1080p vs 4K), total seconds of SELECTED footage only |
| Voice references | model, one-time per character |

Then present:

```
Batch: <stage> — <N> items
Provider A · <exact model id> · <settings>   <rate> × <units> = <total>
Provider B · <exact model id> · <settings>   <rate> × <units> = <total>
Recommendation: <provider> because <price | capability | consistency>
Say the word and I'll start; nothing is generated until you confirm.
```

Rules for the table: same settings on both sides (never compare a 480p draft with a
768p final), include the reference-image and audio surcharges where the provider bills
them, and state re-roll expectations separately — do not hide retries inside the
per-unit rate.

## Where the live rates come from

- **fal.ai (current default):** `genmedia pricing <model-id>` for the live per-unit
  rate, or the model's page on fal. Full mechanics: `fal-ai-ops`.
- **Higgsfield API (configured when the owner added `HIGGSFIELD_API_KEY`):** rates are per
  model and live in the console at `console.higgsfield.ai` (their docs state the model catalog and each
  model's documentation live there, and that their public `openapi.json` is
  supplementary — a model missing from it is not proof it is unavailable). Read the
  model page at quote time; do not trust a blog table.
- **Any provider you add later:** its own pricing surface, read live, cited in the
  quote.

## What we know as of 23 Sep 2026 (orientation only — re-check before relying on it)

- **fal.ai is the only provider that currently covers the whole stack:** GPT Image 2
  for sheets and keyframes, MiniMax H3 Max reference-to-video with a voice reference
  for clips, and the Bytedance upscaler for masters.
- **Higgsfield API** is real and self-serve (keys from the console, async requests with
  polling or webhooks, pay-as-you-go in USD, no subscription, failed requests not
  billed). But its published endpoints are **image-to-video / text-to-video** for Kling
  2.5-turbo and MiniMax Hailuo 2.3, plus its own image models — **no H3, no
  reference-to-video, no audio-reference input, and no upscaler endpoint** in what it
  publishes, and no machine-readable rates. So today it cannot run our clip, keyframe
  or upscale stages, and its image models are a different class from GPT Image 2 for
  character consistency.
- Consequence: when the owner asks "is X cheaper?", the honest answer needs both
  numbers **and** a capability check. If a provider is cheaper but cannot attach the
  character sheet and the speaker's voice reference, it is not a like-for-like
  alternative — say that explicitly instead of quoting a lower number.

## If only one provider can do the job

Say so plainly: *"Only <provider> can run this stage today, so there is no comparison —
here is its live rate and the batch total."* Do not imply a choice that does not exist,
and do not present a two-row table where one row cannot actually run the job.
