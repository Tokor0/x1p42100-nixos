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
    # Force-load USB ethernet modules so they're available immediately
    #initrd.kernelModules = [
    #  "r8152" # Realtek RTL8152/8153/7153 (most common USB-C adapters)
    #  "usbnet" # USB networking framework
    #];
    ## Additional USB ethernet drivers available on demand
    #initrd.availableKernelModules = [
    #  "cdc_ether" # CDC Ethernet (generic USB ethernet)
    #  "cdc_ncm" # CDC NCM (newer USB ethernet)
    #  "ax88179_178a" # ASIX (common in docks/adapters)
    #  "cdc_mbim" # Mobile broadband
    #  "dwc3" # USB3 DWC3 controller (if not built-in)
    #  "dwc3-qcom" # Qualcomm DWC3 platform driver
    #];
  };

  #hardware.enableAllHardware = lib.mkForce false;
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
