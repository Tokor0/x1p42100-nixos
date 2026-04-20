{
  description = "NixOS for the Qualcomm X1P (x1p42100) Lenovo IdeaPad Slim 5x";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    systemd-boot-installer = {
      url = "github:Tokor0/nixos-systemd-boot-installer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    linux-src = {
      url = "github:jglathe/linux_ms_dev_kit/jg/ubuntu-qcom-x1e-6.19.12-jg-1";
      flake = false;
    };
    slim5x-firmware = {
      url = "github:Tokor0/linux-firmware-x1p42100-lenovo-ideapad-slim5x/bccb601c19bb2e4e3320a9666114c039836c4b9c";
      flake = false;
    };
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-linux" ];
      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];
    };
}
