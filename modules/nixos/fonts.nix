{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;

    # Curated nerd-font selection. The Arch install had ~60 variants
    # which is wildly more than anything actually uses. Add more by
    # listing the attribute from `pkgs.nerd-fonts.*`.
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
      nerd-fonts.caskaydia-cove # Cascadia Code NF
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.meslo-lg
      nerd-fonts.geist-mono
      nerd-fonts.symbols-only

      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji

      liberation_ttf
      font-awesome
      material-icons
      material-design-icons
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        serif     = [ "Noto Serif" "Liberation Serif" ];
        emoji     = [ "Noto Color Emoji" ];
      };
    };
  };
}
