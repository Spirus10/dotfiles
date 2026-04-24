{ swww, ... }:

{
  home.packages = [ swww ];

  # Use nixpkgs 25.05's pre-awww swww package. Hyprland starts the
  # daemon and applies this GIF from exec-once.
  xdg.dataFile."wallpapers/bg.gif".source = ../../assets/bg.gif;
}
