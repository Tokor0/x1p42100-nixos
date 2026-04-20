{ ... }:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        helix
        git
        impala
      ];
      networking = {
        wireless.iwd.enable = true;
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
          plugins = [ ];
        };
      };
      system.stateVersion = "26.05";
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
    };
}
