{
  system ? builtins.currentSystem,
  rustChannel ? "stable",
  rustVersion ? "latest",
}:
let
  sources = import ../npins;

  pkgs = import sources.nixpkgs {
    inherit system;
    overlays = [ (import sources.rust-overlay) ];
  };

  inherit (pkgs) lib;

  craneLib = (import sources.crane { inherit pkgs; }).overrideToolchain (
    p: p.rust-bin.${rustChannel}.${rustVersion}.default
  );

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      (craneLib.fileset.commonCargoSources ../.)
      ../src/htmx.min.js
    ];
  };

  commonArgs = {
    inherit src;
    strictDeps = true;

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.perl
    ];
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  multipaint_by_numbers = craneLib.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts;
      doCheck = false;
      meta.mainProgram = "multipaint_by_numbers";
    }
  );
in
{
  inherit pkgs multipaint_by_numbers;

  packages = {
    inherit multipaint_by_numbers;
    default = multipaint_by_numbers;
  };

  checks = {
    inherit multipaint_by_numbers;

    multipaint_by_numbers-clippy = craneLib.cargoClippy (
      commonArgs
      // {
        inherit cargoArtifacts;
      }
    );

    multipaint_by_numbers-doc = craneLib.cargoDoc (
      commonArgs
      // {
        inherit cargoArtifacts;
      }
    );

    multipaint_by_numbers-fmt = craneLib.cargoFmt {
      inherit src;
    };
  };

  shell = craneLib.devShell { };
}
