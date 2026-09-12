{ pkgs, inputs, ... }:

{
  # --- Desktop: GNOME (Wayland, Adreno msm driver) ---
  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    settings.greeter.Exclude = "root";
  };
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    gnome-maps
    gnome-contacts
    gnome-tour
    gnome-user-docs
  ];

  # --- Singularity ---
  programs.singularity-desktop = {
    enable = true;
    core-apps.enable = false;
  };

  # --- Vicre ---
  programs.vicre = {
    enable = true;
    user = "jafed";
    package = inputs.vicre.packages.aarch64-linux.vicre;
    model = "gemini-3.8-flash-high";
  };

  # --- Audio ---
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true;
  };
}
