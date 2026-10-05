---
name: ai-film-prompt-engineering
description: "Prompt craft for AI film production: GPT Image 2.5 Sunburst image prompts (structured, reference-image order, 3-panel landscape character sheets), Seedance 2.5 video prompts (named references, staged beats, dialogue in quotes, native sound), and the rules that keep characters consistent."
version: 4.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [film, prompts, fal-ai, higgsfield, gpt-image-2-5-sunburst, seedance, prompting]
    related_skills: [ai-film-pipeline, ai-film-keyframe-authoring, ai-film-cinematography, fal-ai-ops]
---

# AI Film Prompt Engineering (images + video, current stack)

*Use when: writing any generation prompt — image (GPT Image 2.5 Sunburst) or
video (premium lane: Seedance 2.5; budget lane: the MiniMax H3 family, 5-second
minimum). The rules below are the ones that actually move quality.*

## The non-negotiable rules

1. **Never put metadata in a prompt.** No "key prop — appears in Ep 4-6", no
   shot numbers, no production notes. Pure visual description only.
2. **Character consistency comes from references, not words.** Anchor every
   image to the approved character sheet — attach it as a reference and say
   which reference it is ("the woman from the second reference image"). Never
   re-describe a face from scratch.
3. **Physical cues, not emotions.** "jaw tightens", "eyes drop to the floor",
   "hands clench" work. The word "sad" or "confused" alone doesn't.
4. **No text, no watermark, no labels** — append to image prompts when text
   bleeding is a risk.
5. **The approved Style Reference rides on every image.** Pass the look the
   owner starred as the FIRST reference image on every image request —
   sheets, locations, props and first frames alike — and put the look in words
   too (palette, contrast, light quality, lens feel) so the images cannot
   drift apart.

## Image prompts (GPT Image 2.5 Sunburst — the edit variant)

Every image in the pipeline runs on **`openai/gpt-image-2.5/sunburst/edit`** —
character sheets, location and prop images, and each shot's first frame. That
is necessity, not preference: the text-to-image variant of this model accepts
no reference images at all, and every request must carry the project's Style
Reference. `image_urls` is therefore required (up to 16 images); `mask_url` is
optional (white = editable, black = preserved).

Reference order inside `image_urls` — the same on every image request:

1. the approved **Style Reference** (the look starred on the assets page)
2. the approved **character sheet**, when that character already exists
3. **location / prop** stills

**Sizes must be multiples of 16 on both edges** (max edge 3840, aspect ratio up
to 3:1). An invalid pair is not rejected — it is snapped silently, so a request
for 1920×1080 comes back 1920×1072 with no error. That is why the sizes below
are what they are.

The model follows a **structured prompt template** — it reasons about the
prompt and adheres strongly to long, multi-part instructions. Use this exact
shape (the model's own documented format):

```
Scene: [where this happens, time of day, background, environment]
Subject: [who or what is the main focus]
Important details: [materials, clothing, texture, lighting, camera angle, lens feel, composition, mood]
Use case: [editorial photo / product mockup / concept frame]
Constraints: [no watermark / no logos / no extra text / preserve face / preserve layout]
```

### Asset templates (full writing structure + sheet formats: `references/bible-and-asset-writing.md`)

- **Character sheet = 3-panel, landscape (1536×1024), high quality, ONE face.** Plain neutral
  gray (#e0e0e0) backdrop; equal-width panels — face+shoulders close-up,
  full-body front (A-pose), full-body back (same pose as center). Photorealism
  vocabulary (camera/lens/lighting/skin-texture/material language beats vague
  "quality" adjectives): full-frame DSLR 85mm f/2.8, soft three-point studio
  light, visible skin pores, named real materials. Avoid
  "hyperrealistic / ultra realistic / 8K / flawless". No text/labels/watermarks,
  no inconsistent proportions, no background props.
- **Location / setting:** **4-panel sheet, 16:9 landscape (1536×864), medium
  quality**, locked
  lighting/time-of-day. Wide establishing (top-left, largest) + alternate wide
  ~90° (top-right) + corner depth (bottom-left) + detail shot of a key feature
  (bottom-right). No people, environment only, consistent lighting across panels.
  Add spatial dimensions (e.g. "a room roughly 4m × 6m") to help the model
  reconcile the angles.
- **Prop:** **4-panel grid (1024×768, medium quality), neutral gray
  (#e0e0e0)**, studio lighting, no cast
  shadows, consistent scale. Front + side (90°) + back + close-up detail
  (texture/material/functional details). No hands, no scene context, no text labels.

### Keyframes (first frames — `openai/gpt-image-2.5/sunburst/edit`)

Upload the reference images as `image_urls` in the order above — approved
**Style Reference** first, then each character's sheet, then the location/prop
stills — and describe the composition ("the woman from the second reference
image, in the cafe from the third reference image"); optional `mask_url` for
surgical edits. First frames are generated at **high quality** for best clips,
at the project's shape: **2048×1152 for 16:9, 1152×2048 for a vertical 9:16
project** (both edges multiples of 16).

> **ALTERNATIVES — never delete them, never use them by default:** the **GPT
> Image 2 family** (`openai/gpt-image-2`, `openai/gpt-image-2/edit`) is the
> rollback lane, and **FLUX prompting** (natural-language Subject + Action +
> Style + Context, JSON structured prompts, `@image1`–`@image9` reference tags,
> HEX colors) is the older one. Never mix an older family's structure into a
> Sunburst prompt, and label both as alternatives when you mention them.

## Video prompts (premium lane: Seedance 2.5 — reference-to-video)

The premium lane is today's default; the **budget lane** (the MiniMax H3 family —
`minimax/h3`, `minimax/h3-max`) is the alternative, with its own prompt dialect and a
**5-second clip minimum**, so nothing here about 4-second shots applies to it. Which model
runs a given shot comes from `references/model-registry.yaml` — and before any video batch
you quote both lanes and let the owner choose (once per batch, then remembered).

Two hosts run the same model — `bytedance/seedance-2.5/us/reference-to-video`
on fal.ai and `bytedance/seedance-2.5/reference-to-video` on Higgsfield. Quote
both and let the owner choose (`fal-ai-ops`). The keyframe still sets the
scene, look and lighting; the prompt owns motion, time and dialogue.

**Name every upload inside the prompt text.** The model reads the names, not
the list order: `@Image1` is the shot's first frame (the keyframe — say so),
`@Image2`, `@Image3`… are the character sheets of everyone on screen (one each,
called by name in the action), and `@Audio1` is the speaker's voice reference —
the voice is **cloned** from it, so use the same saved file for that character
on every clip. `@Video1`… refers to any attached clips.

The body of a shot is written in one of three shapes — pick one per shot:

```
[what moves / the action] + [camera move] + [dialogue in quotes with delivery
tone] + [soundscape: room tone, ambient cues]
```

**Several beats in one shot: consecutive stages** — one primary change per
stage, and state what is on screen when the stage ends:

```
Stage 1: Nora sets the phone flat on the counter and looks up. Stage 2: she
takes half a step back as the door opens — by then she is facing the door and
the phone is behind her.
```

**Or a timed shot list** — consecutive, non-overlapping ranges:

```
0-2.5s: Nora sets the phone down and looks up. 2.5-5s: she turns as the door
opens behind her.
```

A timestamp allocates an event its share of the running time; it is not a
frame-accurate cut.

**Dialogue** goes in quotes with a tone clause — the model speaks it and
syncs the lips:

```
Slow push-in over her shoulder. DANA says: "It's everything. The whole
ledger." — tired, flat, quiet. Quiet cafe ambience, distant city traffic.
```

**Two speakers per clip are allowed, and there is no per-line length cap.** The
one-speaker-per-clip / "lines ≤ 5 seconds" rule was retired in Oct 2026. Write the
scene as it plays and let the clip's duration carry the line. The untested part is
voice separation: the model advertises multi-character voice retention, so A/B the
first two-hander and review the voices closely before building on it.

**Soundscape:** always state the audio environment, even for "silent" scenes.
Ambience, effects and lip-synced speech come back with the clip at no extra
cost — `generate_audio` is on by default; only switch it off if the owner asked
for a silent master.

**Keep it simple:** the engine is excellent at subtle moves and bad at stunt
choreography. "Slow push-in" works. A dolly zoom + orbit + chair spin will
look broken.

## Camera language (shared by image and video prompts)

- Framing: wide / medium / medium close-up / close-up / extreme close-up /
  over-shoulder / insert / POV
- Lens: 32mm (environmental), 50mm (natural), 85mm (tight singles)
- Movement: breath-like handheld float (dramatic default), slow push-in
  (reveals), subtle handheld bob (walking), static tripod (establishing),
  slow pan (scanning), handheld float settling (action → stillness)

## The eight key rules (print these)

1. Two speakers per clip are allowed and lines have no length cap (one-speaker rule retired Oct 2026; two-voice separation is untested — A/B it)
2. The keyframe sets the scene; the prompt owns motion, time and dialogue
3. Dialogue in quotes with a delivery tone
4. Generate at 720p (480p for drafts), upscale later
5. Character consistency via reference images, named `@Image1`, `@Image2`… in the prompt
6. Physical cues, not emotions
7. Keep clips 4–6 seconds on the premium lane (Seedance 2.5 accepts nothing under 4s);
   the budget lane's floor is 5s, so a 3s or 4s shot cannot be made there at all
8. The approved Style Reference is the FIRST reference image on every image request

See also: `ai-film-keyframe-authoring` (first-frame prompts), `fal-ai-ops`
(generation commands), and the Prompt & Template Pack.