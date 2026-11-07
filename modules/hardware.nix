{
  flake.modules.nixos.hardware = {
    boot = {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          configurationLimit = 2;
        };
      };
      # The option boot.initrd.systemd.enable has been removed.
      # initrd = {
      # enable = true;
      # systemd.enable = true;
      # };
    };
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/root";
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-label/SYSTEM_DRV";
        fsType = "vfat";
      };
    };
  };
}
