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
        ## Definitely needed for USB:
        #"usb_storage"
        #"phy_qcom_qmp_combo"
        #"phy_snps_eusb2"
        #"phy_qcom_eusb2_repeater"
        #"tcsrcc_x1e80100"

        #"i2c_hid_of"
        #"i2c_qcom_geni"
        #"dispcc-x1e80100"
        #"gpucc-x1p42100"
        #"phy_qcom_edp"
        #"panel_edp"
        #"msm"
        #"nvme"
        #"phy_qcom_qmp_pcie"

        ## Needed with the DP altmode patches
        #"ps883x"
        #"pmic_glink_altmode"
        #"qrtr"

        #"panel_samsung_atna33xc20"

        "842_compress"
        "842_decompress"
        "aegis128"
        "af_alg"
        "ahci"
        "algif_aead"
        "algif_hash"
        "algif_skcipher"
        "apr"
        "asn1_encoder"
        "async_tx"
        "async_xor"
        "authenc"
        "aux_bridge"
        "aux_hpd_bridge"
        "bluetooth"
        "bnep"
        "btbcm"
        "btqca"
        "btqcomsmd"
        "caam"
        #"caamalg_desc"
        #"caamhash_desc"
        #"caam_jr"
        "cec"
        #"cfg80211"
        #"coresight"
        #"coresight_cti"
        #"coresight_etm4x"
        #"coresight_funnel"
        #"coresight_replicator"
        #"coresight_stm"
        #"coresight_tmc"
        #"crypto_engine"
        #"crypto_null"
        #"dax"
        "des_generic"
        "dispcc_x1e80100"
        "dm_bufio"
        "dm_crypt"
        "dm_integrity"
        "dmi_sysfs"
        "dm_mod"
        "drm_display_helper"
        "drm_dp_aux_bus"
        "drm_exec"
        "dwc3_pci"
        "ecc"
        "ecdh_generic"
        "encrypted_keys"
        "erofs"
        "error"
        "f2fs"
        "fastrpc"
        "fuse"
        "gpucc_x1p42100"
        "gpu_sched"
        "hci_uart"
        "i2c_hid"
        "i2c_hid_of"
        "i2c_qcom_geni"
        "icc_bwmon"
        "igc"
        "led_class_multicolor"
        "leds_qcom_lpg"
        "libarc4"
        #"libdes"
        "llcc_qcom"
        "lpasscc_sc8280xp"
        "lz4_compress"
        "lz4hc_compress"
        "mac80211"
        "md4"
        "md5"
        "mdt_loader"
        "mhi"
        "msm"
        "mux_gpio"
        "nls_cp437"
        "nls_iso8859_1"
        "nvme"
        "nvme_auth"
        "nvme_core"
        "nvme_keyring"
        "nvmem_qcom_spmi_sdam"
        "ocmem"
        "overlay"
        "panel_edp"
        "pci_pwrctrl_core"
        "pci_pwrctrl_pwrseq"
        "pdr_interface"
        "phy_nxp_ptn3222"
        "phy_qcom_edp"
        "phy_qcom_eusb2_repeater"
        "phy_qcom_qmp_combo"
        "phy_qcom_qmp_usb"
        "phy_snps_eusb2"
        "pinctrl_lpass_lpi"
        "pinctrl_sm8550_lpass_lpi"
        "pmic_glink"
        "pmic_glink_altmode"
        "polyval_ce"
        "ps883x"
        "pwm_bl"
        "pwrseq_core"
        "pwrseq_qcom_wcn"
        "q6apm_dai"
        "q6apm_lpass_dais"
        "q6prm"
        "q6prm_clocks"
        "qcom_battmgr"
        "qcom_common"
        "qcom_cpucp_mbox"
        "qcom_edac"
        "qcom_glink_smem"
        "qcom_pbs"
        "qcom_pd_mapper"
        "qcom_pdr_msg"
        "qcom_pil_info"
        "qcom_pon"
        "qcom_q6v5"
        "qcom_q6v5_pas"
        "qcom_spmi_temp_alarm"
        "qcom_stats"
        "qcom_sysmon"
        "qmi_helpers"
        "qrtr"
        "qrtr_mhi"
        "qrtr_smd"
        "regmap_sdw"
        "reset_gpio"
        "rfcomm"
        "rfkill"
        "rpmsg_char"
        "rpmsg_ctrl"
        "rtc_pm8xxx"
        "rtsx_pci_sdmmc"
        "sch_fq_codel"
        "sdhci_pci"
        "sd_mod"
        "sha3_ce"
        "slimbus"
        "sm3_ce"
        "sm4"
        "sm4_ce"
        "sm4_ce_ccm"
        "sm4_ce_cipher"
        "sm4_ce_gcm"
        "socinfo"
        "sr_mod"
        "stm_core"
        "stm_p_basic"
        "trusted"
        "typec_ucsi"
        "uas"
        "ucsi_glink"
        "uio"
        "uio_pdrv_genirq"
        "usbhid"
        "usb_storage"
        "wcnss_ctrl"
        "xhci_pci"
        "xor"
        "xor_neon"
        "zram"
      ];
      kernelModules = [
        "nvme"
        "f2fs"
      ];
    };

    kernelParams = [
      "pd_ignore_unused"
      "clk_ignore_unused"
      #"console=tty1"
    ];

    kernelPatches = [
      {
        extraConfig = ''
          CLK_X1E80100_CAMCC y
          HZ_1000 y
          MFD_QCOM_RPM y
          PCIE_QCOM y
          PHY_QCOM_QMP y
          PHY_QCOM_QMP_PCIE y
          QCOM_CLK_RPM y
          REGULATOR_QCOM_RPM y
          SCHED_CLUSTER y
          TYPEC y
        '';
        name = "snapdragon-config";
        patch = null;
      }
    ];

    kernelPackages = pkgs.callPackage ../packages/x1e42100-linux.nix { };
  };
}
