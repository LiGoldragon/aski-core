{
  description = "aski-core — the anatomy of aski: type definitions for the sema engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Pure data derivation — just the .aski anatomy files
      aski-core = pkgs.runCommand "aski-core" {} ''
        mkdir -p $out
        cp ${./core}/*.aski $out/
      '';

    in {
      packages.${system} = {
        default = aski-core;
        inherit aski-core;
      };
    };
}
