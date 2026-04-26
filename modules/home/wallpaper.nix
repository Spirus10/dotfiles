{ awww, ... }:

{
  home.packages = [ awww ];

  # Hyprland starts the daemon and applies this GIF from exec-once.
  xdg.dataFile."wallpapers/bg.gif".source = ../../assets/bg.gif;
}
