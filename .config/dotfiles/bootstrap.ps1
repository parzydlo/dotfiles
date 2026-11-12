# Set up the dotfiles checkout on a Windows machine. Safe to re-run.
# Runs in Windows PowerShell 5.1. See README.md.
param([switch]$BuildTools)
$ErrorActionPreference = 'Stop'

$packages = @(
    'Microsoft.PowerShell'
    'Neovim.Neovim'
    'JanDeDobbeleer.OhMyPosh'
    'astral-sh.uv'
    'BurntSushi.ripgrep.MSVC'
    'Kitware.CMake'
    'OpenJS.NodeJS.LTS'
    'marlocarlo.psmux'
)
$npmTools = @('tree-sitter-cli')
$uvTools  = @('basedpyright', 'ruff')
$links = [ordered]@{
    (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell') = '.config\powershell'
    "$env:LOCALAPPDATA\nvim" = '.config\nvim'
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" = '.config\windows-terminal\settings.json'
}

function Has([string]$Cmd) { [bool](Get-Command $Cmd -ErrorAction SilentlyContinue) }

function Update-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Set-Link([string]$Link, [string]$Target) {
    $item = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -and (@($item.Target)[0] -eq $Target)) { return }
    if ($item) { Rename-Item -LiteralPath $Link "$($item.Name).bak-$(Get-Date -Format yyyyMMddHHmmss)" }
    New-Item -ItemType Directory -Force (Split-Path $Link) | Out-Null
    if (Test-Path -LiteralPath $Target -PathType Container) {
        New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
    } else {
        cmd /c mklink "$Link" "$Target" | Out-Null  # file symlink; needs Developer Mode
    }
    Write-Host "linked $Link"
}

# repo settings
$git = "--git-dir=$HOME\.dotfiles"
git $git config status.showUntrackedFiles no
git $git config core.autocrlf false
git $git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

# packages
if ($BuildTools) { $packages += 'Microsoft.VisualStudio.2022.BuildTools' }
foreach ($id in $packages) {
    winget list --id $id --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) {
        winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements
    }
}
Update-Path
if (-not (Has claude)) { Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression }
foreach ($t in $npmTools) { npm ls -g $t | Out-Null; if ($LASTEXITCODE -ne 0) { npm install -g $t } }
foreach ($t in $uvTools) { if (-not (Has $t)) { uv tool install $t } }
uv tool update-shell | Out-Null
Update-Path

# font
if (-not (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\BlexMono*", "$env:WINDIR\Fonts\BlexMono*" -ErrorAction SilentlyContinue)) {
    oh-my-posh font install IBMPlexMono --headless
}

# links
foreach ($link in $links.Keys) { Set-Link $link (Join-Path $HOME $links[$link]) }

# Claude Code venv for the statusline and hooks
if (-not (Test-Path "$HOME\.claude\venv")) { uv venv --python 3.14 "$HOME\.claude\venv" }

# psmux plugins named in .psmux.conf
$plugins = Select-String -Path "$HOME\.psmux.conf" -Pattern "@plugin\s+'psmux-plugins/([^']+)'" |
    ForEach-Object { $_.Matches[0].Groups[1].Value } |
    Where-Object { -not (Test-Path "$HOME\.psmux\plugins\$_") }
if ($plugins) {
    $tmp = Join-Path $env:TEMP "psmux-plugins-$PID"
    git clone --depth 1 --quiet https://github.com/psmux/psmux-plugins.git $tmp
    foreach ($p in $plugins) { Copy-Item -Recurse "$tmp\$p" "$HOME\.psmux\plugins\$p" }
    Remove-Item -Recurse -Force $tmp
}

# git identity, kept out of the repo
$local = "$HOME\.gitconfig.local"
if (-not (Test-Path $local)) {
    $name = Read-Host 'git user.name'
    $email = Read-Host 'git user.email'
    [IO.File]::WriteAllText($local, "[user]`n`tname = $name`n`temail = $email`n")
}

Write-Host 'Done. Open a new terminal, then start nvim once to install plugins.'
