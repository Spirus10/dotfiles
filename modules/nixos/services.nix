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
  environment.systemPackages = [ pkgs.solaar ];

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

  # Mic noise suppression used to be a noisetorch oneshot here, triggered
  # by a udev rule that could never reach it (udev activates system units;
  # this was a user unit). It is now an RNNoise filter-chain run natively
  # by PipeWire — see modules/nixos/audio.nix.
}
