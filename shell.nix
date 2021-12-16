{ nixpkgs ? import <nixpkgs> {  } }:

let
  pkgs = [
    nixpkgs.cacert
    nixpkgs.docker
    nixpkgs.docker-compose
    nixpkgs.efm-langserver
    nixpkgs.elixir
    nixpkgs.elixir_ls
    nixpkgs.fish
    nixpkgs.git
    nixpkgs.neovim
    nixpkgs.nodePackages.eslint_d
    nixpkgs.nodePackages.typescript-language-server
    nixpkgs.nodejs
    nixpkgs.python3
    nixpkgs.tmux
  ];
 
in
  nixpkgs.stdenv.mkDerivation {
    name = "env";
    buildInputs = pkgs;
  }
