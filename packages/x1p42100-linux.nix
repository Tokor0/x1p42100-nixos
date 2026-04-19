{
  # pkgs,
  lib,
  buildLinux,
  # linuxManualConfig,
  linuxPackagesFor,
  linux-src,
  ...
}:

  # Ubuntu defconfig references debian/canonical-certs.pem which doesn't
  # exist in NixOS. Clear the cert paths directly in the source since
  # buildLinux doesn't accept postPatch and structuredExtraConfig can't
  # represent empty strings (mkValue turns "" into literal '""').
  # patchedSrc = pkgs.applyPatches {
  #   name = "linux-src-patched";
  #   src = linux-src;
  #   postPatch = ''
  #     sed -i 's|CONFIG_SYSTEM_TRUSTED_KEYS=".*"|CONFIG_SYSTEM_TRUSTED_KEYS=""|' arch/arm64/configs/ubuntu_x1e_defconfig
  #     sed -i 's|CONFIG_SYSTEM_REVOCATION_KEYS=".*"|CONFIG_SYSTEM_REVOCATION_KEYS=""|' arch/arm64/configs/ubuntu_x1e_defconfig
  #   '';
  # };

linuxPackagesFor (buildLinux {
  version = "6.19.12";
  ignoreConfigErrors = true;
  defconfig = "defconfig";
  src = linux-src;

  # structuredExtraConfig = with lib.kernel; {
  # simpledrm grabs EFI framebuffer before msm can take over → blank screen.
  # NixOS common-config.nix sets DRM_SIMPLEDRM=y, so mkForce is needed.
  # DRM_SIMPLEDRM = lib.mkForce no;
  # };

})
