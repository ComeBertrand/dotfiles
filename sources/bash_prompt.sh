#!/usr/bin/env bash

if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM='gnome-256color';
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM='xterm-256color';
fi;

prompt_git() {
    local s='';
    local branchName='';

    if [ $(git rev-parse --is-inside-work-tree &>/dev/null; echo "${?}") == '0' ]; then
        if [ "$(git rev-parse --is-inside-git-dir 2>/dev/null)" == 'false' ]; then
            git update-index --really-refresh -q &>/dev/null

            if ! $(git diff --quiet --ignore-submodules --cached); then
                s+='+';
            fi;

            if ! $(git diff-files --quiet --ignore-submodules --); then
                s+="!";
            fi;

            if [ -n "$(git ls-files --others --exclude-standard)" ]; then
                s+='?';
            fi;

            if $(git rev-parse --verify refs/stash &>/dev/null); then
                s+='$';
            fi;
        fi;

        branchName="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo '(unknown)')";
        [ -n "${s}" ] && s=" [${s}]";
        echo -e "${1}${branchName}${2}${s}"
    else
        return;
    fi;
}

if tput setaf 1 &> /dev/null; then
    tput sgr0;
    bold=$(tput bold);
    reset=$(tput sgr0);
    black=$(tput setaf 0);
    blue=$(tput setaf 33);
    cyan=$(tput setaf 37);
    green=$(tput setaf 64);
    orange=$(tput setaf 166);
    purple=$(tput setaf 125);
    red=$(tput setaf 124);
    violet=$(tput setaf 61);
    white=$(tput setaf 15);
    yellow=$(tput setaf 136);
else
    bold='';
    reset="\e[0m";
    black="\e[1;30m";
    blue="\e[1;34m";
    cyan="\e[1;36m";
    green="\e[1;32m";
    orange="\e[1;33m";
    purple="\e[1;35m";
    red="\e[1;31m";
    violet="\e[1;35m";
    white="\e[1;37m";
    yellow="\e[1;33m";
fi;

PS1="\[\033]0;\W\007\]";
PS1+="\[${bold}\]\n";
PS1+="\[${orange}\]\u";
PS1+="\[${white}\] at ";
PS1+="\[${yellow}\]\h";
PS1+="\[${white}\] in ";
PS1+="\[${green}\]\w";
PS1+="\$(prompt_git \"\[${white}\] on \[${violet}\]\" \"\[${blue}\]\")";
PS1+="\n";
PS1+="\[${white}\]\$ \[${reset}\]";
export PS1

PS2="\[${yellow}\]> \[${reset}\]";
export PS2
