{
  config,
  pkgs,
  lib,
  linux-src,
  ...
}:
{
  hardware.deviceTree = {
    enable = true;
    name = "qcom/x1p42100-lenovo-ideapad-slim5x-oled.dtb";
    #overlays = [
    #  {
    #    # The DTB uses "edp-panel" (generic) but Samsung OLED panels need the
    #    # dedicated atna40ct01 driver which handles DP AUX backlight correctly.
    #    # Without this, brightness is detected as 0 and the backlight is never enabled.
    #    name = "panel-samsung-atna40ct01";
    #    dtsText = ''
    #      /dts-v1/;
    #      /plugin/;

    #      / {
    #          compatible = "lenovo,ideapad-slim5x-oled";
    #      };

    #      &{/soc@0/display-subsystem@ae00000/displayport-controller@aea0000/aux-bus/panel} {
    #          compatible = "samsung,atna40ct01";
    #      };
    #    '';
    #  }
    #];
  };

  systemd.tpm2.enable = false;
  boot = {
    initrd = {
      systemd.tpm2.enable = false;
      availableKernelModules = [
        # Definitely needed for USB:
        "usb_storage"
        "uas"
        "phy_qcom_qmp_combo"
        "phy_snps_eusb2"
        "phy_qcom_eusb2_repeater"
        "tcsrcc_x1e80100"

        "i2c_hid_of"
        "i2c_qcom_geni"
        "dispcc_x1e80100"
        "gpucc_x1p42100"
        "phy_qcom_edp"
        "panel_edp"
        "msm"
        "nvme"
        "phy_qcom_qmp_pcie"

        "typec"
        "cdc_ether"
        "r8152"

        # Needed with the DP altmode patches
        "ps883x"
        "pmic_glink_altmode"
        "qrtr"
      ];
      kernelModules = [
        # USB host controller + storage
        "xhci_hcd"
        "xhci_pci"
        "usb_storage"
        "uas"
        # Live image filesystem
        "squashfs"
        "loop"
        "overlay"
        # HID (keyboard/input in initrd)
        "hid_generic"
        "usbhid"
        "i2c_hid_of"
        "i2c_qcom_geni"
        # Block/storage
        "typec"
        "r8152"
        "nvme"
        "f2fs"
        # Display
        "msm"
        "dispcc_x1e80100"
        "gpucc_x1p42100"
      ];
      extraFirmwarePaths = [
        "qcom/gen71500_sqe.fw"
        "qcom/gen71500_gmu.bin"
        "qcom/x1p42100/gen71500_zap.mbn"
        #"qcom/x1p42100/LENOVO/83HL/qcadsp8380.mbn"
        #"qcom/x1p42100/LENOVO/83HL/qccdsp8380.mbn"
        #"qcom/x1p42100/LENOVO/83HL/qcdxkmsucpurwa.mbn"
      ];
    };

    kernelParams = [
      "pd_ignore_unused"
      "clk_ignore_unused"
      "regulator_ignore_unused"
      "efi=noruntime"
      "id_aa64mmfr0.ecv=1"
      "console=tty0"
      "cma=128MB"
    ];

    #kernelPatches = [
    #  {
    #    extraConfig = ''
    #      CLK_X1E80100_CAMCC y
    #      CLK_X1P42100_GPUCC y
    #      HZ_1000 y
    #      MFD_QCOM_RPM y
    #      PCIE_QCOM y
    #      PHY_QCOM_QMP y
    #      PHY_QCOM_QMP_PCIE y
    #      QCOM_CLK_RPM y
    #      REGULATOR_QCOM_RPM y
    #      SCHED_CLUSTER y
    #      TYPEC y
    #    '';
    #    name = "snapdragon-config";
    #    patch = null;
    #  }
    #];

    kernelPackages = pkgs.callPackage ../packages/x1p42100-linux.nix { inherit linux-src; };
  };
}
