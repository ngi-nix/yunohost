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
      overlay = final: prev:
        with final;
        {

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

                moulinette = callPackage ./pkgs/moulinette
                  { } {
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

          metronome = callPackage ./pkgs/metronome
            { } {
            src = metronome-src;
            version = versions.metronome;
          };
          ssowat = callPackage ./pkgs/ssowat
            { } {
            src = ssowat-src;
            version = versions.ssowat;
          };
          yunohost = callPackage ./pkgs/yunohost
            { } {
            src = yunohost-src;
            version = versions.yunohost;
          };
          yunohost-admin =
            callPackage ./pkgs/yunohost/admin.nix
              {
                nodejs = nodejs-12_x;
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

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.yunohost);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules = {
        metronome = import ./modules/metronome.nix;
        yunohost = import ./modules/yunohost.nix;
      };

      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Hardcoded
        modules = [
          # VM-specific configuration
          ({ modulesPath, pkgs, ... }: {
            imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
            virtualisation.qemu.options = [ "-m 2G" "-vga virtio" ];
            environment.systemPackages = with pkgs; [ st unzip ripgrep chromium ];

            networking.hostName = "qemu_virtual";
            networking.networkmanager.enable = true;

            services.xserver.enable = true;
            services.xserver.layout = "us";
            services.xserver.windowManager.i3.enable = true;
            services.xserver.displayManager.lightdm.enable = true;

            users.mutableUsers = false;
            users.users.user = {
              password = "user"; # yes, very secure, I know
              createHome = true;
              isNormalUser = true;
              extraGroups = [ "wheel" ];
            };
          })

          # Flake specific support
          ({ ... }: {
            imports = builtins.attrValues self.nixosModules;
            nixpkgs.overlays = [ self.overlay ];
          })

          # System Configuration
          ({ ... }: {
            services.yunohost.enable = true;
          })
        ];
      };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: self.packages.${system} // {

        yunohost-command-line =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") {
            inherit system;
          };
          with nixpkgsFor.${system};
          with self.packages.${system};

          makeTest {
            nodes = {
              machine = { ... }: {
                imports = builtins.attrValues self.nixosModules;
                services.yunohost.enable = true;

                nixpkgs.overlays = [ self.overlay ];
              };
            };

            testScript =
              let
                commands = [
                  "--help" "--version"
                  "user list"
                  # "user create test" "user delete test" "user info test" "user group list" # reliance on openldap being setup fully?
                  "domain list" # reliance on openldap.service
                  "app list" # needs /etc/yunohost/apps/
                  "backup list"
                  "settings list"
                  "service status" # fails due to different service names
                  "firewall list"
                  "dyndns --help" "dyndns installcron" # needs /etc/cron.d/yunohost-dyndns
                  "tools versions" "tools migrations list" # fails due to reliance on /etc/os-release
                  "hook --help" # not sure about hook names
                  "log list"
                  "diagnosis list"
                ];
              in
              ''
                start_all()

                ${lib.concatMapStringsSep "\n"
                  (cmd: ''
                    print("Running `yunohost ${cmd}`")
                    machine.execute("yunohost ${cmd}")
                  '')
                  commands}

                machine.shutdown()
              '';
          };

      });

    };
}
