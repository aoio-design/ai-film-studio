# fal.ai Ops Skill — generating images, video and masters via the fal API

*Use when: generating any media for the owner's films — reference images,
first-frame keyframes, video clips, or 4K masters — through the owner's fal.ai
account (and their Higgsfield account, when it is configured). There is no GPU
to rent, no pod to start or stop: generation is a paid API call that returns
finished files.*

> **By-hand fallbacks** (where the key belongs on disk, how to re-check it) are in
> `references/manual-fallbacks.md`. Before quoting anything, price every configured
> provider with live rates: `references/provider-price-comparison.md`.
>
> **A second provider may be configured: Higgsfield** (`HIGGSFIELD_API_KEY`, in the same
> `.env`, added by the owner through the app's workspace panel exactly like `FAL_KEY`).
> Check it the same way you check `FAL_KEY` and include it in every price comparison —
> it carries the **same** image model as fal (at OpenAI's own token rates, so images
> normally price identically on both providers) and the **same** premium video model
> (Seedance 2.5, about 19% cheaper at 720p). The budget lane's MiniMax H3 family it sells
> at **2K only**, at the same rate fal charges at 2K — so the platforms match there, and
> below 2K only fal.ai sells it. Where it cannot run a stage, say that plainly instead
> of quoting a number.

## Higgsfield API — the second host

- Base URL: `https://api.higgsfield.ai`. The console copies **one combined
  credential** — paste it into the auth header exactly as copied. Do not split it,
  rebuild it from parts, or paste it anywhere but the header.
- **Submit → poll → download.** Submit a job to the model's path, poll the status URL
  the submit call returns until the job has finished, then download the result.
- A brand-new account runs **2 jobs at once**; more concurrency unlocks once about
  US$25 has been funded. On a busy batch, submit in small waves rather than all at once.
- Generated files stay available for **at least 7 days** — pull finished media into the
  owner's studio promptly; never leave the only copy of a clip on the provider.

## The account and the key

- The owner has a **fal.ai** account (prepaid credits) and an **API key**
  stored as **`FAL_KEY`** in your environment file on the server — the owner adds
  it there from hpanel (Docker Manager → the project → **Manage** → the `.yaml`
  editor → add `FAL_KEY` to the `hermes-agent` service's `environment:` → **Update**),
  or, if they prefer, in `$HERMES_HOME/.env` through the app's file browser — that
  file sits in a dot-folder, so the workspace must be switched to the agent's home
  path and "Show hidden files" switched on first (guide Ch4 §4.4). Never ask for the
  key in chat. **Do not send the owner into the app's file browser for this, and do not
  quote your own `$HERMES_HOME` path to them:** the app runs in a different container and
  sees the same folder under a different path, so a path that is correct for you will
  not exist for them.
  **fal is not an LLM provider, so it never appears on the app's Providers page —
  if the owner says it isn't there, that is correct, not a bug.** Confirm it with:
  ```bash
  echo ${FAL_KEY:+FAL_KEY is set}
  ```
  If it prints nothing, read `$HERMES_HOME/.env` yourself and report what you find
  (never ask the owner to paste the key into chat — tell them the steps in guide
  Ch4 §4.4 instead).
  If the line is missing, tell the owner to add `FAL_KEY=…` to that file in
  their Hermes app (guide Chapter 4, Section 4.4) — **never** ask them to
  paste the key in chat.
- **Never print, log, or echo the key itself.** Secrets live in the
  environment; `echo $FAL_KEY` is for the *presence* check above only.

## The tool: genmedia (fal's CLI for agents)

Install once (the guide's Chapter 4, Section 4.5 has the owner-facing
instructions; if it's missing here, install it):

```bash
curl https://genmedia.sh/install -fsS | bash
export PATH="$HOME/.genmedia/bin:$PATH"
```

Verify the connection: `genmedia models seedance --limit 3` — a list with no
error means the key works. To see any model's exact flags:
`genmedia run <model-id> --help`.

## The models (guide stack, 2026)

| Job | Model | Default settings |
|---|---|---|
| Character reference sheets | `openai/gpt-image-2.5/sunburst/edit` | Style Reference in `--image_urls`, `--image_size '{"width":1536,"height":1024}'`, `--quality high`, `--output_format png` (~US$0.04) |
| Location & prop reference images | `openai/gpt-image-2.5/sunburst/edit` | Style Reference in `--image_urls`, `--image_size '{"width":1536,"height":864}'` (prop `'{"width":1024,"height":768}'`), `--quality medium`, `--output_format png` (~US$0.01) |
| Edits to an existing asset image | `openai/gpt-image-2.5/sunburst/edit` | upload that image → `--image_urls '["<style_ref_cdn>","<cdn>"]'`, single image at the asset's AR (character 1536×1024 / location 1536×864 / prop 1024×768), quality tier follows the asset |
| First-frame edits (keyframes) | `openai/gpt-image-2.5/sunburst/edit` | `--image_urls '["<style_ref>","<sheet(s)>","<location>"]'` (order matters), `--image_size '{"width":2048,"height":1152}'` (16:9; vertical 9:16 → `'{"width":1152,"height":2048}'`), `--quality high` (~US$0.045) |
| Reference voices (per character, once) | `fal-ai/elevenlabs/tts/eleven-v3` | 7-second line per character (~US$0.01); saved as `<season>_<CharacterName>_Audio_Reference_v1.wav` |
| Video clips — PREMIUM lane (sound + cloned voice) | fal: `bytedance/seedance-2.5/us/reference-to-video` · Higgsfield: `bytedance/seedance-2.5/reference-to-video` | `--image_urls <first frame, then char sheets>` `--audio_urls <speaker's voice wav>`, `--resolution 720p`, `--duration 5`, `--aspect_ratio 16:9`, `--generate_audio true` (~US$0.57/s at 720p on fal, ~US$0.46/s on Higgsfield) — full parameter list below |
| Video clips — BUDGET lane, cheaper tier | fal: `minimax/h3/reference-to-video` | 768p canvas, `--duration 5…15` (**5-second minimum**), refs named by list order (`Image 1`, `Audio 1`…); ~US$0.06/s (≈US$0.30 per 5s); first 5 reference images free, then ~US$0.08 each |
| Video clips — BUDGET lane, upper tier | fal: `minimax/h3-max/reference-to-video` · Higgsfield (2K only, ~US$0.13/s — fal's own 2K rate, so the platforms match) | 768p canvas, `--duration 5…15` (**5-second minimum**); ~US$0.08/s (≈US$0.40 per 5s); first 5 reference images free, then ~US$0.02 per 2048px image |
| Upscaler (masters) | `fal-ai/bytedance-upscaler/upscale/video` | `--target_resolution 4k`, `--enhancement_preset aigc`, `--target_fps 24` |

### Reference image — character sheet, location, prop (GPT Image 2.5 Sunburst)

```bash
genmedia upload $HERMES_HOME/studio/assets/<season>/<style-ref>/<look>.png   # the approved look
genmedia run openai/gpt-image-2.5/sunburst/edit \
  --prompt "<structured prompt — see templates below>" \
  --image_urls '["<style_ref_cdn>"]' \
  --image_size '{"width":1536,"height":1024}' --quality high --output_format png --download
```

**Always the edit variant — never text-to-image.** The text-to-image variant of this
model accepts no reference images at all, and every request must carry the project's
approved Style Reference (plus, once that character exists, their approved sheet), so
`openai/gpt-image-2.5/sunburst/edit` is the model for EVERY image this pipeline makes.
`image_urls` is required, not optional, and the order is fixed: **Style Reference
first, then the character sheet(s), then location/prop stills.**

**Structured prompt format:** `Scene:` / `Subject:` / `Important details:` / `Use case:` / `Constraints:`
**Character sheet (three-panel, landscape, ONE face):** plain neutral gray (#e0e0e0) backdrop, equal-width 3-panel horizontal sheet: Panel 1 face+shoulders close-up (front, neutral), Panel 2 full-body front (A-pose), Panel 3 full-body back (same pose as center); landscape 1536x1024. Use photographic vocabulary (full-frame DSLR 85mm f/2.8, soft three-point studio light, visible skin texture/pores, individual hair strands, real materials). Describe the character as realistic and unpolished — "avoid conventionally polished or symmetrical features". Do NOT include text labels, watermarks, inconsistent proportions, or background props.
**Location:** **4-panel sheet, 16:9 landscape** — wide establishing + alternate wide (~90°) + corner depth + detail shot; locked lighting/time-of-day, no people, environment only. (Full writing structure: `references/bible-and-asset-writing.md`.)
**Prop:** **4-panel grid, neutral gray (#e0e0e0)** — front + side (90°) + back + close-up detail; studio lighting, no cast shadows, consistent scale, no text labels.

### First-frame edit (keyframes) — GPT Image 2.5 Sunburst edit

Upload the owner's reference images first (Style Reference, then the character sheets, then
the location stills), then reference them by URL:

```bash
genmedia upload $HERMES_HOME/studio/assets/<season>/<style-ref>/<look>.png
genmedia upload $HERMES_HOME/studio/assets/<season>/<asset>/<file>.png
# → prints a cdn_url like https://v3b.fal.media/files/b/...
genmedia run openai/gpt-image-2.5/sunburst/edit \
  --prompt "<composition prompt: put the character from reference 2 into the setting from reference 3…>" \
  --image_urls '["<style_cdn>","<sheet_cdn>","<location_cdn>"]' --image_size '{"width":2048,"height":1152}' --quality high --output_format png --download
```

Render keyframes at the project's shape — **2048×1152** for 16:9, **1152×2048** for a
vertical 9:16 project (tell your agent "this is a vertical 9:16 project" when you start) —
and pass `--aspect_ratio 9:16` on the clips. The frame is supersampled above the clip's
resolution so the video model downsamples clean detail.

**Sizes:** both edges of any `image_size` must be multiples of 16 (max edge 3840, aspect
ratio up to 3:1, 655,360–8,294,400 pixels in total). An invalid pair is **snapped
silently, not rejected** — a request for 1920×1080 comes back 1920×1072 with no error —
so use the sizes above rather than inventing one. `image_urls` takes up to 16 refs;
optional `mask_url`: white = editable, black = preserved. Character sheets, location and
prop images are always landscape — only keyframes follow the project's shape.

### Asset image edit (rework an EXISTING reference image)
When the owner points at an image they can already see and asks for a change ("extract the top-left panel and go wider", "re-light this one"), EDIT that image — upload it, pass it as `--image_urls '["<style_ref_cdn>","<cdn>"]'` (the Style Reference still rides along), and say what the image shows + the ONE change. **Never re-run the whole-sheet text prompt for an image-driven change.** Deliver a SINGLE image at the asset's AR and quality tier (character 1536×1024 high / location 1536×864 medium / prop 1024×768 medium), saved under a NEW versioned filename — the old take stays until the owner stars the new one. If instead the owner changed the *words* (edited the card's description/prompt), that IS a whole-sheet re-run from the amended prompt. Quote both providers' prices before running.

### Reference voice (per character — generate once, reuse on every clip)

Before clips: one short voice reference per speaking character.

```bash
genmedia run fal-ai/elevenlabs/tts/eleven-v3 \
  --text "<one neutral ~7s line in the character's voice>" \
  --voice "<voice preset or clone id — picked with the owner>" --download
```

~US$0.01 per character (US$0.10 per 1,000 chars). The character's asset card carries a **Reference Voice Prompt**; the same saved file is uploaded as `@Audio1` on every clip where that character speaks.

### Video clip — the TWO LANES, then the parameters

**One lane choice per batch, before anything is generated.** Price the same shots on
both lanes, state the trade-off in one line, ask the owner ONCE, and remember their
choice for the project — never re-ask per clip:

- **Premium lane — Seedance 2.5 reference-to-video** (this section): native audio +
  lip-sync in one pass, clips **4–30s**, up to **30 image refs**, image and audio refs
  at no extra cost. ~US$0.57/s at 720p on fal (≈US$2.84 per 5s), ~US$0.46/s on
  Higgsfield (≈US$2.31 per 5s — about 19% cheaper at 720p, 22% at 480p).
- **Budget lane — the MiniMax H3 family** (own subsection below): `minimax/h3`
  ~US$0.06/s and `minimax/h3-max` ~US$0.08/s at 768p (≈US$0.30 / US$0.40 per 5s).
  Clips **5–15s with a 5-second minimum**, so a **3s or 4s shot cannot be made on this
  lane** — the 4-second floor belongs to the premium lane.

Across a 70-second film the two lanes are roughly **7–9× apart** (~US$32–40 premium vs
~US$4–6 budget) — the biggest single cost decision in the production. **List prices only:
quote the live model page, never a promo or discounted rate.**

#### Premium lane — Seedance 2.5 reference-to-video

Everything goes in **one request** — the keyframe first (named `@Image1` in the prompt),
then the character sheets of everyone on screen (`@Image2`, `@Image3`…), then the speaker's
voice reference (`@Audio1`). The model reads the **names you write in the prompt**, not the
list order, so name every upload in the prompt text.

```bash
genmedia upload $HERMES_HOME/studio/shots/<film>/<shot>/<film>_<shot>_v1.png
genmedia upload $HERMES_HOME/studio/assets/<season>/<char>/<sheet>.png
genmedia upload $HERMES_HOME/studio/assets/<season>/<char>/<char>_Audio_Reference_v1.wav
# → three cdn_urls
genmedia run bytedance/seedance-2.5/us/reference-to-video \
  --prompt "@Image1 is the first frame — the shot opens on this exact composition: match its framing, blocking and lighting. @Image2 is <Char>'s identity reference — preserve the face, hair, build and outfit exactly; <Char> is the speaker. @Audio1 is <Char>'s voice reference — the line is delivered in this voice. <scene + action + camera + soundscape> <Char> says, <delivery>: \"<line>\"" \
  --image_urls '["<keyframe_cdn>","<sheet_cdn>"]' \
  --audio_urls "<voice_cdn>" \
  --resolution 720p --duration 5 --aspect_ratio 16:9 --generate_audio true --download
```

Swap the model id for Higgsfield's `bytedance/seedance-2.5/reference-to-video` to run the
same job on the other host (quote both first — see the spending rule). Flags are the
model's own parameter names; `genmedia run <model-id> --help` prints the exact spelling.

Parameters worth setting every time:

| Parameter | What to pass |
|---|---|
| `prompt` | required — the whole shot: the named references, the action as consecutive stages or a timed shot list, dialogue in quotes, the soundscape |
| `image_urls` | up to 30, named `@Image1`, `@Image2`… in the prompt. The first frame first. **No extra cost.** |
| `video_urls` | up to 10 (`@Video1`…). Only when a shot genuinely needs a motion reference — supplying video inputs bills at 0.6× the per-second rate |
| `audio_urls` | up to 10 (`@Audio1`…), the speaker's saved voice reference. Needs at least one image or video reference alongside it. **No extra cost.** |
| `resolution` | `480p` / `720p` / `1080p`, default `720p` |
| `duration` | 4–30 whole seconds, or `auto`. Minimum 4s |
| `aspect_ratio` | always pass the project's ratio explicitly — `16:9`, `9:16`, `1:1`, `4:3`, `3:4`, `21:9`. The default is `auto`; never leave it there |
| `generate_audio` | `true` by default — native ambience, effects and lip-synced speech at no extra cost |
| `task` | `reference` (default) / `editing` / `extension` |
| `seed` | set it to reproduce a take you liked |

Hard limits: **50 files in total** across images, video and audio; each audio file
1.8–30.2 seconds, and at most 30.2 seconds of audio combined. **Image and audio references
cost nothing extra on this model** — you pay for the clip's seconds (plus any video input).

Rules:

- **Minimum clip length on this lane is 4 whole seconds** (maximum 30) and the practical shot length is 5–6s (the plan's range is 5–30s — 5s is the minimum precisely because the budget lane cannot go below it). The budget lane's floor is 5s — a 3s or 4s shot exists only here, on the premium lane.
- **AR is explicit per project** — 16:9 in this Guide (pass `--aspect_ratio`; vertical-shorts projects use 9:16, keyframes 1152×2048).
- **One speaker per clip, lines ≤ 5 seconds.** Multi-speaker exchanges are generated as separate clips (shot/reverse-shot); a multi-speaker clip is a legitimate experiment on this model, not the default.
- **Voice consistency across shots = the same Audio ref file** every time that character speaks.
- **The first frame already carries the setting** — no location sheet at the clip stage.
- Dialogue goes inside the prompt in quotes with a delivery tone
  (`NOVA says: "It's everything." — tired, flat, quiet`), matched to the
  voice reference. The clip comes back with the voice and room sound baked in —
  there are no separate audio files.

#### Budget lane — the MiniMax H3 family (two tiers)

`minimax/h3` (~US$0.06/s at 768p, ≈US$0.30 per 5s) and `minimax/h3-max`
(~US$0.08/s at 768p, ≈US$0.40 per 5s) run the same shots for a fraction of the
premium lane's price. What changes:

- **Clips are 5–15 seconds and the floor is a hard 5 seconds** — there is no way to
  make a 3s or 4s shot on this lane. If a beat needs 4 seconds, either plan it as 5–6s
  or put that one shot on the premium lane (and say so in the quote).
- **It is fal.ai's lane below 2K.** Higgsfield sells the H3 family at **2K only**, at
  about US$0.13/s — the same rate fal charges at 2K, so the platforms match there and
  there is no saving to name; below 2K only fal.ai sells it, so say that instead of
  quoting a two-row comparison.
- **768p canvas** (1344×768 @ 24 fps) against the premium lane's 480p/720p/1080p.
- **References are billed on this lane** (the premium lane's are free): the first **5
  reference images are free**, then about US$0.08 each on the cheaper tier, or about
  US$0.02 per 2048px image on the upper tier. Keep the reference set tight — a keyframe
  plus the sheets that are actually on screen.
- **References are named by upload list order** (`Image 1`, `Image 2`, `Audio 1`…) on
  this family, not by `@Image1`/`@Audio1` handles — never let one family's prompt
  conventions leak into the other. Prompt formats and per-model details: the registry
  and routing files under `references/`.
- **Quote the model id live before the batch** — `genmedia models minimax --limit 5` or
  `genmedia run <model-id> --help` prints the provider's exact slug and flags.

### 4K master (approved clip → upscaled)

```bash
genmedia upload $HERMES_HOME/studio/shots/<film>/<shot>/<film>_<shot>_v1.mp4
genmedia run fal-ai/bytedance-upscaler/upscale/video \
  --video_url "<cdn_url>" \
  --target_resolution 4k --enhancement_preset aigc --target_fps 24 --download
```

(`--target_resolution 1080p` is the cheaper social option; 4K is the master
the owner stores in `$HERMES_HOME/studio/masters/<film>/`. `--target_fps 24`
matches the video model's 24 fps clips — the upscaler defaults to 30 fps and would
otherwise re-time them.)

## The spending rule — the price gate (MANDATORY — never break this)

Generation costs the owner real money **per successful output** (roughly
US$0.04 per character sheet at high quality, US$0.01 per location or prop at
medium, US$0.045 per first frame at high, ~US$0.01 per character for the
one-time voice reference, ~US$2.31–2.84 per 5-second clip at 720p on the premium
lane depending on host, ~US$0.30–0.40 per 5-second clip at 768p on the budget
lane, ~US$0.14 per 4K upscale — these figures are orientation only; check
`genmedia pricing <model-id>` for live rates and quote what you read).

- **Quote BOTH providers, then wait — before every image and every video.** Look up the
  current price on fal.ai and on Higgsfield for that exact job, show both numbers, name
  the cheaper one and say why, then WAIT for approval. Never generate on an unquoted
  price. Say plainly when the two come out equal — **for images they normally do**
  (Higgsfield carries the same image model at OpenAI's own token rates); the clip stage is
  where they differ (about 19% cheaper on Higgsfield at 720p). On the **clip stage** there
  is a second comparison on top of the platforms — two model LANES (below).
- **Compare the two video LANES, then let the owner choose — once per batch.** Price the
  same shots on the **premium lane** (Seedance 2.5: ~US$0.57/s at 720p on fal, ~US$0.46/s
  on Higgsfield, 4–30s clips, refs free) and the **budget lane** (MiniMax H3 family:
  `minimax/h3` ~US$0.06/s, `minimax/h3-max` ~US$0.08/s at 768p, **5-second minimum** — no
  3s or 4s shots). State the trade-off in one line, ask ONCE, and hold the answer for the
  project. Where both platforms sell the model you are quoting, compare both platform
  prices too: Higgsfield sells the H3 family at **2K only** at fal's own 2K rate (~US$0.13/s,
  so the platforms match), and below 2K only fal.ai sells it. Scale: a 70-second film's
  video is ~US$39.73 fal / ~US$32.35 Higgsfield on the premium lane against ~US$5.60
  (`h3-max`) / ~US$4.20 (`h3`) on the budget lane — a 7–9× spread.
- **LIST PRICES ONLY.** Quote the live model page (or `genmedia pricing <model-id>`) every
  time. A promo or discounted rate must never be quoted, repeated or stored anywhere.
- **Never start a paid batch without asking first.** Message the owner on
  Telegram or WhatsApp: *"Shall I generate the [N] shots now? It'll cost
  about US$X."* Wait for a yes. Regenerating a single bad shot from review
  feedback is fine to confirm the same way ("re-roll shot 4? ~US$2.31 on Higgsfield").
- **Quote the cost, then get an explicit yes — even when the owner says
  "go generate".** "Go" or "yes" to an earlier step is NOT approval for a
  paid batch: state the exact scope and estimated cost and WAIT for an
  explicit yes to that message. Never announce a batch and its cost in the
  same message as launching it — the quote comes first, on its own.
- **Check the balance before a batch.** If you can't confirm credit is
  available (the owner's fal dashboard), warn them to top up — a request with
  no credit simply waits, and you should say why.
- **Report the actual cost when a batch finishes** ("12 clips + 2 upscales:
  ~US$5.20"). Batch work: collect everything that needs generating and run it
  in one go — don't ask twice for the same batch.
- **Only successful outputs are billed** — failed requests and queue time are
  free, so a re-roll costs one clip, not a session.

## Verification (before you tell the owner anything is ready)

1. Every `genmedia run … --download` writes the output file(s) locally; check
   they exist and are non-trivial in size (an image ≥ ~100 KB; a 5-second
   clip several MB).
2. Play/check the clip briefly if possible (ffprobe or similar), confirm it's
   an MP4 with audio, then copy it into the studio folder under its
   descriptive versioned name (the studio-ops skill's naming standard) —
   never a bare `image.png`/`video.mp4`, and never overwrite an existing file.
3. Only then tell the owner what is ready to review. Never claim a
   generation succeeded without the downloaded file on disk.

## Failure → action

| Symptom | Action |
|---|---|
| `FAL_KEY is set` prints nothing | Key not in your environment — read `$HERMES_HOME/.env`; if the line is missing, tell the owner to add `FAL_KEY=…` to it via the app's file browser (guide Ch4 §4.4). If the line IS there, ask them to restart the app so you pick it up. Stop. |
| `401 Unauthorized` / `403` | Key wrong or scope not **API** — ask the owner to check the key on fal.ai. |
| `429` or queue waits long | Platform is busy or out of credit — check the balance; wait and retry, or ask the owner to top up. |
| Model error in the response | Re-read `genmedia run <model> --help`, fix the parameter, retry. One retry, then report. |
| Output file missing/empty after `--download` | The request may have failed — check the JSON output for an error before assuming success. |
| Higgsfield job stays queued / `429` | The account's concurrency limit (a new account runs 2 jobs at once; more once about US$25 is funded) — submit fewer jobs per wave, keep polling the status URL, and don't resubmit the same job. |
| A Higgsfield download has expired | Generated files stay available about 7 days — re-run the job, then pull the file into the studio immediately. |

## No teardown

There is no pod to stop, no volume to lose, no hourly meter. When a batch is
done, copy everything to the owner's VPS (`shots/…` for review copies,
`$HERMES_HOME/studio/masters/<film>/` for approved 4K masters), verify the
copies, and report the cost. Done.
