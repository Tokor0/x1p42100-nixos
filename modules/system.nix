{ inputs, ... }:
{
  flake.nixosConfigurations.slim5x-system = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      inputs.self.modules.nixos.slim5x
      inputs.self.modules.nixos.hardware
      inputs.self.modules.nixos.gui
    ];
  };
}
