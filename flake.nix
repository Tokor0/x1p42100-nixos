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
          ];
        };
      };
    };
}
