{ lib, ... }:

{
  imports = [
    # Phase 1 will fill this in with hardware.nix, disko.nix, and
    # modules/nixos. For now this is a minimal stub so `nix flake
    # check` passes.
  ];

  # Placeholder — overwritten once real config lands.
  system.stateVersion = "25.11";
}
