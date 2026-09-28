# Backup & Restore — the weekly mirror into a private repo

*Use when: auditing or repairing the weekly backup, answering "is my work safe", verifying that a
run actually carried the files, or restoring after a loss. The backup is the owner's only off-box
copy of their durable state, so treat "the job ran" and "the data is safe" as two different claims —
and this skill exists to prove the second one.*

> Every path below is inside **`$HERMES_HOME`**, the agent's home folder. Never quote your own
> absolute path to the owner: their app runs in a different container and sees the same folder
> under a different path. Say "my home folder", name the file, and let them look it up.

## What is in the backup — and what is deliberately not

**In** (durable state, mirrored on the weekly run):

| Path (relative to `$HERMES_HOME`) | Why it matters |
|---|---|
| `skills/` | the whole skill library |
| `memories/` | memories + the user profile |
| `config.yaml` | provider/model config — the mirrored copy is secret-scrubbed in place |
| `cron/` | the scheduled jobs themselves |
| `studio/` | the studio's **words**: `projects.json`, scripts, shot plans, prompts, feedback. Generated media is not carried |
| decision record (changelog, handover notes) | without it a restored box cannot tell which standards are current |
| plans (often in a hidden directory, e.g. `.hermes/plans/`) | a plan a future session is meant to execute exists nowhere else |

**Out, by design** (see "Secrets stay out"):

- generated media — images, clips, masters, raw takes: large, regenerable, and the finished copies live elsewhere;
- the **session database** (`state.db`) — hundreds of MB and changing on every call;
- every credential file: `.env`, token/refresh-token stores, password and account stores, a start script holding payment keys;
- `__pycache__`, `.venv`, logs, caches, build output — regenerable, and committed bytecode is noise.

**Rule — decide at creation time, not at audit time.** A new durable artifact you write *outside*
the mirrored set is unprotected from the moment you create it, and nothing fails to tell you. If you
write a plan, a doc or a new directory that matters, add it to the script in the **same pass**, then
run the job and confirm the file is in the commit. A plan that only exists on the box is lost
exactly when it is needed.

**Rule — a backup job that cannot reach the owner is not a backup job.** The run is only as good as
its reporting: the wrapper logs every run to `/config/cron-notify.log` and every non-zero exit to
`/config/hermes-cron.log`, and delivers the output to the owner's chat **only when a chat channel is
connected**. So after you create the job, prove the path with one test message (see `01-agent-onboarding`
§3c) and answer "is it still running?" by reading those two logs — not by assuming.

## Rule 1 — edit only the script the job actually runs

- A relative `script:` name in a cron job resolves under **`$HERMES_HOME/scripts/`**. A same-named
  file in another scripts directory is **never executed**: your edit does nothing, while every run
  still reports success.
- Read the job for its script name and schedule: **`hermes cron list`**.
- After any edit, confirm identity: `md5sum` the file you changed against the path the job resolves
  to, and grep for a line unique to your change.
- To prove which version **RAN**, look for an artifact only one version can produce and check its
  mtime against the run window. Never infer it from "the job is enabled" or from a green completion
  line.

## Rule 2 — a mirror needs a true sync, not an additive copy

`cp -r src/ dst/` merges and never deletes, so a backup built that way only ever grows: files
deleted live linger for weeks, and a restore would resurrect them. Clear the target first, then
copy:

```bash
sync_dir() {  # sync_dir <source-dir> <target-relative-to-the-repo-root>
  local src="$1" dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  find "$dst" -mindepth 1 -maxdepth 1 -not -name '.*' -exec rm -rf {} +
  cp -r "$src"/* "$dst"/ 2>/dev/null
}
```

- Use it for directory mirrors; keep plain `cp` for individual files (config, a single-file app).
- Leaving dot-entries alone keeps large local working directories out of the repo — but **if a
  dot-directory holds content that exists nowhere else, mirror it too**, or the true sync will
  "clean up" the last copy.
- Prune `__pycache__` after copying **and** gitignore it: `git add -A` otherwise commits `.pyc`
  bytecode into the repo.
- **A read-only source tree breaks the clear step on every future run — and it shows up on the
  mirror side.** `cp -r` propagates the source's modes, so the next run's `rm` fails
  (`rm: cannot remove …: Permission denied`), the old copy stays, and the sync quietly stops pruning
  that subtree. Find it with `find <repo>/<mirror> -type d ! -perm -u+w`. **A one-off `chmod u+w` on
  the mirror is not a fix** — the next `cp -r` faithfully restores the source's read-only mode. Fix
  the **source** permissions, or chmod inside `sync_dir` before the `rm`. Either edit changes live
  automation: hand the owner the exact lines rather than slipping them in, and check whether the
  read-only mode is deliberate first.
- **A renamed or moved source silently stops updating its mirror.** `sync_dir` returns 0 when the
  source is missing (`[ -d "$src" ] || return 0`), so the run stays green and the mirror keeps
  whatever it last copied — a **stale backup that reports success**. After any rename, update the
  source path AND the mirror name in the same pass; while something still holds the old path, use an
  explicit fallback instead of a bare path:

```bash
SRC="$HERMES_HOME/<new-name>"
[ -d "$SRC" ] || SRC="$HERMES_HOME/<old-name>"
sync_dir "$SRC" ./<new-name>
```

## Rule 3 — verify the RUN, not the exit line

**A backup script prints "Backup complete" on the strength of its own exit status, which says
nothing about what travelled.** Work down this list after any change to the script, and after any
run you are reporting on:

1. **Read the commit back out of the pushed ref.** Fetch first, then look at the remote branch —
   never a raw-content CDN, which serves cached copies for minutes after a push.
2. **Count the files back out of the pushed ref and compare with the working tree:**

```bash
R="$HERMES_HOME/backup"          # the clone the job pushes from
git -C "$R" fetch origin --quiet
count() { git -C "$R" ls-tree -r origin/main --name-only | grep -c "^$1/"; }
printf 'skills  ref=%s  tree=%s\n' "$(count mirror/skills)" \
  "$(find "$HERMES_HOME/skills" -type f ! -path '*/.git/*' | wc -l)"
```

   (Swap `mirror/skills` for whatever path your script mirrors that tree to — the mapping is the
   mirror of the script, not a guess.) **A count in the ref that is lower than the live tree means
   the run did not carry what you think it did.** Investigate before you call the backup good.
3. **Look for gitlinks — the nested-repo trap, and the reason step 2 is not enough on its own.** A
   directory holding its **own `.git`** makes the outer repo record a **gitlink** instead of its
   files:

```bash
git -C "$R" ls-tree -r origin/main | awk '$1=="160000"{print}'   # gitlinks in the pushed ref
git -C "$R" ls-files -s <mirrored-dir>                            # locally: '160000' for that path
```

   Measured behaviour: a mirrored directory holding **4 files produced 3 entries** in the pushed
   ref, one of them the subdirectory path as `160000 commit` — because that subdirectory was itself a
   git repository. The remote carries **zero** files for that path, and git only says so in a
   warning that scrolls past on stderr: `warning: adding embedded git repository: …` followed by
   `hint: Clones of the outer repository will not contain the contents of the embedded repository`.
   **Fix:** exclude `.git` from what you copy (that directory's history belongs in its own remote),
   so `git add` sees plain files; then re-run and re-count. Expect **`100644` entries** and a count
   that matches the tree.
4. **Confirm the commit is on the REMOTE** (step 1's fetch + `origin/<branch>` is the check) — a
   local commit is not an off-box copy.
5. **Confirm something only the current script version can produce** is present and current, with an
   mtime inside the run window.
6. **Confirm nothing deliberately excluded came back** — grep the ref for the session database and
   the secrets file names. If either is in the ref, stop and treat it as an incident (see Secrets).
7. **Confirm prunes are gone from the working tree yet still retrievable** from history (Rule 5).

## Rule 4 — the schedule comes from the job, never from memory

`hermes cron list` prints the expression AND its next run. Convert with the real clock:
`TZ=<owner-tz> date`. Cron's day-of-week field trips people — **`5` is Friday, not Saturday** — and
"runs tonight" versus "runs in six days" changes the urgency you hand the owner. Correct any doc
that states it wrongly; the next session will trust that line.

## Rule 5 — a true sync never loses history; say so and prove it

Every pruned file is still in the repo's history:

```bash
R="$HERMES_HOME/backup"; P=mirror/skills/example.md
git -C "$R" log --oneline -- "$P"          # the commits that ever touched it
git -C "$R" show HEAD~1:"$P"               # its content in the commit before a deletion
git -C "$R" show --diff-filter=D --name-only --format= HEAD   # what the last run removed
```

`git show <sha>:<path>` legitimately **fails in the commit that deleted the file**
(`fatal: path '…' does not exist in 'HEAD'`) — read the parent commit instead (`HEAD~1`, or the sha
from `log`). When the owner worries that mirroring deletions will destroy old work, answer with
these commands rather than adding a second copy mechanism.

**Syncing an emptied directory.** Because the sync is *true*, whatever the live directory contains
is what the next run pushes — including *nothing*. If a live folder is accidentally emptied or
renamed away, the next run prunes the mirror to match: nothing is lost (the previous state is in the
commit before it) but the copy in the repo is empty now, so the fix is `git show` from that earlier
commit — **not** a fresh backup, which would just push the emptiness again. Two consequences to
state plainly: check the count *before* you call a run good (Rule 3.2), and **never "test" the
backup by emptying a live directory**. If a folder legitimately moves, update the script in the same
pass (Rule 2) so the run carries the move instead of propagating a deletion.

## Rule 6 — secrets stay out, and watch the secrets the backup depends on

Never back up: `.env`, credential/token/refresh-token stores, password or session stores, a start
script holding payment or provider keys, or the session database. Exclude them **by name** and write
the reason inline in the script, so a later session doesn't "fix" the omission and push a live key
into a repo. `config.yaml` is the exception that proves the rule — its mirrored copy is
secret-scrubbed in place, so **check that the scrubbing still happens** before you trust that copy.

- **Keep the push token in the clone's remote URL, not in a file the script copies.** If a token
  ever appears inside a mirrored file, that is a leak: rotate the credential first, then remove the
  path from what the script carries. If it was already pushed, treat the repo's history as
  compromised and re-create the repo — deleting the file is not enough.
- **A private repo is not a secret store.** Private means "not public today"; history keeps every
  version forever, and every future collaborator sees all of it.
- **The reverse hazard.** If a *derived* credential (an HMAC-derived token, a signed URL, anything
  computed from a secret) is computed from a secret that lives in an **excluded** file, then
  restoring from backup silently rotates every user's credential at once. Keep such secrets inside
  the backed-up data directory.
- **The mirror is not a disk image.** It carries files, not the box: a reinstall, a new machine or a
  plan change wipes whatever lived only on disk. Enumerate the on-box-only set — session history,
  account/password stores, provider keys, tunnel credentials, any file mirrored nowhere — and split
  it into **irreplaceable** (chat history, password hashes) and **re-issuable** (provider keys,
  tunnel credentials: re-issued from each dashboard). That split is what the owner decides; the
  answer to "will this break anything?" is never "the backup covers it".

## Rule 7 — an exclusion must not take the only copy (growing directories)

A directory that grows without bound (raw takes, uploads, build output) will eventually dominate the
repo. Exclude it deliberately, never silently:

```bash
sync_dir "$HERMES_HOME/<parent>" ./<parent>   # the mirror still copies it
rm -rf ./<parent>/<growing-dir>               # ...then the exclusion deletes it, so it is RETROACTIVE
```

- Delete **after** the sync rather than teaching `sync_dir` to skip the path: the next run then also
  commits the removal of whatever earlier runs pushed, via `git add -A`. Nothing to clean by hand.
- **Move the keepers first.** Before excluding a directory, copy the small files inside it that exist
  nowhere else (a manifest, a generated/purchased audio file, a contact sheet) into a directory that
  IS mirrored. The silent failure mode is excluding the directory that held the one non-regenerable
  file.
- Write the reason inline — including *"do not re-add this path by 'fixing' the parent sync"* —
  because the next session reads the script, not your notes.
- **Measure before and after**: `du -sh --exclude=.git ./* | sort -hr`, and report the change as a
  share of the total, not the raw size removed. The assumed offender is often the smaller half.
- **Pruning the working tree never shrinks `.git`.** Deletions live in history forever, so the repo
  total barely moves; only a deliberate history rewrite changes that, and that is the owner's
  decision — never a cleanup you run.

## The closing audit after a long working session

List every file you changed in the window, then check each one against what the script carries:

```bash
cd "$HERMES_HOME"
find . -maxdepth 3 -newermt "12 hours ago" -type f ! -path '*/__pycache__/*' ! -path '*/.venv/*' \
  ! -path './cache/*' ! -path '*/state.db*' ! -name '*.log' | sort
# for each path above: is it inside a sync_dir/cp line of the backup script?
```

Cross-check that list against your own changelog: a file you changed but never mentioned is either
an unlogged change or a change not worth keeping — both worth knowing before you say "everything is
logged".

## Restore

Rehearse this when nothing is broken, so the version you run under pressure is not the first one.

1. **Clone the private repo to the backup path** — a clone is not a restore; confirm nothing yet:
   ```bash
   git clone <your-private-repo-url> "$HERMES_HOME/backup"
   ```
2. **Read the decision record first** — the changelog and handover notes state which standards are
   current, so you don't re-apply a superseded one.
3. **Copy each mirrored tree back to its live path.** The mapping is the mirror of the script — read
   the script, don't guess it.
4. **Re-enter what is excluded by design**: provider keys in `.env`, account/password stores, tunnel
   credentials, payment keys in a start script. Re-issue keys from each provider's own dashboard
   rather than from a stale note.
5. **Restart the services** and verify each with its **own** self-test, not a page load.
6. **Prove the restore**: `diff -rq <repo>/mirror/skills "$HERMES_HOME/skills"` (no output = identical),
   then run one real task end to end.
7. **Recover a single file, or a whole emptied folder**, from history with Rule 5's commands:
   `git log -- <path>` → `git show <parent-sha>:<path>` → `git ls-tree -r <sha> --name-only`.

**After any restore, re-verify the JOB, not just the data.** A restore can put every file back and
still leave the backup dead, because the job needs its **destination**, not the data. Prove it by
test, never by inference: the clone exists (`test -d "<BACKUP_DIR>/.git"`), the remote host (mask the
token: `git remote get-url origin | sed -E 's#//[^@]*@#//***@#'`), the branch that gets pushed, and
the script path the job resolves to (Rule 1). Then run the job once and re-count (Rule 3).

## Reporting back to the owner

- **After every verification run, in three lines**: what is safely off the box, what is **not** (the
  excluded set, in plain words), and the next scheduled run (read from the job — Rule 4).
- **Immediately and unprompted** if: the count in the pushed ref is lower than the live tree; a
  gitlink shows up; a credential file is inside the ref; the job is missing, paused or failed; or the
  destination clone is gone.
- Never say "the backup ran" as though it meant "your work is safe". Say which of those two you
  actually proved.

## Failure → action

| Symptom | Action |
|---|---|
| The job reports success but the repo has no new commit | Check the job's `script:` resolves to the file you edited (Rule 1), then the destination clone, remote and branch (Restore, last paragraph). |
| The count in the pushed ref is lower than the tree | Gitlinks first (Rule 3.3), then a renamed/moved source (Rule 2), then an errored `cp`. |
| `rm: cannot remove …: Permission denied` during the clear step | A read-only source tree — fix the source's modes, or make `sync_dir` self-healing; a `chmod` on the mirror alone is not a fix (Rule 2). |
| A whole directory vanished from the repo | The true sync propagated an emptied or renamed live folder — recover from the commit before that run, then fix the source path (Rule 5). |
| A secret is inside the repo | Rotate the credential first, then remove the path from the script; if it was pushed, re-create the repo (Rule 6). |
| The repo is enormous | Measure with `du -sh --exclude=.git ./* \| sort -hr`, exclude the growing directory retroactively, and tell the owner that `.git` will not shrink (Rule 7). |
| A restore worked but the job is dead | Re-verify the destination and the script path by test, then run the job once and re-count (Restore). |
