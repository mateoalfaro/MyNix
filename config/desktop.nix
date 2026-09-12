{ pkgs, inputs, ... }:

{
  # --- Desktop: GNOME (Wayland, Adreno msm driver) ---
  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    settings.greeter.Exclude = "root";
  };
  services.desktopManager.gnome.enable = true;
  # Workaround for nixpkgs#561267: gnome-control-center Users panel only
  # shows Fingerprint Login if org.gnome.login-screen schema (from gdm) is
  # on XDG_DATA_DIRS. Fedora has it in /usr/share globally, NixOS only
  # exports sessionPath packages. Without this, `gsettings get
  # org.gnome.login-screen enable-fingerprint-authentication` fails with
  # "No such schema" and the row is hidden before fprintd is consulted.
  services.desktopManager.gnome.sessionPath = [ pkgs.gdm ];
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
    #package = inputs.vicre.packages.aarch64-linux.vicre;
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
