{ inputs, lib }:

# `wammu-vm` — a QEMU/KVM-test variant of the real `wammu` host.
# Shares every module under ../../modules/nixos EXCEPT nvidia.nix, and
# adds VM-specific bits (qemu-guest, spice, serial console, throwaway
# initial password, password-auth SSH for bootstrap).
#
# Use this target when testing the flake in a VM before touching bare
# metal:
#   sudo nix run github:nix-community/disko -- \
#     --mode disko --flake ./dotfiles#wammu-vm
#   sudo nixos-install --flake ./dotfiles#wammu-vm

let
  inherit (lib) collectNix nixosSystem remove mkForce;
in
nixosSystem {
  specialArgs = { inherit inputs lib; };
  modules = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware.nix

    # Reuse the real user definition — same username, groups, home-
    # manager wiring. Password is overridden below.
    ../../users/wammu

    inputs.agenix.nixosModules.default

    # VM-local overrides. Everything below is only in effect for this
    # host; none of it leaks back into `wammu`.
    {
      networking.hostName = "wammu-vm";
      system.stateVersion = "25.11";

      # Guest agent (clean shutdown, host ↔ guest IO) + SPICE vdagent
      # (clipboard sharing, dynamic resize) when launched via virt-manager.
      services.qemuGuest.enable    = true;
      services.spice-vdagentd.enable = true;

      # VM fallback: keep SDDM on X11 and bypass UWSM wrapper for the
      # Hyprland session. This avoids a flaky VM path where SDDM login
      # succeeds but the Wayland user session exits immediately.
      #
      # `defaultSession` is load-bearing: disabling `withUWSM` does NOT
      # remove the `hyprland-uwsm.desktop` session file, and SDDM caches
      # the last-picked session in /var/lib/sddm/state.conf — so without
      # this, SDDM keeps launching uwsm, which then can't find its own
      # systemd user units and bails with exit 5.
      services.xserver.enable = lib.mkForce true;
      services.displayManager.sddm.wayland.enable = lib.mkForce false;
      services.displayManager.defaultSession = "hyprland";
      programs.hyprland.withUWSM = lib.mkForce false;

      # Route kernel messages to the emulated serial port so
      # `virsh console wammu-vm` (or qemu `-serial stdio`) is usable.
      boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

      # VM rendering quirks: avoid hardware cursor paths and allow
      # wlroots to fall back to software rendering when virgl/GL isn't
      # available from the guest display stack.
      environment.sessionVariables = {
        WLR_NO_HARDWARE_CURSORS   = "1";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
      };

      # Bare-metal Hyprland config pins DP-* outputs/workspaces, which
      # don't exist in QEMU. Force VM-safe monitor/workspace defaults.
      home-manager.users.wammu.wayland.windowManager.hyprland.settings = {
        monitor = lib.mkForce [ ",preferred,auto,1" ];
        workspace = lib.mkForce [ ];
      };

      # Throwaway credential. `hashedPassword = "!"` in users/wammu
      # locks the account; `initialPassword` needs `hashedPassword` null
      # to take effect, so force it.
      #
      # You change this with `passwd` on first login. NEVER use an
      # `initialPassword` literal on bare metal — it's world-readable
      # in /nix/store.
      users.users.wammu.hashedPassword  = mkForce null;
      users.users.wammu.initialPassword = "nixos";

      # Temporarily allow password SSH — bootstrap convenience so you
      # can `ssh -A wammu@<vm-ip>` before copying a pubkey over.
      # services.nix sets this false globally; override here only.
      services.openssh.settings.PasswordAuthentication = mkForce true;
    }
  ]
  # Same auto-import as the bare-metal host, minus nvidia.nix. A
  # virtio-gpu guest has no NVIDIA card to attach a driver to.
  ++ (collectNix ../../modules/nixos
        |> remove ../../modules/nixos/default.nix
        |> remove ../../modules/nixos/nvidia.nix);
}
