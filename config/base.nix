{ ... }:

{
  # --- Platform ---
  nixpkgs.hostPlatform.system = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";

  networking.hostName = "dell7441";

  # --- Flakes (also enabled on installed system) ---
  nix = {
    channel.enable = false;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/jafed/.desktop";
  };

  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
