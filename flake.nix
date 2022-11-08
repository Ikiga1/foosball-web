{
  description = "Configuration";

  # To easily generate a derivation per architecture
  inputs.flake-utils.url = "github:numtide/flake-utils";
  
  outputs = { self, nixpkgs, flake-utils }@attrs: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        system = system;
        overlays = [ self.overlays.default ];
      };
      lib = nixpkgs.lib;
    in
      {
        # Create a new package
        packages = {
          cwi-foosball-web = pkgs.cwi-foosball-web;
          # NixosConfiguration to test the module in a VM
          nixos-cwi-foosball-web = nixpkgs.lib.nixosSystem {
            system = system;
            modules = [
              self.nixosModule.default
              ({ pkgs, lib, config, ... }: {
                services.CWIFoosball ={
                  enable = true;
                  # Warning: will be readable by all users, better to use phpMyAdminPasswordFile instead
                  phpMyAdminPassword = "pleasechangeme";
                };
                # disable documentation to build smaller/quicker
                # (/nixos/modules/profiles/minimal.nix also disables x11 but it recompile stuff)
                documentation.enable = false;
                documentation.nixos.enable = false;
                programs.command-not-found.enable = false;
                users.extraUsers.root.password = "";
                system.stateVersion = "22.11";
              })
            ];
          };
          # NixosConfiguration to test the module in a VM, with an external API
          nixos-cwi-foosball-web-extern = nixpkgs.lib.nixosSystem {
            system = system;
            modules = [
              self.nixosModule.default
              ({ pkgs, lib, config, ... }: {
                services.CWIFoosball = {
                  enable = true;
                  domainAPI = "https://foosball.cwi.nl";
                };
                # disable documentation to build smaller/quicker
                # (/nixos/modules/profiles/minimal.nix also disables x11 but it recompile stuff)
                documentation.enable = false;
                documentation.nixos.enable = false;
                programs.command-not-found.enable = false;
                users.extraUsers.root.password = "";
                system.stateVersion = "22.11";
              })
            ];
          };
        };
        # Development shell (see doc in shellHook)
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            sqlite
            # Php is now packed with sqlite. To enable other extensions, see:
            # https://nixos.org/manual/nixpkgs/stable/#sec-php
            php
            (writeShellApplication {
              name = "my-test-vm";
              text = ''
                nix build .#nixos-cwi-foosball-web.config.system.build.vm && rm -f nixos.qcow2 && QEMU_NET_OPTS="hostfwd=tcp::8080-:80" ./result/bin/run-nixos-vm
              '';
            })
            (writeShellApplication {
              name = "my-test-vm-extern";
              text = ''
                nix build .#nixos-cwi-foosball-web-extern.config.system.build.vm && rm -f nixos.qcow2 && QEMU_NET_OPTS="hostfwd=tcp::8080-:80" ./result/bin/run-nixos-vm
              '';
            })
          ];
          shellHook = ''
            echo 'First make sure to create a database:'
            echo '$ mkdir db && sqlite3 db/foos.db ".read create_database.sql"'
            echo 'You can then start a debug server by typing in the root of this repository:'
            echo '$ php -S localhost:8000'
            echo 'Then go to http://localhost:8000'.
            echo 'By default the password of the admin section is "changeme"'
            echo 'To try to run the whole NixOs config in a VM (with nginx…) run:'
            echo '$ nix build .#nixos-cwi-foosball-web.config.system.build.vm && rm -f nixos.qcow2 && QEMU_NET_OPTS="hostfwd=tcp::8080-:80" ./result/bin/run-nixos-vm'
            echo 'Or:'
            echo '$ my-test-vm'
            echo 'for short. To test it with the external API, use `my-test-vm-extern` (make sure to enable the vpn)'
          '';
        };
      }
  ) // {
    # Add our packages to "pkgs"
    # https://discourse.nixos.org/t/how-to-consume-a-eachdefaultsystem-flake-overlay/19420/9
    overlays.default = final: prev: {
      # callPackages allows stuff like `website.overrides { domainAPI = "https://foosball.cwi.nl"; }`
      cwi-foosball-web = final.callPackage ./website.nix {};
    };

    # Main module to use
    nixosModule.default = {...}: {
      imports = [ ./foosballModule.nix ];
      nixpkgs.overlays = [ self.overlays.default ];
    };

    # NixOs configuration
    
  };
}
