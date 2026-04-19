#!/bin/bash

# -- add the following to .bashrc at the top
[[ $- == *i* ]] || return

if [ ! -f ~/.ansi_color ]; then
	import ansi_color
fi
########

if [[ ! -f ~/.bash_aliases ]]; then
	echo " .. creating .bash_aliases .."
	import bash_aliases.sh
else
	echo " .. .bash_aliases already exists .."
fi

# --- Add to the top of .bashrc
# -- if not running interactively, don't do anything
#[[ $- == *i* ]] || return

cat <<EOT >>~/.bashrc

#printf " .. loading .bashrc ...\n"

if [ -f ~/.ansi_color ]; then

    source \$HOME/.ansi_color
    PS1="\n\$White[\$Yellow\w\$White]\n[\$BBlue\u\$BWhite@\$Purple\h\$White]\$BWhite \$ \$Color_off"
else
    #PS1="\n\[\033[0;37m\][\[\033[0;33m\]\w\[\033[0;37m\]]\n\[\033[1;37m\][\[\033[1;34m\]\u\[\033[1;37m\]@\[\033[0;35m\]\h\[\033[1;37m\]]\[\033[1;37m\] \$ \[\033[0m\]"
    PS1="\n[\w]\n[\u@\h] \$ "
fi


#PROMPT_COMMAND='history -a;history -c;history -r'


# used for RCS
#export LOGNAME="\$SUDO_USER"

EOT

#grep '~/.bash_aliases' ~/.bashrc
#EXIT_CODE=$?

## -- If not found in .bashrc
#if [ $EXIT_CODE -ne 0 ]; then

#cat <<EOT >> ~/.profile

#echo "loading .profile"
#if [ -f ~/.bash_aliases ]; then
#        . ~/.bash_aliases
#fi
#
#if [ -f ~/.bash_inputs ]; then
#        . ~/.bash_inputs
#fi

## vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

#EOT
#else

cat <<EOT >>~/.bash_profile

printf " .. loading .bash_profile ...\n"

if [ -f ~/.bash_inputs ]; then
        . ~/.bash_inputs
fi

if [ -f ~/.bash_aliases ]; then
        . ~/.bash_aliases
fi

# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

EOT

#fi

cat <<EOT >~/.bash_inputs

printf " .. loading .bash_inputs ...\n"

# Make vim the default editor.
export EDITOR='vim';

# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768';
export HISTFILESIZE="\${HISTSIZE}";

# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth:erasedups';

# Omit the following from history
export HISTIGNORE="history:h:exit:logoff"

# Append commands
shopt -s histappend

# Store multiline commands in one line
shopt -s cmdhist


# Prefer US English and use UTF-8.
export LANG='en_US.UTF-8';
#export LC_ALL='en_US.UTF-8';

# Highlight section titles in manual pages.
export LESS_TERMCAP_md="\${Yellow}";

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X';

# Always enable colored grep output.
# -- This has been deprecated
#export GREP_OPTIONS='--color=auto';

###########
# -- https://github.com/learnbyexample/scripting_course/blob/master/.inputrc
# when using Tab for completion, ignore case
set completion-ignore-case on

# single Tab press will complete if unique, display multiple completions otherwise
set show-all-if-ambiguous on

# don't display characters like Ctrl+c when used on readline
set echo-control-characters off

########

# Allow UTF-8 input and output, instead of showing stuff like $'\0123\0456'
set input-meta on
set output-meta on
set convert-meta off
set bell-style off

# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:
EOT

# -- Load the aliias and then reload the shell enviornment
#source .bashrc
source ~/.bash_aliases
reload

##############  ROOT CHANGES ####################

# -- /home/root/.bashrc

cat <<EOT >>~/.bashrc

case \$SUDO_USER in

  'u717312' | 'sminor')
    #PS1="\n\[\033[0;37m\][\[\033[0;33m\]\w\[\033[0;37m\]]\n\[\033[1;37m\][\[\033[1;31m\]\u\[\033[1;37m\]@\[\033[0;35m\]\h\[\033[1;37m\]]\[\033[1;37m\] \$: \[\033[0m\]"
	PS1="\n\[\e[38;5;08m\][\[\e[38;5;33m\]\w\[\e[38;5;08m\]]\n[\[\e[38;5;226m\]\u\[\e[38;5;33m\]@\[\e[38;5;105m\]\h\[\e[38;5;08m\]]\[\033[0m\] \$: "
    alias vi='vim '
  ;;

esac

EOT

# -- Add support for color to svc_ipapps/.bashrc
USER_BASHRC=/home/svc_ipapps/.bashrc
cat <<EOT >>$USER_BASHRC

case \$SUDO_USER in

  'u717312' | 'sminor')
    #PS1="\n\[\033[0;37m\][\[\033[0;33m\]\w\[\033[0;37m\]]\n\[\033[1;37m\][\[\033[1;32m\]\u\[\033[1;37m\]@\[\033[0;35m\]\h\[\033[1;37m\]]\[\033[1;37m\] \$: \[\033[0m\]"
	PS1="\n\[\e[38;5;08m\][\[\e[38;5;33m\]\w\[\e[38;5;08m\]]\n[\[\e[38;5;226m\]\u\[\e[38;5;33m\]@\[\e[38;5;105m\]\h\[\e[38;5;08m\]]\[\033[0m\] \$: "
    #alias vi='vim '
    [[ -f ~/.bash_alias_sem ]] && . ~/.bash_alias_sem
  ;;

esac

EOT

chown svc_ipapps: $USER_BASHRC

# -- Add my personal alias's
USER_BASH_ALIAS=/home/svc_ipapps/.bash_alias_sem
cat <<EOT >>$USER_BASH_ALIAS

printf ".. loading personal alias ..\n"

alias ls='ls -a --color=auto'

alias now='date +"%T"'
alias nowdate='date +"%Y-%m-%d"'

EOT

chown svc_ipapps: $USER_BASH_ALIAS
