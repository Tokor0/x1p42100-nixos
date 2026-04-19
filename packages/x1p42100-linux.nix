{
  buildLinux,
  linuxPackagesFor,
  linux-src,
  ...
}:

linuxPackagesFor (buildLinux {
  version = "6.19.12";
  ignoreConfigErrors = true;
  defconfig = "defconfig";
  src = linux-src;
})
