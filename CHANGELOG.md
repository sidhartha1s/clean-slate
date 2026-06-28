# Changelog

All notable changes to clean-slate are documented here.

## [0.2.0] — 2026-06-29

### Added
- **Multi-harness support.** Install commands and skill paths for **Codex** (OpenAI),
  **OpenClaw**, and **Hermes** (Nous Research), alongside the original **Claude Code**.
- **`install.sh`** (Linux/macOS) and **`install.ps1`** (Windows) — copy `SKILL.md` into the
  right skills directory for the chosen harness, global or `--project` scope. Run from a clone
  or pipe straight from `curl`/`irm`.
- Harness compatibility matrix and per-OS install instructions in the README.
- **`CONTRIBUTING.md`** — how to add a new harness (the three in-sync touch-points across
  `install.sh`, `install.ps1`, and the README matrix) and how to test the installer against a
  throwaway `HOME`.
- **Example output** section in the README — a sample clean-slate report so readers see the
  output shape before installing.

### Notes
- The skill body was already harness-agnostic (it speaks in actions and names your
  instructions file as `CLAUDE.md` / `AGENTS.md`), so no behavioral changes were needed.

## [0.1.0] — 2026-06-29

### Added
- Initial public release: the `clean-slate` session-end verification skill for Claude Code.
