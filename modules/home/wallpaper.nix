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
  # `ALL` is mpvpaper's documented selector for painting every output.
  # Keep both file and playlist loops enabled so EOF cannot tear down the
  # layer if mpvpaper/mpv treats the single wallpaper as a one-item list.
  # The unit is intentionally not WantedBy hyprland-session.target. Hyprland
  # starts it from exec-once after a short delay, which avoids a cold-login
  # race where mpvpaper creates a valid layer surface before the VM output is
  # ready to paint video frames.
  systemd.user.services.mpvpaper = {
    Unit = {
      Description = "Animated wallpaper via mpvpaper";
      PartOf      = [ "graphical-session.target" "hyprland-session.target" ];
      After       = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = ''${pkgs.mpvpaper}/bin/mpvpaper -o "loop-file=inf loop-playlist=inf keep-open=always no-audio hwdec=no" ALL %h/.local/share/wallpapers/bg.webm'';
      Restart   = "always";
      RestartSec = 2;
    };
  };
}
