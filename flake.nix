{
  description = "NixOS for the Qualcomm X1P (x1p42100) Lenovo IdeaPad Slim 5x";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    systemd-boot-installer = {
      url = "github:Tokor0/nixos-systemd-boot-installer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    linux-src = {
      url = "github:jglathe/linux_ms_dev_kit/jg/ubuntu-qcom-x1e-7.3.3-jg-2";
      flake = false;
    };
    slim5x-firmware = {
      url = "github:Tokor0/linux-firmware-x1p42100-lenovo-ideapad-slim5x";
      flake = false;
    };
    # EL2 boot (modules/el2.nix). Both vendor gnu-efi and dtc as submodules.
    slbounce-src = {
      url = "git+https://github.com/TravMurav/slbounce?ref=refs/tags/v5&submodules=1";
      flake = false;
    };
    qebspil-src = {
      url = "git+https://github.com/stephan-gh/qebspil?ref=refs/tags/v1&submodules=1";
      flake = false;
    };
    # EL2 deep sleep (modules/el2-sleep.nix): helper modules, qebspil patch.
    x1e-sleep-src = {
      url = "github:justririll/x1e-sleep/4e84b60eb073e76f8f7190a168c90c0d869b1326";
      flake = false;
    };
    # Input to slbounce's arm64-sysreg-lib header generator.
    arm-sysreg-xml = {
      url = "https://developer.arm.com/-/media/developer/products/architecture/armv8-a-architecture/2020-06/SysReg_xml_v86A-2020-06.tar.gz";
      flake = false;
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-linux" ];
      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];
    };
}
