# Apply theme-specific config
test -f $OMF_CONFIG/theme
    and read -l theme < $OMF_CONFIG/theme
    if [ $theme = "bobthefish" ]
        source $OMF_CONFIG/bobthefish.fish
    end
