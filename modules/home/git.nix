{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name  = "spirus10";
      user.email = "bailey.evanoff@gmail.com";

      init.defaultBranch  = "main";
      pull.rebase         = true;
      push.autoSetupRemote = true;
    };
  };
}
