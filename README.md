# AI Film Studio

A private **shot-review studio** for AI film production: no login on the server itself, and your Cloudflare Access gate (if you put one in front of it) for your own devices. It shows every shot of your film as a card — script text, audio, prompts, generated video, and your feedback notes — in one private web page you open in your browser.

Part of the **[Agentic AI Film Production Studio](https://store.aoiostudios.com/store)** guide. It runs on the same VPS as your AI agent; no extra hosting, no extra cost.

## Features

- **Shot cards** — one card per shot: script, audio files, image/video prompts (editable inline), generated video, and a feedback thread.
- **Video Preview** — a sequence player at the top of each episode page that plays every generated clip end-to-end, with Prev/Play/Next, Loop, and a Follow toggle that scrolls the card row in sync with playback.
- **Two formats per project** — `director` (Script → Audio → Video Prompt → Video) and `standard` (adds Image Prompt + Image rows). Switch by editing the `"format"` field in `data/projects.json`.
- **Two doors, no password to remember on the machine** — a request from the server itself is trusted (no login), and from your own devices it is your **Cloudflare Access** gate that signs you in. The studio's own email + password login remains as the fallback when no gate covers its address (`owner` / `reviewer`, scrypt-hashed, local SQLite).
- **Self-contained** — only needs Python + Flask. No database, no build step.

## License

MIT — free to use, modify, and redistribute. Built for the [Agentic AI Film Production Studio](https://store.aoiostudios.com/store) guide.
