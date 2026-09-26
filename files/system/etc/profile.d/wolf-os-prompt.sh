# shellcheck shell=sh
# Wolf OS terminal prompt (starship), for interactive bash shells.
# Turn it off with `wolf prompt off`. Your own ~/.config/starship.toml is used if you have one.
if [ -n "${BASH_VERSION:-}" ] && [ "${TERM:-dumb}" != dumb ] && command -v starship >/dev/null 2>&1 &&
    [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/wolf-os/prompt-off" ]; then
    case $- in
    *i*)
        if [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]; then
            export STARSHIP_CONFIG=/usr/share/wolf-os/starship.toml
        fi
        eval "$(starship init bash)"
        ;;
    esac
fi
