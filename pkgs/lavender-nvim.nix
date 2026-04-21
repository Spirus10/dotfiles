{ vimUtils, src }:

# Wrapper around jthvai/lavender.nvim (codeberg, not in nixpkgs). The
# source is pinned via `inputs.lavender-nvim` in flake.nix, so version
# drift is controlled by flake.lock and not by whatever branch is
# current upstream.
vimUtils.buildVimPlugin {
  pname   = "lavender-nvim";
  version = "stable";
  inherit src;
  meta = {
    description = "Lavender colorscheme for Neovim";
    homepage    = "https://codeberg.org/jthvai/lavender.nvim";
  };
}
