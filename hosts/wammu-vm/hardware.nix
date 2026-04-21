# Hardware profile for the VM. Imports the qemu-guest profile from
# nixpkgs (which pulls in virtio kernel modules, clock skew handling,
# and a few service tweaks) and spells out the initrd modules needed
# to mount /dev/vda from stage-1.
#
# This file is hand-written — no nixos-generate-config needed, because
# every KVM guest looks the same.
{ modulesPath, lib, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "ahci"
    "xhci_pci"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules  = [ ];
  # kvm-amd presumes an AMD host CPU (matches the bare-metal target).
  # On an Intel host, swap to "kvm-intel".
  boot.kernelModules         = [ "kvm-amd" ];
  boot.extraModulePackages   = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
