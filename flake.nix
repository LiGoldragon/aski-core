{
  description = "aski-core — Kernel schema shared between aski-rs and aski-cc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, fenix, crane, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      toolchain = fenix.packages.${system}.stable.toolchain;
      craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

      askic-bootstrap = pkgs.stdenv.mkDerivation {
        name = "askic-bootstrap-0.4.0";
        src = pkgs.fetchurl {
          url = "https://github.com/LiGoldragon/aski-rs/releases/download/v0.4.0/askic-bundle-x86_64-linux.tar.gz";
          hash = "sha256-H4DGtgUYyzVyDg7yzyu96lQkoVUknCLzseoyDypnoQU=";
        };
        sourceRoot = ".";
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ pkgs.stdenv.cc.cc.lib ];
        installPhase = ''
          install -Dm755 askic $out/bin/.askic-unwrapped
          mkdir -p $out/share/aski-grammar
          cp -r grammar/* $out/share/aski-grammar/
          cat > $out/bin/askic <<'WRAPPER'
          #!/bin/sh
          export ASKI_GRAMMAR_DIR="$(dirname "$(readlink -f "$0")")/../share/aski-grammar"
          exec "$(dirname "$(readlink -f "$0")")/.askic-unwrapped" "$@"
          WRAPPER
          chmod +x $out/bin/askic
        '';
      };

      src = pkgs.lib.cleanSourceWith {
        src = ./.;
        filter = path: type:
          (craneLib.filterCargoSources path type) ||
          (builtins.match ".*\\.aski$" path != null);
      };
      commonArgs = {
        inherit src;
        pname = "aski-core";
        version = "0.1.0";
        nativeBuildInputs = [ askic-bootstrap ];
      };
      cargoArtifacts = craneLib.buildDepsOnly commonArgs;
      aski-core = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });
    in {
      packages.${system} = {
        default = aski-core;
        askic-bootstrap = askic-bootstrap;
      };
      devShells.${system}.default = craneLib.devShell {
        packages = [ askic-bootstrap ];
      };
    };
}
