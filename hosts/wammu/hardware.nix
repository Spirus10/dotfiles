# Hardware configuration for `wammu`.
#
# This file will be REPLACED on first install by running:
#   sudo nixos-generate-config --no-filesystems --root /mnt --dir .
#
# `--no-filesystems` skips generating fileSystems.* (disko owns that).
# The output captures kernel modules, CPU microcode, firmware quirks
# specific to this hardware. Commit the result.
#
# Until then, this stub declares the minimum needed for `nix flake check`.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Populated by nixos-generate-config on the target machine.
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # AMD CPU presumed (3 monitors, gaming rig, nvidia-open). Switch to
  # hardware.cpu.intel.updateMicrocode if this is an Intel box.
  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  # Placeholder — nixos-generate-config will detect the real value.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
