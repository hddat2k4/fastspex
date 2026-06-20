. "$PSScriptRoot\common.ps1"
$json = $false; $phase = ''
for ($i=0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    '--json'  { $json = $true }
    '--phase' { $i++; $phase = $args[$i] }
  }
}
$root = Find-SpexRoot
if (-not $root) { [Console]::Error.WriteLine('error: spex/ not found'); exit 2 }
$feat = Resolve-Feature $root
if (-not $feat) { [Console]::Error.WriteLine('error: no active feature'); exit 2 }
$dir = Join-Path $root "spex\specs\$feat"

switch ($phase) {
  'design'    { $prior = Join-Path $dir 'spec.md';   $label = 'spec' }
  'tasks'     { $prior = Join-Path $dir 'design.md'; $label = 'design' }
  'implement' { $prior = Join-Path $dir 'tasks.md';  $label = 'tasks' }
  default     { [Console]::Error.WriteLine('error: --phase must be design|tasks|implement'); exit 2 }
}

$ok = $true; $blocking = ''
if (-not (Test-Path $prior)) { $ok = $false; $blocking = "$label.md missing" }
else {
  $st = Get-FrontmatterStatus $prior
  if ($st -ne 'approved') { $ok = $false; $blocking = "$label.md not approved (status: $(if($st){$st}else{'none'}))" }
}

$docs = @()
$det = Join-Path $dir 'details'
if (Test-Path $det) { Get-ChildItem "$det\*.md" -ErrorAction SilentlyContinue | ForEach-Object { $docs += "details/$($_.Name)" } }
$td = Join-Path $root 'spex\memory\tech-docs'
if (Test-Path $td) { Get-ChildItem "$td\*.md" -ErrorAction SilentlyContinue | ForEach-Object { $docs += "tech-docs/$($_.Name)" } }
$docsStr = ($docs -join ',')

if ($json) {
  '{"feature":"' + $feat + '","feature_dir":"' + $dir + '","phase":"' + $phase +
  '","ok":' + ($ok.ToString().ToLower()) + ',"blocking":"' + $blocking +
  '","available_docs":"' + $docsStr + '"}'
} else {
  "FEATURE=$feat`nPHASE=$phase`nOK=$(if($ok){1}else{0})`nDOCS=$docsStr"
  if ($blocking) { "BLOCKING=$blocking" }
}
if ($ok) { exit 0 } else { exit 1 }
