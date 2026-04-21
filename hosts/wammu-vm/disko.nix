# Disk layout for the VM variant. Same shape as hosts/wammu/disko.nix —
# GPT + 512 MiB ESP + ext4 root — but targeting /dev/vda (virtio-blk,
# default for libvirt/qemu) instead of the bare-metal NVMe device.
#
# Uses `size` rather than `start`/`end`. The start/end form was older
# disko API and runs into sgdisk quirks with `end = "100%"`.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "512M";
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
          size = "100%";
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
