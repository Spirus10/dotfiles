{
  description = "wammu VM-only flake (shallow Git fetches)";

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
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable&shallow=1";

    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "git+https://github.com/nix-community/nixvim?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "git+https://github.com/nix-community/disko?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "git+https://github.com/ryantm/agenix?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    themes = {
      url = "git+https://github.com/RGBCube/ThemeNix?shallow=1";
    };

    lavender-nvim = {
      url = "git+https://codeberg.org/jthvai/lavender.nvim?ref=stable";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      lib = nixpkgs.lib.extend (final: _prev: import ../lib { lib = final; });
    in
    {
      nixosConfigurations.wammu-vm = import ../hosts/wammu-vm {
        inherit inputs lib;
      };

      inherit lib;
      inherit inputs;
    };
}
