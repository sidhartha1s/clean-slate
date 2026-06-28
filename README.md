# clean-slate

A coding-agent skill that turns **"looks done"** into **"is actually done"** before you close a
session. Works with **Claude Code**, **Codex**, **OpenClaw**, and **Hermes** — the skill is one
harness-agnostic `SKILL.md`.

## The problem it solves

You read the assistant's end-of-session summary, believe everything shipped, and close the laptop. Hours
later you discover: nothing was merged to `main`, the "fix" was a hardcoded session-local hack, the learnings
never left the chat, and the docs went stale. The summary was a **claim**, not a **fact** — and nobody
checked the difference.

`clean-slate` is the check. When a session is wrapping up, it:

1. **Enumerates every claim** of done/committed/merged/tested/fixed/shipped from the session.
2. **Verifies each against the real artifact** — `git`, the PR, the file, the test/CI output — not the chat
   prose or a context-compaction summary. *If it wasn't run this session, it didn't pass this session.*
3. **Reconciles unmerged work** via PR (merging the safe, verified items; holding the risky ones for you).
4. **Lands learnings** where they belong (LEARNINGS.md / memory / instructions file / a machine gate).
5. **Sweeps stale docs** — read-before-edit, surgical, no invented facts.
6. **Emits a report** that loudly flags anything that *looks* done but **isn't**, ending in a
   `YES / NO / BLOCKED-ON-OWNER` verdict.

It also catches the subtle traps: an **auto-commit hook** that makes a dirty tree look clean, branches
pushed-but-never-PR'd, non-git contexts (notes/config dirs), secrets in the commit range, and a "fix" that's
really a workaround.

## Compatibility

The skill is a single `SKILL.md`. Drop it in your harness's skills directory:

| Harness | Global skills dir | Project (repo-local) skills dir |
|---|---|---|
| **Claude Code** | `~/.claude/skills/clean-slate/` | `.claude/skills/clean-slate/` |
| **Codex** (OpenAI) | `~/.codex/skills/clean-slate/` | `.agents/skills/clean-slate/` |
| **OpenClaw** | `~/.openclaw/skills/clean-slate/` | `.openclaw/skills/clean-slate/` |
| **Hermes** (Nous Research) | `~/.hermes/skills/clean-slate/` | `skills/clean-slate/` |

Each harness auto-discovers a skill from its `SKILL.md` and activates it on the `description` frontmatter.
(Codex and Hermes also read `~/.agents/skills/` — a shared cross-agent location, if you prefer one dir for
every tool.)

## Install

Replace `claude-code` with `codex`, `openclaw`, or `hermes` as needed. Add `--project` (or `-Project` on
Windows) to install into the current repo instead of your home directory.

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/install.sh | sh -s -- claude-code
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/install.ps1 -OutFile install.ps1; ./install.ps1 claude-code
```

**From a clone** (inspect first, then install — same script):

```bash
git clone https://github.com/sidhartha1s/clean-slate.git && cd clean-slate
./install.sh codex            # Linux / macOS
./install.ps1 codex           # Windows (or any box with PowerShell Core)
```

**Manual** (no script): copy `SKILL.md` into the matching directory from the table above, e.g.

```bash
mkdir -p ~/.codex/skills/clean-slate
curl -fsSL https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/SKILL.md \
  -o ~/.codex/skills/clean-slate/SKILL.md
```

## Use

It triggers proactively on session-end signals — "let's close this", "wrap up", "is this all merged?",
"are we good to close?" — or invoke it explicitly:

```
/clean-slate
```

It will not fire on a mid-task "are we good?" check-in with no work in flight — that's not session end.

## Example output

Here is a sample report from a session that had one gap merged via a PR and one item held for the owner, so you can see the output shape before installing.

<details>
<summary>Sample clean-slate report</summary>

```
# Clean-Slate Report — auth-rate-limit session / 2026-06-29

## ⚠️ Looks done but ISN'T
- "Rate-limit fix is merged" — it was NOT. PR #482 was still OPEN at wind-down;
  the branch `fix/login-rate-limit` was pushed but never landed. Closing here
  would have left main without the fix. Now merged (see below).

## Blocked on owner
- PR #485 (`migrate-sessions-to-redis`) — staged, reviewed, CI green, but it runs
  a destructive table migration with broad blast radius. HELD, not merged: a
  migration at wind-down needs your go-ahead and a rollback window, not an
  autonomous merge.

## Claims verified
- "Rate-limit fix committed and pushed" — VERIFIED (evidence: `git log @{u}..` empty,
  branch `fix/login-rate-limit` ahead 0 of origin)
- "Rate-limit fix merged to main" — GAP (said merged; `gh pr view 482` →
  "state":"OPEN","mergedAt":null) → reconciled: merged in PR #482, now
  "state":"MERGED","mergedAt":"2026-06-29T03:11:42Z"
- "Unit + integration tests pass" — VERIFIED (re-ran this session: `pytest -q` →
  214 passed, 0 failed; CI on main `gh run list --branch main --limit 1` →
  "conclusion":"success")
- "Redis session migration ready" — GAP (claimed done; PR #485 →
  "state":"OPEN") → HELD as BLOCKED-ON-OWNER, see above

## Reconciled this session
- Merged: PR #482 (login rate-limit) — low-risk, fully verified, tests green,
  review clean. Held: PR #485 (redis session migration) — destructive migration,
  needs owner sign-off + rollback window.
- Learnings: added to `LEARNINGS.md` — "express-rate-limit needs `trust proxy`
  set or all clients share one bucket behind the load balancer" (new gotcha, not
  previously documented; grep of LEARNINGS.md + CLAUDE.md found no existing rule).
- Code: root-cause fix in PR #482 — `trust proxy` enabled in `src/app.ts` and
  keyGenerator switched to `req.ip`; the earlier hardcoded `100` constant was
  moved to `config/rateLimit.ts`.
- Docs: `README.md` deploy section updated to note the `TRUST_PROXY=1` env var;
  `docs/auth.md` rate-limit table corrected (was 60/min, code is 100/min).

## Clean to close?  BLOCKED-ON-OWNER — PR #482 landed and verified; redis session migration (PR #485) held pending your go-ahead on the destructive step.
```

</details>

## How it adapts to your harness

The skill is written in actions, not tool names, so it runs anywhere — but a few things map to your setup:

- **Instructions file** (Steps 5 & 7) — it writes durable rules to your agent-instructions file. That's
  `CLAUDE.md` for Claude Code and `AGENTS.md` for Codex / OpenClaw / Hermes. Point it at whichever you use.
- **Auto-commit hooks** (Step 2) — if your environment commits/pushes edits automatically, the skill already
  treats "clean tree ≠ safe" and checks for a PR instead. Adjust the specifics if your hook differs.
- **Merge protocol** (Step 4) — set it to your repo's convention (rebase vs squash, required reviewers, CI).
- **Where learnings go** (Step 5) — point it at your `LEARNINGS.md`, memory/notes store, and instructions
  file.

## License

MIT — see [LICENSE](LICENSE).
