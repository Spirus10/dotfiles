{ pkgs, ... }:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      consoleMode = "auto";
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Latest kernel for best Wayland + nvidia-open support.
  # Swap to `pkgs.linuxPackages` for LTS or `pkgs.linuxPackages_zen`
  # for desktop-tuned scheduling.
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
