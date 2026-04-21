{ inputs, lib }:

let
  inherit (lib) collectNix nixosSystem remove;
in
nixosSystem {
  specialArgs = { inherit inputs lib; };
  modules = [
    # Disko manages fileSystems.*; hardware.nix is generated with
    # --no-filesystems to avoid conflict.
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware.nix

    # User account(s).
    ../../users/wammu

    # Secrets (agenix). Wired up in Phase 6.
    # inputs.agenix.nixosModules.default

    # Host identity.
    {
      networking.hostName = "wammu";
      # Don't bump casually — this locks state migrations. Match the
      # nixpkgs version you installed from.
      system.stateVersion = "25.11";
    }
  ]
  # Auto-import every system-level module under modules/nixos/**.
  ++ (collectNix ../../modules/nixos |> remove ../../modules/nixos/default.nix);
}
