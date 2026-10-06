# Provider price comparison — before every paid stage

**Rule (also in `ai-film-pipeline` → Rules that never bend):** price the same job at
**every provider you have configured** that can do it, show the owner a short
comparison, name the cheaper one, recommend one, and WAIT for the explicit yes. Never
generate on an unquoted price. Never switch provider silently, and never mix providers
inside one stage without approval. When the two quotes come out equal, say so in plain
words instead of implying a saving.

**And on the video stage, price the two LANES as well as the two platforms** — premium
(Seedance 2.5) against budget (the MiniMax H3 family) — state the trade-off in one line,
ask **once per batch**, and hold the owner's choice for the project. Never re-ask clip by
clip, and never present only one lane as if it were the only option.

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
| Clips | the LANE first (premium Seedance 2.5 vs budget MiniMax H3 family), then model, resolution, clip length in seconds (respecting the lane's floor — 4s premium, **5s budget**), audio on/off, how many reference images/audio ride in the request (on the premium lane image and audio references cost nothing extra — state that instead of padding the quote; on the budget lane the first 5 reference images are free, then references are billed), and both platform prices wherever both platforms sell the model |
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

For clips, the same batch is quoted **twice — once per lane**, each with its own provider
rows, so the owner is choosing between complete options rather than a model and a number:

Rules for the table: same settings on both sides (never compare a 480p draft with a
720p final), include the reference-image and audio surcharges where the provider bills
them, and state re-roll expectations separately — do not hide retries inside the
per-unit rate. Re-quote at the batch's own length: a clip price is per second, so a
4-second shot and a 6-second shot are different jobs.

## Video clips — two lanes, two platforms

The clip stage is the one stage where the owner is choosing between two *models* as well
as two *hosts*. Price both lanes on the same shots and let them decide:

| Lane | Model family | Clip length | List rate (orientation — always re-quote) | Reference images |
|---|---|---|---|---|
| **Premium** | Seedance 2.5 reference-to-video | **4–30s** | ~US$0.57/s @720p on fal.ai (≈US$2.84 per 5s) · ~US$0.46/s on Higgsfield (≈US$2.31 per 5s — roughly 19% cheaper at 720p, 22% at 480p) | up to 30 refs; images and audio cost nothing extra |
| **Budget** | MiniMax H3 family — `minimax/h3` (cheaper tier), `minimax/h3-max` (upper tier) | **5–15s, 5-second minimum** | `h3` ~US$0.06/s @768p (≈US$0.30 per 5s) · `h3-max` ~US$0.08/s @768p (≈US$0.40 per 5s) | first 5 free, then ~US$0.08 each (`h3`) or ~US$0.02 per 2048px image (`h3-max`) |

- **The 5-second floor is a hard constraint, not a preference.** A 3-second or 4-second
  shot cannot be generated on the budget lane; the 4-second floor belongs to the premium
  lane. If a shot needs 4s, either plan it as 5–6s or quote that one shot on the premium
  lane — and say which shots move.
- **Platform coverage differs by lane, so the two-row comparison does too.** Higgsfield
  sells the H3 family at **2K only**, at about US$0.13 per second — the same rate fal.ai
  charges at 2K, so there the platforms **match** and there is no saving to name. Below
  2K, only fal.ai sells it: say that plainly instead of implying a choice. Seedance 2.5 is
  about 19% cheaper on Higgsfield. In practice the budget lane is a fal.ai lane and the
  premium lane is a Higgsfield lane.
- **Scale:** 70 seconds of generated video for an approximately 60-second finished film is about US$39.73 on fal or US$32.35 on Higgsfield on the premium lane, against about US$5.60 (`h3-max`) or US$4.20 (`h3`) on the budget lane — roughly a **7–9× spread**.
- **Ask ONCE per batch.** State the trade-off in one line, let the owner choose, and hold
  that choice for the project — do not re-ask for every clip, and do not present one lane
  as the only option.
- **List prices only.** Quote the live model page (or `genmedia pricing <model-id>`) every
  time. Never quote, repeat or store a promo or discounted rate.

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

## What we know as of 28 Sep 2026 (orientation only — re-check before relying on it)

- **Both providers now cover images and clips.** fal.ai runs GPT Image 2.5 Sunburst for
  sheets, locations, props and keyframes, Seedance 2.5 reference-to-video (with a voice
  reference) for clips, and the Bytedance upscaler for masters. Higgsfield carries the
  **same GPT Image 2.5 Sunburst at OpenAI's own token rates** — expect the two image
  quotes to come out identical, and say so rather than implying a saving — and the
  **same Seedance 2.5**, about 19% cheaper at 720p.
- **Clips carry a second choice: the lane.** The **premium lane** is Seedance 2.5
  (~US$0.57/s @720p fal, ~US$0.46/s Higgsfield; 4–30s clips). The **budget lane** is the
  MiniMax H3 family — `minimax/h3` ~US$0.06/s and `minimax/h3-max` ~US$0.08/s at 768p
  (≈US$0.30 / US$0.40 per 5s) — with **5–15s clips and a 5-second minimum**, so no 3s or
  4s shot can be made there, and the first 5 reference images free (then ~US$0.08 each on
  the cheaper tier, or ~US$0.02 per 2048px image on the other tier). Higgsfield sells the
  H3 family at **2K only**, at about US$0.13/s — the same rate fal.ai charges at 2K, so
  the platforms match there; below 2K only fal.ai sells it. Quote both lanes, ask once
  per batch, and remember the answer.
- **Higgsfield API** is real and self-serve (keys from the console, async requests with
  polling or webhooks, pay-as-you-go in USD, no subscription, failed requests not
  billed). Base `https://api.higgsfield.ai`; the console copies ONE combined credential
  to paste as-is into the auth header. A new account runs 2 jobs at once (the limit rises as
  your balance does), and generated files stay available about 7 days — pull finished
  clips into the studio promptly.
- Consequence: "is X cheaper?" is a two-row question now, and the answer differs by
  stage — normally identical for images, roughly 19% off for clips at 720p on
  Higgsfield. For clips the question is really a **two-lane** question: at 720p on the
  premium lane Higgsfield wins by ~19%, and on the budget lane there is nothing to compare
  below 2K (fal.ai only) and nothing to save at 2K (both platforms ~US$0.13/s). Quote both
  numbers and name the winner; where one provider cannot run the stage at all (the
  upscaler, as published today), say that instead of quoting a number.

## If only one provider can do the job

Say so plainly: *"Only <provider> can run this stage today, so there is no comparison —
here is its live rate and the batch total."* Do not imply a choice that does not exist,
and do not present a two-row table where one row cannot actually run the job.
