if status is-interactive
    # Suppress the greeting
    set -g fish_greeting ""

    # Smart cd (zoxide)
    if command -v zoxide >/dev/null 2>&1
        zoxide init fish | source
    end

    # Prompt (starship)
    if test "$TERM" != dumb; and command -v starship >/dev/null 2>&1
        starship init fish | source
    end
end
