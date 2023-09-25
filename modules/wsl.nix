{ name, ... }:

{
  imports = [
    ./wsl/wsl-distro.nix
    ./wsl/interop.nix
  ];
  
  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "dav";
    startMenuLaunchers = true;
    
    wslConf.network.hostname = name;
  };
}
