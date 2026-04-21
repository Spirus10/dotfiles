{ pkgs, ... }:

{
  home.packages = [ pkgs.awww ];

  # bg.gif lives in the repo so the wallpaper is reproducible — no
  # stashed ~/images/bg.gif reference like the Arch config had.
  xdg.dataFile."wallpapers/bg.gif".source = ../../assets/bg.gif;

  # Daemon: long-running wayland wallpaper process. Wanted-by the
  # graphical session so it comes up with Hyprland and dies with it.
  systemd.user.services.swww-daemon = {
    Unit = {
      Description = "swww wayland wallpaper daemon";
      PartOf      = [ "graphical-session.target" ];
      After       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/swww-daemon";
      Restart   = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Oneshot that applies the wallpaper once the daemon is up. Split
  # into its own unit so restarts of the daemon don't re-trigger a
  # setwallpaper, and `systemctl --user restart swww-wallpaper`
  # reapplies it without touching the daemon.
  systemd.user.services.swww-wallpaper = {
    Unit = {
      Description = "Apply the current wallpaper via swww";
      Requires    = [ "swww-daemon.service" ];
      After       = [ "swww-daemon.service" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      Type      = "oneshot";
      ExecStart = "${pkgs.awww}/bin/swww img %h/.local/share/wallpapers/bg.gif --resize fit";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
