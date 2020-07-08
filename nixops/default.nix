{ self, ... }:

{
  network.description = "Nixops YunoHost setup";

  metronome = { ... }: {
    imports = [ ./metronome.nix ];
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
