{
  pkgs,
  lib,
  ...
}:
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
    consoleLogLevel = 7; # Maximum kernel log verbosity
    kernelParams = [
      "fbcon=nodefer" # Don't defer fbcon — show output immediately
      "boot.shell_on_fail"
    ];
    supportedFilesystems = {
      zfs = lib.mkForce false;
      cifs = lib.mkForce false;
    };
  };

  hardware.firmware = [
    pkgs.linux-firmware
    (pkgs.callPackage ./modules/firmware.nix { })
  ];

  # SSH for remote debugging (blank screen)
  # Login: ssh nixos@<ip> — password: nixos
  services.openssh = {
    enable = true;
  };
  # Networking
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
}
