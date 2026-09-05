Write-Host "`n  Select Provider" -ForegroundColor Blue

# 简写参数展开
$resolvedArgs = @()
foreach ($arg in $args) {
    if ($arg -eq '--yolo') {
        $resolvedArgs += '--dangerously-skip-permissions'
    } else {
        $resolvedArgs += $arg
    }
}

$providersDir = "$env:USERPROFILE\.claude\providers"

# Scan all .json files and build menu entries
$entries = @()
Get-ChildItem -Path $providersDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    try {
        $data = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $model = if ($data.env.ANTHROPIC_MODEL) { $data.env.ANTHROPIC_MODEL } else { "unknown" }
    } catch {
        $model = "unknown"
    }
    $entries += [PSCustomObject]@{ Name = $name; Model = $model; Display = "{0,-12} {1}" -f $name, $model }
}

if ($entries.Count -eq 0) {
    Write-Host "No provider files found in $providersDir" -ForegroundColor Red
    exit 1
}

# Try fzf, fallback to numbered list
$selectedName = $null
$fzfAvailable = $null -ne (Get-Command fzf -ErrorAction SilentlyContinue)

if ($fzfAvailable) {
    $header = "Switch between providers. Applies to this and future Claude Code sessions."
    $selected = $entries | ForEach-Object { $_.Display } | fzf `
        --prompt="" `
        --header=$header `
        --header-first `
        --height=10 `
        --no-border `
        --padding="0,2" `
        --layout=reverse `
        --no-info `
        --separator="" `
        --pointer=" " `
        --color="header:gray,hl:blue,hl+:blue,bg+:-1,fg+:blue,pointer:blue"
    if ($selected) {
        $selectedName = ($selected -split "\s+")[0]
    }
} else {
    Write-Host "Switch between providers. Applies to this and future Claude Code sessions.`n" -ForegroundColor Gray
    for ($i = 0; $i -lt $entries.Count; $i++) {
        Write-Host "  $($i + 1)  $($entries[$i].Display)"
    }
    Write-Host ""
    $input = Read-Host "Enter number"
    $idx = [int]$input - 1
    if ($idx -ge 0 -and $idx -lt $entries.Count) {
        $selectedName = $entries[$idx].Name
    }
}

if (-not $selectedName) { exit 1 }

$providerPath = "$providersDir\$selectedName.json"
$settingsPath = "$env:USERPROFILE\.claude\settings.json"
if (-not (Test-Path $settingsPath)) { '{}' | Out-File -FilePath $settingsPath -Encoding utf8 }

$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
$providerEnv = Get-Content $providerPath -Raw | ConvertFrom-Json
$settings | Add-Member -NotePropertyMembers @{ env = $providerEnv.env } -Force
$settings | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $settingsPath -Encoding utf8

Write-Host "Switched to $selectedName, starting Claude Code..."
& claude @resolvedArgs
