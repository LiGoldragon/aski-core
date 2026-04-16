{
  description = "aski-core — classification domains + cc (core compiler)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Pure data — the .aski anatomy files
      aski-core-data = pkgs.runCommand "aski-core-data" {} ''
        mkdir -p $out
        cp ${./core}/*.aski $out/
      '';

      # cc binary — the core compiler
      cc = pkgs.rustPlatform.buildRustPackage {
        pname = "cc";
        version = "0.17.0";
        src = ./.;
        cargoLock.lockFile = ./Cargo.lock;
      };

      # Generated Rust types — cc run on the .aski files
      aski-core-generated = pkgs.runCommand "aski-core-generated" {
        nativeBuildInputs = [ cc ];
      } ''
        mkdir -p core generated
        cp ${./core}/*.aski core/
        cc
        mkdir -p $out
        cp generated/aski_core.rs $out/
      '';

    in {
      packages.${system} = {
        default = aski-core-generated;
        data = aski-core-data;
        cc = cc;
        generated = aski-core-generated;
      };

      checks.${system} = {
        cc-tests = pkgs.rustPlatform.buildRustPackage {
          pname = "cc-tests";
          version = "0.17.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          checkPhase = ''
            cargo test
          '';
        };
      };
    };
}
