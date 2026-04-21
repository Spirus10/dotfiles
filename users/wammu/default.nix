# User definition for `wammu`.
#
# Declares the NixOS-side user (account, groups, shell). Home-manager
# configuration is wired in during Phase 3 and will import
# ../../modules/home.
{ pkgs, ... }:

{
  users.users.wammu = {
    isNormalUser = true;
    description = "wammu";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"          # sudo
      "networkmanager" # nmcli / network config
      "audio"
      "video"
      "input"
      "dialout"        # serial devices (for sec research/hardware work)
      "libvirtd"       # VMs (enabled in Phase 2)
    ];

    # Replace this before first boot:
    #   1. Generate a hashed password: `mkpasswd -m sha-512`
    #   2. Paste the output here.
    # Or leave as "!" and use `passwd wammu` after first login from TTY.
    hashedPassword = "!";

    # Add your SSH public keys here so you can log in remotely once the
    # box is up. Example:
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAAC3... wammu@somewhere"
    # ];
    openssh.authorizedKeys.keys = [ ];
  };

  # zsh must be enabled system-wide, not just set as a shell, for
  # programs.zsh to manage it via home-manager.
  programs.zsh.enable = true;
}
