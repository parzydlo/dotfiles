function __tokyonight_colors -S
    set -l background 24283b 1f2335
    set -l background_highlight 292e42
    set -l foreground c0caf5 a9b1d6
    set -l foreground_gutter 3b4261
    set -l dark 545c7e 737aa2
    set -l blue 3d59a1 7aa2f7 2ac3de 0db9d7 89ddff b4f9f8 394b70
    set -l cyan 7dcfff
    set -l magenta bb9af7 ff007c
    set -l purple 9d7cd8
    set -l orange ff9e64
    set -l yellow e0af68
    set -l green 9ece6a 73daca 41a6b5
    set -l teal 1abc9c
    set -l red f7768e db4b4b
    set -l selection 2e3c64
    set -l comment 565f89
    set -l terminal_black 414868

# Syntax Highlighting Colors
    set -x fish_color_normal $foreground[1]
    set -x fish_color_command $cyan
    set -x fish_color_keyword $pink
    set -x fish_color_quote $yellow
    set -x fish_color_redirection $foreground[1]
    set -x fish_color_end $orange
    set -x fish_color_error $red[1]
    set -x fish_color_param $purple
    set -x fish_color_comment $comment
    set -x fish_color_selection --background=$selection
    set -x fish_color_search_match --background=$selection
    set -x fish_color_operator $green[1]
    set -x fish_color_escape $pink
    set -x fish_color_autosuggestion $comment

# Completion Pager Colors
    set -x fish_pager_color_progress $comment
    set -x fish_pager_color_prefix $cyan
    set -x fish_pager_color_completion $foreground[1]
    set -x fish_pager_color_description $comment
    set -x fish_pager_color_selected_background --background=$selection

# Prompt Colors
    set -x color_dir_bg $blue[2]
    set -x color_virtual_env_bg $green[2]
    set -x color_git_bg $green[1]
end
