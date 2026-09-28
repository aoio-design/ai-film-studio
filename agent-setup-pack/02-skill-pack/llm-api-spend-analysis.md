# LLM API Spend Analysis — reading the bill and finding what inflated it

*Use when: the owner says "the bill jumped", "this month cost more than last", "why did that cost
so much", or the tokens you can see in a session don't add up to the provider's invoice. The job is
to answer with the provider's own numbers, name the ONE session behind the change, and say what to
do differently — never to hand back totals and let them guess.*

> **Read-only, start to finish.** Nothing on this page edits config, switches a model, changes a
> provider lane or spends money. In particular: **do not change the lane while you investigate a
> bill** — the switch is usually the thing you are trying to explain, and a change mid-window makes
> every comparison worthless afterwards.

## The order of work

Do these in order. The database is step 2, not step 1 — your own numbers are not the bill.

1. **The provider's own account numbers** — that IS the bill, and per-day spend comes from here.
2. **Local session data** (`$HERMES_HOME/state.db`) — what you are being billed *for*, per session,
   model and task.
3. **Recompute** with the provider's live rates, two ways, and compare against the provider's bucket.
4. **Report one culprit session and one cause**, then the change that stops it recurring.

## 1. The provider's own numbers

Load the key out of the agent's own env file and never print, echo or paste a key:

```bash
set -a; . "$HERMES_HOME/.env"; set +a        # loads the key into this shell; prints nothing
curl -s -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  https://openrouter.ai/api/v1/auth/key | python3 -m json.tool
```

> The worked example is OpenRouter's — a router many Hermes setups bill through. Every other
> provider has an equivalent read-only **credits/usage** endpoint plus a **models** endpoint that
> carries rates. Find them in that provider's own docs (`<docs-host>/llms.txt` usually indexes
> everything), read them live, and **say which URL you read** — never invent an endpoint or trust a
> remembered figure.

What the buckets mean — key-scoped, and **not trailing windows**:

| Field | What it covers |
|---|---|
| `usage` | all-time |
| `usage_daily` | the current **UTC** day |
| `usage_weekly` | the current **UTC week, Monday start** |
| `usage_monthly` | the current **UTC calendar month** |

Cross-checks that turn four numbers into a per-day picture:

- `weekly − monthly` ≈ spend in the part of this week that fell before the month started.
- `lifetime ≈ weekly +` everything before this week.
- `usage_daily ≈ 0` while local tokens moved ⇒ today's traffic ran on a different lane or provider.
- **`weekly > monthly` near a month start is normal, not an error.** Say so if the owner asks.

**Per-request proof.** `GET /api/v1/generation?id=<gen_id>` returns exactly ONE generation (404 for
an unknown id). There is **no list endpoint** (`/api/v1/generations` 404s), and an account-wide
activity view needs an **account-level key** — a normal inference key cannot enumerate requests
(it returns `403` there). So when the owner wants line-item proof, say which of the two you can
actually produce: create/use an account-level key, or read the dashboard's activity page. Never
promise per-request line items from an inference key.

**Rates.** `GET https://openrouter.ai/api/v1/models` → `pricing.prompt`, `pricing.completion`,
`pricing.input_cache_read`, in USD **per token**. Read them at the moment you report; a remembered
price is a wrong price.

## 2. Local ground truth — `$HERMES_HOME/state.db`

Fast first look: **`hermes insights --days 7`** — per-day tokens, an *Estimated* cost, models,
platforms. It reads this same database and prints this same estimate, so it is a **floor, not the
bill** (section 4.3).

Two tables matter:

- **`sessions`** — one row per session: `id`, `source` (`webui|desktop|cron|telegram|…`), `title`,
  `started_at`/`ended_at`, token counters, `estimated_cost_usd`, `api_call_count`. Join it, so your
  report names sessions the owner recognises instead of raw ids.
- **`session_model_usage`** — the workhorse: **one row per (session, model, billing_provider,
  task)** with `api_call_count`, `input_tokens` (**cache-MISS prompt tokens**), `cache_read_tokens`,
  `cache_write_tokens` (often 0), `output_tokens`, `reasoning_tokens`, `estimated_cost_usd`,
  `cost_status` (`estimated|unknown`), `cost_source`, `first_seen`/`last_seen`. `task` is `''` for
  the main lane, or `approval`, `title_generation`, `background`.

Read it read-only and aggregate per day × provider × model:

```bash
python3 - <<'PY'
import os, sqlite3
from collections import defaultdict
from datetime import datetime, timedelta, timezone

# the owner's clock, as a UTC offset in hours — say which one you used when you report
TZ = timezone(timedelta(hours=float(os.environ.get("OWNER_UTC_OFFSET", "0"))))
db = os.path.join(os.environ["HERMES_HOME"], "state.db")
lo = (datetime.now(timezone.utc) - timedelta(days=7)).timestamp()

c = sqlite3.connect(f"file:{db}?mode=ro", uri=True)          # read-only, always
agg = defaultdict(lambda: [0, 0, 0, 0, 0.0])
for last, prov, model, api, miss, cr, out, est in c.execute("""
        select last_seen, billing_provider, model, api_call_count,
               input_tokens, cache_read_tokens, output_tokens, estimated_cost_usd
        from session_model_usage where last_seen >= ?""", (lo,)):
    ts = float(last)
    ts = ts / 1000 if ts > 1e12 else ts                      # epoch SECONDS (guard for ms)
    a = agg[(datetime.fromtimestamp(ts, TZ).date().isoformat(),
             prov or "(blank)", (model or "?").split("/")[-1])]
    a[0] += api or 0; a[1] += miss or 0; a[2] += cr or 0; a[3] += out or 0; a[4] += est or 0

for k in sorted(agg):
    a = agg[k]
    print(f"{k[0]}  {k[1]:12s} {k[2]:22s} api={a[0]:5d} miss={a[1]:>12,d} "
          f"cR={a[2]:>12,d} out={a[3]:>10,d} est=${a[4]:8.4f}")
PY
```

For "which session did this", group the same rows by `session_id`, join `sessions` for
`title`/`source`, and sort by `estimated_cost_usd` descending.

**Two pitfalls that give you a silent, confident, wrong answer:**

- **Epoch floats.** `started_at`/`last_seen` are REAL epoch *seconds*. SQLite's `datetime(<numeric>)`
  treats a bare number as **Julian days**, so a `BETWEEN` or `datetime()` filter quietly returns
  nothing — and "nothing" reads as "no spend". Convert in Python (`datetime.fromtimestamp(ts, UTC)`,
  ÷1000 if the value is > 1e12) and state the timezone you presented everything in: the provider
  buckets are UTC, the owner thinks in their own clock.
- **`LIKE` wildcards.** `_` matches any single character, so `LIKE '%gen_%'` also matches
  "generation". A literal underscore needs `LIKE '%gen\_%' ESCAPE '\'`.

One more signal: **the mtime of `config.yaml` is when the model/provider lane changed.** That
timestamp splits the comparison window — spending before it ran on the old lane, after it on the
new one, and the two are not comparable without saying so.

## 3. Recompute, and compare against the provider's real bucket

For each day × provider × model, with that day's live rates (`p_prompt`, `p_cache_read`,
`p_completion`):

```
cost_discounted = miss × p_prompt + cR × p_cache_read + out × p_completion
cost_full       = (miss + cR) × p_prompt + out × p_completion
```

- real ≈ **discounted** ⇒ the provider applied the cache discount.
- real ≈ **full** ⇒ the cache discount was **NOT honoured** for that traffic.
- real between the two ⇒ blended per request (normal on mixed traffic).

Worked shape, to show the method (illustrative rates of $0.10 / $0.02 / $0.30 per 1M tokens):

```
40M cache-miss input, 60M cache-read, 0.5M output
discounted = 40×0.10 + 60×0.02 + 0.5×0.30 = $5.35
full       = 100×0.10 + 0.5×0.30          = $10.15
```

If the provider's bucket for that day reads ≈ $10, the cached history was billed at near-full
prompt price. That is the most common surprise in a "why is this so expensive" audit.

## 4. Why the session numbers never equal the dollars — check all four

1. **Provider mix.** Local token stats count **every** lane: main + auxiliary + fallback, across
   every provider. Traffic that went to a second provider is invisible on the invoice you are
   reading, so a token-heavy day can look cheap on the bill. Compare `billing_provider` across days,
   not totals.
2. **The cache-read volume illusion.** Cache-read tokens usually dominate the raw counts but cost
   roughly 10–25% of the prompt rate — *if* the discount is applied. The real driver is **cache-miss
   input tokens**, billed at full prompt price. Compare miss volumes across days, not totals.
3. **The cache discount not being honoured (the big one).** `estimated_cost_usd` prices
   `cache_read_tokens` at the advertised discount. On long sessions — hours of wall clock, minutes
   between calls because of tool work and background tasks — a route can re-serve history at
   near-full prompt price while still accounting it as cached. Real bills have come in at **about 2×
   the local estimate, with one long session explaining the whole gap**. So: **treat every session
   cost estimate — the DB column and `hermes insights` — as a floor, not a ceiling, and never
   promise the owner a cap from it.**
4. **Pricing-snapshot drift.** Local estimates come from `cost_source` snapshots
   (`provider_models_api` / `official_docs_snapshot`) that can lag the day's price list, so expect a
   small residual even above the full-price math. Call it drift rather than inventing a cause.

## 5. Report back to the owner (plain English, answer first)

Give them, in this order:

1. **Real provider spend per day** in the window, on their clock, and where you read it.
2. **The ONE session that dominated** — title, source, its window, its API-call count. One session
   usually explains the whole delta; if it doesn't, name the two or three that do.
3. **The token split** — cache-miss vs cache-read vs output — and the discounted-vs-full range.
4. **Which lane billed where** — which traffic landed on this provider's invoice and which didn't.
5. **The cause in one line**, then the change that stops it recurring, e.g. *"that 6-hour session
   re-sent its whole history as cache-miss; long jobs want a fresh session per task, or a scheduled
   job."*

Leave them with the cost shape: **long mega-sessions are the expensive shape; fresh sessions per
task are the cheap one — and everything the database shows you is an estimate of a floor.**

**When to report back:** whenever they ask, and unprompted when you notice the spend running above
what the local estimate predicted — that is a finding they need *before* the next batch, not after.

## Failure → action

| Symptom | Action |
|---|---|
| Usage endpoint returns `403` | The key you used cannot read account activity — that view needs an account-level key, or the dashboard. Say which, and don't retry in a loop. |
| `/…/generations` returns `404` | There is no list endpoint. Ask for one id, or use the dashboard's activity page. |
| A date filter returns no rows | The Julian-day trap — convert epoch seconds in Python instead of using `datetime()` in SQL. |
| `cost_status` is `unknown` | No price snapshot for that model — recompute from the provider's live rates and say the estimate is incomplete. |
| Local total is far below the invoice | Work section 4 in order: provider mix first, unhonoured cache discount second. |
| The numbers moved after a model switch | The `config.yaml` mtime splits the window — compare like with like, and don't change lanes mid-investigation. |
| The owner wants line-item proof | Only an account-level key or the dashboard can produce it (Step 1). Offer the one that exists instead of promising either. |
