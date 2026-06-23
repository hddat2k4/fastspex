# Install the ContextHub MCP server (@aisuite/chub) and register it with Claude
# Code. Idempotent: safe to re-run. Parity with bash install-contexthub.sh.
$ErrorActionPreference = 'Stop'

# 1) Require npm.
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  [Console]::Error.WriteLine('error: npm not found. Install Node.js (https://nodejs.org) then re-run.')
  exit 1
}

# 2) Global install (chub CLI + chub-mcp server binary).
& npm install -g '@aisuite/chub'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 3) Register the MCP server.
if (Get-Command claude -ErrorAction SilentlyContinue) {
  # Claude Code CLI present: register (idempotent) at user scope.
  $listed = (& claude mcp list 2>$null | Out-String)
  if ($listed -notmatch 'chub') {
    & claude mcp add --scope user chub -- chub-mcp | Out-Null
    if ($LASTEXITCODE -ne 0) {
      [Console]::Error.WriteLine('error: claude mcp add failed.')
      exit 1
    }
  }
} else {
  # No CLI: write/merge ~/.claude/mcp.json (create fresh, skip if present, else merge).
  $cfgDir  = Join-Path $HOME '.claude'
  $cfgFile = Join-Path $cfgDir 'mcp.json'
  New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
  if (-not (Test-Path $cfgFile)) {
    '{ "mcpServers": { "chub": { "command": "chub-mcp" } } }' |
      Set-Content -Encoding utf8 $cfgFile
  } else {
    $cfg = Get-Content $cfgFile -Raw | ConvertFrom-Json
    if (-not $cfg) { $cfg = [pscustomobject]@{} }
    if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers') -or -not $cfg.mcpServers) {
      $cfg | Add-Member -NotePropertyName 'mcpServers' -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    if (-not ($cfg.mcpServers.PSObject.Properties.Name -contains 'chub')) {
      $cfg.mcpServers | Add-Member -NotePropertyName 'chub' `
        -NotePropertyValue ([pscustomobject]@{ command = 'chub-mcp' }) -Force
      $cfg | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $cfgFile
    }
  }
}

# 4) Done.
'{"installed":true}'
exit 0
