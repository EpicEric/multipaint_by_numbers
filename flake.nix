{
  description = "Multiplayer Picross/Nonogram for Sandhole";

  inputs = { };

  outputs =
    { self, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      eachSystem =
        f:
        (builtins.foldl' (
          acc: system:
          let
            fSystem = f system;
          in
          builtins.foldl' (
            acc': attr:
            acc'
            // {
              ${attr} = (acc'.${attr} or { }) // fSystem.${attr};
            }
          ) acc (builtins.attrNames fSystem)
        ) { } systems);
    in
    eachSystem (
      system:
      let
        inherit (import ./nix { inherit system; })
          pkgs
          packages
          checks
          shell
          ;
        inherit (pkgs) lib;
      in
      {
        packages.${system} = packages;

        apps.${system}.default = {
          type = "app";
          program = lib.getExe self.packages.${system}.default;
          meta = {
            name = "multipaint_by_numbers";
            description = "Multiplayer Picross/Nonogram for Sandhole";
            license = lib.licenses.mit;
            mainProgram = "multipaint_by_numbers";
            platforms = lib.platforms.linux;
          };
        };

        checks.${system} = checks;

        devShells.${system}.default = shell;
      }
    );
}
