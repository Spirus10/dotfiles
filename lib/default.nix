{ lib }:

{
  # Recursively collect every .nix file under `dir`. Use with `remove` to
  # filter the caller's own default.nix out, otherwise you'll infinite-loop:
  #
  #   imports = lib.collectNix ./. |> lib.remove ./default.nix;
  collectNix = dir:
    lib.filesystem.listFilesRecursive dir
    |> builtins.filter (f: lib.hasSuffix ".nix" (toString f));
}
