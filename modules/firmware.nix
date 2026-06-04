{ inputs, withSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.slim5x-firmware = pkgs.runCommand "slim5x-firmware" { } ''
        mkdir -p $out/lib/firmware/qcom/x1p42100/LENOVO/83HL
        cp ${inputs.slim5x-firmware}/qcom/x1p42100/LENOVO/83HL/{adsp_dtbs.elf,adspr.jsn,adsps.jsn,adspua.jsn,battmgr.jsn,cdsp_dtbs.elf,cdspr.jsn,qcadsp8380.mbn,qcav1e8380.mbn,qccdsp8380.mbn,qcdxkmsuc8380.mbn,qcdxkmsucpurwa.mbn,qcvss8380.mbn,qcvss8380_pa.mbn} \
          $out/lib/firmware/qcom/x1p42100/LENOVO/83HL/
      '';
    };

  flake.modules.nixos.slim5x =
    { pkgs, ... }:
    {
      hardware.firmware = [
        pkgs.linux-firmware
        pkgs.wireless-regdb
        (withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.slim5x-firmware))
      ];

      boot.initrd.extraFirmwarePaths = map (f: "qcom/x1p42100/LENOVO/83HL/${f}") [
        "adsp_dtbs.elf"
        "adsp_dtbs.elf"
        "adspr.jsn"
        "adsps.jsn"
        "adspua.jsn"
        "battmgr.jsn"
        "cdsp_dtbs.elf"
        "cdspr.jsn"
        "qcadsp8380.mbn"
        "qcav1e8380.mbn"
        "qccdsp8380.mbn"
        "qcdxkmsuc8380.mbn"
        "qcdxkmsucpurwa.mbn"
        "qcvss8380.mbn"
        "qcvss8380_pa.mbn"
      ];
    };
}
