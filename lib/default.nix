{ lib }:

{
  # Return every .nix file directly under `dir` as an absolute path,
  # excluding `default.nix` itself. Used by aggregator modules to
  # auto-import every sibling file without listing them by hand.
  #
  # Example: imports = lib.collectNix ./.;
  collectNix = dir:
    let
      entries = builtins.readDir dir;
      isNix = name: type:
        type == "regular"
        && lib.hasSuffix ".nix" name
        && name != "default.nix";
      names = lib.attrNames (lib.filterAttrs isNix entries);
    in
    map (name: dir + "/${name}") names;
}
