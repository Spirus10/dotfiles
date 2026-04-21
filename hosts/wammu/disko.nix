# Declarative disk layout for the `wammu` host.
#
# This module wipes the target disk and re-creates it with a GPT table:
#   - 512 MiB EFI System Partition (FAT32) mounted at /boot
#   - remainder as a single ext4 root mounted at /
#
# Run once on first install via:
#   sudo nix --experimental-features 'nix-command flakes' run \
#     github:nix-community/disko/latest -- --mode disko --flake .#wammu
#
# or via disko-install which combines this with `nixos-install`.
{
  disko.devices.disk.main = {
    type = "disk";
    # Edit this before running disko. Verify with `lsblk` on the target.
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1M";
          end = "513M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          name = "root";
          start = "513M";
          end = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
