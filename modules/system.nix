{ inputs, ... }:
{
  flake.nixosConfigurations.slim5xSystem = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      inputs.self.modules.nixos.x1p
      inputs.self.modules.nixos.qcom-fw
      inputs.self.modules.nixos.hardware
      inputs.self.modules.nixos.gui
    ];
  };
}
