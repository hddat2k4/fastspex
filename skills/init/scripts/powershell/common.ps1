# Fastspex shared helpers (PowerShell). Dot-source: . common.ps1
function Find-SpexRoot([string]$Start = (Get-Location).Path) {
  $dir = $Start
  while ($dir -and (Test-Path $dir)) {
    if (Test-Path (Join-Path $dir 'spex\config.yml')) { return $dir }
    $parent = Split-Path -Parent $dir
    if ($parent -eq $dir) { break }
    $dir = $parent
  }
  return $null
}
function Read-Config([string]$Key,[string]$Root){
  if (-not $Root) { $Root = Find-SpexRoot }
  if (-not $Root) { return $null }
  $line = Select-String -Path (Join-Path $Root 'spex\config.yml') -Pattern "^$Key\s*:\s*(.*)$" |
          Select-Object -First 1
  if ($line) { return $line.Matches[0].Groups[1].Value.Trim() } else { return $null }
}
function Get-FrontmatterStatus([string]$File){
  if (-not (Test-Path $File)) { return $null }
  $lines = Get-Content $File
  if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $null }
  for ($i=1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '---') { break }
    if ($lines[$i] -match '^status:\s*(.*)$') { return $Matches[1].Trim() }
  }
  return $null
}
function Resolve-Feature([string]$Root){
  if (-not $Root) { $Root = Find-SpexRoot }
  if (-not $Root) { return $null }
  $specs = Join-Path $Root 'spex\specs'
  $ptr = Join-Path $Root 'spex\active-feature'
  if (Test-Path $ptr) {
    $f = (Get-Content $ptr -Raw).Trim()
    if ($f -and (Test-Path (Join-Path $specs $f))) { return $f }
  }
  if (Get-Command git -ErrorAction SilentlyContinue) {
    $br = (& git -C $Root rev-parse --abbrev-ref HEAD 2>$null)
    if ($br -and ($br -match '^[0-9]{3}-') -and (Test-Path (Join-Path $specs $br))) { return $br }
  }
  $dirs = @(Get-ChildItem -Directory $specs -ErrorAction SilentlyContinue)
  if ($dirs.Count -eq 1) { return $dirs[0].Name }
  if ($dirs.Count -eq 0) { return $null }
  return ($dirs | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name
}
