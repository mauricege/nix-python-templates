#!/usr/bin/env bash
# set -euo pipefail

usage() {
    echo "Usage: $0 <subcommand> [destination-directory]"
    echo "Subcommands:"
    echo "  init [destination-directory]    Initialize a new project (defaults to current directory)"
    echo "  update [destination-directory]  Update an existing project (defaults to current directory)"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

subcommand="$1"
shift

TEMPLATE_DIR="gh:mauricege/nix-python-templates"

if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    dst_path=$(realpath "$1")
    shift
else
    dst_path="$PWD"
fi

# Save remaining arguments for copier
copier_args=("$@")

case "$subcommand" in
    init)
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

        pythonPackageManager=''${pythonPackageManager:-"uv"}
        pythonProjectFileExists=''${pythonProjectFileExists:-false}

        copier copy "$TEMPLATE_DIR" "$dst_path" --trust --data "_python_package_manager_default=$pythonPackageManager" --data "_python_project_file_exists=$pythonProjectFileExists" "${copier_args[@]}"
        ;;
    update)
        copier update "$dst_path" --trust --skip-answered "${copier_args[@]}"
        ;;
    *)
        usage
        ;;
esac