{ inputs, withSystem, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.x1p-linux = pkgs.buildLinux {
        version = "7.1.3";
        src = inputs.linux-src;

        structuredExtraConfig = with lib.kernel; {
          CLK_X1E80100_CAMCC = yes;
          CLK_X1P42100_GPUCC = yes;
          HZ_1000 = yes;
          MFD_QCOM_RPM = yes;
          PCIE_QCOM = yes;
          PHY_QCOM_QMP = yes;
          PHY_QCOM_QMP_PCIE = yes;
          QCOM_CLK_RPM = yes;
          REGULATOR_QCOM_RPM = yes;
          SCHED_CLUSTER = yes;
          TYPEC = yes;

          VIRTUALIZATION = yes;
          KVM = yes;
          MAGIC_SYSRQ = yes;
        };
      };
    };

  flake.modules.nixos.x1p =
    { pkgs, lib, ... }:
    {

      systemd.tpm2.enable = false;
      boot = {
        initrd = {
          systemd.tpm2.enable = false;
          includeDefaultModules = false;
          availableKernelModules = [
            "usb_storage"
            "phy_qcom_qmp_combo"
            "phy_snps_eusb2"
            "phy_qcom_eusb2_repeater"
            "tcsrcc_x1e80100"

            "i2c_hid_of"
            "i2c_qcom_geni"
            "dispcc-x1e80100"
            "gpucc-x1p42100"
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
          kernelModules = [
            "nvme"
            "f2fs"
          ];
          extraFirmwarePaths = [
            "qcom/gen71500_sqe.fw"
            "qcom/gen71500_gmu.bin"
            "qcom/gen71500_zap.mbn"
            "qcom/x1p42100/gen71500_zap.mbn"
          ];
        };

        kernelParams = [
          "pd_ignore_unused"
          "clk_ignore_unused"
          "cma=128MB"
        ];

        kernelPackages = withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }: pkgs.linuxPackagesFor config.packages.x1p-linux
        );
      };
    };
}
