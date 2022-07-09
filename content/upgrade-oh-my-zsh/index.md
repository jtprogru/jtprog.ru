---
categories: howto
comments: true
date: "2015-09-23T10:21:00+03:00"
draft: false
noauthor: false
share: true
slug: /upgrade-oh-my-zsh/
tags:
- zsh
- oh-my-zsh
- linux
title: '[OhMyZsh] Upgrade OhMyZsh'
type: post
---
Всем пинг! Уже некоторое время я пользуюсь такой прекрасной вещью как командная оболочка [ZSH](https://ru.wikipedia.org/wiki/Zsh) и я вам скажу "ЭТО ПИПЕЦ КАК КРУТО!" Отказаться от стандартной для Ubuntu оболочки Bash меня сподвигла статья [afiskon'а](https://eax.me/zsh/). В большей степени я просто воспользовался его файлом настроек и пока всем доволен. Так же у меня установлена такая вещь как [Oh-My-Zsh](https://github.com/robbyrussell/oh-my-zsh).

Все было прекрасно и радужно до одно момента. Сегодня я решил обновить этот самый `Oh-My-Zsh` и в ответ на команду:
```bash
upgrade_oh_my_zsh
```
Мне вылетело следующее сообщение:

```bash
jtprog@calipso-> upgrade_oh_my_zsh
Upgrading Uh My Zsh
Cannot pull with rebase: You have unstaged changes.
Please commit or stash them.
```

Исправить данную ошибку можно таким вот способом:
```bash
cd ~/.oh-my-zsh/
git add .
git commit -m "commit message"
upgrade_oh_my_zsh
```
Сразу оговорюсь, что в ручную я первый раз попытался сделать обновление. А данная [ошибка](https://github.com/robbyrussell/oh-my-zsh/issues/1991) не нова и висит с 2013 года.

В общем после таких скромных манипуляций вы спокойно сможете обновить Oh-My-Zsh.

На этом все! Profit!

ЗЫЖ Тем, кто заинтересовался работой в данной оболочке советую прочесть прекрасную статью [afiskon'а](http://eax.me/zsh/).

Так же ниже листинг моего файла `~/.zshrc`
```bash
# Path to your oh-my-zsh installation.
export ZSH=/home/jtprog/.oh-my-zsh

# Set name of the theme to load.  
# Look in ~/.oh-my-zsh/themes/  
# Optionally, if you set this to "random", it'll load a random theme each  
# time that oh-my-zsh is loaded.  
ZSH_THEME="apple"

# Uncomment the following line to use case-sensitive completion.  
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case  
# sensitive completion must be off. _ and - will be interchangeable.  
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.  
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).  
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.  
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.  
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.  
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.  
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files  
# under VCS as dirty. This makes repository status check for large repositories  
# much, much faster.  
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time  
# stamp shown in the history command output.  
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"  
HIST_STAMPS="mm.dd.yyyy"

# Would you like to use another custom folder than $ZSH/custom?  
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/)  
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/  
# Example format: plugins=(rails git textmate ruby lighthouse)  
# Add wisely, as too many plugins slow down shell startup.  
plugins=(git ruby adb python ubuntu django virtualenv)

# User configuration

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"  
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment  
export LANG=ru_RU.UTF-8

# Preferred editor for local and remote sessions  
# if [[ -n $SSH_CONNECTION ]]; then  
#   export EDITOR='vim'  
# else  
#   export EDITOR='mvim'  
# fi

# Compilation flags  
export ARCHFLAGS="-arch x86_64"

# ssh  
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,  
# plugins, and themes. Aliases can be placed here, though oh-my-zsh  
# users are encouraged to define aliases within the ZSH_CUSTOM folder.  
# For a full list of active aliases, run `alias`.  
#  
# Example aliases  
# alias zshconfig="mate ~/.zshrc"  
# alias ohmyzsh="mate ~/.oh-my-zsh"

export PROMPT='%n@%m-> '  
export RPROMPT='[%~]'

git_prompt() {  
  temp=`git symbolic-ref HEAD 2>/dev/null | cut -d / -f 3`  
  if [ "$temp" != "" ]; then echo "$temp:"; fi  
}  
setopt prompt_subst  
export RPROMPT='[$(git_prompt)%~]'

setopt menucomplete  
zstyle ':completion:*' menu select=1 _complete _ignored _approximate

setopt correctall

compress () {  
  if [ $1 ] ; then  
    case $1 in  
      tbz)  tar cjvf $2.tar.bz2 $2   ;;  
      tgz)  tar czvf $2.tar.gz  $2   ;;  
      tar)  tar cpvf $2.tar  $2      ;;  
      bz2)  bzip $2                  ;;  
      gz)   gzip -c -9 -n $2 > $2.gz ;;  
      zip)  zip -r $2.zip $2         ;;  
      7z)   7z a $2.7z $2            ;;  
      *)    echo "'$1' cannot be packed via >compress<" ;;  
    esac  
  else  
    echo "'$1' is not a valid file"  
  fi  
}

extract () {  
  if [ -f $1 ] ; then  
    case $1 in  
      *.tar.bz2) tar xvjf $1   ;;  
      *.tar.gz)  tar xvzf $1   ;;
      *.tar.xz)  tar xvfJ $1   ;;  
      *.bz2)     bunzip2 $1    ;;  
      *.rar)     unrar x $1    ;;  
      *.gz)      gunzip $1     ;;  
      *.tar)     tar xvf $1    ;;  
      *.tbz2)    tar xvjf $1   ;;  
      *.tgz)     tar xvzf $1   ;;
      *.zip)     unzip $1      ;;  
      *.Z)       uncompress $1 ;;  
      *.7z)      7z x $1       ;;  
      *)         echo "'$1' cannot be extracted via >extract<" ;;
    esac  
  else
    echo "'$1' is not a valid file"
  fi
}

command_not_found_handler() {
  /usr/lib/command-not-found $1
}
setopt autocdsetopt extendedglobsetopt hist_ignore_all_dupssetopt hist_ignore_space
```
