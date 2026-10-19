#!/usr/bin/env bash
set -euo pipefail

config_only=false
case "${1:-}" in
    --config-only) config_only=true ;;
    --help)
        printf 'Użycie: bash scripts/install-nvim.sh [--config-only]\n'
        printf 'Instaluje Neovim przez APT na Debianie i podłącza konfigurację użytkownika.\n'
        printf -- '--config-only: podłącza wyłącznie konfigurację, bez APT i sudo.\n'
        exit 0 ;;
    '') ;;
    *) printf 'Nieznany argument: %s\n' "$1" >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
    printf 'Podaj najwyżej jeden argument.\n' >&2
    exit 2
fi

: "${HOME:?Brak zmiennej HOME}"
repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_root/nvim"
source_file="$repo_dir/nvim/init.lua"

if [[ "$config_root" != /* ]]; then
    printf 'XDG_CONFIG_HOME musi być ścieżką absolutną.\n' >&2
    exit 1
fi
if [[ "${NVIM_APPNAME:-nvim}" != nvim ]]; then
    printf 'Ten zestaw używa standardowego profilu nvim; usuń NVIM_APPNAME przed instalacją i uruchamianiem edytora.\n' >&2
    exit 1
fi
if [[ ! -r "$source_file" ]]; then
    printf 'Nie można odczytać konfiguracji: %s\n' "$source_file" >&2
    exit 1
fi

# Sprawdź pliki przed instalacją pakietu lub przeniesieniem konfiguracji.
for name in init.lua init.vim; do
    target="$config_dir/$name"
    if [[ -e "$target" && ! -f "$target" && ! -L "$target" ]]; then
        printf 'Oczekiwano pliku konfiguracyjnego: %s\n' "$target" >&2
        exit 1
    fi
done

if [[ "$config_only" == false ]]; then
    if [[ $(uname -s) != Linux || ! -f /etc/debian_version ]]; then
        printf 'Instalacja pakietu wymaga Debiana. Dla samej konfiguracji użyj --config-only.\n' >&2
        exit 1
    fi
    if ! command -v nvim >/dev/null 2>&1; then
        command -v apt-get >/dev/null 2>&1 || {
            printf 'Nie znaleziono apt-get.\n' >&2
            exit 1
        }
        if [[ $EUID -eq 0 ]]; then
            apt-get update
            apt-get install --yes neovim
        else
            command -v sudo >/dev/null 2>&1 || {
                printf 'Administrator musi zainstalować pakiet neovim (brak sudo).\n' >&2
                exit 1
            }
            sudo apt-get update
            sudo apt-get install --yes neovim
        fi
    else
        printf 'Neovim jest już dostępny; pomijam instalację pakietu.\n'
    fi
fi

mkdir -p -- "$config_dir"
backup_dir=''
for name in init.lua init.vim; do
    target="$config_dir/$name"
    if [[ "$name" == init.lua && -L "$target" ]] && [[ $(readlink "$target") == "$source_file" ]]; then
        continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -z "$backup_dir" ]]; then
            backup_dir=$(mktemp -d "$config_dir/backup-dotfiles.XXXXXX")
            printf 'Kopia poprzedniej konfiguracji: %s\n' "$backup_dir"
        fi
        mv -- "$target" "$backup_dir/$name"
    fi
done

if [[ ! -L "$config_dir/init.lua" ]]; then
    ln -s -- "$source_file" "$config_dir/init.lua"
fi
printf 'Konfiguracja Neovima: %s -> %s\n' "$config_dir/init.lua" "$source_file"
printf 'Nowe uruchomienie nvim wczyta aktualną konfigurację z repozytorium.\n'
printf 'Aby ustawić EDITOR/VISUAL w bieżącej sesji Bash, wykonaj: source ~/.bashrc\n'
