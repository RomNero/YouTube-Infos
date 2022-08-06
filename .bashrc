if [[ $- != *i* ]] ; then
    # Shell is non-interactive.  Be done now!
    return
fi

shopt -s checkwinsize
shopt -s histappend
echo $LANG

export HISTTIMEFORMAT="%h/%d - %H:%M:%S "
export HISTSIZE=100000
export PS1="\[\u@$(hostname -f): \w\]\$ "
case ${TERM} in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
    ;;
  screen)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
    ;;
esac

use_color=true
safe_term=${TERM//[^[:alnum:]]/?}
match_lhs=""

[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
    && type -P dircolors >/dev/null \
    && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
    # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
    if type -P dircolors >/dev/null ; then
        if [[ -f ~/.dir_colors ]] ; then
            eval $(dircolors -b ~/.dir_colors)
        elif [[ -f /etc/DIR_COLORS ]] ; then
            eval $(dircolors -b /etc/DIR_COLORS)
        fi
    fi

    if [[ ${EUID} == 0 ]] ; then
        ## default prompt
        PS1='\[\033[01;31m\]\u\[\033[01;32m\]@$(hostname -f) \w \$\[\033[00m\] '
    else
        PS1='\[\033[01;32m\]\u\[\033[01;32m\]@$(hostname -f) \w \$\[\033[00m\] '
    fi

				## With Git Branch
#        PS1="\[\033[01;31m\]\u\[\033[01;32m\]@$(hostname -f) \w \$\[\033[00m\] \[\033[38;5;11m\](\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)) \[\033[01;32m\]\$\[\033[00m\] "
#    else
#        PS1="\[\033[01;32m\]\u\[\033[01;32m\]@$(hostname -f) \w \$\[\033[00m\] \[\033[38;5;11m\](\$(git branch 2>/dev/null | grep '^*' | colrm 1 2)) \[\033[01;32m\]\$\[\033[00m\] "
#    fi


    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias grep='grep --colour=auto'
    alias ll='ls --color=auto -la'
    alias l='ls --color=auto -lA'
else
    if [[ ${EUID} == 0 ]] ; then
        # show root@ when we do not have colors
        PS1='\[\u@$(hostname -f): \w\]\$ '
    else
        PS1='\[\u@$(hostname -f): \w\]\$ '
    fi
fi

PS2='> '
PS3='> '
PS4='+ '

unset use_color safe_term match_lhs

# Ubuntu/Debian
[ -r /etc/bash_completion ] && . /etc/bash_completion

# RedHat
#[ -r /etc/profile.d/bash_completion.sh ] && . /etc/profile.d/bash_completion.sh
