# Własne nazwy bez zmiany zachowania rm, cp, mv czy innych standardowych komend.
alias ll='ls -alh'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias dfh='df -h'
alias duh='du -h --max-depth=1'
alias freeh='free -h'
alias crd='composer run dev'
alias llog='less "storage/logs/laravel-$(date +%F).log"'
alias ltail='tail -f "storage/logs/laravel-$(date +%F).log"'
alias casa='cd /etc/apache2/sites-available'
alias cnsa='cd /etc/nginx/sites-available'

# Node / npm / Nuxt — uruchamiaj z katalogu projektu.
alias nci='npm ci'
alias ncib='npm ci --include=dev'
alias nb='npm run build'
alias ngen='npm run generate'
alias nr='npm run'
alias nls='npm ls --depth=0'

if command -v ss >/dev/null 2>&1; then
    alias ports='ss -tuln'
fi

if command -v systemctl >/dev/null 2>&1; then
    alias failed='systemctl --failed --no-pager'
fi
