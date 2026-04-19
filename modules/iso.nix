{ inputs, ... }:
{
  flake.nixosConfigurations.slim5xISO = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit (inputs) linux-src; };
    system = "aarch64-linux";
    modules = [
      inputs.systemd-boot-installer.modules.nixos.live
      inputs.self.modules.nixos.x1p
      inputs.self.modules.nixos.qcom-fw
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
              "fbcon=nodefer"
              "boot.shell_on_fail"
            ];
            supportedFilesystems = {
              zfs = lib.mkForce false;
              cifs = lib.mkForce false;
            };
          };
          services.openssh.enable = true;
          networking = {
            wireless.iwd.enable = true;
            hostName = "nixos";
            networkmanager.wifi.backend = "iwd";
          };
          environment.systemPackages = with pkgs; [
            neovim
            git
            impala
          ];
          nix.settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
        }
      )
    ];
  };
}
