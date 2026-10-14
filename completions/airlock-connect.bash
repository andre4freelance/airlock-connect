# Bash completion for airlock-connect

_airlock_connect_complete() {
    local cur prev prefix entries
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    prefix="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

    if [[ ! -d "$prefix" ]]; then
        return 0
    fi

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "-h --help -v --version -l --list ls" -- "$cur") )
        return 0
    fi

    # Read all .gpg files relative to password store
    entries=$(find "$prefix" -type f -name "*.gpg" ! -path "*/.*" 2>/dev/null | sed -e "s|^$prefix/||" -e 's|\.gpg$||')
    COMPREPLY=( $(compgen -W "$entries" -- "$cur") )
}

complete -F _airlock_connect_complete airlock-connect
complete -F _airlock_connect_complete connect
