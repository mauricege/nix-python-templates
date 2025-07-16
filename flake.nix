{
  nixConfig = {
    extra-trusted-substituters = ["https://cache.flox.dev"];
    extra-trusted-public-keys = ["flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flox.url = "github:flox/flox";
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
            inputs'.flox.packages.default
            devenv
            devbox
            copier
          ];
        };
        packages.python-env = pkgs.writeShellApplication {
          name = "python-env";
          runtimeInputs = [pkgs.copier pkgs.git];
          text = ''
            # set -euo pipefail

            if [ $# -ne 1 ]; then
              echo "Usage: python-env <destination-directory>"
              exit 1
            fi

            TEMPLATE_DIR=${self}
            DEST_DIR=$(realpath "$1")

            # Create a writable temp copy
            TMP_TEMPLATE=$(mktemp -d)
            cp -r "$TEMPLATE_DIR/." "$TMP_TEMPLATE"
            chmod -R u+w "$TMP_TEMPLATE"

            copier copy "$TMP_TEMPLATE" "$DEST_DIR"
          '';
        };
      };
    };
}
