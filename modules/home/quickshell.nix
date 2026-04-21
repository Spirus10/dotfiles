{ pkgs, ... }:

{
  home.packages = [ pkgs.quickshell ];

  # Single-file shell. Kept verbatim in assets/ so it remains diffable
  # against upstream QML tooling; theming lands later by threading the
  # lavender palette into a pragma-prepended copy.
  xdg.configFile."quickshell/shell.qml".source = ../../assets/quickshell/shell.qml;

  # systemd user unit so the shell follows graphical-session.target —
  # same lifecycle as Hyprland, no `exec-once` bookkeeping, restart
  # on crash. `qs` is the Quickshell CLI.
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      PartOf      = [ "graphical-session.target" ];
      After       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs";
      Restart   = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
