#!/usr/bin/env zsh

SNIPPETS_PATH=${SNIPPETS_PATH:-"$HOME/.config/literate-zsh-fzf-snippets/snippets"}
PATH=$SNIPPETS_PATH:$PATH
chmod -R +x $SNIPPETS_PATH/*
FZF_SNIPPETS_BINDKEY=${FZF_SNIPPETS_BINDKEY:-'^[^['}


_tru_fzf-snippet() {

    unsetopt shwordsplit
    # merge filename and tags into single line
    results=$(for FILE in $SNIPPETS_PATH/*
              do
                  getname=$(basename $FILE)
                  gettags=$(head -n 2 $FILE | tail -1)
                  echo "$gettags ,| $getname"
              done)

    preview=`echo $results | column -s ',' -t | fzf -p 90% -i --ansi --bind ctrl-/:toggle-preview "$@" --preview-window up:wrap --preview "echo {} | cut -f2 -d'|' | tr -d ' ' | xargs -I % bat --color=always --language bash --plain $SNIPPETS_PATH/%" --expect=alt-enter`

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
        ,*)
            if [[ $(cat $SNIPPETS_PATH/$filename | sed 1,2d | wc -l | bc) -lt 8 ]]; then
            #if [[ $(cat $SNIPPETS_PATH/$filename | sed 1,2d | wc -l | bc) < 8 ]]; then
                BUFFER=" $(cat $SNIPPETS_PATH/$filename | sed 1,2d)"
            else
                chmod +x $SNIPPETS_PATH/$filename
                BUFFER=" . $filename"
            fi
            ;;
    esac
}
zle -N _tru_fzf-snippet
bindkey $FZF_SNIPPETS_BINDKEY _tru_fzf-snippet
