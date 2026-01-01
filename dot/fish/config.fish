## Source from conf.d before our fish config
source /usr/share/cachyos-fish-config/conf.d/done.fish

# vim
set VISUAL "vim"
set EDITOR "vim"

# emacs
fish_add_path ~/.config/emacs/bin

# go
fish_add_path ~/Documents/git/go/bin
fish_add_path /usr/lib/go/bin
export GOPATH="$HOME/Documents/git/go"

# fzf
fzf --fish | source

# fzf options
export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target,.cache,cache,icons,.icons
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target,.cache,cache,icons,.icons
  --preview 'eza --color=always --icons --tree -- {}'"

# necessary-verbs
alias necessary-verbs="sudo ~/.local/bin/necessary-verbs"

# gocryptfs
set CLCLM "/tmp/clanculum"
alias incog="mkdir -p $CLCLM > /dev/null && gocryptfs ~/.local/vault $CLCLM && cd $CLCLM"
alias outcog="fusermount -u $CLCLM"

## Set values
## Run fastfetch as welcome message
function fish_greeting
    fastfetch
end

# Format man pages
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
  source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end


## Functions

# Vi Mode
function fish_user_key_bindings
  fish_vi_key_bindings
  bind -M insert -m default jk backward-char force-repaint
  bind -M insert \cH backward-kill-word
  bind -M insert \e\[3\;5~ kill-word
end

# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Useful aliases
# Replace ls with eza
alias l='eza -l --color=always --group-directories-first --icons' # preferred listing
alias la='eza -al --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -al --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles

# Safeguards
alias cp="cp -riv"
alias mv="mv -iv"
alias rm="rm -iv"
alias mkdir="mkdir -pv"

# Defaults
alias rsync="rsync -urvP"

# Common use
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias hw='hwinfo --short'                                   # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl"              # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'          # List amount of -git packages
# alias update='sudo pacman -Syu'

# Get fastest mirrors
alias mirror="sudo cachyos-rate-mirrors"

# Help people new to Arch
alias apt='man pacman'
alias apt-get='man pacman'
alias please='sudo'
alias tb='nc termbin.com 9999'

# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

alias cls='echo "" > "$HOME/.local/share/fish/fish_history"'

# abbreviations
abbr -a 'upd' 'sudo pacman -Syyu && yay -Syyu && doom upgrade && flatpak update'

abbr -a 'video' 'yt-dlp -f "bestvideo[height<=360][vcodec^=avc1]+bestaudio[ext=m4a]/best[height<=360]" \
       -S "height:360,+size,+vbr:800,+abr:96" \
       --merge-output-format mp4\
       --embed-metadata --embed-thumbnail \
       --write-auto-subs --sub-langs "en" \
       --restrict-filenames --continue \
       --retries 10'

abbr -a 'music' 'yt-dlp -f "bestaudio/best" -x --audio-format flac --embed-thumbnail --embed-metadata --no-write-description --no-write-info-json --no-write-comments'

abbr -a 'ocrmypdf' 'ocrmypdf --output-type pdf --redo-ocr --jbig2-lossy --optimize 2'

# yazi
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp" > /dev/null
end


# zoxide
zoxide init --cmd cd fish | source
