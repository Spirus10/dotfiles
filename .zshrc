# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#

####################################
### WAMMU WORLD ####################
####################################

source ~/.aliases

reboot_to_windows()
{
	windows_title=$(grep -i windows /boot/grub/grub.cfg | cut -d "'" -f 2)
	sudo grub-reboot "$windows_title" && sudo reboot
}
alias reboot-to-windows='reboot_to_windows'

export PATH="$HOME/.local/bin:$PATH"

krabby random

export EDITOR=nvim

# =============================================================================
# LAVENDER ZSH CONFIGURATION
# Complete setup to match lavender.nvim colorscheme in terminal
# =============================================================================

# -----------------------------------------------------------------------------
# LS_COLORS - File and directory colors (matching lavender palette)
# -----------------------------------------------------------------------------
export LS_COLORS="rs=0:di=1;35:ln=1;36:mh=00:pi=1;33:so=1;32:do=1;35:bd=1;34:cd=1;34:or=1;31:mi=1;31:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=1;32:*.tar=1;31:*.tgz=1;31:*.arc=1;31:*.arj=1;31:*.taz=1;31:*.lha=1;31:*.lz4=1;31:*.lzh=1;31:*.lzma=1;31:*.tlz=1;31:*.txz=1;31:*.tzo=1;31:*.t7z=1;31:*.zip=1;31:*.z=1;31:*.dz=1;31:*.gz=1;31:*.lrz=1;31:*.lz=1;31:*.lzo=1;31:*.xz=1;31:*.zst=1;31:*.tzst=1;31:*.bz2=1;31:*.bz=1;31:*.tbz=1;31:*.tbz2=1;31:*.tz=1;31:*.deb=1;31:*.rpm=1;31:*.jar=1;31:*.war=1;31:*.ear=1;31:*.sar=1;31:*.rar=1;31:*.alz=1;31:*.ace=1;31:*.zoo=1;31:*.cpio=1;31:*.7z=1;31:*.rz=1;31:*.cab=1;31:*.wim=1;31:*.swm=1;31:*.dwm=1;31:*.esd=1;31:*.jpg=1;35:*.jpeg=1;35:*.mjpg=1;35:*.mjpeg=1;35:*.gif=1;35:*.bmp=1;35:*.pbm=1;35:*.pgm=1;35:*.ppm=1;35:*.tga=1;35:*.xbm=1;35:*.xpm=1;35:*.tif=1;35:*.tiff=1;35:*.png=1;35:*.svg=1;35:*.svgz=1;35:*.mng=1;35:*.pcx=1;35:*.mov=1;35:*.mpg=1;35:*.mpeg=1;35:*.m2v=1;35:*.mkv=1;35:*.webm=1;35:*.webp=1;35:*.ogm=1;35:*.mp4=1;35:*.m4v=1;35:*.mp4v=1;35:*.vob=1;35:*.qt=1;35:*.nuv=1;35:*.wmv=1;35:*.asf=1;35:*.rm=1;35:*.rmvb=1;35:*.flc=1;35:*.avi=1;35:*.fli=1;35:*.flv=1;35:*.gl=1;35:*.dl=1;35:*.xcf=1;35:*.xwd=1;35:*.yuv=1;35:*.cgm=1;35:*.emf=1;35:*.ogv=1;35:*.ogx=1;35:*.aac=1;36:*.au=1;36:*.flac=1;36:*.m4a=1;36:*.mid=1;36:*.midi=1;36:*.mka=1;36:*.mp3=1;36:*.mpc=1;36:*.ogg=1;36:*.ra=1;36:*.wav=1;36:*.oga=1;36:*.opus=1;36:*.spx=1;36:*.xspf=1;36:*.pdf=1;33:*.ps=1;33:*.txt=0;37:*.patch=0;37:*.diff=0;37:*.log=0;37:*.tex=1;33:*.doc=1;33:*.docx=1;33:*.ppt=1;33:*.pptx=1;33:*.xls=1;33:*.xlsx=1;33:"

# -----------------------------------------------------------------------------
# ZSH SYNTAX HIGHLIGHTING STYLES (requires zsh-syntax-highlighting plugin)
# -----------------------------------------------------------------------------
# Commands and executables - green tones
ZSH_HIGHLIGHT_STYLES[command]='fg=2,bold'                      # #2df4c0 - bright green
ZSH_HIGHLIGHT_STYLES[builtin]='fg=10'                          # #59d6b5 - softer green
ZSH_HIGHLIGHT_STYLES[function]='fg=2'                          # #2df4c0 - bright green
ZSH_HIGHLIGHT_STYLES[alias]='fg=10,bold'                       # #59d6b5 - softer green, bold
ZSH_HIGHLIGHT_STYLES[precommand]='fg=14,bold'                  # #80cbc4 - cyan

# Paths and directories - purple tones
ZSH_HIGHLIGHT_STYLES[path]='fg=5'                              # #b4a4f4 - lavender purple
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=13'                      # #b994f1 - bright purple
ZSH_HIGHLIGHT_STYLES[path_approx]='fg=5,underline'             # #b4a4f4 - underlined

# Strings and quotes - yellow/amber
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=3'            # #ffc777 - amber
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'            # #ffc777 - amber
ZSH_HIGHLIGHT_STYLES[string]='fg=3'                            # #ffc777 - amber
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=11'             # #add8e6 - light blue

# Keywords and reserved words - bright purple
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=13,bold'               # #b994f1 - bright purple
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=13'                     # #b994f1 - bright purple
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=13'                     # #b994f1 - bright purple

# Comments and documentation - muted gray
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'                           # #515772 - gray
ZSH_HIGHLIGHT_STYLES[line-comment]='fg=8'                      # #515772 - gray

# Numbers and arithmetic - light blue
ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]='fg=12'             # #7486d6 - blue
ZSH_HIGHLIGHT_STYLES[numeric-literal]='fg=12'                  # #7486d6 - blue

# Variables and parameters - light tones
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=15'           # #eeffff - white
ZSH_HIGHLIGHT_STYLES[parameter-expansion]='fg=7'               # #d6e7f0 - light gray
ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=7'              # #d6e7f0 - light gray
ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=7'              # #d6e7f0 - light gray

# Errors and warnings - red tones
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'                # #ff5370 - red
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=9'                  # #ff757f - light red
ZSH_HIGHLIGHT_STYLES[redirection]='fg=9'                       # #ff757f - light red

# Brackets and delimiters - cyan tones
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=6,bold'              # #04d1f9 - cyan
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=14,bold'             # #80cbc4 - light cyan
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=6,bold'              # #04d1f9 - cyan
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=14,bold'             # #80cbc4 - light cyan
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg=15,bold,underline'  # #eeffff - white

# History and completion
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=12,bold'           # #7486d6 - blue

# -----------------------------------------------------------------------------
# COMPLETION COLORS
# -----------------------------------------------------------------------------
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '%F{13}%B%d%b%f'    # Purple descriptions
zstyle ':completion:*:messages' format '%F{3}%d%f'             # Yellow messages
zstyle ':completion:*:warnings' format '%F{1}No matches found%f'  # Red warnings
zstyle ':completion:*:corrections' format '%F{9}%d (errors: %e)%f'  # Light red corrections

# Group completions
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands

# Menu selection colors
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# -----------------------------------------------------------------------------
# CUSTOM PROMPT (Simple but themed)
# -----------------------------------------------------------------------------
# You can uncomment this for a simple lavender-themed prompt
# autoload -U colors && colors
# PROMPT='%F{13}❯%f %F{5}%~%f %F{2}%#%f '
# RPROMPT='%F{8}%T%f'

# -----------------------------------------------------------------------------
# GREP COLORS
# -----------------------------------------------------------------------------
export GREP_COLORS="ms=1;31:mc=1;31:sl=:cx=:fn=1;35:ln=1;33:bn=1;33:se=1;36"

# -----------------------------------------------------------------------------
# LESS COLORS (for man pages, etc.)
# -----------------------------------------------------------------------------
export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;35m'     # begin bold (purple)
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\e[1;44;33m'  # begin reverse video
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\e[1;36m'     # begin underline (cyan)
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline

# -----------------------------------------------------------------------------
# ADDITIONAL TOOL COLORS
# -----------------------------------------------------------------------------
# fd colors (if using fd instead of find)
export FD_COLORS="di=1;35:ln=1;36:so=1;32:ex=1;32:fi=0;37"

# bat theme (if using bat instead of cat)
export BAT_THEME="ansi"

# -----------------------------------------------------------------------------
# PLUGIN RECOMMENDATIONS
# -----------------------------------------------------------------------------
# Add these to your plugins array in .zshrc if using oh-my-zsh:
# plugins=(
#   git
#   zsh-syntax-highlighting
#   zsh-autosuggestions
#   colored-man-pages
# )

# For autosuggestions color (if using zsh-autosuggestions):
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"

# -----------------------------------------------------------------------------
# INSTALLATION NOTES
# -----------------------------------------------------------------------------
# 1. Make sure you have zsh-syntax-highlighting installed
# 2. Source this file in your .zshrc: source path/to/this/file
# 3. Restart your terminal or run: source ~/.zshrc
# 4. For best results, use with the lavender Ghostty colorscheme

[ -f "/home/wammu/.ghcup/env" ] && . "/home/wammu/.ghcup/env" # ghcup-env

# opencode
export PATH=/home/wammu/.opencode/bin:$PATH
