<#
.SYNOPSIS
    Set up this dotfiles checkout on a Windows machine.

.DESCRIPTION
    Run after the bare clone and checkout described in README.md next to this
    file. Every step checks first and skips work that is already done, so the
    script is safe to re-run. Nothing is deleted: an existing file or folder
    in the way of a link is renamed to <name>.bak-<timestamp>.

    Written for Windows PowerShell 5.1, because a fresh machine has no pwsh 7
    until step 2 installs it.

.PARAMETER BuildTools
    Also install Visual Studio 2022 Build Tools (C++ workload, several GB).
    Needed for telescope-fzf-native and for compiling treesitter parsers.
    Without it nvim still works: telescope falls back to its Lua sorter.

.PARAMETER SkipPackages
    Skip winget, npm and uv installs; only do config, links and venv.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File $HOME\.config\dotfiles\bootstrap.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$BuildTools,
    [switch]$SkipPackages,
    [string]$GitName,
    [string]$GitEmail
)

$ErrorActionPreference = 'Stop'
$GitDir = Join-Path $HOME '.dotfiles'
$Notes = New-Object System.Collections.Generic.List[string]

function Write-Step([string]$Text) { Write-Host "`n== $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text) { Write-Host "   ok    $Text" -ForegroundColor DarkGray }
function Write-Do([string]$Text) { Write-Host "   do    $Text" -ForegroundColor Green }
function Write-Warn2([string]$Text) { Write-Host "   WARN  $Text" -ForegroundColor Yellow; $Notes.Add($Text) }
function Test-Command([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-WingetPackage([string]$Id, [string[]]$Extra = @()) {
    $null = winget list --id $Id --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok $Id; return }
    if ($PSCmdlet.ShouldProcess($Id, 'winget install')) {
        Write-Do "winget install $Id"
        winget install --id $Id --exact --silent --accept-source-agreements --accept-package-agreements @Extra
        if ($LASTEXITCODE -ne 0) { Write-Warn2 "winget install $Id failed (exit $LASTEXITCODE)" }
    }
}

function Get-FullPath([string]$Path) {
    [IO.Path]::GetFullPath($Path).TrimEnd('\')
}

# Make $Link point at $Target. Kind is Junction (directories, no privilege
# needed) or SymbolicLink (files; needs Developer Mode or admin).
function Set-Link([string]$Link, [string]$Target, [string]$Kind) {
    if (-not (Test-Path -LiteralPath $Target)) {
        Write-Warn2 "link target missing, skipped: $Target"
        return
    }
    $item = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
        $current = @($item.Target)[0]
        if ($current -and ((Get-FullPath $current) -eq (Get-FullPath $Target))) {
            Write-Ok "$Link -> $Target"
            return
        }
    }
    if (-not $PSCmdlet.ShouldProcess($Link, "link to $Target")) { return }
    if ($item) {
        # Rename, never delete: Remove-Item on a junction can recurse into its target.
        $backup = '{0}.bak-{1}' -f $item.Name, (Get-Date -Format 'yyyyMMdd-HHmmss')
        Rename-Item -LiteralPath $Link -NewName $backup
        Write-Do "moved existing $Link to $backup"
    }
    $parent = Split-Path $Link -Parent
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    if ($Kind -eq 'Junction') {
        New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
    } else {
        # cmd's mklink passes the unprivileged-create flag, so Developer Mode is
        # enough; New-Item -ItemType SymbolicLink in 5.1 needs admin.
        cmd /c mklink "$Link" "$Target" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warn2 "could not symlink $Link. Turn on Developer Mode (Settings > System > For developers) and re-run."
            return
        }
    }
    Write-Do "$Link -> $Target"
}

# ---------------------------------------------------------------------------
Write-Step '1. dotfiles repo settings'
if (-not (Test-Path (Join-Path $GitDir 'HEAD'))) {
    throw "No bare repo at $GitDir. Follow README.md first."
}
$repoSettings = [ordered]@{
    'status.showUntrackedFiles' = 'no'      # work tree is $HOME
    'core.autocrlf'             = 'false'   # repo is shared with the mac; store bytes as-is
    'remote.origin.fetch'       = '+refs/heads/*:refs/remotes/origin/*'  # bare clones lack it
}
foreach ($key in $repoSettings.Keys) {
    $want = $repoSettings[$key]
    $have = git --git-dir=$GitDir config --get $key
    if ($have -eq $want) { Write-Ok "$key = $want"; continue }
    if ($PSCmdlet.ShouldProcess($key, "git config = $want")) {
        git --git-dir=$GitDir config $key $want
        Write-Do "$key = $want"
    }
}

# ---------------------------------------------------------------------------
Write-Step '2. packages'
if ($SkipPackages) {
    Write-Ok 'skipped (-SkipPackages)'
} else {
    if (-not (Test-Command winget)) { throw 'winget not found. Install "App Installer" from the Microsoft Store.' }
    $packages = @(
        'Git.Git'
        'Microsoft.PowerShell'
        'Neovim.Neovim'
        'JanDeDobbeleer.OhMyPosh'
        'astral-sh.uv'
        'BurntSushi.ripgrep.MSVC'   # telescope find_files and live_grep
        'Kitware.CMake'             # builds telescope-fzf-native
        'OpenJS.NodeJS.LTS'         # mason's node-based servers, tree-sitter-cli
        'marlocarlo.psmux'
    )
    foreach ($id in $packages) { Install-WingetPackage $id }
    if ($BuildTools) {
        Install-WingetPackage 'Microsoft.VisualStudio.2022.BuildTools' @(
            '--override', '--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
    } else {
        Write-Ok 'VS Build Tools skipped (pass -BuildTools for telescope-fzf-native and treesitter parsers)'
    }
    Update-SessionPath

    if (Test-Command claude) {
        Write-Ok 'Claude Code'
    } elseif ($PSCmdlet.ShouldProcess('Claude Code', 'native install')) {
        Write-Do 'Claude Code (native installer)'
        Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    }

    if (Test-Command tree-sitter) {
        Write-Ok 'tree-sitter-cli'
    } elseif (-not (Test-Command npm)) {
        Write-Warn2 'npm not on PATH yet; open a new shell and re-run for tree-sitter-cli'
    } elseif ($PSCmdlet.ShouldProcess('tree-sitter-cli', 'npm install -g')) {
        Write-Do 'npm install -g tree-sitter-cli'
        npm install -g tree-sitter-cli
    }

    # basedpyright and ruff are uv tools, not mason packages: mason cannot
    # install python servers without a real python.exe on PATH.
    if (Test-Command uv) {
        $uvTools = (uv tool list 2>$null) -join "`n"
        foreach ($tool in 'basedpyright', 'ruff') {
            if ($uvTools -match "(?m)^$tool ") { Write-Ok "uv tool $tool"; continue }
            if ($PSCmdlet.ShouldProcess($tool, 'uv tool install')) {
                Write-Do "uv tool install $tool"
                uv tool install $tool
            }
        }
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | ForEach-Object { $_.TrimEnd('\') }
        if ($userPath -contains (Join-Path $HOME '.local\bin')) {
            Write-Ok '~/.local/bin on user PATH'
        } elseif ($PSCmdlet.ShouldProcess('~/.local/bin', 'uv tool update-shell')) {
            Write-Do 'uv tool update-shell (adds ~/.local/bin to user PATH)'
            uv tool update-shell 2>$null | Out-Null
            Update-SessionPath
        }
    } else {
        Write-Warn2 'uv not on PATH yet; open a new shell and re-run for basedpyright/ruff and the Claude venv'
    }
}

# ---------------------------------------------------------------------------
Write-Step '3. font (BlexMono Nerd Font Mono, used by Windows Terminal)'
$fontDirs = @("$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts")
$haveFont = $fontDirs | Where-Object { Test-Path "$_\BlexMonoNerdFontMono-Regular.ttf" }
if ($haveFont) {
    Write-Ok 'BlexMono Nerd Font Mono'
} elseif (-not (Test-Command oh-my-posh)) {
    Write-Warn2 'oh-my-posh not on PATH yet; open a new shell and re-run for the font'
} elseif ($PSCmdlet.ShouldProcess('IBMPlexMono Nerd Font', 'oh-my-posh font install')) {
    Write-Do 'oh-my-posh font install IBMPlexMono'
    oh-my-posh font install IBMPlexMono --headless
}

# ---------------------------------------------------------------------------
Write-Step '4. links into the checkout'
$docs = [Environment]::GetFolderPath('MyDocuments')
if ($docs -match 'OneDrive') {
    Write-Warn2 "Documents is redirected into OneDrive ($docs). The PowerShell junction works locally, but OneDrive does not sync through junctions; exclude the folder from sync if it complains."
}
Set-Link (Join-Path $docs 'PowerShell') (Join-Path $HOME '.config\powershell') 'Junction'
Set-Link (Join-Path $env:LOCALAPPDATA 'nvim') (Join-Path $HOME '.config\nvim') 'Junction'

$wtState = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
if (Test-Path $wtState) {
    # File symlink, not hardlink: WT saves by replacing the file, which would
    # break a hardlink; it resolves symlinks and writes through them.
    Set-Link (Join-Path $wtState 'settings.json') (Join-Path $HOME '.config\windows-terminal\settings.json') 'SymbolicLink'
} else {
    Write-Warn2 'Windows Terminal has not run yet (no LocalState). Start it once, close it, and re-run.'
}

# ---------------------------------------------------------------------------
Write-Step '5. Claude Code venv (statusline and memory hook run from it)'
$venvPy = Join-Path $HOME '.claude\venv\Scripts\python.exe'
if (Test-Path $venvPy) {
    Write-Ok $venvPy
} elseif (-not (Test-Command uv)) {
    Write-Warn2 'uv missing; Claude Code statusline and PreToolUse hook will fail until ~/.claude/venv exists'
} elseif ($PSCmdlet.ShouldProcess('~/.claude/venv', 'uv venv --python 3.14')) {
    Write-Do 'uv venv --python 3.14 ~/.claude/venv'
    uv venv --python 3.14 (Join-Path $HOME '.claude\venv')
}

# ---------------------------------------------------------------------------
Write-Step '6. psmux plugins'
$pluginRoot = Join-Path $HOME '.psmux\plugins'
$conf = Join-Path $HOME '.psmux.conf'
$wanted = @()
if (Test-Path $conf) {
    $wanted = Select-String -Path $conf -Pattern "^\s*set\s+-g\s+@plugin\s+'psmux-plugins/([^']+)'" |
        ForEach-Object { $_.Matches[0].Groups[1].Value }
}
$missing = @($wanted | Where-Object { -not (Test-Path (Join-Path $pluginRoot $_)) })
if ($missing.Count -eq 0) {
    Write-Ok ("{0} plugins present" -f @($wanted).Count)
} elseif ($PSCmdlet.ShouldProcess(($missing -join ', '), 'copy from psmux/psmux-plugins')) {
    # Same source ppm uses: one monorepo, one folder per plugin.
    $tmp = Join-Path $env:TEMP ("psmux-plugins-" + [guid]::NewGuid().ToString('N'))
    git clone --depth 1 --quiet https://github.com/psmux/psmux-plugins.git $tmp
    if (-not (Test-Path $pluginRoot)) { New-Item -ItemType Directory -Path $pluginRoot | Out-Null }
    foreach ($name in $missing) {
        Copy-Item -Recurse (Join-Path $tmp $name) (Join-Path $pluginRoot $name)
        Write-Do "plugin $name"
    }
    Remove-Item -Recurse -Force $tmp
}

# ---------------------------------------------------------------------------
Write-Step '7. git identity (~/.gitconfig.local, untracked)'
$local = Join-Path $HOME '.gitconfig.local'
if (Test-Path $local) {
    Write-Ok $local
} elseif ($PSCmdlet.ShouldProcess($local, 'write [user] name/email')) {
    if (-not $GitName)  { $GitName  = Read-Host 'git user.name' }
    if (-not $GitEmail) { $GitEmail = Read-Host 'git user.email' }
    # UTF-8 without BOM: git reads the file as bytes and a BOM breaks the first section header.
    $text = "[user]`n`tname = $GitName`n`temail = $GitEmail`n"
    [IO.File]::WriteAllText($local, $text, (New-Object System.Text.UTF8Encoding $false))
    Write-Do "$local ($GitEmail)"
}

# ---------------------------------------------------------------------------
Write-Step 'done'
Write-Host '   Still manual:'
Write-Host '   - open a new terminal so PATH changes apply'
Write-Host '   - start nvim once: vim.pack installs plugins, mason installs its servers'
Write-Host '   - winget psmux is upstream: it lacks the local core and plugin patches'
if ($Notes.Count) {
    Write-Host "`n   Warnings:" -ForegroundColor Yellow
    $Notes | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
}
