if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -Ux VIRTUAL_ENV_DISABLE_PROMPT 1

set -x PYENV_ROOT $HOME/.pyenv
#set -x PATH $PYENV_ROOT/bin $PATH
fish_add_path $PYENV_ROOT/bin
pyenv init - | source

__tokyonight_colors
