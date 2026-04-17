{
  description = "synth-core — rkyv contract types for askicc↔askic (grammar types)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
    corec = {
      url = "github:LiGoldragon/corec";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
      inputs.crane.follows = "crane";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, fenix, crane, flake-utils, corec, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain = fenix.packages.${system}.stable.toolchain;
        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        corec-bin = corec.packages.${system}.corec;

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            (craneLib.filterCargoSources path type)
            || (builtins.match ".*\\.core$" path != null);
        };

        generated = pkgs.runCommand "synth-core-generated" {
          nativeBuildInputs = [ corec-bin ];
        } ''
          mkdir -p generated
          corec ${./core} generated/aski_core.rs
          mkdir -p $out
          cp generated/aski_core.rs $out/
        '';

        synth-core-source = pkgs.runCommand "synth-core-source" {} ''
          cp -r ${src} $out
          chmod -R +w $out
          mkdir -p $out/generated
          cp ${generated}/aski_core.rs $out/generated/
        '';

        commonArgs = {
          src = synth-core-source;
          pname = "synth-core";
          version = "0.17.0";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        synth-core-lib = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

        data = pkgs.runCommand "synth-core-data" {} ''
          mkdir -p $out
          cp ${./core}/*.core $out/
        '';

      in {
        packages = {
          default = synth-core-source;
          source = synth-core-source;
          lib = synth-core-lib;
          inherit generated data;
        };

        checks = {
          lib-build = synth-core-lib;
        };

        devShells.default = craneLib.devShell {
          packages = [ corec-bin pkgs.rust-analyzer ];
        };
      }
    );
}
