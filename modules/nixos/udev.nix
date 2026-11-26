{ ... }:

{
  # Inlined ports of udev/rules.d/*.rules.
  services.udev.extraRules = ''
    # Any Logitech USB device plug-in pulls up the logitech-devices target,
    # so downstream solaar/keyd tweaks activate without manual intervention.
    SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="logitech-devices.target"

    # The FIFINE mic rule that used to live here started noisetorch. It
    # could never have fired: ENV{SYSTEMD_WANTS} activates system units,
    # and the unit it named was a user unit. Mic noise suppression is now
    # a PipeWire filter-chain (modules/nixos/audio.nix), which needs no
    # hotplug trigger at all.
  '';

  # The target file the first rule wants. Empty target — other units
  # (e.g. solaar.service) can WantedBy=logitech-devices.target to pile on.
  systemd.targets.logitech-devices = {
    description = "Logitech USB device connected";
  };
}
