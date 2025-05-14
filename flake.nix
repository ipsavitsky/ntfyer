{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, zig-overlay }:
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
          ];
        };
      };

      packages.x86_64-linux = rec {
        default = ntfyer;
        ntfyer = pkgs.stdenvNoCC.mkDerivation {
          name = "ntfyer";
          version = "0.1.0";
          src = ./.;

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
