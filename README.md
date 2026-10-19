# Linux Admin — Bash i Neovim na serwerach Debian

Przenośna konfiguracja użytkownika dla serwerów Debian. Repozytorium zawiera aliasy,
funkcje, konfigurację Neovima i instalatory. `install.sh` podłącza tylko Bash,
bez instalowania pakietów ani sudo. Osobny `scripts/install-nvim.sh` może zainstalować
systemowy pakiet Neovim przez APT, a następnie podłącza konfigurację użytkownika.
Przeznaczone dla interaktywnego **Basha**, nie dla zsh ani sh.

## Pierwsze uruchomienie

1. Wyślij przygotowane pliki do repozytorium `kzamojcin/linux-admin`. Nie zapisuj w nim haseł,
   tokenów, kluczy prywatnych ani konfiguracji zawierającej sekrety.
2. Na serwerze zaloguj się jako użytkownik, który ma korzystać z aliasów.
   Potrzebujesz Basha i Gita; jeśli brakuje Gita, administrator może zainstalować go
   komendą `sudo apt install git`.
3. Sklonuj repozytorium:

```bash
git clone https://github.com/kzamojcin/linux-admin.git "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
bash install.sh
source ~/.bashrc
dotfiles-help
```

HTTPS bez uwierzytelnienia wystarczy dla repozytorium publicznego. Dla prywatnego
skonfiguruj osobny klucz SSH na każdym serwerze i dodaj jego część publiczną do
**Settings → Deploy keys** tego repozytorium, bez zaznaczania **Allow write access**.
Przykład (nie nadpisuj istniejącego klucza o tej nazwie):

```bash
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
ssh-keygen -t ed25519 -f "$HOME/.ssh/linux_admin_deploy" -C "linux-admin@$(hostname)"
cat "$HOME/.ssh/linux_admin_deploy.pub"
```

Do `~/.ssh/config` dodaj dedykowany wpis (zachowaj pozostałe wpisy):

```sshconfig
Host github-linux-admin
    HostName github.com
    User git
    IdentityFile ~/.ssh/linux_admin_deploy
    IdentitiesOnly yes
```

Wtedy zamiast klonowania przez HTTPS użyj:

```bash
git clone git@github-linux-admin:kzamojcin/linux-admin.git "$HOME/.dotfiles"
```

Przy pierwszym połączeniu sprawdź fingerprint hosta według dokumentacji GitHuba.
Nie kopiuj między serwerami prywatnego klucza ze swojego komputera.
Hasło klucza może być obsługiwane przez `ssh-agent`; aktualizacja jest ręczna.

## Co robi instalator

- Dopisuje oznaczony blok do istniejącego `~/.bashrc`; reszta konfiguracji pozostaje.
- Przed zmianą istniejącego pliku tworzy `~/.bashrc.backup.XXXXXX`.
- Ponowne uruchomienie nie powiela bloku; jeśli nic się nie zmieniło, nie zapisuje pliku.
- Zapamiętuje rzeczywistą ścieżkę repozytorium, także zawierającą spacje.
- Sprawdza składnię Bash przed zapisaniem konfiguracji.
- Nie pobiera niczego z sieci i nie zmienia profilu logowania.

Uruchamiaj `bash install.sh` bez sudo, na koncie docelowym. Nazwa użytkownika
nie musi być taka sama na wszystkich serwerach. Po przeniesieniu katalogu repozytorium
uruchom instalator ponownie. Pliki ładowane przez `source` nie wymagają `chmod +x`.

### Sesje SSH

Standardowy profil użytkownika Debiana zwykle już wczytuje `.bashrc`.
Jeżeli po nowym logowaniu SSH nie ma aliasów, sprawdź profil logowania:
Bash wybiera **pierwszy istniejący i czytelny** plik spośród `~/.bash_profile`,
`~/.bash_login`, `~/.profile`. W tym pliku powinno znajdować się wczytanie `.bashrc`.
Jeżeli go brakuje, dodaj:

```bash
if [ -n "${BASH_VERSION:-}" ] && [ -r "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
```

Nie twórz bez potrzeby `.bash_profile`, bo przesłoni istniejący `.profile`.
Aliasy dotyczą interaktywnych sesji użytkownika. Nie są przeznaczone dla crona,
skryptów ani poleceń `ssh serwer komenda`. `sudo -i` uruchamia konfigurację roota.

## Dostępne komendy

| Komenda | Działanie |
| --- | --- |
| `ll`, `la` | Lista plików, także ukrytych |
| `..`, `...` | Przejście o jeden lub dwa katalogi wyżej |
| `dfh` | Zajętość systemów plików |
| `duh` | Rozmiary katalogów w bieżącej lokalizacji |
| `freeh` | Zużycie pamięci |
| `ports` | Nasłuchujące porty TCP/UDP; wymaga `ss` |
| `failed` | Usługi systemd w stanie failed |
| `artisan ...` | `php artisan ...` z zachowaniem wszystkich argumentów |
| `ams` | `php artisan migrate:status` |
| `ao` | `php artisan optimize` |
| `aoc` | `php artisan optimize:clear` |
| `acc` | `php artisan config:clear` |
| `acache` | `php artisan config:cache` |
| `crd` | `composer run dev` dla projektów ze skryptem `dev` |
| `llog` | `less "storage/logs/laravel-$(date +%F).log"` |
| `ltail` | `tail -f "storage/logs/laravel-$(date +%F).log"` |
| `casa` | Przejście do `/etc/apache2/sites-available` |
| `cnsa` | Przejście do `/etc/nginx/sites-available` |
| `tabname "Serwer testowy"` | Zmiana tytułu karty, jeśli terminal obsługuje OSC 1 |
| `mkcd "katalog"` | Utworzenie katalogu i przejście do niego |
| `jlog ssh` | Ostatnie 100 wpisów dziennika usługi ssh |
| `jfollow ssh` | Podgląd dziennika ssh na żywo; Ctrl+C kończy |
| `dotfiles-update` | Pobranie zmian i ponowne wczytanie konfiguracji |
| `dotfiles-help` | Skrócona pomoc |

Dostęp do dziennika zależy od uprawnień użytkownika. Jeśli potrzebne są wyższe
uprawnienia, użyj bezpośrednio np. `sudo journalctl -u ssh -n 100 --no-pager`.
Funkcja powłoki `jlog` nie jest programem dostępnym przez `sudo jlog`.

Komendy Artisan wymagają PHP CLI i uruchomienia z katalogu zawierającego plik
`artisan`. Skróty przekazują dodatkowe argumenty, np. `ams --database=pgsql`,
`ao --help`. Nie dodają `sudo`, `--force` ani completion.
`aoc` wykonuje dokładnie `optimize:clear`: zależnie od wersji Laravela usuwa również
dane domyślnego cache aplikacji, nie tylko cache konfiguracji. Do samej konfiguracji
służy `acc`. Komendy te są uruchamiane wyłącznie na żądanie, nigdy przy logowaniu.
`casa` i `cnsa` nie instalują serwerów WWW; gdy katalogu brakuje, `cd` zgłosi błąd.

`llog` i `ltail` uruchamiaj z głównego katalogu aplikacji Laravel korzystającej
z dziennych plików logów. Data jest wyliczana przy każdym wywołaniu według czasu
serwera. Wyjście z `less`: `q`; zakończenie `tail -f`: Ctrl+C. Po zmianie dnia
uruchom `ltail` ponownie, aby śledzić nowy plik.

## Neovim

Na Debianie, po sklonowaniu repozytorium, uruchom na swoim koncie:

```bash
cd "$HOME/.dotfiles"
bash scripts/install-nvim.sh
source ~/.bashrc
nvim /ścieżka/do/pliku
```

Skrypt używa `sudo` tylko dla `apt-get update` i `apt-get install --yes neovim`.
Gdy `nvim` jest już dostępny, pomija APT. **Nie uruchamiaj całego skryptu przez sudo**,
bo konfiguracja ma należeć do użytkownika; uruchomienie jako root konfiguruje roota.
Nie zmienia systemowych alternatyw edytora.

Jeżeli Neovim jest już zainstalowany lub chcesz przygotować samą konfigurację:

```bash
bash scripts/install-nvim.sh --config-only
```

Konfiguracja odwzorowuje ustawienia z lokalnych `.vimrc` i `init.lua`:

- kolorowanie składni i wykrywanie typu pliku;
- bezwzględny numer bieżącej linii i względne numery pozostałych;
- tabulator i poziom wcięcia po 4 kolumny (bez narzucania `expandtab`);
- podświetlenie bieżącej linii.

Nie wymaga pluginów, menedżera pakietów Neovima, LSP ani dostępu do sieci.
Konfiguracja to dowiązanie `~/.config/nvim/init.lua` do `nvim/init.lua` w repozytorium.
Uwzględnia również absolutne `XDG_CONFIG_HOME`; używa standardowego profilu `nvim`,
więc niestandardowe `NVIM_APPNAME` trzeba usunąć także przy uruchamianiu edytora.
Istniejące `init.lua` i `init.vim` są przenoszone do unikalnego katalogu
`backup-dotfiles.XXXXXX` w katalogu konfiguracji Neovima. Neovim nie powinien mieć
jednocześnie aktywnych obu plików. Pozostałe pliki (np. własne pluginy) pozostają.
Ponowne uruchomienie instalatora nie tworzy kolejnej kopii, jeśli link jest poprawny.
Plik `~/.vimrc` pozostaje bez zmian.

Po `dotfiles-update` nowe ustawienia edytora obowiązują przy następnym uruchomieniu
`nvim`. Po przeniesieniu repozytorium uruchom ponownie oba instalatory.
Przy wczytywaniu Bash `EDITOR` i `VISUAL` są ustawiane na `nvim` tylko wtedy, gdy
program jest dostępny. Własne wartości możesz ustawić później w `~/.bashrc.local`.

## Co przeniesiono z konfiguracji użytkownika

Oprócz Artisan i ustawień Neovima wspólne są `crd`, `tabname`, historia 2000 komend
z `HISTCONTROL=ignoredups` oraz istniejący `~/.local/bin` dodawany do PATH bez
duplikatów. Nie przeniesiono adresów SSH, tuneli, ścieżek projektów i zdjęć,
operacji rsync z usuwaniem, logowania do API, integracji Keychain/Homebrew/PhpStorm,
tworzenia klientów Passport ani completion Artisan. Fzf, zoxide i glow pozostają
opcjonalnymi ustawieniami lokalnymi; nie są zależnościami wspólnego zestawu.

## Zmiany i aktualizacje

Edytuj `bash/aliases.sh` lub `bash/functions.sh` na komputerze roboczym,
sprawdź składnię przez `bash -n PLIK`, a następnie zatwierdź i wyślij zmiany do GitHuba.
Na każdym serwerze wykonaj:

```bash
dotfiles-update
```

Komenda wymaga klonu Git z aktywną gałęzią śledzącą upstream. Przerywa pracę przy
lokalnych zmianach, również nieśledzonych plikach. Używa `git pull --ff-only`:
nie tworzy merge commitów, nie wykonuje resetu ani stasha. Następnie sprawdza
składnię trzech plików Bash i wczytuje konfigurację w bieżącej powłoce.
Jeśli pobrana konfiguracja ma błąd składni, pozostaje na dysku, ale nie jest wczytywana
przez tę komendę; popraw ją przed otwarciem następnej sesji. Sprawdzenie składni
nie zastępuje przeglądu zmian, ponieważ konfiguracja Bash jest wykonywalnym kodem.

Nie ma automatycznego pobierania przy logowaniu ani harmonogramu. Awaria sieci
nie przeszkadza w korzystaniu z już pobranej konfiguracji. Pozostałe otwarte sesje
zachowują swoje ustawienia do ponownego wczytania. Po **usunięciu lub zmianie nazwy**
aliasu/funkcji otwórz nową sesję, aby usunąć starą definicję z pamięci powłoki.

## Ustawienia konkretnego serwera

Opcjonalnie utwórz `~/.bashrc.local` **poza repozytorium**, np.:

```bash
alias capp='cd /var/www/moj-projekt'
```

Plik jest ładowany na końcu wspólnej konfiguracji i może nadpisywać jej aliasy.
Instalator go nie tworzy ani nie zmienia. Nie dodawaj tam `source ~/.bashrc`,
bo utworzyłoby to pętlę. Dotfiles powinny być wczytywane tylko raz z `.bashrc`.

## Odłączenie konfiguracji

Usuń z `~/.bashrc` fragment od `# >>> linux-admin dotfiles >>>` do
`# <<< linux-admin dotfiles <<<` włącznie i otwórz nową sesję.
Repozytorium oraz `~/.bashrc.local` mogą pozostać na dysku.

Aby odłączyć Neovim, usuń tylko utworzone przez instalator dowiązanie `init.lua`
i w razie potrzeby przywróć swoje pliki z wybranego katalogu `backup-dotfiles.*`.

## Sprawdzenie zmian lokalnie

```bash
python3 -m unittest discover -s tests -v
```

Testy używają katalogów tymczasowych i atrapy PHP: nie wywołują Artisan ani APT,
nie zmieniają konfiguracji użytkownika. Test ustawień i kolorowania w prawdziwym
Neovimie jest pomijany, jeśli program nie jest dostępny. Python służy wyłącznie
do testów, nie jest zależnością instalatorów.

## Dokumentacja źródłowa

- [Pliki startowe Bash](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)
- [GitHub deploy keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys)
- [Fingerprinty SSH GitHuba](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
- [Konfiguracja startowa Neovima](https://neovim.io/doc/user/starting/)
- [Pakiet Neovim w Debianie](https://packages.debian.org/stable/neovim)
- [Laravel optimize i optimize:clear](https://laravel.com/framework/docs/11.x/deployment)
