{
  pkgs,
  lib,
  ...
}:
{

  boot = {
    blacklistedKernelModules = [ "qcom_q6v5_pas" ];
    supportedFilesystems = {
      zfs = lib.mkForce false;
      cifs = lib.mkForce false;
    };
  };

  hardware.enableAllHardware = lib.mkForce false;

  isoImage.forceTextMode = true;
  environment.systemPackages = with pkgs; [
    neovim
    git
  ];
}
