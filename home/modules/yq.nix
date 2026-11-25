# yq (mikefarah's, the Go one), the YAML processor with jq-style syntax.
{ pkgs, ... }:
{
  home.packages = [ pkgs.yq-go ];
}
