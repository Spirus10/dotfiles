{ ... }:

{
  # Port of keyd/default.conf: capslock becomes Super/Meta on every
  # keyboard, system-wide. `*` in Arch-keyd is the default ID match;
  # in the NixOS module a named keyboard with no `ids` filter is
  # equivalent.
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock = "leftmeta";
      };
    };
  };
}
