{ pkgs, ... }:

{
  home.packages = [ pkgs.awww ];

  # bg.gif lives in the repo so the wallpaper is reproducible — no
  # stashed ~/images/bg.gif reference like the Arch config had.
  xdg.dataFile."wallpapers/bg.gif".source = ../../assets/bg.gif;

  # Daemon: long-running wayland wallpaper process. Wanted-by the
  # graphical session so it comes up with Hyprland and dies with it.
  #
  # `awww` is the renamed swww upstream; `pkgs.swww` is a nixpkgs alias.
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wayland wallpaper daemon";
      PartOf      = [ "graphical-session.target" ];
      After       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart   = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Oneshot that applies the wallpaper once the daemon is up. Split
  # into its own unit so restarts of the daemon don't re-trigger a
  # setwallpaper, and `systemctl --user restart awww-wallpaper`
  # reapplies it without touching the daemon.
  systemd.user.services.awww-wallpaper = {
    Unit = {
      Description = "Apply the current wallpaper via awww";
      Requires    = [ "awww-daemon.service" ];
      After       = [ "awww-daemon.service" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "oneshot";
      ExecStart = "${pkgs.awww}/bin/awww img %h/.local/share/wallpapers/bg.gif --resize fit";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
