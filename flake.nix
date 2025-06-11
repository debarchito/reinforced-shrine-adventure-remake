{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    oxalica.url = "github:oxalica/rust-overlay";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      oxalica,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ oxalica.overlays.default ];
        };
      in
      {
        packages = rec {
          reinforced-shrine-adventure =
            let
              rustPlatform = pkgs.makeRustPlatform rec {
                rustc = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
                cargo = rustc;
              };
            in
            rustPlatform.buildRustPackage rec {
              name = "reinforced-shrine-adventure";
              src = self;
              nativeBuildInputs = [
                pkgs.mold
                pkgs.pkg-config
              ];
              buildInputs = [
                pkgs.alsa-lib.dev
                pkgs.udev.dev
              ];
              cargoLock.lockFile = ./Cargo.lock;
              LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
              RUSTFLAGS = "-Clink-arg=-fuse-ld=mold";
            };
          default = reinforced-shrine-adventure;
        };
      }
    );
}
