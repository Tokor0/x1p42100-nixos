{
  pkgs,
  lib,
  ...
}:
{

  boot.supportedFilesystems = {
    zfs = lib.mkForce false;
    cifs = lib.mkForce false;
  };

  boot.blacklistedKernelModules = [ "qcom_q6v5_pas" ];

  hardware.enableAllHardware = lib.mkForce false;

  isoImage.forceTextMode = true;
  environment.systemPackages = with pkgs; [
    neovim
    git
  ];
}
