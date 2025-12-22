{
  lib,
  fetchFromGitHub,
  buildLinux,
  linuxPackagesFor,
  ...
}:

linuxPackagesFor (buildLinux {
  src = fetchFromGitHub {
    owner = "jglathe";
    repo = "linux_ms_dev_kit";
    #rev = "0c67f2fcc1830453719b576fa6fa8acd8c290145";
    rev = "jg/ubuntu-qcom-x1e-6.17";
    hash = "sha256-9r+ozCdQhvvS1MRH/j2sSZIMdq65y6uw5Ne2C/pNs8M=";
  };
  version = "6.17.0";
})
