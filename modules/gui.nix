{ inputs, ... }:
{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.base ];
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
      ];
      networking.hostName = "qcom-nixos";
      hardware.bluetooth.enable = true;
      programs = {
        firefox.enable = true;
        hyprland.enable = true;
      };
      services.openssh.enable = true;
    };
}
