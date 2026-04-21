{ lib, theme, ... }:

let
  # Ghostty's config format allows `palette = N=#HEX` 16 times. Emit
  # one line per ANSI slot from theme.term, in order.
  paletteLines = lib.concatMapStringsSep "\n"
    (i: "palette = ${toString i}=${(builtins.elemAt theme.term i).hex}")
    (lib.range 0 15);
in
{
  programs.ghostty = {
    enable = true;
    settings = {
      theme              = "lavender";
      background-opacity = 0.8;
      font-family        = "JetBrainsMono Nerd Font";
    };
  };

  # Theme lives alongside the generated config. `programs.ghostty`
  # writes ~/.config/ghostty/config; this adds the theme the config
  # references, with values pulled from the central palette.
  xdg.configFile."ghostty/themes/lavender".text = ''
    ${paletteLines}
    background           = ${theme.bg.hex}
    foreground           = ${theme.fgBright.hex}
    cursor-color         = ${theme.purple.hex}
    cursor-text          = ${theme.bg.hex}
    selection-background = ${theme.selection.hex}
    selection-foreground = ${theme.fgBright.hex}
  '';
}
