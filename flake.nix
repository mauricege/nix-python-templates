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
        packages = rec {
          python-env = pkgs.writeShellApplication {
            name = "python-env";
            runtimeInputs = [pkgs.copier pkgs.git];
            text = ''
              # set -euo pipefail

              if [ $# -ne 1 ]; then
                echo "Usage: python-env <destination-directory>"
                exit 1
              fi

              TEMPLATE_DIR=${self}
              dst_path=$(realpath "$1")

              # List files in the destination path, or set to empty if directory does not exist
              if [ -d "$dst_path" ]; then
                files=$(ls "$dst_path")
              else
                files=""
              fi

              echo "Checking for python package manager files in $dst_path:"
              if [[ $files == *"pyproject.toml"* ]]; then
                  echo "Found pyproject.toml, using uv as package manager. Could also be poetry or pixi, but we default to uv."
                  pythonPackageManager="uv"
                  pythonProjectFileExists=true
              fi
              if [[ $files == *"uv.lock"* ]]; then
                  echo "Found uv.lock, using uv as package manager."
                  pythonPackageManager="uv"
                  pythonProjectFileExists=true
              fi

              if [[ $files == *"pixi.lock"* ]] || [[ $files == *"pixi.toml"* ]]; then
                  echo "Found pixi.lock or pixi.toml, using pixi as package manager."
                  pythonPackageManager="pixi"
                  pythonProjectFileExists=true
              fi

              if [[ $files == *"environment.yml"* ]]; then
                  echo "Found environment.yml, using micromamba as package manager."
                  pythonPackageManager="micromamba"
                  pythonProjectFileExists=true
              fi


              pythonPackageManager=''${pythonPackageManager:- "uv"}
              pythonProjectFileExists=''${pythonProjectFileExists:- false}


              # Create a writable temp copy
              TMP_TEMPLATE=$(mktemp -d)
              cp -r "$TEMPLATE_DIR/." "$TMP_TEMPLATE"
              chmod -R u+w "$TMP_TEMPLATE"

              copier copy "$TMP_TEMPLATE" "$dst_path" --trust --data "_python_package_manager_default=$pythonPackageManager" --data "_python_project_file_exists=$pythonProjectFileExists"
            '';
          };
          default = python-env;
        };
      };
    };
}
