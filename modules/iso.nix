{ inputs, ... }:
{
  flake = {
    modules.nixos.iso =
      { lib, ... }:
      {
        boot = {
          # The live ISO must re-detect the USB boot stick in the initrd to
          # mount /iso (the squashfs source). `x1p` sets includeDefaultModules =
          # false, so only explicitly-listed modules are in the initrd -- and the
          # USB-A port's PHY/Type-C chain was incomplete, leaving the controller
          # stuck in dual-role (never switched to host), so the stick never
          # enumerated and the initrd hung on "waiting for NIXOS_ISO".
          # These are the USB-stack modules tokyo loads in stage-2 but the initrd
          # lacked (notably phy_qcom_qmp_usb -- the USB3 PHY -- and qcom_glink_smem
          # which pmic_glink needs).
          initrd.availableKernelModules = [
            "phy_qcom_qmp_usb"
            "phy_nxp_ptn3222"
            "qcom_glink_smem"
            "gpio_sbu_mux"
            "typec_ucsi"
            "ucsi_glink"
          ];

          kernelParams = [ "regulator_ignore_unused" ];

          loader = {
            systemd-boot.enable = lib.mkForce true;
            grub = {
              enable = lib.mkForce false;
              memtest86.enable = lib.mkForce false;
            };
          };
          supportedFilesystems = {
            zfs = lib.mkForce false;
            cifs = lib.mkForce false;
          };
        };
        hardware = {
          enableAllHardware = lib.mkForce false;
          enableRedistributableFirmware = lib.mkForce false;
        };

        # Mirror the official NixOS installer (profiles/installation-device.nix):
        # auto-login as a passwordless `nixos` user who can sudo without a
        # password. The `live` module ships no users, so without this the getty
        # drops to a login prompt with no valid credentials.
        services.getty.autologinUser = lib.mkDefault "nixos";
        users.users.nixos = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          # Empty password: no prompt on autologin, and `passwd` still works.
          initialHashedPassword = "";
        };
        users.users.root.initialHashedPassword = "";
        security.sudo.wheelNeedsPassword = false;
        isoImage = {
          forceTextMode = false;
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
