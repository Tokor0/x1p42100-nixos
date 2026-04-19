{
  description = "Minimal NixOS installation media";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systemd-boot-installer = {
      url = "github:Tokor0/nixos-systemd-boot-installer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    linux-src = {
      url = "github:jglathe/linux_ms_dev_kit/jg/ubuntu-qcom-x1e-6.19.12-jg-1";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      linux-src,
      ...
    }@inputs:
    let
      pkgs-unpatched = nixpkgs.legacyPackages.aarch64-linux;
      nixpkgs-patched =
        (pkgs-unpatched.applyPatches {
          name = "nixpkgs-patched";
          src = nixpkgs;
          patches = [
            ./nixpkgs-devicetree.patch
            ./nixpkgs-efi-shell.patch
          ];
        }).overrideAttrs
          { allowSubstitutes = true; };
    in
    {
      nixosModules = {
        qcom-fw = ./modules/firmware.nix;
        x1p = ./modules/x1p42100.nix;
      };
      nixosConfigurations = {
        slim5xISO = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs linux-src; };
          system = "aarch64-linux";
          modules = [
            inputs.systemd-boot-installer.modules.nixos.live
            ./iso.nix
            ./modules/x1p42100.nix
            {
              nix = {
                settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
              };
            }
          ];
        };
        slim5xSystem = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs linux-src; };
          system = "aarch64-linux";
          modules = [
            ./modules/x1p42100.nix
            ./configuration.nix
          ];

        };
      };
    };
}
