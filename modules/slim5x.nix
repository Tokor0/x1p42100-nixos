{ inputs, ... }:
{
  flake.modules.nixos.slim5x =
    { lib, pkgs, ... }:
    {
      imports = [
        inputs.self.modules.nixos.x1p
      ];
      hardware.deviceTree = {
        enable = true;
        name = "qcom/x1p42100-lenovo-ideapad-slim5x-oled.dtb";
        # Only this board's DTBs; the el2 entry narrows it to its own DTB.
        filter = lib.mkDefault "x1p42100-lenovo-ideapad-slim5x-*.dtb";
        overlays = [
          {
            # The board DT pins the panel's 3.3 V rail on (regulator-always-on),
            # so the panel electronics stay powered through suspend: ~0.9 W of
            # a 1.2 W s2idle drain, measured in EL2. Hand the rail to the panel
            # driver, as nearly every other X1 laptop DT does. Overlays cannot
            # delete a property, so the regulator is replaced by a copy.
            # Compiled with plain dtc: NixOS' dtsText path needs the kernel's
            # dev output for include paths.
            name = "slim5x-edp-rail-switchable";
            dtboFile = pkgs.runCommand "slim5x-edp-rail-switchable.dtbo" {
              nativeBuildInputs = [ pkgs.dtc ];
            } "dtc -@ -I dts -O dtb -o $out ${./slim5x-edp-rail.dtso}";
          }
        ];
      };
    };
}
