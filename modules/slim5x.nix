{ inputs, ... }:
{
  flake.modules.nixos.slim5x = {
    imports = [
      inputs.self.modules.nixos.x1p
    ];
    hardware.deviceTree = {
      enable = true;
      name = "qcom/x1p42100-lenovo-ideapad-slim5x-oled.dtb";
    };
  };
}
