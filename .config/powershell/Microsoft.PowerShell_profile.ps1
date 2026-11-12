
$Env:EDITOR = "nvim"
$Env:VISUAL = "nvim"

function gs { git status @args }
function config { git --git-dir=$HOME\.dotfiles --work-tree=$HOME @args }
# poimandres token colours for PSReadLine. Stock defaults are ANSI indices
# (Command = ESC[93m bright yellow); these are 24-bit values taken from the
# scopes named in the comments. See ~/.claude/memory/tools/oh-my-posh.md
#
# Do NOT guard this on `Get-Module -Name PSReadLine`: ConsoleHost imports
# PSReadLine AFTER the profile runs, so that check is false here and the whole
# block silently does nothing. Calling Set-PSReadLineOption auto-imports it.
try {
    Set-PSReadLineOption -Colors @{
        Command            = "`e[38;2;173;215;255m"  # ADD7FF entity.name.function
        Parameter          = "`e[38;2;145;180;213m"  # 91B4D5 keyword.operator
        Operator           = "`e[38;2;145;180;213m"  # 91B4D5 keyword.operator
        Keyword            = "`e[38;2;166;172;205m"  # A6ACCD keyword.control
        Type               = "`e[38;2;166;172;205m"  # A6ACCD entity.name.type.alias
        String             = "`e[38;2;95;179;161m"   # 5FB3A1 string.regexp
        Number             = "`e[38;2;93;228;199m"   # 5DE4C7 constant.numeric
        Variable           = "`e[38;2;228;240;251m"  # E4F0FB variable.other.readwrite
        Member             = "`e[38;2;228;240;251m"  # E4F0FB variable.other.property
        Comment            = "`e[38;2;118;124;157m"  # 767C9D comment
        Default            = "`e[38;2;166;172;205m"  # A6ACCD editor.foreground
        Emphasis           = "`e[38;2;93;228;199m"   # 5DE4C7 accent
        Error              = "`e[38;2;208;103;157m"  # D0679D support.class.error
        InlinePrediction   = "`e[38;2;80;100;119m"   # 506477 dimmed ghost text
        ContinuationPrompt = "`e[38;2;118;124;157m"  # 767C9D
        Selection          = "`e[38;2;228;240;251;48;2;113;124;180m"  # E4F0FB on 717CB4
    }
} catch {
    Write-Verbose "PSReadLine colours not applied: $_"
}

oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\poimandres.omp.json" | Invoke-Expression  # [omp-manager]
