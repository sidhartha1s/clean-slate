# clean-slate

A harness-agnostic session-end verification skill that turns "looks done" into "is actually done," for Claude Code, Codex, OpenClaw, and Hermes.

## The problem it solves

You read the assistant's end-of-session summary, believe everything shipped, and close the laptop. Hours later you discover: nothing was merged to `main`, the "fix" was a hardcoded session-local hack, the learnings never left the chat, and the docs went stale. The summary was a claim, not a fact, and nobody checked the difference.

## What it does

When a session is wrapping up, clean-slate:

1. Enumerates every claim of done, committed, merged, pushed, tested, fixed, or shipped from the session.
2. Verifies each against the real artifact (git, the PR, the file, the test or CI output), not the chat prose or a context-compaction summary. If it was not run this session, it did not pass this session.
3. Reconciles unmerged work via PR: merges the safe, verified items, holds the risky ones for the owner.
4. Lands learnings where they belong (LEARNINGS.md, memory, an instructions file, or a machine gate).
5. Sweeps stale docs: read-before-edit, surgical, no invented facts.
6. Emits a report that flags anything that looks done but is not, ending in a YES, NO, or BLOCKED-ON-OWNER verdict.

It also catches an auto-commit hook that makes a dirty tree look clean, branches pushed but never PR'd, non-git contexts (notes or config dirs), secrets in the commit range, and a "fix" that is really a workaround.

## Compatibility

The skill is a single `SKILL.md`. Each harness auto-discovers it and activates it on the `description` frontmatter.

| Harness | Global skills dir | Project (repo-local) skills dir |
|---|---|---|
| Claude Code | `~/.claude/skills/clean-slate/` | `.claude/skills/clean-slate/` |
| Codex (OpenAI) | `~/.codex/skills/clean-slate/` | `.agents/skills/clean-slate/` |
| OpenClaw | `~/.openclaw/skills/clean-slate/` | `.openclaw/skills/clean-slate/` |
| Hermes (Nous Research) | `~/.hermes/skills/clean-slate/` | `skills/clean-slate/` |

Codex and Hermes also read `~/.agents/skills/`, a shared cross-agent location if you prefer one directory for every tool.

## Install

Replace `claude-code` with `codex`, `openclaw`, or `hermes` as needed. Add `--project` (or `-Project` on Windows) to install into the current repo instead of your home directory.

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/install.sh | sh -s -- claude-code
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/install.ps1 -OutFile install.ps1; ./install.ps1 claude-code
```

**Manual**, no script, copy `SKILL.md` into the matching directory from the table above:

```bash
mkdir -p ~/.codex/skills/clean-slate
curl -fsSL https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/SKILL.md \
  -o ~/.codex/skills/clean-slate/SKILL.md
```

## Usage

It triggers proactively on session-end signals, such as "let's close this," "wrap up," "is this all merged?," or "are we good to close?," or invoke it explicitly:

```
/clean-slate
```

It will not fire on a mid-task "are we good?" check-in with no work in flight; that is not session end.

## Layout

- `SKILL.md`: the skill itself, written in actions rather than tool names so it runs on any harness.
- `install.sh` / `install.ps1`: installer scripts, one per-harness target directory each.
- `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`: standard repo files.

## Notes

- **Instructions file**: it writes durable rules to `CLAUDE.md` for Claude Code, or `AGENTS.md` for Codex, OpenClaw, and Hermes.
- **Auto-commit hooks**: the skill treats a clean tree as not proof of safety by itself, and checks for a PR instead.
- **Merge protocol and where learnings land** are meant to be adjusted to match your repo's own convention.

## License

MIT, see [LICENSE](LICENSE).
