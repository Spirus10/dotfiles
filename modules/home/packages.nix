{ pkgs, inputs, ... }:

{
  # User-level applications. System-level CLI (git, curl, etc.) is in
  # modules/nixos/packages.nix. Anything graphical or user-scoped
  # lives here so home-manager manages it per-user.
  home.packages = with pkgs; [
    # Browsers, chat, creative
    firefox
    discord
    spotify
    obsidian

    # Password manager
    _1password-gui
    _1password-cli

    # Hyprland desktop companions referenced by hyprland.nix binds
    dolphin
    cliphist        # clipboard history backend read by quickshell
    wl-clipboard    # wl-copy / wl-paste
    grim
    slurp
    swappy
    brightnessctl
    playerctl

    # Shell QoL
    bat
    eza
    fd
    ripgrep
    fzf

    # Pokemon greeter (used by zsh.nix on shell start)
    krabby

    # `nh` — friendlier `nixos-rebuild` wrapper. Used by the `nhu`
    # alias and by the rebuild helper script added in Phase 7.
    nh
  ] ++ [
    # agenix CLI — for editing secrets via `agenix -e <name>.age`.
    # Reads secrets/secrets.nix for the recipient map. Shipped via
    # the flake input so the CLI version matches the NixOS module.
    inputs.agenix.packages.${pkgs.system}.default
  ];
}
