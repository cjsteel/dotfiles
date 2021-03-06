source $HOME/.common.sh

################################
# G L O B A L  S E T T I N G S #
################################

fpath=($HOME/.zsh_completions $fpath)

setopt ALWAYS_LAST_PROMPT ALWAYS_TO_END APPEND_HISTORY AUTO_CD AUTO_LIST \
    AUTO_MENU AUTO_NAME_DIRS AUTO_PARAM_SLASH AUTO_RESUME BANG_HIST \
    NO_CHECK_JOBS NO_HUP CLOBBER CORRECT CORRECT_ALL PRINTEXITVALUE \
    EXTENDED_HISTORY FUNCTION_ARGZERO GLOB HIST_IGNORE_DUPS \
    COMPLETE_IN_WORD HIST_REDUCE_BLANKS MAIL_WARNING POSIX_BUILTINS \
    PRINT_EIGHT_BIT NO_BEEP EXTENDEDGLOB SH_WORD_SPLIT

unsetopt CHASE_DOTS CHASE_LINKS BG_NICE IGNORE_BRACES PROMPT_CR NOMATCH

SAVEHIST=20000
HISTSIZE=20000
HISTFILE=~/.zsh_history
WATCH=notme
WATCHFMT="%n has %a tty%l from %M at %D %T"

#######################
# C O M P L E T I O N #
#######################
autoload multicomp mtoolsmatch insmodcomp
autoload -U compinit
autoload -Uz vcs_info
compinit

# Tab completion from both ends.
setopt completeinword

# Tab completion should be case-insensitive.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Better completion for killall.
zstyle ':completion:*:killall:*' command 'ps -u $USER -o cmd'

##########################
# K E Y  B I N D I N G S #
##########################

set -o vi  # First, set vi line editing mode.

# Set up emacs-style key bindings too.
bindkey ' '      magic-space
bindkey '^A'     beginning-of-line
bindkey '^E'     end-of-line
bindkey '^D'     logout
bindkey '^L'     clear-screen
bindkey '^J'     self-insert  # LF
bindkey '^U'     kill-whole-line
bindkey '^W'     vi-backward-kill-word
bindkey '^f'     vi-forward-word
bindkey '^b'     vi-backward-word
bindkey '^x'     kill-word
bindkey '^R'     history-incremental-search-backward
bindkey '^S'     history-incremental-search-forward
bindkey '^P'     history-beginning-search-backward
bindkey '^N'     history-beginning-search-forward


history-fuzzy-search() {
    emulate -L zsh
    setopt extendedglob

    autoload -Uz read-from-minibuffer
    zmodload -i zsh/parameter

    local char line words first word
    integer index
    typeset -a lines
    typeset -A lines_hash

    while true; do
        # Show match if any.
        if [[ -n $line ]]; then
            BUFFER=$line
        else
            zle kill-buffer
        fi

        # Read one character.
        zle -R "fuzzy: $last_pattern"

        read -k char

        if (( #char == ##\r )); then
            unset last_pattern
            if [[ -z $line ]]; then
                zle -R ''
                BUFFER=$last_pattern
                return 0
            else
                zle -R ''
                BUFFER=$line
                zle accept-line
                return 0
            fi
        elif (( #char == ##\C-u )); then
            unset last_pattern
        elif (( #char == ##\C-y )); then
            if [[ ${#lines} -gt $index ]]; then
                index=$((index+1))
                line=${lines[$index]}
            fi
        elif (( #char < 32 )); then
            unset last_pattern
            zle -R ''
            BUFFER=$line
            return 0
        else
            index=1
            if (( #char == ##\b || #char == 127 )); then
                last_pattern="${last_pattern%?}"
            else
                last_pattern=$last_pattern$char
            fi
            words=("${(s/ /)last_pattern}")
            first=${words[1]}
            lines_hash=(${(kv)history[(R)*$first*]})
            if [[ ${#words} -gt 1 ]]; then
                for i in {2..${#words}}; do
                    word=${words[$i]}
                    lines_hash=(${(kv)lines_hash[(R)*$word*]})
                done
            fi
            lines=(${(vou)lines_hash})
            line=${lines[$index]}
        fi
    done
}

zle -N history-fuzzy-search
bindkey '^y' history-fuzzy-search

###############
# P R O M P T #
###############

setopt prompt_subst
zstyle ':vcs_info:*' actionformats '[%B%b:%F{1}%a%f%%b]'
zstyle ':vcs_info:*' formats '[%F{3}%b%f]'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b:%F{3}%r%f'
zstyle ':vcs_info:*' enable git cvs svn

# or use pre_cmd, see man zshcontrib
autoload -U is-at-least
vcs_info_wrapper() {
    if is-at-least 4.3.7; then
        vcs_info
        if [ -n "$vcs_info_msg_0_" ]; then
            echo "${vcs_info_msg_0_}"
        fi
    fi
}

PROMPT='[%B%n%b@%B%m%b]%18<..<%~%<<$(vcs_info_wrapper)%# '
