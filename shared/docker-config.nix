{
  programs.zsh.shellAliases = {
    # Delete all stopped containers (including data-only containers)
    dkrm = "docker ps -aq -f status=exited | xargs -r docker rm -f";
    dkkill = "docker ps -q | xargs -r docker kill";
  };
}