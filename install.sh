#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 0 ]]; then
    if [[ $# -eq 1 && $1 == --help ]]; then
        printf 'Użycie: bash install.sh\nPodłącza ten katalog do ~/.bashrc bieżącego użytkownika.\n'
        exit 0
    fi
    printf 'Nieznany argument. Użycie: bash install.sh [--help]\n' >&2
    exit 2
fi

: "${HOME:?Brak zmiennej HOME}"
repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
rc_file="$HOME/.bashrc"
begin_marker='# >>> linux-admin dotfiles >>>'
end_marker='# <<< linux-admin dotfiles <<<'

for file in init.sh aliases.sh functions.sh; do
    bash -n "$repo_dir/bash/$file"
done

if [[ ! -d "$HOME" ]]; then
    printf 'Katalog domowy nie istnieje: %s\n' "$HOME" >&2
    exit 1
fi
if [[ -e "$rc_file" && ! -f "$rc_file" ]] || [[ -L "$rc_file" && ! -e "$rc_file" ]]; then
    printf 'Nie można bezpiecznie zmodyfikować: %s\n' "$rc_file" >&2
    exit 1
fi

temp_file=$(mktemp "$HOME/.bashrc.dotfiles.XXXXXX")
trap 'rm -f -- "$temp_file"' EXIT

if [[ -f "$rc_file" ]]; then
    # Usuń tylko nasz poprzedni blok. Uszkodzone/zdublowane znaczniki przerywają instalację.
    awk -v begin="$begin_marker" -v end="$end_marker" '
        $0 == begin { if (inside || seen++) exit 1; inside=1; next }
        $0 == end { if (!inside) exit 1; inside=0; next }
        !inside { print }
        END { if (inside) exit 1 }
    ' "$rc_file" > "$temp_file" || {
        printf 'Nieprawidłowe znaczniki dotfiles w .bashrc. Plik pozostał bez zmian.\n' >&2
        exit 1
    }
fi

{
    printf '%s\n' "$begin_marker"
    printf 'if [ -n "${BASH_VERSION:-}" ] && [ -r %q ]; then\n' "$repo_dir/bash/init.sh"
    printf '    source %q\n' "$repo_dir/bash/init.sh"
    printf 'fi\n'
    printf '%s\n' "$end_marker"
} >> "$temp_file"

bash -n "$temp_file"
if [[ -f "$rc_file" ]] && cmp -s "$rc_file" "$temp_file"; then
    printf 'Konfiguracja jest już podłączona. Bez zmian.\n'
else
    if [[ -f "$rc_file" ]]; then
        backup_file=$(mktemp "$HOME/.bashrc.backup.XXXXXX")
        cp -p -- "$rc_file" "$backup_file"
        printf 'Kopia zapasowa: %s\n' "$backup_file"
        # Zapis przez istniejący plik zachowuje jego uprawnienia i dowiązanie symboliczne.
        cat "$temp_file" > "$rc_file"
    else
        cp -- "$temp_file" "$rc_file"
    fi
    printf 'Podłączono: %s\n' "$repo_dir"
fi

printf 'W bieżącym terminalu wykonaj: source ~/.bashrc\n'
printf 'Przy logowaniu SSH profil użytkownika musi wczytywać ~/.bashrc (opis w README.md).\n'
