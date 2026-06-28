# clean-slate

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that turns **"looks done"** into
**"is actually done"** before you close a coding session.

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

## Install

Drop the skill into your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/clean-slate
cp SKILL.md ~/.claude/skills/clean-slate/SKILL.md
```

(Or your project-local `.claude/skills/` if you want it per-repo.)

## Use

It triggers proactively on session-end signals — "let's close this", "wrap up", "is this all merged?",
"are we good to close?" — or invoke it explicitly:

```
/clean-slate
```

It will not fire on a mid-task "are we good?" check-in with no work in flight — that's not session end.

## Customize

The skill is written to be harness-agnostic, but a few things are worth tuning to your setup:

- **Merge protocol** (Step 4) — set it to your repo's convention (rebase vs squash, required reviewers, CI).
- **Where learnings go** (Step 5) — point it at your `LEARNINGS.md`, notes store, and instructions file
  (`CLAUDE.md` / `AGENTS.md`).
- **Auto-commit behavior** (Step 2) — if your environment commits/pushes edits automatically, the "clean
  tree ≠ safe" note already covers it; adjust the specifics if your hook differs.

## License

MIT — see [LICENSE](LICENSE).
