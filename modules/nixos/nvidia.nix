{ config, ... }:

{
  # Load nvidia early so KMS happens in initrd.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit support for Steam/Wine
  };

  hardware.nvidia = {
    # nvidia-open (MIT-licensed kernel module). Works on Turing (RTX 20xx,
    # GTX 16xx) and newer. Switch `open = false` for the proprietary blob
    # if you're on Maxwell/Pascal.
    open = true;

    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland / Hyprland compatibility env.
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    # Hyprland-specific: avoid cursor flicker on nvidia.
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
