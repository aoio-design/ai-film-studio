---
name: ai-film-keyframe-authoring
description: "Authoring first-frame keyframe prompts for AI film shots: the frozen moment, reference-image order (Style Reference first), camera spec, exposure, movement language, timing and per-shot asset loading (GPT Image 2.5 Sunburst edit)."
version: 4.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [film, keyframes, prompts, fal-ai, higgsfield, gpt-image-2-5-sunburst, seedance, storyboard]
    related_skills: [ai-film-pipeline, ai-film-prompt-engineering, ai-film-cinematography, fal-ai-ops]
---

# Keyframe Authoring (first-frame prompts)

*Use when: writing the image prompt for the FIRST FRAME of a video clip — the
starting picture the video model moves from.*

## The format

Each shot gets ONE first-frame prompt. It must contain:

1. **Character identity** — attach the approved character sheet and say which
   reference it is
2. **Location** — attach the location image and say which reference it is (+ angle)
3. **The frozen moment** — the instant before the action starts
4. **Camera spec** — framing + lens feel + exposure
5. **Style** — the project's approved Style Reference, attached FIRST, plus the
   look restated in words (palette, contrast, light quality, lens feel)

## Prompt skeleton

```
[CHARACTER] (the character from reference N) [frozen pose/position] in/at
[LOCATION] (the setting from reference M, Angle [X]). [Key prop or detail
relevant to the shot]. Camera: [framing — e.g. medium close-up, 50mm],
[height/angle], [lighting], underexposed 1–1.5 stops night (or: daylight/soft).
[Style: cinematic, film grain, moody]. Mouth closed/neutral [if the shot has
dialogue].
```

The order of the attachments is the order you number them: the approved Style
Reference is **reference 1**, the character sheet is **reference 2**, the
location still **reference 3** (and any later character or prop after that).

## Worked example

```
Nora (the woman from reference 2) stands at the counter of the cafe (the
setting from reference 3, Angle B), phone held up in one hand, earbuds in,
watching her screen intently — she hasn't looked up yet. Camera: medium shot,
50mm, eye level, warm interior light spilling from the counter, soft film
grain. Mouth closed/neutral.
```

The `@Tag` tokens you may see elsewhere in this pack are the project's
shorthand for a character or a place. The image model only reads the attached
references, so the prompt itself must say which reference each element comes
from ("the woman from reference 2", "the setting from reference 3").

## Keyframe rules (never break these)

1. **First frame by default — an opening+closing pair ONLY if the selected
   video model requires it.** The keyframe is the starting picture the video
   model moves from. Read the video binding in
   `references/model-registry.yaml` before choosing — Seedance 2.5 (the
   premium lane, and the current default) uses a single first frame, as the
   budget lane's MiniMax H3 family does; a model that
   needs a first+last pair changes this rule.
   If the user picks an alternative video model, follow the mapping protocol in
   `references/model-routing.md` and re-derive the frame count/size from it.
2. If the image already shows the action, the video model gets confused and
   "un-does" it. The moment BEFORE the action — not the action itself. The
   action belongs in the video prompt, not the image.
3. **Mouth closed/neutral for dialogue shots** — the video model lip-syncs
   from the audio it generates; an open mouth in the reference fights it.
4. **The same references everywhere = the same face everywhere.** Never
   describe the character's face from scratch in a keyframe prompt — always
   anchor it to the approved sheet.
5. **Never generate a frame with no subject** — a pure black frame, or any beat
   written as "nothing lit". A blank frame is editorial: make it in post. An
   image model has nothing to render, so it returns noise or invents a texture,
   and you are billed for it either way. Keep the beat in the plan as an
   editorial mark, and leave that shot out of the generation batch.

## Camera language (usable in any image or video prompt)

**Framing:** wide / medium / medium close-up / close-up / extreme close-up /
over-shoulder / insert / POV.

**Lens feel:** 32mm (wide, slightly environmental), 50mm (natural, default),
85mm (tight singles), 85mm macro (props, details).

**Movement (for the VIDEO prompt, not the keyframe):**
- `breath-like handheld float` — default for dramatic scenes
- `slow push-in` — reveals, emotional moments
- `subtle handheld bob` — walking, action
- `static tripod shot` — establishing shots
- `slow pan` — scanning a space
- `handheld float settling` — transition from action to stillness

**Exposure guide:**
- Night exterior: underexposed 1.5 stops
- Interior, moonlight only: underexposed 1.5 stops
- Interior, warm lamp: underexposed 0.5 stops
- Day-lit exterior: underexposed 0.5 stops "for mood" — never apply night
  defaults to day scenes

## Timing (clip length depends on the LANE you are shooting on)

Plan against the lane the batch is running on, and remember that the choice of lane is
made (and quoted) per batch, not per shot:

- **Premium lane — Seedance 2.5: 4–30 seconds, plan 5–6s.** Its minimum clip length is
  **4 whole seconds** (maximum 30). Never plan a shorter clip than 4s.
- **Budget lane — the MiniMax H3 family: 5–15 seconds, 5-second minimum.** A
  **3-second or 4-second shot cannot be generated on this lane at all** — the 4-second
  floor belongs to the premium lane. If a beat genuinely needs 4s, either plan it as 5–6s
  or shoot that one shot on the premium lane and say which shots move.

```
4s — quick reaction, cutaway, insert, one short dialogue line   (PREMIUM lane only)
5s — standard action, character moment                          (both lanes)
6s — establishing shot, reveal, dramatic hold                   (both lanes)
```

Durations are earned, not assigned to fill time. Dialogue pacing ≈ 3–4 words
per second: a 35–40 word paragraph is ~9–10s — a long single clip. Prefer
splitting it into a multi-shot sequence (speaker close-up → reaction/insert
cutaway → speaker finish) and let the line carry across the cutaways.

## Per-shot asset loading (GPT Image 2.5 Sunburst edit)

`openai/gpt-image-2.5/sunburst/edit` accepts **up to 16 reference images**
(`image_urls` — required, not optional) in one request, plus an optional
`mask_url`. The composition prompt describes how the references combine — put
the character from one reference into the setting from another.

Every keyframe call carries the project's approved **Style Reference FIRST**,
then the character sheet(s) of everyone on screen, then the location (and any
prop) still:

```
image_urls = [Style Reference, character sheet(s)…, location / prop still(s)…]
```

Render every keyframe at the **project's shape**, quality high — **2048×1152**
for a 16:9 project, **1152×2048** for a vertical 9:16 project (say "this is a
vertical project" when you start). Both edges must be multiples of 16: an
invalid pair is snapped silently rather than rejected (a 1920×1080 request
comes back 1920×1072), so use the sizes above. The frame is supersampled above
the clip's resolution so the video model downsamples clean detail (exact
command: see the `fal-ai-ops` skill).

Verify the generated image actually contains the right character and place
before generating video — a wrong keyframe wastes a paid video clip.

## Reference

- Prompt templates pack (Downloads page): `keyframe-prompt-format.md`,
  `character-sheet-prompt.md`, `the-7-key-rules.md`
- Generation commands: see the `fal-ai-ops` skill
