{ ... }:

{
  users.users.jafed = {
    isNormalUser = true;
    description = "jafed";
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
