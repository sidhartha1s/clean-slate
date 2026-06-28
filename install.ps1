<#
.SYNOPSIS
  clean-slate installer (Windows / PowerShell).
  Drops SKILL.md into your agent harness's skills directory.

.EXAMPLE
  ./install.ps1 codex
  ./install.ps1 hermes -Project

  # one-liner (download then run, so args can be passed):
  irm https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/install.ps1 -OutFile install.ps1; ./install.ps1 codex
#>
param(
  [ValidateSet("claude-code", "codex", "openclaw", "hermes")]
  [string]$Harness = "claude-code",
  [switch]$Project
)
$ErrorActionPreference = "Stop"
$rawSkill = "https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/SKILL.md"

$paths = @{
  "claude-code" = @{ Global = "$HOME\.claude\skills\clean-slate";   Project = ".claude\skills\clean-slate" }
  "codex"       = @{ Global = "$HOME\.codex\skills\clean-slate";    Project = ".agents\skills\clean-slate" }
  "openclaw"    = @{ Global = "$HOME\.openclaw\skills\clean-slate"; Project = ".openclaw\skills\clean-slate" }
  "hermes"      = @{ Global = "$HOME\.hermes\skills\clean-slate";   Project = "skills\clean-slate" }
}

$dest = if ($Project) { $paths[$Harness].Project } else { $paths[$Harness].Global }
New-Item -ItemType Directory -Force -Path $dest | Out-Null

if (Test-Path "./SKILL.md") {
  Copy-Item "./SKILL.md" "$dest\SKILL.md" -Force
} else {
  Invoke-WebRequest -Uri $rawSkill -OutFile "$dest\SKILL.md"
}

Write-Host "clean-slate installed for $Harness -> $dest\SKILL.md"
