# Contributing to clean-slate

Thanks for helping out. clean-slate is one file — `SKILL.md` — plus two installers that drop it into a harness's skills directory. Most contributions are small. Keep them that way.

## The one thing that grows over time: adding a new harness

Supporting a new agent harness means adding it in **three places** and keeping them in sync. The project's own review already caught a sync bug where the installers and the README drifted — so treat "all three match" as a hard requirement, not a nicety.

### 1. `install.sh` — add a `case` arm

Each harness is one line setting `GLOBAL_DIR` (home-scoped) and `PROJECT_DIR` (repo-local). Match the existing shape exactly:

```sh
  newharness)  GLOBAL_DIR="$HOME/.newharness/skills/clean-slate"; PROJECT_DIR=".newharness/skills/clean-slate" ;;
```

Then add the name to **both** the `--help` usage line and the unknown-harness error so they list it:

```sh
echo "usage: install.sh [claude-code|codex|openclaw|hermes|newharness] [--project]"
```
```sh
echo "clean-slate: unknown harness '$HARNESS' (claude-code|codex|openclaw|hermes|newharness)" >&2
```

### 2. `install.ps1` — add a hashtable entry **and** extend `[ValidateSet(...)]`

Two edits here, not one. Add the `$paths` entry (`Global` + `Project`, backslash paths):

```powershell
  "newharness"  = @{ Global = "$HOME\.newharness\skills\clean-slate"; Project = ".newharness\skills\clean-slate" }
```

Then add the name to the param's `[ValidateSet(...)]` — miss this and PowerShell rejects the value before your hashtable entry is ever reached:

```powershell
  [ValidateSet("claude-code", "codex", "openclaw", "hermes", "newharness")]
```

### 3. `README.md` — add a compatibility-matrix row

Add a row to the table under **## Compatibility**, with both directories trailing-slashed to match the existing rows:

```markdown
| **NewHarness** | `~/.newharness/skills/clean-slate/` | `.newharness/skills/clean-slate/` |
```

### Keep all three in sync

`GLOBAL_DIR`/`PROJECT_DIR` in `install.sh`, `Global`/`Project` in `install.ps1`, and the matrix row in `README.md` must describe the **same two paths**. A diff that edits one or two but not all three is the exact drift the project's review caught before — reviewers will check that the paths agree across all three files.

## Testing `install.sh` locally without touching your real home dir

Run the installer against a throwaway `HOME` so a global install lands in a temp dir instead of `~`. The harness is the first positional arg; no `--project` means global scope:

```sh
TMPHOME=$(mktemp -d); HOME="$TMPHOME" sh ./install.sh newharness
```

Then verify the file landed at the path your matrix row promises, and that it's actually this skill:

```sh
ls "$TMPHOME/.newharness/skills/clean-slate/SKILL.md"                          # the matrix global path
grep '^name: clean-slate' "$TMPHOME/.newharness/skills/clean-slate/SKILL.md"   # must match
```

For the project scope, run from inside a scratch dir and pass `--project` as the second arg:

```sh
cd "$(mktemp -d)" && sh /path/to/install.sh newharness --project
ls .newharness/skills/clean-slate/SKILL.md
```

**Don't regress the foreign-`SKILL.md` guard.** The installer copies a local `./SKILL.md` only when `grep -q '^name: clean-slate'` confirms it's *this* skill; otherwise it downloads from the repo. A bare "`./SKILL.md` exists" check would copy an unrelated skill when the script is piped (`curl | sh`) from inside some other skill's directory. `install.ps1` enforces the same guard via `Select-String -Pattern '^name: clean-slate' -Quiet`. Keep both checks intact.

## PR etiquette

- **Small PRs.** One harness, one fix, or one doc change per PR — easy to review, easy to revert.
- **WHY in the commit message.** State the reason for the change, not just what changed.
- **The skill body stays harness-agnostic.** `SKILL.md` speaks in actions, not tool names. When it refers to the agent-instructions file, it names both forms — `CLAUDE.md` / `AGENTS.md` — and lets the reader point it at theirs. Don't hardcode one harness's filenames, paths, or commands into the skill body; harness-specific paths belong in the installers and the README matrix, not the skill.
