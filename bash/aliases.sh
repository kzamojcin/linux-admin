# Własne nazwy bez zmiany zachowania rm, cp, mv czy innych standardowych komend.
alias ll='ls -alh'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias dfh='df -h'
alias duh='du -h --max-depth=1'
alias freeh='free -h'
alias crd='composer run dev'
alias casa='cd /etc/apache2/sites-available'
alias cnsa='cd /etc/nginx/sites-available'

if command -v ss >/dev/null 2>&1; then
    alias ports='ss -tuln'
fi

if command -v systemctl >/dev/null 2>&1; then
    alias failed='systemctl --failed --no-pager'
fi
