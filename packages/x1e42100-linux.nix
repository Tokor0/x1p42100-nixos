{
  lib,
  fetchFromGitHub,
  buildLinux,
  linuxPackagesFor,
  ...
}:

linuxPackagesFor (buildLinux {
  #src = fetchFromGitHub {
  #  owner = "jglathe";
  #  repo = "linux_ms_dev_kit";
  #  rev = "jg/ubuntu-qcom-x1e-6.17";
  #  hash = "sha256-9r+ozCdQhvvS1MRH/j2sSZIMdq65y6uw5Ne2C/pNs8M=";
  #};
  #version = "6.17.0";
  src = fetchFromGitHub {
    owner = "jglathe";
    repo = "linux_ms_dev_kit";
    rev = "jg/ubuntu-qcom-x1e-6.18.y";
    hash = "sha256-qapDpQZxoJzDEVbv4YvW8HyzqxdX71sdybH6U6FqI9w=";
  };
  version = "6.18.3-jg-0";
})
