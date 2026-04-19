{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./hardware.nix ];
  users.users = {
    root.initialPassword = "root";

    user = {
      isNormalUser = true;
      initialPassword = "arm";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
  };
  environment.systemPackages = with pkgs; [
    kitty
    wofi
    neovim
    git
  ];

  networking.hostName = "qcom-nixos";
  networking.networkmanager = {
    enable = true;
    plugins = [ ];
  };

  hardware.bluetooth.enable = true;

  programs = {
    firefox.enable = true;
    hyprland = {
      enable = true;
      # package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # portalPackage =
      #   inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };

  services.openssh.enable = true;

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = "26.05";
}
