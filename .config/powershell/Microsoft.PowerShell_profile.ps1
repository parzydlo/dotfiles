oh-my-posh init pwsh --config 'pure' | Invoke-Expression

$Env:TERM = "xterm-256color"
$Env:EDITOR = "nvim"
$Env:VISUAL = "nvim"

function gs { git status @args }
function config { git --git-dir=$HOME\.dotfiles --work-tree=$HOME @args }
