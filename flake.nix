{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-darwin"
        # ...
      ];
      perSystem = {
        config,
        pkgs,
        inputs',
        self',
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            devenv
            copier
            self'.packages.python-env
            pixi
            uv
          ];
        };
        packages = rec {
          python-env = pkgs.writeShellApplication {
            name = "python-env";
            runtimeInputs = with pkgs; [copier git pixi uv];
            text = builtins.readFile "${self}/python-env.sh";
          };
          default = python-env;
        };
      };
    };
}
