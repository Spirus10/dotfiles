{ pkgs, ... }:

{
  # Minimal system-level CLI. User-level packages (firefox, discord,
  # etc.) go in modules/home/packages.nix in Phase 3 — those belong to
  # home-manager, not the base system.
  environment.systemPackages = with pkgs; [
    bind        # dig, nslookup
    curl
    git
    htop
    jq
    pciutils    # lspci
    rsync
    tree
    usbutils    # lsusb
    wget
  ];
}
