---
name: seedance
description: "Prompt dialect for the PREMIUM video lane — Seedance 2.5 reference-to-video: naming every upload as @Image1/@Image2/@Audio1, consecutive stages or a timed shot list, dialogue in quotes with a delivery tone, native audio and lip-sync, the full parameter set, host pricing, and the lane-choice rule."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [film, prompts, video, seedance, seedance-2-5, premium-lane, fal-ai, higgsfield, reference-to-video]
    related_skills: [minimax-h3-prompting, ai-film-prompt-engineering, ai-film-keyframe-authoring, fal-ai-ops, ai-film-pipeline]
---

# Seedance 2.5 Video Prompting (the premium lane)

*Use when: the batch is running on the PREMIUM video lane — Seedance 2.5
reference-to-video — and you are writing the prompt for a clip. Read this
before writing anything, and read `minimax-h3-prompting` if the batch is on the
budget lane: the two prompt dialects are different, and neither one's
conventions may leak into the other.*

## What the premium lane is

One model, two hosts, a prompt that carries **named references**, and native
audio — lip-synced speech, effects and ambience — generated with the clip in a
single pass. That last part is what the price buys: there is no separate audio
stage, no voice-cloning pass, no lip-sync tool.

| | |
|---|---|
| Model | Seedance 2.5 reference-to-video — fal: `bytedance/seedance-2.5/us/reference-to-video` · Higgsfield: `bytedance/seedance-2.5/reference-to-video` |
| Clip length | **4–30 whole seconds** (or `auto`) — a 3s or 4s shot exists only on this lane |
| References | up to **30 images** + **10 videos** + **10 audios**, 50 files in total; **image and audio references cost nothing extra** |
| Audio | native, on by default |
| Plan for | **5–6s coverage** per shot; the shot plan runs 5–30s |

### Prices (list)

| Host | 480p | 720p | 1080p |
|---|---|---|---|
| fal | US$0.2646/s | **US$0.5676/s** | US$1.396278/s |
| Higgsfield | US$0.2056/s | **US$0.4622/s** | US$1.1372/s |

- A 5-second 720p clip is ≈ **US$2.84 on fal** or ≈ **US$2.31 on Higgsfield** —
  roughly 19% cheaper at 720p and 22% at 480p.
- **fal bills at 0.6× the per-second rate when video inputs are supplied** — an
  attached `@Video1` is cheaper than the headline rate, not more expensive.
- **Quote the live model page on both hosts before every batch, name the cheaper
  one, and wait for a yes.** List prices only: a promo or discounted rate is
  never quoted, repeated or stored, and no batch starts on an unquoted price.
- 720p is the working resolution; 1080p costs roughly 2.5× the 720p rate, and
  masters come from the upscaler stage rather than a bigger raster here.

### The lane choice — ask ONCE per batch

This lane competes with the budget lane (the MiniMax H3 family). Price **both**
lanes at this project's resolution and clip length, state the trade-off in one
line, ask **once**, and hold the answer for the project — never re-ask per clip.

| Lane | 5s clip @720p/768p | What it trades |
|---|---|---|
| **Premium — Seedance 2.5** | ≈US$2.84 fal · ≈US$2.31 Higgsfield | 4–30s clips, up to 30 image refs, refs free, native audio + lip-sync |
| **Budget — `minimax/h3`** | ≈US$0.30 | 5–15s with a **5-second floor**, 15s cap, refs billed past the first 5 |
| **Budget — `minimax/h3-max`** | ≈US$0.40 | as above |

For **70 seconds of generated video in an approximately 60-second finished film**, the two lanes are roughly **7–9× apart**. A 3s or 4s beat is the one thing that forces the premium lane.

## Parameters

| Parameter | What to pass |
|---|---|
| `prompt` | **required.** The whole shot — named references, the action, dialogue, soundscape. |
| `task` | `reference` (default) · `editing` · `extension` |
| `image_urls` | up to **30**, named `@Image1`, `@Image2`, … inside the prompt. First frame first. No extra cost. |
| `video_urls` | up to **10** (`@Video1`, …) — only when a shot genuinely needs a motion reference |
| `audio_urls` | up to **10** (`@Audio1`, …). Each file 1.8–30.2s, and **at most 30.2s combined**; supplying audio requires at least one image or video reference. No extra cost. |
| `resolution` | `480p` / `720p` / `1080p`, default `720p` |
| `duration` | 4–30 **whole** seconds, or `auto` (default `auto`) |
| `aspect_ratio` | `16:9` · `9:16` · `1:1` · `4:3` · `3:4` · `21:9`. **Always pass the project's ratio explicitly** — the default is `auto`, and `auto` is not a substitute for a decision |
| `generate_audio` | `true` by default — ambience, effects and lip-synced speech at the same price either way |
| `seed` | set it to reproduce a take the owner liked |
| `bitrate_mode` · `codec` · `end_user_id` | available; leave at defaults unless there is a reason not to |

Hard limits: **50 files in total** across all modalities, and images up to
**30 MB** each.

## The prompt

### 1. Name every upload inside the prompt text

The model reads the **names you write in the prompt**, not the order you listed
the files. **Give every reference an explicit job in the sentence that uses
it.**

- `@Image1` — the shot's first frame (the keyframe). Say that it is.
- `@Image2`, `@Image3`, … — the character sheet of each person on screen, one
  each, called by name in the action.
- `@Audio1` — the speaker's voice reference. **The voice is cloned from this
  file**, so use the same saved file for that character on every clip.
- `@Video1`, … — an attached clip whose motion or camera you want followed.

```text
@Image1 is the first frame — the shot opens on this exact composition; match its
framing, blocking and lighting. @Image2 is DANA's identity reference — preserve her
face, hair, build and outfit; DANA is the speaker. @Audio1 is DANA's voice
reference — the line is delivered in this voice.
```

`Image 1` / `Audio 1` list-order citing is the **budget lane's** convention, not
this one — write `@Image1` / `@Audio1` here.

### 2. Write the action as stages, or as a timed shot list

**Consecutive stages** — one primary change per stage, and what is on screen
when the stage ends:

```text
Stage 1: DANA sets the folded letter flat on the counter and looks up. Stage 2:
she takes half a step back as the door opens behind her — by then she is facing
the door and the letter is behind her.
```

**Or a timed shot list** — consecutive, non-overlapping ranges:

```text
0-2.5s: DANA sets the letter down and looks up. 2.5-5s: she turns as the door
opens behind her.
```

A timestamp **allocates an event its share of the running time**; it is **not a
frame-accurate cut**. Don't pack more action into a range than there is time to
execute.

### 3. Dialogue in quotes, with a delivery tone

The model speaks the line and syncs the lips. Quote the words and give the
delivery:

```text
Slow push-in over her shoulder. DANA says: "It's everything. The whole ledger."
— tired, flat, quiet. Low cafe murmur, a cup settling, footsteps on a wooden floor.
```

- **Two speakers per clip are allowed and lines have no length cap** — the
  one-speaker / ≤5s rule was retired in Oct 2026. A two-hander clip is the untested
  part: the model advertises multi-character voice retention, so A/B the first one
  and review the voices before building on it.
- **Voice consistency across shots = the same saved Audio reference file** every
  time that character speaks.
- Exact quoted text beats paraphrase; a strong identity reference on `@Image2`
  gives the model a consistent mouth to animate; close-ups lip-sync better than
  wides.

### 4. Soundscape — always state it

Say what the scene sounds like, even for a near-silent one: room tone, ambient
cues, effects. Audio comes back with the clip at no extra cost
(`generate_audio` is on by default); only switch it off if the owner asked for a
silent master, and if you do, say so in the quote.

### 5. Keep the moves simple

The model is excellent at subtle moves and poor at stunt choreography. A slow
push-in, a small handheld float, a slow pan — all fine. A dolly zoom with an
orbit and a chair spin will look broken.

### 6. The keyframe carries the setting

The first frame already holds the location, look and lighting — that is why
there is no location plate at the clip stage. The clip prompt owns motion, time
and dialogue; the keyframe prompt owns the frozen moment (see
`ai-film-keyframe-authoring`). Camera framing, lens and movement vocabulary is
shared across the pack (`ai-film-prompt-engineering`,
`ai-film-cinematography`).

### 7. One worked prompt, end to end

```text
@Image1 is the first frame — the shot opens on this exact composition; match its
framing, blocking and lighting. @Image2 is DANA's identity reference — preserve her
face, hair, build and outfit; DANA is the speaker. @Audio1 is DANA's voice
reference — the line is delivered in this voice.

Stage 1: DANA sets the folded letter flat on the counter and looks up. Stage 2: she
takes half a step back as the door opens behind her — by then she is facing the door
and the letter is behind her.

Slow push-in over her shoulder. DANA says: "It's everything. The whole ledger." —
tired, flat, quiet. Low cafe murmur, a cup settling, footsteps on a wooden floor.
```

```bash
genmedia run bytedance/seedance-2.5/us/reference-to-video \
  --prompt "$(cat <this-shot>.txt)" \
  --image_urls '["<keyframe_cdn>","<sheet_cdn>"]' \
  --audio_urls '["<voice_cdn>"]' \
  --resolution 720p --duration 5 --aspect_ratio 16:9 \
  --task reference --generate_audio true --download
```

Swap the model id to `bytedance/seedance-2.5/reference-to-video` to run the same
job on Higgsfield — after quoting both hosts and getting a yes. `genmedia run
<model-id> --help` prints the exact spelling of every flag; `fal-ai-ops` has the
full command set, the quoting rule and the verification steps.

## Never break these

1. **Name every upload in the prompt text** — the model reads the names, not the
   list.
2. Each reference gets an explicit job in the sentence that uses it.
3. **Dialogue goes in quotes with a delivery tone** — one speaker or two, no length cap (one-speaker rule retired Oct 2026).
4. **Pass the aspect ratio explicitly** — never leave it on `auto`.
5. Soundscape stated in every prompt.
6. Image and audio references cost nothing extra; a video reference bills at
   0.6× — never imply otherwise in a quote.
7. `@Image1` / `@Audio1` here; `Image 1` / `Audio 1` is the budget lane's
   convention. One dialect per batch.
8. Clip length is planned per lane: 5–6s coverage, and nothing under 4s anywhere.
9. List prices only, live, both hosts, before every batch.

## Older-generation techniques you may see elsewhere

Public Seedance guides describe a previous generation of the model. If you meet
`[AUDIO: 2s] …` audio script blocks, per-second `[0-3s] …` breakdowns, JSON
prompts, "Director Mode", "Omni Reference", "Fast mode", a 15-second audio
window, "up to 9 reference images" or an APIMart price list, you are reading the
older generation — its limits and syntax are not this lane's. The craft advice
still holds where it is about *content* (overdescribe the action, describe the
audio, ground the shot in camera terms, keep references clean and few, avoid
text baked into storyboard panels), and the structural forms above are the ones
this model actually takes.

## Sources

- Seedance 2.5 reference-to-video model parameters and prompt structure, as
  published on the fal.ai and Higgsfield model pages (quote them live)
- Generation commands, costs and verification: the `fal-ai-ops` skill
- First-frame prompts for these clips: `ai-film-keyframe-authoring`
- The other lane's prompt dialect: `minimax-h3-prompting`
