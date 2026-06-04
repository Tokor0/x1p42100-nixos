{ inputs, ... }:
{
  flake = {
    modules.nixos.iso =
      { lib, ... }:
      {
        boot = {
          loader = {
            systemd-boot.enable = lib.mkForce true;
            grub = {
              enable = lib.mkForce false;
              memtest86.enable = lib.mkForce false;
            };
          };
          blacklistedKernelModules = [
            "qcom_q6v5_pas"
          ];
          supportedFilesystems = {
            zfs = lib.mkForce false;
            cifs = lib.mkForce false;
          };
        };
        hardware = {
          enableAllHardware = lib.mkForce false;
          enableRedistributableFirmware = lib.mkForce false;
        };
        isoImage = {
          forceTextMode = true;
          squashfsCompression = "zstd";
        };
      };

    nixosConfigurations.slim5x-iso = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        inputs.systemd-boot-installer.modules.nixos.live
        inputs.self.modules.nixos.slim5x
        inputs.self.modules.nixos.iso
        inputs.self.modules.nixos.base
      ];
    };
  };
}
