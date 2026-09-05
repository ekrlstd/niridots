set -l fzf_theme_opts "\
--color=bg+:#534438
--color=bg:#19120d
--color=spinner:#eee0d7
--color=hl:#ffb4ab
--color=fg:#eee0d7
--color=header:#ffb4ab
--color=info:#ffb77b
--color=pointer:#eee0d7
--color=marker:#d8c2b3
--color=fg+:#eee0d7
--color=prompt:#ffb77b
--color=hl+:#ffb4ab
--color=selected-bg:#534438
--color=border:#534438
--color=label:#eee0d7"

if set -q FZF_DEFAULT_OPTS[1]; and test -n "$FZF_DEFAULT_OPTS"
    set -Ux FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS
$fzf_theme_opts"
else
    set -Ux FZF_DEFAULT_OPTS "$fzf_theme_opts"
end
