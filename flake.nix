{
  description = "wammu's NixOS flake";

  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";

    nixos-hardware.url = "git+https://github.com/NixOS/nixos-hardware?ref=master";

    home-manager = {
      url = "git+https://github.com/nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "git+https://github.com/nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "git+https://github.com/nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "git+https://github.com/ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    themes = {
      url = "git+https://github.com/RGBCube/ThemeNix";
    };

    # Lavender colorscheme for nvim — not packaged in nixpkgs, so we
    # pin the codeberg source and wrap it in pkgs/lavender-nvim.nix.
    lavender-nvim = {
      url = "git+https://codeberg.org/jthvai/lavender.nvim?ref=stable";
      flake = false;
    };

    # Last pre-awww rewrite release. awww 0.12.0 currently regresses
    # animated GIF rendering, so keep the old swww daemon pinned locally
    # instead of depending on nixpkgs' renamed package.
    swww-0_11_2 = {
      url = "github:LGFae/swww/v0.11.2";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      # Extend nixpkgs.lib with our own helpers (see ./lib). Everything
      # downstream — including hosts — uses this extended lib.
      lib = nixpkgs.lib.extend (final: _prev: import ./lib { lib = final; });

      # Each directory under ./hosts becomes a NixOS configuration. The
      # host's default.nix is a function { inputs, lib } -> nixosConfiguration
      # that returns a full `lib.nixosSystem { ... }` value.
      hostDirs = lib.filterAttrs
        (_: type: type == "directory")
        (builtins.readDir ./hosts);

      mkHost = name: _type: import ./hosts/${name} { inherit inputs lib; };
    in
    {
      nixosConfigurations = lib.mapAttrs mkHost hostDirs;

      inherit lib;
      inherit inputs;
    };
}
