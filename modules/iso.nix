{ inputs, ... }:
{
  flake.nixosConfigurations.slim5xISO = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      inputs.systemd-boot-installer.modules.nixos.live
      inputs.self.modules.nixos.x1p
      inputs.self.modules.nixos.qcom-fw
      inputs.self.modules.nixos.base
      (
        { pkgs, lib, ... }:
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
              "nouveau"
            ];
            consoleLogLevel = 7;
            kernelParams = [
              "boot.shell_on_fail"
              "drm.debug=0x1e"
            ];
            supportedFilesystems = {
              zfs = lib.mkForce false;
              cifs = lib.mkForce false;
            };
          };
          hardware.enableAllHardware = lib.mkForce false;
          isoImage.forceTextMode = true;
          boot.initrd.network.enable = true;
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
          networking = {
            hostName = "nixos";
            firewall.enable = false;
            networkmanager.enable = true;
            useDHCP = lib.mkForce true;
          };
          users.users.root.initialPassword = "nixos";
        }
      )
    ];
  };
}
