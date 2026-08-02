{ awww, pkgs, ... }:

let
  wallpaper = "$HOME/.local/share/wallpapers/bg.gif";

  # `awww img` talks to the daemon over a unix socket that the daemon
  # only binds a moment after it starts. Hyprland's `exec-once` fired
  # both concurrently, so the client lost the race and the outputs
  # stayed on the default black — poll until the daemon answers.
  applyWallpaper = pkgs.writeShellScript "awww-apply-wallpaper" ''
    for _ in $(seq 100); do
      ${awww}/bin/awww query >/dev/null 2>&1 && break
      sleep 0.1
    done
    exec ${awww}/bin/awww img "${wallpaper}" --resize stretch
  '';
in
{
  home.packages = [ awww ];

  xdg.dataFile."wallpapers/bg.gif".source = ../../assets/bg.gif;

  # Same lifecycle treatment as quickshell: tie the daemon to
  # graphical-session.target rather than juggling `exec-once`.
  #
  # The image is applied via ExecStartPost rather than a second unit. A
  # separate unit would need `After` on both the daemon *and* the target
  # — omitting the latter leaves systemd's implicit
  # `Before=graphical-session.target`, which closes an ordering cycle and
  # gets the daemon's start job silently dropped. One unit sidesteps it,
  # and a daemon restart re-applies the wallpaper for free.
  systemd.user.services.awww = {
    Unit = {
      Description = "awww wallpaper daemon";
      PartOf      = [ "graphical-session.target" ];
      After       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart     = "${awww}/bin/awww-daemon";
      ExecStartPost = "${applyWallpaper}";
      Restart       = "on-failure";
      RestartSec    = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
