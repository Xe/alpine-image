{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs;[
    packer qemu bashInteractive
  ];
}
