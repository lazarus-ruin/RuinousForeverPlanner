param(
    [string]$GameRoot = 'C:\Program Files (x86)\World of Warcraft',
    [switch]$StageWhileRunning
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $projectRoot 'RuinousForeverPlanner'
$gameFull = [IO.Path]::GetFullPath($GameRoot)
$buildInfo = Join-Path $gameFull '.build.info'
if (!(Test-Path -LiteralPath $buildInfo)) { throw 'Cannot verify the WoW installation: .build.info missing.' }
$betaLine = Get-Content -LiteralPath $buildInfo | Where-Object { $_ -match '\|wow_classic_beta\s*$' } | Select-Object -First 1
if (!$betaLine) { throw 'Installation metadata does not identify wow_classic_beta.' }
$buildMatch = [regex]::Match($betaLine, '\b1\.60\.\d+\.\d+\b')
if (!$buildMatch.Success) { throw 'Unexpected beta version; inspect compatibility before installing.' }
$runningClient = [bool](Get-Process -Name 'WowB' -ErrorAction SilentlyContinue)
if ($runningClient -and !$StageWhileRunning) { throw 'Close the Forever beta client before installing, or explicitly use -StageWhileRunning to stage files without reloading.' }
$toc = Join-Path $source 'RuinousForeverPlanner.toc'
if (!(Test-Path -LiteralPath $toc)) { throw 'Project addon source is missing.' }
$release = Get-Content -LiteralPath (Join-Path $projectRoot 'release.json') -Raw | ConvertFrom-Json
$sourceToc = Get-Content -LiteralPath $toc
if (!($sourceToc -contains ('## Version: ' + $release.version))) { throw 'Source TOC and release version differ.' }
$addons = [IO.Path]::GetFullPath((Join-Path $gameFull '_classic_beta_\Interface\AddOns'))
$destination = [IO.Path]::GetFullPath((Join-Path $addons 'RuinousForeverPlanner'))
if ((Split-Path -Parent $destination) -ne $addons -or (Split-Path -Leaf $destination) -ne 'RuinousForeverPlanner') { throw 'Unexpected destination.' }
$backup = $null
if (Test-Path -LiteralPath $destination) {
    if ((Get-Item -LiteralPath $destination).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Destination is a link; inspect manually before installation.' }
    $backup = Join-Path $projectRoot ('output\install-backups\RuinousForeverPlanner-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Get-ChildItem -LiteralPath $destination -File | Copy-Item -Destination $backup
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source -File | Copy-Item -Destination $destination -Force
$verified = @()
foreach ($file in Get-ChildItem -LiteralPath $source -File) {
    $installed = Join-Path $destination $file.Name
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    if ((Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash -ne $hash) { throw ('Installation verification failed: ' + $file.Name) }
    $verified += [ordered]@{name=$file.Name;sha256=$hash}
}
# The user requested a complete rename and confirmed no settings need migration.
# Preserve the previous addon outside AddOns so both copies cannot load together.
$legacy = [IO.Path]::GetFullPath((Join-Path $addons 'ForeverPlanner'))
$legacyBackup = $null
if (Test-Path -LiteralPath $legacy) {
    if ((Split-Path -Parent $legacy) -ne $addons -or (Split-Path -Leaf $legacy) -ne 'ForeverPlanner') { throw 'Unexpected legacy addon path.' }
    if ((Get-Item -LiteralPath $legacy).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Legacy addon is a link; inspect before moving.' }
    $backupRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'output\install-backups'))
    $legacyBackup = [IO.Path]::GetFullPath((Join-Path $backupRoot ('Legacy-ForeverPlanner-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))))
    if ((Split-Path -Parent $legacyBackup) -ne $backupRoot) { throw 'Unexpected legacy backup target.' }
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    if (Test-Path -LiteralPath $legacyBackup) { throw 'Legacy backup already exists; retry with a new timestamp.' }
    Move-Item -LiteralPath $legacy -Destination $legacyBackup
}
$report = [ordered]@{version=$release.version;clientVersion=$buildMatch.Value;destination=$destination;backup=$backup;legacyBackup=$legacyBackup;files=$verified;clientWasRunning=$runningClient;restartRequired=$true;clientLaunched=$false;inGameTested=$false}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $projectRoot 'output\installation-report.json') -Encoding utf8
Write-Output ('Installed and hash-verified RuinousForeverPlanner ' + $release.version + ' in beta client ' + $buildMatch.Value)
Write-Output 'Live login and /rfp verification are still required.'
