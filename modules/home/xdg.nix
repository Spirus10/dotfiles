{ ... }:

{
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      # Keep pre-26.05 behaviour explicit until `home.stateVersion`
      # is intentionally bumped.
      setSessionVariables = true;
      # Rely on XDG defaults for Documents/Downloads/etc. — no custom
      # layout needed yet. Override here if that changes.
    };
  };
}
