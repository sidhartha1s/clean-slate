---
name: clean-slate
description: >-
  Use at session wind-down to turn "looks done" into "is actually done" before you walk away.
  Trigger proactively — named or not — on "let's close this", "we're done", "wrap up", "before I go",
  "is this all merged?", "did the notes get saved?", "are we good to close?", or any signal a coding
  session is ending while work is in flight. It walks the session's transcript for every claim of
  done/committed/merged/tested/fixed/shipped, VERIFIES each by running the check itself against the real
  artifact (git, the PR, the file, the test/CI output) rather than trusting a chat summary or a context
  compaction summary, reconciles unmerged work, lands learnings where they belong, sweeps stale docs, and
  emits a report flagging anything that LOOKS done but ISN'T. Under-triggering defeats the purpose. Do NOT
  fire on a mid-task "are we good?" check-in with no close signal and no work in flight — that is not
  session end.
---

# Clean Slate

The failure this prevents: you read a summary, believe everything shipped, close the laptop — and hours
later (or in a new session) find nothing was merged to main, the "fix" was hardcoded/session-local, the
learnings never left the conversation, and the docs went stale.

The core stance: **a claim is not a fact.** "The assistant said it's merged" and a context-compaction
summary are both *claims*. Verify by looking at the artifact you would look at — git, the PR, the file, the
test output — not the green check or the prose. If you didn't run it this session, it didn't pass this
session.

## Step 1 — Enumerate the claims

**Walk this session's transcript top to bottom and list every claim of *done / committed / merged / pushed
/ tested / fixed / shipped / created / saved*.** The live conversation is the primary source — most claims
live there, not in any summary.

If this is a fresh/resumed session and the prior transcript is NOT in context, reconstruct the list from:
the compaction summary + any session breadcrumb/checkpoint + `git log` since the last known-good SHA + open
PRs. Treat all of it — transcript included — as *claims*, not facts.

This list is your checklist; each item gets a verdict in the report.

## Step 2 — Verify each claim against the artifact

**Run the checks yourself, now, in this session.** Do not lift a "merged" line from earlier in the
transcript — it may predate a later edit, the exact staleness trap. Write each verdict in the same turn as
the command that produced it, right under that command's output. A batch of verdicts authored after the
commands scrolled away is how fabrication creeps in — a fabricated `gh pr view` line is as easy to type as a
fabricated "merged." Tie each verdict to output you just produced.

A session can touch several contexts — a project repo, a dotfiles/config dir, a notes folder. **Some of
these are not git repos.** Enumerate each working dir touched (`pwd` / `git rev-parse --git-dir` per
context). For a git repo, run the block below. For a **non-repo** context (e.g. a notes dir), skip git
entirely — there the durability check is "did the file land on disk," not a fetch.

```bash
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a repo — skip git block"; }
git fetch origin --prune          # without it every origin/* check is stale; harmless if no origin
git status --porcelain            # uncommitted / untracked
git branch -vv                    # which branch; gone-but-not-deleted tracking branches
git log --oneline @{u}..          # ahead of upstream (unpushed)
git stash list                    # stashed work dies silently on close
git worktree list                 # worktrees holding work
gh pr list --state open --json number,title,headRefName
gh pr view <n> --json state,mergedAt   # the only proof a PR landed
```

Then judge, per claim:
- **Merged:** an *open* PR is not a merged PR. Proof is `"state":"MERGED"` with a non-null `"mergedAt"`. A
  branch that "should be merged" usually isn't.
- **Tested / green:** were the tests actually run *this session*, and did they pass? A remembered green run
  from before a later edit is stale — re-run. CI on main: `gh run list --branch main --limit 1 --json conclusion`.
- **Fixed:** read the diff. Durable root-cause fix, or a one-run workaround / hardcoded value? A workaround
  that leaves the bug live is not a fix — say so. Don't diff against `HEAD` to prove a logical change (HEAD
  is already the edited version); capture the explicit pre-work SHA and diff that range.

**If your agent harness auto-commits edits, the obvious detectors lie.** Some setups run a hook that commits
(and sometimes pushes) every file edit on a feature branch. When that's on, `git status` is clean and
`@{u}..` is empty even when nothing durable happened — **"clean tree" and "nothing unpushed" are NOT
evidence the work is safe.** The real durability check becomes: **does a PR exist for the branch's
commits?** Compare each non-main branch carrying auto-generated commits against `gh pr list` heads — a
branch with commits but no PR is stranded work, already pushed and invisible. Such hooks typically skip
protected branches (so commits made directly on `main` still show in `@{u}..` — catch those) and skip paths
outside the repo or gitignored (so those edits show as dirty — commit them).

## Step 3 — Find session-local / hardcoded work

The pain this catches: a change that lives only in this session's context or as a hardcoded constant, never
made durable. Look for edited-but-uncommitted files, values that should be config, and "works right now"
state that won't survive a restart. Anything that would vanish on close is a GAP.

## Step 4 — Reconcile unmerged work

Precondition for any commit/PR: confirm you're committing as the **intended author**, not a stray default
identity (`git config user.email`, `gh auth status`). Then reconcile via your project's protocol — prefer
PR over direct-to-main:

> branch → commit (WHY in the message, one logical change each) → PR → code review → fix blocking findings
> → run the test/E2E suite → merge (rebase or your repo's convention) → verify main green → delete the
> local branch.

**Merge decision — be a thought-partner, not a silent default.** The whole pain is work left UNMERGED, so a
HOLD-everything default just recreates the state you fear. Default to **merging the low-risk, fully-verified,
green-CI, clean-review items**; **HOLD only the genuinely risky/ambiguous ones** (migrations, broad blast
radius, failing or absent CI, unresolved review findings, anything you can't fully verify) as
BLOCKED-ON-OWNER. State the tradeoff in the report — what you merged and why, what you held and why — so the
human can override.

Notes:
- **No test/E2E suite?** Don't scaffold one at wind-down — that's a multi-file creative task to do with a
  clear head, not autonomously while someone is leaving. Flag it as BLOCKED-ON-OWNER and HOLD that merge.
- If `git pull --ff-only` fails (local main diverged), stop and reconcile rather than leaving the branch
  undeleted — otherwise you create the stale-branch mess this skill exists to prevent.

## Step 5 — Reconcile learnings

Two kinds, both caught here:
- **Mistakes this session** — what went wrong, the RCA, the fix, how to prevent recurrence.
- **Genuinely new things learned** — facts, gotchas, verified-vs-stale corrections.

**Before writing anything, grep your existing notes/instructions for the rule.** If it already exists, the
failure was non-adherence, not a missing rule; do NOT append a duplicate — note the existing rule instead.

Route each genuinely-new learning, and confirm it *reached* there (a learning sitting only in the
conversation, or in a notes file but never indexed, is the exact gap to catch):
- repo `LEARNINGS.md` (or equivalent) → repo-specific lessons.
- your persistent memory/notes location → cross-session / behavioral lessons. If that store has an index,
  confirm BOTH the new note AND its index entry landed; an unindexed note is half-saved.
- your agent-instructions file (e.g. `CLAUDE.md`, `AGENTS.md`) → durable behavioral rules.

If a quality bar needs enforcing, a **machine gate** beats a prose note (notes get skipped). But a gate is
code — it goes through Step 4/6 (PR → review → merge) and you must confirm it actually fires. If you can't
land and verify the gate this session, don't fake it with a note: flag "gate needed: <what>" as
BLOCKED-ON-OWNER.

## Step 6 — Fix code if needed

If verification surfaced a real defect or a workaround-not-fix, correct the root cause through the Step 4
protocol — not an uncommitted local patch. Surgical: change only what the fix requires.

## Step 7 — Docs sweep

Merging code does not make docs current. **Per context touched** (Step 2 enumerated them), for every doc the
session's changes affected, **read it before editing** and update only what's now wrong or missing:
`README.md`, agent-instructions files, `LEARNINGS.md`, `docs/`, and any project-tracking doc the repo
actually uses (`ROADMAP.md` / `CHANGELOG.md` *if present*). If a module/flag/feature was deleted, `grep -r`
its name across the whole repo (docs + deps in `pyproject.toml`/`package.json`/`requirements.txt`), not just
code.

**Do not invent facts to fill a doc.** If you don't know, leave it and flag it — a confident wrong line is
worse than an honest gap.

## Checks worth adding (don't stop at the obvious)

- Untracked files of durable value (scratch artifacts worth saving to the right repo before cleanup).
- Stale local branches / worktrees from merged PRs that should be pruned.
- Secrets accidentally committed — scan the session's commit range, not just the working tree:
  `git log -p <pre-work-SHA>..HEAD | grep -nE '(api[_-]?key|secret|password|token|BEGIN.*PRIVATE KEY)'`.
- A "fix" that is actually a workaround — re-classify it honestly.

## Discipline

- Verify against the **artifact**, never a summary, metric, or green check. Every VERIFIED line must cite a
  line of output you produced this turn. Couldn't run it → GAP/UNKNOWN.
- **Read a file before you touch it** — a top recurring tool error.
- **Surgical and minimal.** One word plus an example often beats fifteen lines. Match the existing style.
- **Fail loud.** "Done" is wrong if anything was skipped. If a true root-cause fix isn't possible yet, say so.

## The Clean-Slate Report

**If Step 2 found nothing unmerged, unverified, or stranded — everything genuinely landed — skip the
template and emit the one-line YES verdict. Do not manufacture GAPs to fill sections.**

Otherwise end with this, and surface the ⚠️ and BLOCKED-ON-OWNER sections loudly at the TOP of your message
(people skim and routinely miss trailing notes):

```
# Clean-Slate Report — <session / date>

## ⚠️ Looks done but ISN'T
- <the thing a tired operator would have closed on, stated bluntly>

## Blocked on owner
- <merge/scope/risk call held — staged + reviewed, NOT merged, and why it was held>

## Claims verified
- <claim> — VERIFIED (evidence: "state":"MERGED","mergedAt":"...")
- <claim> — GAP (said merged; `gh pr view 12` → "state":"OPEN") → merged in PR #N / held, see above
- <claim> — GAP (fix was a hardcoded workaround) → root-cause patch in PR #M

## Reconciled this session
- Merged: <PRs landed on main, with why-safe>   Held: <PRs awaiting owner, with why-risky>
- Learnings: <what + WHERE — LEARNINGS.md / memory note + index / instructions file / gate>, or "already covered by <existing rule>"
- Code: <root-cause fixes>
- Docs: <files updated, per repo, and what changed>

## Clean to close?  YES / NO / BLOCKED-ON-OWNER — <one-line reason>
```

Answer **YES** only when every claim is VERIFIED with real evidence and nothing is stranded. If anything is
unverified or stranded, the honest answer is **NO**. If everything verified is reconciled but a merge/scope
call is held, it's **BLOCKED-ON-OWNER** — not YES; no one should walk away believing it's clean when a
decision is still pending.
