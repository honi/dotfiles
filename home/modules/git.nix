# git. Installed by Nix (not apt) through Home Manager.
{ ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      ".direnv"
      ".devenv/"
      "devenv.lock"
      "devenv.nix"
    ];
    settings = {
      user = {
        name = "Joni Bekenstein";
        email = "joni@bek.io";
      };
      push = {
        default = "simple";
        followTags = true;
        autoSetupRemote = true;
      };
      color.ui = "auto";
      alias = {
        co = "checkout";
        br = "branch";
        st = "status";
        ci = "commit";
        cm = "commit -m";
        ca = "commit --amend";
        a = "add";
        ps = "push";
        pl = "pull";
        l = "log --graph --pretty=format:'%C(yellow)%h%C(cyan)%d%Creset %s %C(white)- %an, %ar%Creset'";
        d = "diff";
        dc = "diff --cached";
        cbr = "rev-parse --abbrev-ref HEAD";
        cp = "cherry-pick";
        rs = "restore --staged";
      };
      core = {
        autocrlf = "input";
        ignorecase = false;
      };
      pull.rebase = true;
      init.defaultBranch = "main";
    };
  };
}
