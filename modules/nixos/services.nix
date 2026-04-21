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

  # Logitech wireless devices (Unifying receivers etc.). Binds its unit
  # to the logitech-devices.target defined in udev.nix.
  services.solaar = {
    enable = true;
    window = "hide"; # tray only; no popup on login
  };

  # Noisetorch binary + per-user state. Actual activation happens via
  # the Yeti udev rule -> noisetorch-start.service. First run still
  # requires the GUI: open noisetorch, pick the mic, click Load.
  environment.systemPackages = [ pkgs.noisetorch ];

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
