# Completion korzysta wyłącznie z mechanizmów Basha, bez bash-completion.
_dotfiles_tmux_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]:-}" prev='' session
    COMPREPLY=()

    if (( COMP_CWORD > 0 )); then
        prev="${COMP_WORDS[COMP_CWORD-1]}"
    fi
    [[ "$prev" == -t ]] || return 0
    command -v tmux >/dev/null 2>&1 || return 0

    # Pętla działa również w Bash 3.2 i zachowuje spacje w nazwach sesji.
    while IFS= read -r session; do
        if [[ "$session" == "$cur"* ]]; then
            COMPREPLY+=("$session")
        fi
    done < <(command tmux list-sessions -F '#S' 2>/dev/null)
    return 0
}

# Nie zastępuj pełniejszego completion, jeśli zostało już zarejestrowane.
if command -v tmux >/dev/null 2>&1 && ! complete -p tmux >/dev/null 2>&1; then
    complete -F _dotfiles_tmux_complete tmux
fi
