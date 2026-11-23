{ inputs, ... }:
{
  # Experimental: lets the SoC collapse CX and put DDR in self-refresh during
  # s2idle when booted in EL2. Follows jglathe/linux_ms_dev_kit issue #102
  # (this laptop) and justririll/x1e-sleep (where most pieces come from).
  flake.modules.nixos.x1p =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.x1p.el2.deepSleep;
      kernel = config.boot.kernelPackages.kernel;

      # The kernel config has no HOTPLUG_PCI_PCIE, so pci_bridge_d3_possible()
      # is false for the hot-plug capable root ports even with
      # pcie_port_pm=force. The port then stays in D0, the controller never
      # sends PME_Turn_Off, and after CX collapse the Wi-Fi link is dead.
      # Allow D3 on that one root port only.
      wifiPortD3 = pkgs.writeText "wifi_port_d3.c" ''
        // SPDX-License-Identifier: GPL-2.0
        #include <linux/module.h>
        #include <linux/pci.h>

        static int dom = 4;
        module_param(dom, int, 0444);

        static int set_bridge_d3(bool on)
        {
        	struct pci_dev *p = pci_get_domain_bus_and_slot(dom, 0, PCI_DEVFN(0, 0));

        	if (!p)
        		return -ENODEV;
        	p->bridge_d3 = on;
        	pr_info("wifi_port_d3: %s bridge_d3=%d\n", pci_name(p), on);
        	pci_dev_put(p);
        	return 0;
        }

        static int __init wifi_port_d3_init(void)
        {
        	return set_bridge_d3(true);
        }

        static void __exit wifi_port_d3_exit(void)
        {
        	set_bridge_d3(false);
        }

        module_init(wifi_port_d3_init);
        module_exit(wifi_port_d3_exit);
        MODULE_LICENSE("GPL");
      '';

      sleepModules = pkgs.stdenv.mkDerivation {
        pname = "x1-el2-sleep-modules";
        version = kernel.version;
        dontUnpack = true;
        nativeBuildInputs = kernel.moduleBuildDependencies;
        preBuild = ''
          cp ${inputs.x1e-sleep-src}/modules/el1tmr/el1tmr.c .
          cp ${inputs.x1e-sleep-src}/modules/aoss-cxsd-only/aoss_cxsd_only.c .
          cp ${wifiPortD3} wifi_port_d3.c
          echo 'obj-m := el1tmr.o aoss_cxsd_only.o wifi_port_d3.o' > Makefile
        '';
        # kbuild's modules_install signs each module and writes the
        # <module>.ko.cer certificate that aggregateModules expects.
        makeFlags = config.boot.kernelPackages.kernelModuleMakeFlags ++ [
          "-C"
          "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          "M=$(PWD)"
          "INSTALL_MOD_PATH=${placeholder "out"}"
        ];
        buildFlags = [ "modules" ];
        installTargets = [ "modules_install" ];
      };

      setup = pkgs.writeShellScript "x1-el2-sleep-setup" ''
        # Refuses to load unless the kernel itself runs in EL2 (VHE).
        modprobe el1tmr

        # aoss_cxsd_only fails until the AOSS QMP device has probed.
        for _ in $(seq 30); do
          modprobe aoss_cxsd_only && break
          sleep 1
        done

        ${lib.optionalString (cfg.wifiPciDomain != null) ''
          port=/sys/bus/pci/devices/${lib.fixedWidthString 4 "0" (toString cfg.wifiPciDomain)}:00:00.0
          for _ in $(seq 30); do
            [ -e "$port" ] && break
            sleep 1
          done
          modprobe wifi_port_d3 dom=${toString cfg.wifiPciDomain}
        ''}

        # These interconnect providers used to wait for crypto@1dfa000 (no
        # driver in 7.3) before sync_state, so their boot-time maximum
        # bandwidth votes were never released. jg-2 disables that node, so
        # this should now be a no-op; kept as a fallback until verified.
        for p in /sys/devices/platform/interconnect-1 /sys/devices/platform/soc@0/1700000.interconnect; do
          for _ in $(seq 60); do
            [ -e "$p/state_synced" ] && break
            sleep 1
          done
          [ "$(cat "$p/state_synced" 2>/dev/null)" = 1 ] || echo 1 > "$p/state_synced"
        done

        for d in ${lib.escapeShellArgs cfg.disableWakeup}; do
          [ -e "$d/power/wakeup" ] && echo disabled > "$d/power/wakeup"
        done
        exit 0
      '';
    in
    {
      options.x1p.el2.deepSleep = {
        enable = lib.mkEnableOption ''
          experimental deep s2idle in the `el2` specialisation: CX collapse
          and DDR self-refresh. Loads the `el1tmr` module, which must be
          removed (`rmmod el1tmr`) before starting KVM guests
        '';

        wifiPciDomain = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.unsigned;
          default = null;
          description = ''
            PCI domain of the root port the Wi-Fi card sits behind. That port
            is allowed to enter D3 so the link is re-established on resume.
          '';
        };

        disableWakeup = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Devices whose wakeup is turned off. Once the SoC really collapses
            these wake it again within seconds. The power key and keyboard
            keep working as wake sources.
          '';
        };
      };

      config = lib.mkIf (config.x1p.el2.enable && cfg.enable) {
        x1p.el2.deepSleep.disableWakeup = [
          "/sys/bus/platform/devices/a000000.usb"
          "/sys/bus/platform/devices/a200000.usb"
          "/sys/bus/platform/devices/a400000.usb"
          "/sys/bus/platform/devices/a600000.usb"
          "/sys/bus/platform/devices/a800000.usb"
          # Lid switch. Opening the lid no longer wakes the machine.
          "/sys/devices/platform/gpio-keys"
        ];

        specialisation.el2.configuration = {
          boot.extraModulePackages = [ sleepModules ];
          boot.kernelParams = [ "pcie_port_pm=force" ];

          systemd.services.x1-el2-sleep = {
            description = "Prepare deep s2idle in EL2";
            wantedBy = [ "multi-user.target" ];
            path = [
              pkgs.kmod
              pkgs.coreutils
            ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = setup;
            };
          };

          # Only the booted DTB: the overlay needs a base built with symbols.
          hardware.deviceTree.filter = baseNameOf config.hardware.deviceTree.name;
          hardware.deviceTree.overlays = [
            {
              name = "x1-el2-sleep";
              dtsText = ''
                /dts-v1/;
                /plugin/;

                / {
                	compatible = "qcom,x1p42100";
                };

                &{/cpus/domain-idle-states} {
                	/* ACPI \_SB.SYSM._LPI "platform.SS1" */
                	domain_ss1: domain-sleep-1 {
                		compatible = "domain-idle-state";
                		arm,psci-suspend-param = <0x02000154>;
                		entry-latency-us = <250>;
                		exit-latency-us = <250>;
                		min-residency-us = <7500>;
                	};
                };

                /*
                 * The firmware denies both system states unless the clusters
                 * request CL5. Suspend only: CL5 from runtime idle trips the
                 * DC ZVA erratum, and DRIPS from runtime idle hangs the SoC.
                 */
                &cluster_cl5 {
                	system-state;
                };

                &domain_ss3 {
                	system-state;
                };

                &cluster_pd0 {
                	domain-idle-states = <&cluster_cl4>, <&cluster_cl5>;
                };

                &cluster_pd1 {
                	domain-idle-states = <&cluster_cl4>, <&cluster_cl5>;
                };

                &system_pd {
                	domain-idle-states = <&domain_ss1>, <&domain_ss3>;
                };
              '';
            }
          ];
        };
      };
    };

  flake.modules.nixos.slim5x.x1p.el2.deepSleep = {
    wifiPciDomain = 4;
    # Touchpad: wakes the machine when the lid is closed onto it.
    disableWakeup = [ "/sys/bus/i2c/devices/1-0038" ];
  };
}
