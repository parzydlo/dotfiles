
$Env:TERM = "xterm-256color"
$Env:EDITOR = "nvim"
$Env:VISUAL = "nvim"

function gs { git status @args }
function config { git --git-dir=$HOME\.dotfiles --work-tree=$HOME @args }
oh-my-posh init pwsh --config 'C:\Users\Jan\AppData\Local\Programs\oh-my-posh\themes\pure.omp.json' | Invoke-Expression  # [omp-manager]
