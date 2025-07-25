{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        lib = nixpkgs.lib;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        forLinux = list: lib.optionals (lib.strings.hasInfix "linux" system) list;
      in
      {
        packages = rec {
          reinforced-shrine-adventure =
            let
              rustPlatform = pkgs.makeRustPlatform rec {
                cargo = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
                rustc = cargo;
              };
            in
            rustPlatform.buildRustPackage rec {
              name = "reinforced-shrine-adventure";
              src = self;
              nativeBuildInputs = [
                pkgs.just
                pkgs.mold
                pkgs.pkg-config
              ];
              xorgBuildInputs = [
                pkgs.xorg.libX11
                pkgs.xorg.libXcursor
                pkgs.xorg.libXi
              ];
              waylandBuildInputs = [
                pkgs.libxkbcommon
                pkgs.wayland
              ];
              buildInputs =
                forLinux [
                  pkgs.alsa-lib
                  pkgs.udev
                  pkgs.vulkan-loader
                ]
                ++ forLinux xorgBuildInputs
                ++ forLinux waylandBuildInputs;
              cargoLock.lockFile = ./Cargo.lock;
              LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
              RUSTFLAGS = "-Clink-arg=-fuse-ld=mold";
            };
          default = reinforced-shrine-adventure;
        };
      }
    );
}
