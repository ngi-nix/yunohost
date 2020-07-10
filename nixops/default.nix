{ self, ... }:

{
  network.description = "Nixops YunoHost setup";

  yunohost = { pkgs, lib, ... }: {
    imports = builtins.attrValues self.nixosModules;

    # used to ripgrep
    environment.systemPackages = with pkgs; [ ripgrep ];

    services.openssh.permitRootLogin = lib.mkForce "prohibit-password";
    services.yunohost.enable = true;
  };

  defaults = { ... }: {
    imports = [ ./machines/libvirtd.nix ];

    deployment.libvirtd = {
      memorySize = 512;
      baseImageSize = 4;
    };

    nixpkgs.overlays = [ self.overlay ];
  };
}
