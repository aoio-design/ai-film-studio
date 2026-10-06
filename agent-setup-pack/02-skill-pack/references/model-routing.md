# Model Routing — workflow, mapping protocol, governance (customer-pack mirror)

**Companion to `model-registry.yaml`** (the data). This file holds the *rules*: which model runs
which stage, how binding scope is resolved, how to map an unmapped model, and the exact agent↔user
workflow for generation. The registry lists *what's available*; this file tells you *how to pick
and how to talk to the owner about it*.

Two-part structure on purpose: **stage logic is model-agnostic** ("what" never changes); **model
binding is living data** ("which model" changes — and appends instead of overriding).

## Part 1 — Stages (model-agnostic; ~never changes)

| Stage | Deliverable | Layout convention / method | Downstream dependency |
|---|---|---|---|
| **Reference images** | character sheets / set stills / prop sheets | char **3-panel** (face close-up ‖ front/back, ONE-face rule) · loc **4-panel** 2×2 · prop **4-panel** grid | consistency for the video model |
| **Keyframe** (first-frame edit) | one frozen frame per shot — opening+closing **if the video binding demands a pair** | single opening frame, mouth closed/neutral on dialogue shots | **AR inherited from the VIDEO binding** |
| **Video clip** | clip with dialogue + sound | motion + dialogue and soundscape; one or two speakers are allowed, with no fixed line-length cap; premium 4–30s, budget 5–15s (5-second minimum) | master |
| **Master** | 4K (or 1080p social) upscale | aigc preset | output |

> **The one living rule: the selected VIDEO model owns the frame aspect ratio (and whether a
> first-last frame pair is required).** The keyframe stage reads the video binding BEFORE emitting
> frame dimensions. Today that's Seedance 2.5 ⇒ a single first frame at 2048×1152 (16:9) or
> 1152×2048 (9:16) — both edges multiples of 16, the model's silent-snap rule. If the project's
> video binding wants other dims or a frame pair, the keyframe stage re-derives from it.

## Editing vs regenerating an EXISTING asset image (task routing)

The `reference_images` stage has two profiles — **`new-sheet-from-prompt`** (`sunburst-asset-sheet`: the whole sheet, composed from the drafted prompt AND the attached references) and **`edit-existing-image`** (`sunburst-asset-edit`). Both run on `openai/gpt-image-2.5/sunburst/edit`: the edit variant is mandatory for EVERY image, because the text-to-image variant of the model accepts no reference images at all and each request must carry the project's Style Reference. Pick by what changed:

- **Words changed** — the description/prompt on the card was edited (wrong jawline, wrong era, "make it a bookshop, not a cafe") → re-draft the sheet prompt and re-run the **whole sheet** (`sunburst-asset-sheet`, same AR/quality tier; the Style Reference still rides first).
- **The existing image is the instruction** — the owner points at an image they can see ("using image-2.png, extract the top-left panel and go wider", "re-light this one") → **edit that image** with the `sunburst-asset-edit` profile: upload the image, pass it as `image_urls` (Style Reference first), describe the change in the prompt, deliver a SINGLE image at the asset's AR/quality tier. Never re-run the whole-sheet text prompt for an image-driven change.
- **Deliver under a NEW versioned filename** — the old take stays on the card until the owner stars the new one (never overwrite).
- **Quote the live price before running** (≈ US$0.01 at 1536×864 medium, ≈ US$0.04 at 1536×1024 high, ≈ US$0.045 per first frame at 2048×1152 high — always check the live table, and price every configured provider that can do the job: `provider-price-comparison.md`).

## Binding scope — precedence (resolved highest → lowest at generation time)

| Level | What it sets | Example |
|---|---|---|
| **Shot override** | one shot → one alternative model | `Ep3-12A → minimax/h3-max/reference-to-video` (budget-lane rescue) |
| **Project binding** | a whole film pins alternatives | "this series refs on nanobanana" |
| **Global default** | the frozen stack for new projects | gpt-image-2.5-sunburst + seedance-2.5 + bytedance |

A shot's `model: <id>` + `resolved_at: <ts>` records what produced it (**provenance**). Adding an
alternative profile NEVER touches the default — selection is additive.

**A binding is a (provider, model) pair.** A second provider (Higgsfield) may be configured
with its key in the same `.env` (`HIGGSFIELD_API_KEY`); price it on every job it can run. Both
hosts carry the same image model (Higgsfield at OpenAI's own token rates, so images normally
price identically on the two) and the same premium video model (Seedance 2.5 — roughly 19%
cheaper on Higgsfield at 720p), so most stages offer a real choice: quote both, name the
cheaper, wait for the yes. The budget lane's MiniMax H3 family is a fal.ai lane below 2K —
Higgsfield sells it at **2K only**, at the same rate fal charges at 2K, so the platforms
match there; below 2K there is no second platform to compare. The upscaler is still the one
stage where only the fal endpoint is published. The price
check runs across providers for that stage BEFORE a paid run
(`provider-price-comparison.md`), and a binding that names a provider with no key configured is
not a valid binding — say so instead of silently falling back.

### The video stage is also a LANE choice (`video_lanes` in the registry)

The video stage carries a second decision the owner makes, once per batch:

| Lane | Profiles | Clips | Rate (list) | Refs |
|---|---|---|---|---|
| **Premium** | `seedance-25` (default) | 4–30s | US$0.5676/s @720p fal · US$0.4622/s @720p Higgsfield (≈US$2.84 / US$2.31 per 5s) | up to 30 image refs; image and audio refs free |
| **Budget** | `h3-reference-video` (cheaper tier), `h3-max-reference-video` (upper tier) | 5–15s, **5-second minimum** | US$0.06/s (`h3`) · US$0.08/s (`h3-max`) @768p (US$0.30 / US$0.40 per 5s) | first 5 reference images free, then ~US$0.08 each (`h3`) or ~US$0.02 per 2048px image (`h3-max`) |

- **A 3s or 4s shot cannot be made on the budget lane** — the 4-second floor belongs to the
  premium lane only. Plan 5–6s there, or put that one shot on the premium lane and say so.
- **Price both lanes, state the trade-off in one line, ask ONCE per batch** and hold the
  owner's choice for the project — never re-ask clip by clip.
- **List prices only:** quote the live model page each time; never quote, repeat or store a
  promo or discounted rate.
- Scale: **70 seconds of generated video for an approximately 60-second finished film** is ~US$39.73 fal / ~US$32.35 Higgsfield on the premium lane, against ~US$5.60 (`h3-max`) / ~US$4.20 (`h3`) on the budget lane — about a 7–9× spread.

## Mapping protocol — for a recognized/unknown model

1. **Confirm scope + name.** Which stage, and shot / project / global? (Named model + "this
   touches N files: …".)
2. **Gather, cheapest first:**
   a. `genmedia run <model-id> --help` (fal's own param registry — local + free)
   b. the fal.ai model page
   c. the provider's dev page.
   **Provider/search steps are permission-gated** (may burn Firecrawl/gateway credits); prefer
   `curl` for known URLs. If the owner asks you to search the web for prompt structure, ask first.
3. **Extract a provisional profile:** prompt structure, params, native dims/AR, whether a frame
   pair is required, cost/quality tiers, documented quality dialect.
4. **Re-verify layout METHOD** — 3/4-panel conventions stay pipeline-owned, but the *method*
   (one-shot multi-panel vs hero+edit) must be checked against the new model's capabilities.
5. **Quality dialect is PROVISIONAL, not inherited.** Do NOT copy an existing model's
   "camera/lens beats photorealistic" finding into a new model (the current GPT Image 2.5
   Sunburst profile carries the GPT Image 2 family's dialect as an unverified carry-over —
   smoke-test it before a batch leans on it). If docs are silent, run a **one-shot smoke
   test** (cheapest tier) to confirm dialect + dims before any batch.
6. **Verify gate (mandatory).** Confirm prompt structure + dims against official docs, run the
   smoke test, report its cost, get approval before a real batch.
7. **Append the profile** (dated, source URLs, verified-by) under the matching stage in
   `model-registry.yaml`, then set scope. **After** the smoke test passes — not before the batch.

## Agent↔owner workflow (the journey)

**Principle: the studio (FAB) REVIEWS + collects feedback; the CHAT session orchestrates
generation** (skills, FAL key, cost quoting, registry). Generation is never triggered from the FAB
(the feedback watcher is deliberately read-only). When the owner hits "generate" in the FAB,
redirect them to the chat session.

**Invocation:** `/ai-film-pipeline` + an idea. Loads the pipeline + scriptwriting skills, switches
to production mode. (Also auto-loads on film intent voiced in plain language.)

```
1. SESSION START      /ai-film-pipeline + idea → clarify (plain prose). No generation.
2. CREATE PROJECT     summarize plan → seek approval to create the project AND state the initial
                       model binding (global defaults or a project override) + a first cost
                       estimate for the reference-image stage. On approval, create it. Owner
                       reviews assets + shot pages, gives feedback in the studio.
3. REFERENCE IMAGES   (a) FAB "generate assets" → redirect to chat.
                      (b) In chat: RESOLVE SCOPE → present stage's current primary (+ registry
                          alternatives) → LIVE cost quote on EVERY configured provider
                          (fal.ai + Higgsfield) → seek approval.
                          · approved → small smoke test if new/unmapped → batch → upload to assets
                            page → report actual cost.
                          · alternative named → MAPPING PROTOCOL → amended prompt to assets page →
                            owner verifies/edits prompt → approve → smoke ONE → batch → promote
                            profile to mapped + append.
                          · post-round change (images not up to quality) → same alternative branch.
4. FIRST FRAMES       first check: all reference assets approved? Then same shape (scope → quote →
                       approve/test/alternative). Keyframe reads VIDEO binding for dims/frame-pair.
                       Owner may opt to generate the first 3 frames as a test.
5. VIDEO CLIPS        first check: all first frames approved? Then **LANE CHOICE FIRST** — price
                       both lanes (premium Seedance 2.5 vs budget MiniMax H3 family), state the
                       trade-off in one line, ask ONCE for the batch and remember the answer for
                       the project; the budget lane's 5-second minimum rules out 3s/4s shots.
                       Then same shape (scope → quote → approve/test). If video mixing, FLAG
                       a dominant spec (look-consistency risk); re-edge rescue shots if the owner
                       wants a uniform look.
6. MASTER             clarify 1080p vs 4K → first check: all clips approved? → cost quote → upscale
                       → save to master folder → report done + cost + per-shot model provenance.
```

### The generate-approval loop (compressed rule)
`RESOLVE SCOPE` → (alternative named → MAPPING PROTOCOL) → `LIVE COST QUOTE` → `SEEK APPROVAL`
(never start a paid batch without an explicit yes) → `GENERATE + PROVENANCE` → `report actual cost`.

**"Go generate" is not approval — the quote is the gate.** When the owner
says "go" or "yes, generate" after an earlier step, that is NOT authorization
for a paid batch: reply with the exact scope and the live cost estimate and
WAIT for an explicit yes to that specific quote. Never announce a batch and
its cost in the same message as launching it.

## Governance

- **Append, never override.** A model is added once, selected by scope. The global default row is
  frozen unless the owner names a model.
- **Post-round model change is a first-class branch**, not an edge case — it is the escape hatch
  (e.g. "this clip costs too much on Seedance — regenerate it on the H3 budget lane", or the
  reverse). Always through scope → quote → approval.
- **Cost basis in the registry is guidance only.** ALWAYS `genmedia pricing <id>` live before
  quoting the owner.
- **Audit trail:** every mapping append is recorded (dated, source URLs, verified-by).