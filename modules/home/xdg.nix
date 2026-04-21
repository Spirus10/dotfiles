{ ... }:

{
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      # Rely on XDG defaults for Documents/Downloads/etc. — no custom
      # layout needed yet. Override here if that changes.
    };
  };
}
