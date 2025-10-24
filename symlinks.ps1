<# 
  Zweck:
    - Verschiebt ausgewählte Configs in ~/.dotfiles
    - Erstellt Symlinks/Junctions zurück an die gewohnten Orte
    - Idempotent: vorhandene Links/Ziele werden geprüft & übersprungen
  Hinweise:
    - Für Datei-Symlinks Adminrechte ODER Windows-Entwicklermodus.
    - Junctions für Ordner funktionieren ohne Admin.
#>

param(
  [string]$DotfilesRoot = "$HOME\.dotfiles",
  [switch]$VerboseLog
)

# ---------- Hilfsfunktionen ----------

function Write-Info($msg)  { if ($VerboseLog) { Write-Host "[INFO]  $msg" } }
function Write-Skip($msg)  { Write-Host "[SKIP]  $msg" -ForegroundColor Yellow }
function Write-Ok($msg)    { Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Act($msg)   { Write-Host "[DO]    $msg" -ForegroundColor Cyan }
function Timestamp()       { Get-Date -Format "yyyyMMdd-HHmmss" }

function Initialize-Directory($path) {  
  $dir = (Split-Path -Parent $path)
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

function Test-PathIsLink($path) {       
  try { $item = Get-Item -LiteralPath $path -ErrorAction Stop; return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint) }
  catch { return $false }
}

function Get-ItemLinkTarget($path) {    
  try { $item = Get-Item -LiteralPath $path -ErrorAction Stop; if ($item.PSObject.Properties.Name -contains 'LinkTarget') { return $item.LinkTarget } else { return $null } }
  catch { return $null }
}

function Move-ItemToDotfiles($src, $dst) {  
  Initialize-Directory $dst
  if (Test-Path $dst) {
    $bak = "$src.bak.$(Timestamp)"
    Write-Act "Backup vorhandener Quelle: `"$src`" → `"$bak`" (Dotfiles-Ziel existiert schon)"
    Move-Item -LiteralPath $src -Destination $bak -Force
    return
  }
  Write-Act "Move: `"$src`" → `"$dst`""
  Initialize-Directory $dst
  Move-Item -LiteralPath $src -Destination $dst -Force
}

function New-ItemLink($linkPath, $targetPath, [ValidateSet('File','Directory')]$kind) { 
  Initialize-Directory $linkPath
  if ($kind -eq 'Directory') {
    New-Item -ItemType Junction -Path $linkPath -Target $targetPath -Force | Out-Null
  } else {
    New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -Force | Out-Null
  }
  Write-Ok "Link: `"$linkPath`" → `"$targetPath`""
}

function Set-ItemLink($linkPath, $dotfilePath, [ValidateSet('File','Directory')]$kind) {  
  if (Test-PathIsLink $linkPath) {
    $cur = Get-ItemLinkTarget $linkPath
    if ($cur -and (Resolve-Path $cur -ErrorAction SilentlyContinue) -and ((Resolve-Path $cur).Path -ieq (Resolve-Path $dotfilePath).Path)) {
      Write-Skip "Bereits verlinkt: `"$linkPath`" → `"$cur`""
      return
    } else {
      Write-Act "Entferne bestehenden Link für Neuverlinkung: `"$linkPath`""
      Remove-Item -LiteralPath $linkPath -Force
    }
  }
  if (Test-Path $linkPath) { Move-ItemToDotfiles -src $linkPath -dst $dotfilePath }
  if ($kind -eq 'Directory') {
    if (-not (Test-Path $dotfilePath)) { New-Item -ItemType Directory -Path $dotfilePath | Out-Null }
  } else {
    Initialize-Directory $dotfilePath
    if (-not (Test-Path $dotfilePath)) { New-Item -ItemType File -Path $dotfilePath | Out-Null }
  }
  New-ItemLink -linkPath $linkPath -targetPath $dotfilePath -kind $kind
}


# ---------- Konfiguration ----------

$VSUser = Join-Path $env:APPDATA "Code\User"

$Plan = @(
  @{ Link = "$HOME\.gitconfig";                     Dot = Join-Path $DotfilesRoot ".gitconfig";                     Kind = 'File' }
  @{ Link = "$HOME\.gitignore";                     Dot = Join-Path $DotfilesRoot ".gitignore";                     Kind = 'File' }
  @{ Link = "$HOME\.bash_profile";                  Dot = Join-Path $DotfilesRoot ".bash_profile";                  Kind = 'File' }
  @{ Link = "$HOME\.bashrc";                        Dot = Join-Path $DotfilesRoot ".bashrc";                        Kind = 'File' }
  @{ Link = "$HOME\.bash_aliases";                  Dot = Join-Path $DotfilesRoot ".bash_aliases";                  Kind = 'File' }
  @{ Link = (Join-Path $VSUser "settings.json");    Dot = Join-Path $DotfilesRoot "vscode\User\settings.json";      Kind = 'File' }
  @{ Link = (Join-Path $VSUser "keybindings.json"); Dot = Join-Path $DotfilesRoot "vscode\User\keybindings.json";   Kind = 'File' }
  @{ Link = (Join-Path $VSUser "snippets");         Dot = Join-Path $DotfilesRoot "vscode\User\snippets";           Kind = 'Directory' }
)

# ---------- Ablauf ----------

Write-Host "=== Setup Dotfiles → $DotfilesRoot ==="
if (-not (Test-Path $DotfilesRoot)) {
  Write-Act "Erzeuge Dotfiles-Root: `"$DotfilesRoot`""
  New-Item -ItemType Directory -Path $DotfilesRoot | Out-Null
}

foreach ($item in $Plan) {
  $link = $item.Link
  $dot  = $item.Dot
  $kind = $item.Kind
  Write-Info "Verarbeite: $link  (→ $dot)  [$kind]"
  Set-ItemLink -linkPath $link -dotfilePath $dot -kind $kind
}

Write-Host "=== Fertig. ==="
