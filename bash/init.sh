# Wczytywany przez source w interaktywnej powłoce Bash.
case $- in
    *i*) ;;
    *) return ;;
esac

_DOTFILES_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)" || return

source "$_DOTFILES_DIR/bash/aliases.sh"
source "$_DOTFILES_DIR/bash/functions.sh"

# Przenośne ustawienia z konfiguracji użytkownika.
HISTCONTROL=ignoredups
HISTSIZE=2000
HISTFILESIZE=2000

if [[ -d "$HOME/.local/bin" ]]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi

if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
fi

# Ustawienia danego serwera mają pierwszeństwo przed wspólnymi.
if [[ -r "$HOME/.bashrc.local" ]]; then
    source "$HOME/.bashrc.local"
fi
