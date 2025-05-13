{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, zig }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells.x86_64-linux = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            zig.packages."x86_64-linux"."0.14.0"
            libnotify
            glib
            gdk-pixbuf
            pkg-config
            valgrind
            zls
          ];
        };
      };
    };
}
