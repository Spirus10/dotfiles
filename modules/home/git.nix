{ ... }:

{
  programs.git = {
    enable    = true;
    userName  = "spirus10";
    userEmail = "bailey.evanoff@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase        = true;
      push.autoSetupRemote = true;
    };
  };
}
