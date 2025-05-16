{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        treefmtModule = treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix;
        runtimeDependencies = with pkgs; [
          libnotify
          glib
          gdk-pixbuf
        ];
      in
      {
        formatter = treefmtModule.config.build.wrapper;

        devShells = {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                zig_0_14
                pkg-config
                valgrind
                zls
              ]
              ++ runtimeDependencies;
          };
        };

        packages = rec {
          default = ntfyer;
          ntfyer = pkgs.stdenv.mkDerivation rec {
            name = "ntfyer";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              zig_0_14.hook
              pkg-config
            ];

            buildInputs = runtimeDependencies;
          };
        };
      }
    )
    // {
      nixosModules = {
        ntfyer = import ./nix/module.nix { ntfyer = self.packages; };
      };
    };
}
