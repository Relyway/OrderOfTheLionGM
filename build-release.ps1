param([string]$Version = "1.0.9")

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$StageRoot = Join-Path $env:TEMP ("OrderOfTheLionGM-release-" + [guid]::NewGuid().ToString("N"))
$AddonStage = Join-Path $StageRoot "OrderOfTheLionGM"
$Output = Join-Path $RepoRoot ("OrderOfTheLionGM-v" + $Version + ".zip")

New-Item -ItemType Directory -Path $AddonStage -Force | Out-Null

$Files = @(
    "OrderOfTheLionGM.toc",
    "Core.lua",
    "Advanced.lua",
    "UI.lua",
    "Minimap.lua",
    "Events.lua",
    "README.txt",
    "CHANGELOG.txt"
)

foreach ($File in $Files) {
    Copy-Item (Join-Path $RepoRoot $File) (Join-Path $AddonStage $File) -Force
}

if (Test-Path $Output) {
    Remove-Item $Output -Force
}

Compress-Archive -Path $AddonStage -DestinationPath $Output -CompressionLevel Optimal
Remove-Item $StageRoot -Recurse -Force

Write-Host "Created $Output"
