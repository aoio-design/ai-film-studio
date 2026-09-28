---
name: ai-film-marketing-copy
description: "Promotional copy for AI film episodes and series — loglines, episode blurbs, YouTube descriptions, channel/about-page bios, and support links. Covers single- and dual-protagonist logline formulas, teaser-paragraph templates, structured description layouts, and studio-bio structure."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [marketing-copy, loglines, episode-descriptions, youtube-descriptions, promotional-copy, publishing]
    related_skills: [ai-film-content-strategy, ai-film-scriptwriting, ai-film-pipeline, studio-ops]
---

# AI Film Marketing Copy

## Overview

The copy that gets a finished film watched: the one-line hook, the blurb on the tile, the description under the video, and the sentence that says who made it. This skill produces **text only** — the film itself and its review live in the studio (see `studio-ops`), and the publishing mechanics (which platform, how often, what the algorithm rewards) live in `ai-film-content-strategy`. This is the words.

**Core rule:** the hook sells the *tension*, not the plot. The moment a blurb starts explaining the story, it has stopped working.

| Deliverable | Length | Job |
|-------------|--------|-----|
| **Logline** | One sentence, 20–30 words | Structural tension — what the story *is* |
| **Blurb** | 3–5 sentences | Atmosphere and hook — why to press play |
| **Description** | 5 sections | Context, episode list, production notes, links, tags |
| **Studio blurb** | 3–5 sentences | Identity — who makes this and why |

**Where the copy goes:** write it to a file under `$HERMES_HOME/` (the only path that survives an app update) and tell the owner the path so they can copy-paste it. Keep one copy file per series so the tone and the boilerplate stay identical across episodes.

## When to Use

- The owner has finished (or is close to finishing) a film and wants to publish it
- Writing a logline for an episode or a series
- Drafting an episode blurb/teaser paragraph for a tile, a pinned comment or a social post
- Writing a platform description for a series (context, episode list, production notes, tags)
- Drafting a channel "About" page or a studio bio
- Wanting a structured template instead of a blank page

---

## Logline Formulas

A logline is one sentence of **structural tension**: who wants what, what blocks them, what it costs. It is not a summary — it is the shape of the problem.

### Single-Protagonist

```
When [PROTAGONIST] wants [GOAL] in [SETTING],
but [OBSTACLE] stands in their way,
they must [ACTION] before [STAKES] or lose [CONSEQUENCE].
```

**Sci-fi example:** *"In a colony on Europa where memories can be traded like currency, a rookie archivist discovers someone is erasing her own past — one citizen at a time."*

### Dual-Protagonist (two halves of one puzzle)

For a series where two leads each hold half the answer — the researcher + witness archetype from `ai-film-scriptwriting`:

```
When [PROTAGONIST_A] discovers [EVIDENCE] linking to [PROTAGONIST_B],
they must convince [PROTAGONIST_B] to [SHARED_ACTION] before [STAKE],
or [CONSEQUENCE] will bury the truth.
```

**Placeholder example:** *"When an archivist finds her missing supervisor's encrypted notes, she must convince the only witness — a man the city has written off as a crank — to help her read them, before whoever emptied the office finds her next."*

Keep every worked example **plainly generic**. Roles ("the archivist", "the father") and throwaway names (DANA) are safe; characters, titles or premise details lifted from a real series you watched are not — a template should never carry someone else's story into your copy.

**Logline checklist:**

- [ ] One sentence, 20–30 words, sayable in a single breath
- [ ] Contains a goal, an obstacle, and a cost
- [ ] The setting is named only when the setting *is* the hook
- [ ] No episode numbers, tool names or episode-specific detail

---

## Episode Blurb (Teaser Paragraph)

A short paragraph (3–5 sentences) for a streaming tile, a pinned comment or the opening lines of a description. It opens on a specific object or event, shows how the leads' worlds collide, and ends on a question or a threat.

### Template

```
[PROTAGONIST] expected [ROUTINE_THING]. What arrived was [UNEXPECTED_OBJECT/EVENT]
that [CHANGES_EVERYTHING]. [SHE/HE] doesn't understand most of it. But one thing
[SHE/HE] does recognize: [SPECIFIC_DETAIL/CONNECTION]. When [SHE/HE] tracks down
[SECOND_PROTAGONIST], they realize [THE_CONNECTION_THEY_SHARE] — and they're not
the only ones looking for it.
```

### Placeholder Example

*"DANA expected an ordinary night shift. What arrived was her supervisor's life's work — encrypted notes, a worn notebook, and a warning that the truth is older than the story she was told. She doesn't understand most of it. But one thing she does recognize: a circled photograph of a man the city has written off as a crank. When she tracks him down in a bus-station cafe, they realize the research connects them in ways neither of them is ready for. And they're not the only ones looking for it."*

**Rules:** open on a concrete object, not a mood. Don't name episode numbers, budgets, tools or runtimes in the hook paragraph — the blurb hooks, it does not log. End on the question the next episode answers.

---

## YouTube / Platform Description Structure (Series)

For a series page or an episode upload, the description does two jobs: it tells a cold viewer what this is, and it gives the platform something to index. Use this order.

### 1. Series Hook (2–3 sentences)

Establish premise and stakes. Answer "what is this series about?" in plain language before the first link or emoji. Reuse the same hook across episodes so a viewer arriving mid-season still knows what they've found.

### 2. Episode List

Numbered episodes with one-line summaries. For a season page:

```
Season 1 Episodes:
1. [Episode Title] — [One line: what changes for the protagonist].
2. [Episode Title] — [One line].
3. [Episode Title] — [One line].
```

Keep the one-liners spoiler-light and in the series' voice — this list is also an on-ramp for viewers who were told to start somewhere other than episode 1.

### 3. Production Notes

How it was made, in two or three lines, identical across every episode so the channel reads as one project. Name the tools you actually used — nothing you didn't.

```
🎬 Keyframes with [your image model]; clips with [your video model]; assembled in [your editor].
📝 Script, shot breakdown and this description written with [your agent/pipeline].
```

### 4. Support Links

Only include a support link if you actually have one, and keep it one line. Generic "support us" gets ignored; a specific, honest sentence works.

```
☕ Support the series — [YOUR_SUPPORT_LINK]
```

Never promise an incentive, credit, reward or discount you cannot personally deliver, and never state a rate you have not verified — a link that disappoints costs more than no link.

### 5. Hashtags

5–10 tags: series title, genre, format, studio, platform.

```
#AIFilm #SciFiMystery #[SeriesTitle] #[StudioName] #[Platform] #ShortFilm
```

---

## Channel & Studio Blurb (About Page / Studio Bio)

A short identity statement (3–5 sentences) with four beats: who you are, what you make, how it's made, why it exists.

### Template

> **[STUDIO NAME]** is an independent AI film studio based in [LOCATION], making original [GENRE] series with a fully AI-native pipeline — script to screen, no cameras and no crew. Our films run [FORMAT: e.g. 3–5 minute shorts, released weekly] and are built shot by shot from [one or two specifics: generated keyframes, generated clips, an original score]. Our mission: [MISSION STATEMENT — what you are trying to prove, in your own words].

**Notes:**

- Claim only what you can show. No view counts, awards, festival selections or "as seen on" lines unless they are real and current.
- "Fully AI-native" is a selling point, not a confession — say it plainly and let the work answer for itself. Voluntarily labelling content as AI-generated is also the honest default on every platform.
- One studio blurb, used everywhere. Diverging bios across channels read as three different projects.

---

## Copy QA Before It Ships

- [ ] The logline is one sentence of tension, not a plot summary
- [ ] The blurb opens on an object or an event, not a mood
- [ ] Logline ≠ blurb (see Pitfalls)
- [ ] Production notes and the series hook are byte-identical to the previous episode's
- [ ] Nothing in the copy names a real person, brand or organisation
- [ ] Every link works and every claim is one you can back up
- [ ] Episode titles in the list match the titles in the studio project
- [ ] Copy file saved under `$HERMES_HOME/` and the path given to the owner

---

## Pitfalls

1. **Don't embed plot metadata in blurbs** — a blurb hooks, it does not explain. No episode numbers, tools, runtimes or production detail in the hook paragraph.
2. **Keep production notes separate** — "how it was made" and "what it's about" are two sections, never one sentence.
3. **Support links need context** — a specific line or no line at all. Vague appeals are invisible.
4. **Hashtags: quality over quantity** — 5–10 relevant tags beat 30 spammy ones. Include the series title, genre, format and studio.
5. **Loglines are NOT blurbs** — a logline is one sentence of structural tension; a blurb is a short paragraph of atmosphere and hook. Don't substitute one for the other.
6. **Test the logline aloud** — if you can't say it in one breath, cut it.
7. **Don't reuse another series' copy** — boilerplate is fine, but the series hook, blurb and title list must be written for *this* series or the audience notices the seams.
8. **Never invent a number, an incentive or a credential** — placeholder text in a shipped description is a real defect; leave it blank rather than guess.
