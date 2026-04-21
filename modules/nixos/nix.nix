{ inputs, ... }:

{
  # 1password, Spotify, Discord, NVIDIA drivers — the usual suspects.
  # Flip this off and every unfree package build fails, which surfaces
  # what actually requires the allowlist.
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    extraOptions = ''
	!include /var/lib/nix/access-tokens.conf
    '';

    # Automatic garbage collection — keep the last 14 days.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # Pin the system-wide nixpkgs to the flake's nixpkgs so legacy
    # `nix-shell -p foo` and `nix run nixpkgs#foo` resolve to the same
    # pkgs as the system build. Without this, `nix-shell` uses the root
    # channel, which is confusing on a flakes-only setup.
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
