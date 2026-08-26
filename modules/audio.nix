{ withSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # sound/soc/qcom/qdsp6/topology.c asks the firmware loader for
      #   qcom/<card->driver_name>/<card->name>-tplg.bin
      # driver_name is hardcoded "x1e80100" in sound/soc/qcom/x1e80100.c (even on
      # x1p42100), and card->name is the `model` of the `sound` node in
      # x1p42100-lenovo-ideapad-slim5x-oled.dts, so the request is for
      #   qcom/x1e80100/X1E80100-LENOVO-Ideapad-5-tplg.bin
      # and nothing ships that name. The Slim 5x has the same audio layout as the
      # ThinkPad T14s (2x WSA8845, WCD9385 headset, 2x VA DMIC, 3x DP), which is why
      # alsa-ucm-conf routes it to LENOVO-T14s.conf -- and the T14s entry in
      # linux-firmware is itself a symlink to X1E80100-Romulus-tplg.bin, which is
      # byte-for-byte what audioreach-topology builds from
      # X1E80100-LENOVO-Thinkpad-T14s.m4. So just install it under our name.
      #
      # A real copy rather than a symlink: hardware.firmware's compressFirmware pass
      # rewrites links, and symlink chains here are reported to misbehave at boot.
      packages.slim5x-audio-topology = pkgs.runCommand "slim5x-audio-topology" { } ''
        install -Dm444 \
          ${pkgs.linux-firmware}/lib/firmware/qcom/x1e80100/X1E80100-Romulus-tplg.bin \
          $out/lib/firmware/qcom/x1e80100/X1E80100-LENOVO-Ideapad-5-tplg.bin
      '';
    };

  flake.modules.nixos.slim5x =
    { pkgs, ... }:
    {
      # Merges with the firmware list in firmware.nix. hardware.firmware compresses
      # each package, so this lands as ...-tplg.bin.zst -- which is what the kernel
      # (FW_LOADER_COMPRESS_ZSTD) looks for. Not needed in the initrd: the topology
      # is requested late, at sound card probe, unlike the ADSP images.
      hardware.firmware = [
        (withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }: config.packages.slim5x-audio-topology
        ))
      ];
    };

  # In `base` rather than `gui` so the live ISO has audio too.
  flake.modules.nixos.base = {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    security.rtkit.enable = true;
  };
}
