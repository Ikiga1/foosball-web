# foosball-web

Web application that keeps track of foosball ratings. This repository is a fork of https://github.com/Tombana/foosball-web that provides a flake module to ease the installation of the server. See also https://github.com/cwi-foosball/foosball for the configuration of the client machine (basically running automatically a browser pointing to the appropriate url).

## Installation

You can either manuall setup php+nginx (or apache) to install the website on any system (you can safely remove the `.nix` files in that case), or if you use NixOs with flake we provide a NixOs module. In your `flake.nix` just add an input:
```
inputs.cwi-foosball-web.url = "github:cwi-foosball/foosball-web";
```
(you can also clone this repository and use its local path, just be sure to update your flake on change, or to play with flake's arguments when rebuilding your configuration).

Then add this input in the `outputs`'s function arguments of the flake:
```
 outputs = { self, nixpkgs, cwi-foosball-web, ... }:
```
Then in your configuration you can load the module with
```
modules = [
  cwi-foosball-web.nixosModule.default
  # …
];
```
and enable it with like this (you can put this directly in the list of modules, or elsewhere in your configuration):
```
{
  services.CWIFoosballWeb = {
    enable = true;
  };
}
```

Then a server should run on port `80` (this port is automatically opened in the firewall, you can disable this with `services.CWIFoosballWeb.openFirewallPorts = false`.

## Options

The NixOs module provides a list of options (see `foosballModule.nix` for more details). For instance if you want to use another distant API server (for instance because you don't want to fork the database but you don't have write access to the server to update the UI) and disable the opening of the port 80 in the firewall:
```
{
  services.CWIFoosballWeb = {
    enable = true;
    domainAPI = "https://foosball.cwi.nl";
    openFirewallPorts = false;
  };
}
```
(this specific url won't work if you are not on the local CWI network or if you are not using a VPN)

You can also change the password of `phpMyAdmin` and the domain of the website:
```
{
  services.CWIFoosballWeb = {
    enable = true;
    domain = "https://foosball.mydomain.nl";
    phpMyAdminPassword = "myPassword";
  };
}
```
(Note that the password will be readable in `/nix/store` by all the users of the server. If this is a problem use `phpMyAdminPasswordFile` instead.)

See `foosballModule.nix` for a full list of options (TODO: export it as html file).


## Development

To try to develop the website, [install nix](https://nixos.org/download.html) (with flakes enabled), clone this repository, and run inside:
```
$ nix develop
```
This will bring you into a shell with php and sqlite installed. Then, run:
```
$ mkdir db && sqlite3 db/foos.db ".read create_database.sql"
```
to create the database, and start the server with:
```
$ php -S localhost:8000
```


This repository also provides the code to install a whole server via a NixOs module. To test the module, you can run (after `nix develop`):
```
$ my-test-vm
```
(that is a shortcut for `nix build .#nixos-cwi-foosball-web.config.system.build.vm && rm -f nixos.qcow2 && QEMU_NET_OPTS="hostfwd=tcp::8080-:80" ./result/bin/run-nixos-vm`). It will automatically start qemu with the server/database, and you can access the website at the url <https://localhost:8080>.
