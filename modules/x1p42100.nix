{
  config,
  pkgs,
  lib,
  ...
}:
{
  hardware.deviceTree = {
    enable = true;
    name = "qcom/x1p42100-lenovo-ideapad-slim5x.dtb";
  };

  systemd.tpm2.enable = false;
  boot = {
    initrd = {
      systemd.tpm2.enable = false;
      availableKernelModules = [
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
        "msm"
        "nvme"
        "phy_qcom_qmp_pcie"

        # Needed with the DP altmode patches
        "ps883x"
        "pmic_glink_altmode"
        "qrtr"
      ];
    };

    kernelParams = [
      "pd_ignore_unused"
      "clk_ignore_unused"
    ];

    kernelPackages = pkgs.callPackage ../packages/x1e42100-linux.nix { };
  };
}
