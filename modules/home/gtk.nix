{ pkgs, ... }:

{
  # `colorScheme = "dark"` is the load-bearing line. Besides setting
  # gtk-application-prefer-dark-theme for GTK3, home-manager writes
  # dconf `org/gnome/desktop/interface color-scheme = "prefer-dark"`,
  # which xdg-desktop-portal-gtk re-exports as the freedesktop
  # `org.freedesktop.appearance color-scheme` value. That portal reading
  # is what Firefox (and libadwaita/GTK4 apps, which ignore theme names)
  # consults — it defaulted to 0 / "no preference", so Firefox drew light
  # chrome regardless of the theme picked inside Firefox itself.
  gtk = {
    enable      = true;
    colorScheme = "dark";

    theme = {
      name    = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name    = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
