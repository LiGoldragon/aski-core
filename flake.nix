{
  description = "aski-core — rkyv contract types for askicc↔askic";

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
            || (builtins.match ".*\\.aski$" path != null);
        };

        # Run corec on core/*.aski → generated/aski_core.rs
        generated = pkgs.runCommand "aski-core-generated" {
          nativeBuildInputs = [ corec-bin ];
        } ''
          mkdir -p generated
          corec ${./core} generated/aski_core.rs
          mkdir -p $out
          cp generated/aski_core.rs $out/
        '';

        # Full source tree with generated types in place.
        # Downstream crates depend on this via flake-crates/aski-core.
        aski-core-source = pkgs.runCommand "aski-core-source" {} ''
          cp -r ${src} $out
          chmod -R +w $out
          mkdir -p $out/generated
          cp ${generated}/aski_core.rs $out/generated/
        '';

        # Build the lib crate (verifies the generated types compile)
        commonArgs = {
          src = aski-core-source;
          pname = "aski-core";
          version = "0.17.0";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        aski-core-lib = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

        # Pure data — the .aski anatomy files
        data = pkgs.runCommand "aski-core-data" {} ''
          mkdir -p $out
          cp ${./core}/*.aski $out/
        '';

      in {
        packages = {
          default = aski-core-source;
          source = aski-core-source;
          lib = aski-core-lib;
          inherit generated data;
        };

        checks = {
          # Verify the generated types compile
          lib-build = aski-core-lib;
        };

        devShells.default = craneLib.devShell {
          packages = [ corec-bin pkgs.rust-analyzer ];
        };
      }
    );
}
