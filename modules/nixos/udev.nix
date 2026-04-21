{ ... }:

{
  # Inlined ports of udev/rules.d/*.rules.
  services.udev.extraRules = ''
    # Any Logitech USB device plug-in pulls up the logitech-devices target,
    # so downstream solaar/keyd tweaks activate without manual intervention.
    SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="logitech-devices.target"

    # When the Blue Yeti mic shows up, start noisetorch so the filter
    # engages before the first mic-enabled app grabs the source.
    SUBSYSTEM=="sound", ATTRS{id}=="*Yeti*", TAG+="systemd", ENV{SYSTEMD_WANTS}="noisetorch-start.service"
  '';

  # The target file the first rule wants. Empty target — other units
  # (e.g. solaar.service) can WantedBy=logitech-devices.target to pile on.
  systemd.targets.logitech-devices = {
    description = "Logitech USB device connected";
  };
}
