{ lib, ... }:

{
  networking.networkmanager = {
    enable = true;
    plugins = lib.mkForce [ ];
  };
  hardware.bluetooth.enable = true;

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
