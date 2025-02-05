{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix = {
    url = "github:nix-community/poetry2nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
        inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication;
        inherit (poetry2nix.legacyPackages.${system}) mkPoetryEnv;
        # pkgs = nixpkgs.legacyPackages.${system};
        pkgs = import "${nixpkgs}" {
          inherit system;
          config.allowUnfree = true;
        };
        poetryOverrides = pkgs.poetry2nix.overrides.withDefaults 
          (self: super:
            let
              pyBuildPackages = self.python.pythonForBuild.pkgs;
            in
          {
            elpy = super.elpy.overridePythonAttrs
            (
              old: {
                buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
              }
            );
          });
        poetryEnv = mkPoetryEnv {
          projectDir = ./.;
          overrides = poetryOverrides;
          # preferWheels = true;
        };
      in
      {
        packages = {
          myapp = mkPoetryApplication { projectDir = self; };
          default = self.packages.${system}.myapp;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            poetryEnv
            python3Packages.pyusb
            python3Packages.libusb1
            libusb1
          ];
          packages = [
            poetry2nix.packages.${system}.poetry
            pkgs.libusb1
          ];
          allowUnfree = true;
        };
      });
}
