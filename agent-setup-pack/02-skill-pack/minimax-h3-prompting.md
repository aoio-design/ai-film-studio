---
name: minimax-h3-prompting
description: "Prompt dialect for the BUDGET video lane — the MiniMax H3 family (minimax/h3, minimax/h3-max) on fal.ai: the three-field structured prompt, keyframe alignment modes, speaker and dialogue syntax, camera-motion vocabulary, the six-section full-reference form for character and voice references, one-job-per-reference rules, and the 5-second floor."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [film, prompts, video, minimax, h3, budget-lane, fal-ai, reference-to-video]
    related_skills: [seedance, ai-film-prompt-engineering, ai-film-keyframe-authoring, fal-ai-ops, ai-film-pipeline]
---

# MiniMax H3 Video Prompting (the budget lane)

*Use when: the batch is running on the BUDGET video lane — the MiniMax H3
family on fal.ai — and you are writing the prompt for a clip. This lane does
not take free prose: H3 wants a structured, fielded prompt. Read this before
writing anything, and read `seedance` if the batch is on the premium lane —
the two dialects are different and must never be mixed inside one prompt.*

## The lane in one table

| | |
|---|---|
| Models (fal) | `minimax/h3` — the cheaper tier · `minimax/h3-max` — the upper tier |
| Price (list) | `h3` **US$0.06/s** at 768p (≈ **US$0.30** per 5s) · `h3-max` **US$0.08/s** at 768p (≈ **US$0.40** per 5s) |
| Clip length | **5–15 seconds, and the floor is a hard 5 seconds.** A 3s or 4s shot **cannot be generated on this lane** — the 4-second floor belongs to the premium lane |
| Canvas | 768p |
| References | the **first 5 reference images are free**, then about US$0.08 each (`h3`) or about US$0.02 per 2048px image (`h3-max`) — keep the reference set tight |
| Second host | Higgsfield sells the H3 family **at 2K only**, about US$0.13/s — the same rate fal charges at 2K, so the platforms match there and there is no cheaper host to name. **Below 2K, fal.ai is the only H3 host** |
| Audio | native — dialogue, ambience and effects come back with the clip; no separate audio pass |

**Quote the live model page before every batch** (`genmedia pricing <model-id>`
or `genmedia run <model-id> --help`), list prices only, and name which host you
are quoting. Never generate on an unquoted price.

## Two prompt shapes — pick one per shot

| Shape | Use it when | Sections |
|---|---|---|
| **A — the three-field prompt** | text-only shots, or a shot with a keyframe (first frame, first+last, or last frame) and no character/voice references | one alignment line (image modes only) + `integrated_multimodal_description`, `overall_soundscape`, `non_diegetic_music` |
| **B — full-reference mode** | the shot carries character sheets, a location plate, motion or voice references — the normal case for a series | six named sections, `subject_definitions` first |

Do not pad a Shape A prompt with Shape B sections, and do not send a Shape A
prompt when you have references attached — the references need naming.

## Shape A — the three-field prompt

### 1. The alignment line (image-input modes only)

One line, then **one blank line** before the fields. The `S.SS` timestamp is the
clip's effective duration written to **exactly two decimal places** (5s → `5.00`).

```text
For the target video, at 0.00 seconds into the target video, Image 1 (from [Shot 1]) is fully referenced.
```

```text
How the reference pictures align with the target video — Image 1 (from [Shot 1]) aligns with the 0.00-second mark of the target video; Image 2 (from [Shot N]) aligns with the 5.00-second mark of the target video.
```

```text
How the reference pictures align with the target video — Image 1 (from [Shot N]) aligns with the 5.00-second mark of the target video.
```

| Mode | Input | What the body must do |
|---|---|---|
| **T2VA** | text only | no alignment line at all — start straight at the fields |
| **I2VA** | first frame | anchor the first frame, then action onset → continuous development → result/reaction; keep identity, clothing, colours, key objects and spatial relationships consistent |
| **FL2VA** | first + last frame | describe the motion path *between* the two frames; **prefer a single shot**; last-frame state must be reached by the FINAL shot |
| **L2VA** | last frame | infer a plausible preceding state, then converge on the given last frame |

### 2. The three fields

```text
integrated_multimodal_description: [Shot 1] ...

overall_soundscape: ...

non_diegetic_music: ...
```

- **`integrated_multimodal_description`** — the whole body: visuals, action,
  shots, speakers, dialogue, diegetic audio, laid out along the timeline.
- **`overall_soundscape`** — 1–4 sentences, one paragraph: ambience and physical
  sound across the whole clip (wind, rain, traffic, footsteps, fabric, impacts,
  breathing, laughter). Do **not** repeat dialogue, singing or diegetic music
  here — those live in the description. Use `N/A` **only** for silence you
  explicitly asked for.
- **`non_diegetic_music`** — 1–3 sentences: instrumentation, speed, rhythm,
  dynamic changes. **No abstract mood words** and no explanations of what the
  music is supposed to make the audience feel. Diegetic music (a radio, a TV, a
  band in the scene) belongs in the description instead. `N/A` when there is
  none.

### 3. Shots and cuts

- `[Shot 1]` carries **no timestamp**. Later shots open with a strictly
  increasing cut time: `[Shot 2] At 00:03.500, the camera cuts to...`
- Declare the overall style at the start of `[Shot 1]` — `Live-action`,
  `cinematic`, `2D-animated`, `3D CG`, `claymation`, `watercolour`, `vintage
  film`. For a keyframe shot, take the style from the reference image.
- Cut vocabulary: `the camera cuts to`, `the shot cuts to`, `the shot
  transitions to`, `the shot changes to`, `the shot switches to`. Cross-dissolve,
  fade and wipe **only** when the owner asked for them.
- A cut must introduce **new** information (subject, space, state, viewpoint or
  time). For a mere change of distance or angle, use camera motion inside the
  shot instead of cutting.
- Match prompt length to the clip length — a short body on a long clip comes
  back as rushed action.

### 4. Camera motion — type + amplitude + speed

| Dimension | Vocabulary |
|---|---|
| Type | `Zoom In/Out` (focal length only) · `Push In/Pull Out` (camera body moves) · `Pan Left/Right` (lens pivots) · `Truck Left/Right` (body translates) · `Tilt Up/Down` · `Pedestal Up/Down` · `Arc Shot` · `Tracking Shot` · `Static Shot` · `Shake Slightly/Strongly` · `POV` · `Roll Clockwise/Counterclockwise` |
| Amplitude | `with small amplitude` / `with large amplitude` (omit for medium) |
| Speed | `at slow speed` / `at fast speed` (omit for normal) |

Write it as **natural English inside the shot sentence**. Never stack labels at
the end of a sentence.

```text
The camera pushes in with small amplitude at slow speed toward the folded letter in her hands.
The camera pans right with large amplitude at fast speed, revealing the open doorway.
```

### 5. Speakers and dialogue

- Give every person who speaks, sings or voices over a stable ID — `(S1)`,
  `(S2)`, same ID across every shot of the clip. Group speech is `(S1,S2)`.
  Characters who never vocalise get **no** ID.
- On first appearance, establish who they are from what is visible and audible:
  type, age, gender, on-screen or not, pitch, timbre, speaking rate, accent.
- **Dialogue syntax:** the identifying phrase, the ID, the action and the
  delivery go **outside** `<d>`; inside `<d>` goes only the language tag and the
  exact words.

```text
The woman with a quiet, breathy voice (S1) says: <d>[English] I get off at the next station.</d>
```

- **Every original word and punctuation mark stays verbatim — never translate,
  never paraphrase.**
- Voiceover: use the exact phrase `says in an off-screen voiceover`, and
  immediately after the `<d>` block state that the on-screen character's lips
  stay closed:

```text
The man (S1) says in an off-screen voiceover: <d>[English] I still remember that road.</d> while his lips remain completely closed.
```

- Dialogue that runs **across a cut**: put `<scenetrans>` at the connecting point
  in **both** parts and say the audio continues across the cut (`continues
  seamlessly across the cut`, `carries over from the previous shot`, `remains
  audible across the transition`). Speech cut off by the end of the clip: `<cutoff>`.
- **One speaker per clip** keeps the spoken timeline clean — split an exchange
  into shot/reverse-shot clips.

### 6. On-screen text

Visible text — signs, labels, neon, subtitles — goes in **English double
quotation marks**, verbatim, untranslated:

```text
A red neon sign reading "OPEN" glows above the doorway.
```

## Shape B — full-reference mode (six sections, in this order)

```text
subject_definitions:
summary:
retention_analysis:
detailed_description:
overall_soundscape:
non_diegetic_music:
```

Write every section in English except dialogue/lyrics inside `<d>` and the
visible text of the scene.

### Reference labels

| Label | What it means |
|---|---|
| `<Subject N>` | reusable visible content — a person, animal, object, place, garment, prop, style, action, expression or pose |
| `<Picture N>` | a reference image used as a concrete frame anchor — first/key/last frame, or a storyboard panel |
| `<Video N>` | a reference video — an edit source, a continuation start, or a whole-video temporal structure |
| `<Audio N>` | an audio signal that is copied or referenced — timbre, style, dialogue, beat |

- One line per item: what the label means, what role it plays, what to follow.
  One subject can be built from several assets — say what each one provides:
  `<Subject 1> is the woman whose appearance comes from Image 1 and whose walking motion comes from Video 1.`
- An image used only to define a subject is cited **inside that subject's line** —
  no separate entry for it.
- An audio reference bound to a speaker reuses the speaker's global ID:
  `<Audio 1> is the voice-timbre reference for <Subject 1> (S1).`
- Video and audio labels number **independently** — one source video can be
  `<Video 1>` and `<Audio 2>`.

### summary

One short paragraph opening with a square-bracketed task-type prefix. Combine
types with ` + `, no repeats. Use these prefixes only; invent no new ones:

`[keyframe completion]` · `[reference generation]` · `[video editing]` ·
`[video continuation]` · `[audio reuse]` · `[audio reference]`

```text
[reference generation + keyframe completion] ...
```

A video-editing summary opens: `The target video is an edited version of <Video 1>.`

### retention_analysis

One line per label, at its first relevant appearance, using these markers —
**never write `(Sx)` in this section**:

- visual: `fully_preserved` · `partially_preserved` · `attribute_transfer` · `weak_reference`
- audio: `fully_copy` · `partially_copy` · `reference` · `weak_reference`

```text
<Subject 1> (appears in [Shot 1], [Shot 3]): fully_preserved — face, hair and coat match the reference throughout.
<Audio 1>: reference — the target speaker follows the voice timbre and measured delivery without copying the original signal.
```

### detailed_description

- **350–500 words** for a generation task; if the clip is dialogue-dense, a
  complete spoken timeline matters more than the word count.
- The style goes in **1–2 sentences BEFORE `[Shot 1]`** — unlike Shape A, where
  the style opens `[Shot 1]`.
- Shots, camera motion, speakers and dialogue follow the same rules as Shape A
  above — reuse that vocabulary.
- Insert each label at its first appearance and wherever its role applies, with
  natural anchor phrasing: `the shot begins from Image 1`, `the shot's keyframe
  corresponds to Image 2`, `the shot ends on Image 3`.
- A speaking subject is written `<Subject 2> (S1) turns toward the woman and
  says, <d>[English] ...</d>` — the subject label carries the **referenced
  identity**, the ID carries the **actual speaker**. Off-screen: same form, mark
  it `off-screen`.
- Reused dialogue is preserved word for word in its original language inside
  `<d>`. Mark unintelligible spans `[unclear]`. Standardise punctuation — no
  tildes, no emoji, no bullets.
- Never reduce this section to a plot summary or a list of reference
  relationships; it is the shot itself.

### The two audio sections

Same rules as Shape A. When reference audio is used, state the copy/reference
relationship in whichever section matches the audible layer — and in **both** if
one file provides both:

```text
overall_soundscape: The copied ambience layer from <Audio 1> continues throughout the target video.
non_diegetic_music: <Audio 2> is reused as the complete audience-only score.
```

## Reference discipline (applies to both shapes)

**Core principle: every reference gets exactly one named job.** A picture for
appearance or composition, a video for motion or camera, an audio file for the
sound signal. Then say what the model should retain, transfer, change, or treat
as a loose reference.

- **Name the references in the prompt by the input's own convention.** On fal
  this family cites references **by modality and upload order** — `Image 1`,
  `Image 2`, `Video 1`, `Audio 1` — and the numbering follows the order you send
  the files. The `<Picture N>` / `<Audio N>` spellings in the model's own
  documentation name the same slots; use the input spelling in the prompt you
  send, and keep one convention for the whole batch.
- **Never let the other lane's handles leak in.** `@Image1` / `@Audio1` is the
  premium lane's convention and means nothing here.
- **Keep the reference kit tight.** The first 5 reference images are free and
  the rest are billed, so send the keyframe plus the sheets actually on screen —
  not the whole asset library.
- **Reference ceilings (verify against the live model page, which is also what
  sets the bill):** up to 9 images, 3 videos of 2–15s each (15s total) and 3
  audio clips of 2–15s each (15s total), 12 mixed files at most. Audio alone is
  not a valid input — it must arrive with an image or a video.
- **Do not mix role families in one request.** A fixed frame anchor (first
  and/or last frame) and attribute-style references are different jobs; pick
  one shape for the clip.
- **Filter before uploading** — permission, relevance, clarity, compatibility,
  priority. A reference that fails any of the five does not go in.
- **Assign responsibility instead of asking for two things at once.** Never
  write "use the face from A and the lighting from B, keep both" — say which
  source controls which attribute.
- **References guide, they do not guarantee.** Identity, motion and timbre
  follow the references reasonably well; physics, lip-sync, timing and
  pixel-level reproduction do not. Plan a re-roll rather than promising
  precision.

## Duration and timing

- Clips are **5–15s on this lane, 5s minimum**. The shot plan runs **5–30s**
  with **5–6s coverage** per shot; anything genuinely needing 4s either becomes
  5–6s or moves to the premium lane (and the quote says so).
- Alignment timestamps are written to exactly two decimals — a 5s clip is
  `aligns with the 5.00-second mark`.
- Cut times strictly increase and stay inside the clip's duration.

## Worked example — Shape A (I2VA, 5s, one speaker)

```text
For the target video, at 0.00 seconds into the target video, Image 1 is fully referenced.

integrated_multimodal_description: Live-action, cinematic. [Shot 1] DANA, a woman in her late thirties with short dark hair and a grey coat, stands at the counter of a small cafe, a folded letter held in both hands. The camera pushes in with small amplitude at slow speed toward the letter. DANA, in a quiet, breathy voice (S1), says: <d>[English] I never opened it.</d> She sets the letter flat on the counter and looks up.

overall_soundscape: Low cafe murmur, a coffee machine hissing, a cup settling on a saucer, footsteps on a wooden floor.

non_diegetic_music: Sparse upright piano, slow tempo, single notes with long decay, no percussion.
```

## Worked example — Shape B skeleton

```text
subject_definitions:
<Subject 1> is the woman whose appearance comes from Image 1.
<Audio 1> is the voice-timbre reference for <Subject 1> (S1).

summary: [reference generation] The shot follows <Subject 1> through a single continuous beat at the cafe counter.

retention_analysis:
<Subject 1> (appears in [Shot 1]): fully_preserved — face, hair, build and coat match the reference.
<Audio 1>: reference — the speaker follows the reference timbre without copying the original signal.

detailed_description: Live-action, cinematic, underexposed interior. [Shot 1] <Subject 1> (S1) stands at the cafe counter, a folded letter in both hands. The camera pushes in with small amplitude at slow speed toward the letter as she says, <d>[English] I never opened it.</d> She sets the letter flat on the counter and looks up. ...

overall_soundscape: Low cafe murmur, a coffee machine hissing, footsteps on a wooden floor.

non_diegetic_music: Sparse upright piano, slow tempo, single notes with long decay, no percussion.
```

## Sending it to fal

The call has the same shape as the premium lane's, with this family's own model
id and flags — confirm the exact flag spelling with `--help` first, and quote
the live price before submitting:

```bash
genmedia run minimax/h3-max/reference-to-video --help    # flags + live price first

genmedia run minimax/h3-max/reference-to-video \
  --prompt "$(cat <this-shot>.txt)" \
  --image_urls '["<keyframe_cdn>","<sheet_cdn>"]' \
  --audio_urls '["<voice_cdn>"]' \
  --duration 5 --aspect_ratio 16:9 --download
```

Upload the keyframe, then each character sheet actually on screen, then the
speaker's voice reference — the prompt's `Image N` / `Audio N` numbering follows
that upload order. Voice references are real recordings of the line, so the
model clones the timbre instead of inventing a voice; the **same saved file on
every clip** is what keeps a character sounding identical across shots. Pass the
project's aspect ratio explicitly, and check the downloaded file exists before
reporting anything as ready (`fal-ai-ops` has the full command set, the quoting
rule and the verification steps).

## Never break these

1. Dialogue inside `<d>` is verbatim — no translation, no paraphrase, keep the
   punctuation.
2. `[Shot 1]` has no timestamp; later cut times strictly increase and stay
   inside the clip.
3. Alignment timestamps take exactly two decimal places.
4. FL2VA stays a single shot unless the owner asked for several; the given last
   frame must be reached by the final shot.
5. Camera motion is written as natural English inside the shot — never as
   stacked labels.
6. `N/A` means "explicitly silent / no music" — not a blank field.
7. `detailed_description` stays 350–500 words; it is the shot, not a summary.
8. Invent no new labels in `summary`, and write no `(Sx)` in
   `retention_analysis`.
9. One speaker per clip, and one prompt convention per batch — the premium
   lane's `@Image1` handles never appear here.
10. Nothing generates before the lane is chosen and the live price is quoted.

## Sources

- MiniMax H3 official prompt-writing guides, base and reference modes:
  `https://huggingface.co/MiniMaxAI/MiniMax-H3` (docs and `skills/` directory)
- Generation commands, price quoting and verification: the `fal-ai-ops` skill
- First-frame prompts for these clips: `ai-film-keyframe-authoring`
- The other lane's prompt dialect: `seedance`
