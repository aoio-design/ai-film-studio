---
name: ai-film-character-set-design
description: "Authoring a project's character bible and set/prop text for the studio: the order of work, the six bible fields, body-language archetypes, emotional-range cards, wardrobe and location/prop logic, and the consistency rules that keep one character the same person across every frame."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [character-design, set-design, character-bible, consistency, emotional-range, body-language]
    related_skills: [ai-film-pipeline, ai-film-prompt-engineering, ai-film-sheet-standards, studio-ops, fal-ai-ops]
---

# Character & Set Design — authoring the bible

*Use when: designing a character, location or prop for a project — writing or
revising the text on the studio's **Character Bible & Assets** page
(`/a/<season>`) — or when a character keeps drifting between frames. All of it
is written and approved BEFORE anything is generated: words first, media later.*

## Where this skill sits

This skill owns the **method**: what to pull out of the script, in what order,
and how the words become something an image model can draw. It deliberately does
not repeat the rules that live next to it:

| You need | Read |
|---|---|
| Where the text goes, the field names, file naming, the review loop | `studio-ops` |
| What each of the six fields must contain, at what depth, with examples | `references/bible-and-asset-writing.md` |
| Prompt shapes (image + video) and the asset templates | `ai-film-prompt-engineering` |
| Panel counts, dimensions, quality tier, sheet prompt rules | `ai-film-sheet-standards` |
| Exact generation commands and live rates | `fal-ai-ops` |
| The order of steps, and who approves what | `ai-film-pipeline` |

## The order of work (never reorder this)

1. **The script is approved first.** Characters are derived from the approved
   script, not invented beside it. If the script is still moving, the bible is
   premature.
2. **Write every character's six fields in one pass** — appearance, personality
   & backstory, distinguishing features, wardrobe/style, emotional range, body
   language — plus the character sheet prompt composed from them. Locations and
   props get their description and prompt in the same pass. **Nothing is
   generated at this stage.**
3. **The user reviews the words** on `/a/<season>`: they edit fields directly on
   the cards or leave notes, and tell you when the words are approved.
4. Only then does the reference-image stage run — the sheet format is in
   `ai-film-sheet-standards`, the command and live rates in `fal-ai-ops`, and it
   starts only after a cost quote and an explicit yes.

A bible written after generation is a caption, not a source of truth. Words cost
nothing; media costs money.

## Step 1 — the character bible card

One card per character, six fields. What each field must *contain* — the depth
target, the rules and a worked example for each — is in
`references/bible-and-asset-writing.md`. This is the skeleton to fill and the
discipline that keeps it usable:

```markdown
## CHARACTER — <role> (Lead / Supporting / Background)

appearance        age · height · build · face (eyes, nose, mouth, jaw) ·
                  skin (named tone + texture) · hair (colour, cut, texture) ·
                  posture at rest · default expression
personality       who they are NOW · 2–4 backstory beats that explain it ·
                  what they want · how that shows in behaviour
distinguishing    2–4 markers that survive across scenes and angles
wardrobe          palette (2–4 colours) · silhouette (fit and shape) ·
                  texture (real materials) · signature outfit · story variants
emotional_range   4–6 NAMED states, NEUTRAL first, each with its physical tells
body_language     stance · gesture range · energy · one reusable
                  "prompt injection" sentence
character_sheet_prompt   the image prompt, composed from the six fields above
```

### What to pull out of the script

- **Age and build from behaviour**, not from guesswork: what the script has the
  character doing tells you whether they are wiry, heavy-set, restless or still.
- **Two to four distinguishing markers, and no more.** A marker has to survive
  every angle and every wardrobe change — a small scar, a chipped tooth, an
  always-worn ring, a slight limp. A mood does not survive; neither does a
  detail the model can only see from the front.
- **The default expression** — the face the character wears when nothing is
  happening. That is what the sheet's close-up panel renders, so it must be
  ordinary, not a performance.
- **The wardrobe as one signature outfit plus variants.** Choose one outfit;
  add a variant only where the story changes it, and note *where* the change
  happens so no shot contradicts it.
- **What the character notices and how they move** — the raw material for the
  body-language field (next section). A character who scans exits before sitting
  down is a different generation from one who drops into a chair.

### Rules the bible lives by

1. **Every detail must be drawable.** "Quietly resentful" is not a detail;
   "jaw set, eyes down, hands still" is one. Never leave an interior state
   without its physical expression.
2. **Concrete and ordinary beats idealized.** Name real skin, hair and eye
   colours and textures, and describe the character as *realistic and unpolished*
   — a conventionally perfect face is exactly the plastic look the pipeline is
   trying to avoid.
3. **Write it fresh.** Never open another project's or another character's text
   to copy the shape: a reused phrase shows up downstream as a reused face.
4. **The bible is the source of truth.** Once a field is approved, no later
   prompt contradicts it. If a change is wanted, change the field first, then
   re-compose the sheet prompt from it.
5. **One character, one card, one home folder.** A character who returns in a
   later season keeps the original files and is referenced from their home
   folder — never copied or re-described elsewhere (naming standard:
   `studio-ops`).

### Voices (speaking characters only)

Every character who speaks needs a **one-time reference voice**, generated once
and reused on every clip where they speak — the saved file *is* the voice, so
regenerating it per clip changes the person. The card carries the voice
direction; the command and the naming standard are in `fal-ai-ops` and
`studio-ops`.

## Step 2 — physical presence (body-language archetypes)

Appearance alone does not make a character consistent; *how they occupy space*
does. Pick the archetype that fits, put its prompt-injection sentence in the
`body_language` field, and paste that sentence into the character block of every
prompt where the character appears.

| Archetype | Physical signature | Prompt injection (fill in `[Character]`) |
|---|---|---|
| **The isolated truth seeker** | coiled, hyper-vigilant, defensive arms, visibly tired | `[Character] stands with coiled intensity, shoulders hunched, eyes scanning rapidly, one hand gripping {object} defensively` |
| **The artificial humanoid** | eerily symmetrical, deliberately smooth, minimal blinking, expressions lag a beat | `[Character] holds perfectly symmetrical posture, turns the torso as one unit, eyes fixed with minimal blinking, expression shifting a beat too late` |
| **The bureaucratic authoritarian** | rigid and symmetrical, feet planted wide, slow deliberate gestures, chin up | `[Character] stands rigid and symmetrical, feet planted wide, hands clasped behind the back, chin elevated` |
| **The conditioned worker** | meek and compliant, hands clasped at the front, head bowed — then an abrupt rigid freeze | `[Character] with meek compliant posture, head bowed, then abruptly freezes with wide-eyed disorientation` |
| **The hardened survivor** | low centre of gravity, heavy planted steps, asymmetrical weight, hands near gear | `[Character] moves with a low grounded centre of gravity, heavy deliberate steps, one hand resting near {tool}, weight shifted to one hip` |
| **The intellectual obsessive** | frantic micro-movements, pacing, hands sketching the air, no spatial awareness | `[Character] paces, hands sketching patterns in the air, tapping every surface, rapid micro-movements` |
| **The manic anarchist** (comedy) | explosive unpredictable energy, wide eyes, arms flailing, invades space | `[Character] moves with explosive manic energy, arms flailing, unpredictable full-body movement` |
| **The deadpan straight man** (comedy) | perfectly still in the middle of chaos, stone-faced, slow blinks, hands motionless | `[Character] stands rigid and stone-faced, perfectly still amid chaos, blank expression, minimal reaction` |
| **The defensively witty** (dramedy) | open confident posture masking nervous tics, eye-rolls, drops eye contact when serious | `[Character] with open confident posture but nervous micro-tics, self-deprecating shrugs, avoids eye contact when vulnerable` |
| **The coiled high-stress** (dramedy) | shoulders up to the ears, arms crossed, jaw clenched — then collapse | `[Character] holds rigid tension, arms crossed, jaw clenched — then collapses into exhausted stillness` |
| **The yearning lover** (romance) | prolonged soft eye contact, head tilt, leaning in, hands hovering near contact | `[Character] leans in with intense soft eye contact, head tilted, body angled toward them, hands hovering near shared space` |
| **The hesitant romantic** (romance) | guarded posture, downcast eyes, fidgeting — opens only once safe | `[Character] stands guarded, arms crossed, eyes down, fidgeting with a sleeve cuff, then uncrosses and reaches slowly` |
| **The unspoken bond** (two-hander) | heavy pauses, eyes tracking each other, mirrored posture, synchronised breathing | `[Character] pauses before speaking, eyes tracking the other's face, mirroring their posture in silence` |
| **The heartbroken estranged** (romance) | slouched and deflated, avoids the other's gaze, heavy steps | `[Character] stands slouched and deflated, avoids eye contact, arms crossed tight, heavy slow steps` |

**How to use the archetypes:**

- **Match by genre first, then by character.** Sci-fi leans *isolated truth
  seeker*, *artificial humanoid*, *bureaucratic authoritarian*; action and
  frontier lean *hardened survivor*; comedy leans *manic anarchist* and *deadpan
  straight man*; dramedy leans *defensively witty* and *coiled high-stress*;
  romance leans *yearning lover* and *unspoken bond*, turning to *heartbroken
  estranged* when the story breaks them.
- **A profile can change across the arc** — often that change *is* the story.
  Document the shift at the scene where it happens ("starts coiled and
  defensive, collapses into exhausted stillness in scene 12") so shots on either
  side of the turn do not mix the two.
- **Reference the profile everywhere a body appears**: the character block of a
  scene prompt, any first-frame prompt where the posture changes, and the video
  prompt — where the motion arc across the clip matters, not just the face.

## Step 3 — emotional range cards

Four to six named states per character, NEUTRAL first. Each state needs the
**body**, never the emotion word — these cards become the acting notes for every
scene:

```markdown
NEUTRAL:    relaxed face, flat mouth, slow blink
HAPPY:      corner-of-the-mouth smile, eyes soften, shoulders drop
CONCERNED:  brow furrows, eyes track the other person, weight shifts forward
SURPRISED:  brows up, mouth slightly open, one half-step back
DETERMINED: jaw set, steady gaze, hands still
SAD:        eyes down, soft mouth, slight droop in the shoulders
```

Rules: name each state in capitals so it can be quoted straight into a prompt;
always write the face *and* the body (eyes, brows, mouth, breathing, hands,
posture); and keep the states distinct — two states with the same physical tells
are one state. A state that exists only as an adjective cannot be generated.

## Step 4 — the look (Style Reference)

Before anything is generated, the project gets one look, approved once: the
user's own images go into the **Style Reference** section of the assets page and
the user stars the approved one(s). From then on **every** image carries that
look — first among the references *and* restated in words (palette, contrast,
light quality, lens feel).

Rules that matter here (mechanics in `studio-ops`, command in `fal-ai-ops`):

- **Never star an image for the user**, and never invent a look when nothing is
  approved — generate without one and say so.
- **A new style reference changes nothing already generated.** It applies from
  the next generation onwards. Never offer to re-render approved assets in a new
  look unless the user asks for that.
- **The look must exist in words as well as in the image.** If the only place it
  lives is an attachment, the next prompt that loses the attachment drifts.

## Step 5 — locations and props (same discipline, no faces)

**Locations** — the description is the text the user reviews; the prompt is the
4-panel sheet language defined in `ai-film-sheet-standards`:

- **Lock the time of day and the lighting**, and hold it across every panel.
  Scene mood belongs in shot prompts: a sheet baked with "cold moonlight and a
  red rim light" contaminates every scene it is used in.
- **No people.** Environment only — at most one to three small distant figures
  for scale in a public space, none in an empty one.
- **Give it size** — "a room roughly 6m × 8m, ceiling 2.8m". Spatial dimensions
  are what let the model reconcile four different angles into one place.
- **Name the fixed elements**: architecture, furniture, landmarks, materials,
  condition (new, worn, improvised). Anything that moves between shots is set
  dressing, not the location.

**Props** — the description is what the object *is*; the prompt is the 4-panel
prop-sheet language:

- Materials, scale, condition and wear, plus any moving parts.
- **No hands, no scene context, no stray text.** The exception is text that is
  genuinely part of the object (a label, a screen, a printed page) — describe it
  explicitly when so.
- A prop that only matters in one shot is shot dressing, not a bible asset.

## Step 6 — set dressing (genre texture in the prompt)

Set dressing is what tells the audience how a world works. Three rules govern
it, then a short vocabulary per genre. The full genre look library lives in
`ai-film-cinematography`.

1. **Describe what a thing does and how it looks, not what it is.** "Scrolling
   green lines of decrypted data on a terminal" beats "a computer screen".
2. **Light from an object onto a face is the strongest dressing effect there
   is.** A face lit by a flickering amber screen reads differently from one lit
   by a cool hologram — say which light reaches the character.
3. **Keep the technology consistent per location.** If a room has analogue
   monitors in one scene it has analogue monitors in the next; swapping the
   hardware mid-location breaks the place.

| Genre | Dressing language that reads well |
|---|---|
| Sci-fi — interfaces | "translucent 3D holographic display, cyan light particles" · "transparent HUD overlay, low-opacity vector graphics" · "low-fidelity CRT, green phosphor scanlines, chunky physical buttons" · "mercury-smooth interactive surface, no visible controls" |
| Sci-fi — signage & power | "towering digital billboard flickering above the street, rain-streaked" · "corporate monogram embedded in the architecture, a surveillance camera below it" · "propaganda mural, bold colours, weathered" · "instructional poster, clean sans-serif, sterile framing" |
| Comedy | "absurd lower-third character title, white sans-serif on a blue bar" · "bold punchline text overlay filling the frame" · "hand-painted local sign with uneven lettering" · "deliberately ugly fictional brand logo" |
| Dramedy | "quietly ironic poster or chalkboard in the background" — keep it out of the foreground and let it be discovered |
| Romance | "handwritten letter on cream paper, ink slightly smudged" · "open journal, flowing handwriting, warm light on the page" · "faded photo prints, warm washed-out colour" · "minimalist title card, thin serif, white on black" |

## Consistency — the whole point of the bible

| Symptom | Cause | Fix |
|---|---|---|
| The face drifts between shots | the face is being re-described in words instead of anchored | attach the approved character sheet as a reference and say which reference it is; never describe the face from scratch |
| The character looks different in the sheet than in the scene | the sheet was edited and the face degraded | paste the original face back over any edited panel (the ONE-face rule is in `ai-film-sheet-standards`) |
| Every scene looks like the same scene | scene lighting was baked into the sheet | re-make the sheet under neutral studio light and move the mood into the shot prompt |
| The wardrobe changes with no story reason | variants were never written down | add the variant to the wardrobe field and record where the change happens |
| The character reads flat | the bible was written as adjectives | rewrite the fields until every line is something a camera could see |

Rules that hold the whole thing together:

1. **Reference images carry identity; words carry action.** The sheet is the
   anchor; the prompt describes what happens, in physical cues.
2. **The base character block never changes.** Copy and paste the same block
   between prompts instead of retyping it — a retyped description is a new face.
3. **Three to five key visual elements per prompt is the working maximum.** More
   elements make the render muddier, not richer.
4. **Design for the cut.** Whatever the video model moves between, the place and
   the wardrobe must match at both ends of the shot — only the story element
   changes.
5. **One field, one meaning.** If a sheet prompt and a scene prompt disagree,
   the approved field wins and one of the two prompts is wrong.

## Common pitfalls

1. **Filling the sheet with story.** Backstory belongs in the personality field;
   it must never leak into a generation prompt as narration.
2. **A one-line field.** That is a draft. Every field has to let an image model
   draw the character without guessing.
3. **Details too small to see.** A "subtle" detail is invisible at frame size —
   pick markers that survive a wide shot.
4. **Vague scale.** "A cramped room" renders as anything; "a cramped room about
   8 × 10 feet with a low ceiling" renders as one thing.
5. **Props in the character's hands on the sheet.** They lock the character to
   one scene; hands rest at the sides.
6. **Adding a character mid-production.** A new lead means a new sheet, a new
   voice and new cost — quote it and get approval like any other batch.
7. **Copying another character's card.** The two will share a face.

## See also

- `references/bible-and-asset-writing.md` — the per-field content spec and worked examples
- `ai-film-sheet-standards` — panels, dimensions, quality tier, sheet prompt rules
- `ai-film-prompt-engineering` — image and video prompt shapes
- `ai-film-keyframe-authoring` — first-frame prompts
- `studio-ops` — where the text lives, the review loop, the naming standard
- `fal-ai-ops` — commands, live rates, the price gate
