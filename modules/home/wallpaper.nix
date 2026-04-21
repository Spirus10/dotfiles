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
  # `-o` takes mpv's profile-option syntax (space-separated, no `--`).
  #   loop-file=inf  loop the same file in place. NOT `loop` — that's
  #                  an alias for loop-playlist=inf, which rewinds by
  #                  restarting the playlist entry and rebuilds the
  #                  decoder each cycle. On virtio-vga-gl that fresh
  #                  context eventually fails and playback stalls.
  #   keep-open=always  don't quit on EOF, belt-and-braces alongside loop
  #   no-audio       mute
  #   hwdec=no       force software decode — virtio-vga-gl in the VM
  #                  advertises GL but has no real video acceleration,
  #                  so hw-accelerated decode is unreliable. Costs
  #                  nothing on bare metal for a 1080p VP9 clip this
  #                  short.
  systemd.user.services.mpvpaper = {
    Unit = {
      Description = "Animated wallpaper via mpvpaper";
      PartOf      = [ "graphical-session.target" ];
      After       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = ''${pkgs.mpvpaper}/bin/mpvpaper -o "loop-file=inf keep-open=always no-audio hwdec=no" '*' %h/.local/share/wallpapers/bg.webm'';
      Restart   = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
