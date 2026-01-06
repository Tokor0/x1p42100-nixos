{
  description = "Minimal NixOS installation media";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { self, nixpkgs }:
    let
      pkgs-unpatched = nixpkgs.legacyPackages.aarch64-linux;
      nixpkgs-patched =
        (pkgs-unpatched.applyPatches {
          name = "nixpkgs-patched";
          src = nixpkgs;
          patches = [
            (pkgs-unpatched.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/commit/de1fdb6310af8f70c98746ba4550dc2799a03621.patch";
              hash = "sha256-brqJxblmqWFAk8JgxmxXeHoiaWiQtsCsOzht/WlH5eE=";
            })
            ./nixpkgs-efi-shell.patch
          ];
        }).overrideAttrs
          { allowSubstitutes = true; };
    in
    {
      nixosConfigurations = {
        slim5xISO = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            "${nixpkgs-patched}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./iso.nix
            ./modules/x1p42100.nix
            {
              nix = {
                settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
              };
              networking.networkmanager.enable = true;
            }
          ];
        };
        slim5xSystem = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./modules/x1p42100.nix
            (
              { pkgs, lib, ... }:
              {
                boot.loader.efi = {
                  canTouchEfiVariables = true;
                };
                boot.loader.systemd-boot = {
                  enable = true;
                  configurationLimit = 2;
                };
                boot.initrd = {
                  enable = true;
                  systemd.enable = true;
                };
                hardware.enableRedistributableFirmware = true;
                fileSystems = {
                  "/" = {
                    device = "/dev/disk/by-path/platform-1bf8000.pci-pci-0006:01:00.0-nvme-1-part6";
                    fsType = "ext4";
                  };
                  "/boot" = {
                    device = "/dev/disk/by-label/SYSTEM_DRV";
                    fsType = "vsfat";
                  };
                };

                environment.systemPackages = with pkgs; [
                  neovim
                  git
                ];

                networking.hostName = "system";
                networking.networkmanager = {
                  enable = true;
                  plugins = [ ];
                };

                hardware.bluetooth.enable = true;

                programs = {
                  firefox.enable = true;
                  hyprland.enable = true;
                };
                nix = {
                  settings.experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                };
              }
            )
          ];

        };
      };
    };
}
