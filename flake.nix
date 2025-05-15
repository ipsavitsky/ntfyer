{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem ( system:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            zig_0_14
            libnotify
            glib
            gdk-pixbuf
            pkg-config

            valgrind
            zls
          ];
        };
      };

      packages = rec {
        default = ntfyer;
        ntfyer = pkgs.stdenvNoCC.mkDerivation rec {
          name = "ntfyer";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            zig_0_14.hook
            libnotify
            glib
            gdk-pixbuf
            pkg-config
          ];
        };
      };
    }) // {
      nixosModules = {
        ntfyer = import ./nix/module.nix { ntfyer = self.packages; };
      };
    };
}
