{ pkgs, ... }:

{
  home.packages = [ pkgs.mpvpaper ];

  # Animated wallpaper via mpvpaper (mpv-as-layer-shell). Previous
  # attempt used awww, but awww 0.12.0 regressed issue #404 — the
  # transition animator panics on every animated GIF. mpvpaper uses
  # mpv's real video pipeline instead, so format/codec/timing/looping
  # are all handled by code that's been solid for decades.
  xdg.dataFile."wallpapers/bg.webm".source = ../../assets/bg.webm;

  # One long-running unit: mpvpaper keeps an mpv instance alive that
  # paints the wallpaper surface. No daemon+one-shot dance — starting
  # the unit IS starting playback, stopping it tears mpv down.
  #
  #   -o "loop-file=inf --no-audio"  mpv options: infinite loop, mute
  #   '*'                            apply to all outputs
  systemd.user.services.mpvpaper = {
    Unit = {
      Description = "Animated wallpaper via mpvpaper";
      PartOf      = [ "graphical-session.target" ];
      After       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = ''${pkgs.mpvpaper}/bin/mpvpaper -o "loop-file=inf --no-audio" '*' %h/.local/share/wallpapers/bg.webm'';
      Restart   = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
