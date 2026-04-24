# User definition for `wammu` plus the home-manager wiring. Every
# file under ../../modules/home is imported into this user's home
# config via `collectNix`, matching the system-level pattern.
{ inputs, lib, pkgs, ... }:

let
  inherit (lib) collectNix;
  swwwPkgs = import inputs.nixpkgs-swww {
    inherit (pkgs) system;
  };
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users.wammu = {
    isNormalUser = true;
    description  = "wammu";
    shell        = pkgs.zsh;
    extraGroups = [
      "wheel"          # sudo
      "networkmanager" # nmcli / network config
      "audio"
      "video"
      "input"
      "dialout"        # serial devices (for sec research/hardware work)
      "libvirtd"       # VMs
    ];

    # Replace before first boot:
    #   1. Generate a hashed password: `mkpasswd -m sha-512`
    #   2. Paste the output here.
    # Or leave as "!" and use `passwd wammu` after first login from TTY.
    hashedPassword = "!";

    # Add SSH public keys here for remote login once the box is up.
    openssh.authorizedKeys.keys = [ ];
  };

  # zsh must be enabled system-wide for programs.zsh (home-manager) to
  # layer on top of it correctly.
  programs.zsh.enable = true;

  home-manager = {
    # Use the system's pkgs (with overlays + allowUnfree) so home
    # packages resolve from the same instantiation as system packages.
    useGlobalPkgs    = true;
    useUserPackages  = true;

    # Rename any stray files home-manager wants to own instead of
    # aborting the switch. Saves the usual "existing file at ..." dance.
    backupFileExtension = "hm-bak";

    extraSpecialArgs = {
      inherit inputs;
      inherit (swwwPkgs) swww;
    };

    users.wammu = {
      imports = collectNix ../../modules/home;

      home = {
        username      = "wammu";
        homeDirectory = "/home/wammu";
        stateVersion  = "25.11";
      };
    };
  };
}
