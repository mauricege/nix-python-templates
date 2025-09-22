#!/usr/bin/env bash
# set -euo pipefail

usage() {
    echo "Usage: $0 <subcommand> [destination-directory]"
    echo "Subcommands:"
    echo "  init [destination-directory]    Initialize a new project (defaults to current directory)"
    echo "  update [destination-directory]  Update an existing project (defaults to current directory)"
    echo "  template <devenv|unpyatched> [destination-directory]  Create a new project using a predefined template"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

subcommand="$1"
shift

TEMPLATE_DIR="gh:mauricege/nix-python-templates"


case "$subcommand" in
    init)
        if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
            dst_path=$(realpath "$1")
            shift
        else
            dst_path="$PWD"
        fi
        
        # Save remaining arguments for copier
        copier_args=("$@")
        # List files in the destination path, or set to empty if directory does not exist
        if [ -d "$dst_path" ]; then
            files=$(ls "$dst_path")
        else
            files=""
        fi
        
        echo "Checking for python package manager files in $dst_path:"
        if [[ $files == *"pyproject.toml"* ]]; then
            pythonProjectFileExists=true
            if grep -q '^\[tool.uv' "$dst_path/pyproject.toml"; then
                echo "Found [tool.uv] in pyproject.toml, using uv as package manager."
                pythonPackageManager="uv"
                elif grep -q '^\[tool.pixi' "$dst_path/pyproject.toml"; then
                echo "Found [tool.pixi] in pyproject.toml, using pixi as package manager."
                pythonPackageManager="pixi"
            else
                echo "pyproject.toml found, but no specific tool section detected. Defaulting to uv."
                pythonPackageManager="uv"
            fi
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
            echo "Found environment.yml, using pixi as package manager and importing environment.yml."
            pythonPackageManager="pixi"
            pythonProjectFileExists=true
        fi

        if [[ -f "/run/current-system/sw/share/nix-ld/lib/ld.so" ]]; then
            unpyatchBackendDefault="nix-ld"
        fi
        unpyatchBackendDefault=''${unpyatchBackendDefault:-"fhs"}
        pythonPackageManager=''${pythonPackageManager:-"uv"}
        pythonProjectFileExists=''${pythonProjectFileExists:-false}
        
        copier copy "$TEMPLATE_DIR" "$dst_path" --trust --data "_unpyatch_backend_default=$unpyatchBackendDefault" --data "_python_package_manager_default=$pythonPackageManager" --data "_python_project_file_exists=$pythonProjectFileExists" "${copier_args[@]}"
    ;;
    update)
        if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
            dst_path=$(realpath "$1")
            shift
        else
            dst_path="$PWD"
        fi
        
        # Save remaining arguments for copier
        copier_args=("$@")
        copier update "$dst_path" --trust --skip-answered "${copier_args[@]}"
    ;;
    template)
        template_name="$1"
        shift
        
        # Only allow 'devenv' or 'FHS'
        if [[ "$template_name" != "devenv" && "$template_name" != "unpyatched" ]]; then
            echo "Error: template_name must be 'devenv' or 'unpyatched'"
            exit 1
        fi
        
        if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
            dst_path=$(realpath "$1")
            shift
        else
            dst_path="$PWD"
        fi
        
        mkdir -p "$dst_path"
        
        copier_args=("$@")
        
        # Create a temporary answers.yml file
        answers_file="$dst_path/.copier-answers.yml"
        if [[ "$template_name" == "devenv" ]]; then
            cat > "$answers_file" <<EOF
_src_path: $dst_path
cudaSupport: true
declarative_python_environment: true
framework: devenv
i_know_what_i_am_doing: false
install_flash_attention: false
interface: flake
project_name: "$(basename "$dst_path")"
python_package_manager: uv
python_packages: ''
python_version: '3.12'
stable: true
EOF
        else
            cat > "$answers_file" <<EOF
_src_path: $dst_path
i_know_what_i_am_doing: false
project_name: "$(basename "$dst_path")"
python_package_manager: uv
unpyatched_backend: nix-ld
stable: true
EOF
        fi
        
        echo "Using template '$template_name' for destination '$dst_path'"
        copier copy "$TEMPLATE_DIR" "$dst_path" --trust --defaults --answers-file ".copier-answers.yml" "${copier_args[@]}"
    ;;
    *)
        usage
    ;;
esac