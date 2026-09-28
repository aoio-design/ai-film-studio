# Onboarding a New AI Media Provider — keys, connectors and the three doors

*Use when: the owner says "add <vendor> api key", "connect <vendor>", "can you use <vendor> from
here", or names any new image / video / audio / TTS / tool vendor they want in the studio.*

Scope: **adding an outside vendor** to the stack. Not for choosing among providers that are already
wired (that is the model registry and `ai-film-pipeline`) and not for running the generation stages
themselves (that is `fal-ai-ops`).

> **The job is not "paste a key into `.env`."** It is: work out which of the vendor's products the
> owner actually means, prove the credential works **for free**, store it so the vendor's own SDK can
> read it, and tell them what would make it usable. Research first, then ask — never write on an
> assumption, and never spend money to find out whether a key works.

## Step 0 — the three doors (ask which one, before any write)

Every modern AI media vendor ships two or three **different products that do not share
credentials**. Work out which exist, then ask which one the owner wants:

1. **MCP connector** — agent-native, OAuth sign-in, billed through the account they already have with
   the vendor, no key to manage. Often the right answer for this stack.
2. **Developer API** — a **separate** paid product with its own console and metering. Nothing in the
   agent consumes it until a script or skill exists.
3. **Official CLI** — a global npm/pip install plus a browser login; usually keyless too.

Offer 2–3 options with the trade-off, put the recommended one first, and **WAIT**. "Add the API key"
means the developer product at one vendor and there may be no key at all at another. Adding an MCP
server, installing an SDK/CLI and writing a new skill are all changes to the production stack, so the
pack's change-control gate applies (`01-agent-onboarding.md` → "Changing my studio"): what changes,
which files, what could break, how to undo it, what it costs — then ask. Nothing is written before
the owner picks a door.

Quick triage that saves a round trip: `hermes mcp catalog` may not list the vendor — but
`hermes mcp add <name> --url <url> --auth oauth` works for **any** custom remote server, catalog or
not. A vendor's own site claiming it "supports agents" is not proof; the endpoint's own metadata is
(Step 2).

## Step 1 — read the vendor's auth contract before believing the word "key"

Shapes that exist in the wild, all of them called "the API key" by the owner:

- a single bearer token;
- **a two-part pair joined in the header at request time** — e.g. an `…_API_KEY_ID` plus an
  `…_API_KEY_SECRET`, sent as `Authorization: Key <id>:<secret>`. The owner will paste **one** value;
  there are two. Ask for both explicitly, and say why.
- OAuth only — no key exists at all.

Use the vendor's **own documented environment-variable names, verbatim**. Inventing your own
`VENDOR_*` prefix silently breaks the vendor's official SDK later, with no error until someone tries
to use it.

Docs map: `<docs-host>/llms.txt` lists every page — fetch that first instead of guessing URLs.
Model/endpoint catalogs often live in the vendor's **console**, not the docs, and a published
OpenAPI file may be explicitly non-authoritative (a model missing from it is not proof it is
unavailable).

## Step 2 — probe a remote MCP endpoint before running `hermes mcp add`

Read-only, free, and it tells you which OAuth flow you will get — worth doing before dragging the
owner into a browser flow:

```
curl -s -i -X POST <mcp-url> -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}'
```

`401` plus a `www-authenticate: Bearer resource_metadata="<url>"` header means the server is live and
OAuth-gated. Read what it points at:

```
curl -s <registry>/.well-known/oauth-protected-resource
curl -s <registry>/.well-known/oauth-authorization-server
```

Look for a `device_code` flow naming the agent — that is the flow a headless agent can actually
complete (the owner opens a URL and types a code out of band). `authorization_code_pkce` needs a
redirect receiver and is the harder path. **Capture the flow before the add**, so you can tell the
owner exactly what to expect.

Two failure modes to plan for, both benign: the desktop consent card returning "unanswered", and
`hermes mcp login` self-terminating on a ~90s timeout. Vendor auth codes commonly expire in about a
minute — have the owner signed in and ready before you start. The hand-driven DCR+PKCE recipe lives
in the bundled `hermes-agent` skill.

## Step 3 — find a FREE verification call before spending anything

**Never verify a generation credential by generating.**

```
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Key ***" <status-url-with-a-bogus-id>
```

A bad key returns `401`; a good key returns `404` for the unknown object. That separates "wrong
credential" from "no such object" at zero cost. Derive the equivalent per vendor — a status lookup,
a model list, an account/credits read — and **say which probe you used**, so the next session can
repeat it.

## Step 4 — write the credential

- Secrets go in the agent's env file — `hermes config env-path` prints it (normally
  `$HERMES_HOME/.env`). Never in `config.yaml`, never in the studio repo, never in chat.
- Append with a shell append or a targeted `patch`. **NEVER `read_file` → `write_file` on a secrets
  file**: secret redaction rewrites what the read returns, so a round-trip replaces the real value
  with a `«redacted:…»` placeholder and the file still parses cleanly. The failure only surfaces much
  later, as an auth error.
- `chmod 600`. Never echo the value back into chat or a log — report the **verification result**
  instead.
- **Media vendors are not chat providers.** A key for an image/video/audio vendor will **not** appear
  on the app's Providers page — that page is for chat models only. If the owner says it isn't there,
  that is correct, not a bug: point them at the env file instead of hunting for it. Never ask them to
  paste a key into chat.
- Toolset/config changes apply on the **next** session, not mid-conversation (deliberate — prompt
  caching). Say so when you tell them it is ready.

## Step 5 — a stored key is not a capability

`.env` alone changes nothing: no provider, toolset or CLI reads it. Say this in the **same reply** as
the write, and name what would make it usable:

- the vendor's official SDK (pip/npm) wrapped in a small script, or
- a `<vendor>-ops` skill holding the submit → poll → download loop (the `fal-ai-ops` shape), or
- an MCP connector instead of the key.

All three are stack writes → ask first. Two facts to carry into that conversation:

- **Generation vendors are async and poll-based**: submit → `request_id` → poll a status URL →
  download the output URLs. Output URLs are retained for a limited period (commonly about 7 days) —
  copy finished media into the studio's own storage immediately, and never treat a vendor URL as the
  archive. Terminal states usually include `failed`, `nsfw` and `canceled`, not just
  success/failure.
- **The consumer site and the developer API are different products with different credit pools.**
  Confirm which one the owner is actually paying for before you quote any cost, and quote **live**
  rates only — never a promotional or discounted figure.

## Pitfalls

- **Don't hand the owner a shell command you could have run yourself.** Run every probe and curl
  yourself; hand over only what genuinely needs their browser or their consent.
- **Interactive TTY wizards cannot be driven from a chat session.** `hermes setup <section>` and bare
  `hermes tools` need a real terminal — never try to drive them; give the explicit command instead.
  From inside the session use the non-interactive forms: `hermes tools list`,
  `hermes tools enable|disable <name>`, `hermes mcp list`, `hermes mcp catalog`.
- **Check the vendor's own docs for gating.** A capability can exist and still be unavailable for
  that account — verify before recommending it, and never dictate dashboard menu paths or setting
  locations from memory.
- **Never name a vendor integration as "the" answer without checking the vendor supports the agent.**
  Read the endpoint metadata, not the marketing page.
- **Don't store a credential whose consumer doesn't exist yet without flagging it.** A dead key in
  `.env` looks like completed work; it is only step one.
- **One vendor at a time.** Two integrations in one pass, and neither of you will know which one
  broke the batch.

## What to report back to the owner

One message, in this order: which door you are proposing and what it costs (say "nothing" when it
is free), what you verified for free, what is now stored and where it may be used from, and what is
still missing before it can actually produce anything. If nothing is usable yet, say that plainly —
a stored key that nothing consumes is step one, not finished work. Then go back to the price gate:
nothing is generated until the owner has approved a live quote.

## Failure → action

| Symptom | Action |
|---|---|
| `401` on the free probe | Key wrong, truncated, or from the wrong product. Re-read the auth contract (Step 1); ask for the missing half if it is a pair. |
| `403` on the free probe | Credential is valid but not scoped for that endpoint — check the account's permissions, not the key's spelling. |
| `hermes mcp login` times out at ~90s | Known path — capture the flow first (Step 2) and have the owner ready; the hand-driven recipe is in the bundled `hermes-agent` skill. |
| The vendor is not in `hermes mcp catalog` | Expected for most vendors; `hermes mcp add` takes any URL (Step 0). |
| The owner says the key "isn't on the Providers page" | Correct — that page is for chat models only. Send them to the env file (Step 4). |
| The key is stored but nothing happens | Step 5: a stored key is not a capability. Name what is still missing, and ask before building it. |
| A probe returns HTML instead of JSON | You hit a docs/marketing page, not the API — re-read the endpoint metadata. |
| The vendor's own SDK rejects the key later | An invented env-var name — use the vendor's documented names verbatim (Step 1). |
