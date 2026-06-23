$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps   = Join-Path $here '..\..\skills\init\scripts\powershell'
$pass = 0; $fail = 0
function Assert-Eq($a,$b,$m){ if($a -eq $b){$script:pass++} else {$script:fail++; Write-Host "FAIL: $m - expected [$b] got [$a]"} }

# fixture
$root = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path "$root\spex\specs" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\spex\memory\tech-docs" | Out-Null
"fastspex: 1`nmode: brownfield`nself_review: true`nscripts: true" |
  Out-File -Encoding utf8 "$root\spex\config.yml"
Push-Location $root

# new-feature -> 001 slug, active-feature, JSON
$out = & "$ps\new-feature.ps1" --json "Add User Login!" | Out-String
Assert-Eq ([bool]($out -match '"feature":"001-add-user-login"')) $true "new-feature numbered slug"
Assert-Eq (Test-Path "$root\spex\specs\001-add-user-login\spec.md") $true "spec.md created"
Assert-Eq ((Get-Content "$root\spex\active-feature" -Raw).Trim()) "001-add-user-login" "active-feature written"

# check design fails (draft) then passes (approved)
& "$ps\check.ps1" --phase design *> $null; Assert-Eq $LASTEXITCODE 1 "design gate fails on draft"
(Get-Content "$root\spex\specs\001-add-user-login\spec.md") -replace 'status: draft','status: approved' |
  Set-Content "$root\spex\specs\001-add-user-login\spec.md"
& "$ps\check.ps1" --phase design *> $null; Assert-Eq $LASTEXITCODE 0 "design gate passes on approved"
& "$ps\check.ps1" --phase bogus  *> $null; Assert-Eq $LASTEXITCODE 2 "bad phase -> exit 2"

Pop-Location

# ----------------------------------------------------------------------------
# install-contexthub.ps1 — ContextHub MCP installer (parity with bash variant).
# SAFETY: npm/claude are stubbed as fake .cmd shims on a temp PATH and HOME is
# redirected to a temp dir, so the real npm/claude/global config are untouched.
# ----------------------------------------------------------------------------
$installer = Join-Path $ps 'install-contexthub.ps1'

# Build an isolated sandbox: a stub PATH dir + a fake HOME. $npmMode controls
# whether the npm stub succeeds ('ok') or fails ('fail'); $withClaude toggles
# whether a claude.cmd shim is present. Returns a hashtable describing the env.
function New-InstallSandbox([string]$npmMode = 'ok', [bool]$withClaude = $true) {
  $base    = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
  $binDir  = Join-Path $base 'bin'
  $homeDir = Join-Path $base 'home'
  New-Item -ItemType Directory -Force -Path $binDir  | Out-Null
  New-Item -ItemType Directory -Force -Path $homeDir | Out-Null
  $npmLog    = Join-Path $base 'npm.log'
  $claudeLog = Join-Path $base 'claude.log'
  # claude state: a marker file under HOME stands in for "chub is registered".
  $regFile = Join-Path $homeDir 'claude-registered'

  $npmExit = if ($npmMode -eq 'fail') { 1 } else { 0 }
  @"
@echo off
echo %* >> "$npmLog"
exit /b $npmExit
"@ | Set-Content -Encoding ascii (Join-Path $binDir 'npm.cmd')

  if ($withClaude) {
    # `claude mcp list` prints chub only after `claude mcp add` has run once,
    # which is recorded by creating $regFile. This emulates idempotent registration.
    @"
@echo off
echo %* >> "$claudeLog"
if "%1"=="mcp" if "%2"=="list" (
  if exist "$regFile" echo chub: chub-mcp
  exit /b 0
)
if "%1"=="mcp" if "%2"=="add" (
  echo registered > "$regFile"
  exit /b 0
)
exit /b 0
"@ | Set-Content -Encoding ascii (Join-Path $binDir 'claude.cmd')
  }

  @{
    Base = $base; Bin = $binDir; Home = $homeDir
    NpmLog = $npmLog; ClaudeLog = $claudeLog
    Mcp = (Join-Path $homeDir '.claude\mcp.json')
  }
}

# Run the installer inside a sandbox with npm/claude shimmed and HOME redirected.
# Captures stdout + exit code while leaving the outer environment untouched.
# SAFETY: PATH is reduced to ONLY the stub bin + System32, so the real npm/claude
# (elsewhere on the user's PATH) are unreachable and can never be invoked.
function Invoke-Installer($sb) {
  $savedPath = $env:PATH
  $savedHome = $env:HOME
  $savedUser = $env:USERPROFILE
  $savedHomeDrive = $env:HOMEDRIVE
  $savedHomePath  = $env:HOMEPATH
  try {
    $sys = Join-Path $env:SystemRoot 'System32'
    $psh = Join-Path $sys 'WindowsPowerShell\v1.0'
    $env:PATH        = "$($sb.Bin);$sys;$psh"
    $env:HOME        = $sb.Home
    $env:USERPROFILE = $sb.Home
    # PowerShell derives $HOME from HOMEDRIVE+HOMEPATH on Windows; align them too.
    $env:HOMEDRIVE = ''
    $env:HOMEPATH  = $sb.Home
    $stdout = & powershell -NoProfile -ExecutionPolicy Bypass -File $installer 2>$null | Out-String
    return @{ Out = $stdout; Code = $LASTEXITCODE }
  } finally {
    $env:PATH        = $savedPath
    $env:HOME        = $savedHome
    $env:USERPROFILE = $savedUser
    $env:HOMEDRIVE   = $savedHomeDrive
    $env:HOMEPATH    = $savedHomePath
  }
}

# (A) claude + npm present -> installs, registers via claude, idempotent.
$sb = New-InstallSandbox 'ok' $true
$r1 = Invoke-Installer $sb
Assert-Eq $r1.Code 0 "A: exit 0 when npm+claude present"
Assert-Eq ([bool]($r1.Out -match '"installed":true')) $true "A: stdout has installed:true"
$npmLog1 = if (Test-Path $sb.NpmLog) { Get-Content $sb.NpmLog -Raw } else { '' }
Assert-Eq ([bool]($npmLog1 -match 'install -g @aisuite/chub')) $true "A: npm called with install -g @aisuite/chub"
$claudeLog1 = if (Test-Path $sb.ClaudeLog) { Get-Content $sb.ClaudeLog -Raw } else { '' }
Assert-Eq ([bool]($claudeLog1 -match 'mcp add')) $true "A: claude mcp add called"
Assert-Eq ([bool]($claudeLog1 -match 'chub')) $true "A: claude add references chub"
Assert-Eq ([bool]($claudeLog1 -match 'chub-mcp')) $true "A: claude add references chub-mcp"
# idempotent second run: registers exactly once (no duplicate `mcp add`).
$r2 = Invoke-Installer $sb
Assert-Eq $r2.Code 0 "A: exit 0 on idempotent re-run"
$addCount = ([regex]::Matches((Get-Content $sb.ClaudeLog -Raw), 'mcp add')).Count
Assert-Eq $addCount 1 "A: claude mcp add not duplicated on re-run"

# (B) npm fails -> non-zero exit, does NOT print installed.
$sbF = New-InstallSandbox 'fail' $true
$rF = Invoke-Installer $sbF
Assert-Eq ([bool]($rF.Code -ne 0)) $true "B: non-zero exit when npm fails"
Assert-Eq ([bool]($rF.Out -match '"installed":true')) $false "B: no installed:true when npm fails"

# (C) no claude -> ~/.claude/mcp.json fallback, created with chub, idempotent.
$sbC = New-InstallSandbox 'ok' $false
$rC1 = Invoke-Installer $sbC
Assert-Eq $rC1.Code 0 "C: exit 0 via mcp.json fallback"
Assert-Eq (Test-Path $sbC.Mcp) $true "C: mcp.json created"
$mcpRaw = if (Test-Path $sbC.Mcp) { Get-Content $sbC.Mcp -Raw } else { '' }
Assert-Eq ([bool]($mcpRaw -match 'chub')) $true "C: mcp.json contains chub"
Assert-Eq ([bool]($mcpRaw -match 'chub-mcp')) $true "C: mcp.json contains chub-mcp command"
Assert-Eq ([bool]($rC1.Out -match '"installed":true')) $true "C: stdout has installed:true"
# idempotent: re-run does not duplicate the chub entry.
$rC2 = Invoke-Installer $sbC
Assert-Eq $rC2.Code 0 "C: exit 0 on idempotent re-run"
$mcpObj = (Get-Content $sbC.Mcp -Raw | ConvertFrom-Json)
$chubProps = @($mcpObj.mcpServers.PSObject.Properties | Where-Object { $_.Name -eq 'chub' })
Assert-Eq $chubProps.Count 1 "C: single chub entry after re-run"

Write-Host "----"; Write-Host "pass=$pass fail=$fail"
if ($fail -gt 0) { exit 1 }
