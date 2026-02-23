{
  system ? builtins.currentSystem,
}:
(import ./nix { inherit system; }).multipaint_by_numbers
