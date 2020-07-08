{
  description = "YunoHost flake";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; ref = "nixos-20.03"; };

  # Unstable tools.
  inputs.nixops = { type = "github"; owner = "NixOS"; repo = "nixops"; };
  inputs.nixops.inputs.nixpkgs.follows = "/nixpkgs";
  inputs.nixops-libvirtd = { type = "github"; owner = "nix-community"; repo = "nixops-libvirtd"; flake = false; };

  inputs.poetry2nix = { type = "github"; owner = "nix-community"; repo = "poetry2nix"; };

  # Upstream source tree(s).
  inputs.metronome-src = { type = "github"; owner = "maranda"; repo = "metronome"; flake = false; };

  inputs.ssowat-src = { type = "github"; owner = "YunoHost"; repo = "SSOwat"; ref = "buster-unstable"; flake = false; };
  inputs.moulinette-src = { type = "github"; owner = "YunoHost"; repo = "moulinette"; ref = "buster-unstable"; flake = false; };
  inputs.yunohost-src = { type = "github"; owner = "YunoHost"; repo = "yunohost"; ref = "buster-unstable"; flake = false; };
  inputs.yunohost-admin-src = { type = "github"; owner = "YunoHost"; repo = "yunohost-admin"; ref = "buster-unstable"; flake = false; };

  outputs = { self, nixpkgs, metronome-src, ssowat-src, moulinette-src, yunohost-src, yunohost-admin-src, ... }@inputs:
    let
      # Generate a user-friendly version numer.
      versions =
        let
          generateVersion = flake: builtins.substring 0 8 flake.lastModifiedDate;
        in
        {
          metronome = generateVersion metronome-src;
          ssowat = generateVersion ssowat-src;
          moulinette = generateVersion moulinette-src;
          yunohost = generateVersion yunohost-src;
          yunohost-admin = generateVersion yunohost-admin-src;
        };

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in
    {

      # A Nixpkgs overlay.
      overlay = final: prev: with final; {

        # Lua Packages

        luaPackages = final.lua.pkgs;
        lua = prev.lua.override {
          packageOverrides =
            let
              overridenPackages = import ./pkgs/lua/overrides.nix { pkgs = final.pkgs; };
              generatedPackages = callPackage ./pkgs/lua/package-set.nix { };
              finalPackages = lib.composeExtensions generatedPackages overridenPackages;
            in
            finalPackages;
        };

        # Python Packages

        python2Packages = final.python2.pkgs;
        python2 = prev.python2.override {
          packageOverrides = final: prev:
            with final; {

              moulinette = callPackage ./pkgs/moulinette { } {
                src = moulinette-src;
                version = versions.moulinette;
              };

              pytest-cov = buildPythonPackage rec {
                pname = "pytest-cov";
                version = "2.10.0";

                src = fetchPypi {
                  inherit pname version;
                  sha256 = "11xcy37zrcr02xxgym9wr2q79hwhwiyv19pxrcpm2lwfyk4rsqhs";
                };

                propagatedBuildInputs = [ pytest coverage ];

                doCheck = false;
              };

            };
        };

        # Packages

        nixops = inputs.nixops.defaultPackage.${system};
        nixops-libvirtd = import inputs.nixops-libvirtd { pkgs = final.pkgs; };

        inherit (inputs.poetry2nix.packages.${system})
          poetry poetry2nix;

        metronome = callPackage ./pkgs/metronome { } {
          src = metronome-src;
          version = versions.metronome;
        };
        ssowat = callPackage ./pkgs/ssowat { } {
          src = ssowat-src;
          version = versions.ssowat;
        };
        yunohost = callPackage ./pkgs/yunohost { } {
          src = yunohost-src;
          version = versions.yunohost;
        };
        yunohost-admin = callPackage ./pkgs/yunohost/admin.nix {
          fetchNodeModules = callPackage ./pkgs/yunohost/fetchNodeModules.nix { };
        } rec {
          src = yunohost-admin-src;
          version = versions.yunohost-admin;
          rngid = builtins.substring 0 4 version;
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgSet = nixpkgsFor.${system};
        in
        {
          inherit (pkgSet.luaPackages)
            luafilesystem luajson lualdap lrexlib-pcre luasocket
            luaexpat luaevent luasec lua-zlib luadbi;

          inherit (pkgSet.python2Packages)
            moulinette;

          inherit (pkgSet)
            metronome
            ssowat
            yunohost yunohost-admin;
        }
      );

      # Development environment
      devShell = forAllSystems (system:
        let
          pkgSet = nixpkgsFor.${system};
          # Not proud of how this looks, but it works, though it is prone to breakages and ugly
          nixopsWrapper = with pkgSet; symlinkJoin {
            name = "nixops-wrapper";
            paths = [ nixops nixops-libvirtd python3.pkgs.libvirt ];
          };
        in
        pkgSet.mkShell {
          buildInputs = [ nixopsWrapper ];
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.yunohost);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.hello =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];

          environment.systemPackages = [ pkgs.hello ];

          #systemd.services = { ... };
        };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: self.packages.${system} // {

        # Additional tests, if applicable.
        test =
          with nixpkgsFor.${system};
          stdenv.mkDerivation {
            name = "hello-test-${version}";

            buildInputs = [ hello ];

            unpackPhase = "true";

            buildPhase = ''
              echo 'running some integration tests'
              [[ $(hello) = 'Hello, world!' ]]
            '';

            installPhase = "mkdir -p $out";
          };

        # A VM test of the NixOS module.
        vmTest =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") {
            inherit system;
          };

          makeTest {
            nodes = {
              client = { ... }: {
                imports = [ self.nixosModules.hello ];
              };
            };

            testScript =
              ''
                start_all()
                client.wait_for_unit("multi-user.target")
                client.succeed("hello")
              '';
          };
      });

    };
}
