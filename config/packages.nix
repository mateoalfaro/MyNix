{ inputs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    inputs.llms.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt
    inputs.llms.packages.${pkgs.stdenv.hostPlatform.system}.opencode2
    bibata-cursors
    gnome-tweaks
    fex
    brave-origin
    resources
    gcc
    zed-editor
    git
    sbctl
    nil
    nixd
    clang
    clang-tools
  ];
}
