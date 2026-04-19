# NixOS for the Quallcomm X1P (x1p42100) based Lenovo IdeaPad Slim 5x laptop

This project provides a flake that provides the ubuntu-qcom kernel for use in NixOS.

## Build instructions

Development happens in a Nix environment. The build times are very long as the kernel is built from scratch. Building should be avoided in favor of less time consuming testing and assessment methods.

ISO build
: nix build .#nixosConfigurations.slim5xISO.config.system.build.isoImage

## systemd-boot for the ISO

The ISO currently uses systemd-boot, opposed to the default GRUB behavior in the NixOS ISO module.

## Current affairs

- [x] The ISO builds
- [x] The ISO boots to the systemd-boot menu
- [ ] The ISO boots into linux succesfully
  - The boot process starts, some logs are printed out on the screen, after which the screen goes blank.

# References

[ubuntu-qcom]: /url github.com/jglathe/linux_ms_dev_kit
