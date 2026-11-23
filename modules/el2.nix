{ inputs, withSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # EFI driver that performs Qualcomm "Secure Launch" with Microsoft's
      # tcblaunch.exe at ExitBootServices, leaving the kernel in EL2 instead of
      # under the Qualcomm hypervisor. Also builds sltest.efi.
      packages.slbounce = pkgs.stdenv.mkDerivation {
        pname = "slbounce";
        version = "5";
        src = inputs.slbounce-src;
        nativeBuildInputs = [
          pkgs.dtc
          (pkgs.buildPackages.python3.withPackages (ps: [ ps.beautifulsoup4 ]))
        ];
        # The arm64-sysreg-lib submodule ships only its generator; the headers
        # are produced from Arm's register XML.
        preBuild = ''
          (cd external/arm64-sysreg-lib && python ./run-build.py ${inputs.arm-sysreg-xml}/SysReg_xml_v86A-2020-06)
        '';
        makeFlags = [
          "CROSS_COMPILE=${pkgs.stdenv.cc.targetPrefix}"
          "all"
        ];
        installPhase = ''
          mkdir -p $out
          cp out/*.efi $out/
        '';
      };

      # EFI driver that starts the ADSP/CDSP at ExitBootServices. In EL2 there
      # is no hypervisor to boot them and Linux can only attach to DSPs that
      # are already running.
      packages.qebspil = pkgs.stdenv.mkDerivation {
        pname = "qebspil";
        version = "1";
        src = inputs.qebspil-src;
        # Tell AOSS that the DSP images run, as Linux does when it starts them
        # itself. Without it the ADSP goes silent after the first DDR
        # low-power entry in s2idle.
        patches = [
          "${inputs.x1e-sleep-src}/qebspil/0001-pil-send-AOSS-load_state-off-on-before-starting-ADSP.patch"
        ];
        nativeBuildInputs = [ pkgs.dtc ];
        makeFlags = [
          "CROSS_COMPILE=${pkgs.stdenv.cc.targetPrefix}"
          # The Makefile's own expansion of this macro breaks under Nix.
          # 0 = only start remoteprocs marked qcom,broken-reset (the EL2 DTB).
          "CFLAGS+=-DQEBSPIL_ALWAYS_START=0"
        ];
        installPhase = ''
          mkdir -p $out
          cp out/*.efi $out/
        '';
      };
    };

  flake.modules.nixos.x1p =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.x1p.el2;
      packages = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }: config.packages);
    in
    {
      options.x1p.el2 = {
        enable = lib.mkEnableOption ''
          an `el2` specialisation that boots Linux in EL2 via slbounce.
          Needed for KVM and for the SoC to reach its deep sleep states.
          The default boot entry is unaffected. Requires systemd-boot
        '';

        tcblaunch = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = lib.literalExpression "./tcblaunch.exe";
          description = ''
            Microsoft's signed `tcblaunch.exe`, which slbounce uses to take
            over EL2. It cannot be redistributed: copy it from your own
            Windows installation at `C:\Windows\System32\tcblaunch.exe`.

            Several revisions exist, and Microsoft's newest ones are reported
            not to work with slbounce. Check yours with `sltest.efi` before
            booting the `el2` entry.
          '';
        };

        firmware = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
          description = ''
            Remoteproc firmware for qebspil to start before the switch to EL2,
            keyed by the `firmware-name` the device tree uses. Find the names
            with `find /sys/firmware/devicetree -name firmware-name -exec cat {} + | xargs -0n1`;
            only those of `remoteproc` nodes are needed. If empty, qebspil is
            not installed and the DSPs (audio, battery status) stay off in EL2.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.tcblaunch != null;
            message = ''
              x1p.el2.enable requires x1p.el2.tcblaunch to point at a copy of
              C:\Windows\System32\tcblaunch.exe from your Windows installation.
            '';
          }
          {
            assertion = config.boot.loader.systemd-boot.enable;
            message = "x1p.el2.enable requires boot.loader.systemd-boot.";
          }
        ];

        specialisation.el2.configuration = {
          hardware.deviceTree.name = lib.mkForce (
            lib.removeSuffix ".dtb" config.hardware.deviceTree.name + "-el2.dtb"
          );
          boot.kernelParams = [
            "id_aa64mmfr0.ecv=1"
            # "deep" (PSCI SYSTEM_SUSPEND) is reported not to work in EL2, and
            # the SoC's low-power states are only reachable through s2idle.
            "mem_sleep_default=s2idle"
          ];
        };

        # systemd-boot loads everything in EFI/systemd/drivers for every entry.
        # That is safe: slbounce only switches to EL2, and qebspil only starts
        # the DSPs, when the entry's device tree is the -el2 one.
        boot.loader.systemd-boot.extraFiles = {
          "EFI/systemd/drivers/slbounceaa64.efi" = "${packages.slbounce}/slbounce.efi";
          # Run `sltest.efi tcblaunch.exe` from an EFI shell: a green line at
          # the top of the screen means Secure Launch works on this machine.
          "sltest.efi" = "${packages.slbounce}/sltest.efi";
        }
        # slbounce looks for tcblaunch.exe in the root of its own filesystem.
        # Guarded so that a missing file reaches the assertion above.
        // lib.optionalAttrs (cfg.tcblaunch != null) {
          "tcblaunch.exe" = "${cfg.tcblaunch}";
        }
        // lib.optionalAttrs (cfg.firmware != { }) {
          "EFI/systemd/drivers/qebspilaa64.efi" = "${packages.qebspil}/qebspilaa64.efi";
        }
        // lib.mapAttrs' (name: lib.nameValuePair "firmware/${name}") cfg.firmware;
      };
    };

  flake.modules.nixos.slim5x =
    { pkgs, lib, ... }:
    let
      firmware = withSystem pkgs.stdenv.hostPlatform.system (
        { config, ... }: config.packages.slim5x-firmware
      );
    in
    {
      x1p.el2.firmware = lib.genAttrs (map (f: "qcom/x1p42100/LENOVO/83HL/${f}") [
        "qcadsp8380.mbn"
        "adsp_dtbs.elf"
        "qccdsp8380.mbn"
        "cdsp_dtbs.elf"
      ]) (name: "${firmware}/lib/firmware/${name}");
    };
}
