{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells.x86_64-linux = {
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

      packages.x86_64-linux = rec {
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
    };
}
