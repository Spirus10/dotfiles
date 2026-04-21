{ ... }:

let
  mkColor = raw: {
    inherit raw;                   # "b4a4f4"
    hex    = "#${raw}";            # "#b4a4f4"
    with0x = "0x${raw}";           # Qt/QML literals
    rgba   = alpha: "rgba(${raw}${alpha})"; # Hyprland color syntax
  };

  # Lavender palette, sourced from jthvai/lavender.nvim via the
  # Ghostty theme file. Single source of truth for every themed
  # module (hyprland borders, ghostty palette, zsh highlighting,
  # starship prompt, nixvim colorscheme).
  colors = rec {
    bg         = mkColor "1b1c2b";  # primary background
    bgAlt      = mkColor "212337";  # subtle surfaces
    selection  = mkColor "403c64";  # visual selection

    fg         = mkColor "d6e7f0";  # default foreground
    fgBright   = mkColor "eeffff";  # emphasis foreground
    comment    = mkColor "515772";  # mutes, comments, fade

    red        = mkColor "ff5370";
    redBright  = mkColor "ff757f";
    green      = mkColor "2df4c0";
    greenAlt   = mkColor "59d6b5";
    amber      = mkColor "ffc777";
    amberAlt   = mkColor "add8e6";
    blue       = mkColor "5fafff";
    blueDeep   = mkColor "7486d6";
    cyan       = mkColor "04d1f9";
    cyanBright = mkColor "80cbc4";
    purple     = mkColor "b4a4f4";
    purpleLite = mkColor "b994f1";

    cursor     = purple;
  };
in
{
  # Threaded into every home module as `{ theme, ... }:`.
  _module.args.theme = colors // {
    # Terminal palette for Ghostty / nvim termcolors. Order is the
    # ANSI 16 (0..15); don't sort — indexes are semantic.
    term = [
      colors.bg         # 0  — black / bg
      colors.red        # 1
      colors.green      # 2
      colors.amber      # 3
      colors.blue       # 4
      colors.purple     # 5
      colors.cyan       # 6
      colors.fg         # 7  — light fg
      colors.comment    # 8  — dim "bright black"
      colors.redBright  # 9
      colors.greenAlt   # 10
      colors.amberAlt   # 11
      colors.blueDeep   # 12
      colors.purpleLite # 13
      colors.cyanBright # 14
      colors.fgBright   # 15 — brightest fg
    ];
  };
}
