{ ... }:

{
  # --- Bootloader: systemd-boot with XBOOTLDR (ESP only has 97M free) ---
  # Windows ESP (nvme0n1p1) is mounted at /efi and NOT formatted.
  # Kernels/initrds live on the 2GB XBOOTLDR partition at /boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.kernel.sysctl."kernel.sysrq" = 80;

  # --- Filesystems (Windows p1-p4 untouched) ---
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/XBOOTLDR";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
  fileSystems."/efi" = {
    device = "/dev/disk/by-partuuid/995a7b04-3f4d-4adf-b54f-3b5d6ddce3fe";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
  swapDevices = [ ];
  zramSwap.enable = true;
}
