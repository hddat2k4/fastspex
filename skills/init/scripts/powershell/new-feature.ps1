. "$PSScriptRoot\common.ps1"
$json = $false; $branch = $false; $descParts = @()
for ($i=0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    '--json'   { $json = $true }
    '--branch' { $branch = $true }
    default    { $descParts += $args[$i] }
  }
}
$desc = ($descParts -join ' ').Trim()
if (-not $desc) { [Console]::Error.WriteLine('error: feature description required'); exit 1 }
$root = Find-SpexRoot
if (-not $root) { [Console]::Error.WriteLine('error: spex/ not found (run /init)'); exit 1 }
$specs = Join-Path $root 'spex\specs'; New-Item -ItemType Directory -Force -Path $specs | Out-Null

$max = 0
Get-ChildItem -Directory $specs -ErrorAction SilentlyContinue | ForEach-Object {
  if ($_.Name -match '^(\d{3})-') { $n = [int]$Matches[1]; if ($n -gt $max) { $max = $n } }
}
$num = '{0:000}' -f ($max + 1)
$slug = ($desc.ToLower() -replace '[^a-z0-9]+','-').Trim('-')
$slug = ($slug -split '-' | Select-Object -First 5) -join '-'
if ($slug.Length -gt 50) { $slug = $slug.Substring(0,50).Trim('-') }
if (-not $slug) { $slug = 'feature' }

$feat = "$num-$slug"; $dir = Join-Path $specs $feat
if (Test-Path $dir) { [Console]::Error.WriteLine("error: $feat already exists"); exit 1 }
New-Item -ItemType Directory -Force -Path $dir | Out-Null
# Use the project-local spec template when init materialized it; else a frontmatter stub.
$tpl = Join-Path $root 'spex\templates\spec.md'
$specFile = Join-Path $dir 'spec.md'
if (Test-Path $tpl) {
  (Get-Content $tpl) -replace '^feature:.*', "feature: $feat" -replace '^status:.*', 'status: draft' |
    Set-Content -Encoding utf8 $specFile
} else {
  "---`nfeature: $feat`nstatus: draft`n---" | Out-File -Encoding utf8 $specFile
}
$feat | Out-File -Encoding utf8 (Join-Path $root 'spex\active-feature')

if ($branch -and (Get-Command git -ErrorAction SilentlyContinue)) {
  & git -C $root checkout -b $feat 2>$null | Out-Null
}

if ($json) {
  '{"feature":"' + $feat + '","feature_dir":"' + $dir + '","spec_file":"' + $specFile + '"}'
} else {
  "FEATURE=$feat`nFEATURE_DIR=$dir`nSPEC_FILE=$specFile"
}
