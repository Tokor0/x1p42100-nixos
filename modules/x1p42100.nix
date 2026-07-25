{ inputs, withSystem, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.x1p-linux = pkgs.buildLinux {
        version = "7.1.3";
        src = inputs.linux-src;

        kernelPatches = [
          {
            # Under review upstream, not merged. Adds the system-level PSCI idle
            # state; without it aosd/cxsd/ddr never leave 0 and suspend costs
            # ~2.3 W. See the patch header for the open review points.
            name = "hamoa-system-power-domain-ss3";
            patch = ../patches/hamoa-system-power-domain-ss3.patch;
          }
        ];

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
          # pd_ignore_unused and clk_ignore_unused were inherited from Ubuntu's
          # bringup config and deliberately removed: they stop the kernel ever
          # disabling unused power domains and clocks, which leaves 37 domains
          # on (including two UFS GDSCs on a machine that boots from NVMe) and
          # keeps cx/mx/mmcx voted up. With them set, `apss` slept 0.018% of a
          # 1 h s2idle suspend despite 145 ms average gaps between interrupts,
          # so the domains are being held up rather than woken.
          # Re-add both if the machine hangs at boot or on resume.
          "cma=128MB"
        ];

        kernelPackages = withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }: pkgs.linuxPackagesFor config.packages.x1p-linux
        );
      };
    };
}
