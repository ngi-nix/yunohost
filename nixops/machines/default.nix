{ pkgs, ... }:

{
  nixpkgs.system = builtins.currentSystem;

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
