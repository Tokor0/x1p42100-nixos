{ inputs, withSystem, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.x1p-linux = pkgs.buildLinux {
        version = "7.3.3";
        src = inputs.linux-src;

        structuredExtraConfig = with lib.kernel; {
          CLK_X1E80100_CAMCC = yes;
          CLK_X1P42100_GPUCC = yes;

          # Out-of-tree jglathe driver. No DTS references it (the Slim 5x panel
          # uses "edp-panel"), it still calls the drm_panel_init() that 7.2 made
          # static, and Ubuntu ships CONFIG_DRM_PANEL_SAMSUNG_ATNA40CT01=n.
          # Disable it so nixpkgs' autoModules doesn't try to build it.
          DRM_PANEL_SAMSUNG_ATNA40CT01 = no;
          # Out-of-tree Dell XPS 9345 EC driver lacks MODULE_IMPORT_NS("IIO_CONSUMER");
          # Ubuntu ships it disabled.
          EC_DELL_XPS = no;
          HZ_1000 = yes;
          # Ubuntu's IgH EtherCAT master uses x86-only cpu_khz; Ubuntu builds it
          # on amd64 only. Optional: unreachable while ETHERNET is off.
          IGH_ECAT = option no;
          MFD_QCOM_RPM = yes;
          # Ubuntu's AppArmor SAUCE patches use skb->secmark without guarding
          # it on CONFIG_NETWORK_SECMARK, which Ubuntu always enables.
          NETWORK_SECMARK = yes;
          PCIE_QCOM = yes;
          PHY_QCOM_QMP = yes;
          PHY_QCOM_QMP_PCIE = yes;
          QCOM_CLK_RPM = yes;
          REGULATOR_QCOM_RPM = yes;
          # Ubuntu SAUCE: would block unprivileged user namespaces (bwrap, Steam,
          # Chromium sandbox) if AppArmor were ever enabled.
          SECURITY_APPARMOR_RESTRICT_USERNS = no;
          SCHED_CLUSTER = yes;
          TYPEC = yes;

          VIRTUALIZATION = yes;
          KVM = yes;
          MAGIC_SYSRQ = yes;

          # Build time: skip subsystems for hardware the Slim 5x can't have.
          # USB-attachable classes (USB net/Wi-Fi/audio, UVC) are kept.
          DRM_AMDGPU = no;
          DRM_NOUVEAU = no;
          DRM_RADEON = no;
          DRM_XE = no;
          ATA = no;
          ETHERNET = no;
          INFINIBAND = lib.mkForce no;
          MEDIA_ANALOG_TV_SUPPORT = lib.mkForce no;
          MEDIA_DIGITAL_TV_SUPPORT = lib.mkForce no;
          MEDIA_PCI_SUPPORT = lib.mkForce no;
          MEDIA_SDR_SUPPORT = no;
          MTD = no;
          RC_CORE = lib.mkForce no;
          SCSI_LOWLEVEL = lib.mkForce no;
          SND_PCI = no;
          STAGING = lib.mkForce no;
          WLAN_VENDOR_INTEL = no;
        }
        # Non-Qualcomm SoC families: their clk/pinctrl/phy drivers and DTBs.
        // lib.genAttrs [
          "ARCH_ACTIONS"
          "ARCH_AIROHA"
          "ARCH_ALPINE"
          "ARCH_APPLE"
          "ARCH_ASPEED"
          "ARCH_AXIADO"
          "ARCH_BCM"
          "ARCH_BERLIN"
          "ARCH_BLAIZE"
          "ARCH_BST"
          "ARCH_CIX"
          "ARCH_EXYNOS"
          "ARCH_HISI"
          "ARCH_INTEL_SOCFPGA"
          "ARCH_K3"
          "ARCH_KEEMBAY"
          "ARCH_LG1K"
          "ARCH_MA35"
          "ARCH_MEDIATEK"
          "ARCH_MESON"
          "ARCH_MICROCHIP"
          "ARCH_MVEBU"
          "ARCH_NPCM"
          "ARCH_NXP"
          "ARCH_REALTEK"
          "ARCH_RENESAS"
          "ARCH_ROCKCHIP"
          "ARCH_SEATTLE"
          "ARCH_SOPHGO"
          "ARCH_SPRD"
          "ARCH_STM32"
          "ARCH_SUNXI"
          "ARCH_SYNQUACER"
          "ARCH_TEGRA"
          "ARCH_THUNDER"
          "ARCH_THUNDER2"
          "ARCH_UNIPHIER"
          "ARCH_VEXPRESS"
          "ARCH_VISCONTI"
          "ARCH_XGENE"
          "ARCH_ZYNQMP"
        ] (_: lib.kernel.no)
        # Set by nixpkgs' common-config, but unreachable with the above disabled.
        // lib.genAttrs [
          "8139TOO_8129"
          "8139TOO_PIO"
          "AIC79XX_DEBUG_ENABLE"
          "AIC7XXX_DEBUG_ENABLE"
          "AIC94XX_DEBUG"
          "ATA_BMDMA"
          "ATA_SFF"
          "DINGHAI"
          "DRM_AMD_ACP"
          "DRM_AMD_DC_FP"
          "DRM_AMD_DC_SI"
          "DRM_AMD_ISP"
          "DRM_AMD_SECURE_DISPLAY"
          "DRM_AMDGPU_CIK"
          "DRM_AMDGPU_SI"
          "DRM_AMDGPU_USERPTR"
          "DRM_NOUVEAU_SVM"
          "DRM_VC4_HDMI_CEC"
          "FSL_MC_UAPI_SUPPORT"
          "HSA_AMD"
          "HSA_AMD_P2P"
          "INFINIBAND_IPOIB"
          "INFINIBAND_IPOIB_CM"
          "LIRC"
          "MEDIA_ATTACH"
          "MEDIA_CEC_RC"
          "MEGARAID_NEWGEN"
          "MT798X_WMAC"
          "MTD_COMPLEX_MAPPINGS"
          "NET_VENDOR_MEDIATEK"
          "ROCKCHIP_DW_HDMI_QP"
          "ROCKCHIP_DW_MIPI_DSI2"
          "SATA_MOBILE_LPM_POLICY"
          "SCSI_LOWLEVEL_PCMCIA"
          "SCSI_SAS_ATA"
          "STAGING_MEDIA"
          "SUN8I_DE2_CCU"
          "USB_XHCI_TEGRA"
        ] (_: lib.mkForce lib.kernel.unset);
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
