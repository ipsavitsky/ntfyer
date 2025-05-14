{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zon2nix.url = "github:jcollie/zon2nix";
  };

  outputs = { self, nixpkgs, zig-overlay, zon2nix }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells.x86_64-linux = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            zig-overlay.packages."x86_64-linux"."0.14.0"
            libnotify
            glib
            gdk-pixbuf
            pkg-config

            valgrind
            zls
            zon2nix.packages."x86_64-linux".zon2nix
          ];
        };
      };

      packages.x86_64-linux = rec {
        default = ntfyer;
        ntfyer = pkgs.stdenvNoCC.mkDerivation rec {
          name = "ntfyer";
          version = "0.1.0";
          src = ./.;

          deps = pkgs.callPackage ./nix/build.zig.zon.nix { name = "ntfy-cache"; };
          zigBuildFlags = [
            "--system"
            deps
          ];
          nativeBuildInputs = with pkgs; [
            zig.hook
            libnotify
            glib
            gdk-pixbuf
            pkg-config
          ];
        };
      };
    };
}
