artisan() {
    if [[ ! -f artisan ]]; then
        printf 'Uruchom komendę w głównym katalogu aplikacji Laravel (plik artisan).\n' >&2
        return 1
    fi
    command php artisan "$@"
}

ams() {
    artisan migrate:status "$@"
}

ao() {
    artisan optimize "$@"
}

aoc() {
    artisan optimize:clear "$@"
}

acc() {
    artisan config:clear "$@"
}

acache() {
    artisan config:cache "$@"
}

tabname() {
    printf '\033]1;%s\007' "$*"
}

mkcd() {
    if [[ $# -ne 1 || -z $1 ]]; then
        printf 'Użycie: mkcd KATALOG\n' >&2
        return 2
    fi
    mkdir -p -- "$1" && cd -- "$1"
}

jlog() {
    if [[ $# -ne 1 || -z $1 ]]; then
        printf 'Użycie: jlog USŁUGA (np. jlog ssh)\n' >&2
        return 2
    fi
    command journalctl --unit="$1" --lines=100 --no-pager
}

jfollow() {
    if [[ $# -ne 1 || -z $1 ]]; then
        printf 'Użycie: jfollow USŁUGA (Ctrl+C kończy podgląd)\n' >&2
        return 2
    fi
    command journalctl --unit="$1" --lines=100 --follow
}

dotfiles-update() {
    local repo="${_DOTFILES_DIR:-}" top status file
    if [[ -z "$repo" || ! -d "$repo" ]]; then
        printf 'Brak katalogu dotfiles. Wczytaj konfigurację ponownie.\n' >&2
        return 1
    fi
    top=$(command git -C "$repo" rev-parse --show-toplevel) || return
    if [[ "$top" != "$repo" ]]; then
        printf 'Katalog dotfiles musi być głównym katalogiem repozytorium Git.\n' >&2
        return 1
    fi
    status=$(command git -C "$repo" status --porcelain --untracked-files=all) || return
    if [[ -n "$status" ]]; then
        printf 'Aktualizacja przerwana: repozytorium zawiera lokalne zmiany lub nowe pliki.\n' >&2
        printf 'Sprawdź: git -C %q status\n' "$repo" >&2
        return 1
    fi
    command git -C "$repo" symbolic-ref -q HEAD >/dev/null || {
        printf 'Aktualizacja wymaga aktywnej gałęzi (wykryto detached HEAD).\n' >&2
        return 1
    }
    command git -C "$repo" rev-parse --verify '@{upstream}' >/dev/null || return
    command git -C "$repo" pull --ff-only || return

    for file in init.sh aliases.sh functions.sh; do
        if ! command bash -n "$repo/bash/$file"; then
            printf 'Pliki pobrano, ale nie wczytano konfiguracji: błąd składni w %s.\n' "$file" >&2
            return 1
        fi
    done
    source "$repo/bash/init.sh" || return
    printf 'Dotfiles zaktualizowane i wczytane w bieżącej powłoce.\n'
}

dotfiles-help() {
    cat <<'HELP'
ll / la           Lista plików (szczegółowa / z ukrytymi)
.. / ...          Przejście o jeden / dwa katalogi wyżej
dfh / duh         Miejsce na dyskach / rozmiary katalogów
freeh             Zużycie pamięci
ports             Porty TCP/UDP nasłuchujące (wymaga ss)
failed            Usługi w stanie failed (wymaga systemctl)
artisan ...       php artisan ... (z katalogu aplikacji Laravel)
ams               artisan migrate:status
ao / aoc          artisan optimize / optimize:clear
acc / acache      artisan config:clear / config:cache
crd               composer run dev (jeśli projekt definiuje skrypt dev)
casa / cnsa       sites-available Apache / Nginx
tabname TYTUŁ     Tytuł karty w terminalach obsługujących OSC 1
mkcd KATALOG      Utworzenie katalogu i przejście do niego
jlog USŁUGA       Ostatnie 100 wpisów dziennika usługi
jfollow USŁUGA    Podgląd dziennika na żywo; zakończenie: Ctrl+C
dotfiles-update   Git pull --ff-only i wczytanie konfiguracji
dotfiles-help     Ta lista
HELP
}
