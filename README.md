# NixOS for x1p42100

NixOS for the Qualcomm Snapdragon X Plus (x1p42100) based _Lenovo Ideapad Slim
5x_.

# Installation

_Note: This exact installation process has yet to be tested._

### Step 1: Building the installer ISO

Currently, a binary release of the ISO is not available, and you will have to
compile it yourself. Since cross-compiling is not currently supported, the ISO
must be built on the device itself or another ARM64 based system.

The easiest way to build the ISO on Windows is probably to use WSL with
[Nix installed](https://nixos.org/download/#nix-install-windows).

Once you have Nix installed on some ARM64 system, you can use the following
commands to build the ISO:

```
git clone git@github.com:Tokor0/x1p42100-nixos
cd x1p42100-nixos
nix build --extra-experimental-features 'nix-command flakes' .#nixosConfigurations.slim5x-iso.config.system.build.isoImage
```

Then, flash the ISO onto a USB-**A** device. Note that USB-C will not work.

### Step 2: Device preparation

BitLocker must be turned off. To do this, search for "Device encryption
settings" in the start menu, and turn "Device encryption" off.

Next, create a new partition for the Linux root filesystem. To do this you
probably want to shrink the Windows partition. Search for "Create and format
hard disk partitions" in the start menu and shrink the (C:) partition to your
liking. Then, create the new partition in the free space.

_Note: The default EFI partition is very small, and you may want to extend it.
This may break the Windows installation._

### Step 3: Booting the ISO

Reboot the laptop, and enter the UEFI menu by pressing F2 when the boot logo
screen is showing.

Go to "Security > Secure Boot" and disable it. Then exit and save the changes.

Connect the previously flashed bootable USB drive to the laptop and enter the
boot menu by pressing F12 at boot and select the drive.

### Step 4: Installation

First, connect to Wi-Fi using `nmtui`.

Enter a root shell and format the previously created partition:

```
sudo -i
mkfs.ext4 -L root /dev/nvme0n1pX
```

Mount the root filesystem and the EFI partition:

```
mount /dev/disk/by-label/root /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/SYSTEM_DRV /mnt/boot
```

Finally, run `nixos-install`:

```
nixos-install --root /mnt --no-channel-copy --no-root-password --flake git@github.com:Tokor0/x1p42100-nixos#slim5x-system
```

Now, NixOS is installed, and you should be able to boot into it by rebooting and
selecting the appropriate boot option.

After booting, you can login with the username `user` and password `arm`. You
probably want to change the password using `passwd`. You can connect to Wi-Fi
using `nmtui`.

By default, some programs are installed. You can start Hyprland using
`start-hyprland`. In Hyprland, press Super-Q to open a terminal emulator, or
Super-Space to open a program launcher. Here, Super refers to the Windows key.

# Flake structure

The flake is organized as a set of [dendritic](https://github.com/mightyiam/dendritic)
[flake-parts](https://flake.parts) modules. Every file under `modules/` is
imported automatically via [`import-tree`](https://github.com/vic/import-tree),
and each one contributes to `flake.modules.nixos.*`, a collection of reusable
NixOS modules:

- `x1p` — core hardware support shared by every X1P-42-100 device: the custom
  [jglathe](https://github.com/jglathe/linux_ms_dev_kit) kernel, initrd modules
  and GPU firmware. (`modules/x1p42100.nix`)
- `slim5x` — `x1p` plus the Slim 5x device tree and Lenovo firmware.
  (`modules/slim5x.nix`, `modules/firmware.nix`)
- `base` — minimal common configuration (networking, Nix settings, base
  packages). (`modules/base.nix`)
- `gui` — a `base` desktop with a `user` account, Hyprland and Firefox.
  (`modules/gui.nix`)
- `hardware` — bootloader and filesystem layout for the installed system.
  (`modules/hardware.nix`)
- `iso` — installer-specific overrides (systemd-boot, autologin, USB initrd
  modules). (`modules/iso.nix`)

These are composed into two `nixosConfigurations`:

- `slim5x-iso` — the live installer ISO (`slim5x` + `iso` + `base`).
- `slim5x-system` — the installed system (`slim5x` + `hardware` + `gui`).

# Using in your own NixOS configuration

Add this flake as an input and import one of the exposed modules. For most
purposes you want `slim5x`, which pulls in the kernel, initrd modules, device
tree and firmware needed to run the Slim 5x:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    x1p42100-nixos.url = "github:Tokor0/x1p42100-nixos";
  };

  outputs = { nixpkgs, x1p42100-nixos, ... }: {
    nixosConfigurations.my-slim5x = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        x1p42100-nixos.modules.nixos.slim5x
        # ... your own configuration.nix, hardware bits, etc.
      ];
    };
  };
}
```

If your device is a different X1P-42-100 machine (not the Slim 5x), import the
lower-level `x1p` module instead and supply your own `hardware.deviceTree`
 (See [jglathe's repo](https://github.com/jglathe/linux_ms_dev_kit/tree/jg/ubuntu-qcom-x1e-6.19.14-jg-3/arch/arm64/boot/dts/qcom) for other readily available DTs) settings and firmware.

## Related repos

This project relies heavily on work by others.

- [jglathe's Ubuntu kernel for Snapdragon X laptops](https://github.com/jglathe/linux_ms_dev_kit)
- [kurugzgy's x1e NixOS config](https://github.com/kuruczgy/x1e-nixos-config)
