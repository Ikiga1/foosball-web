{ pkgs, lib, config, ... }:
with lib;
{
  # Define new options to easily turn on/off the module on any NixOs system and to configure it in a few lines.
  # Read their 'description' field to see what they are useful for.
  options.services.CWIFoosballWeb = {
    enable = mkEnableOption "server of foosball's website of CWI.";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "foosball.cwi.nl";
      description = "Domain of the current server.";
    };
    domainAPI = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "https://foosball.cwi.nl";
      description = "Url of the API: if the string is empty, it includes the API in the current website.";
    };
    nginxFakeCORS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instead of modifying the javascript urls (this often fails because of CORS security) create in nginx a proxy to fake CORS.";
    };
    phpMyAdminPassword = lib.mkOption {
      type = with types; nullOr str;
      default = null;
      example = "iAmALongPassword";
      description = "Password for the phpMyAdmin database (warning: it will be readable by all users in /nix/store/, use phpMyAdminPasswordFile if you want to avoid this issue).";
    };
    phpMyAdminPasswordFile = lib.mkOption {
      type = with types; nullOr path;
      default = null;
      example = "/var/lib/cwi-foosball-web/password.txt";
      description = "Password for the phpMyAdmin database.";
    };
    openFirewallPorts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the firewall port 80.";
    };
    # More advanced options
    appName = lib.mkOption {
      type = lib.types.str;
      default = "cwifoosball";
      description = "Name used for the php pool/systemd service, state directory…";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/cwi-foosball-web";
      description = "Folder containing the database.";
    };
    domainDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Fallback to this website if the clients asks for a non-existant domain (e.g. localhost).";
    };
  };

  # Configure the system depending on the options chosen by the end user
  # To get a list of all available options, use https://search.nixos.org/options or the nixpkg/nixos/nix manuals
  config =
    let
      cfg = config.services.CWIFoosballWeb; # this is long to type, let's define a shorter version
      usernamePhp = "cwi-foosball-php";
    in
      # Enable the configuration only if the module is enabled.
      lib.mkIf cfg.enable {
        ## Add pkgs to the list of packages
        nixpkgs.overlays = [
          (final: prev: {
            # callPackages allows stuff like `website.overrides { domainAPI = "https://foosball.cwi.nl"; }`
            cwi-foosball-web = final.callPackage ./website.nix {};
          })
        ];
        ## Configure the web server
        services.nginx = {
          enable = true;
          ### Otherwise it fails at startup (DNS are maybe not yet configured?)
          ### Unfortunalely if we use the proxyResolveWhileRunning it also fails because we need to explicit the
          ### list of dns server (stupid nginx) and some of them may be blacklisted. So instead we will just wait
          ### for the service to be restarted and use a static web page in `share/cwi-foosball-web/index.html`
          # resolver.addresses = [ "8.8.8.8" "192.16.184.42" ];
          # proxyResolveWhileRunning = true;
          virtualHosts.${cfg.domain} = {
            root =
              "${pkgs.cwi-foosball-web.override
                { domainAPI = if cfg.nginxFakeCORS then "" else cfg.domainAPI;}}/srv";
            default = cfg.domainDefault; # fallback to this domain
            # Enable php
            locations =
              if cfg.domainAPI != "" && cfg.nginxFakeCORS then
                {
                  # We don't need php, but we want to forward all the api calls, pretending to come from the
                  # right domain to avoid CORS
                  # WARNING: of course this will work only if you have enabled the VPN/if you are on the network
                  # containing cfg.domainAPI
                  "~ ^/(api|admin)/" = {
                    proxyPass = cfg.domainAPI;
                    extraConfig = ''
                      proxy_set_header Origin ${cfg.domainAPI};
                      proxy_hide_header Access-Control-Allow-Origin;
                      add_header Access-Control-Allow-Origin $http_origin;
                    '';
                  };
                }
              else
                {
                  "~ \.php$".extraConfig = ''
                    fastcgi_pass  unix:${config.services.phpfpm.pools.${cfg.appName}.socket};
                    fastcgi_index index.php;
                  '';
                };
          };
        };

        # Setup php
        services.phpfpm.pools.${cfg.appName} = {
          user = usernamePhp;
          settings = {
            pm = "dynamic";
            "listen.owner" = config.services.nginx.user;
            "pm.max_children" = 5;
            "pm.start_servers" = 2;
            "pm.min_spare_servers" = 1;
            "pm.max_spare_servers" = 3;
            "pm.max_requests" = 500;
          };
          phpEnv = {
            # $STATE_DIRECTORY is set by systemd to the state directory (can also work with user services this way)
            # i.e. to the folder containing the database. We just forward it to php here.
            "STATE_DIRECTORY" = cfg.dataDir;
            "PHP_LITE_ADMIN_PASSWORD" = mkIf (cfg.phpMyAdminPassword != null) cfg.phpMyAdminPassword;
            "PHP_LITE_ADMIN_PASSWORD_FILE" = mkIf (cfg.phpMyAdminPasswordFile != null) cfg.phpMyAdminPasswordFile;
          };
        };

        # Open the ports
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewallPorts [ 80 ];

        users.users.${usernamePhp} = {
          isSystemUser = true;
          group = usernamePhp;
        };
        users.groups.${usernamePhp} = {};
        
        systemd.tmpfiles.rules = [
          "d '${cfg.dataDir}' 0770 ${usernamePhp} root - -"
        ];

                
        # Create the database, expoiting the fact that phpfpm creates a new service named as follows:
        systemd.services."phpfpm-${cfg.appName}".serviceConfig = {
          # Can't use statedirectory + User = usernamePhp because phpfpm needs to be run as root to start
          # the socket.
          # Create the database (better: do it from the app directly) as the usernampPhp user.
          ExecStartPre = with pkgs; writeShellScript "create-db" ''
            mydb="${cfg.dataDir}/foos.db"
            if [ ! -f "$mydb" ]; then
              ${sqlite}/bin/sqlite3 "$mydb" ".read ${./create_database.sql}"
              chown ${usernamePhp} "$mydb"
            fi
          '';
        };

        
        ## fails: StateDirectory needs user = phpuser, but php needs user = root to create the socket.
        # Create the database, expoiting the fact that phpfpm creates a new service named as follows:
        # systemd.services."create-datadir-for-server-${cfg.appName}".serviceConfig = {
        #   User = "cwi-foosball-php";
        #   Group = "cwi-foosball-php";
          
        #   StateDirectory = cfg.appName; # systemd functionality to create a folder with the appropriate permissions
        #   # Create the database (better: do it from the app directly)
        #   ExecStartPre = with pkgs; writeShellScript "create-db" ''
        #     mydb="$STATE_DIRECTORY/foos.db"
        #     if [ ! -f "$mydb" ]; then
        #       ${sqlite}/bin/sqlite3 $mydb ".read ${./create_database.sql}"
        #     fi
        #   '';
        # };
      };
}
