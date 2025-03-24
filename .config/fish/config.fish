set -x LANG en_US.UTF-8

if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -Ux VIRTUAL_ENV_DISABLE_PROMPT 0
__poimandres_colors

# Set up PYENV_ROOT and PATH
set -x PYENV_ROOT $HOME/.pyenv
if test -d "$PYENV_ROOT/bin"
    fish_add_path $PYENV_ROOT/bin
end

# Define a wrapper function to lazy-load pyenv
function pyenv
    # Erase this wrapper so the next call goes to the real pyenv
    functions --erase pyenv

    # Load pyenv into the environment
    command pyenv init --path | source
    command pyenv init - | source

    # Re-run the original command with the real pyenv
    command pyenv $argv
end

test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish
