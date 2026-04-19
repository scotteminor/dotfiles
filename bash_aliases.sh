#!/bin/bash

USER_BASH_ALIASES='./.bash_aliases'

cat <<EOT >$USER_BASH_ALIASES

echo " .. loading .bash_aliases .."

# -- Added from https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html
alias='rm -I --preserve-root'           # -- this should be added to /etc/bashrc file


alias ..='cd ..'
alias ...='cd ../..'

alias ping='ping -c5'

alias mkdir='mkdir -pv'

alias la='l -A'
alias ls='ls -la --color=auto'

alias grep='grep --color=auto'

alias h='history'
alias hc='history -c'
alias c='clear'

# -- Added from https://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html
alias mount='mount |column -t'
alias path='echo -e \${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%m.%d.%Y'

#alias ps='ps aux'
alias sudoi='sudo -iu svc_ipapps'

alias tcpdump='sudo tcpdump -nnn'
alias vi='vim '

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec \$SHELL -l"

# -- Added from  https://github.com/learnbyexample/scripting_course/blob/master/.bash_aliases
# simple case-insensitive file search based on name
# remove '-type f' if you want to match directories as well
fs() {
    find -type f -iname '*'"\$@"'*' ;
}

killport() {
  local name="killport"
  if [[ "$1" == "-h" ]]; then
    # shellcheck disable=SC2154
    echo "usage: ${name} <port>"
    echo "  Kills the process using the specified port, e.g:"
    echo "  ${name} 8080"
    return 0
  fi

  # Check if port number was provided
  if [[ -z "$1" ]]; then
    echo "error: no port specified"
    echo "usage: ${name} <port>"
    return 1
  fi

  local port="$1"

  # Find the process using the port
  local pid=$(lsof -ti :"${port}")

  if [[ -z "$pid" ]]; then
    echo "no process found using port ${port}"
    return 1
  fi

  # Get process info before killing it
  local process_info=$(ps -p "${pid}" -o comm | tail -n 1)

  # Kill the process, update the user.
  if kill "${pid}"; then
    echo -e "killed process using port \e[1;37m${port}\e[0m: \e[1;32m${process_info}\e[0m"
  else
    echo "failed to kill process ${pid} using port ${port}"
    return 1
  fi
}

# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

EOT

#
# -- version specific alias

add_alias() {
    # -- Add the alias to the end of the file before the formatting line
    echo "1: $1"
    #echo "user bash aliases: $USER_BASH_ALIASES"
    if [[ ! -z $1 ]]; then
        # -- parse the alias being passed.  Look for '='
        echo -e " Parsing for alias"
        ALIAS_TO_ADD=$(echo "$1" | awk -F'=' '{ print $1 }' | awk '{ print $2 }')
        echo -e "ALIAS_TO_ADD: $ALIAS_TO_ADD"
        if [[ ! -z $ALIAS_TO_ADD ]]; then
            grep "$ALIAS_TO_ADD=" $USER_BASH_ALIASES
            if [[ $? -ne 1 ]]; then
                echo "commenting current alias"
                # -- comment out the current alias
                echo -e -"Step 1"
                sed -i '/#\?$ALIAS_TO_ADD=/{x;/^$/!d;g;}' $USER_BASH_ALIASES
                echo -e "Step 2"
                sed -i '/$ALIAS_TO_ADD=/s/^/#/' $USER_BASH_ALIASES
                # -- Add new alias
                #sed -i "#$ALIAS_TO_ADD=/a\$1" $USER_BASH_ALIASES
                echo -e "Step 3"
                sed -i '/# vim: /i'"$1" $USER_BASH_ALIASES
            else
                echo -e "Adding to alias file"
                sed -i '/# vim: /i'"$1" $USER_BASH_ALIASES
            fi
        else
            # -- Alias doesn't exist.  Add to the bottom of file before '# vim: '
            sed -i '/# vim: /i'"$1" $USER_BASH_ALIASES
        fi

    else
        echo -e "\n\n Nothing was passed to add to alias file \n\n"
    fi
}

#
add_rhel7_alias() {
    if [[ -f /usr/bin/netstat ]]; then
        echo "adding netstats alias"
        add_alias "alias ports='echo \"netstat -tulanp\" && sudo netstat -tulanp'"
    fi

    # -- RHEL v7
    if [[ -f /usr/bin/screen ]]; then
        # Quickly resume a screen session or start one
        echo "adding screen alias"
        add_alias "alias dr='screen -dr || screen'"
    fi

}

#
add_rhel8_alias() {
    # -- RHEL v8
    if [[ -f /usr/sbin/ss ]]; then
        echo "Adding ss alias"
        add_alias "alias ports='echo \"ss -tulanp\" && sudo ss -tulanp'"
    fi

    # -- RHEL v8
    if [[ -f /usr/bin/tmux ]]; then
        # add color to tmux
        #alias tmux="TERM=screen-256color-bce tmux"
        #echo "Adding tmux alias"
        echo -e "Addiing tmux alias"
        add_alias "alias dr='tmux attach -t 0 || tmux'"
    fi
}

#
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
elif [[ -f /etc/lib/os-release ]]; then
    . /etc/lib/os-release
fi

# -- read the ID value from the os-release file
case "$ID" in
'rhel')
    # -- read $VERSION_ID to get the version
    MAJOR_VERSION=$(echo $VERSION_ID | awk -F. '{ print $1 }')
    case $MAJOR_VERSION in
    7)
        # -- RHEL v7
        echo "rhel7"
        add_rhel7_alias
        ;;

    8)
        echo "rhel8"
        add_rhel8_alias

        ;;
    *)
        echo "Unknown $MAJOR_VERSION"
        ;;
    esac
    ;;

*)
    echo 'Unknown'
    ;;
esac
