---
name: ai-film-craft-fundamentals
description: "Filmmaking craft for AI films: what each shot is for, shot size as emotional distance, blocking, coverage (including the axis and one-speaker-per-clip dialogue pattern), how a scene is built from beats, pacing and tension/release, plus the visual-storytelling choices (mise en scène, colour, juxtaposition, metaphor, the rule of three, irony) that make clips cut together into a film."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [filmmaking, craft, coverage, blocking, pacing, shot-sizes, visual-storytelling]
    related_skills: [ai-film-cinematography, ai-film-scriptwriting, ai-film-keyframe-authoring, ai-film-pipeline]
---

# AI Film Craft Fundamentals

## Overview

Everything in this pack so far tells you how to *generate*: which model runs which stage,
how to author a keyframe, how to write a prompt in a given style. This skill is the layer
underneath all of that — **what each shot is for, where the camera goes, how a scene is
built out of shots, and how it should move.**

Craft is the difference between a folder of good-looking clips and a film. Two projects can
use the identical models at the identical settings and land worlds apart, because one of
them decided shot sizes, blocking, coverage and rhythm on purpose and the other generated
a list of pretty pictures. Generation quality is a dial; craft decides whether the dial is
worth turning.

**Where the neighbouring rules live (don't duplicate them here):**

| You need | Read |
|---|---|
| The shot-size / angle / lens / lighting / composition tables, style archetypes, film-look recipes | `ai-film-cinematography` |
| Beat sheets, episode structures, loglines, dialogue, screenplay format | `ai-film-scriptwriting` |
| The first-frame prompt format and reference order | `ai-film-keyframe-authoring` |
| The order of work, the approval gates, the two video lanes | `ai-film-pipeline` |
| Anything with a price in it | `ai-film-cost-benchmarking` |

## When to Use

- Breaking an approved script into a shot plan (what shots, in what order, at what size)
- Deciding where the camera goes in a scene, and how many shots the scene needs
- Staging a scene — who stands where, who moves, who is closest to the lens
- A scene reads flat, confusing, or "like slides" and you need to find out why
- Setting the rhythm of an episode (cut speed, holds, tension and release)
- Judging whether a shot earns its place at all before it costs anything

---

## 1. The unit of the work: one shot, one job

A shot is the smallest unit of meaning in the film. Before a shot prompt exists, it should
have a **job line** — one sentence, written for yourself, naming what the shot does:

- "establish the room and that she is late"
- "show he has decided"
- "reveal the knife on the counter"
- "let her reaction land"

Rules that follow from that:

- **If you can't name the job, cut the shot.** Every shot costs a keyframe and a clip.
- **One change per shot.** The shot's first frame and last frame should differ *only* in
  the change the shot exists for. That is the whole first-frame/last-frame contract — if
  two things change (she stands up *and* the light shifts *and* the room is different),
  the model interpolates mud and the edit has nothing clean to cut on.
- **Enter late, leave early.** Start after the action has begun (mid-motion, the moment
  before the turn) and end before it fully resolves. A shot that runs an action
  top-to-tail reads as flat and is the most common reason an AI scene feels like a
  screensaver.
- **Three beats make a pattern.** Setup, setup, turn. Three shots in a scene, three
  attempts at a goal, three items of information — the third one is where the meaning
  changes. If a scene has only two beats, it usually has no turn yet.
- **A shot must serve the scene, not the shot.** A beautiful frame that doesn't advance
  the scene is decoration.

## 2. Shot size is emotional distance

Shot size is not a zoom setting — it is how close the audience is allowed to stand to
someone. The full table with prompt keywords is in `ai-film-cinematography`; the craft
reasoning is here:

| Size | Audience position | Use it for |
|---|---|---|
| **Extreme Wide (EWS)** | Observer, far away | Scale, isolation, "this world is bigger than them" |
| **Wide (WS)** | In the room | Where we are, entrances, full-body action |
| **Medium Wide (MWS)** | A couple of metres away | Dialogue where bodies matter — walking, working, two people with space between them |
| **Medium (MS)** | Across a table | Standard dialogue; the neutral, workhorse shot |
| **Medium Close-up (MCU)** | Confidant | Emotional dialogue; the frame where performance reads |
| **Close-up (CU)** | Intimate | The reaction; the moment the audience should feel, not read |
| **Extreme Close-up (ECU)** | Inside their head | Emphasis and symbol — eyes, hands, the object that matters |

- **Wider = more context, less intimacy. Tighter = more feeling, less world.** Move
  between those two poles deliberately.
- **A push from wide to close is the character's arc made visual** — it is the cheapest
  way to say "this went from a problem to a personal one" without a line of dialogue.
- **Progression beats randomness.** For a scene, plan a direction (wide → medium → close,
  or the reverse for a reveal) instead of picking sizes shot by shot.
- **Generation reality check.** Faces are most convincing at **MCU–MS** range — that is
  where the hero frames and dialogue shots should live. ECU can read waxy or
  over-smoothed, and wide shots with several people can garble anatomy and background
  detail. So: spend your tight shots on faces, and use silhouette, distance or an
  abstraction when a wide shot with a crowd is the only way to tell the story.
- **A close-up has to be earned.** Cut to a CU *because* the previous beats built
  something to read on the face — not to make a flat scene feel dramatic.

## 3. Blocking — putting bodies in space

Blocking is where the characters are, how far apart, at what height, facing which way,
and how they move through the space. In practice it is the fastest way to communicate
power, intimacy and conflict **before anyone speaks**:

| Blocking choice | What it says |
|---|---|
| Standing vs seated, high vs low ground | Power, status, who is holding the room |
| Distance between two people | Intimacy or threat — how much space is being held |
| Facing vs turned away, eye contact vs none | Connection, evasion, who is being shut out |
| Who moves, who stays still | Agency. Movement draws the eye; stillness reads as control or defeat |
| What sits between them and the lens | Obstruction = distance, secrecy, entrapment (doorways, bars of light, furniture) |
| Who is on their feet when someone enters | Protocol, threat, informality — one image, no dialogue |

**Blocking inside an AI clip — the rules that matter:**

- **The keyframe fixes the staging.** The first frame is where everyone is standing; the
  video prompt only owns what *changes* from there. Writing staging into the clip prompt
  that contradicts the keyframe produces drift, not performance.
- **Keep the move small enough to happen in the clip's length.** A 5–6s shot can carry one
  clear change of position, one gesture, one head turn. A whole scene's worth of
  movement squeezed into one clip reads as a wobble.
- **Don't restage mid-clip.** Having a character cross the room *and* sit down *and*
  another enter means three things changing at once — split it into coverage instead.
- **Eyelines and screen direction are decided at the keyframe.** If A looks frame-right,
  the reverse shot's A-alternate must look frame-left or the edit reads as two people
  staring at the same wall.
- **Hold the axis.** Pick the line between the two characters (or between the character
  and what they're looking at) and stay on one side of it from first frame to last frame
  of a scene. Crossing it without a neutral shot flips the geography and disorients the
  audience — the classic "which side of the room are they on?" failure.
- **Change the angle meaningfully, not accidentally.** Two shots of the same subject from
  near-identical positions cut as a stutter; move the camera a real amount (roughly 30°
  or more) or change the size.

## 4. Coverage — how a scene becomes a set of shots

Coverage is the set of shots you generate so the scene can be cut. It is planned in the
script stage, counted by the shot auditor, and paid for at the clip stage — so it is both a
story decision and a budget decision.

### The standard breakdown

Each script scene splits into **sub-scenes / shots** (1A, 1B, 1C…), one camera position
each, one keyframe each, one clip each. The working convention:

| Letter | Shot | Job |
|---|---|---|
| **A** | Wide / establishing | Where we are, who is in the scene, the geography |
| **B** | Medium / two-shot / over-the-shoulder | The exchange — dialogue, interaction, bodies in space |
| **C** | Close-up / ECU | The reaction, the decision, the detail that turns the scene |
| **D** (when needed) | Insert / cutaway | The object, the clock, the hands, the other room — the cheapest coverage there is |

- **Three sizes per scene that has a turn.** A/wide, B/medium, C/close is the minimum
  shape that gives you something to cut. A scene with only one camera position has no
  edit, no rhythm, and no reaction.
- **Dialogue is reverse-shot, one speaker per clip.** The video model syncs one mouth to
  one voice per clip, so an exchange is written as pairs of shots (a single on A, then a
  single on B from the opposite side of the axis), each with its own keyframe. Lines stay
  short. Never plan a shot that names two speakers — it cannot be generated as written.
- **The master + singles pattern.** Generate one generous wide that holds the whole beat
  (a safety and an establishing shot you can cut back to), then singles for the
  performance. The wide is your insurance if a single comes back unusable.
- **Cutaways and inserts are the best value in the whole production.** Hands, a prop, a
  doorway, a screen, a detail of the set — no faces, so the image model rarely fumbles
  them, they are short, and they are what saves an edit that doesn't cut. Plan two per
  scene with a turn.
- **End the scene on the reaction, not the action.** The last shot of a scene is usually a
  C — the face after the decision, held a beat longer than is comfortable.
- **Coverage is a cost lever, not a free choice.** Every extra shot is one more keyframe
  and one more clip; a scene covered in nine shots costs roughly three times a scene
  covered in three. Cover it enough to cut, then stop.

## 5. How a scene is built

A scene is not a slab of time — it is a small story with its own shape. Build it in beats
and let the beats choose the shots.

| Beat | What it does | Typical coverage |
|---|---|---|
| **Open** | Land us in the space and the situation, mid-motion, on a question | A — wide, or a strong single if the space is already known |
| **Situation** | Establish what's at stake and who wants what | B / two-shot / OTS |
| **Escalate** | Add pressure; each beat is louder, faster or more intense than the last | Alternating B and C, cutting faster |
| **Turn** | Something changes — a reveal, a decision, a reversal | C or ECU on the moment, or an insert that shows the audience what a character can't see |
| **Release** | The consequence lands | The held shot. Stay on the face one beat longer than comfortable |
| **Exit** | Tell us the next question | The reaction, or a cutaway that sends us onward |

- **Every scene changes a value.** Something goes from safe to threatened, from hopeful to
  lost, from suspicious to certain. If nothing changes, the scene is exposition and should
  be either shortened into a beat of another scene or cut.
- **Escalation, not repetition.** Repeating the same beat louder doesn't escalate; each
  beat must change the situation or the information.
- **The release must be proportional to the tension.** A hold only lands if anticipation
  was built. Tension with no release reads as flat, and a release with no build reads as
  arbitrary.
- **Emotion lives in the space between events** — the pause before answering, the look
  after the line, the shot that holds when the audience expects a cut. Budget for those
  shots; they are what people remember.
- **Alternate fast and slow scenes.** Two slow scenes in a row = a lull. A breath before a
  turn makes the turn hit.
- **Exposition dies on contact.** Never let a character explain the world in a neutral
  scene. Either show the world being used, or put the information inside an emotionally
  charged moment — and spread it across scenes instead of handing it over in one lump.
- **Plant before you pay.** Only introduce what will pay off (Chekhov's gun). A detail
  visible in an early keyframe and central in a later one reads as intentional writing,
  and in this medium it is nearly free to plant — it's one prop in one frame.

## 6. Pacing

Pacing is the rhythm of *information*, not just cut speed. Fast dialogue is not fast pace;
fast revelations are.

| Layer | What it controls | How to steer it |
|---|---|---|
| **Scene pacing** | How long a scene lasts | Cut shorter when tension is high, let it breathe when emotion needs room |
| **Sequence pacing** | How scenes are ordered | Alternate fast and slow; never two slow scenes in a row |
| **Film pacing** | The overall tension curve | Draw the curve: peaks and valleys, one big peak, one last beat after it |
| **Tempo** | The speed of information *within* a scene | Fast cuts ≠ fast pace — new facts per second is what the audience feels |

### Pacing by the numbers, and the lane constraint

| Feel | Traditional cut rhythm | How to get it here |
|---|---|---|
| Urgent | cuts every 2–4s | Generate 5–6s shots whose *action* only occupies the middle — then trim to the usable 2–4s in the edit |
| Medium | cuts every 5–10s | The natural shot length of the plan: one clean change per shot, cut at the change |
| Slow / held | 10–30s holds | A single long clip on the higher-quality lane (which supports long takes), or several shots of the *same framing* cut together to hold the beat |

**The important translation:** you cannot generate a 2-second shot — the premium lane's
floor is 4 seconds and the budget lane's is a hard 5 seconds. So **fast pacing is made in
the edit, not at the generator.** Plan every shot with a couple of seconds of usable head
and tail: start the action a beat *after* the shot begins and end it before the shot
finishes, and you can cut a 5–6s clip down to anything. A plan that writes the action
across the entire clip duration has nothing to trim and will cut as sluggish no matter how
many shots it has.

**Symptoms and fixes:**

| Symptom | Fix |
|---|---|
| Too slow — the audience drifts | Cut 15–20% of the runtime. Move a complication or reveal earlier |
| Too fast — nobody can follow | Insert a breather shot. Let a moment land before moving on |
| Uneven — bursts of interest, then flat | Give every scene a mini-arc; redistribute where information lands |
| No variation | Alternate tension and release. The release is what makes the tension mean anything |

## 7. Visual storytelling that carries the scene

The frame is a sentence. These are the elements that write it — and each one is
expressible in a keyframe prompt, which is why they matter more here than on a physical
set.

### Mise en scène — everything in the frame, arranged on purpose

| Element | The question to ask |
|---|---|
| Setting | What does this place say about who lives here? |
| Lighting | Where is the light *coming from*, and what does that do to the mood? |
| Costume | What does this outfit say about their state in this scene? |
| Blocking | Who is where, and what does the arrangement say about power or intimacy? |
| Props | Does this object mean something, or is it clutter? |
| Colour | What dominates the frame, and has it changed since the last scene? |

If an element doesn't serve the story, remove it. Decoration is the most common way a
well-prompted frame still ends up saying nothing.

### Colour

Pick one dominant palette for the project and hold it; shift it at the turn. A character
walking from a cold-lit room into a warm-lit one *is* a change of state, with no dialogue.
The palette table and the film-look recipes are in `ai-film-cinematography` — the craft
rule is consistency with a deliberate break, not variety.

### Juxtaposition — meaning from contrast

Two things placed together make a third thing. The match cut (a shape or motion carrying
across two shots), the thematic pairing (luxury and decay in one frame), the opposition of
two characters, the tonal clash (something absurd inside a serious moment). Every one of
these is a composition decision you can state in a prompt.

### Metaphor

An image standing for an idea: the setting as an emotional state, a character as a
concept, a repeated visual as the film's argument. Film metaphors are strongest when they
are *physical and specific* — a character framed through doorway bars reads as trapped
without a word of exposition.

### The rule of three

Three is the smallest number the brain reads as a pattern: setup, setup, turn. Three
shots, three items of information, three attempts (the first fails quickly, the second
fails harder, the third changes everything). Give the third beat the meaning.

### Irony — the tension machine

- **Verbal** — a character says the opposite of what's true.
- **Situational** — the outcome is the reverse of the expectation.
- **Dramatic** — the audience knows something the character doesn't.

Dramatic irony is the most useful one: show the audience what the character can't see (an
insert, a cutaway, a detail in the corner of the frame) and every following shot becomes
tense by itself.

## 8. Why some cheap-looking footage reads expensive

The techniques that make a modest production look considered — all of them are promptable:

| Technique | The move |
|---|---|
| **Contrast ratio** | Deep shadows hide what you don't have. What the audience can't see, they fill in |
| **Motivated light** | Light from a visible source — a lamp, a window, a screen — reads as real |
| **Unified palette** | Two or three dominant colours held across the whole film make any footage look intentional |
| **Depth of field** | Shallow focus on the subject hides the background |
| **Texture** | Tactile surfaces — fabric, concrete, metal, skin — read as production value |
| **Intentional framing** | A composed frame with a reason; a badly composed one cannot be saved in the edit |
| **Sound** | Clean audio, ambience and music are half of the felt quality of a film |

**And the hierarchy that governs everything above:** audiences forgive imperfect visuals
far more readily than they forgive an unclear or unnecessary shot. Stunning images with no
story are forgotten in minutes; a well-built scene with modest images is remembered.

## 9. Emotion — how the audience is made to feel

| Mechanism | How it works |
|---|---|
| **Identification** | The audience sees themselves in the character — a relatable flaw, a universal want |
| **Anticipation** | We know what's coming and don't want it (dramatic irony) |
| **Payoff** | The moment we've been waiting for — the reunion, the choice, the sacrifice |
| **Contrast** | Joy hits harder straight after sorrow; cut between the two |
| **The held moment** | Stay on the reaction longer than is comfortable — the audience processes with them |

By genre, the primary feeling to build: **sci-fi — awe and unease** (scale plus the
uncanny), **romance — longing before joy** (separation, the almost-kiss), **comedy —
surprise that feels inevitable**, **thriller — anxiety then relief**, **drama — empathy
then catharsis**.

Emotion is never in the pixels. It comes from the script, the staging and the *withholding*
of the cut — which is why the shots you plan around a reaction are worth more than the
shots you plan around an action.

## 10. Common pitfalls

1. **A protagonist with no flaw.** A perfect character is an uninteresting one; the story is
   the flaw being overcome.
2. **Exposition in the first scene.** Reveal through conflict and use, not explanation.
3. **No second track.** Where a love, friendship or mentorship thread is missing, the film is
   plot without theme.
4. **A turn that comes from nowhere.** A good reversal is surprising *and* inevitable —
   plant the clue where it is invisible on first viewing.
5. **Ignoring the rule of three.** Two beats of a pattern leaves the scene unresolved;
   four wastes a shot.
6. **Mood without meaning.** A gorgeous frame that doesn't serve the scene is a screensaver.
7. **Camera without purpose.** A tilted frame or a close-up must have a psychological reason.
8. **An unearned close-up.** Cut to a face because the scene built something to read.
9. **Emotion without setup.** The audience cannot feel what it wasn't prepared to feel.
10. **Two changes in one clip.** A shot whose keyframe and prompt disagree about staging,
    lighting or position comes back as a morph.
11. **Coverage that can't cut.** Crossing the axis, eyelines that don't oppose, or two
    consecutive near-identical angles — the individual shots look fine and the scene
    won't assemble.
12. **Too much camera movement for a short clip.** A full dolly from wide to close inside
    5 seconds is more distance than the clip can carry; use a subtle move and let the cut
    do the work.
13. **Lighting that shifts mid-clip.** Keep one light logic inside a shot unless the change
    *is* the reveal.
14. **Unusable tails.** Writing action across the whole clip length, so nothing can be
    trimmed and the pacing dies in the edit.

## 11. The craft pass — run this before any batch

Cheap, and it prevents the expensive kind of rework:

1. Every shot has a one-line job. Anything without a job is cut.
2. Every scene has a beat map: open, escalate, turn, exit — and a value that changes.
3. The scene has at least three sizes (wide / medium / close) and, if it's about objects,
   a cutaway or two.
4. The axis is chosen and the eyelines oppose across the dialogue pairs.
5. One speaker per clip on every shot; no line over ~5 seconds.
6. Each shot changes exactly one thing from its keyframe to its last frame.
7. Palette, light logic and lens feel are stated per scene and held across its shots.
8. Every shot's action sits in the middle of its length, with usable head and tail either
   side.
9. Shot durations are inside the lane floors (4s minimum only on the higher-quality lane;
   the lower-cost lane cannot go below 5s), and the scene total hits the runtime target.
10. Run the shot auditor instead of adding the durations up by hand — it reports the shot
    count, the runtime and a cost range, and flags the two things that silently break a
    shoot (multiple speakers in one clip, and durations under a lane's floor). It lives at
    `scripts/audit_shots.py` in this pack.
