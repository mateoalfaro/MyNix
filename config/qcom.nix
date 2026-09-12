{ pkgs, ... }:

{
  # --- Snapdragon X Elite X1E80100 (Dell Inspiron 14 Plus 7441), vendored ---
  # Previously pulled from kuruczgy/x1e-nixos-config (pinned 2026-07-21, Yoga/ThinkPad
  # only, custom kernel unmaintained). With nixpkgs unstable 2026-09 / kernel 7.2,
  # the DTB + firmware are upstream; the bits below are the still-needed glue:
  # initrd modules for USB/display/NVMe, TPM workarounds, iris blacklist, SoC params.
  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "qcom/x1e80100-dell-inspiron-14-plus-7441.dtb";

  # AUO B140QAX01.H advertises PWM brightness, not AUX brightness control.
  # Firmware already routes PMK8550 GPIO5 to func3; describe its PWM provider
  # and panel connection so NixOS builds the corrected DTB for every generation.
  # Physical brightness response still needs verification after reboot.
  hardware.deviceTree.overlays = [
    {
      # This unit's Windows inventory identifies LXST2021 (HID vendor 29BD).
      # Use the upstream Latitude 7455 LXST2021 wiring/address on the shared
      # Thena board, instead of the Inspiron's nonresponding address 0x10.
      # Verified on this unit: 29BD:1103 binds at 0x09 and touch works.
      name = "dell7441-lxst2021-touchscreen";
      filter = "x1e80100-dell-inspiron-14-plus-7441.dtb";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
            compatible = "dell,inspiron-14-plus-7441";

            fragment@0 {
                target-path = "/soc@0/geniqup@ac0000/i2c@a80000/touchscreen@10";
                __overlay__ {
                    status = "disabled";
                };
            };

            fragment@1 {
                target = <&i2c8>;
                __overlay__ {
                    #address-cells = <1>;
                    #size-cells = <0>;
                    touchscreen@9 {
                        compatible = "hid-over-i2c";
                        reg = <0x09>;
                        hid-descr-addr = <0x01>;
                        interrupts-extended = <&tlmm 51 8>;
                        pinctrl-0 = <&ts0_default>;
                        pinctrl-names = "default";
                        status = "okay";
                    };
                };
            };
        };
      '';
    }
    {
      name = "dell7441-auo-pwm-backlight";
      filter = "x1e80100-dell-inspiron-14-plus-7441.dtb";
      dtsText = ''
        // Experimental: PMK8550 channel 0 -> GPIO5 func3, already selected by firmware.
        // Physical brightness response on the AUO panel still needs validation.
        /dts-v1/;
        /plugin/;

        / {
            compatible = "dell,inspiron-14-plus-7441";

            fragment@0 {
                target = <&pmk8550_pwm>;
                __overlay__ {
                    status = "okay";
                    pinctrl-names = "default";
                    pinctrl-0 = <&dell_pwm_output>;
                };
            };

            fragment@1 {
                target = <&pmk8550_gpios>;
                __overlay__ {
                    dell_pwm_output: dell-backlight-pwm-state {
                        pins = "gpio5";
                        function = "func3";
                    };
                };
            };

            fragment@2 {
                target-path = "/";
                __overlay__ {
                    dell_pwm_backlight: backlight {
                        compatible = "pwm-backlight";
                        pwms = <&pmk8550_pwm 0 4266537>;
                        power-supply = <&vreg_edp_3p3>;
                        brightness-levels = <0 10 20 30 40 50 60 70 80 90 100>;
                        num-interpolated-steps = <10>;
                        default-brightness-level = <80>;
                    };
                };
            };

            fragment@3 {
                target-path = "/soc@0/display-subsystem@ae00000/displayport-controller@aea0000/aux-bus/panel";
                __overlay__ {
                    backlight = <&dell_pwm_backlight>;
                };
            };
        };
      '';
    }
  ];

  # No TPM driver on this platform; without this, boot waits ~1.5min on TPM.
  systemd.tpm2.enable = false;
  boot.initrd.systemd.tpm2.enable = false;

  boot.blacklistedKernelModules = [
    # Too buggy right now, too many kernel crashes (x1e upstream note, still true).
    "qcom_iris"
  ];

  boot.initrd.includeDefaultModules = false;
  boot.initrd.availableKernelModules = [
    # Definitely needed for USB:
    "usb_storage"
    "phy_qcom_qmp_combo"
    "phy_snps_eusb2"
    "phy_qcom_eusb2_repeater"
    "tcsrcc_x1e80100"

    "i2c_hid_of"
    "i2c_qcom_geni"
    "dispcc-x1e80100"
    "gpucc-x1e80100"
    "phy_qcom_edp"
    "panel_edp"
    # The panel now depends on the PMK8550 PWM backlight during early boot.
    "leds-qcom-lpg"
    "pwm_bl"
    "msm"
    "nvme"
    "phy_qcom_qmp_pcie"

    # Needed with the DP altmode patches
    "ps883x"
    "pmic_glink_altmode"
    "qrtr"
  ];

  boot.kernelParams = [
    "pd_ignore_unused"
    "clk_ignore_unused"

    # Linux local privilege escalation using algif_aead:
    # https://copy.fail/
    # Linux local privilege escalation using esp4, esp6, rxrpc:
    # https://github.com/V4bel/dirtyfrag
    "module_blacklist=algif_aead,esp4,esp6,rxrpc"
  ];

  # Non-LTS kernel as requested (unstable's latest; x1e module defaults to this too)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Extra safety from x1e upstream: NVMe/ASPM lockup workaround if needed.
  # Uncomment if you see random freezes:
  # boot.kernelParams = [ "pcie_aspm=off" ];

  hardware.enableRedistributableFirmware = true;

  # --- Qualcomm DSP firmware extracted from Windows via qcom-firmware-extract ---
  # Source files live in ../firmware/lib/firmware/qcom/... (canonical linux-firmware
  # layout, NOT ../firmware/lib/firmware/updates/...).
  # NOTE: do NOT stage under `updates/` here. On classic distros the kernel's
  # firmware loader searches /lib/firmware/updates/ first, but on NixOS
  # `hardware.firmware` packages are combined into one store dir
  # (/nix/store/...-firmware/lib/firmware) which is passed to the kernel as the
  # single firmware search path, so `updates/` is never consulted and files
  # placed there are invisible (this was the previous bug: ADSP/CDSP/GPU-zap
  # all failed with error -2 despite being present under updates/).
  # Install directly to /lib/firmware/qcom/... so buildEnv merges them with
  # linux-firmware (no filename collisions for inspiron-14-plus-7441; only the
  # tplg comes from upstream). Do NOT vendor *.xz duplicates: NixOS
  # auto-compresses everything to .zst, and `*.xz.zst` is never requested.
  hardware.firmware = [
    (pkgs.runCommand "qcom-x1e-firmware-extracted" { } ''
      mkdir -p $out/lib/firmware
      cp -r ${../firmware/lib/firmware}/* $out/lib/firmware/
    '')
  ];

  services.fprintd.enable = true;
}
