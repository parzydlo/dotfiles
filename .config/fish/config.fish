if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -Ux VIRTUAL_ENV_DISABLE_PROMPT 1
set -gx GTK_THEME Adwaita:dark
set -gx DISPLAY (cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0 #GWSL
set -gx PULSE_SERVER tcp:(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}') #GWSL

# Load pyenv automatically by appending
# the following to ~/.config/fish/config.fish:

pyenv init - | source

eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
