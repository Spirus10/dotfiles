{ pkgs, ... }:

{
  # Remote admin.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Solaar — Logitech Unifying receiver manager. No native NixOS module
  # exists for this, so we install the package and run it as a user
  # service pinned to the graphical session.
  environment.systemPackages = [ pkgs.solaar pkgs.noisetorch ];

  systemd.user.services.solaar = {
    description = "Solaar (Logitech device manager)";
    wantedBy   = [ "graphical-session.target" ];
    partOf     = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart   = "${pkgs.solaar}/bin/solaar --window=hide";
      Restart     = "on-failure";
      RestartSec  = 3;
    };
  };

  # Noisetorch per-user oneshot. Actual activation happens via the Yeti
  # udev rule -> noisetorch-start.service (defined below). First run
  # still requires the GUI: open noisetorch, pick the mic, click Load.

  systemd.user.services.noisetorch-start = {
    description = "Engage noisetorch mic filter";
    # Not WantedBy default.target: only starts on the udev trigger.
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.noisetorch}/bin/noisetorch -i";
      RemainAfterExit = true;
    };
  };
}
