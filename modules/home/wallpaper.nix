{ pkgs, ... }:

{
  home.packages = [ pkgs.awww ];

  # bg.gif lives in the repo so the wallpaper is reproducible — no
  # stashed ~/images/bg.gif reference like the Arch config had.
  #
  # The asset is intentionally coalesced (`magick src.gif -coalesce`),
  # not delta-compressed. awww 0.12.0 panics in the transition animator
  # if consecutive frames have different dimensions — which delta GIFs
  # have by design. Keep all frames at the full 1920x1080 or awww dies.
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
      # `--no-cache --format xrgb` is a workaround for a regression in
      # awww 0.12.0 (transitions.rs copy_from_slice panic on animated
      # GIFs). See upstream issue #404. Remove once a newer release is
      # in nixpkgs and the regression is fixed.
      ExecStart = "${pkgs.awww}/bin/awww-daemon --no-cache --format xrgb";
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
      # `--transition-type none` matters: awww's default transition
      # (a wipe at a 45° angle) can stall mid-animation on virgl/VM GL
      # paths and freeze the wallpaper in a half-wiped, diagonal state.
      ExecStart = "${pkgs.awww}/bin/awww img %h/.local/share/wallpapers/bg.gif --resize fit --transition-type none";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
