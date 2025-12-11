{ pkgs, inputs }:

let
  plugins = import ./plugins.nix { inherit pkgs inputs; };
in

{
  inherit (plugins) plug plugNoCheck;
}
