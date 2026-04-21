{ config, lib, pkgs, theme, ... }:

{
  programs.zsh = {
    enable                     = true;
    dotDir                     = config.home.homeDirectory;
    autosuggestion.enable      = true;
    syntaxHighlighting.enable  = true;
    historySubstringSearch.enable = true;

    history = {
      path   = "$HOME/.zsh_history";
      size   = 1000;
      save   = 1000;
    };

    shellAliases = {
      ll   = "ls -la";
      ".." = "cd ..";
      v    = "nvim";
      # Replaces `psyu` from the Arch config. Daily rebuild via `nh`.
      nhu  = "nh os switch .";
    };

    sessionVariables = {
      EDITOR   = "nvim";
      BAT_THEME = "ansi";
      GREP_COLORS = "ms=1;31:mc=1;31:sl=:cx=:fn=1;35:ln=1;33:bn=1;33:se=1;36";
      FD_COLORS   = "di=1;35:ln=1;36:so=1;32:ex=1;32:fi=0;37";
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=8,underline";
    };

    initContent = lib.mkOrder 1000 ''
      # ---- LS_COLORS -------------------------------------------------
      # Kept verbatim from the Arch .zshrc. 160+ filetype associations
      # chosen to match the lavender palette — `di=1;35` lands on
      # bright purple via Ghostty's slot 13.
      export LS_COLORS="rs=0:di=1;35:ln=1;36:mh=00:pi=1;33:so=1;32:do=1;35:bd=1;34:cd=1;34:or=1;31:mi=1;31:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=1;32:*.tar=1;31:*.tgz=1;31:*.arc=1;31:*.arj=1;31:*.taz=1;31:*.lha=1;31:*.lz4=1;31:*.lzh=1;31:*.lzma=1;31:*.tlz=1;31:*.txz=1;31:*.tzo=1;31:*.t7z=1;31:*.zip=1;31:*.z=1;31:*.dz=1;31:*.gz=1;31:*.lrz=1;31:*.lz=1;31:*.lzo=1;31:*.xz=1;31:*.zst=1;31:*.tzst=1;31:*.bz2=1;31:*.bz=1;31:*.tbz=1;31:*.tbz2=1;31:*.tz=1;31:*.deb=1;31:*.rpm=1;31:*.jar=1;31:*.war=1;31:*.ear=1;31:*.sar=1;31:*.rar=1;31:*.alz=1;31:*.ace=1;31:*.zoo=1;31:*.cpio=1;31:*.7z=1;31:*.rz=1;31:*.cab=1;31:*.wim=1;31:*.swm=1;31:*.dwm=1;31:*.esd=1;31:*.jpg=1;35:*.jpeg=1;35:*.mjpg=1;35:*.mjpeg=1;35:*.gif=1;35:*.bmp=1;35:*.pbm=1;35:*.pgm=1;35:*.ppm=1;35:*.tga=1;35:*.xbm=1;35:*.xpm=1;35:*.tif=1;35:*.tiff=1;35:*.png=1;35:*.svg=1;35:*.svgz=1;35:*.mng=1;35:*.pcx=1;35:*.mov=1;35:*.mpg=1;35:*.mpeg=1;35:*.m2v=1;35:*.mkv=1;35:*.webm=1;35:*.webp=1;35:*.ogm=1;35:*.mp4=1;35:*.m4v=1;35:*.mp4v=1;35:*.vob=1;35:*.qt=1;35:*.nuv=1;35:*.wmv=1;35:*.asf=1;35:*.rm=1;35:*.rmvb=1;35:*.flc=1;35:*.avi=1;35:*.fli=1;35:*.flv=1;35:*.gl=1;35:*.dl=1;35:*.xcf=1;35:*.xwd=1;35:*.yuv=1;35:*.cgm=1;35:*.emf=1;35:*.ogv=1;35:*.ogx=1;35:*.aac=1;36:*.au=1;36:*.flac=1;36:*.m4a=1;36:*.mid=1;36:*.midi=1;36:*.mka=1;36:*.mp3=1;36:*.mpc=1;36:*.ogg=1;36:*.ra=1;36:*.wav=1;36:*.oga=1;36:*.opus=1;36:*.spx=1;36:*.xspf=1;36:*.pdf=1;33:*.ps=1;33:*.txt=0;37:*.patch=0;37:*.diff=0;37:*.log=0;37:*.tex=1;33:*.doc=1;33:*.docx=1;33:*.ppt=1;33:*.pptx=1;33:*.xls=1;33:*.xlsx=1;33:"

      # ---- zsh-syntax-highlighting styles ----------------------------
      # Each `fg=N` indexes the 0..15 Ghostty palette from theme.nix.
      # e.g. fg=5 = lavender, fg=13 = bright purple, fg=8 = gray.
      #
      # Declare the associative array ourselves — home-manager's init
      # ordering doesn't guarantee zsh-syntax-highlighting (which does
      # its own `typeset -A`) has sourced yet when this block runs. A
      # bare `ARR[key]=v` without a prior declaration errors out with
      # "assignment to invalid subscript range", killing every later
      # assignment in the block.
      typeset -gA ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[command]='fg=2,bold'
      ZSH_HIGHLIGHT_STYLES[builtin]='fg=10'
      ZSH_HIGHLIGHT_STYLES[function]='fg=2'
      ZSH_HIGHLIGHT_STYLES[alias]='fg=10,bold'
      ZSH_HIGHLIGHT_STYLES[precommand]='fg=14,bold'
      ZSH_HIGHLIGHT_STYLES[path]='fg=5'
      ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=13'
      ZSH_HIGHLIGHT_STYLES[path_approx]='fg=5,underline'
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=3'
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'
      ZSH_HIGHLIGHT_STYLES[string]='fg=3'
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=11'
      ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=13,bold'
      ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=13'
      ZSH_HIGHLIGHT_STYLES[global-alias]='fg=13'
      ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
      ZSH_HIGHLIGHT_STYLES[line-comment]='fg=8'
      ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]='fg=12'
      ZSH_HIGHLIGHT_STYLES[numeric-literal]='fg=12'
      ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=15'
      ZSH_HIGHLIGHT_STYLES[parameter-expansion]='fg=7'
      ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=7'
      ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=7'
      ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
      ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=9'
      ZSH_HIGHLIGHT_STYLES[redirection]='fg=9'
      ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=6,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=14,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=6,bold'
      ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=14,bold'
      ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg=15,bold,underline'
      ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=12,bold'

      # ---- completion styling ---------------------------------------
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:descriptions' format '%F{13}%B%d%b%f'
      zstyle ':completion:*:messages'     format '%F{3}%d%f'
      zstyle ':completion:*:warnings'     format '%F{1}No matches found%f'
      zstyle ':completion:*:corrections'  format '%F{9}%d (errors: %e)%f'
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
      zstyle ':completion:*' menu select
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}

      # ---- LESS pager colors ----------------------------------------
      # Uses the `$'\e...'` form so zsh emits literal ESC bytes. Plain
      # session variables would export the escape sequences as strings.
      export LESS_TERMCAP_mb=$'\e[1;31m'
      export LESS_TERMCAP_md=$'\e[1;35m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[1;44;33m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;36m'
      export LESS_TERMCAP_ue=$'\e[0m'

      # ---- boot-selection helpers -----------------------------------
      # The Arch originals shelled out to grub-reboot. systemd-boot
      # uses bootctl set-oneshot instead; systemctl handles the UEFI
      # firmware setup reboot directly.
      reboot-to-windows() {
        local entry
        entry=$(bootctl list --json=short 2>/dev/null \
          | jq -r '.[] | select(.title // "" | test("Windows"; "i")) | .id' \
          | head -n1)
        if [[ -z "$entry" ]]; then
          echo "reboot-to-windows: Windows boot entry not found" >&2
          return 1
        fi
        sudo systemctl reboot --boot-loader-entry="$entry"
      }

      reboot-to-uefi() {
        sudo systemctl reboot --firmware-setup
      }

      # Pokemon greeter on shell start. Non-fatal if krabby missing.
      command -v krabby >/dev/null && krabby random || true
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      character = {
        success_symbol = "[❯](bold fg:${theme.purple.hex})";
        error_symbol   = "[❯](bold fg:${theme.red.hex})";
        vimcmd_symbol  = "[❮](bold fg:${theme.green.hex})";
      };
      directory = {
        style              = "bold fg:${theme.purple.hex}";
        truncation_length  = 4;
        truncate_to_repo   = true;
      };
      git_branch = {
        style  = "fg:${theme.green.hex}";
        symbol = " ";
      };
      git_status = {
        style = "fg:${theme.amber.hex}";
      };
      cmd_duration = {
        style    = "fg:${theme.comment.hex}";
        min_time = 2000;
      };
      hostname = {
        style = "fg:${theme.cyan.hex}";
      };
      username = {
        style_user = "fg:${theme.blue.hex}";
      };
    };
  };
}
