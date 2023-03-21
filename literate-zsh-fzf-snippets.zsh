#!/usr/bin/env zsh

SNIPPETS_PATH=${SNIPPETS_PATH:-"$HOME/.config/literate-zsh-fzf-snippets/snippets"}
export PATH=$SNIPPETS_PATH:$PATH
chmod -R +x $SNIPPETS_PATH/*
FZF_SNIPPETS_BINDKEYS=${FZF_SNIPPETS_BINDKEYS:-'^[x'}

if [ ! -d "$SNIPPETS_PATH" ]; then
  mkdir -p "$SNIPPETS_PATH"
fi

_tru_fzf-snippet() {
    local results preview key rest filename

    # merge filename and tags into single line
    results=$(find "$SNIPPETS_PATH" -type f -print0 | xargs -0 awk 'FNR==2 {split(FILENAME,a,"/"); print $0 ",| " a[length(a)]}')

    preview=$(echo $results | column -s ',' -t | fzf -p 90% -i --ansi --bind ctrl-/:toggle-preview "$@" --preview-window up:wrap --preview "echo {} | cut -f2 -d'|' | tr -d ' ' | xargs -I % bat --color=always --language bash --plain $SNIPPETS_PATH/%" --expect=alt-enter,enter)

    if [  -z "$preview" ]; then
        return
    fi

    key="$(head -1 <<< "$preview")"
    rest="$(sed 1d <<< "$preview")"
    filename=$(echo $rest | cut -f2 -d'|' | tr -d ' ')

    case "$key" in
        alt-enter)
            BUFFER=" $(cat $SNIPPETS_PATH/$filename | sed 1,2d)"
            ;;
        *)
            if [[ $(cat $SNIPPETS_PATH/$filename | sed 1,2d | wc -l | bc) -lt 8 ]]; then
                BUFFER=" $(cat $SNIPPETS_PATH/$filename | sed 1,2d)"
            else
                chmod +x $SNIPPETS_PATH/$filename
                BUFFER=" . $filename"
            fi
            ;;
    esac
}
zle -N _tru_fzf-snippet

_tru_fzf-snippet_bind_keys() {
    local IFS=' '
    setopt localoptions shwordsplit

    for key in $FZF_SNIPPETS_BINDKEYS; do
        bindkey $key _tru_fzf-snippet
    done
}
_tru_fzf-snippet_bind_keys
