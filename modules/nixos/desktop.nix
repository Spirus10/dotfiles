{ pkgs, ... }:

{
  # SDDM's Wayland greeter uses Weston. On this host Weston currently
  # picks the AMD iGPU first, where no physical outputs are connected,
  # and exits with "Could not enable any output". Keep the greeter on X11;
  # the selected Hyprland desktop session is still Wayland.
  services.xserver.enable = true;

  # Hyprland as a Wayland session. This flips on the compositor, dbus
  # integration, and xdg-desktop-portal-hyprland. Per-user keybinds and
  # monitor layout are configured via home-manager in Phase 3.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG portals — required for screen sharing (OBS, Discord), file
  # pickers from sandboxed apps, etc.
  xdg.portal = {
    enable = true;
    wlr.enable = false; # programs.hyprland provides the hyprland portal
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
  };

  services.displayManager.defaultSession = "hyprland";

  # Dolphin (KDE file manager) is referenced by your Hyprland keybinds
  # as $fileManager. It needs a polkit agent to do privileged actions.
  security.polkit.enable = true;

  # Dconf backs GTK settings; without it many GTK apps can't persist
  # preferences on a pure-Wayland session.
  programs.dconf.enable = true;
}
