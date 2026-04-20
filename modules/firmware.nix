{ inputs, withSystem, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.firmware-slim5x = pkgs.runCommand "slim5x-firmware" { } ''
      mkdir -p $out/lib/firmware/qcom/x1p42100/LENOVO/83HL
      cp ${inputs.slim5x-firmware}/qcom/x1p42100/LENOVO/83HL/{adsp_dtbs.elf,adspr.jsn,adsps.jsn,adspua.jsn,battmgr.jsn,cdsp_dtbs.elf,cdspr.jsn,qcadsp8380.mbn,qcav1e8380.mbn,qccdsp8380.mbn,qcdxkmsuc8380.mbn,qcdxkmsucpurwa.mbn,qcvss8380.mbn,qcvss8380_pa.mbn} \
        $out/lib/firmware/qcom/x1p42100/LENOVO/83HL/
    '';
  };

  flake.modules.nixos.qcom-fw = { pkgs, ... }: {
    hardware.firmware = [
      pkgs.linux-firmware
      (withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages.firmware-slim5x))
    ];
  };
}
