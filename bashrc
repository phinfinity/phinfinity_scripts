#
# ~/.bashrc
#
# This is the bashrc that I regularly use on my system

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
source /etc/profile
source /etc/bash.bashrc
if [ -f /usr/etc/profile.d/autojump.bash ]
then
	.  /usr/etc/profile.d/autojump.bash
fi

alias less='less -Ri' # for colorfull less and case insensitive search
alias ls='ls --color=auto' # Keep warn , done for color on less
alias grep='grep --color=auto' # same warn as above
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
export PYTHONSTARTUP="$HOME/.pyrc"
alias cd..="cd .."
alias sl=ls
alias LS=ls
alias SL=ls
alias sL=ls
alias Sl=ls
alias lS=ls
alias Ls=ls
export EDITOR=vim
#Useful Calculator command
? () { echo "$*" | bc -l; }
c () { echo "$*" | bc -l; }
export PATH="/usr/lib/colorgcc/bin:"$PATH
mkdircd () { mkdir "$*" ; cd "$*"; }
export HISTSIZE="" # http://superuser.com/questions/479726/how-to-get-infinite-command-history-in-bash
#export HISTFILESIZE=10000000
export HISTCONTROL=ignoredups:ignorespace
export HISTIGNORE="rm *"
export HISTTIMEFORMAT="%d %b %y %T "
shortls () { ls --color=always -tCF1 |head -30 | tr '\t\n' '  '; echo;}
lcd() { cd $*; if [ "$?" == "0" ]; then shortls; fi; }
PS1='\[\e[0;32m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] \[\e[1;37m\]'
complete -cf sudo
#enable Extended globbing for example:  rm !(except_file)
shopt -s extglob
alias g++='g++ -Wall -Wextra'
alias gcc='gcc -Wall -Wextra'
alias xo='xdg-open'
alias xclip='xclip -selection c'
alias recordscreen='/home/phinfinity/repos/recordscreen/recordscreen.py'
alias v='vim -R' # for readonly viewing
export MAKEFLAGS="-j 5"
lsh() {
	if [[ $# == '0' ]]
	then
		du -csh ./* | sort -h
	else
		du -csh $* | sort -h
	fi
}
lsd() {
	dlist=$(find -maxdepth 1 -type d)
	IFSSAVE=$IFS
	IFS=$'\n'
	for i in $dlist
	do
		fcount=$(find $i | wc -l)
		echo -e $fcount"\t"$i
	done | sort -n
	IFS=$IFSSAVE
}
s() {
	retv=$?
	pcomm=$(history  2 | head -1 | cut -d' ' -f 4-)
	if [[ $retv == "0" ]]
	then
		notify-send "$pcomm Has Completed Successfully"
	else
		notify-send -i "/usr/share/icons/gnome/256x256/status/dialog-warning.png" "$pcomm Has Failed!!"
	fi
}
#alias file="file -m $HOME/mymagic"
alias memsort="ps -A --sort -rss -o pid,comm,pmem,rss | less"
# geoip
#function geoip_curl_xml { curl -D - http://freegeoip.net/xml/$1; }
#alias geoip=geoip_curl_xml
genrand(){ dd if=/dev/urandom bs=8 count=1 2>/dev/null | base64  | tr '/\==+' 'zancd' | head -c 9; }
lsp(){ 
	# Warning canonicalizes links
	MYPATH=$(readlink -f $1)
	echo -n $MYPATH | xclip
	echo $MYPATH
}
pvmeasure() {
	if [[ $# -ne '1' ]]
	then
		echo "Usage: pvmeasure file_name"
	elif [[ -r $1 && -f $1 ]]
	then
		PIPE=$(mktemp -u)
		mkfifo $PIPE
		echo "Use : $PIPE"
		pv $1 > $PIPE
		rm $PIPE
	else
		echo "Cannot Read $1" 
	fi
}
gp() {
	git pull && git push
}
alias gm="git commit -a"
alias gd="git diff"
loc() {
	egrep -v 'import|package|^\s*\}\s*$|^\s*$|^\s*//.*$|^\s*[/]*\*.*$' $* | wc -l
}
