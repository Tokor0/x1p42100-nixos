{ ... }:
{
  flake.modules.nixos.qcom-fw = { pkgs, ... }: {
    hardware.firmware = [
      pkgs.linux-firmware
      (pkgs.callPackage (
        { runCommand, fetchFromGitHub, ... }:
        let
          slim5x = fetchFromGitHub {
            owner = "Tokor0";
            repo = "linux-firmware-x1p42100-lenovo-ideapad-slim5x";
            rev = "bccb601c19bb2e4e3320a9666114c039836c4b9c";
            hash = "sha256-x5Y75WCzl3JfdrL4pPw1xgzY/z/qK+DFfrMo1bh8Eh4=";
          };
        in
        runCommand "qcom-laptops-firmware" { } ''
          mkdir -p $out/lib/firmware/qcom/x1p42100/LENOVO/83HL
          cp ${slim5x}/qcom/x1p42100/LENOVO/83HL/{adsp_dtbs.elf,adspr.jsn,adsps.jsn,adspua.jsn,battmgr.jsn,cdsp_dtbs.elf,cdspr.jsn,qcadsp8380.mbn,qcav1e8380.mbn,qccdsp8380.mbn,qcdxkmsuc8380.mbn,qcdxkmsucpurwa.mbn,qcvss8380.mbn,qcvss8380_pa.mbn} \
            $out/lib/firmware/qcom/x1p42100/LENOVO/83HL/
        ''
      ) { })
    ];
  };
}
