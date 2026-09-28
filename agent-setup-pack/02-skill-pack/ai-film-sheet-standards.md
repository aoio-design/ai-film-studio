---
name: ai-film-sheet-standards
description: "The reference-sheet spec for the studio: which model renders every sheet, panel counts and dimensions per asset type, the sheet prompt skeleton and closing constraint, the ONE-face rule, and what to update when a sheet standard changes."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [reference-sheets, layout-standards, dimensions, consistency, propagation]
    related_skills: [ai-film-character-set-design, ai-film-prompt-engineering, ai-film-keyframe-authoring, fal-ai-ops, studio-ops]
---

# Reference Sheet Standards — the spec

*Use when: writing, reviewing or changing the layout of a reference sheet
(character, location or prop), or when someone asks "how many panels / what
size / what quality". One place, one answer. Sheets are the project's identity
anchors — every later image in the project is generated against them.*

## The spec (current)

| Asset | Endpoint | Panels | Dimensions | Quality |
|---|---|---|---|---|
| **Character sheet** | `openai/gpt-image-2.5/sunburst/edit` | 3, landscape, side by side | **1536×1024** | **high** |
| **Location sheet** | `openai/gpt-image-2.5/sunburst/edit` | 4, 16:9 landscape | **1536×864** | **medium** |
| **Prop sheet** | `openai/gpt-image-2.5/sunburst/edit` | 4, grid | **1024×768** | **medium** |
| **Keyframe** (for reference — `ai-film-keyframe-authoring`) | `openai/gpt-image-2.5/sunburst/edit` | 1 frame | 16:9 → **2048×1152** · 9:16 → **1152×2048** | **high** |

**Every one of these runs on the EDIT endpoint.** The text-to-image variant of
the model accepts no reference images at all, and every image in the pipeline
must carry the project's approved **Style Reference** — so
`openai/gpt-image-2.5/sunburst/edit` is the model for every image job there is,
`image_urls` is required rather than optional, and the order inside it is fixed:

```
image_urls = [ Style Reference, character sheet(s)…, location / prop still(s)… ]
```

Quality tier follows the asset: **high is the character and keyframe tier;
medium is the location and prop tier.** A sheet is always landscape — only
keyframes follow the project's shape (16:9 or vertical 9:16). Exact command,
flags and live rates: `fal-ai-ops`.

## Dimension rules (why the numbers are what they are)

- **Both edges must be multiples of 16.** Max edge 3840, aspect ratio up to 3:1,
  655,360–8,294,400 pixels in total.
- **An invalid pair is snapped silently, not rejected.** Ask for 1920×1080 and
  1920×1072 comes back with no error — which is why you use the sizes in the
  table and never invent one.
- `image_urls` takes up to **16** references; an optional `mask_url` marks white
  as editable and black as preserved.

## Character sheet — 3 panels, landscape, ONE face

Three equal-width panels on one landscape frame, in this order:

1. **Face + shoulders close-up** — front view, neutral, ordinary expression
2. **Full-body front** — A-pose, feet at the bottom of the frame
3. **Full-body back** — the same pose as the centre panel

Rules:

- **ONE face.** The face lives only in the close-up panel. Clear it from the
  full-body panels; if the sheet is later edited (an outfit change, a re-light),
  paste the **original full-quality face** back over the edited one — every edit
  degrades skin detail, and a degraded face is the plastic look the video model
  then amplifies.
- **Describe the character as realistic and unpolished** — "avoid conventionally
  polished or symmetrical features". That one clause is the difference between a
  person and a stock face.
- **Plain neutral grey (#e0e0e0) backdrop.** No props, no scene, no decoration.
- **Neutral studio lighting only.** A sheet lit for one scene is locked to that
  scene, which is exactly why scene mood never goes on a sheet.
- **A-pose for the body panels** — arms slightly out with the palms forward,
  which stops the arms adhering to the torso. No handheld objects.
- **No text anywhere**, and in particular **never put the character's name in
  the prompt**: the model renders it as caption text on the image. Identify the
  subject by description ("a 40-year-old man, wiry, sun-worn"), never by name.
- **End the prompt with exactly this sentence:**
  `No text, no labels, no watermark, no captions anywhere.`

> **Optional extra — a clean cutout asset.** A single full-body A-pose on plain
> white, described with deep focus and sharp edges and no background blur, for
> texture reference, cutout work or a post-production extraction. It is a
> *separate* asset, never a replacement for the 3-panel sheet: the sheet is what
> downstream shots are generated against.

## Location sheet — 4 panels, 16:9

Four distinct views of **one** place, locked to one time of day and one lighting
state:

1. **Wide establishing** — top-left, and the largest panel of the four
2. **Alternate wide** — the same space from roughly 90°
3. **Corner depth** — a third angle that reveals how far the space runs
4. **Detail shot** — one key feature, material or texture

Rules:

- **No people.** Environment only; at most one to three small distant figures
  for scale in a public space, none in an empty one.
- **Give it dimensions** ("roughly 6m × 8m, ceiling 2.8m") so the model can
  reconcile four angles into a single place.
- **Every panel a distinct angle** — repeat an angle and you have paid for a
  panel that adds nothing.
- **Consistent lighting across the panels.** Time-of-day mood belongs in the
  shot prompts, not here.
- End with the same closing constraint as the character sheet.

## Prop sheet — 4 panels, grid

Front · side (90°) · back · close-up detail: neutral grey (#e0e0e0), studio
lighting, no cast shadows, one consistent scale across all four panels.

**No hands, no scene context, no labelling** — unless the text is genuinely part
of the object (a printed page, a screen, a sign), in which case describe it
explicitly rather than letting the model invent it. End with the same closing
constraint.

## The prompt skeleton (all three sheet types)

Sheets are written to one shape — a full-sentence brief, not a keyword soup:

```
[LAYOUT & FORMAT] of a [SUBJECT DESCRIPTION], featuring [N] distinct views:
[VIEW BREAKDOWN]. The subject has [MATERIAL & OUTFIT / ARCHITECTURE DETAILS].
[REALISM & LIGHTING TRIGGERS]. [ISOLATED BACKDROP CLAUSE].
No text, no labels, no watermark, no captions anywhere.
```

**Layout & format.** Name the sheet and its panel count, matching the spec
above — "a three-panel character reference sheet, landscape" · "a 4-panel
location reference sheet".

**Subject.** The approved bible text (see `ai-film-character-set-design`),
compressed to what is visible: age, build, face, hair, skin; for a place, its
architectural identity. **Never the name.**

**View breakdown.** State every panel's content and position, in order. This is
what stops two panels showing the same angle and stops panels bleeding into each
other.

**Details.** Outfit and materials for a character; architecture, surfaces and
fixed elements for a place; materials, scale and wear for an object.

**Realism triggers.** Photorealism comes from camera vocabulary, not from praise
words. **Pick one from each row and no more:**

| Row | Choose one |
|---|---|
| Camera body | full-frame DSLR · a medium-format studio body · a 35mm film body |
| Lens | 85mm f/2.8 portrait (no facial distortion) · 100mm f/4 macro (edge clarity) · 50mm f/2.8 (natural field of view) |
| Colour | clean neutral digital · warm film-stock colour · soft pastel film colour · saturated film colour |
| Lighting | soft three-point studio light · high-key softbox · butterfly with a soft hair light · clamshell beauty light · flat overcast daylight (locations) |
| Micro-texture | visible skin texture and pores · individual hair strands with flyaways · authentic surface grain and wear · real material detail, no smoothing |

**Never** reach for "hyperrealistic", "ultra realistic", "8K" or "flawless" —
those push the render towards the plastic look rather than away from it. Lens,
light, skin and material do the work.

**Closing clauses.** Always end with the isolated backdrop clause (a seamless
neutral backdrop for a sheet), then the constraint sentence, verbatim:
`No text, no labels, no watermark, no captions anywhere.`

### Sketches (replace every bracket)

```
Three-panel character reference sheet, landscape, of [a 40-year-old man, wiry,
sun-worn, close-cropped grey hair, weathered skin, ordinary unpolished
features], featuring three equal-width panels side by side on one frame: left
panel face and shoulders close-up, front view, neutral expression; centre panel
full-body front view in a relaxed A-pose, arms slightly out, palms forward;
right panel full-body back view, same pose as the centre. He wears [a faded
olive canvas work jacket over a plain grey knit top, straight dark cotton
trousers, scuffed leather boots]. Full-frame DSLR, 85mm f/2.8, soft three-point
studio lighting, visible skin texture and pores, individual hair strands,
isolated on a seamless neutral grey background. No text, no labels, no
watermark, no captions anywhere.
```

```
4-panel location reference sheet, 16:9 landscape, of [a modest corner bakery
interior, roughly 6m × 8m, ceiling 2.8m], featuring four distinct views of the
same place: top-left wide establishing view down the length of the shop,
top-right alternate wide view from the far corner at roughly 90°, bottom-left
corner depth view showing the back wall and doorway, bottom-right detail shot of
the worn counter edge and pastry case. [Exposed brick, warm pendant lights, worn
wood tables, brass fittings]. Full-frame DSLR, 35mm f/5.6, flat overcast
daylight through the shopfront, authentic surface grain and wear, no people. No
text, no labels, no watermark, no captions anywhere.
```

```
4-panel prop reference sheet of [a scuffed black flip phone, roughly 10cm, worn
matte plastic, one cracked corner, screen off, no text], featuring four distinct
views: front, side at 90°, back, and close-up detail of the worn hinge and the
cracked corner. Neutral grey backdrop, studio lighting, no cast shadows,
consistent scale across all four panels. Full-frame DSLR, 100mm f/4 macro,
visible material grain and scuffing. No text, no labels, no watermark, no
captions anywhere.
```

## Reworking a sheet (or any asset image)

Two different jobs — pick by what changed:

- **The words changed** (a bible field was edited: wrong jawline, wrong era,
  wrong room) → re-compose the sheet prompt from the amended fields and re-run
  the **whole sheet** at the same dimensions and quality tier. The Style
  Reference still rides first.
- **The image is the instruction** (the user points at a take they can see —
  "extract the top-left panel and go wider", "re-light this one") → **edit that
  image**: upload it, pass it in `image_urls` behind the Style Reference,
  describe what the image shows plus the ONE change, and deliver a **single**
  image at that asset's aspect ratio and quality tier. Never re-run the
  whole-sheet text prompt for an image-driven change.
- **Always deliver under a new versioned filename** and leave the old take in
  place. The user stars the take they want — only the user stars anything.

## When a sheet standard changes

A sheet standard has more copies than it looks. Classify the change first, then
say the scope out loud — **name which files are touched and get agreement before
editing**; never batch a multi-file rewrite silently.

- **A LAYOUT change** (panel count, panel order, panel content) — this is a
  layout edit, and it propagates into every prompt block that describes a sheet.
- **A model / dimension / quality change** — that is a *registry* change: it
  propagates *into* the layout files. Update the registry entry and the spec
  table above and leave the layout descriptions alone. A registry row is not the
  layout standard, and a layout edit is not a registry edit.

Surfaces that usually carry a copy of the standard:

1. **this pack** — the spec here, the asset templates in
   `ai-film-prompt-engineering`, the field rules in
   `references/bible-and-asset-writing.md`
2. **the user's own copies** — prompt files, notes and downloaded prompt packs;
   ask which ones they keep instead of assuming
3. **your agent's skills folder** — a local skill that repeats the panel count
   or the dimensions
4. **the studio app's templates** — any placeholder or label naming the sheet
   format; the app caches its templates, so restart it after editing one

Then prove the sweep with **two passes** over every surface: one grep for the
**new** wording (expect exactly the files you edited) and one for the
**retired** wording (expect hits only inside files carrying an explicit
banner). Grep for the older format names as well, not only the current one.

**Never delete a retired format** — it is the record of the retired pipeline,
and assets generated with it may still need re-referencing. Banner it and keep
it:

```markdown
> **SUPERSEDED (<date>).** Replaced by <the standard that is in force>. Kept
> because assets generated with it may still need regenerating or referencing.
```

…then leave the old template verbatim below the banner. If the retired text
still claims to *be* the standard somewhere in its body, fix that claim too — a
banner on top with a contradicting body underneath is worse than no banner.

## Pitfalls

- **A format that still says "replaces X".** Between the current standard and
  the first one, intermediate formats often still claim authority. Grep for
  every old format name and banner each claimant.
- **Second copies in fixtures and tests.** Prompt text hides in example files
  and in the string pairs of any script that generates them — both have to
  change or the check passes on stale text.
- **Borrowing one model's dialect for another.** Panel layout is a convention;
  each model has its own prompt dialect and its own real dimensions. When a new
  model is tried, re-verify the prompt structure and the dimensions rather than
  carrying the old vocabulary across.
- **Editing the layout to fix a registry fact.** Wrong size or quality is a
  registry edit — do not rewrite the panel description to compensate.
- **Forgetting to restart.** A studio template change does not appear until the
  app is restarted.

## See also

- `ai-film-character-set-design` — writing the bible text a sheet prompt is composed from
- `ai-film-prompt-engineering` — image and video prompt shapes
- `ai-film-keyframe-authoring` — first-frame prompts and the project's shape
- `fal-ai-ops` — the exact command, the quality flags and live rates
- `studio-ops` — where sheets are saved, the naming standard, the review loop
