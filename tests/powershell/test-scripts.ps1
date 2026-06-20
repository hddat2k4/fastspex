$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps   = Join-Path $here '..\..\skills\spex-init\scripts\powershell'
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
Write-Host "----"; Write-Host "pass=$pass fail=$fail"
if ($fail -gt 0) { exit 1 }
