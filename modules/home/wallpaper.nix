{ inputs, pkgs, ... }:

let
  swww = pkgs.callPackage ../../pkgs/swww-0_11_2.nix {
    swwwSrc = inputs.swww-0_11_2;
  };
in
{
  home.packages = [ swww ];

  # Pinned to swww 0.11.2, the last known-good release before the awww
  # 0.12 rewrite/regression. Hyprland starts the daemon and applies this
  # GIF from exec-once.
  xdg.dataFile."wallpapers/bg.gif".source = ../../assets/bg.gif;
}
